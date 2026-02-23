/**
 * Trailer — YouTube composition (1920x1080, 16:9).
 * Multi-clip montage with cinematic VO and music.
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
  Easing,
} from "remotion";
import { FearOverlay } from "../components/FearOverlay.js";
import { Subtitles, generateSubtitleSegments } from "../components/Subtitles.js";
import { GameLogo } from "../components/GameLogo.js";
import { Vignette, Flash } from "../vendor/VisualEffects.js";
import { COLORS } from "../themes/horror.js";
import type { FearTimelinePoint } from "../../types.js";

export interface TrailerClipSegment {
  videoSrc: string;
  durationInFrames: number;
  fearTimeline: FearTimelinePoint[];
  clipStartTime: number;
}

export interface TrailerProps {
  clips?: TrailerClipSegment[];
  voiceoverSrc?: string;
  voiceoverText?: string;
  voiceoverDuration?: number;
  musicSrc?: string;
  musicVolume?: number;
}

export const Trailer: React.FC<TrailerProps> = ({
  clips = [],
  voiceoverSrc,
  voiceoverText,
  voiceoverDuration = 10,
  musicSrc,
  musicVolume = 0.3,
}) => {
  const { durationInFrames, fps } = useVideoConfig();
  const frame = useCurrentFrame();

  // Calculate segment positions
  const logoDuration = 120; // 4 seconds
  const totalClipFrames = clips.reduce((sum, c) => sum + c.durationInFrames, 0);
  const transitionFrames = 10; // per transition

  // Generate subtitles
  const subtitleSegments = voiceoverText
    ? generateSubtitleSegments(
        voiceoverText,
        Math.round(voiceoverDuration * fps),
        30 // delay 1s
      )
    : [];

  let offset = 0;

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      {/* Opening black + title fade */}
      <Sequence durationInFrames={60}>
        <AbsoluteFill
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div
            style={{
              fontFamily: "'Courier New', monospace",
              fontSize: 16,
              color: COLORS.textMuted,
              opacity: interpolate(frame, [0, 30, 50, 60], [0, 0.8, 0.8, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
              letterSpacing: "0.3em",
              textTransform: "uppercase",
            }}
          >
            [CLASSIFIED FOOTAGE]
          </div>
        </AbsoluteFill>
      </Sequence>

      {/* Clip montage */}
      {clips.map((clip, i) => {
        const start = 60 + offset;
        offset += clip.durationInFrames;

        return (
          <Sequence
            key={i}
            from={start}
            durationInFrames={clip.durationInFrames}
          >
            <AbsoluteFill>
              <Video
                src={clip.videoSrc}
                style={{
                  width: "100%",
                  height: "100%",
                  objectFit: "cover",
                }}
              />
              <FearOverlay
                timeline={clip.fearTimeline}
                clipStartTime={clip.clipStartTime}
              />
              <Vignette intensity={0.4} />

              {/* Flash on cut */}
              {i > 0 && <Flash color="#FFFFFF" duration={2} intensity={0.3} />}
            </AbsoluteFill>
          </Sequence>
        );
      })}

      {/* Subtitles over everything */}
      <Subtitles
        segments={subtitleSegments}
        position="bottom"
        fontSize={36}
        style="standard"
      />

      {/* End card */}
      <Sequence
        from={durationInFrames - logoDuration}
        durationInFrames={logoDuration}
      >
        <GameLogo
          animationDuration={45}
          showCTA
          ctaText="Coming soon to Roblox"
          glitchReveal
        />
      </Sequence>

      {/* Audio tracks */}
      {voiceoverSrc && <Audio src={voiceoverSrc} volume={0.9} />}
      {musicSrc && <Audio src={musicSrc} volume={musicVolume} />}
    </AbsoluteFill>
  );
};
