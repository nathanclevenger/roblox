/**
 * RawFootage — "Leaked" footage composition (1920x1080, 16:9).
 * Minimal processing: VHS overlay, no VO, security camera aesthetic.
 */

import React from "react";
import { AbsoluteFill, Video, Sequence, useVideoConfig } from "remotion";
import { VHSOverlay } from "../components/VHSOverlay.js";
import { Vignette } from "../vendor/VisualEffects.js";

export interface RawFootageProps {
  videoSrc?: string;
  footageDate?: string;
  desaturate?: boolean;
  trackingGlitches?: boolean;
}

export const RawFootage: React.FC<RawFootageProps> = ({
  videoSrc = "",
  footageDate = "03/14/2024",
  desaturate = true,
  trackingGlitches = true,
}) => {
  const { durationInFrames } = useVideoConfig();

  return (
    <AbsoluteFill style={{ backgroundColor: "#000" }}>
      {/* Gameplay footage with security cam treatment */}
      <Video
        src={videoSrc}
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
          filter: desaturate
            ? "saturate(0.4) contrast(1.1) brightness(0.9)"
            : "none",
        }}
      />

      {/* VHS overlay */}
      <VHSOverlay
        showTimestamp
        showRecIndicator
        trackingGlitches={trackingGlitches}
        baseDate={footageDate}
        noiseIntensity={0.04}
      />

      {/* Heavy vignette for surveillance look */}
      <Vignette intensity={0.5} />
    </AbsoluteFill>
  );
};
