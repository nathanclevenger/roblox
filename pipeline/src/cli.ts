#!/usr/bin/env node
/**
 * Pipeline CLI — orchestrates the full video generation workflow.
 *
 * Commands:
 *   capture  — Record a playtest session (OBS + MCP)
 *   analyze  — Score and rank clips from a session
 *   voiceover — Generate VO for a clip
 *   render   — Render a clip to video
 *   preview  — Open Remotion Studio for a clip
 *   auto     — Full pipeline: capture → analyze → voiceover → render
 */

import { Command } from "commander";
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { execSync, spawn } from "node:child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "..");

const program = new Command();

program
  .name("pipeline")
  .description("The Origin — video generation pipeline")
  .version("0.1.0");

// ── capture ──────────────────────────────────────────────

program
  .command("capture")
  .description("Record a playtest session via OBS + MCP")
  .option("-l, --level <level>", "Level name", "hospital")
  .option("-t, --types <types>", "Content types (comma-separated)", "tiktok,raw")
  .option("--no-obs", "Skip OBS recording (metadata only)")
  .option("--obs-scene <scene>", "OBS scene name for Roblox capture")
  .action(async (opts) => {
    const { generateSessionId, getSessionPaths } = await import(
      "./capture/session-manager.js"
    );

    const sessionId = generateSessionId(opts.level);
    const paths = getSessionPaths(sessionId);
    console.log(`Session: ${sessionId}`);
    console.log(`Output:  ${paths.raw}`);

    // Step 1: Connect OBS (if enabled)
    if (opts.obs !== false) {
      const { OBSController } = await import("./capture/obs-controller.js");
      const obs = new OBSController();

      try {
        await obs.connect();
        await obs.setOutputPath(paths.raw);

        if (opts.obsScene) {
          await obs.setScene(opts.obsScene);
        }

        console.log("\nOBS connected. Starting recording...");
        await obs.startRecording();
        console.log("Recording started. Run playtest in Studio, then press Ctrl+C to stop.\n");

        // Wait for SIGINT
        await new Promise<void>((resolvePromise) => {
          process.on("SIGINT", async () => {
            console.log("\nStopping recording...");
            const outputPath = await obs.stopRecording();
            await obs.disconnect();
            console.log(`Recording saved: ${outputPath}`);
            resolvePromise();
          });
        });
      } catch (err) {
        console.error("OBS error:", err instanceof Error ? err.message : err);
        console.log("Continuing without OBS recording...");
      }
    }

    // Step 2: Inject EventLogger and collect events
    console.log(`\nSession ${sessionId} ready.`);
    console.log("Next steps:");
    console.log(`  1. Inject EventLogger: pnpm pipeline inject --session ${sessionId}`);
    console.log(`  2. Run playtest in Studio`);
    console.log(`  3. Collect events: pnpm pipeline collect --session ${sessionId}`);
    console.log(`  4. Analyze: pnpm pipeline analyze --session ${sessionId}`);
  });

// ── inject ───────────────────────────────────────────────

program
  .command("inject")
  .description("Inject EventLogger into Studio (prints the Luau source)")
  .action(async () => {
    const { getEventLoggerSource } = await import(
      "./metadata/event-injector.js"
    );
    const source = getEventLoggerSource();
    console.log("Copy the following into MCP run_code or a LocalScript:\n");
    console.log("─".repeat(60));
    console.log(source);
    console.log("─".repeat(60));
    console.log(
      `\n${source.length} characters. Paste into Studio's command bar or inject via MCP.`
    );
  });

// ── collect ──────────────────────────────────────────────

