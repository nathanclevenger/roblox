# Dev Diary: How Drawing Becomes Reality
> Composition: DevDiary
> Duration: 90s
> Aspect: 16:9

## Voiceover
[0:00] So the question we kept asking ourselves was: how do you take a line someone draws on a flat screen and turn it into a real, physical object in a 3D world?
[0:10] Let me show you how it works.
[0:12] When you draw on the canvas, we are capturing every single stroke as a series of points. [pause] Your pencil position, the pressure, the speed — all of it.
[0:22] Those points get connected into a closed polygon. Then we extrude that shape into 3D space. [pause] Basically, we give your drawing depth.
[0:32] But here is where it gets interesting. The shape alone is not enough. We need physics.
[0:38] Every material in Draw to Escape has real physical properties. Density. Friction. Elasticity. Buoyancy. Conductivity.
[0:48] [pause] Watch this. Same shape — a simple rectangle. Same size. But I am going to spawn it with three different materials.
[0:56] Wood. It has low density, so it floats. High friction, so things grip it. And it is flammable — keep it away from lava.
[1:04] Now the same shape in Stone. Much denser, so it sinks immediately. But it can take a hit. It will not break when something heavy lands on it.
[1:12] And Balloon. Almost zero density. This thing wants to fly. It will lift off the ground and carry anything light enough with it.
[1:20] [pause] Same drawing. Completely different gameplay.
[1:24] And then there are the weirder materials. Metal conducts electricity — so if lightning hits your metal bridge, anything standing on it gets shocked. Rubber bounces and insulates. Ice is slippery and transparent. Magnet pulls metal toward it. Glass shatters on impact but lets light through.
[1:40] Every line you draw has weight, friction, and physics. Your drawing is not decoration. [pause] It is engineering.
[1:48] [pause] That is the system. Simple to use, deep to master. We can not wait to see what you build.
[1:54] Draw to Escape. Coming soon to Roblox.

## Visual Direction
Shot-by-shot breakdown with timestamps:

**Intro — The Question [0:00-0:12]**
- [0:00-0:05] Developer PiP (picture-in-picture) in the bottom-left corner — face cam, casual setting, natural lighting. Main screen shows a timelapse of early prototype footage: crude placeholder art, basic rectangles appearing in 3D space. The early jank is charming and authentic.
- [0:05-0:10] PiP stays. Main screen transitions to the current game — polished version of the same mechanic. Side-by-side comparison: prototype vs. final. The improvement is dramatic.
- [0:10-0:12] Main screen: Clean shot of the in-game drawing canvas opening. PiP shrinks slightly as the demonstration begins.

**Part 1 — Stroke Capture [0:12-0:32]**
- [0:12-0:18] Main screen shows the 2D drawing canvas in full. A hand draws a shape slowly — the individual stroke points are visualized as glowing dots along the path. A debug overlay shows the point data accumulating in real-time: coordinates, timestamps, spacing. PiP shows the developer narrating.
- [0:18-0:22] The dots connect into a polygon outline. The polygon fills with a soft color. A code snippet appears in a floating PiP panel (upper right): a Luau code block showing the stroke-to-polygon conversion — `CatmullRomSpline`, point sampling, polygon closing logic. The code scrolls slowly enough to be readable but the viewer does not need to read it all.
- [0:22-0:28] The 2D polygon lifts off the canvas surface. A visualization shows the extrusion process — the flat shape gains depth, becoming a 3D mesh. The camera rotates around the newly formed object. Wireframe overlay shows the mesh geometry — triangulated faces, vertex normals. The code PiP updates to show the extrusion logic.
- [0:28-0:32] The object drops into the 3D game world. A physics debug overlay shows the collider being generated around the mesh. Gravity takes effect and the object settles onto the ground. The transition from "digital model" to "physical game object" is shown as a single smooth moment.

**Part 2 — Material Properties [0:32-0:56]**
- [0:32-0:38] Main screen: A clean material selection UI. The 9 material icons are displayed in a grid. As each is highlighted, a floating properties panel shows its stats: Density, Friction, Elasticity, Buoyancy, Conductivity, Special (flammable, transparent, magnetic, etc.). The code PiP shows the material property table — a clean Luau dictionary with all the values.
- [0:38-0:48] Close-up on a simple drawn rectangle sitting on the canvas. The material selector is visible. The developer hovers over each material, and the rectangle's appearance changes in real-time — wood grain texture, stone roughness, balloon translucency. The preview updates before spawning.
- [0:48-0:56] Split into three vertical panels. Each panel shows the same rectangle shape about to be spawned in the same position — above a pool of water. A countdown "3, 2, 1" and all three spawn simultaneously.

