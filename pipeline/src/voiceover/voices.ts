/**
 * Voice profile configs for ElevenLabs TTS per content type.
 * Voice IDs are from ElevenLabs voice library.
 */

import type { ContentType } from "../types.js";

export interface VoiceProfile {
  voiceId: string;
  name: string;
  stability: number; // 0-1 (lower = more expressive)
  similarityBoost: number; // 0-1
  style: number; // 0-1 (style exaggeration)
  speakerBoost: boolean;
  description: string;
}

/**
 * Voice profiles per content type.
 * Update voiceIds with your ElevenLabs account's cloned/selected voices.
 */
export const VOICE_PROFILES: Record<ContentType, VoiceProfile> = {
  tiktok: {
    voiceId: "pNInz6obpgDQGcFmaJgB", // "Adam" — calm, narratory
    name: "Narrator",
    stability: 0.35, // more expressive
    similarityBoost: 0.75,
    style: 0.5,
    speakerBoost: true,
    description: "Calm narrator whispering commentary over gameplay",
  },
  raw: {
    voiceId: "pNInz6obpgDQGcFmaJgB",
    name: "Narrator",
    stability: 0.5,
    similarityBoost: 0.8,
    style: 0.3,
    speakerBoost: false,
    description: "Minimal VO — mostly just intro/outro for raw footage",
  },
  trailer: {
    voiceId: "ErXwobaYiN019PkySvjV", // "Antoni" — deep, cinematic
    name: "Cinematic",
    stability: 0.6, // stable for cinematic tone
    similarityBoost: 0.85,
    style: 0.7, // dramatic
    speakerBoost: true,
    description: "Deep cinematic voice for trailer taglines",
  },
  arg: {
    voiceId: "VR6AewLTigWG4xSOukaG", // "Arnold" — gruff, distorted
    name: "Corrupted",
    stability: 0.15, // maximally unstable for glitchy effect
    similarityBoost: 0.5,
    style: 0.9,
    speakerBoost: false,
    description: "Unstable, glitchy voice for ARG/PA announcements",
  },
  devdiary: {
    voiceId: "pNInz6obpgDQGcFmaJgB",
    name: "Developer",
    stability: 0.7, // casual, clear
    similarityBoost: 0.8,
    style: 0.2,
    speakerBoost: true,
    description: "Clear developer commentary for dev diary videos",
  },
};

/**
 * Get the voice profile for a content type, with optional overrides.
 */
export function getVoiceProfile(
  contentType: ContentType,
  overrides?: Partial<VoiceProfile>
): VoiceProfile {
  return { ...VOICE_PROFILES[contentType], ...overrides };
}
