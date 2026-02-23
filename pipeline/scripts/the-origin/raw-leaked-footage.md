# The Origin — Leaked Playtest Footage
> Composition: RawFootage
> Duration: 45s
> Aspect: 9:16

## Voiceover
[None. This is presented as unedited leaked footage. All audio is diegetic — gameplay sounds, player reactions, and ambient game audio only. No narration, no music overlay.]

## Visual Direction

### Setup — VHS Aesthetic
The entire video is presented through a VHS filter: scan lines, tracking artifacts, slight color bleed, timestamp overlay, and intermittent signal degradation. The framing suggests a screen recording of a security camera feed or an internal QA capture. A persistent timestamp in the bottom-right reads "03/14/2024 — 02:47:31 AM" and advances in real time. Top-left corner: "QA-BUILD v0.3.7 — INTERNAL ONLY — DO NOT DISTRIBUTE" in small monospaced text.

### Shot-by-Shot

- [0:00-0:03] Static burst. The feed resolves into a third-person gameplay view — a player character standing in a hospital corridor. The camera is slightly too far back, like an observation angle rather than a gameplay camera. The lighting is raw, unpolished — exposed light sources, hard shadows. The build looks early: UI elements are placeholder (white rectangles with text labels like "FEAR: 2" and "LIVES: 3"). Brief tracking artifact rolls across the screen.

- [0:03-0:08] The player moves forward cautiously. Flashlight on. The corridor is long, with rooms branching off on both sides. Through one doorway, a hospital bed is overturned. Through another, a chair faces the wall. The player stops at an intersection. Looks left. Looks right. The ambient audio is heavy — dripping, electrical hum, something that might be breathing or might be ventilation. The placeholder "FEAR" counter ticks from 2 to 3.

- [0:08-0:13] The player goes right. Enters a patient ward — four beds, curtains drawn around two of them. The player approaches the first curtain. Reaches for it. Pulls it back — empty bed, stained sheets. Approaches the second curtain. The VHS tracking destabilizes for 2 seconds — horizontal bands roll across the image. When it resolves, the player is pulling back the second curtain. Also empty. But the sheets are warm — a subtle steam or heat shimmer effect rises from the bed. The "FEAR" counter jumps to 4.

- [0:13-0:18] The player backs away from the bed. Turns toward the exit. The lights in the ward flicker once, twice, then die completely. Total darkness except for the player's flashlight — which starts to strobe and dim (electronics proximity effect from The Patient). The flashlight emits a high-pitched whine. The "FEAR" counter maxes at 5. The VHS signal degrades — color drains, static intensifies.

- [0:18-0:25] Movement in the darkness. The player's flashlight catches a shape at the far end of the ward — tall, thin, wrong proportions. The Patient. It's standing between the player and the only exit. It doesn't move. The player doesn't move. Seven seconds of standoff. The only audio is a flatline tone (steady, medical-monitor-style) and the player's heartbeat (gameplay audio, not added in post). The VHS timestamp continues advancing. A tracking artifact rolls across The Patient's silhouette.

- [0:25-0:32] The Patient takes a step. The player breaks left, vaulting over a bed. The camera struggles to keep up — the "observation angle" framing makes the chase feel voyeuristic, like watching something you shouldn't be seeing. The player runs through the ward, knocking over an IV stand (crash SFX), slams through a door into the corridor. The Patient follows — not running, but moving with an unnatural gliding gait that somehow keeps pace. The VHS signal is deteriorating badly now — periodic blackouts of 2-3 frames.

- [0:32-0:38] The player rounds a corner and finds a storage closet. Dives inside. The screen goes dark — closet interior. Muffled audio. Through the door crack: The Patient's shadow passes. Passes again. It's circling. The player's breathing is the only clear audio. The "FEAR" counter is invisible in the darkness. The VHS timestamp is the only UI element visible — its glow provides the faintest light reference.

- [0:38-0:42] The shadow stops moving. Silence. Five seconds. Then — the closet door handle turns. Slowly. The VHS feed tears violently — full signal loss. Horizontal static fills the screen. For exactly 3 frames within the static, a face is visible — too close, distorted, looking directly into the camera. It's unclear if this is The Patient or something else entirely.

