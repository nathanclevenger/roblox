# The Origin — Dev Diary: The Fear System
> Composition: DevDiary
> Duration: 90s
> Aspect: 16:9

## Voiceover
[Developer voice — casual, enthusiastic, technical but accessible. Not scripted-sounding. Think: someone explaining their passion project to a friend who's also a gamer. Natural speech patterns with occasional self-corrections. No reverb — clean, close-mic, podcast quality.]

[0:00-0:05] "So one of the things I'm most proud of in The Origin is the fear system. And I want to break down exactly how it works, because I think it's what makes the game actually scary — not just jumpscare-scary, but like... dread."

[0:05-0:10] "Okay, so the core idea is really simple. Your proximity to the entity determines your fear tier. Five tiers. And each tier stacks more effects on top of the last one."

[0:10-0:18] "Let me show you. So right now, I'm at Safe — the entity is more than 80 studs away. The screen looks normal. Audio is normal. You're just... exploring. It's actually kind of peaceful. That's on purpose — because the contrast is what makes the fear work."

[0:18-0:27] "Now watch — I'm going to walk toward where the entity is patrolling. And... there. You see that? We just crossed into Unease. That's 50 to 80 studs away. The colors start desaturating — really subtle, like maybe 15 percent. And there's this low ambient drone that fades in. Most players don't consciously notice this tier. But their body does."

[0:27-0:38] "Getting closer. Okay, now we're in Dread — 25 to 50 studs. This is where it gets real. Heartbeat audio kicks in. The vignette starts closing in around the edges of your screen. And here — this is cool — we start layering in whisper audio. It's unintelligible, just enough to make your brain think someone's behind you. The desaturation is heavier now, maybe 40 percent. The world is losing its color."

[0:38-0:50] "Alright, I'm pushing into Panic — 10 to 25 studs. The heartbeat gets faster, the vignette gets tighter, and now we add screen shake. Subtle — we don't want motion sickness — but enough that the world feels unstable. And the whispers get louder. If you're wearing headphones — which you should be — this is where people usually start holding their breath in real life."

[0:50-1:02] "And then... Proximity. Zero to ten studs. The entity is right there. Everything stacks. Heartbeat is pounding, the screen is nearly monochrome, heavy vignette, shake, chromatic aberration — you see the color fringing on the edges? And the whispers — they're not whispers anymore. They're almost voices. Almost saying something. We spent weeks tuning this so it sits right at the edge of intelligibility. Your brain keeps trying to decode it, which keeps you from thinking clearly. That's the whole point."

[1:02-1:12] "What I love about this system is that it's not binary. It's not 'safe' and then suddenly 'oh a monster.' It's a gradient. Fear builds. You feel the entity getting closer before you see it. Your screen is telling you something is wrong before your eyes confirm it. And because each tier adds effects on top of the previous ones — it stacks — the transition from Safe to Proximity is this smooth ramp of dread."

[1:12-1:22] "And one more thing — this system ties into the adaptive AI. The entity isn't just wandering randomly. It's learning your routes, your hiding spots. So over time, these fear tier transitions happen faster and more frequently. The game literally gets scarier as it learns you. The fear system is the feedback loop — it's how the game communicates to you that you're being hunted."

[1:22-1:30] "If you want to experience this yourself, Level 1 is free. Play it with headphones, in the dark. And pay attention to how the screen changes before you ever see anything. That's the fear system at work. Link in bio."

## Visual Direction

### Layout
The screen is split: main gameplay footage occupies roughly 70% of the frame (left/center), with a persistent sidebar panel on the right (~30%) displaying technical information. The developer's face cam is picture-in-picture in the bottom-left corner of the gameplay footage (small, ~15% of frame width). The sidebar updates dynamically throughout the video.

### Sidebar Panel Design
Dark background (#1A1A2E) with code-style formatting. Contains:
- **Fear Tier Indicator**: Large text showing current tier name with color coding (Safe=green, Unease=yellow, Dread=orange, Panic=red, Proximity=deep red/pulsing).
- **Distance Readout**: "Entity Distance: XX studs" — updates in real time.
- **Active Effects Checklist**: Each effect has an on/off indicator that lights up as tiers activate:
  - [ ] Desaturation
  - [ ] Ambient Drone
  - [ ] Heartbeat Audio
  - [ ] Vignette
  - [ ] Whisper Layer
  - [ ] Screen Shake
  - [ ] Chromatic Aberration
- **Code Snippet Window**: Shows relevant lines from `ProximityFear/init.luau` — scrolls to the active section as the developer discusses each tier.

### Shot-by-Shot

- [0:00-0:05] Developer speaking to camera (face cam PiP). Gameplay behind is a slow pan through the hospital — atmospheric establishing shot at Safe tier. Sidebar shows "Safe" in green, all effects unchecked.

- [0:05-0:10] Gameplay: bird's-eye debug view showing the player icon and entity icon on a map, with distance rings drawn at 80, 50, 25, and 10 studs. The rings are color-coded to match tier colors. Entity is beyond the 80-stud ring. Sidebar updates to show the distance thresholds in a diagram.

- [0:10-0:18] Gameplay returns to first-person view. Player walks through a clean, well-lit section of the hospital. Sidebar: "Safe — 80+ studs." Code snippet window shows:
  ```luau
  -- ProximityFear/init.luau
  local TIERS = {
      Safe =      { min = 80,  max = math.huge },
      Unease =    { min = 50,  max = 80 },
      Dread =     { min = 25,  max = 50 },
      Panic =     { min = 10,  max = 25 },
      Proximity = { min = 0,   max = 10 },
  }
  ```

- [0:18-0:27] Player walks toward entity. The distance readout counts down: 82... 79... 75... As it crosses 80, the sidebar flashes "UNEASE" in yellow. The first effect checkbox lights up: "Desaturation [ON]". In the gameplay footage, the subtle color shift is visible. Code snippet scrolls to:
  ```luau
  -- Unease effects
  self.desaturation:SetIntensity(0.15)
  self.ambientDrone:Play()
  self.ambientDrone:SetVolume(0.2)
  ```
  Second checkbox: "Ambient Drone [ON]."

- [0:27-0:38] Distance continues dropping. At 50 studs, sidebar flashes "DREAD" in orange. New effects activate visibly: heartbeat audio, vignette. The gameplay footage now shows the visual effects in real time — the viewer can see the screen darkening at edges, colors washing out further. Code snippet:
  ```luau
  -- Dread effects (stacked on Unease)
  self.desaturation:SetIntensity(0.40)
  self.heartbeat:Play()
  self.heartbeat:SetBPM(80)
  self.vignette:SetIntensity(0.3)
  self.whispers:Play()
  self.whispers:SetVolume(0.15)
  ```
  Checkboxes light up sequentially: "Heartbeat [ON]", "Vignette [ON]", "Whisper Layer [ON]."

- [0:38-0:50] Entering Panic zone. Sidebar goes red: "PANIC — 10-25 studs." The gameplay footage is noticeably degraded now — the contrast with the Safe footage from 20 seconds ago is stark. Screen shake becomes visible. Developer in PiP gestures at the screen to point out the effects. Code snippet:
  ```luau
  -- Panic effects (stacked on Dread)
  self.desaturation:SetIntensity(0.65)
  self.heartbeat:SetBPM(110)
  self.vignette:SetIntensity(0.5)
  self.whispers:SetVolume(0.4)
  self.screenShake:Enable(0.3) -- intensity
  ```
  "Screen Shake [ON]" lights up.

- [0:50-1:02] Proximity zone. Sidebar pulses deep red: "PROXIMITY — 0-10 studs." All seven effect checkboxes are lit. The gameplay footage is heavily degraded — near-monochrome, tight vignette, visible chromatic aberration fringing, shake. The entity is barely visible in the darkness ahead. Code snippet:
  ```luau
  -- Proximity effects (stacked on Panic)
  self.desaturation:SetIntensity(0.90)
  self.heartbeat:SetBPM(140)
  self.vignette:SetIntensity(0.8)
  self.whispers:SetVolume(0.8)
  self.screenShake:Enable(0.6)
  self.chromaticAberration:Enable(0.5)
  -- Whispers approach intelligibility threshold
  self.whispers:SetCoherence(0.7)
  ```
  "Chromatic Aberration [ON]" — the final checkbox.

- [1:02-1:12] Side-by-side comparison. The gameplay viewport splits into 5 vertical strips, each showing the same corridor at a different fear tier simultaneously (Safe | Unease | Dread | Panic | Proximity). The visual gradient from left (full color, clean) to right (monochrome, degraded) is dramatic. Labels above each strip. Sidebar shows all tiers with their thresholds.

- [1:12-1:22] Gameplay returns to a single view — a replay of the adaptive AI finding the player's hiding spot, shown with the fear tier overlay visible. The sidebar shows the fear tier spiking from Safe to Proximity rapidly as the entity approaches the known hiding location. The developer's face cam shows genuine enthusiasm while explaining.

- [1:22-1:30] Developer in face cam (larger now, ~30% of frame). Gameplay behind shows the title screen. Sidebar fades to show the game logo and "Level 1 — Free" text. CTA: "Link in bio" appears as lower-third text overlay.

## Audio Notes

- **Developer VO**: Primary audio channel. Clean, podcast-quality recording. No background music competing with the explanation. The developer's voice should be the loudest element at all times.
- **Gameplay audio**: Mixed at ~40% volume relative to VO. Serves as illustration, not competition. When the developer describes a specific audio effect (heartbeat, whispers, drone), that effect is momentarily boosted to ~70% for demonstration, then back to 40%.
- **Heartbeat demonstration** (0:27-0:38): Boosted so viewers can clearly hear the BPM change.
- **Whisper demonstration** (0:50-1:02): Boosted with a brief moment where the VO pauses and the whispers are isolated at full volume for 3 seconds — letting the viewer experience them directly.
- **No background music** for the entire piece. The game's audio design IS the soundtrack. This is intentional — it demonstrates that the fear system's audio layer is compelling enough to stand alone.
- **Side-by-side section** (1:02-1:12): Audio cross-fades between each tier's soundscape as the developer discusses them, left to right.

## Fear Timeline

This video deliberately walks through all five fear tiers as a demonstration:

| Timestamp | Fear Tier | Distance (studs) | Effects Active |
|-----------|-----------|-------------------|----------------|
| 0:10-0:18 | Safe | 80+ | None — baseline |
| 0:18-0:27 | Unease | 50-80 | Desaturation (15%), Ambient Drone |
| 0:27-0:38 | Dread | 25-50 | + Heartbeat (80 BPM), Vignette (30%), Whispers (low) |
| 0:38-0:50 | Panic | 10-25 | + Screen Shake, Heartbeat (110 BPM), Vignette (50%), Whispers (med) |
| 0:50-1:02 | Proximity | 0-10 | + Chromatic Aberration, All effects maxed, Heartbeat (140 BPM) |

## Render Notes

- **Code snippets**: Use a monospaced font (JetBrains Mono or Fira Code) with syntax highlighting matching a dark editor theme (One Dark or Dracula). The code shown is representative — it should look like real game code but is simplified for readability. Line numbers visible. Smooth scroll transitions between sections.
- **Sidebar panel**: Persistent throughout the video. Uses a semi-transparent dark background so it doesn't compete visually. The fear tier indicator should be large and immediately readable. Effect checkboxes use a satisfying "click-on" animation (checkmark + color fill) synced to the moment each effect activates in gameplay.
- **Developer face cam**: Natural lighting (ring light or softbox, not harsh). Casual setting (desk/studio). The developer should gesture and look at the gameplay footage naturally, not stare at the camera the entire time. The PiP window has a thin colored border that matches the current fear tier color.
- **Side-by-side comparison** (1:02-1:12): The five strips should be perfectly synced — same camera position and angle, only the fear effects differ. This may require recording five separate passes at identical positions with the fear tier forced/overridden for each.
- **Accessibility**: Auto-captions for all VO. Code snippets should be on screen long enough to read (minimum 4 seconds per snippet). Fear tier transitions should be visually obvious even without audio.
- **Thumbnail**: Use the 5-strip comparison shot with text overlay: "How Fear Actually Works in Our Horror Game."
- **Export versions**: 16:9 for YouTube (primary), 9:16 crop for TikTok/Shorts (focus on gameplay footage, sidebar content as overlays, 60s max edit).
