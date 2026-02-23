# Dev Diary: Building 10 Worlds From Code
> Composition: DevDiary
> Duration: 90s
> Aspect: 16:9

## Voiceover
[0:00] Every stage in Draw to Escape was built entirely from code. No dragging parts in Studio. No manual placement. Just Luau scripts generating fifty stages across ten themed zones.
[0:12] Let me show you how.
[0:14] [pause] Zone 1 — the Sketch Fields. This is where every player begins. Bright, welcoming, simple geometry.
[0:22] Under the hood, it's a procedural layout system. The stage generator takes a zone config table — dimensions, gap sizes, hazard types — and builds the entire stage from those parameters.
[0:33] Each zone has its own config. The Sketch Fields get wide platforms, small gaps, no hazards. Forgiving. But as the zones progress, the configs tighten.
[0:42] Zone 4 — the Watercolor Wetlands — introduces flowing water. The current system uses BodyVelocity forces on any part that touches the water volume. Your drawings get pushed downstream. You have to account for drift.
[0:54] Zone 6 — the Neon Grid — flips gravity. One line of code: workspace.Gravity is set to negative. Everything inverts. Your drawings still obey physics, but now "up" is "down." Players have to rewire their spatial reasoning.
[1:03] Zone 8 — the Storm Peaks — runs a weather system. A coroutine loop picks random positions above the stage and fires lightning bolts. If the bolt hits a Metal drawing, it conducts. Rubber is safe. The player has to think about material choice, not just shape.
[1:16] And then there's Zone 9 — the Void. [pause] The Void generates nothing. That's the point. No floor. No walls. No skybox. The player builds the entire stage from their own drawings. The only authored element is a single spawn tile and an exit marker. Everything between is imagination.
[1:32] The final zone — The Cliff — is a vertical stage. The generator stacks platforms upward instead of forward. Wind forces increase with altitude. Lightning frequency scales. And at Stage 50, the gap between you and the summit is tuned to be just barely unsolvable with a single straight drawing. You have to get creative.
[1:48] [pause] Here's what the zone progression looks like when you lay them end to end.
[1:53] [no VO — zone showcase montage]
[2:18] Ten zones. Fifty stages. Nine materials. All generated from about two thousand lines of Luau. [pause] No Studio GUI required.
[2:27] That's Draw to Escape.

## Visual Direction
Shot-by-shot breakdown with timestamps:

**Intro [0:00-0:14]**
- [0:00-0:06] Developer PiP in bottom-right corner (small, circular frame). Main screen shows a split view: on the left, a VS Code / code editor window with a Luau file open; on the right, a Roblox Studio viewport showing an empty baseplate. The developer speaks directly to camera.
- [0:06-0:12] The editor executes the build script. On the right, the empty baseplate erupts with geometry — platforms, gaps, walls, decorations all spawning in rapid succession. The camera in Studio orbits slowly as the Sketch Fields zone assembles itself in real time. Parts appear in sequence: floor tiles first, then walls, then decorative elements. The PiP developer watches it build with a knowing nod.
- [0:12-0:14] Quick transition: the editor fills the full screen for a beat, showing the top of the zone config file. Camera pushes in on the code.

**Zone 1 — Sketch Fields [0:14-0:33]**
- [0:14-0:22] Full-screen gameplay footage of the Sketch Fields. Bright green meadow, hand-drawn clouds, warm sunlight. Camera flies through stages 1-5 in a smooth tracking shot, showing the generous platforms, small gaps, and friendly geometry. A player character runs through, drawing simple bridges. Everything feels safe and inviting.
- [0:22-0:28] Code snippet overlay (semi-transparent, positioned in the lower third). The code shows a zone config table:
```luau
--!strict
local SketchFieldsConfig: ZoneConfig = {
    zoneName = "Sketch Fields",
    stageRange = { first = 1, last = 5 },
    platformWidth = { min = 12, max = 20 },
    gapSize = { min = 8, max = 14 },
    hazards = {},
    skyColor = Color3.fromRGB(135, 206, 235),
    ambientColor = Color3.fromRGB(180, 220, 160),
    material = Enum.Material.SmoothPlastic,
}
```
The code highlights line by line as the VO explains the config system. In the background, the Sketch Fields are visible, soft-focused.
- [0:28-0:33] Side-by-side comparison. Left panel: the zone config for Sketch Fields (wide platforms, small gaps, no hazards). Right panel: the zone config for Storm Peaks (narrow platforms, large gaps, lightning hazard). The numbers visually contrast — the difficulty curve is visible in the data. Key values glow when the VO mentions "configs tighten."