**Part 3 — Material Demos [0:56-1:20]**
- [0:56-1:04] Left panel (WOOD): The wooden rectangle drops, hits the water surface, and floats. It bobs gently. A physics debug overlay shows the buoyancy force arrows pushing upward. A small character stands on it — it holds. Close-up on the wood grain texture. Then a lava block slides nearby — the wood catches fire and burns away.
- [1:04-1:12] Center panel (STONE): The stone rectangle drops, hits the water surface, and sinks immediately. Bubbles rise. It settles on the bottom. A physics overlay shows the gravity force far exceeding buoyancy. Then a heavy anvil drops on it from above — the stone holds, doesn't crack. Durable.
- [1:12-1:20] Right panel (BALLOON): The balloon rectangle drops, but instead of falling, it floats upward. It rises off the ground, drifts above the water, keeps rising. The physics overlay shows buoyancy exceeding gravity by a wide margin. A small character grabs onto it and is lifted into the air. They look down nervously.
- [1:20-1:24] The three panels merge back into a single frame. A side-by-side replay in miniature: float, sink, fly. Same shape. Different outcomes.

**Part 4 — Advanced Materials [1:24-1:48]**
- [1:24-1:30] Quick demo: METAL bridge. Lightning strikes it. Electricity arcs along the entire surface in a visually stunning flash. A character standing on it gets shocked and ragdolls off. Cut to RUBBER bridge — same lightning strike, electricity dissipates harmlessly. Character is fine.
- [1:30-1:34] Quick demo: ICE ramp. Character slides down it at high speed, completely frictionless. The transparency lets them see through it to the path below. It is both a tool and a window.
- [1:34-1:38] Quick demo: MAGNET block placed near metal objects. The metal objects slide toward it, snapping into place. A puzzle being solved by magnetic attraction — a metal key pulled across a gap to a magnet-drawn platform.
- [1:38-1:42] Quick demo: GLASS dome. Light passes through it, illuminating the inside. A rock falls on it and it shatters into fragments. The fragments scatter with realistic physics. Beautiful but fragile.
- [1:42-1:48] Full PiP of the developer returns to prominence. They gesture while delivering the "engineering" line. Behind them, a monitor shows a complex drawing being materialized — a player-created Rube Goldberg machine using multiple materials in sequence.

**Outro [1:48-1:56]**
- [1:48-1:52] Developer PiP fades. Main screen shows a gallery of player-created drawings in-game — the most creative, beautiful, and absurd solutions from playtesting. A slow pan across them. Each one is unique.
- [1:52-1:54] Draw to Escape logo, sketched in the same style as the game's drawings. The logo gains depth and materializes, just like an in-game object.
- [1:54-1:56] "Coming Soon to Roblox" text beneath the logo. Social media handles. Dev studio name.

## Audio Notes
- **Music**: Subtle, intelligent underscore. Not driving the pace — supporting the explanation. Ambient electronic with light piano. Think Kurzgesagt or Noclip documentary vibes. Slightly brighter during the material demos. Gentle swell during the "engineering" closing line. Warm resolution for the outro.
- **SFX**: Pencil drawing sounds during all canvas demonstrations. Physics-appropriate sounds for each material demo — wood splashing, stone sinking with a deep "glub," balloon whooshing upward, metal conducting with an electric crackle, ice sliding with a glassy hiss, magnet pulling with a low hum, glass shattering with a crystalline crash. The debug overlays get a subtle UI sound — soft clicks and hums — to feel technical without being distracting.
- **Voiceover style**: The developer's natural speaking voice. Not overly polished or narrated — it should feel like a real person explaining their work with genuine passion. Occasional "um"s or natural speech patterns are fine and even preferred. The tone is educational and excited. They clearly love this system.

## Render Notes
- 16:9 widescreen. This is a dev diary, so the production value is intentionally one step below the main trailer — polished but authentic.
- PiP (picture-in-picture) of the developer is present throughout but varies in size: larger during talking-head segments, smaller during gameplay demonstrations.
- Code snippets shown on screen should be real Luau — syntactically correct, with proper `--!strict` annotations and type hints. They should be readable but viewers are not expected to parse them fully. The code serves as a credibility signal.
- The physics debug overlays (force arrows, collider wireframes, property readouts) should look like actual development tools — monospace text, colored arrows, wireframe rendering. They sell the "under the hood" feeling.
- Color grade: Clean, neutral, well-lit. Slightly cooler than the main trailer. The gameplay footage should match the game's native look.
- Pacing: Slower than the TikToks. Give each demo room to breathe. The viewer should have time to observe each material's behavior. This is education, not hype.
- Subtitles: Include full subtitles for the developer VO. Positioned at the bottom, clean font, high contrast background.