- [0:42-0:45] The feed cuts to a blue "NO SIGNAL" screen (VHS-style, with the channel indicator "AV-1" in the corner). Holds for 1.5 seconds. Then text appears overlaid on the blue screen — typed character by character in white monospaced font: "FOOTAGE RECOVERED FROM QA SERVER — FILE LAST MODIFIED 03/14/2024." Below, after a pause: "BUILD v0.3.7 WAS NEVER RELEASED." Final line, after another pause: "THE ORIGIN — COMING SOON." Hold. End.

## Audio Notes

- **All audio is diegetic** — sourced from within the game world. No soundtrack, no narration, no post-production music.
- **0:00-0:08**: Hospital ambient loop — HVAC hum, distant dripping, faint electrical crackle. Footsteps on tile (player movement). The sound should feel unprocessed, like a raw gameplay capture.
- **0:08-0:13**: Curtain pull SFX (fabric on metal rings). Bed springs creaking. VHS tracking artifact has its own audio — a brief warble/flutter sound during signal degradation.
- **0:13-0:18**: Light fixture failure SFX (buzz-pop-silence sequence). Flashlight strobe has a high-pitched electrical whine that oscillates. A low-frequency hum begins — The Patient's proximity audio signature.
- **0:18-0:25**: Flatline tone (continuous, 440Hz, medical monitor). Player heartbeat (80 BPM, gameplay-generated). The Patient's breathing — deep, wet, labored — barely audible beneath the flatline. No music. The silence between sounds is the scariest part.
- **0:25-0:32**: Chase audio — running footsteps (tile), IV stand crash (metal clatter), door slam (heavy fire door). The Patient's movement sound — not footsteps, but a dragging/sliding sound. The flatline tone persists, now Doppler-shifting as the player moves relative to the entity.
- **0:32-0:38**: Muffled audio (closet interior acoustic). Player breathing (close-mic, raw). Entity shadow passing — accompanied by the proximity hum rising and falling. Door handle turning — metal mechanism click, slow rotation creak.
- **0:38-0:42**: VHS signal loss — loud static burst (white noise). The 3-frame face insert has no distinct audio — it's buried in the static.
- **0:42-0:45**: "NO SIGNAL" screen — low 60Hz hum (CRT buzz). Text typing has faint keyboard click SFX. Silence after final line.

## Fear Timeline

| Timestamp | Fear Tier | Shown Via |
|-----------|-----------|-----------|
| 0:00-0:08 | Safe → Unease → Dread | Placeholder "FEAR" counter (2 → 3) |
| 0:08-0:13 | Dread → Panic | Counter jumps to 4, subtle visual effects |
| 0:13-0:18 | Panic → Proximity | Counter at 5, flashlight strobe, electronics fail |
| 0:18-0:25 | Proximity (sustained) | Full visual degradation beneath VHS overlay |
| 0:25-0:38 | Proximity (chase/hiding) | Effects present but partially obscured by VHS artifacts |
| 0:38-0:45 | N/A (signal lost) | No gameplay visible |

## Render Notes

- **VHS filter specifications**: Composite video simulation — chroma subsampling (color bleeds horizontally), scan lines at 480i density, head-switching noise at frame bottom (2-3 pixel band), random tracking errors (horizontal band displacement, 2-5 per clip), tape noise (subtle color snow in dark areas), slight temporal ghosting (1-frame echo at 30% opacity).
- **Timestamp format**: "MM/DD/YYYY — HH:MM:SS AM" in the bottom-right. Monospaced white with black outline. Advances in real time. Font: VCR OSD Mono or similar.
- **QA build overlay**: Top-left, small (~12pt equivalent), monospaced, semi-transparent white. Should look like a debug watermark.
- **The face in static** (0:38-0:42): Exactly 3 frames (at 30fps = 100ms). Not clearly The Patient — more abstract, distorted, painterly. Should be easy to miss on first viewing but unmistakable on frame-by-frame. Do NOT make it a cheap jumpscare face — it should be unsettling, ambiguous.
- **"NO SIGNAL" screen**: Accurate to late-90s/early-2000s VHS players. Blue background (#0000AA), "NO SIGNAL" centered in white, "AV-1" top-right corner.
- **Distribution strategy**: Post without context or game branding (no logo until the final text). Let it circulate as "found footage." Seed in horror/gaming communities. The QA build number and date should provoke investigation. Respond to comments in-character ("where did you find this?" etc.) for the first 24 hours before confirming it's marketing.
- **Platform notes**: TikTok upload should use a generic/throwaway account name (not the official game account) for the first post. Repost from official account 24-48 hours later with "We didn't authorize this release."
