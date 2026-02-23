/**
 * TikTok Chase Sequence — The Origin (Hospital Level 1)
 *
 * 30-second choreographed chase scene matching the marketing script:
 * - Player walks corridor → spots entity → freeze → chase → hides in locker → entity passes
 *
 * Camera: First-person POV transitioning to cinematic angles during the chase.
 * Entity: The Patient — spawns at corridor end, transitions Idle → Hunt → Chase → Search.
 */

import type { Choreography } from "../../types.js";

// Hospital Level 1 reference positions (approximate)
const CORRIDOR_START = { x: -20, y: 5, z: 40 };
const CORRIDOR_MID = { x: -20, y: 5, z: 20 };
const WHEELCHAIR_POS = { x: -20, y: 3, z: 15 };
const CORRIDOR_END = { x: -20, y: 5, z: -10 };
const ENTITY_SPAWN = { x: -20, y: 5, z: -30 };
const ENTITY_APPROACH_1 = { x: -20, y: 5, z: -20 };
const ENTITY_APPROACH_2 = { x: -20, y: 5, z: -5 };
const ENTITY_CHASE_1 = { x: -20, y: 5, z: 5 };
const ENTITY_CHASE_2 = { x: -20, y: 5, z: 15 };
const LOCKER_POS = { x: -15, y: 5, z: 25 };
const ENTITY_PASS_LOCKER = { x: -20, y: 5, z: 28 };
const ENTITY_PAST_LOCKER = { x: -20, y: 5, z: 40 };