program
  .command("collect")
  .description("Parse events from Studio console output")
  .requiredOption("-s, --session <id>", "Session ID")
  .option("-i, --input <file>", "Raw console output file (instead of MCP)")
  .option("-l, --level <level>", "Level name", "hospital")
  .action(async (opts) => {
    const {
      parseConsoleOutput,
      buildSession,
      saveSessionMetadata,
    } = await import("./metadata/event-parser.js");

    let rawOutput: string;

    if (opts.input) {
      rawOutput = readFileSync(opts.input, "utf-8");
    } else {
      console.log(
        "No input file specified. Paste console output below (end with Ctrl+D):\n"
      );
      rawOutput = readFileSync("/dev/stdin", "utf-8");
    }

    const payloads = parseConsoleOutput(rawOutput);
    if (payloads.length === 0) {
      console.error("No event payloads found in console output.");
      console.error(
        "Ensure EventLogger was injected and a round was completed."
      );
      process.exit(1);
    }

    console.log(`Found ${payloads.length} event payload(s)`);

    // Use the largest payload (most events = longest round)
    const events = payloads.reduce(
      (best, p) => (p.length > best.length ? p : best),
      payloads[0]
    );

    const session = buildSession(opts.session, opts.level, events);
    const filePath = saveSessionMetadata(session);

    console.log(`\nSession saved: ${filePath}`);
    console.log(`  Events: ${session.events.length}`);
    console.log(`  Duration: ${session.duration.toFixed(1)}s`);
    console.log(
      `\nNext: pnpm pipeline analyze --session ${opts.session}`
    );
  });

// ── analyze ──────────────────────────────────────────────

program
  .command("analyze")
  .description("Score and rank clips from a session")
  .requiredOption("-s, --session <id>", "Session ID")
  .option("-n, --max-clips <n>", "Max clips to output", "12")
  .option("-m, --min-score <n>", "Minimum clip score", "30")
  .action(async (opts) => {
    const { getMetadataPath } = await import(
      "./capture/session-manager.js"
    );
    const { selectClips, recommendContentTypes } = await import(
      "./metadata/clip-selector.js"
    );

    const metaPath = getMetadataPath(opts.session);
    if (!existsSync(metaPath)) {
      console.error(`Session not found: ${metaPath}`);
      console.error("Run 'collect' first to parse events.");
      process.exit(1);
    }

    const session = JSON.parse(readFileSync(metaPath, "utf-8"));
    const clips = selectClips(session, {
      maxClips: parseInt(opts.maxClips),
      minScore: parseInt(opts.minScore),
    });

    console.log(`\nSession: ${opts.session}`);
    console.log(`Events: ${session.events.length}`);
    console.log(`Duration: ${session.duration.toFixed(1)}s`);
    console.log(`\n${"─".repeat(70)}`);
    console.log(
      `${"#".padEnd(4)} ${"Score".padEnd(6)} ${"Time".padEnd(14)} ${"Tags".padEnd(25)} Reason`
    );
    console.log("─".repeat(70));

    for (let i = 0; i < clips.length; i++) {
      const clip = clips[i];
      const timeRange = `${clip.startTime.toFixed(1)}-${clip.endTime.toFixed(1)}s`;
      const tags = clip.tags.join(", ");
      const types = recommendContentTypes(clip).join(", ");
      console.log(
        `${String(i + 1).padEnd(4)} ${String(clip.score.toFixed(0)).padEnd(6)} ${timeRange.padEnd(14)} ${tags.padEnd(25)} ${clip.reason}`
      );
    }

    console.log(`\nFound ${clips.length} clips above score threshold.`);
    console.log(
      `\nNext: pnpm pipeline render --session ${opts.session} --clip 1 --type tiktok`
    );
  });

// ── voiceover ────────────────────────────────────────────

program
  .command("voiceover")
  .description("Generate voiceover for a clip")
  .requiredOption("-s, --session <id>", "Session ID")
  .requiredOption("-c, --clip <n>", "Clip number (1-based)")
  .option("-t, --type <type>", "Content type", "tiktok")
  .option("--text <text>", "Override VO text")
  .action(async (opts) => {
    const { getMetadataPath, getVoiceoverPath } = await import(
      "./capture/session-manager.js"
    );
    const { selectClips } = await import("./metadata/clip-selector.js");
    const { generateScript } = await import(
      "./voiceover/script-generator.js"
    );
    const { synthesize } = await import("./voiceover/tts-client.js");
    const { getVoiceProfile } = await import("./voiceover/voices.js");

    const metaPath = getMetadataPath(opts.session);
    if (!existsSync(metaPath)) {
      console.error(`Session not found: ${metaPath}`);
      process.exit(1);
    }

    const session = JSON.parse(readFileSync(metaPath, "utf-8"));
    const clips = selectClips(session);
    const clipIdx = parseInt(opts.clip) - 1;

    if (clipIdx < 0 || clipIdx >= clips.length) {
      console.error(`Clip ${opts.clip} not found. Session has ${clips.length} clips.`);
      process.exit(1);
    }

    const clip = clips[clipIdx];
    const contentType = opts.type as "tiktok" | "raw" | "trailer" | "arg" | "devdiary";
    const text = opts.text || generateScript(clip, contentType);

    if (!text) {
      console.log("No voiceover text generated for this clip/type combination.");
      process.exit(0);
    }

    console.log(`Clip #${opts.clip}: ${clip.reason}`);
    console.log(`Type: ${contentType}`);
    console.log(`Text: "${text}"`);

    const voice = getVoiceProfile(contentType);
    const outputPath = getVoiceoverPath(opts.session, clipIdx);

    const result = await synthesize(text, voice, outputPath);
    console.log(`\nVoiceover saved: ${result.audioPath}`);
    console.log(`Estimated duration: ${result.duration.toFixed(1)}s`);
  });

