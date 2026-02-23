# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Roblox Luau project: A* pathfinding library + procedural map generator for an abandoned mental asylum. No external tooling or dependencies beyond the Roblox engine runtime.

- **Pathfinding.lua** — A* pathfinding module. Public: `findPath`, `smoothPath`, `getRandomWalkablePosition`, `isPathValid`, `visualize`, `findPathMultiFloor`. Helpers (`toGrid`, `toKey`, `heuristic`, `isWalkable`, `MinHeap`) are module-private `local`s.
- **MapGenerator.lua** — Procedural map generator. Grid-based room stamping on a 24-stud slot grid. Public: `generate(config)`, `getFloorConnections()`, `cleanup()`. Builds physical parts (walls, floors, ceilings, doors, stairs, furniture), exterior shell, forest, and rain.
- **RoomTemplates.lua** — Room template data (9 types: Hallway, Lobby, Stairwell, PatientRoom, PaddedCell, OperatingRoom, Bathroom, Office, StorageRoom). Public: `templates`, `getWeightedList()`, `pickRandom(rng)`.
- **ExampleUsage.lua** — Demo NPC script showing a WANDER/PURSUE state machine that imports the pathfinding library.

## Build / Test / Lint

No build system, test framework, linter, or formatter is configured. Testing is done manually in Roblox Studio. There is no Rojo, Wally, Aftman, or CI setup.

## Architecture

**Grid-based A\* pathfinding on the XZ plane:**
- World positions are snapped to a `GRID_SIZE = 4` stud grid via `toGrid()`
- 8-directional movement (4 cardinal + 4 diagonal), all flat (Y=0 deltas)
- Walkability is determined at runtime via two raycasts per cell (ground detection + overhead clearance), not a pre-baked navmesh
- `Vector3` values are serialized to `"X,Y,Z"` strings for use as hash table keys (Lua tables lack value-equality for userdata)
- Open set uses a custom `MinHeap` priority queue sorted by f-score

**Path post-processing (`smoothPath`) is a two-stage pipeline:**
1. Line-of-sight simplification — removes redundant waypoints by raycasting ahead
2. Catmull-Rom spline interpolation — inserts smooth intermediate points (X/Z only; Y held flat)

**Multi-floor pathfinding (`findPathMultiFloor`):**
- Chains single-floor `findPath` calls through stairwell connections
- Inserts interpolated stair-traversal waypoints between floors
- Returns a single unified `{Vector3}` array spanning all floors

**Map generator (`MapGenerator.generate`):**
- Each floor is a 2D grid of 24x24-stud slots (`SLOT_SIZE=24`, `FLOOR_HEIGHT=16`)
- Generation pipeline: place stairwell → lobby → grow hallways → fill rooms → carve doors → ensure solvability (flood fill) → apply conditions → place furniture → build parts → exterior → forest → rain
- Solvability guaranteed via flood fill from stairwell with forced door connections for unreachable rooms
- Seeded RNG (`Random.new(seed)`) for reproducible generation
- Room templates define grid size, door edges, materials, furniture slots, and condition overlays

**Example NPC architecture:**
- Two-state FSM (WANDER ↔ PURSUE) with a background `task.spawn` coroutine that validates the current path every 0.25s
- Event-driven map invalidation via `workspace.DescendantAdded`/`DescendantRemoving` signals on collidable `BasePart`s

## Code Conventions

- Luau with type annotations (`position: Vector3`, `path: { Vector3 }`, `?` for optionals)
- Tab indentation
- `SCREAMING_SNAKE_CASE` for constants, `camelCase` for variables/functions
- Single-file module pattern: `local M = {} ... return M`
- Private functions are `local`, public API is attached to the returned module table
