# Draw to Escape — Monetization Design

## Core Philosophy

1. **No pay-to-win.** Every Robux purchase is cosmetic, convenience, or creative enhancement. Never puzzle-solving power. A free player can three-star every stage.
2. **Free path to everything.** Every material, hint, and unlock can be earned through play. Paying accelerates or enhances — never gates.
3. **All 50 stages are always free.** The full obstacle course from Stage 1 through Stage 50 is available to every player on day one. No level locks, no paywalls.
4. **The drawing system is the cosmetic platform.** Pen skins, canvas themes, drawing frames, and materialization effects are a natural extension of the core mechanic. Players already want their drawings to look unique — we just let them.
5. **Family-friendly monetization.** Target audience is 8-16. Pricing is low, no predatory urgency mechanics, no randomized loot boxes with hidden odds. Parents should feel comfortable with every purchase.

---

## Revenue Stream Breakdown

### 1. Game Passes (One-Time Purchases)

Game Passes are the backbone — high-margin, one-time, account-permanent. Each pass enhances the creative or comfort experience without making puzzles easier.

| Pass | Price (Robux) | Description |
|------|--------------|-------------|
| **VIP Artist** | 399 | The flagship creator upgrade. Doubles drawing lifetime before physics decay, grants +1 max simultaneous drawings (from 3 to 4), adds a golden pen trail visible to all players, and displays a VIP crown next to the player's name in lobbies. Positioned as the "I love this game" purchase. |
| **Material Master** | 249 | Unlocks all 9 materials (wood, stone, ice, balloon, rubber, metal, neon, glass, magnet) from Stage 1. Free players unlock materials progressively through zone completion. This is acceleration, not gating — every material is earnable by reaching its zone. |
| **Private Canvas** | 199 | 2x canvas drawing area, extra line thickness options, and a grid overlay toggle. Bigger canvas means more creative freedom — not bigger physics objects. Drawing size still obeys the same world-space limits. |
| **Skip Stage** | 149 | Consumable pass. Instantly completes the current stage and advances to the next, awarding 1 star (no 2 or 3 star rating). Can be re-purchased. Designed as a frustration valve, not a progression shortcut — skipped stages show a "skipped" badge on the stage select screen, motivating return visits. |
| **No Jumpscares** | 99 | Replaces all jumpscare death animations with a gentle "fade to paint splatter" screen. The game's difficulty is unchanged — only the death presentation softens. Essential for younger or anxiety-sensitive players. This is an accessibility feature we charge minimally for. |

**Conversion strategy:** After a player fails a stage 3+ times, show a non-intrusive "Need a hand?" prompt with the Hint Pack and Skip Stage options. After completing Zone 1 (Stages 1-5), show a brief preview of all 9 materials with the Material Master unlock. The VIP Artist pass is promoted organically — players see golden pen trails on other players and ask "how do I get that?"

### 2. Developer Products (Repeatable Purchases)

Consumables for in-the-moment needs. Low price, low friction, high volume.

| Product | Price (Robux) | Description |
|---------|--------------|-------------|
| **Extra Life** | 25 | Revive in place after death instead of restarting the stage. Does not restore drawings — the player keeps their position but must redraw. One use per purchase. |
| **Hint Pack x5** | 49 | Five detailed visual hints that overlay the canvas showing optimal drawing shapes and material placements for the current stage. Hints reveal one step at a time, not the full solution. Earnable for free: 1 hint per daily login, 1 hint per 3-star completion. |
| **Time Extend** | 35 | Adds +30 seconds on timed stages (Zones 7-10 introduce time pressure). Does not stack — one extend per stage attempt. Timed stages are designed with generous base timers; this is insurance, not necessity. |
| **Drawing Refill** | 15 | Resets the drawing count to max for the current stage attempt. Normally, each stage gives a fixed number of drawings (3 base, 4 with VIP Artist). This lets players erase and retry without restarting. Cheapest purchase — drives first-time conversion. |

**Volume strategy:** Drawing Refill at 15 Robux is intentionally the cheapest item in the game. It targets the moment of maximum frustration (ran out of drawings, almost solved it) with minimal financial friction. It is the gateway purchase that normalizes spending.