// ── render ───────────────────────────────────────────────

program
  .command("render")
  .description("Render a clip to video via Remotion")
  .requiredOption("-s, --session <id>", "Session ID")
  .requiredOption("-c, --clip <n>", "Clip number (1-based)")
  .option("-t, --type <type>", "Content type", "tiktok")
  .option("--crf <n>", "Quality (18=high, 28=low)", "20")
  .option("--preview", "Fast preview (lower quality)")
  .action(async (opts) => {
    const { getMetadataPath, getRenderedPath, getClipPath, getVoiceoverPath } =
      await import("./capture/session-manager.js");
    const { selectClips } = await import("./metadata/clip-selector.js");

    const metaPath = getMetadataPath(opts.session);
    if (!existsSync(metaPath)) {
      console.error(`Session not found: ${metaPath}`);
      process.exit(1);
    }

    const session = JSON.parse(readFileSync(metaPath, "utf-8"));
    const clips = selectClips(session);
    const clipIdx = parseInt(opts.clip) - 1;

    if (clipIdx < 0 || clipIdx >= clips.length) {
      console.error(`Clip ${opts.clip} not found.`);
      process.exit(1);
    }

    const clip = clips[clipIdx];
    const contentType = opts.type;
    const outputPath = getRenderedPath(opts.session, clipIdx, contentType);
    const clipVideoPath = getClipPath(opts.session, clipIdx);
    const voPath = getVoiceoverPath(opts.session, clipIdx);

    // Map content type to composition ID
    const compositionMap: Record<string, string> = {
      tiktok: "GameplayClip",
      raw: "RawFootage",
      trailer: "Trailer",
      arg: "ARGContent",
      devdiary: "DevDiary",
    };
    const compositionId = compositionMap[contentType] || "GameplayClip";

    console.log(`Rendering clip #${opts.clip} as ${contentType}`);
    console.log(`  Composition: ${compositionId}`);
    console.log(`  Output: ${outputPath}`);

    // Build input props
    const inputProps = JSON.stringify({
      videoSrc: clipVideoPath,
      voiceoverSrc: existsSync(voPath) ? voPath : undefined,
      fearTimeline: clip.fearTimeline,
      clipStartTime: clip.startTime,
    });

    const crf = opts.preview ? 28 : parseInt(opts.crf);

    // Use Remotion CLI for rendering
    const cmd = [
      "npx",
      "remotion",
      "render",
      compositionId,
      outputPath,
      "--props",
      inputProps,
      "--crf",
      String(crf),
      "--codec",
      "h264",
    ].join(" ");

    console.log("\nStarting Remotion render...\n");

    try {
      execSync(cmd, {
        cwd: ROOT,
        stdio: "inherit",
        env: { ...process.env },
      });
      console.log(`\nRender complete: ${outputPath}`);
    } catch (err) {
      console.error("Render failed:", err instanceof Error ? err.message : err);
      process.exit(1);
    }
  });

// ── preview ──────────────────────────────────────────────

program
  .command("preview")
  .description("Open Remotion Studio to preview compositions")
  .action(async () => {
    console.log("Starting Remotion Studio...");
    const child = spawn("npx", ["remotion", "studio"], {
      cwd: ROOT,
      stdio: "inherit",
      env: { ...process.env },
    });

    child.on("exit", (code) => {
      process.exit(code ?? 0);
    });
  });

// ── split ────────────────────────────────────────────────

