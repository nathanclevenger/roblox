/**
 * VO script generator — creates voiceover text from clip metadata and templates.
 * Each content type has its own narration style.
 */

import type { ClipCandidate, ContentType, FearTier } from "../types.js";

/**
 * Generate voiceover text for a clip based on content type.
 */
export function generateScript(
  clip: ClipCandidate,
  contentType: ContentType
): string {
  switch (contentType) {
    case "tiktok":
      return generateTikTokScript(clip);
    case "raw":
      return generateRawScript(clip);
    case "trailer":
      return generateTrailerScript(clip);
    case "arg":
      return generateARGScript(clip);
    case "devdiary":
      return generateDevDiaryScript(clip);
  }
}

/**
 * TikTok/Shorts — whispered narration building tension.
 */
function generateTikTokScript(clip: ClipCandidate): string {
  const lines: string[] = [];

  // Opener based on highest-impact tag
  if (clip.tags.includes("near-miss")) {
    const distance = getClosestDistance(clip);
    lines.push(
      `The entity is ${distance} studs away. He has no idea.`
    );
  } else if (clip.tags.includes("chase")) {
    lines.push("This is the moment everything goes wrong.");
  } else if (clip.tags.includes("death")) {
    lines.push("Watch what happens next.");
  } else if (clip.tags.includes("hiding")) {
    lines.push("Don't. Move.");
  } else {
    lines.push("Something isn't right.");
  }

  // Mid-clip tension based on fear timeline
  const peakFear = getPeakFear(clip);
  if (peakFear === "Proximity") {
    lines.push("It's right there.");
  } else if (peakFear === "Panic") {
    lines.push("There's nowhere to hide.");
  }

  // Closer
  if (clip.tags.includes("death")) {
    lines.push("And that's how it ends.");
  } else if (clip.tags.includes("escape")) {
    lines.push("Somehow, they made it out.");
  }

  return lines.join(" ");
}

/**
 * Raw footage — minimal VO, just intro/outro.
 */
function generateRawScript(clip: ClipCandidate): string {
  if (clip.tags.includes("chase")) {
    return "Unedited footage recovered from a playtest session.";
  }
  if (clip.tags.includes("death")) {
    return "This is exactly how it happened.";
  }
  return ""; // No VO for most raw clips
}

/**
 * Trailer — cinematic taglines.
 */
function generateTrailerScript(clip: ClipCandidate): string {
  const taglines = [
    "In the dark, something watches.",
    "It learns. It adapts. It remembers.",
    "You were never meant to leave.",
    "Every hiding spot. Every escape route. It knows.",
    "The Origin.",
  ];

  // Select taglines based on clip content
  const lines: string[] = [];

  if (clip.tags.includes("chase")) {
    lines.push("You can run.");
  }
  if (clip.tags.includes("hiding")) {
    lines.push("You can hide.");
  }
  if (clip.tags.includes("death")) {
    lines.push("But it always finds you.");
  }

  // Always end with the game title
  lines.push("The Origin.");

  return lines.join(" ");
}

/**
 * ARG — corrupted/distorted text for in-universe documents.
 */
function generateARGScript(clip: ClipCandidate): string {
  const fragments = [
    "Subject response... nominal.",
    "Containment breach detected in sector seven.",
    "All personnel evacuate to designated safe zones.",
    "The entity has... adapted.",
    "Recording corrupted. Data recovery... failed.",
    "Patient zero. File redacted.",
    "Do not look directly at... [STATIC]",
    "They told us it was contained.",
  ];

  // Pick 2-3 fragments based on clip score as pseudo-random seed
  const seed = Math.floor(clip.score * 100);
  const selected: string[] = [];
  for (let i = 0; i < 3; i++) {
    const idx = (seed + i * 7) % fragments.length;
    selected.push(fragments[idx]);
  }

  return selected.join(" ");
}

/**
 * Dev Diary — casual developer commentary.
 */
function generateDevDiaryScript(clip: ClipCandidate): string {
  const lines: string[] = [];

  if (clip.tags.includes("chase")) {
    lines.push(
      "So here you can see the entity transitioning into chase state."
    );
    lines.push(
      "The AI uses line-of-sight checks combined with an eight second memory buffer."
    );
  } else if (clip.tags.includes("hiding")) {
    lines.push(
      "This is the hiding system in action."
    );
    lines.push(
      "The entity actually checks hiding spots it hasn't visited recently, so the player can't just use the same spot."
    );
  } else if (clip.tags.includes("fear-spike")) {
    lines.push(
      "Watch the fear intensity here — it jumps from safe to panic in under three seconds."
    );
  } else {
    lines.push(
      "Let me walk you through what's happening in this clip."
    );
  }

  return lines.join(" ");
}

// -- Helpers --

function getClosestDistance(clip: ClipCandidate): number {
  if (clip.fearTimeline.length === 0) return 50;
  const closest = clip.fearTimeline.reduce(
    (min, p) => Math.min(min, p.distance),
    Infinity
  );
  return Math.round(closest);
}

function getPeakFear(clip: ClipCandidate): FearTier {
  const tierOrder: FearTier[] = [
    "Safe",
    "Unease",
    "Dread",
    "Panic",
    "Proximity",
  ];
  let peak = 0;
  for (const point of clip.fearTimeline) {
    const idx = tierOrder.indexOf(point.tier);
    if (idx > peak) peak = idx;
  }
  return tierOrder[peak];
}
