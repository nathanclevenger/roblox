/**
 * VHSOverlay — scan lines, timestamp, tracking artifacts for "leaked footage" aesthetic.
 */

import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  random,
} from "remotion";
import { VHS_CONFIG, COLORS } from "../themes/horror.js";

export interface VHSOverlayProps {
  showTimestamp?: boolean;
  showRecIndicator?: boolean;
  trackingGlitches?: boolean;
  baseDate?: string; // date for timestamp display
  noiseIntensity?: number;
}

export const VHSOverlay: React.FC<VHSOverlayProps> = ({
  showTimestamp = true,
  showRecIndicator = true,
  trackingGlitches = true,
  baseDate = "03/14/2024",
  noiseIntensity = VHS_CONFIG.noiseIntensity,
}) => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();

  const seconds = Math.floor(frame / fps);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const timeStr = `${String(hours).padStart(2, "0")}:${String(minutes % 60).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`;

  // Tracking glitch — occasional horizontal displacement
  const hasGlitch =
    trackingGlitches && random(`glitch-${frame}`) > 0.97;
  const glitchOffset = hasGlitch
    ? (random(`glitch-offset-${frame}`) - 0.5) * 20
    : 0;
  const glitchHeight = hasGlitch
    ? 2 + random(`glitch-h-${frame}`) * 8
    : 0;
  const glitchY = hasGlitch ? random(`glitch-y-${frame}`) * height : 0;

  // REC indicator blink
  const recVisible = Math.floor(frame / (fps * 0.8)) % 2 === 0;

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {/* Scan lines */}
      <AbsoluteFill
        style={{
          background: `repeating-linear-gradient(
            0deg,
            rgba(0, 0, 0, ${VHS_CONFIG.scanLineOpacity}),
            rgba(0, 0, 0, ${VHS_CONFIG.scanLineOpacity}) ${VHS_CONFIG.scanLineHeight}px,
            transparent ${VHS_CONFIG.scanLineHeight}px,
            transparent ${VHS_CONFIG.scanLineHeight + VHS_CONFIG.scanLineGap}px
          )`,
          transform: `translateY(${(frame * VHS_CONFIG.trackingSpeed) % (VHS_CONFIG.scanLineHeight + VHS_CONFIG.scanLineGap)}px)`,
        }}
      />

      {/* Subtle noise grain */}
      <AbsoluteFill
        style={{
          opacity: noiseIntensity,
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' seed='${frame}' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.5'/%3E%3C/svg%3E")`,
          backgroundSize: "256px 256px",
          mixBlendMode: "overlay",
        }}
      />

      {/* Color bleed / chromatic shift */}
      <AbsoluteFill
        style={{
          boxShadow: `inset ${VHS_CONFIG.colorBleed}px 0 0 rgba(255, 0, 0, 0.05), inset -${VHS_CONFIG.colorBleed}px 0 0 rgba(0, 0, 255, 0.05)`,
        }}
      />

      {/* Tracking glitch bar */}
      {hasGlitch && (
        <div
          style={{
            position: "absolute",
            top: glitchY,
            left: 0,
            width: "100%",
            height: glitchHeight,
            transform: `translateX(${glitchOffset}px)`,
            backgroundColor: `rgba(255, 255, 255, 0.1)`,
            backdropFilter: "brightness(1.5) saturate(0.5)",
          }}
        />
      )}

      {/* Timestamp */}
      {showTimestamp && (
        <div
          style={{
            position: "absolute",
            bottom: 24,
            right: 24,
            fontFamily: "'Courier New', monospace",
            fontSize: 16,
            color: COLORS.vhs,
            textShadow: `0 0 4px ${COLORS.vhs}`,
            opacity: 0.8,
          }}
        >
          {baseDate} {timeStr}
        </div>
      )}

      {/* REC indicator */}
      {showRecIndicator && (
        <div
          style={{
            position: "absolute",
            top: 24,
            left: 24,
            display: "flex",
            alignItems: "center",
            gap: 8,
            opacity: recVisible ? 0.9 : 0,
          }}
        >
          <div
            style={{
              width: 10,
              height: 10,
              borderRadius: "50%",
              backgroundColor: "#ff0000",
              boxShadow: "0 0 6px #ff0000",
            }}
          />
          <span
            style={{
              fontFamily: "'Courier New', monospace",
              fontSize: 14,
              color: "#ff0000",
              fontWeight: "bold",
            }}
          >
            REC
          </span>
        </div>
      )}

      {/* Top/bottom letterbox fade for VHS feel */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: 20,
          background:
            "linear-gradient(to bottom, rgba(0,0,0,0.3), transparent)",
        }}
      />
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: 20,
          background:
            "linear-gradient(to top, rgba(0,0,0,0.3), transparent)",
        }}
      />
    </AbsoluteFill>
  );
};