### 3. Cosmetic Shop

The drawing mechanic creates a uniquely rich cosmetic surface. Every player's creations are visible to others — cosmetics here are self-expression tools, not just vanity items.

#### Pen Skins (99-199 Robux each)
Trail effects on the pen while drawing and on materialized objects. Visible to all players in the stage.
- **Fire Pen** — Flame trail while drawing, materialized objects glow with ember particles (149R)
- **Sparkle Pen** — Glittering trail, objects shimmer with star particles (99R)
- **Rainbow Pen** — Color-cycling trail, objects have a subtle prismatic sheen (199R)
- **Ink Splatter Pen** — Drip/splatter trail, objects have an ink-wash texture overlay (149R)
- **Frost Pen** — Ice crystal trail, objects have a frosted surface effect (149R)
- **Neon Pen** — Glow trail, objects emit a soft colored light (199R)
- **Pixel Pen** — Pixelated/8-bit trail, objects have a retro texture (99R)

#### Canvas Themes (49 Robux each)
Background texture of the 2D drawing canvas. Purely visual — does not affect drawing or gameplay.
- **Grid Paper** — Engineering grid with measurements
- **Parchment** — Aged paper with burnt edges
- **Blueprint** — Blue background, white lines
- **Chalkboard** — Dark background, dusty chalk texture
- **Notebook** — Lined paper with margin
- **Watercolor** — Soft painted wash background

#### Death Animations (149 Robux each)
Replacement animations for the default jumpscare death. These are opt-in cosmetic overrides — the No Jumpscares pass gives a simple fade, while these are expressive alternatives.
- **Confetti Explosion** — Character pops into a burst of confetti and streamers
- **Paint Dissolve** — Character melts into a pool of colorful paint
- **Get Yeeted** — Character is launched off-screen with a cartoon whoosh
- **Sketch Erase** — Character is "erased" line by line like a drawing being undone
- **Ragdoll Tumble** — Exaggerated physics ragdoll with bounce sound effects

#### Victory Dances (79 Robux each)
Emotes played on stage completion, visible to all players on the results screen.
- **Pen Drop** — Character drops an oversized pen like a mic drop
- **Canvas Flip** — Character flips the canvas like a table flip, confetti falls
- **Masterpiece Pose** — Character strikes an artist's pose with a beret and palette
- **Speed Sketch** — Character rapidly draws in the air, fireworks appear
- **The Bow** — Theatrical bow with applause sound

#### Drawing Frames (49 Robux each)
Decorative borders that appear around materialized 3D drawings. Visible to all players.
- **Gold Frame** — Ornate museum-style gold border
- **Neon Outline** — Glowing colored edge
- **Pixel Border** — Retro 8-bit frame
- **Vine Wrap** — Organic vine/leaf border
- **Blueprint Edge** — Technical drawing border with dimension markers

### 4. Seasonal Pass (Battle Pass Model)

The recurring revenue engine. 30-day cycles aligned with themed content drops.

| Tier | Price | Contents |
|------|-------|---------|
| **Free Track** | 0 | Basic cosmetics (1 canvas theme, 1 drawing frame, 1 victory dance recolor), XP boosts, daily hint refills, badges |
| **Paid Track** | 299 Robux | Exclusive pen skins, canvas themes, death animations, victory dances, drawing frames, a seasonal material variant (visual-only reskin), and the season-exclusive title |

**Progression:**
- Earn pass XP through normal gameplay + themed challenges
- Challenges drive varied play: "Complete Stage 12 using only ice," "Three-star any 5 stages in Zone 3," "Complete a stage with a single drawing," "Use every material in one stage"
- 30 tiers, roughly 1 per day of casual play
- End-of-season exclusive badge + title for completing paid track (status symbol in lobbies)

**Season Themes:**
- Season 1: "Back to School" (school supply-themed cosmetics — pencil pen, homework canvas, chalkboard eraser death)
- Season 2: "Winter Workshop" (holiday-themed — candy cane pen, wrapping paper canvas, snowman death)
- Season 3: "Neon Nights" (cyberpunk-themed — circuit pen, hologram canvas, glitch death)
- Season 4: "Prehistoric" (dinosaur-themed — bone pen, cave wall canvas, fossil death)
- Each season introduces 2-3 new free stages as bonus content alongside the pass

