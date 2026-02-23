/**
 * Subtitles — voiceover text renderer synced to audio timing.
 * Supports word-by-word reveal and fear-tinted styling.
 */

import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
} from "remotion";
import { COLORS, FONTS } from "../themes/horror.js";

export interface SubtitleSegment {
  text: string;
  startFrame: number;
  endFrame: number;
}

export interface SubtitlesProps {
  segments: SubtitleSegment[];
  position?: "bottom" | "center" | "top";
  fontSize?: number;
  maxWidth?: number;
  style?: "standard" | "whisper" | "shout" | "corrupted";
}

export const Subtitles: React.FC<SubtitlesProps> = ({
  segments,
  position = "bottom",
  fontSize = 32,
  maxWidth = 80, // percentage of width
  style = "standard",
}) => {
  const frame = useCurrentFrame();

  const active = segments.find(
    (s) => frame >= s.startFrame && frame < s.endFrame
  );

  if (!active) return null;

  const progress = interpolate(
    frame,
    [active.startFrame, active.endFrame],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Fade in/out
  const fadeIn = interpolate(
    frame,
    [active.startFrame, active.startFrame + 5],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const fadeOut = interpolate(
    frame,
    [active.endFrame - 5, active.endFrame],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );
  const opacity = Math.min(fadeIn, fadeOut);

  const positionStyle: React.CSSProperties =
    position === "bottom"
      ? { bottom: "10%", left: "50%", transform: "translateX(-50%)" }
      : position === "top"
        ? { top: "10%", left: "50%", transform: "translateX(-50%)" }
        : {
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
          };

  const textStyle = getTextStyle(style, fontSize);

  return (
    <div
      style={{
        position: "absolute",
        ...positionStyle,
        maxWidth: `${maxWidth}%`,
        textAlign: "center",
        opacity,
        zIndex: 100,
      }}
    >
      <span
        style={{
          ...textStyle,
          padding: "8px 16px",
          backgroundColor: "rgba(0, 0, 0, 0.7)",
          borderRadius: 4,
          display: "inline-block",
        }}
      >
        {active.text}
      </span>
    </div>
  );
};

function getTextStyle(
  style: string,
  fontSize: number
): React.CSSProperties {
  switch (style) {
    case "whisper":
      return {
        fontFamily: FONTS.primary,
        fontSize: fontSize * 0.85,
        color: COLORS.textMuted,
        fontStyle: "italic",
        letterSpacing: "0.05em",
      };
    case "shout":
      return {
        fontFamily: FONTS.display,
        fontSize: fontSize * 1.3,
        color: COLORS.danger,
        fontWeight: "bold",
        textTransform: "uppercase",
        textShadow: `0 0 10px ${COLORS.danger}`,
      };
    case "corrupted":
      return {
        fontFamily: FONTS.mono,
        fontSize,
        color: COLORS.corruption,
        textShadow: `2px 0 ${COLORS.glitch}, -2px 0 ${COLORS.accent}`,
        letterSpacing: "0.1em",
      };
    default:
      return {
        fontFamily: FONTS.primary,
        fontSize,
        color: COLORS.text,
        fontWeight: 500,
      };
  }
}

/**
 * Helper to generate subtitle segments from text and audio duration.
 * Splits text into sentence-sized chunks timed to audio.
 */
export function generateSubtitleSegments(
  text: string,
  audioDurationFrames: number,
  startFrame: number = 0
): SubtitleSegment[] {
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
  const totalWords = text.split(/\s+/).length;
  const framesPerWord = audioDurationFrames / totalWords;

  const segments: SubtitleSegment[] = [];
  let currentFrame = startFrame;

  for (const sentence of sentences) {
    const wordCount = sentence.trim().split(/\s+/).length;
    const duration = Math.max(15, Math.round(wordCount * framesPerWord));

    segments.push({
      text: sentence.trim(),
      startFrame: currentFrame,
      endFrame: currentFrame + duration,
    });

    currentFrame += duration;
  }

  return segments;
}
