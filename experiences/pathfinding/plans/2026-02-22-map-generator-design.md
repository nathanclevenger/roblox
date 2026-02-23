# Map Generator Design: Abandoned Mental Asylum

## Overview

A hybrid procedural map generator that assembles preset room templates into a multi-floor abandoned mental asylum, surrounded by a simple forest with rain. Integrates with the existing A* pathfinding library for seamless NPC navigation across floors.

## Setting

Abandoned mental asylum in a rainy forest. 2-3 floors. Interior rooms are decayed, with procedural variation in condition (flooded, collapsed, boarded up). Exterior is a simple forest with rain.

## Approach: Grid-Based Room Stamping

Each floor is a 2D grid of slots (e.g. 8x6). Room templates occupy 1+ slots. The generator fills the grid with rooms connected by hallways, carves doorways, applies procedural variation, and builds the physical Roblox parts.

### Grid Dimensions

- Grid slot size: **24x24 studs** (divisible by pathfinding `GRID_SIZE = 4`, giving 6x6 pathfinding nodes per slot)
- Floor height: **16 studs**
- Each floor built at `Y = floorIndex * 16`

## Room Template System

Each template defines:
- **type** — `"PatientRoom"`, `"Hallway"`, `"OperatingRoom"`, `"PaddedCell"`, `"Bathroom"`, `"Office"`, `"StorageRoom"`, `"Lobby"`, `"Stairwell"`
- **gridSize** — slots occupied (e.g. `{x=1, z=1}`, `{x=2, z=1}`)
- **doorPositions** — which edges can have doors (`"north"`, `"south"`, `"east"`, `"west"`)
- **floorMaterial/wallMaterial** — base materials
- **furnitureSlots** — named positions for prop placement
- **conditions** — possible overlays: `"normal"`, `"flooded"`, `"collapsed"`, `"boarded"`

The stairwell template spans the full 16-stud floor height with a staircase connecting to the floor above.

## Floor Generation Algorithm

1. **Place stairwell** — Floor 1: random interior position. Floors 2+: same grid position (vertical alignment).
2. **Place lobby** (floor 1 only) — Adjacent to building entrance at grid edge.
3. **Grow hallways** — Random walk from stairwell favoring straight lines. 1-slot wide.
4. **Fill rooms** — Empty slots adjacent to hallways get room templates. Type selection is weighted (more patient rooms, fewer operating rooms). Multi-slot rooms claim adjacent empty slots.
5. **Carve doors** — Door frames between adjacent rooms/hallways where `doorPositions` align. At least one door per room guaranteed.
6. **Apply conditions** — Random rooms marked flooded/collapsed/boarded. Worse conditions on deeper floors.
7. **Place furniture** — Fill `furnitureSlots` per room type with random variation (some slots empty for abandoned feel).

### Solvability Guarantee

After generation, flood-fill from the lobby. Any unreachable room gets connected by forcing open an adjacent door or carving a hallway. Every stairwell on every floor must be reachable from the lobby. No locked doors in this iteration — all rooms are physically reachable.

## Pathfinding Integration

### Same-Floor Navigation

Existing `Pathfinding.findPath` works automatically via raycasting once walls/floors are placed as `BasePart`s. No changes needed.

### Multi-Floor Navigation

New function `Pathfinding.findPathMultiFloor(startPos, targetPos, floorConnections)`:

1. Determine start/target floor from Y position
2. Same floor: delegate to `findPath`
3. Different floors: build high-level plan (start -> stairwell -> intermediate stairs -> target floor stairwell -> target)
4. Call `findPath` for each floor segment
5. Insert stair-traversal waypoints between segments
6. Return single concatenated `{Vector3}` array

### Room Metadata

Generated floor `BasePart`s tagged with `RoomType` attribute. Stairwell zones marked for NPC floor reasoning.

## Exterior & Atmosphere

- **Building shell** — Exterior walls wrap grid footprint. Main entrance on one side. Broken/boarded windows on upper floors.
- **Forest** — Trees scattered 100-200 studs around building using Poisson disk sampling. Density increases with distance. Simple geometry: cylinder trunk + cone/sphere canopy.
- **Terrain** — Flat ground plane with grass material.
- **Rain** — `ParticleEmitter` on large transparent part above map. Downward-falling rain particles. No lightning.

## File Structure

| File | Purpose |
|------|---------|
| `MapGenerator.lua` | Main module — orchestrates generation, public API |
| `RoomTemplates.lua` | Room template definitions |
| `Pathfinding.lua` | Extended with `findPathMultiFloor` |

## Public API

```lua
-- MapGenerator
MapGenerator.generate(config) -> MapData
-- config: { floors: number, gridWidth: number, gridDepth: number, seed: number? }

MapGenerator.getFloorConnections() -> { [floorIndex]: { Vector3 } }
-- Stairwell positions per floor

MapGenerator.cleanup()
-- Destroys all generated parts

-- Pathfinding (addition)
Pathfinding.findPathMultiFloor(startPos, targetPos, floorConnections) -> { Vector3 }?
```
