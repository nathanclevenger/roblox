/**
 * DevDiary — PiP gameplay + code/diagram overlays (1920x1080, 16:9).
 * Developer commentary with technical overlays.
 */

import React from "react";
import {
  AbsoluteFill,
  Video,
  Audio,
  Sequence,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
} from "remotion";
import { Subtitles, generateSubtitleSegments } from "../components/Subtitles.js";
import { GameLogo } from "../components/GameLogo.js";
import { Vignette } from "../vendor/VisualEffects.js";
import { COLORS, FONTS } from "../themes/horror.js";
import type { FearTimelinePoint, FearTier } from "../../types.js";
import { FEAR_COLORS } from "../themes/horror.js";

export interface DevDiaryProps {
  videoSrc?: string;
  voiceoverSrc?: string;
  voiceoverText?: string;
  voiceoverDuration?: number;
  fearTimeline?: FearTimelinePoint[];
  clipStartTime?: number;
  codeSnippet?: string;
  codeLabel?: string;
  annotations?: Array<{
    text: string;
    startFrame: number;
    endFrame: number;
  }>;
}

export const DevDiary: React.FC<DevDiaryProps> = ({
  videoSrc = "",
  voiceoverSrc,
  voiceoverText,
  voiceoverDuration = 10,
  fearTimeline = [],
  clipStartTime = 0,
  codeSnippet,
  codeLabel,
  annotations = [],
}) => {
  const { durationInFrames, fps, width, height } = useVideoConfig();
  const frame = useCurrentFrame();

  const logoDuration = 90;
  const mainDuration = durationInFrames - logoDuration;

  // Subtitle segments
  const subtitleSegments = voiceoverText
    ? generateSubtitleSegments(
        voiceoverText,
        Math.round(voiceoverDuration * fps),
        15
      )
    : [];

  // Code panel slide-in
  const codePanelWidth = codeSnippet ? 500 : 0;
  const codePanelX = codeSnippet
    ? interpolate(frame, [30, 50], [codePanelWidth, 0], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })
    : codePanelWidth;

  return (
    <AbsoluteFill style={{ backgroundColor: "#0a0a0a" }}>
      {/* Main content area */}
      <Sequence durationInFrames={mainDuration}>
        <AbsoluteFill>
          {/* Gameplay video — positioned as PiP when code is showing */}
          <div
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              right: codePanelWidth > 0 ? codePanelWidth : 0,
              bottom: 0,
              overflow: "hidden",
            }}
          >
            <Video
              src={videoSrc}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
              }}
            />
            <Vignette intensity={0.25} />
          </div>

          {/* Code panel (right side) */}
          {codeSnippet && (
            <div
              style={{
                position: "absolute",
                top: 0,
                right: 0,
                width: codePanelWidth,
                height: "100%",
                transform: `translateX(${codePanelX}px)`,
                backgroundColor: "#1e1e1e",
                borderLeft: `2px solid ${COLORS.accentDim}`,
                display: "flex",
                flexDirection: "column",
              }}
            >
              {/* Code panel header */}
              {codeLabel && (
                <div
                  style={{
                    padding: "12px 16px",
                    backgroundColor: "#252526",
                    borderBottom: "1px solid #3c3c3c",
                    fontFamily: FONTS.mono,
                    fontSize: 12,
                    color: COLORS.textMuted,
                  }}
                >
                  {codeLabel}
                </div>
              )}

              {/* Code content */}
              <pre
                style={{
                  flex: 1,
                  padding: 16,
                  margin: 0,
                  fontFamily: FONTS.mono,
                  fontSize: 13,
                  lineHeight: 1.6,
                  color: "#d4d4d4",
                  overflow: "hidden",
                  whiteSpace: "pre-wrap",
                }}
              >
                {codeSnippet}
              </pre>
            </div>
          )}

          {/* Fear meter (small, bottom-left) */}
          {fearTimeline.length > 0 && (
            <FearMeter
              timeline={fearTimeline}
              clipStartTime={clipStartTime}
            />
          )}

          {/* Technical annotations */}
          {annotations.map((ann, i) => {
            if (frame < ann.startFrame || frame >= ann.endFrame) return null;
            const opacity = interpolate(
              frame,
              [ann.startFrame, ann.startFrame + 10, ann.endFrame - 10, ann.endFrame],
              [0, 1, 1, 0],
              { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
            );
            return (
              <div
                key={i}
                style={{
                  position: "absolute",
                  top: 60 + i * 40,
                  left: 20,
                  opacity,
                  fontFamily: FONTS.mono,
                  fontSize: 14,
                  color: COLORS.accent,
                  backgroundColor: "rgba(0, 0, 0, 0.7)",
                  padding: "6px 12px",
                  borderLeft: `3px solid ${COLORS.accent}`,
                  borderRadius: "0 4px 4px 0",
                }}
              >
                {ann.text}
              </div>
            );
          })}

          {/* Subtitles */}
          <Subtitles
            segments={subtitleSegments}
            position="bottom"
            fontSize={28}
            style="standard"
          />
        </AbsoluteFill>
      </Sequence>

      {/* Audio */}
      {voiceoverSrc && <Audio src={voiceoverSrc} volume={0.9} />}

      {/* End card */}
      <Sequence from={mainDuration} durationInFrames={logoDuration}>
        <GameLogo
          animationDuration={30}
          showCTA
          ctaText="Follow for more dev updates"
          glitchReveal={false}
        />
      </Sequence>
    </AbsoluteFill>
  );
};

/**
 * Small fear meter overlay for dev diary context.
 */
const FearMeter: React.FC<{
  timeline: FearTimelinePoint[];
  clipStartTime: number;
}> = ({ timeline, clipStartTime }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const currentTime = clipStartTime + frame / fps;

  // Find current fear level
  let currentTier: FearTier = "Safe";
  let currentIntensity = 0;
  for (const point of timeline) {
    if (point.time <= currentTime) {
      currentTier = point.tier;
      currentIntensity = point.intensity;
    }
  }

  return (
    <div
      style={{
        position: "absolute",
        bottom: 80,
        left: 20,
        display: "flex",
        alignItems: "center",
        gap: 8,
        backgroundColor: "rgba(0, 0, 0, 0.7)",
        padding: "8px 12px",
        borderRadius: 6,
      }}
    >
      <div
        style={{
          width: 8,
          height: 8,
          borderRadius: "50%",
          backgroundColor: FEAR_COLORS[currentTier],
          boxShadow: `0 0 6px ${FEAR_COLORS[currentTier]}`,
        }}
      />
      <span
        style={{
          fontFamily: FONTS.mono,
          fontSize: 12,
          color: FEAR_COLORS[currentTier],
        }}
      >
        FEAR: {currentTier.toUpperCase()} ({Math.round(currentIntensity * 100)}%)
      </span>
    </div>
  );
};