### 5. Roblox Premium Benefits

Roblox pays developers per Premium-subscriber engagement minute. Making the game sticky for Premium users is pure bonus revenue.

| Benefit | Description |
|---------|-------------|
| **+20% Star Earn Rate** | All star sources — stage completions, daily challenges, community events. Stacks with other bonuses. |
| **Exclusive Pen Skin** | "Diamond Pen" — a prismatic trail that is only available to Premium subscribers. Visible status symbol. |
| **Early Seasonal Access** | 3 days early access to each new seasonal pass. Premium players set the cosmetic trends. |
| **Premium Lobby Badge** | Golden easel icon next to name in stage lobbies and leaderboards. |
| **Bonus Daily Hint** | 1 extra free hint per day (2 total instead of 1 from daily login). |

### 6. Seasonal & Limited Events

Time-limited content creates urgency and spikes player return.

| Event | Timing | Content |
|-------|--------|---------|
| **Art Gallery Opening** | Monthly | Featured "Creator Gallery" showcase of community drawings. Top-voted drawings displayed in a special lobby gallery. Voting rights are free; premium gallery frame slots (save + permanently display your best drawings) cost 99R. |
| **Speedrun Saturdays** | Weekly | Timed leaderboard challenge on a rotating stage. Top 100 earn an exclusive trail effect for the week. Top 10 earn a permanent cosmetic badge. Entry is free; a commemorative "I competed" frame is 49R. |
| **Weekly Featured Combo** | Weekly | A curated canvas + pen combo at 20% discount (bundled at ~120R instead of ~150R separate). Rotates every Monday. Creates a browsing habit and artificial scarcity. |
| **Halloween Haunt** | October | All 10 zones get spooky overlays. Exclusive jumpscare variants (even for No Jumpscares owners — opt-in). Pumpkin pen, cobweb canvas, ghost death animation. 2x star weekend. |
| **Holiday Create-a-Thon** | December | Community challenge: collectively complete 1M stages as a player base. Milestone rewards unlock for everyone (500K = free canvas theme, 1M = free pen skin). Drives organic engagement metrics. |
| **Anniversary Event** | Launch anniversary | 5 new bonus stages, retrospective cosmetics, "OG Player" badge for anyone who played in the first month. |

### 7. Engagement Loops (Free Economy)

The free economy keeps non-paying players engaged and creates aspirational targets that drive conversion.

#### Daily Login Streak
| Day | Reward |
|-----|--------|
| Day 1 | 1 Free Hint |
| Day 2 | 25 Stars |
| Day 3 | 1 Free Drawing Refill |
| Day 4 | 50 Stars |
| Day 5 | 1 Free Hint |
| Day 6 | 75 Stars |
| Day 7 | Free Material Trial (any locked material for 24 hours) |
| Day 10 | 150 Stars |
| Day 14 | 1 Free Skip Stage |
| Day 21 | Random Canvas Theme (from basic pool) |
| Day 30 | Exclusive "Dedicated Artist" badge + 500 Stars |

Streak resets on miss. The Day 14 Skip Stage drives retention through the second week — the hardest retention window.

#### Star Shop
Stars are earned through gameplay (stage completions, star ratings, daily challenges, community events). They can be spent on:

| Item | Star Cost | Notes |
|------|-----------|-------|
| Hint x1 | 50 Stars | Farmable alternative to Robux hints |
| Drawing Refill x1 | 30 Stars | Farmable alternative to Robux refills |
| Basic Pen Skin | 500 Stars | Rotating selection, 3 available at a time |
| Basic Canvas Theme | 300 Stars | Rotating selection |
| Basic Victory Dance | 400 Stars | Rotating selection |
| Basic Drawing Frame | 300 Stars | Rotating selection |
| Extra Life x1 | 200 Stars | High cost to preserve Robux Extra Life value |

