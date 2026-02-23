/**
 * TikTok "Draw Anything" — Draw to Escape
 *
 * 30-second showcase of the core drawing mechanic across 3 zones:
 * - Sketch Fields: draw a bridge to cross a gap
 * - Watercolor Wetlands: draw a wooden boat to cross water
 * - Crayon Caverns: draw a neon torch to light the way
 * - Rapid montage of creative solutions
 * - Victory screen with 3 stars
 *
 * Camera: Dynamic follow cam with cinematic angles on materialization moments.
 */

import type { Choreography } from "../../types.js";

// Stage positions (each zone 200 studs apart on Z)
const ZONE1_GAP_EDGE = { x: 0, y: 5, z: 30 };
const ZONE1_BRIDGE_MID = { x: 0, y: 5, z: 40 };
const ZONE1_FAR_SIDE = { x: 0, y: 5, z: 50 };

const ZONE2_WATER_EDGE = { x: 0, y: 5, z: 220 };
const ZONE2_BOAT_POS = { x: 0, y: 3, z: 230 };
const ZONE2_FAR_SIDE = { x: 0, y: 5, z: 250 };

const ZONE3_DARK_ENTRANCE = { x: 0, y: 5, z: 420 };
const ZONE3_TORCH_POS = { x: 0, y: 5, z: 430 };
const ZONE3_REVEALED = { x: 0, y: 5, z: 445 };

const VICTORY_POS = { x: 0, y: 5, z: 460 };

