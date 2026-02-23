/**
 * MCP Director — generates Luau scripts from choreography definitions
 * and builds execution plans for Studio injection.
 */

import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import type {
  Choreography,
  ExecutionPlan,
  ExecutionStep,
} from "./types.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const LUAU_DIR = resolve(__dirname, "../../luau");

function readTemplate(filename: string): string {
  return readFileSync(resolve(LUAU_DIR, filename), "utf-8");
}

/**
 * Generate the server-side Luau script with the action timeline embedded.
 */
export function generateServerScript(choreography: Choreography): string {
  const template = readTemplate("DirectorServer.luau");

  const timelineJson = JSON.stringify(choreography.actions);
  // Merge markers into the action timeline as log_marker actions
  const markerActions = choreography.markers.map((m) => ({
    time: m.time,
    type: "log_marker",
    params: { label: m.label, time: m.time },
  }));
  const allActions = [...choreography.actions, ...markerActions].sort(
    (a, b) => a.time - b.time
  );
  const fullTimelineJson = JSON.stringify(allActions);

  return template
    .replace('"__TIMELINE_JSON__"', `'${escapeLuauString(fullTimelineJson)}'`)
    .replaceAll("__DURATION__", String(choreography.durationSeconds));
}

/**
 * Generate the client-side camera Luau script with keyframes embedded.
 */
export function generateCameraScript(choreography: Choreography): string {
  const template = readTemplate("DirectorCamera.luau");

  const cameraJson = JSON.stringify(choreography.camera);

  return template
    .replace('"__CAMERA_JSON__"', `'${escapeLuauString(cameraJson)}'`)
    .replaceAll("__SETUP_DELAY__", String(choreography.setupDelaySeconds));
}

/**
 * Generate a step-by-step execution plan for MCP tool calls.
 */
export function generateExecutionPlan(choreography: Choreography): ExecutionPlan {
  const steps: ExecutionStep[] = [];
  let stepNum = 1;

  const cameraScriptPath =
    "game.StarterPlayer.StarterPlayerScripts.DirectorCamera";

  // Phase 1: Setup (edit mode)
  steps.push({
    step: stepNum++,
    phase: "setup",
    description: "Create DirectorCamera LocalScript in StarterPlayerScripts",
    tool: "create_object",
    params: {
      className: "LocalScript",
      parent: "game.StarterPlayer.StarterPlayerScripts",
      name: "DirectorCamera",
    },
  });

  steps.push({
    step: stepNum++,
    phase: "setup",
    description: "Set DirectorCamera source code (camera keyframes embedded)",
    tool: "set_script_source",
    params: {
      instancePath: cameraScriptPath,
      source: "<<GENERATED_CAMERA_SCRIPT>>",
    },
  });

  // Phase 2: Playtest
  steps.push({
    step: stepNum++,
    phase: "playtest",
    description: "Start play mode",
    tool: "start_stop_play",
    params: {
      mode: "start_play",
    },
  });

  steps.push({
    step: stepNum++,
    phase: "playtest",
    description: `Run server choreography (${choreography.actions.length} actions over ${choreography.durationSeconds}s)`,
    tool: "run_script_in_play_mode",
    params: {
      code: "<<GENERATED_SERVER_SCRIPT>>",
      mode: "start_play",
      timeout: choreography.durationSeconds + 15,
    },
  });

  steps.push({
    step: stepNum++,
    phase: "playtest",
    description: "Stop play mode",
    tool: "start_stop_play",
    params: {
      mode: "stop",
    },
  });

  // Phase 3: Cleanup
  steps.push({
    step: stepNum++,
    phase: "cleanup",
    description: "Delete DirectorCamera script",
    tool: "delete_object",
    params: {
      instancePath: cameraScriptPath,
    },
  });

  return {
    choreography: {
      id: choreography.id,
      game: choreography.game,
      title: choreography.title,
      durationSeconds: choreography.durationSeconds,
    },
    steps,
    estimatedDurationSeconds:
      choreography.durationSeconds +
      choreography.setupDelaySeconds +
      20, // buffer for setup/teardown
  };
}

/**
 * Format an execution plan as human-readable text.
 */
export function formatExecutionPlan(plan: ExecutionPlan): string {
  const lines: string[] = [];

  lines.push(`Choreography: ${plan.choreography.title}`);
  lines.push(`Game: ${plan.choreography.game}`);
  lines.push(`Duration: ${plan.choreography.durationSeconds}s`);
  lines.push(
    `Estimated total: ~${plan.estimatedDurationSeconds}s (including setup/teardown)`
  );
  lines.push("");
  lines.push("=".repeat(70));

  let currentPhase = "";
  for (const step of plan.steps) {
    if (step.phase !== currentPhase) {
      currentPhase = step.phase;
      lines.push("");
      lines.push(
        `── ${currentPhase.toUpperCase()} ${"─".repeat(70 - currentPhase.length - 4)}`
      );
    }

    lines.push(
      `  ${String(step.step).padStart(2)}. [${step.tool}] ${step.description}`
    );
  }

  lines.push("");
  lines.push("=".repeat(70));
  lines.push("");
  lines.push("To execute manually with MCP tools:");
  lines.push(
    "  1. Run setup steps in Edit mode (inject camera script)"
  );
  lines.push(
    "  2. Start playtest, then run server script via run_script_in_play_mode"
  );
  lines.push("  3. Wait for choreography to complete");
  lines.push("  4. Stop playtest and cleanup");
  lines.push("");
  lines.push(
    "Use --print-server and --print-camera to get the generated Luau scripts."
  );

  return lines.join("\n");
}

/**
 * Escape a string for embedding in a Luau single-quoted string literal.
 */
function escapeLuauString(str: string): string {
  return str
    .replace(/\\/g, "\\\\")
    .replace(/'/g, "\\'")
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r");
}
