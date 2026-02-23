/**
 * Transitions — vendored from platform/ai/packages/motion.md
 * Scene transition utilities adapted for horror content.
 */

import React from "react";
import { AbsoluteFill, useCurrentFrame, interpolate, Easing } from "remotion";

export type TransitionType =
  | "cut"
  | "slide-left"
  | "slide-right"
  | "slide-up"
  | "slide-down"
  | "wipe-left"
  | "wipe-right"
  | "fade"
  | "zoom-in"
  | "zoom-out";

export interface TransitionProps {
  type: TransitionType;
  durationInFrames?: number;
  from: React.ReactNode;
  to: React.ReactNode;
  easing?: (t: number) => number;
}

export const Transition: React.FC<TransitionProps> = ({
  type,
  durationInFrames = 6,
  from,
  to,
  easing = Easing.out(Easing.ease),
}) => {
  const frame = useCurrentFrame();

  if (type === "cut") {
    return <>{frame < durationInFrames ? from : to}</>;
  }

  const progress = interpolate(frame, [0, durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

  switch (type) {
    case "fade":
      return (
        <AbsoluteFill>
          <AbsoluteFill style={{ opacity: 1 - progress }}>{from}</AbsoluteFill>
          <AbsoluteFill style={{ opacity: progress }}>{to}</AbsoluteFill>
        </AbsoluteFill>
      );

    case "zoom-in":
      return (
        <AbsoluteFill>
          <AbsoluteFill
            style={{
              transform: `scale(${1 - progress * 0.2})`,
              opacity: 1 - progress,
            }}
          >
            {from}
          </AbsoluteFill>
          <AbsoluteFill
            style={{
              transform: `scale(${0.9 + progress * 0.1})`,
              opacity: progress,
            }}
          >
            {to}
          </AbsoluteFill>
        </AbsoluteFill>
      );

    case "wipe-left":
      return (
        <AbsoluteFill>
          <AbsoluteFill>{from}</AbsoluteFill>
          <AbsoluteFill
            style={{ clipPath: `inset(0 ${(1 - progress) * 100}% 0 0)` }}
          >
            {to}
          </AbsoluteFill>
        </AbsoluteFill>
      );

    default:
      return <>{frame < durationInFrames ? from : to}</>;
  }
};
