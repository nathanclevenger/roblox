/**
 * HorrorGlitch — max-intensity glitch effect for ARG content.
 * Combines RGB split, scan lines, frame displacement, and corruption artifacts.
 */

import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  random,
} from "remotion";
import { COLORS } from "../themes/horror.js";

export interface HorrorGlitchProps {
  children: React.ReactNode;
  /** Base intensity 0-1 (default 0.7) */
  intensity?: number;
  /** Random burst probability per frame 0-1 (default 0.1) */
  burstChance?: number;
  /** Seed for deterministic randomness */
  seed?: string;
}

export const HorrorGlitch: React.FC<HorrorGlitchProps> = ({
  children,
  intensity = 0.7,
  burstChance = 0.1,
  seed = "horror",
}) => {
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();

  // Determine if this frame has a burst
  const isBurst = random(`${seed}-burst-${frame}`) < burstChance;
  const burstMultiplier = isBurst ? 2.5 : 1;
  const effectiveIntensity = Math.min(1, intensity * burstMultiplier);

  // RGB channel offsets
  const rgbOffset = effectiveIntensity * 15;
  const redX = random(`${seed}-rx-${frame}`) * rgbOffset - rgbOffset / 2;
  const redY = random(`${seed}-ry-${frame}`) * rgbOffset * 0.3;
  const blueX = -redX * 0.8;
  const blueY = random(`${seed}-by-${frame}`) * rgbOffset * 0.3;

  // Horizontal displacement bars
  const numBars = isBurst ? 3 + Math.floor(random(`${seed}-bars-${frame}`) * 5) : 0;
  const bars = Array.from({ length: numBars }, (_, i) => ({
    y: random(`${seed}-bar-y-${frame}-${i}`) * height,
    height: 1 + random(`${seed}-bar-h-${frame}-${i}`) * 10,
    offset: (random(`${seed}-bar-o-${frame}-${i}`) - 0.5) * 40 * effectiveIntensity,
    opacity: 0.3 + random(`${seed}-bar-a-${frame}-${i}`) * 0.5,
  }));

  // Skew distortion
  const skew = isBurst
    ? (random(`${seed}-skew-${frame}`) - 0.5) * 8 * effectiveIntensity
    : 0;

  // Brightness flash on burst
  const brightness = isBurst ? 1 + random(`${seed}-bright-${frame}`) * 0.5 : 1;

  return (
    <AbsoluteFill>
      {/* Base layer with skew */}
      <AbsoluteFill
        style={{
          transform: `skewX(${skew}deg)`,
          filter: `brightness(${brightness})`,
        }}
      >
        {/* Red channel */}
        <AbsoluteFill
          style={{
            transform: `translate(${redX}px, ${redY}px)`,
            mixBlendMode: "screen",
            opacity: 0.9,
          }}
        >
          <div
            style={{
              filter: "sepia(1) hue-rotate(-50deg) saturate(5)",
              width: "100%",
              height: "100%",
            }}
          >
            {children}
          </div>
        </AbsoluteFill>

        {/* Green channel (base) */}
        <AbsoluteFill style={{ mixBlendMode: "screen" }}>
          <div
            style={{
              filter: "sepia(1) hue-rotate(50deg) saturate(3)",
              width: "100%",
              height: "100%",
            }}
          >
            {children}
          </div>
        </AbsoluteFill>

        {/* Blue channel */}
        <AbsoluteFill
          style={{
            transform: `translate(${blueX}px, ${blueY}px)`,
            mixBlendMode: "screen",
            opacity: 0.9,
          }}
        >
          <div
            style={{
              filter: "sepia(1) hue-rotate(180deg) saturate(3)",
              width: "100%",
              height: "100%",
            }}
          >
            {children}
          </div>
        </AbsoluteFill>
      </AbsoluteFill>

      {/* Scan lines */}
      <AbsoluteFill
        style={{
          background: `repeating-linear-gradient(
            0deg,
            rgba(0, 0, 0, ${0.05 + effectiveIntensity * 0.1}),
            rgba(0, 0, 0, ${0.05 + effectiveIntensity * 0.1}) 1px,
            transparent 1px,
            transparent 3px
          )`,
          pointerEvents: "none",
        }}
      />

      {/* Displacement bars */}
      {bars.map((bar, i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            top: bar.y,
            left: 0,
            width: "100%",
            height: bar.height,
            transform: `translateX(${bar.offset}px)`,
            backgroundColor: `rgba(255, 255, 255, ${bar.opacity * 0.15})`,
            backdropFilter: `brightness(${1 + effectiveIntensity * 0.5}) hue-rotate(${random(`${seed}-hue-${frame}-${i}`) * 180}deg)`,
            pointerEvents: "none",
          }}
        />
      ))}

      {/* Corruption text fragments on burst */}
      {isBurst && random(`${seed}-text-${frame}`) > 0.5 && (
        <div
          style={{
            position: "absolute",
            top: `${random(`${seed}-ty-${frame}`) * 80 + 10}%`,
            left: `${random(`${seed}-tx-${frame}`) * 60 + 20}%`,
            fontFamily: "'Courier New', monospace",
            fontSize: 12 + random(`${seed}-ts-${frame}`) * 14,
            color: COLORS.corruption,
            opacity: 0.6,
            textShadow: `0 0 4px ${COLORS.corruption}`,
            pointerEvents: "none",
          }}
        >
          {getCorruptionText(frame, seed)}
        </div>
      )}
    </AbsoluteFill>
  );
};

const CORRUPTION_FRAGMENTS = [
  "ERR_MEMORY_FAULT",
  "0xDEAD",
  "DATA_CORRUPTED",
  "SIGNAL_LOST",
  "???",
  "HELP",
  "IT SEES YOU",
  "NaN",
  "REDACTED",
  "SECTOR_7",
  "CONTAINMENT_FAILED",
];

function getCorruptionText(frame: number, seed: string): string {
  const idx = Math.floor(random(`${seed}-frag-${frame}`) * CORRUPTION_FRAGMENTS.length);
  return CORRUPTION_FRAGMENTS[idx];
}