program
  .command("split")
  .description("Split raw recording into clips using ffmpeg")
  .requiredOption("-s, --session <id>", "Session ID")
  .requiredOption("-r, --recording <path>", "Path to raw recording file")
  .action(async (opts) => {
    const { getMetadataPath, getClipPath } = await import(
      "./capture/session-manager.js"
    );
    const { selectClips } = await import("./metadata/clip-selector.js");

    const metaPath = getMetadataPath(opts.session);
    if (!existsSync(metaPath)) {
      console.error(`Session not found: ${metaPath}`);
      process.exit(1);
    }

    const session = JSON.parse(readFileSync(metaPath, "utf-8"));
    const clips = selectClips(session);

    if (!existsSync(opts.recording)) {
      console.error(`Recording not found: ${opts.recording}`);
      process.exit(1);
    }

    console.log(`Splitting ${clips.length} clips from: ${opts.recording}\n`);

    for (let i = 0; i < clips.length; i++) {
      const clip = clips[i];
      const outputPath = getClipPath(opts.session, i);
      const duration = clip.endTime - clip.startTime;

      const cmd = [
        "ffmpeg",
        "-y",
        "-ss",
        String(clip.startTime),
        "-i",
        opts.recording,
        "-t",
        String(duration),
        "-c:v",
        "libx264",
        "-crf",
        "18",
        "-preset",
        "fast",
        "-c:a",
        "aac",
        outputPath,
      ].join(" ");

      console.log(
        `  Clip ${i + 1}/${clips.length}: ${clip.startTime.toFixed(1)}s-${clip.endTime.toFixed(1)}s (${duration.toFixed(1)}s) → ${outputPath}`
      );

      try {
        execSync(cmd, { stdio: "pipe" });
      } catch (err) {
        console.error(`  Failed to split clip ${i + 1}:`, err instanceof Error ? err.message : err);
      }
    }

    console.log(`\nDone. ${clips.length} clips saved.`);
  });

// ── auto ─────────────────────────────────────────────────

program
  .command("auto")
  .description("Full pipeline: analyze → voiceover → render")
  .requiredOption("-s, --session <id>", "Session ID")
  .option("-r, --recording <path>", "Path to raw recording file")
  .option("-t, --types <types>", "Content types (comma-separated)", "tiktok")
  .option("-n, --max-clips <n>", "Max clips to render", "5")
  .option("--preview", "Fast preview mode")
  .action(async (opts) => {
    const { getMetadataPath, getClipPath, getVoiceoverPath, getRenderedPath } =
      await import("./capture/session-manager.js");
    const { selectClips, recommendContentTypes } = await import(
      "./metadata/clip-selector.js"
    );
    const { generateScript } = await import(
      "./voiceover/script-generator.js"
    );
    const { synthesize } = await import("./voiceover/tts-client.js");
    const { getVoiceProfile } = await import("./voiceover/voices.js");

    const metaPath = getMetadataPath(opts.session);
    if (!existsSync(metaPath)) {
      console.error(`Session not found: ${metaPath}`);
      process.exit(1);
    }

    const session = JSON.parse(readFileSync(metaPath, "utf-8"));
    const clips = selectClips(session, {
      maxClips: parseInt(opts.maxClips),
    });
    const contentTypes = opts.types.split(",");

    console.log(`Session: ${opts.session}`);
    console.log(`Clips: ${clips.length}`);
    console.log(`Types: ${contentTypes.join(", ")}`);

    // Step 1: Split recording (if provided)
    if (opts.recording) {
      console.log("\n[1/3] Splitting recording into clips...");
      for (let i = 0; i < clips.length; i++) {
        const clip = clips[i];
        const outputPath = getClipPath(opts.session, i);
        const duration = clip.endTime - clip.startTime;

        try {
          execSync(
            `ffmpeg -y -ss ${clip.startTime} -i "${opts.recording}" -t ${duration} -c:v libx264 -crf 18 -preset fast -c:a aac "${outputPath}"`,
            { stdio: "pipe" }
          );
          console.log(`  Clip ${i + 1}: ${duration.toFixed(1)}s`);
        } catch {
          console.error(`  Failed to split clip ${i + 1}`);
        }
      }
    }

    // Step 2: Generate voiceovers
    console.log("\n[2/3] Generating voiceovers...");
    for (let i = 0; i < clips.length; i++) {
      const clip = clips[i];
      for (const type of contentTypes) {
        const text = generateScript(
          clip,
          type as "tiktok" | "raw" | "trailer" | "arg" | "devdiary"
        );
        if (!text) continue;

        const voice = getVoiceProfile(
          type as "tiktok" | "raw" | "trailer" | "arg" | "devdiary"
        );
        const voPath = getVoiceoverPath(opts.session, i);

        try {
          await synthesize(text, voice, voPath);
          console.log(`  Clip ${i + 1} (${type}): generated`);
        } catch (err) {
          console.warn(
            `  Clip ${i + 1} (${type}): VO failed — ${err instanceof Error ? err.message : "unknown"}`
          );
        }
      }
    }

    // Step 3: Render
    console.log("\n[3/3] Rendering videos...");
    const compositionMap: Record<string, string> = {
      tiktok: "GameplayClip",
      raw: "RawFootage",
      trailer: "Trailer",
      arg: "ARGContent",
      devdiary: "DevDiary",
    };

    for (let i = 0; i < clips.length; i++) {
      const clip = clips[i];
      for (const type of contentTypes) {
        const outputPath = getRenderedPath(opts.session, i, type);
        const clipVideoPath = getClipPath(opts.session, i);
        const voPath = getVoiceoverPath(opts.session, i);
        const compositionId = compositionMap[type] || "GameplayClip";

        const inputProps = JSON.stringify({
          videoSrc: clipVideoPath,
          voiceoverSrc: existsSync(voPath) ? voPath : undefined,
          fearTimeline: clip.fearTimeline,
          clipStartTime: clip.startTime,
        });

        const crf = opts.preview ? 28 : 20;

        try {
          execSync(
            `npx remotion render ${compositionId} "${outputPath}" --props '${inputProps}' --crf ${crf} --codec h264`,
            { cwd: ROOT, stdio: "pipe" }
          );
          console.log(`  Clip ${i + 1} (${type}): rendered → ${outputPath}`);
        } catch {
          console.error(`  Clip ${i + 1} (${type}): render failed`);
        }
      }
    }

    console.log("\nPipeline complete.");
  });

