/**
 * Clip selector — scores and ranks moments from a playtest session
 * to identify the best clips for each content type.
 */

import {
  type GameEvent,
  type ClipCandidate,
  type ClipTag,
  type FearTimelinePoint,
  type PlaytestSession,
  type ContentType,
  type FearTier,
  getFearTierFromDistance,
} from "../types.js";

// Scoring weights
const SCORE_CHASE = 70;
const SCORE_NEAR_MISS = 90;
const SCORE_DEATH = 80;
const SCORE_HIDING_PASS = 60;
const SCORE_FEAR_SPIKE = 65;
const SCORE_GENERATOR = 50;
const SCORE_ESCAPE = 75;

// Clip duration bounds (seconds)
const MIN_CLIP_DURATION = 5;
const MAX_CLIP_DURATION = 60;
const DEFAULT_CLIP_PADDING = 3; // seconds before/after the moment

// Fear tier severity ordering
const FEAR_SEVERITY: Record<FearTier, number> = {
  Safe: 0,
  Unease: 1,
  Dread: 2,
  Panic: 3,
  Proximity: 4,
};

interface ScoredMoment {
  time: number;
  score: number;
  reason: string;
  tags: ClipTag[];
  duration: number; // suggested clip duration
}

/**
 * Analyze a session and produce ranked clip candidates.
 */
export function selectClips(
  session: PlaytestSession,
  options: {
    maxClips?: number;
    contentType?: ContentType;
    minScore?: number;
  } = {}
): ClipCandidate[] {
  const { maxClips = 12, minScore = 30 } = options;
  const { events } = session;

  if (events.length === 0) return [];

  // Step 1: Score individual moments
  const moments = scoreMoments(events);

  // Step 2: Merge overlapping moments into clips
  const merged = mergeOverlapping(moments);

  // Step 3: Build fear timeline for each clip
  const candidates: ClipCandidate[] = merged
    .filter((m) => m.score >= minScore)
    .sort((a, b) => b.score - a.score)
    .slice(0, maxClips)
    .map((moment, i) => {
      const startTime = Math.max(0, moment.time - DEFAULT_CLIP_PADDING);
      const endTime = Math.min(
        session.duration,
        moment.time + moment.duration + DEFAULT_CLIP_PADDING
      );

      const clipEvents = events.filter(
        (e) => e.timestamp >= startTime && e.timestamp <= endTime
      );

      return {
        id: `${session.id}-clip-${i}`,
        sessionId: session.id,
        startTime,
        endTime,
        score: moment.score,
        reason: moment.reason,
        tags: moment.tags,
        events: clipEvents,
        fearTimeline: buildFearTimeline(clipEvents),
      };
    });

  return candidates;
}

/**
 * Score individual moments from events.
 */
function scoreMoments(events: GameEvent[]): ScoredMoment[] {
  const moments: ScoredMoment[] = [];

  for (let i = 0; i < events.length; i++) {
    const event = events[i];

    switch (event.type) {
      case "EntityStateChanged": {
        const data = event.data as { from: string; to: string };
        // Chase start is always interesting
        if (data.to === "Chase") {
          const chaseEnd = findNextEvent(events, i, (e) =>
            e.type === "EntityStateChanged" &&
            (e.data as { to: string }).to !== "Chase"
          );
          const duration = chaseEnd
            ? chaseEnd.timestamp - event.timestamp
            : 10;

          moments.push({
            time: event.timestamp,
            score: SCORE_CHASE + Math.min(duration * 2, 20), // longer chases score higher
            reason: `Chase sequence (${duration.toFixed(1)}s)`,
            tags: ["chase"],
            duration: Math.min(duration + 2, MAX_CLIP_DURATION),
          });
        }
        break;
      }

      case "FearTierChanged": {
        const data = event.data as {
          from: string;
          to: string;
          distance: number;
          intensity: number;
        };
        const fromSev = FEAR_SEVERITY[data.from as FearTier] ?? 0;
        const toSev = FEAR_SEVERITY[data.to as FearTier] ?? 0;
        const jump = toSev - fromSev;

        // Fear spike of 2+ levels in one jump
        if (jump >= 2) {
          moments.push({
            time: event.timestamp,
            score: SCORE_FEAR_SPIKE + jump * 10,
            reason: `Fear spike: ${data.from} -> ${data.to} (${data.distance.toFixed(0)} studs)`,
            tags: ["fear-spike"],
            duration: 8,
          });
        }

        // Near miss: entity within 10 studs but no chase active
        if (data.distance < 10 && data.to !== "Proximity") {
          const recentChase = events
            .slice(Math.max(0, i - 20), i)
            .some(
              (e) =>
                e.type === "EntityStateChanged" &&
                (e.data as { to: string }).to === "Chase"
            );
          if (!recentChase) {
            moments.push({
              time: event.timestamp,
              score: SCORE_NEAR_MISS,
              reason: `Near miss at ${data.distance.toFixed(1)} studs`,
              tags: ["near-miss"],
              duration: 10,
            });
          }
        }
        break;
      }

      case "PlayerDamaged": {
        const data = event.data as { health: number; isDowned: boolean };
        if (data.isDowned) {
          moments.push({
            time: event.timestamp,
            score: SCORE_DEATH,
            reason: "Player death",
            tags: ["death"],
            duration: 8,
          });
        }
        break;
      }

      case "HidingEntered": {
        // Check if entity passes nearby while hiding
        const hidingExit = findNextEvent(events, i, (e) =>
          e.type === "HidingExited"
        );
        if (hidingExit) {
          const hidingDuration = hidingExit.timestamp - event.timestamp;
          const entityPassed = events
            .filter(
              (e) =>
                e.type === "EntityPosition" &&
                e.timestamp >= event.timestamp &&
                e.timestamp <= hidingExit.timestamp
            )
            .some((e) => {
              const pos = (e.data as { position: { x: number; y: number; z: number } }).position;
              // Check if entity came close (we don't have player position here, but
              // the FearTierChanged events tell us)
              return true; // simplified — rely on FearTierChanged for proximity
            });

          const fearDuringHiding = events.filter(
            (e) =>
              e.type === "FearTierChanged" &&
              e.timestamp >= event.timestamp &&
              e.timestamp <= hidingExit.timestamp
          );
          const peakFear = fearDuringHiding.reduce((max, e) => {
            const sev = FEAR_SEVERITY[(e.data as { to: string }).to as FearTier] ?? 0;
            return Math.max(max, sev);
          }, 0);

          if (peakFear >= 3) {
            // Panic or Proximity while hiding
            moments.push({
              time: event.timestamp,
              score: SCORE_HIDING_PASS + peakFear * 5,
              reason: `Hiding while entity passes (${hidingDuration.toFixed(1)}s, peak fear ${peakFear})`,
              tags: ["hiding"],
              duration: hidingDuration + 4,
            });
          }
        }
        break;
      }

      case "HidingSpotChecked": {
        const data = event.data as { playerFound: boolean };
        if (data.playerFound) {
          moments.push({
            time: event.timestamp,
            score: SCORE_DEATH - 5, // almost as dramatic as death
            reason: "Found while hiding",
            tags: ["jumpscare", "death"],
            duration: 6,
          });
        }
        break;
      }

      case "GeneratorStateUpdate": {
        const data = event.data as {
          active: boolean;
          totalActive: number;
          totalRequired: number;
        };
        if (data.active && data.totalActive === data.totalRequired) {
          moments.push({
            time: event.timestamp,
            score: SCORE_GENERATOR + 20, // final generator is exciting
            reason: `All generators activated (${data.totalRequired}/${data.totalRequired})`,
            tags: ["generator"],
            duration: 10,
          });
        } else if (data.active) {
          moments.push({
            time: event.timestamp,
            score: SCORE_GENERATOR,
            reason: `Generator activated (${data.totalActive}/${data.totalRequired})`,
            tags: ["generator"],
            duration: 8,
          });
        }
        break;
      }

      case "RoundEnded": {
        const data = event.data as { outcome: string };
        if (data.outcome === "escaped" || data.outcome === "extracted") {
          moments.push({
            time: event.timestamp - 5,
            score: SCORE_ESCAPE,
            reason: "Successful escape",
            tags: ["escape"],
            duration: 12,
          });
        }
        break;
      }
    }
  }

  return moments;
}