**Zone 4 — Watercolor Wetlands [0:33-0:54]**
- [0:33-0:42] Gameplay footage of the Wetlands. Soft pastel palette — lavender water, pink lily pads, peach-colored fog. A player draws a wooden boat and places it on the water. The boat begins drifting downstream. The player compensates by angling their next drawing upstream.
- [0:42-0:50] Code snippet overlay. The water current system:
```luau
local function applyCurrentForce(part: BasePart): ()
    if not part:IsDescendantOf(waterVolume) then
        return
    end
    local force = Instance.new("BodyVelocity")
    force.Velocity = currentDirection * currentSpeed
    force.MaxForce = Vector3.new(5000, 0, 5000)
    force.Parent = part
    task.delay(part:GetAttribute("Lifetime") or 10, function()
        force:Destroy()
    end)
end
```
The camera stays on the Wetlands gameplay in the background, showing the current pushing a drawing sideways as the code explains why.
- [0:50-0:54] Quick gameplay moment: a player's drawing drifts into a wall and wedges itself, creating an accidental dam. Water particle effects pool behind it. The developer in PiP chuckles. "You have to account for drift."

**Zone 6 — Neon Grid [0:54-1:03]**
- [0:54-0:58] Hard cut to the Neon Grid. Dramatic visual shift — dark wireframe landscape, glowing cyan and magenta grid lines, pulsing geometric shapes. The camera flips upside down as the VO says "flips gravity." The player runs on the ceiling.
- [0:58-1:03] Code snippet, clean and simple:
```luau
local function applyGravityFlip(zone: ZoneConfig): ()
    if zone.gravityFlip then
        workspace.Gravity = -196.2
    else
        workspace.Gravity = 196.2
    end
end
```
The simplicity is the point — one property change transforms the entire experience. Gameplay shows a player drawing a platform "above" them (which is actually below, since gravity is inverted). The platform falls upward and locks into place on the ceiling-floor.

**Zone 8 — Storm Peaks [1:03-1:16]**
- [1:03-1:08] Wide establishing shot of the Storm Peaks. Jagged dark mountains. Storm clouds swirl overhead. Rain particles streak across the screen. A lightning bolt strikes a metal drawing on a distant platform, sending sparks cascading. The atmosphere is hostile.
- [1:08-1:16] Code snippet — the lightning system:
```luau
task.spawn(function()
    while stormActive do
        task.wait(lightningInterval)
        local strikePos = getRandomStrikePosition(stageArea)
        local bolt = createLightningBolt(strikePos)
        bolt.Parent = workspace

        local hitParts = workspace:GetPartBoundsInRadius(strikePos, 8)
        for _, part in hitParts do
            if part:GetAttribute("Material") == "Metal" then
                conductElectricity(part)
            end
        end
    end
end)
```
As the code scrolls, gameplay shows a player drawing a rubber platform (highlighted in the UI material selector) while lightning strikes around them. They are safe. Cut to another player choosing metal — the lightning finds the metal drawing and arcs through it. Death screen flash.

