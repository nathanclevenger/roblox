/**
 * Choreography types — defines the data structures for scripted video capture.
 *
 * A Choreography is a timeline of camera keyframes and server-side actions
 * that produce repeatable, director-quality footage when executed in Roblox Studio.
 */

export type Vec3 = { x: number; y: number; z: number };

export type CameraMode =
  | "fixed"
  | "follow_player"
  | "follow_entity"
  | "scripted"
  | "first_person";

export type Easing = "linear" | "ease_in" | "ease_out" | "ease_in_out";

export interface CameraKeyframe {
  /** Seconds from playtest start */
  time: number;
  /** World position (for fixed/scripted modes) */
  position?: Vec3;
  /** Look target position */
  lookAt?: Vec3;
  /** Field of view in degrees */
  fov?: number;
  /** Camera mode for this keyframe */
  mode?: CameraMode;
  /** Easing function to interpolate toward this keyframe */
  easing?: Easing;
  /** Follow offset (for follow_player / follow_entity modes) */
  followOffset?: Vec3;
  /** Entity name to follow (for follow_entity mode) */
  followTarget?: string;
}

export type ActionType =
  // The Origin
  | "teleport_player"
  | "entity_activate"
  | "entity_set_position"
  | "entity_transition"
  | "entity_target_player"
  // Draw to Escape
  | "start_round"
  | "end_round"
  | "submit_drawing"
  | "complete_stage"
  | "teleport_to_stage"
  // Shared
  | "set_lighting"
  | "log_marker"
  | "run_luau";

export interface Action {
  /** Seconds from playtest start */
  time: number;
  /** Action type to execute */
  type: ActionType;
  /** Action-specific parameters */
  params: Record<string, unknown>;
}

export interface Marker {
  /** Seconds from playtest start */
  time: number;
  /** Human-readable label for clip segmentation */
  label: string;
}

export type GameId = "the-origin" | "draw-to-escape";

export interface Choreography {
  /** Unique identifier for this choreography */
  id: string;
  /** Which game this choreography targets */
  game: GameId;
  /** Human-readable title */
  title: string;
  /** Total duration in seconds */
  durationSeconds: number;
  /** Seconds to wait after spawn before starting the timeline */
  setupDelaySeconds: number;
  /** Camera keyframe timeline */
  camera: CameraKeyframe[];
  /** Server-side action timeline */
  actions: Action[];
  /** Named markers for clip segmentation / OBS scene triggers */
  markers: Marker[];
}

export interface ExecutionStep {
  /** Step number (1-based) */
  step: number;
  /** Phase: "setup", "playtest", "cleanup" */
  phase: "setup" | "playtest" | "cleanup";
  /** Human-readable description */
  description: string;
  /** MCP tool to call */
  tool: string;
  /** MCP tool parameters */
  params: Record<string, unknown>;
}

export interface ExecutionPlan {
  choreography: Pick<Choreography, "id" | "game" | "title" | "durationSeconds">;
  steps: ExecutionStep[];
  estimatedDurationSeconds: number;
}