const choreography: Choreography = {
  id: "the-origin-tiktok-chase-sequence",
  game: "the-origin",
  title: "Hospital Chase — TikTok (30s)",
  durationSeconds: 30,
  setupDelaySeconds: 3,

  camera: [
    // [0:00-0:04] First-person POV walking down dark corridor
    {
      time: 0,
      mode: "first_person",
      fov: 70,
    },
    // [0:04] Turn corner — shift to slightly offset follow
    {
      time: 4,
      mode: "follow_player",
      followOffset: { x: 0.5, y: 1, z: -1 },
      fov: 70,
      easing: "ease_in_out",
    },
    // [0:07] Spot entity — tighten FOV, create tension
    {
      time: 7,
      mode: "scripted",
      position: { x: -20, y: 6, z: 10 },
      lookAt: ENTITY_SPAWN,
      fov: 55,
      easing: "ease_in",
    },
    // [0:12] Freeze moment — camera holds steady on entity
    {
      time: 12,
      mode: "scripted",
      position: { x: -20, y: 5.5, z: 8 },
      lookAt: ENTITY_APPROACH_1,
      fov: 50,
      easing: "linear",
    },
    // [0:15] Entity advances — slight pull back
    {
      time: 15,
      mode: "scripted",
      position: { x: -20, y: 5.5, z: 12 },
      lookAt: ENTITY_APPROACH_2,
      fov: 60,
      easing: "ease_in",
    },
    // [0:19] Sprint begins — violent camera movement
    {
      time: 19,
      mode: "follow_player",
      followOffset: { x: 1, y: 2, z: -3 },
      fov: 85,
      easing: "ease_out",
    },
    // [0:21] Dive into locker — tight angle
    {
      time: 21,
      mode: "scripted",
      position: { x: -14.5, y: 5, z: 25 },
      lookAt: { x: -20, y: 4.5, z: 25 },
      fov: 40,
      easing: "ease_in_out",
    },
    // [0:22] Inside locker — narrow POV (simulated via tight FOV)
    {
      time: 22,
      mode: "scripted",
      position: { x: -15.5, y: 5, z: 25.5 },
      lookAt: { x: -20, y: 4.5, z: 25 },
      fov: 30,
      easing: "ease_in",
    },
    // [0:25] Entity feet pass — look down at floor level
    {
      time: 25,
      mode: "scripted",
      position: { x: -15.5, y: 4, z: 25.5 },
      lookAt: ENTITY_PASS_LOCKER,
      fov: 35,
      easing: "linear",
    },
    // [0:27] Entity passes — look toward where it went
    {
      time: 27,
      mode: "scripted",
      position: { x: -15.5, y: 4.5, z: 25.5 },
      lookAt: ENTITY_PAST_LOCKER,
      fov: 40,
      easing: "ease_out",
    },
    // [0:28] Hold — subtle camera drift
    {
      time: 28,
      mode: "scripted",
      position: { x: -15.5, y: 5, z: 25.5 },
      lookAt: { x: -20, y: 5, z: 30 },
      fov: 45,
      easing: "ease_in_out",
    },
  ],

  actions: [
    // [0:00] Set dark corridor lighting
    {
      time: 0,
      type: "set_lighting",
      params: {
        Brightness: 0,
        Ambient: { R: 0.02, G: 0.02, B: 0.03 },
        OutdoorAmbient: { R: 0, G: 0, B: 0 },
        ClockTime: 0,
        FogEnd: 100,
        FogColor: { R: 0.05, G: 0.05, B: 0.07 },
      },
    },
    // [0:00] Place player at corridor start
    {
      time: 0,
      type: "teleport_player",
      params: { position: CORRIDOR_START },
    },
    // [0:00] Start the round (so client systems initialize)
    {
      time: 0.5,
      type: "start_round",
      params: {},
    },
    // [0:04] Teleport player further (simulating walk)
    {
      time: 4,
      type: "teleport_player",
      params: { position: CORRIDOR_MID },
    },
    // [0:07] Activate entity — The Patient appears at far end
    {
      time: 7,
      type: "entity_activate",
      params: {
        name: "ThePatient",
        position: ENTITY_SPAWN,
        state: "Idle",
      },
    },
    // [0:07] Entity state: Idle (standing motionless)
    {
      time: 7,
      type: "entity_transition",
      params: { state: "Idle" },
    },
    // [0:12] Entity starts investigating (head tilt)
    {
      time: 12,
      type: "entity_transition",
      params: { state: "Investigate" },
    },
    // [0:13] Entity moves closer
    {
      time: 13,
      type: "entity_set_position",
      params: {
        name: "ThePatient",
        position: ENTITY_APPROACH_1,
        state: "Investigate",
      },
    },
    // [0:15] Entity transitions to Hunt
    {
      time: 15,
      type: "entity_transition",
      params: { state: "Hunt" },
    },
    {
      time: 15,
      type: "entity_target_player",
      params: { name: "ThePatient", state: "Hunt" },
    },
    // [0:16] Entity advances
    {
      time: 16,
      type: "entity_set_position",
      params: {
        name: "ThePatient",
        position: ENTITY_APPROACH_2,
        state: "Hunt",
      },
    },
    // [0:18] Entity transitions to Chase
    {
      time: 18,
      type: "entity_transition",
      params: { state: "Chase" },
    },
    {
      time: 18.5,
      type: "entity_set_position",
      params: {
        name: "ThePatient",
        position: ENTITY_CHASE_1,
        state: "Chase",
      },
    },
    // [0:19] Player sprints — teleport to simulate running
    {
      time: 19,
      type: "teleport_player",
      params: { position: { x: -18, y: 5, z: 20 } },
    },
    {
      time: 19.5,
      type: "entity_set_position",
      params: {
        name: "ThePatient",
        position: ENTITY_CHASE_2,
        state: "Chase",
      },
    },
    // [0:20] Player approaching locker
    {
      time: 20,
      type: "teleport_player",
      params: { position: { x: -16, y: 5, z: 24 } },
    },
    // [0:21] Player at locker (hiding)
    {
      time: 21,
      type: "teleport_player",
      params: { position: LOCKER_POS },
    },
    // [0:22] Entity transitions to Search (lost player)
    {
      time: 22,
      type: "entity_transition",
      params: { state: "Search" },
    },
    // [0:24] Entity approaches locker area
    {
      time: 24,
      type: "entity_set_position",
      params: {
        name: "ThePatient",
        position: ENTITY_PASS_LOCKER,
        state: "Search",
      },
    },
    // [0:26] Entity passes locker
    {
      time: 26,
      type: "entity_set_position",
      params: {
        name: "ThePatient",
        position: ENTITY_PAST_LOCKER,
        state: "Search",
      },
    },
    // [0:27] Entity moves away — tension release
    {
      time: 27,
      type: "entity_set_position",
      params: {
        name: "ThePatient",
        position: { x: -20, y: 5, z: 55 },
        state: "Patrol",
      },
    },
    {
      time: 27,
      type: "entity_transition",
      params: { state: "Patrol" },
    },
  ],

  markers: [
    { time: 0, label: "cold-open" },
    { time: 4, label: "wheelchair-reveal" },
    { time: 7, label: "entity-spotted" },
    { time: 12, label: "freeze-moment" },
    { time: 15, label: "entity-advances" },
    { time: 19, label: "chase-begins" },
    { time: 21, label: "locker-hide" },
    { time: 25, label: "entity-passes" },
    { time: 28, label: "logo-card" },
  ],
};

export default choreography;