**Zone 9 — The Void [1:16-1:32]**
- [1:16-1:22] The screen goes black. Not dark — black. Absolute emptiness. A single glowing tile fades in at the center of the frame. A player character stands on it. The camera slowly orbits. There is nothing else.
- [1:22-1:28] Code snippet — the Void generator:
```luau
local VoidConfig: ZoneConfig = {
    zoneName = "The Void",
    stageRange = { first = 41, last = 45 },
    platformWidth = { min = 0, max = 0 },
    gapSize = { min = 0, max = 0 },
    hazards = {},
    generateGeometry = false,
    spawnTile = true,
    exitMarker = true,
}
```
The config is almost empty — that is the design. The VO pauses on "generates nothing." The contrast between this sparse config and the Sketch Fields config shown earlier is striking.
- [1:28-1:32] Time-lapse: a player builds a path through the Void from their drawings. The camera pulls back steadily, revealing an intricate constellation of glowing drawn objects — platforms, bridges, ramps — floating in the dark. It looks like a galaxy made of imagination.

**Zone 10 — The Cliff [1:32-1:48]**
- [1:32-1:38] Dramatic vertical reveal. Camera starts at the base of The Cliff and tilts upward — a towering procedural structure of stacked platforms, jutting ledges, and narrow handholds stretching impossibly high. Wind particles streak horizontally. Lightning flashes illuminate the structure from above.
- [1:38-1:44] Code snippet — the vertical stage generator and scaling difficulty:
```luau
local function generateCliffStage(stageNum: number, baseHeight: number): ()
    local altitude = baseHeight + (stageNum - 46) * CLIFF_STAGE_HEIGHT
    local windForce = BASE_WIND * (1 + altitude / MAX_ALTITUDE)
    local lightningFreq = BASE_LIGHTNING_FREQ * (1 + altitude / MAX_ALTITUDE)

    local platform = createPlatform({
        position = Vector3.new(0, altitude, 0),
        width = math.max(6, 14 - (stageNum - 46) * 2),
        depth = math.max(4, 10 - (stageNum - 46)),
    })
    platform.Parent = workspace
end
```
As the code displays, the gameplay shows the platforms getting narrower and the wind getting stronger as the player climbs. The numbers in the code map directly to what the viewer sees on screen.
- [1:44-1:48] Stage 50. The final gap. The camera frames the player on one side and the summit on the other. The gap is visible — just slightly too far. The developer in PiP says "just barely unsolvable with a single straight drawing" while the player on screen stares at the distance, opens the canvas, and starts drawing something creative.

**Zone Showcase Montage [1:48-2:18]**
- [1:48-1:53] Transition: the screen splits into a horizontal filmstrip-style layout. A progress bar appears at the bottom with zone names marked along it.
- [1:53-2:18] Each zone gets 2.5 seconds of its most visually striking moment, presented in sequence:
  1. **Sketch Fields** [1:53-1:55]: Bright meadow, player running across a drawn bridge with doodle flowers bobbing.
  2. **Paper Forest** [1:55-1:58]: Camera soaring through paper-craft canopy, translucent paper leaves catching golden light.
  3. **Crayon Caverns** [1:58-2:00]: Neon drawing illuminating a vast cavern of crayon-scrawled walls, color exploding outward.
  4. **Watercolor Wetlands** [2:00-2:03]: Pastel lake, a drawn boat cutting through gentle current, a watercolor fish breaching in the background.
  5. **Ink Ruins** [2:03-2:05]: Player sprinting across crumbling ink tiles, drawing replacement platforms mid-stride, frantic and kinetic.
  6. **Neon Grid** [2:05-2:08]: Inverted gravity, player running on the ceiling past glowing laser grids, neon reflections everywhere.
  7. **Living Canvas** [2:08-2:10]: A hostile sketch creature lunging at the player, who draws a cage around it at the last second.
  8. **Storm Peaks** [2:10-2:13]: Lightning striking a mountaintop, player huddled under a rubber dome, electricity arcing around them.
  9. **The Void** [2:13-2:15]: A single glowing path built by the player, floating in infinite darkness — haunting and beautiful.
  10. **The Cliff** [2:15-2:18]: Player launching off a balloon ramp at the summit, golden light exploding, three stars bursting.
- Each zone transition uses an "ink wash" wipe that matches the incoming zone's color palette. The progress bar fills as each zone passes.

