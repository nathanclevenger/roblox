/**
 * Horror theme — color palette, fonts, and effect presets for The Origin.
 */

import type { FearTier } from "../../types.js";

export const COLORS = {
  background: "#0a0a0a",
  surface: "#1a1a1a",
  text: "#e0e0e0",
  textMuted: "#808080",
  accent: "#cc0000", // blood red
  accentDim: "#660000",
  warning: "#ff6600",
  danger: "#ff0000",
  safe: "#2a5a2a",
  vignette: "#000000",
  vhs: "#00ff00", // VHS green
  glitch: "#ff00ff", // magenta glitch
  corruption: "#00ffff", // cyan corruption
} as const;

export const FONTS = {
  primary: "Inter, system-ui, sans-serif",
  mono: "'Courier New', Courier, monospace",
  display: "'Impact', 'Arial Black', sans-serif",
} as const;

export const FEAR_COLORS: Record<FearTier, string> = {
  Safe: "#2a5a2a",
  Unease: "#6a6a2a",
  Dread: "#8a4a0a",
  Panic: "#aa2a0a",
  Proximity: "#ff0000",
};

export const FEAR_BORDER_WIDTHS: Record<FearTier, number> = {
  Safe: 0,
  Unease: 2,
  Dread: 4,
  Panic: 8,
  Proximity: 12,
};

/**
 * VHS overlay configuration.
 */
export const VHS_CONFIG = {
  scanLineOpacity: 0.08,
  scanLineHeight: 2,
  scanLineGap: 2,
  trackingSpeed: 0.5, // pixels per frame vertical offset
  timestampFormat: "REC  %H:%M:%S",
  noiseIntensity: 0.03,
  colorBleed: 1.5, // pixels
} as const;

/**
 * Glitch intensity presets per content type.
 */
export const GLITCH_PRESETS = {
  subtle: { intensity: 0.2, duration: 4 },
  medium: { intensity: 0.5, duration: 6 },
  heavy: { intensity: 0.8, duration: 10 },
  extreme: { intensity: 1.0, duration: 15 },
} as const;

/**
 * Content type aspect ratios and dimensions.
 */
export const DIMENSIONS = {
  tiktok: { width: 1080, height: 1920, fps: 30 }, // 9:16
  raw: { width: 1920, height: 1080, fps: 30 }, // 16:9
  trailer: { width: 1920, height: 1080, fps: 30 }, // 16:9
  arg: { width: 1080, height: 1080, fps: 30 }, // 1:1
  devdiary: { width: 1920, height: 1080, fps: 30 }, // 16:9
} as const;
