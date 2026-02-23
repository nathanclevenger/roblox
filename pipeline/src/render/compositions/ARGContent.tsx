/**
 * ARGContent — Glitched/corrupted clips (1080x1080, 1:1) for ARG marketing.
 * Heavy corruption, data fragments, in-universe PA announcements.
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
  random,
} from "remotion";
import { HorrorGlitch } from "../components/HorrorGlitch.js";
import { VHSOverlay } from "../components/VHSOverlay.js";
import { Subtitles } from "../components/Subtitles.js";
import { COLORS, FONTS } from "../themes/horror.js";

export interface ARGContentProps {
  videoSrc?: string;
  voiceoverSrc?: string;
  voiceoverText?: string;
  voiceoverDuration?: number;
  corruptionLevel?: number;
  fileId?: string;
}

export const ARGContent: React.FC<ARGContentProps> = ({
  videoSrc = "",
  voiceoverSrc,
  voiceoverText,
  voiceoverDuration = 5,
  corruptionLevel = 0.6,
  fileId = "SUBJ-0047",
}) => {
  const { durationInFrames, fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // Pulsing corruption — increases over duration
  const timeProgress = frame / durationInFrames;
  const dynamicCorruption =
    corruptionLevel * (0.5 + timeProgress * 0.5);
  const burstChance = 0.05 + timeProgress * 0.1;

  // Generate subtitles with corrupted style
  const subtitleSegments = voiceoverText
    ? [
        {
          text: voiceoverText,
          startFrame: Math.round(fps * 0.3),
          endFrame: Math.round(voiceoverDuration * fps),
        },
      ]
    : [];

  // Classification header
  const classificationOpacity = interpolate(
    frame,
    [0, 15, durationInFrames - 15, durationInFrames],
    [0, 0.8, 0.8, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Static burst frames
  const isStaticBurst =
    random(`static-${frame}`) > 0.95 && frame > 10;

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      {/* Main footage with heavy glitch */}
      <HorrorGlitch
        intensity={dynamicCorruption}
        burstChance={burstChance}
        seed={`arg-${fileId}`}
      >
        <AbsoluteFill>
          <Video
            src={videoSrc}
            style={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
              filter: `saturate(0.3) contrast(1.3) brightness(0.8) hue-rotate(${timeProgress * 20}deg)`,
            }}
          />
        </AbsoluteFill>
      </HorrorGlitch>

      {/* VHS overlay with aggressive settings */}
      <VHSOverlay
        showTimestamp={false}
        showRecIndicator={false}
        trackingGlitches
        noiseIntensity={0.06}
      />

      {/* Static burst overlay */}
      {isStaticBurst && (
        <AbsoluteFill
          style={{
            backgroundColor: `rgba(255, 255, 255, ${random(`static-a-${frame}`) * 0.3})`,
            mixBlendMode: "overlay",
          }}
        />
      )}

      {/* Classification header */}
      <div
        style={{
          position: "absolute",
          top: 20,
          left: 0,
          right: 0,
          textAlign: "center",
          opacity: classificationOpacity,
        }}
      >
        <div
          style={{
            fontFamily: FONTS.mono,
            fontSize: 11,
            color: COLORS.accent,
            letterSpacing: "0.3em",
            textTransform: "uppercase",
          }}
        >
          CLASSIFIED // FILE: {fileId} // CLEARANCE: LEVEL 5
        </div>
        <div
          style={{
            width: "80%",
            height: 1,
            backgroundColor: COLORS.accentDim,
            margin: "8px auto 0",
            opacity: 0.5,
          }}
        />
      </div>

      {/* Data corruption artifacts at bottom */}
      <div
        style={{
          position: "absolute",
          bottom: 16,
          left: 16,
          right: 16,
          fontFamily: FONTS.mono,
          fontSize: 10,
          color: COLORS.corruption,
          opacity: 0.4 + timeProgress * 0.3,
          lineHeight: 1.4,
          textShadow: `0 0 3px ${COLORS.corruption}`,
        }}
      >
        {generateDataFragment(frame)}
      </div>

      {/* VO subtitles */}
      <Subtitles
        segments={subtitleSegments}
        position="center"
        fontSize={24}
        style="corrupted"
      />

      {/* Audio */}
      {voiceoverSrc && (
        <Audio src={voiceoverSrc} volume={0.7} />
      )}
    </AbsoluteFill>
  );
};

function generateDataFragment(frame: number): string {
  const fragments = [
    "0x4F524947 0x494E2020 0x50524F4A 0x45435420",
    "PACKET_LOSS: 47.3% | SIGNAL: DEGRADED | STATUS: UNKNOWN",
    "ERR: MEMORY_ADDR_VIOLATION at 0xDEAD0047 [SECTOR 7]",
    "SUBJECT_RESPONSE: ███████████ | THREAT_LEVEL: CRITICAL",
    "LOG_TIMESTAMP: ████-██-██T██:██:██Z | RECORDER: [REDACTED]",
  ];
  const idx = Math.floor(frame / 30) % fragments.length;
  return fragments[idx];
}