// ── direct ──────────────────────────────────────────────

program
  .command("direct")
  .description("Generate choreographed video capture scripts from a .choreography.ts file")
  .requiredOption(
    "-s, --script <path>",
    "Choreography script path (e.g., the-origin/tiktok-chase-sequence)"
  )
  .option("--print-server", "Output the generated server Luau script")
  .option("--print-camera", "Output the generated camera Luau script")
  .option("--print-plan", "Output the execution plan (default)")
  .action(async (opts) => {
    const {
      generateServerScript,
      generateCameraScript,
      generateExecutionPlan,
      formatExecutionPlan,
    } = await import("./choreography/mcp-director.js");

    // Resolve choreography file
    const scriptPath = resolve(
      ROOT,
      "src",
      "choreography",
      "scripts",
      `${opts.script}.choreography.ts`
    );

    if (!existsSync(scriptPath)) {
      console.error(`Choreography not found: ${scriptPath}`);
      console.error(
        "\nAvailable choreographies:"
      );
      // List available scripts
      const { readdirSync } = await import("node:fs");
      const scriptDir = resolve(ROOT, "src", "choreography", "scripts");
      if (existsSync(scriptDir)) {
        for (const game of readdirSync(scriptDir)) {
          const gameDir = resolve(scriptDir, game);
          try {
            for (const file of readdirSync(gameDir)) {
              if (file.endsWith(".choreography.ts")) {
                const name = file.replace(".choreography.ts", "");
                console.error(`  ${game}/${name}`);
              }
            }
          } catch {
            // skip non-directories
          }
        }
      }
      process.exit(1);
    }

    // Dynamic import of the choreography module
    const mod = await import(scriptPath);
    const choreography = mod.default;

    if (!choreography || !choreography.id) {
      console.error("Invalid choreography file — must export a default Choreography object.");
      process.exit(1);
    }

    if (opts.printServer) {
      const script = generateServerScript(choreography);
      console.log(script);
      console.error(
        `\n── ${script.length} characters. Inject via run_script_in_play_mode. ──`
      );
    } else if (opts.printCamera) {
      const script = generateCameraScript(choreography);
      console.log(script);
      console.error(
        `\n── ${script.length} characters. Inject into StarterPlayerScripts before playtest. ──`
      );
    } else {
      // Default: print execution plan
      const plan = generateExecutionPlan(choreography);
      console.log(formatExecutionPlan(plan));
    }
  });

program.parse();
