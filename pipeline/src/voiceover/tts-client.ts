/**
 * ElevenLabs TTS client — direct API v1 calls for local voiceover generation.
 * Uses the REST API directly (not the Cloudflare Worker from platform repo).
 */

import { writeFile, mkdir } from "node:fs/promises";
import { existsSync, createReadStream } from "node:fs";
import { resolve, dirname } from "node:path";
import { createHash } from "node:crypto";
import type { VoiceoverResult } from "../types.js";
import type { VoiceProfile } from "./voices.js";

const ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1";

function getApiKey(): string {
  const key = process.env.ELEVENLABS_API_KEY;
  if (!key) {
    throw new Error(
      "ELEVENLABS_API_KEY environment variable not set. " +
        "Get your API key from https://elevenlabs.io/app/settings/api-keys"
    );
  }
  return key;
}

/**
 * Synthesize speech from text using ElevenLabs API.
 */
export async function synthesize(
  text: string,
  voice: VoiceProfile,
  outputPath: string,
  options: {
    modelId?: string;
    outputFormat?: string;
  } = {}
): Promise<VoiceoverResult> {
  const {
    modelId = "eleven_multilingual_v2",
    outputFormat = "mp3_44100_128",
  } = options;

  // Check cache
  const cacheKey = getCacheKey(text, voice.voiceId, voice.stability);
  const cacheDir = dirname(outputPath);
  if (!existsSync(cacheDir)) {
    await mkdir(cacheDir, { recursive: true });
  }

  if (existsSync(outputPath)) {
    console.log(`Using cached voiceover: ${outputPath}`);
    const duration = estimateDuration(text);
    return { audioPath: outputPath, duration };
  }

  const apiKey = getApiKey();
  const url = `${ELEVENLABS_API_URL}/text-to-speech/${voice.voiceId}`;

  console.log(`Generating voiceover (${text.length} chars, voice: ${voice.name})...`);

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "xi-api-key": apiKey,
      Accept: "audio/mpeg",
    },
    body: JSON.stringify({
      text,
      model_id: modelId,
      output_format: outputFormat,
      voice_settings: {
        stability: voice.stability,
        similarity_boost: voice.similarityBoost,
        style: voice.style,
        use_speaker_boost: voice.speakerBoost,
      },
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `ElevenLabs API error (${response.status}): ${body}`
    );
  }

  const audioBuffer = Buffer.from(await response.arrayBuffer());
  await writeFile(outputPath, audioBuffer);

  const duration = estimateDuration(text);
  console.log(
    `Voiceover saved: ${outputPath} (${(audioBuffer.length / 1024).toFixed(1)} KB, ~${duration.toFixed(1)}s)`
  );

  return { audioPath: outputPath, duration };
}

/**
 * Estimate audio duration from text.
 * Average speaking rate ~150 WPM for narration.
 */
function estimateDuration(text: string): number {
  const words = text.split(/\s+/).filter(Boolean).length;
  const wpm = 150;
  return Math.max(1, (words / wpm) * 60);
}

/**
 * Generate a cache key from text and voice settings.
 */
function getCacheKey(
  text: string,
  voiceId: string,
  stability: number
): string {
  const hash = createHash("md5")
    .update(`${text}-${voiceId}-${stability}`)
    .digest("hex")
    .slice(0, 12);
  return hash;
}
