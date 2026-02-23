/**
 * GameLogo — The Origin branding/CTA component for video outros.
 */

import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  Easing,
} from "remotion";
import { COLORS, FONTS } from "../themes/horror.js";

export interface GameLogoProps {
  /** Duration of the logo animation in frames */
  animationDuration?: number;
  /** Show CTA text below logo */
  showCTA?: boolean;
  ctaText?: string;
  /** Glitch effect on reveal */
  glitchReveal?: boolean;
}

export const GameLogo: React.FC<GameLogoProps> = ({
  animationDuration = 30,
  showCTA = true,
  ctaText = "Play now on Roblox",
  glitchReveal = true,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Main title fade-in
  const titleOpacity = interpolate(
    frame,
    [0, animationDuration * 0.4],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.out(Easing.ease) }
  );

  // Title scale punch
  const titleScale = interpolate(
    frame,
    [0, animationDuration * 0.3, animationDuration * 0.5],
    [0.8, 1.05, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // CTA fade-in (delayed)
  const ctaOpacity = interpolate(
    frame,
    [animationDuration * 0.5, animationDuration * 0.7],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Glitch flicker during reveal
  const isGlitching =
    glitchReveal && frame < animationDuration * 0.4 && frame % 3 === 0;

  // Subtle ambient pulse after reveal
  const pulse =
    frame > animationDuration
      ? Math.sin(frame * 0.05) * 0.03 + 1
      : 1;

  return (
    <AbsoluteFill
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: "rgba(0, 0, 0, 0.85)",
      }}
    >
      {/* Title */}
      <div
        style={{
          opacity: isGlitching ? titleOpacity * 0.3 : titleOpacity,
          transform: `scale(${titleScale * pulse})`,
          fontFamily: FONTS.display,
          fontSize: 72,
          color: COLORS.text,
          textTransform: "uppercase",
          letterSpacing: "0.15em",
          textShadow: `0 0 20px ${COLORS.accent}, 0 0 40px ${COLORS.accentDim}`,
          filter: isGlitching
            ? `hue-rotate(${Math.random() * 360}deg) brightness(2)`
            : "none",
        }}
      >
        THE ORIGIN
      </div>

      {/* Accent line */}
      <div
        style={{
          width: interpolate(
            frame,
            [animationDuration * 0.2, animationDuration * 0.5],
            [0, 200],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
          ),
          height: 2,
          backgroundColor: COLORS.accent,
          marginTop: 16,
          boxShadow: `0 0 10px ${COLORS.accent}`,
        }}
      />

      {/* CTA */}
      {showCTA && (
        <div
          style={{
            opacity: ctaOpacity,
            marginTop: 24,
            fontFamily: FONTS.primary,
            fontSize: 20,
            color: COLORS.textMuted,
            letterSpacing: "0.05em",
          }}
        >
          {ctaText}
        </div>
      )}
    </AbsoluteFill>
  );
};