**Star earn rates (base):**
- Complete a stage: 10 Stars
- 2-star completion: +10 Stars (20 total)
- 3-star completion: +20 Stars (30 total)
- Daily challenge: 25 Stars
- First completion of any stage: 50 Stars (one-time bonus)

This means a free player earning 30 Stars/stage across ~5 stages/day plus a daily challenge earns ~175 Stars/day. A basic pen skin (500 Stars) takes ~3 days of play. This is intentionally achievable — the Star Shop exists to reward engagement, not create artificial grind.

#### Drawing of the Day
- Players can submit one drawing per day to the community gallery
- All players vote (free, unlimited votes)
- Daily winner's drawing is displayed in the main lobby for 24 hours with their username
- Weekly top drawing earns a "Featured Artist" badge
- Monthly top drawing earns an exclusive pen skin variant

This system costs nothing to run (community-generated content), drives daily return visits, and creates organic social media sharing.

---

## Pricing Strategy

### Anchor Pricing
- VIP Artist at 399 Robux is the anchor — every other pass and most cosmetics feel cheap by comparison
- The Seasonal Pass at 299 is the recurring sweet spot (less than a single pen skin bundle in many Roblox games)
- Drawing Refill at 15 Robux is the gateway — priced to feel like "basically free" for the first Robux transaction
- Individual cosmetics at 49-199 keep the impulse purchase threshold low for an 8-16 audience

### Bundle Psychology
- Material Master (249R) vs earning materials over 10 zones — the value proposition is "skip ~10 hours of progressive unlocks"
- Hint Pack x5 (49R) vs buying hints individually — bulk discount frames the pack as smart spending
- Weekly Featured Combo (canvas + pen at ~120R) — creates urgency and perceived value through limited-time bundling

### Price Tier Structure
```
15R   — Drawing Refill (gateway, impulse)
25R   — Extra Life (micro-transaction, in-moment)
35R   — Time Extend (micro-transaction, in-moment)
49R   — Hint Pack x5, Canvas Themes, Drawing Frames (low commitment)
79R   — Victory Dances (mid-low)
99R   — No Jumpscares, entry-level Pen Skins (mid)
149R  — Skip Stage, Death Animations, premium Pen Skins (mid)
199R  — Private Canvas, top-tier Pen Skins (mid-high)
249R  — Material Master (high)
299R  — Seasonal Pass (recurring high)
399R  — VIP Artist (anchor)
```

Each tier roughly doubles the previous, creating natural "upgrade" psychology. The 15R to 399R range spans a 26x multiple, ensuring every budget has an entry point.

### Conversion Funnel
```
Free Player (all 50 stages, 3 base materials)
    | fails stage 3+ times, runs out of drawings
    v
Gateway Purchase (Drawing Refill 15R or Hint Pack 49R)
    | completes more stages, sees cosmetics on other players
    v
Comfort Purchase (No Jumpscares 99R or Skip Stage 149R)
    | plays regularly, wants creative enhancement
    v
Creator Purchase (Private Canvas 199R or Material Master 249R)
    | deeply engaged, wants full experience
    v
VIP Purchase (VIP Artist 399R)
    | wants recurring content
    v
Seasonal Pass Buyer (299R/month)
    | browses shop habitually
    v
Cosmetic Collector (ongoing shop purchases)
```

### Free-to-Paid Parity
Every paid item has a free earning path:
- **Materials:** Unlock progressively by reaching each zone (Material Master just accelerates)
- **Hints:** 1 free per daily login, earnable via Star Shop (50 Stars each)
- **Skip Stage:** Earnable via 14-day login streak
- **Extra Lives:** Earnable at high Star cost (200 Stars)
- **Basic Cosmetics:** Available through Star Shop rotation and seasonal free track
- **Premium Cosmetics:** Seasonal paid track items are exclusive to that season, but equivalent-quality items appear in the Star Shop in subsequent seasons

---

## Revenue Projections Framework

Rather than fixed projections, use these benchmarks for the Roblox obby/creative genre:

| Metric | Conservative | Moderate | Optimistic |
|--------|-------------|----------|------------|
| DAU (after 3 months) | 10K | 50K | 250K+ |
| Conversion rate (any purchase) | 3-5% | 8-12% | 15-20% |
| ARPPU (avg revenue per paying user) | 150 Robux | 400 Robux | 800+ Robux |
| Premium subscriber % | 8% | 15% | 25% |
| Seasonal pass attach rate (of payers) | 20% | 40% | 60% |

