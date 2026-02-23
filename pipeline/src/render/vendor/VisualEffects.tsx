/**
 * Visual Effects — vendored from platform/ai/packages/motion.md
 * Glitch, ChromaticAberration, Vignette, Flash components
 */

import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  Easing,
  random,
} from "remotion";

// -- Glitch Effect --

export interface GlitchProps {
  children: React.ReactNode;
  intensity?: number;
  duration?: number;
  startFrame?: number;
  style?: "rgb-split" | "scan-lines" | "distortion" | "all";
}

export const Glitch: React.FC<GlitchProps> = ({
  children,
  intensity = 0.5,
  duration = 6,
  startFrame = 0,
  style = "rgb-split",
}) => {
  const frame = useCurrentFrame();
  const relativeFrame = frame - startFrame;

  if (relativeFrame < 0 || relativeFrame >= duration) {
    return <>{children}</>;
  }

  const progress = interpolate(
    relativeFrame,
    [0, duration / 2, duration],
    [0, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  const glitchAmount = progress * intensity;

  if (style === "rgb-split" || style === "all") {
    const offsetX = glitchAmount * 10;
    const offsetY = glitchAmount * 5;

    return (
      <AbsoluteFill>
        <AbsoluteFill
          style={{
            transform: `translate(${offsetX}px, 0)`,
            mixBlendMode: "screen",
            filter: `brightness(${1 + glitchAmount})`,
          }}
        >
          <div style={{ filter: "sepia(1) hue-rotate(-50deg) saturate(5)" }}>
            {children}
          </div>
        </AbsoluteFill>
        <AbsoluteFill
          style={{
            transform: `translate(${-offsetX}px, ${offsetY}px)`,
            mixBlendMode: "screen",
            filter: `brightness(${1 + glitchAmount})`,
          }}
        >
          <div style={{ filter: "sepia(1) hue-rotate(50deg) saturate(3)" }}>
            {children}
          </div>
        </AbsoluteFill>
        <AbsoluteFill
          style={{
            transform: `translate(0, ${-offsetY}px)`,
            mixBlendMode: "screen",
          }}
        >
          <div style={{ filter: "sepia(1) hue-rotate(180deg) saturate(3)" }}>
            {children}
          </div>
        </AbsoluteFill>
      </AbsoluteFill>
    );
  }

  if (style === "scan-lines") {
    return (
      <AbsoluteFill>
        {children}
        <AbsoluteFill
          style={{
            background: `repeating-linear-gradient(
              0deg,
              rgba(0, 0, 0, ${0.1 * glitchAmount}),
              rgba(0, 0, 0, ${0.1 * glitchAmount}) 2px,
              transparent 2px,
              transparent 4px
            )`,
            pointerEvents: "none",
          }}
        />
      </AbsoluteFill>
    );
  }

  if (style === "distortion") {
    return (
      <div
        style={{
          filter: `blur(${glitchAmount * 2}px) contrast(${1 + glitchAmount * 0.5})`,
          transform: `skewX(${glitchAmount * 5}deg)`,
        }}
      >
        {children}
      </div>
    );
  }

  return <>{children}</>;
};

// -- Chromatic Aberration --

export interface ChromaticAberrationProps {
  children: React.ReactNode;
  intensity?: number;
  angle?: number;
}

export const ChromaticAberration: React.FC<ChromaticAberrationProps> = ({
  children,
  intensity = 0.3,
  angle = 0,
}) => {
  const offsetX = Math.cos((angle * Math.PI) / 180) * intensity * 5;
  const offsetY = Math.sin((angle * Math.PI) / 180) * intensity * 5;

  return (
    <AbsoluteFill>
      <AbsoluteFill
        style={{
          transform: `translate(${offsetX}px, ${offsetY}px)`,
          mixBlendMode: "screen",
        }}
      >
        <div style={{ filter: "sepia(1) hue-rotate(-50deg) saturate(5)" }}>
          {children}
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{ mixBlendMode: "screen" }}>
        <div style={{ filter: "sepia(1) hue-rotate(50deg) saturate(3)" }}>
          {children}
        </div>
      </AbsoluteFill>
      <AbsoluteFill
        style={{
          transform: `translate(${-offsetX}px, ${-offsetY}px)`,
          mixBlendMode: "screen",
        }}
      >
        <div style={{ filter: "sepia(1) hue-rotate(180deg) saturate(3)" }}>
          {children}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// -- Flash --

export interface FlashProps {
  color?: string;
  duration?: number;
  startFrame?: number;
  intensity?: number;
}

export const Flash: React.FC<FlashProps> = ({
  color = "#FFFFFF",
  duration = 3,
  startFrame = 0,
  intensity = 0.8,
}) => {
  const frame = useCurrentFrame();
  const relativeFrame = frame - startFrame;

  if (relativeFrame < 0 || relativeFrame >= duration) {
    return null;
  }

  const opacity = interpolate(
    relativeFrame,
    [0, 1, duration],
    [intensity, intensity, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill
      style={{
        backgroundColor: color,
        opacity,
        pointerEvents: "none",
        mixBlendMode: "screen",
      }}
    />
  );
};

// -- Vignette --

export interface VignetteProps {
  intensity?: number;
  color?: string;
}

export const Vignette: React.FC<VignetteProps> = ({
  intensity = 0.5,
  color = "#000000",
}) => {
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(ellipse at center, transparent 0%, ${color} 100%)`,
        opacity: intensity,
        pointerEvents: "none",
      }}
    />
  );
};
