/**
 * Session manager — generates session IDs, manages file paths and naming conventions.
 */

import { mkdirSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUTPUT_ROOT = resolve(__dirname, "../../output");

export interface SessionPaths {
  raw: string; // OBS recording output
  metadata: string; // session event JSON
  audio: string; // voiceover files
  clips: string; // ffmpeg-split segments
  rendered: string; // final videos
}

/**
 * Generate a unique session ID.
 * Format: <level>-<YYYYMMDD>-<HHMMSS>-<random>
 */
export function generateSessionId(level: string): string {
  const now = new Date();
  const date = now.toISOString().slice(0, 10).replace(/-/g, "");
  const time = now.toTimeString().slice(0, 8).replace(/:/g, "");
  const rand = Math.random().toString(36).slice(2, 6);
  return `${level}-${date}-${time}-${rand}`;
}

/**
 * Get all output paths for a session, creating directories as needed.
 */
export function getSessionPaths(sessionId: string): SessionPaths {
  const paths: SessionPaths = {
    raw: resolve(OUTPUT_ROOT, "raw", sessionId),
    metadata: resolve(OUTPUT_ROOT, "metadata"),
    audio: resolve(OUTPUT_ROOT, "audio", sessionId),
    clips: resolve(OUTPUT_ROOT, "clips", sessionId),
    rendered: resolve(OUTPUT_ROOT, "rendered", sessionId),
  };

  for (const dir of Object.values(paths)) {
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }
  }

  return paths;
}

/**
 * Get the expected OBS recording filename for a session.
 */
export function getRecordingFilename(sessionId: string): string {
  return `${sessionId}.mkv`;
}

/**
 * Get the path for a clip segment file.
 */
export function getClipPath(
  sessionId: string,
  clipIndex: number,
  ext: string = "mp4"
): string {
  const paths = getSessionPaths(sessionId);
  return resolve(paths.clips, `clip-${clipIndex.toString().padStart(3, "0")}.${ext}`);
}

/**
 * Get the path for a rendered video.
 */
export function getRenderedPath(
  sessionId: string,
  clipIndex: number,
  contentType: string,
  ext: string = "mp4"
): string {
  const paths = getSessionPaths(sessionId);
  return resolve(
    paths.rendered,
    `${contentType}-clip-${clipIndex.toString().padStart(3, "0")}.${ext}`
  );
}

/**
 * Get the path for a voiceover audio file.
 */
export function getVoiceoverPath(
  sessionId: string,
  clipIndex: number,
  ext: string = "mp3"
): string {
  const paths = getSessionPaths(sessionId);
  return resolve(paths.audio, `vo-clip-${clipIndex.toString().padStart(3, "0")}.${ext}`);
}

/**
 * Get the path for session metadata JSON.
 */
export function getMetadataPath(sessionId: string): string {
  return resolve(OUTPUT_ROOT, "metadata", `${sessionId}.json`);
}