**Outro [2:18-2:30]**
- [2:18-2:22] Developer PiP returns to full prominence. The code editor is visible behind them, showing the project file tree: `src/server/`, `src/shared/zones/`, `src/shared/materials/`. The developer speaks the closing lines directly to camera.
- [2:22-2:27] The code editor zooms into the `wc -l` output of the codebase — the line count. "About two thousand lines of Luau." The number is visible on screen.
- [2:27-2:30] Draw to Escape logo sketches itself in, centered. Beneath it: "Built with Luau. No Studio GUI required." Smaller text: "Play Free on Roblox." Social handles in the corner. The developer PiP gives a small wave and fades out.

## Audio Notes
- **Music**: Ambient, documentary-style electronic track. Warm pads, soft arpeggiated synths, a gentle pulse. The music serves the VO — it supports without competing. Think "behind the scenes" energy — curious, inviting, intellectual.
  - [0:00-0:14]: Minimal. Soft pad and quiet clicks, like a keyboard being typed on.
  - [0:14-1:48]: The track builds incrementally with each zone. New instruments layer in subtly — a bass note for the Wetlands, a synth arpeggio for the Neon Grid, a distorted guitar swell for the Storm Peaks. By the Void, the music strips back to almost nothing — a single sustained tone. The Cliff brings everything back with a building crescendo.
  - [1:48-2:18]: The zone montage gets a more energetic mix — the same track but with drums entering for the first time, driving the pace.
  - [2:18-2:30]: Resolution. Music decays to the same soft pad and clicks from the opening. Circular.
- **SFX**:
  - Code editor sounds: Subtle keyboard clacks when code appears on screen. A soft "run" beep when the build script executes.
  - Zone-specific ambience layered under the VO for each zone section: birdsong for Sketch Fields, dripping water for Caverns, rain for Storm Peaks, absolute silence for the Void.
  - Materialization sounds during gameplay clips are present but mixed low — this is a dev diary, not a hype reel.
  - The zone montage at [1:53-2:18] gets the full SFX treatment — each zone's signature sound hits during its 2.5-second window.
- **VO style**: The developer speaking. Knowledgeable, conversational, slightly nerdy. Not a polished narrator — someone who built this thing and is genuinely proud to explain it. Pacing is unhurried. They pause when showing code, letting the viewer read. Technical terms are used naturally but not over-explained.

## Render Notes
- 16:9 widescreen. This is long-form content — YouTube landscape format.
- Developer PiP: Circular frame, bottom-right corner, approximately 15% of screen width. Well-lit, clean background. The PiP fades in and out based on whether the developer is speaking directly to camera vs. narrating over footage. It should never obstruct code snippets or critical gameplay.
- Code snippets: Use a clean dark theme (VS Code Dark+ or similar). Syntax highlighting must be accurate for Luau. Font size should be large enough to read on mobile — minimum 18pt equivalent on a 1080p export. Code appears line by line or in highlighted blocks timed to the VO.
- Split views and side-by-side comparisons should use clean dividers. No busy UI — the content is already information-dense.
- Color grade: Natural and documentary-feeling for the dev diary sections. Each zone's gameplay footage should use that zone's native palette without additional grading. The zone montage at [1:53-2:18] is the most visually vivid section — let the colors pop.
- Camera work in gameplay sections: Smooth, controlled orbits and tracking shots. This is a showcase, not a play session — the camera should feel authored and intentional. The Void orbit at [1:16-1:22] should be especially slow and deliberate.
- Pacing: Slower than the TikTok formats. Let the code breathe. Let the zones breathe. The audience for this video is people who want to understand how the game works, not just see it in action. Every shot should hold long enough to absorb.
- Text overlays: Zone names should appear briefly (1.5 seconds) in the lower-left when each zone is first shown. Code snippet overlays should have a slight drop shadow or background blur to maintain readability over gameplay footage.
- The zone montage progress bar should be minimal — a thin line with small zone name labels. It provides orientation without dominating the frame.