**Key levers:**
- **Retention:** Obby games on Roblox have strong natural retention due to progressive difficulty. The 50-stage structure + star ratings + daily challenges are designed to maintain a 30%+ D7 retention rate.
- **Breadth over depth:** The 8-16 audience has lower individual spend capacity but much higher volume. The game's family-friendly positioning widens the addressable market vs horror-only titles.
- **Social multiplier:** Drawings are inherently shareable. Pen trails, drawing frames, and the Creator Gallery drive organic social media posting — every screenshot is free marketing.
- **Seasonal pass as retention anchor:** The 30-day pass cycle creates a recurring engagement commitment that smooths revenue spikes.

**Revenue composition target (steady state):**
| Source | % of Revenue |
|--------|-------------|
| Game Passes (one-time) | 30% |
| Developer Products (consumables) | 25% |
| Seasonal Pass | 20% |
| Cosmetic Shop | 15% |
| Premium Playtime Revenue | 10% |

---

## What We Never Sell

Hard rules. Non-negotiable.

1. **No puzzle solutions.** Hints show partial guidance. We never sell a "solve this stage for me" button. The Skip Stage pass skips the stage entirely — it does not reveal the answer. The game is about the creative joy of solving.
2. **No drawing power advantages.** Paying players never get larger physics objects, stronger materials, more durable drawings, or physics multipliers. VIP Artist extends drawing lifetime and count — but lifetime is a convenience (less re-drawing), and +1 drawing is marginal. The puzzle difficulty is identical.
3. **No stage gating.** All 50 stages are free, always. We never lock stages behind a paywall, a player level, or a star requirement. Players can attempt any stage at any time via stage select (after reaching it sequentially once).
4. **No randomized gameplay items.** No loot boxes, gacha, or mystery packs containing gameplay-affecting items. If we ever introduce cosmetic mystery packs, odds will be published per Roblox policy and every item will be cosmetic-only.
5. **No social segregation.** Paying and free players share all lobbies, leaderboards, and community features. No "VIP servers" that split the player base. (Private servers are a Roblox platform feature and remain available, but we do not gate matchmaking.)
6. **No exploitative death monetization.** Extra Lives are available but never aggressively prompted. We never increase difficulty to drive Extra Life sales. Death is part of the game loop, not a monetization vector.
7. **No material-gated stages.** Every stage is solvable with the materials available to a free player at that point in the progression. Material Master provides creative variety, not required tools.

---

## Implementation Priority

| Phase | Timing | Items |
|-------|--------|-------|
| **Launch** | Day 1 | VIP Artist pass, Material Master pass, No Jumpscares pass, Drawing Refill product, Extra Life product, Hint Pack product, 3 base pen skins (Sparkle, Fire, Ink Splatter), 3 base canvas themes (Grid Paper, Blueprint, Parchment), Premium Benefits, Star economy + Star Shop (basic tier), Daily Login Streak |
| **Week 2** | Day 8-14 | Skip Stage pass (consumable), Private Canvas pass, Time Extend product, remaining pen skins, all death animation cosmetics, victory dances, drawing frames, Weekly Featured Combo system |
| **Month 1** | Week 3-4 | Seasonal Pass (Season 1: "Back to School"), expanded Star Shop rotation, Creator Gallery (basic — save + display drawings), Drawing of the Day voting system, Speedrun Saturdays leaderboard |
| **Month 2** | Post-stabilization | Premium gallery frame slots, monthly Art Gallery Opening events, additional seasonal cosmetics, community milestone system |
| **Month 3+** | Ongoing | Seasonal pass rotation (new season every 30 days), limited-time event cosmetics (Halloween, Holiday), new pen skins and canvas themes each season, community-requested cosmetics, potential collaborative/co-op drawing mode with associated cosmetics |