/**
 * Merge overlapping moments into combined clips with summed scores.
 */
function mergeOverlapping(moments: ScoredMoment[]): ScoredMoment[] {
  if (moments.length === 0) return [];

  const sorted = [...moments].sort((a, b) => a.time - b.time);
  const merged: ScoredMoment[] = [sorted[0]];

  for (let i = 1; i < sorted.length; i++) {
    const current = sorted[i];
    const last = merged[merged.length - 1];

    // Overlap if current starts within last's duration
    if (current.time <= last.time + last.duration) {
      // Merge: extend duration, sum scores, combine tags
      last.duration = Math.max(
        last.duration,
        current.time - last.time + current.duration
      );
      last.score = Math.min(100, last.score + current.score * 0.3);
      last.reason += ` + ${current.reason}`;
      last.tags = [...new Set([...last.tags, ...current.tags])];
    } else {
      merged.push({ ...current });
    }
  }

  // Clamp durations
  for (const m of merged) {
    m.duration = Math.max(MIN_CLIP_DURATION, Math.min(m.duration, MAX_CLIP_DURATION));
  }

  return merged;
}

/**
 * Build a fear intensity timeline from events within a clip.
 */
function buildFearTimeline(events: GameEvent[]): FearTimelinePoint[] {
  const timeline: FearTimelinePoint[] = [];

  for (const event of events) {
    if (event.type === "FearTierChanged") {
      const data = event.data as {
        to: string;
        distance: number;
        intensity: number;
      };
      timeline.push({
        time: event.timestamp,
        tier: data.to as FearTier,
        intensity: data.intensity,
        distance: data.distance,
      });
    } else if (event.type === "EntityPosition") {
      // Sample fear from entity position (approximate — we don't have player pos)
      // The FearTierChanged events are more reliable; this fills gaps
    }
  }

  return timeline;
}

/**
 * Find the next event matching a predicate after index `start`.
 */
function findNextEvent(
  events: GameEvent[],
  startIndex: number,
  predicate: (e: GameEvent) => boolean
): GameEvent | undefined {
  for (let i = startIndex + 1; i < events.length; i++) {
    if (predicate(events[i])) return events[i];
  }
  return undefined;
}

/**
 * Get recommended content types for a clip based on its tags and score.
 */
export function recommendContentTypes(clip: ClipCandidate): ContentType[] {
  const types: ContentType[] = [];

  // TikTok: high-action clips under 60s
  if (clip.score >= 50 && clip.endTime - clip.startTime <= 60) {
    types.push("tiktok");
  }

  // Raw footage: anything goes, especially chases and deaths
  if (clip.tags.includes("chase") || clip.tags.includes("death")) {
    types.push("raw");
  }

  // ARG: hiding, near-misses, glitchy moments
  if (
    clip.tags.includes("hiding") ||
    clip.tags.includes("near-miss") ||
    clip.tags.includes("jumpscare")
  ) {
    types.push("arg");
  }

  // Default to raw if nothing else fits
  if (types.length === 0) {
    types.push("raw");
  }

  return types;
}