const choreography: Choreography = {
  id: "draw-to-escape-tiktok-draw-anything",
  game: "draw-to-escape",
  title: "Draw Anything, Escape Everything — TikTok (30s)",
  durationSeconds: 30,
  setupDelaySeconds: 2,

  camera: [
    // [0:00-0:03] Wide shot — player at gap edge
    {
      time: 0,
      mode: "scripted",
      position: { x: 5, y: 8, z: 25 },
      lookAt: ZONE1_GAP_EDGE,
      fov: 65,
    },
    // [0:03] Zoom into canvas (tighter FOV on player)
    {
      time: 3,
      mode: "follow_player",
      followOffset: { x: 2, y: 3, z: -2 },
      fov: 55,
      easing: "ease_in_out",
    },
    // [0:05] Pull back to show bridge materializing
    {
      time: 5,
      mode: "scripted",
      position: { x: 8, y: 10, z: 35 },
      lookAt: ZONE1_BRIDGE_MID,
      fov: 70,
      easing: "ease_out",
    },
    // [0:07] Low angle — player running across bridge
    {
      time: 7,
      mode: "scripted",
      position: { x: 3, y: 2, z: 42 },
      lookAt: { x: 0, y: 5, z: 45 },
      fov: 60,
      easing: "ease_in",
    },
    // [0:10] Hard cut — Watercolor Wetlands, wide establishing shot
    {
      time: 10,
      mode: "scripted",
      position: { x: 10, y: 12, z: 215 },
      lookAt: ZONE2_WATER_EDGE,
      fov: 75,
      easing: "linear",
    },
    // [0:12] Follow player drawing boat
    {
      time: 12,
      mode: "follow_player",
      followOffset: { x: 2, y: 3, z: -2 },
      fov: 55,
      easing: "ease_in_out",
    },
    // [0:14] Show boat on water — side angle
    {
      time: 14,
      mode: "scripted",
      position: { x: 8, y: 4, z: 232 },
      lookAt: ZONE2_BOAT_POS,
      fov: 60,
      easing: "ease_out",
    },
    // [0:16] Smash cut — Crayon Caverns, nearly black
    {
      time: 16,
      mode: "scripted",
      position: { x: 3, y: 6, z: 418 },
      lookAt: ZONE3_DARK_ENTRANCE,
      fov: 50,
      easing: "linear",
    },
    // [0:18] Canvas glow — close on player
    {
      time: 18,
      mode: "follow_player",
      followOffset: { x: 1, y: 2, z: -1.5 },
      fov: 50,
      easing: "ease_in",
    },
    // [0:19.5] Pull back — neon torch illuminates cavern
    {
      time: 19.5,
      mode: "scripted",
      position: { x: 10, y: 10, z: 425 },
      lookAt: ZONE3_TORCH_POS,
      fov: 80,
      easing: "ease_out",
    },
    // [0:20-0:24] Rapid montage — quick cuts (wide dynamic)
    {
      time: 20,
      mode: "follow_player",
      followOffset: { x: 5, y: 8, z: -5 },
      fov: 70,
      easing: "linear",
    },
    // [0:24] Victory podium — overhead shot
    {
      time: 24,
      mode: "scripted",
      position: { x: 0, y: 15, z: 455 },
      lookAt: VICTORY_POS,
      fov: 60,
      easing: "ease_in_out",
    },
    // [0:27] Logo — static center frame
    {
      time: 27,
      mode: "fixed",
      position: { x: 0, y: 5, z: 465 },
      lookAt: { x: 0, y: 5, z: 470 },
      fov: 70,
    },
  ],

  actions: [
    // [0:00] Set bright, warm lighting for Sketch Fields
    {
      time: 0,
      type: "set_lighting",
      params: {
        Brightness: 2,
        ClockTime: 14,
        FogEnd: 500,
      },
    },
    // [0:00] Place player at gap edge (Zone 1)
    {
      time: 0,
      type: "teleport_player",
      params: { position: ZONE1_GAP_EDGE },
    },
    // [0:03] Submit bridge drawing (wood plank)
    {
      time: 3,
      type: "submit_drawing",
      params: {
        material: "wood",
        strokes: [
          {
            Points: [
              { X: 50, Y: 140 },
              { X: 100, Y: 135 },
              { X: 200, Y: 135 },
              { X: 300, Y: 138 },
              { X: 350, Y: 140 },
            ],
            Color: { R: 0.6, G: 0.4, B: 0.2 },
            Thickness: 12,
            Material: "wood",
          },
          {
            Points: [
              { X: 50, Y: 160 },
              { X: 100, Y: 158 },
              { X: 200, Y: 158 },
              { X: 300, Y: 160 },
              { X: 350, Y: 162 },
            ],
            Color: { R: 0.5, G: 0.35, B: 0.15 },
            Thickness: 12,
            Material: "wood",
          },
        ],
      },
    },
    // [0:05] Teleport player to bridge
    {
      time: 5,
      type: "teleport_player",
      params: { position: ZONE1_BRIDGE_MID },
    },
    // [0:07] Player crosses bridge
    {
      time: 7,
      type: "teleport_player",
      params: { position: ZONE1_FAR_SIDE },
    },
    // [0:09] Teleport to Zone 2 — Watercolor Wetlands
    {
      time: 9.5,
      type: "teleport_to_stage",
      params: { stageId: 6 },
    },
    // [0:10] Adjust to water edge
    {
      time: 10,
      type: "teleport_player",
      params: { position: ZONE2_WATER_EDGE },
    },
    // [0:12] Submit boat drawing (wood)
    {
      time: 12,
      type: "submit_drawing",
      params: {
        material: "wood",
        strokes: [
          {
            Points: [
              { X: 80, Y: 180 },
              { X: 120, Y: 200 },
              { X: 200, Y: 210 },
              { X: 280, Y: 200 },
              { X: 320, Y: 180 },
            ],
            Color: { R: 0.55, G: 0.35, B: 0.15 },
            Thickness: 10,
            Material: "wood",
          },
          {
            Points: [
              { X: 80, Y: 180 },
              { X: 60, Y: 160 },
              { X: 80, Y: 140 },
            ],
            Color: { R: 0.55, G: 0.35, B: 0.15 },
            Thickness: 8,
            Material: "wood",
          },
        ],
      },
    },
    // [0:14] Player on boat
    {
      time: 14,
      type: "teleport_player",
      params: { position: ZONE2_BOAT_POS },
    },
    // [0:15.5] Player reaches far side
    {
      time: 15.5,
      type: "teleport_player",
      params: { position: ZONE2_FAR_SIDE },
    },
    // [0:16] Teleport to Zone 3 — Crayon Caverns (dark)
    {
      time: 16,
      type: "set_lighting",
      params: {
        Brightness: 0,
        Ambient: { R: 0.01, G: 0.01, B: 0.02 },
        ClockTime: 0,
        FogEnd: 30,
        FogColor: { R: 0.02, G: 0.02, B: 0.05 },
      },
    },
    {
      time: 16,
      type: "teleport_player",
      params: { position: ZONE3_DARK_ENTRANCE },
    },
    // [0:18] Submit neon torch drawing
    {
      time: 18,
      type: "submit_drawing",
      params: {
        material: "neon",
        strokes: [
          {
            Points: [
              { X: 190, Y: 250 },
              { X: 195, Y: 200 },
              { X: 200, Y: 150 },
              { X: 205, Y: 100 },
            ],
            Color: { R: 0.3, G: 0.2, B: 0.1 },
            Thickness: 6,
            Material: "wood",
          },
          {
            Points: [
              { X: 180, Y: 100 },
              { X: 190, Y: 70 },
              { X: 200, Y: 60 },
              { X: 210, Y: 70 },
              { X: 220, Y: 100 },
            ],
            Color: { R: 0.0, G: 0.9, B: 1.0 },
            Thickness: 14,
            Material: "neon",
          },
        ],
      },
    },
    // [0:19.5] Cavern illuminated — restore some lighting
    {
      time: 19.5,
      type: "set_lighting",
      params: {
        Brightness: 0.5,
        Ambient: { R: 0.05, G: 0.15, B: 0.2 },
        FogEnd: 120,
      },
    },
    {
      time: 19.5,
      type: "teleport_player",
      params: { position: ZONE3_TORCH_POS },
    },
    // [0:20-0:24] Rapid montage — quick stage teleports
    {
      time: 20,
      type: "set_lighting",
      params: { Brightness: 2, ClockTime: 14, FogEnd: 500 },
    },
    {
      time: 20,
      type: "teleport_to_stage",
      params: { stageId: 3 },
    },
    {
      time: 21,
      type: "submit_drawing",
      params: { material: "stone" },
    },
    {
      time: 22,
      type: "teleport_to_stage",
      params: { stageId: 8 },
    },
    {
      time: 22.5,
      type: "submit_drawing",
      params: { material: "balloon" },
    },
    {
      time: 23,
      type: "teleport_to_stage",
      params: { stageId: 12 },
    },
    {
      time: 23.5,
      type: "submit_drawing",
      params: { material: "metal" },
    },
    // [0:24] Victory — teleport to podium
    {
      time: 24,
      type: "teleport_player",
      params: { position: VICTORY_POS },
    },
    {
      time: 24.5,
      type: "complete_stage",
      params: { stageId: 12, stars: 3 },
    },
  ],

  markers: [
    { time: 0, label: "zone1-gap" },
    { time: 3, label: "draw-bridge" },
    { time: 7, label: "cross-bridge" },
    { time: 10, label: "zone2-water" },
    { time: 12, label: "draw-boat" },
    { time: 16, label: "zone3-dark" },
    { time: 18, label: "draw-torch" },
    { time: 20, label: "montage-start" },
    { time: 24, label: "victory" },
    { time: 27, label: "logo-card" },
  ],
};

export default choreography;
