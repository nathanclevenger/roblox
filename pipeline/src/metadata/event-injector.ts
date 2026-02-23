/**
 * EventLogger injector — reads the Luau script and injects it into
 * Roblox Studio via MCP run_code during a capture session.
 *
 * When run from the CLI, this module outputs the injection command
 * that should be executed through the MCP run_code tool.
 */

import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const LOGGER_PATH = resolve(__dirname, "../../luau/EventLogger.luau");

/**
 * Read the EventLogger.luau source code for injection.
 */
export function getEventLoggerSource(): string {
  return readFileSync(LOGGER_PATH, "utf-8");
}

/**
 * Build the run_code command string that injects EventLogger into Studio.
 * The script is wrapped in a loadstring call so it executes in the client context.
 */
export function buildInjectionCommand(): string {
  const source = getEventLoggerSource();
  // Escape the source for embedding in a Luau string
  const escaped = source
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n");
  return `loadstring("${escaped}")()`;
}

/**
 * Build a simpler injection approach — paste the source directly into
 * a LocalScript under StarterPlayerScripts so it runs on playtest.
 * Returns the source as-is (MCP set_script_source handles the rest).
 */
export function getInjectionSource(): string {
  return getEventLoggerSource();
}