**Launch justification:** Day 1 includes all game passes (permanent revenue from early adopters), core consumables (gateway purchases for struggling players), a starter cosmetic selection (so paying players are visually distinct immediately), and the free economy backbone (Stars + daily login so free players feel progress from day one). The seasonal pass is deferred to Month 1 to allow the player base to stabilize and establish what "normal" engagement looks like before layering on a 30-day cycle.

---

## Roblox-Specific Technical Notes

### MarketplaceService
- Game Passes created via Creator Dashboard, checked with `MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)`
- Cache pass ownership on join — do not re-check every frame. Store in a per-player table on the server.
- Developer Products via `MarketplaceService:PromptProductPurchase(player, productId)` with `MarketplaceService.ProcessReceipt` callback
- `ProcessReceipt` must be idempotent — Roblox may call it multiple times for the same transaction. Use a DataStore key per receipt to deduplicate.
- Never trust the client for ownership checks. All pass/product validation happens server-side.

### DataStore Architecture
- **PlayerData** DataStore: Stores stage progress (completion status, star ratings per stage), unlocked materials, equipped cosmetics (pen skin, canvas theme, death animation, victory dance, drawing frame), Star balance, daily login streak, hint/refill/life counts, seasonal pass progress.
- Use `UpdateAsync` over `SetAsync` to prevent race conditions (e.g., two servers processing the same player's data during a teleport).
- Wrap all DataStore calls in `pcall` — they can fail due to network errors or rate limits.
- Save on `Players.PlayerRemoving` + `game:BindToClose()` to catch both normal leave and server shutdown.
- Budget DataStore keys carefully: one key per player (`Player_{UserId}`) containing a serialized table. Avoid one key per data field.

### Premium Detection
- Check `Player.MembershipType == Enum.MembershipType.Premium` on join
- Listen to `Players.PlayerMembershipChanged` for mid-session upgrades
- Apply +20% star multiplier server-side in the star award calculation, not client-side

### Cosmetic System
- Equipped cosmetics stored in DataStore, loaded on join, applied via server-side replication
- Pen trail effects implemented as `ParticleEmitter` or `Trail` instances attached to the drawing cursor (replicated from server)
- Canvas themes are local-only (only the drawing player sees their own canvas theme) — no replication needed, reduces network traffic
- Drawing frames are 3D `SurfaceGui` or `BillboardGui` borders applied to materialized drawings — replicated to all players
- Death animations override the default death handler; check for No Jumpscares pass first, then check for equipped death animation cosmetic, then fall through to default jumpscare

### Seasonal Pass System
- Season config stored in a `GlobalDataStore` or `OrderedDataStore` keyed by season ID
- Per-player season progress stored in the main PlayerData table under a `SeasonPass` key with the current season ID
- On season rollover: server checks if `SeasonPass.seasonId ~= currentSeasonId`, resets progress, archives old season rewards
- Challenge definitions are server-authoritative — client requests current challenges, server validates completion
- Tier rewards granted server-side on tier-up, recorded in DataStore to prevent re-granting

### Star Economy
- All Star awards calculated and granted server-side
- Star balance is a single integer in the PlayerData DataStore
- Star Shop purchases validated server-side: check balance, deduct, grant item, save — all in one `UpdateAsync` call to prevent exploits
- Premium +20% bonus applied at the point of award, not at the point of display — prevents visual desync

### Drawing System Integration
- Drawing count tracked server-side per stage attempt. Client sends draw requests; server validates against remaining count.
- VIP Artist +1 drawing applied server-side when initializing stage attempt
- Drawing Refill product resets the server-side count to max (3 base or 4 VIP) for the current attempt
- Drawing lifetime (decay timer) tracked server-side. VIP Artist doubles the timer constant. Timer runs on server heartbeat, not client — prevents time manipulation.

### Anti-Exploit Considerations
- All purchases validated server-side via `ProcessReceipt` and `UserOwnsGamePassAsync`
- Star balance changes only through server-side `UpdateAsync` — client never writes directly
- Drawing count enforced server-side — client cannot spawn drawings beyond the limit
- Stage completion validated server-side (player must have reached the stage end trigger)
- Leaderboard times validated against server-side stage timer, not client-reported values
- Hint system delivers hint data from server on request, rate-limited to prevent data mining all solutions
