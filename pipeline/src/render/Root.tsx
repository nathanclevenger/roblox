/**
 * Remotion Root — registers all compositions for The Origin video pipeline.
 */

import React from "react";
import { Composition } from "remotion";
import { GameplayClip } from "./compositions/GameplayClip.js";
import { RawFootage } from "./compositions/RawFootage.js";
import { Trailer } from "./compositions/Trailer.js";
import { ARGContent } from "./compositions/ARGContent.js";
import { DevDiary } from "./compositions/DevDiary.js";
import { DIMENSIONS } from "./themes/horror.js";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* TikTok/Shorts — 9:16, highest volume */}
      <Composition
        id="GameplayClip"
        component={GameplayClip}
        durationInFrames={900} // 30s default, overridden per clip
        fps={DIMENSIONS.tiktok.fps}
        width={DIMENSIONS.tiktok.width}
        height={DIMENSIONS.tiktok.height}
        defaultProps={{
          videoSrc: "",
          fearTimeline: [],
          clipStartTime: 0,
        }}
      />

      {/* Raw "leaked" footage — 16:9 */}
      <Composition
        id="RawFootage"
        component={RawFootage}
        durationInFrames={900}
        fps={DIMENSIONS.raw.fps}
        width={DIMENSIONS.raw.width}
        height={DIMENSIONS.raw.height}
        defaultProps={{
          videoSrc: "",
        }}
      />

      {/* Trailer — 16:9, multi-clip montage */}
      <Composition
        id="Trailer"
        component={Trailer}
        durationInFrames={1800} // 60s default
        fps={DIMENSIONS.trailer.fps}
        width={DIMENSIONS.trailer.width}
        height={DIMENSIONS.trailer.height}
        defaultProps={{
          clips: [],
        }}
      />

      {/* ARG content — 1:1, heavy corruption */}
      <Composition
        id="ARGContent"
        component={ARGContent}
        durationInFrames={450} // 15s default
        fps={DIMENSIONS.arg.fps}
        width={DIMENSIONS.arg.width}
        height={DIMENSIONS.arg.height}
        defaultProps={{
          videoSrc: "",
        }}
      />

      {/* Dev Diary — 16:9, PiP + code overlays */}
      <Composition
        id="DevDiary"
        component={DevDiary}
        durationInFrames={1800} // 60s default
        fps={DIMENSIONS.devdiary.fps}
        width={DIMENSIONS.devdiary.width}
        height={DIMENSIONS.devdiary.height}
        defaultProps={{
          videoSrc: "",
        }}
      />
    </>
  );
};
