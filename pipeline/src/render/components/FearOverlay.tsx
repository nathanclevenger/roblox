/**
 * FearOverlay — pulsing vignette/border driven by fear tier timeline data.
 * Intensity ramps with proximity to the entity.
 */

import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
} from "remotion";
import type { FearTimelinePoint, FearTier } from "../../types.js";
import {
  FEAR_COLORS,
  FEAR_BORDER_WIDTHS,
  COLORS,
} from "../themes/horror.js";

export interface FearOverlayProps {
  timeline: FearTimelinePoint[];
  clipStartTime: number;
}

export const FearOverlay: React.FC<FearOverlayProps> = ({
  timeline,
  clipStartTime,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const currentTime = clipStartTime + frame / fps;

  // Find the current fear state by interpolating timeline
  const current = getCurrentFear(timeline, currentTime);
  const { tier, intensity } = current;

  // Pulse effect — faster at higher intensity
  const pulseFreq = 0.5 + intensity * 2; // 0.5Hz at Safe → 2.5Hz at Proximity
  const pulsePhase = Math.sin(frame * pulseFreq * (Math.PI / fps));
  const pulseAmount = 0.15 * intensity;
  const effectiveIntensity = intensity + pulsePhase * pulseAmount;

  const borderWidth = FEAR_BORDER_WIDTHS[tier];
  const borderColor = FEAR_COLORS[tier];

  // Vignette gets heavier with fear
  const vignetteSize = interpolate(effectiveIntensity, [0, 1], [80, 40], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {/* Pulsing vignette */}
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at center, transparent ${vignetteSize}%, ${COLORS.vignette} 100%)`,
          opacity: 0.3 + effectiveIntensity * 0.5,
        }}
      />

      {/* Colored border glow */}
      {borderWidth > 0 && (
        <AbsoluteFill
          style={{
            boxShadow: `inset 0 0 ${borderWidth * 3}px ${borderWidth}px ${borderColor}`,
            opacity: 0.6 + pulsePhase * 0.2,
          }}
        />
      )}

      {/* Red tint at high fear */}
      {intensity > 0.6 && (
        <AbsoluteFill
          style={{
            backgroundColor: COLORS.danger,
            opacity: (intensity - 0.6) * 0.15,
            mixBlendMode: "multiply",
          }}
        />
      )}
    </AbsoluteFill>
  );
};

function getCurrentFear(
  timeline: FearTimelinePoint[],
  time: number
): { tier: FearTier; intensity: number } {
  if (timeline.length === 0) {
    return { tier: "Safe", intensity: 0 };
  }

  // Find the two surrounding points and lerp
  let before = timeline[0];
  let after = timeline[timeline.length - 1];

  for (let i = 0; i < timeline.length - 1; i++) {
    if (timeline[i].time <= time && timeline[i + 1].time > time) {
      before = timeline[i];
      after = timeline[i + 1];
      break;
    }
  }

  if (time <= before.time) return { tier: before.tier, intensity: before.intensity };
  if (time >= after.time) return { tier: after.tier, intensity: after.intensity };

  // Lerp intensity between points
  const t = (time - before.time) / (after.time - before.time);
  const intensity = before.intensity + (after.intensity - before.intensity) * t;

  // Use the tier of whichever point we're closer to
  const tier = t < 0.5 ? before.tier : after.tier;

  return { tier, intensity };
}
