/**
 * GameplayClip — TikTok/Shorts composition (1080x1920, 9:16).
 * Highest volume output: gameplay footage + VO + fear overlay + subtitles.
 */

import React from "react";
import {
  AbsoluteFill,
  Video,
  Audio,
  useCurrentFrame,
  useVideoConfig,
  Sequence,
} from "remotion";
import { FearOverlay } from "../components/FearOverlay.js";
import { Subtitles, generateSubtitleSegments } from "../components/Subtitles.js";
import { GameLogo } from "../components/GameLogo.js";
import { Vignette } from "../vendor/VisualEffects.js";
import type { FearTimelinePoint } from "../../types.js";

export interface GameplayClipProps {
  videoSrc?: string;
  voiceoverSrc?: string;
  voiceoverText?: string;
  voiceoverDuration?: number;
  fearTimeline?: FearTimelinePoint[];
  clipStartTime?: number;
  showLogo?: boolean;
  logoDuration?: number;
}

export const GameplayClip: React.FC<GameplayClipProps> = ({
  videoSrc = "",
  voiceoverSrc,
  voiceoverText,
  voiceoverDuration = 5,
  fearTimeline = [],
  clipStartTime = 0,
  showLogo = true,
  logoDuration = 90,
}) => {
  const { durationInFrames, fps, width, height } = useVideoConfig();
  const frame = useCurrentFrame();

  const mainDuration = showLogo
    ? durationInFrames - logoDuration
    : durationInFrames;

  // Generate subtitles from VO text
  const subtitleSegments = voiceoverText
    ? generateSubtitleSegments(
        voiceoverText,
        Math.round(voiceoverDuration * fps),
        Math.round(fps * 0.5) // delay 0.5s
      )
    : [];

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      {/* Main gameplay section */}
      <Sequence durationInFrames={mainDuration}>
        <AbsoluteFill>
          {/* Gameplay footage — cropped to 9:16 */}
          <Video
            src={videoSrc}
            style={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
              objectPosition: "center",
            }}
          />

          {/* Fear-driven vignette/border */}
          <FearOverlay
            timeline={fearTimeline}
            clipStartTime={clipStartTime}
          />

          {/* Base vignette for cinematic look */}
          <Vignette intensity={0.3} />

          {/* Subtitles */}
          <Subtitles
            segments={subtitleSegments}
            position="bottom"
            fontSize={28}
            style="whisper"
          />
        </AbsoluteFill>
      </Sequence>

      {/* Voiceover audio */}
      {voiceoverSrc && (
        <Audio
          src={voiceoverSrc}
          startFrom={0}
          volume={0.85}
        />
      )}

      {/* End card with logo */}
      {showLogo && (
        <Sequence from={mainDuration} durationInFrames={logoDuration}>
          <GameLogo
            animationDuration={30}
            showCTA
            ctaText="Play now on Roblox"
          />
        </Sequence>
      )}
    </AbsoluteFill>
  );
};
