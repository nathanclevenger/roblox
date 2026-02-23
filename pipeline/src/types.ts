import { z } from "zod";

// -- Entity & Game State (mirrors Types.luau) --

export const EntityState = z.enum([
  "Idle",
  "Patrol",
  "Investigate",
  "Hunt",
  "Chase",
  "Search",
]);
export type EntityState = z.infer<typeof EntityState>;

export const FearTier = z.enum([
  "Safe",
  "Unease",
  "Dread",
  "Panic",
  "Proximity",
]);
export type FearTier = z.infer<typeof FearTier>;

export const HidingSpotType = z.enum([
  "Locker",
  "UnderBed",
  "Closet",
  "LaundryCart",
  "BathroomStall",
  "Desk",
]);
export type HidingSpotType = z.infer<typeof HidingSpotType>;

// -- Game Events (emitted by EventLogger.luau) --

export const GameEventType = z.enum([
  "EntityPosition",
  "EntityStateChanged",
  "HidingEntered",
  "HidingExited",
  "HidingSpotChecked",
  "PlayerDamaged",
  "PlayerDeath",
  "GeneratorInteract",
  "GeneratorStateUpdate",
  "RoundStarted",
  "RoundEnded",
  "FearTierChanged",
  "StateMachineTransition",
  "PlayerStateUpdate",
]);
export type GameEventType = z.infer<typeof GameEventType>;

export const Vector3Schema = z.object({
  x: z.number(),
  y: z.number(),
  z: z.number(),
});
export type Vector3 = z.infer<typeof Vector3Schema>;

export const GameEvent = z.object({
  type: GameEventType,
  timestamp: z.number(), // seconds since round start
  data: z.record(z.unknown()),
});
export type GameEvent = z.infer<typeof GameEvent>;

export const EntityPositionEvent = GameEvent.extend({
  type: z.literal("EntityPosition"),
  data: z.object({
    position: Vector3Schema,
    state: EntityState,
  }),
});

export const EntityStateChangedEvent = GameEvent.extend({
  type: z.literal("EntityStateChanged"),
  data: z.object({
    from: EntityState,
    to: EntityState,
  }),
});

export const HidingEvent = GameEvent.extend({
  type: z.enum(["HidingEntered", "HidingExited"]),
  data: z.object({
    spotType: HidingSpotType,
    spotId: z.string(),
  }),
});

export const PlayerDamagedEvent = GameEvent.extend({
  type: z.literal("PlayerDamaged"),
  data: z.object({
    health: z.number(),
    isDowned: z.boolean(),
  }),
});

export const GeneratorEvent = GameEvent.extend({
  type: z.literal("GeneratorStateUpdate"),
  data: z.object({
    generatorId: z.string(),
    active: z.boolean(),
    totalActive: z.number(),
    totalRequired: z.number(),
  }),
});

export const FearTierChangedEvent = GameEvent.extend({
  type: z.literal("FearTierChanged"),
  data: z.object({
    from: FearTier,
    to: FearTier,
    distance: z.number(),
    intensity: z.number(),
  }),
});

export const StateMachineTransitionEvent = GameEvent.extend({
  type: z.literal("StateMachineTransition"),
  data: z.object({
    from: EntityState,
    to: EntityState,
    reason: z.string().optional(),
  }),
});

// -- Pipeline Data Structures --

export interface PlaytestSession {
  id: string;
  startedAt: string; // ISO timestamp
  level: string;
  duration: number; // seconds
  recordingPath: string | null; // OBS output file
  events: GameEvent[];
}

export interface ClipCandidate {
  id: string;
  sessionId: string;
  startTime: number; // seconds into recording
  endTime: number; // seconds into recording
  score: number; // 0-100
  reason: string; // why this clip scored high
  tags: ClipTag[];
  events: GameEvent[]; // events within this clip's window
  fearTimeline: FearTimelinePoint[];
}

export type ClipTag =
  | "chase"
  | "near-miss"
  | "death"
  | "hiding"
  | "generator"
  | "fear-spike"
  | "jumpscare"
  | "escape";

export interface FearTimelinePoint {
  time: number; // seconds
  tier: FearTier;
  intensity: number; // 0-1
  distance: number; // studs
}

export type ContentType =
  | "tiktok"
  | "raw"
  | "trailer"
  | "arg"
  | "devdiary";

export interface RenderJob {
  sessionId: string;
  clipId: string;
  contentType: ContentType;
  inputVideoPath: string;
  voiceoverPath: string | null;
  outputPath: string;
  composition: CompositionId;
}

export type CompositionId =
  | "GameplayClip"
  | "RawFootage"
  | "Trailer"
  | "ARGContent"
  | "DevDiary";

export interface VoiceoverRequest {
  text: string;
  voiceId: string;
  stability: number;
  similarityBoost: number;
  style: number;
}

export interface VoiceoverResult {
  audioPath: string;
  duration: number; // seconds
}

// -- Fear Tier Thresholds (mirrors ProximityFear/init.luau) --

export const FEAR_THRESHOLDS = {
  SAFE: 80,
  UNEASE: 50,
  DREAD: 25,
  PANIC: 10,
} as const;

export function getFearTierFromDistance(distance: number): {
  tier: FearTier;
  intensity: number;
} {
  if (distance >= FEAR_THRESHOLDS.SAFE) {
    return { tier: "Safe", intensity: 0 };
  }
  if (distance >= FEAR_THRESHOLDS.UNEASE) {
    const t =
      1 -
      (distance - FEAR_THRESHOLDS.UNEASE) /
        (FEAR_THRESHOLDS.SAFE - FEAR_THRESHOLDS.UNEASE);
    return { tier: "Unease", intensity: t * 0.25 };
  }
  if (distance >= FEAR_THRESHOLDS.DREAD) {
    const t =
      1 -
      (distance - FEAR_THRESHOLDS.DREAD) /
        (FEAR_THRESHOLDS.UNEASE - FEAR_THRESHOLDS.DREAD);
    return { tier: "Dread", intensity: 0.25 + t * 0.25 };
  }
  if (distance >= FEAR_THRESHOLDS.PANIC) {
    const t =
      1 -
      (distance - FEAR_THRESHOLDS.PANIC) /
        (FEAR_THRESHOLDS.DREAD - FEAR_THRESHOLDS.PANIC);
    return { tier: "Panic", intensity: 0.5 + t * 0.25 };
  }
  const t = 1 - distance / FEAR_THRESHOLDS.PANIC;
  return { tier: "Proximity", intensity: 0.75 + t * 0.25 };
}

// -- Event sentinels for console parsing --

export const EVENT_SENTINEL_START = "__ORIGIN_EVENTS_START__";
export const EVENT_SENTINEL_END = "__ORIGIN_EVENTS_END__";
