/**
 * Event parser — extracts game event JSON from Roblox Studio console output.
 * Looks for data between __ORIGIN_EVENTS_START__ and __ORIGIN_EVENTS_END__ sentinels.
 */

import { writeFileSync, mkdirSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import {
  GameEvent,
  EVENT_SENTINEL_START,
  EVENT_SENTINEL_END,
  type PlaytestSession,
} from "../types.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const METADATA_DIR = resolve(__dirname, "../../output/metadata");

/**
 * Parse raw console output text and extract all event payloads.
 * A single console dump may contain multiple sentinel-wrapped payloads
 * (e.g., if multiple rounds were played in one session).
 */
export function parseConsoleOutput(rawOutput: string): GameEvent[][] {
  const payloads: GameEvent[][] = [];
  let searchStart = 0;

  while (true) {
    const startIdx = rawOutput.indexOf(EVENT_SENTINEL_START, searchStart);
    if (startIdx === -1) break;

    const jsonStart = startIdx + EVENT_SENTINEL_START.length;
    const endIdx = rawOutput.indexOf(EVENT_SENTINEL_END, jsonStart);
    if (endIdx === -1) break;

    const jsonStr = rawOutput.slice(jsonStart, endIdx).trim();
    try {
      const raw = JSON.parse(jsonStr);
      if (!Array.isArray(raw)) {
        console.warn("Expected array of events, got:", typeof raw);
        searchStart = endIdx + EVENT_SENTINEL_END.length;
        continue;
      }

      // Validate each event
      const validated: GameEvent[] = [];
      for (const item of raw) {
        const result = GameEvent.safeParse(item);
        if (result.success) {
          validated.push(result.data);
        } else {
          // Keep the event even if it doesn't fully validate — best-effort
          validated.push(item as GameEvent);
        }
      }
      payloads.push(validated);
    } catch (err) {
      console.warn("Failed to parse event JSON:", err);
    }

    searchStart = endIdx + EVENT_SENTINEL_END.length;
  }

  return payloads;
}

/**
 * Parse console output from MCP get_console_output / get_playtest_output format.
 * These return structured log arrays rather than raw text.
 */
export function parseStructuredOutput(
  logs: Array<{ level: string; message: string; ts?: number }>
): GameEvent[][] {
  // Concatenate all log messages into a single string for sentinel parsing
  const combined = logs.map((l) => l.message).join("\n");
  return parseConsoleOutput(combined);
}

/**
 * Save parsed events to a session metadata file.
 */
export function saveSessionMetadata(session: PlaytestSession): string {
  if (!existsSync(METADATA_DIR)) {
    mkdirSync(METADATA_DIR, { recursive: true });
  }

  const filePath = resolve(METADATA_DIR, `${session.id}.json`);
  writeFileSync(filePath, JSON.stringify(session, null, 2));
  console.log(`Saved session metadata: ${filePath} (${session.events.length} events)`);
  return filePath;
}

/**
 * Build a PlaytestSession from parsed events.
 */
export function buildSession(
  sessionId: string,
  level: string,
  events: GameEvent[],
  recordingPath: string | null = null
): PlaytestSession {
  const roundStart = events.find((e) => e.type === "RoundStarted");
  const roundEnd = events.find((e) => e.type === "RoundEnded");

  const duration = roundEnd
    ? roundEnd.timestamp
    : events.length > 0
      ? events[events.length - 1].timestamp
      : 0;

  return {
    id: sessionId,
    startedAt: new Date().toISOString(),
    level,
    duration,
    recordingPath,
    events,
  };
}
