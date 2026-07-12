# Destructro Truck Requirements

Status: accepted intake candidate, pending review and merge of the requirements/bootstrap pull request.

## Product vision

**Destructro Truck is a score-driven 2D arcade game about converting momentum into destruction and destruction rewards back into momentum through increasingly skillful routing.**

The player launches a truck, destroys ground-level buildings, uses aerial targets and special structures to recover speed and control, buys upgrades, and repeats runs to improve scores and leaderboard positions. The game must be easy to understand immediately while rewarding route planning, timing, resource management, and mastery.

Detailed vision and design guidance live in:

- `assembly/design/MVP_VISION.md`
- `assembly/design/DESIGN_PRINCIPLES.md`

## Target users

- Score-chasing arcade players.
- Players who enjoy route optimization, repeat attempts, progression, and leaderboard competition.
- Casual players who want approachable controls without removing the high skill ceiling.

## Platforms and technology

- MVP platform: Windows PC.
- First post-MVP platform: Android.
- Engine: Godot.
- Primary scripting language: GDScript.
- Presentation: 2D side view with 2D gameplay physics.
- Input, UI scaling, and performance design must remain compatible with a later Android port.

## Core gameplay

### Run structure

- The player launches the truck through a timing challenge.
- Launch speed is timing-based from the beginning.
- Ramp angle starts fixed.
- A permanent upgrade unlocks a second timing challenge that influences launch angle.
- Mid-air left/right control applies capped rotation and is always available while airborne.
- A separate directional nudge spends energy; tapping provides fine correction, while holding spends more for a stronger impulse.
- The run ends when the truck lacks enough momentum to remain viable.
- There is no truck health, durability, fuel, tire wear, engine heat, ammunition, or repair system in the MVP.

### Modes

#### Survival

- No hard time cap.
- Typical successful runs should last roughly 5–8 minutes.
- Exceptionally skilled players may continue as long as they preserve momentum and remain viable.

#### Timed Efficiency

- Uses the same truck, levels, physics, controls, objects, upgrades, and content.
- Ends after a fixed duration.
- Rewards maximizing results within the time limit.
- Uses separate rules and leaderboards from Survival.

### Difficulty and retry flow

- One standard gameplay difficulty in the MVP.
- Results are shown after runs by default.
- Players may enable Instant Restart to begin another attempt with minimal interruption.
- No replay system is included.

## Momentum and resource economy

Momentum is the central run resource.

- Every contact with an intact building destroys it.
- Destroying a normal building removes a fixed amount of speed.
- Buildings grant score, money, destruction progress, combo value, and possibly ability or equipment charge according to data.
- Repeated destruction naturally drains momentum unless the player recovers speed through routing, aerial targets, special structures, boosts, pickups, nudges, or rear equipment.
- Every gameplay object must have a clear resource cost, reward, or both.

## Buildings and destruction

- The MVP includes two data-driven building types.
- Buildings have only two gameplay states: intact and destroyed.
- There are no intermediate damage states and no destruction threshold.
- Any truck contact with an intact building destroys it.
- Each building type applies a deterministic fixed speed loss.
- A destroyed building is replaced by one simple authored collidable wreck shape.
- The wreck may still serve as a smaller ramp or bounce surface.
- Smaller chunks and debris are visual only and must not unpredictably alter the truck’s path.
- At least one special building variant, such as a gas station or propane facility, must grant forward and upward impulse while using the shared building system rather than bespoke one-off mechanics.
- Early implementation must use debug-style hitboxes, placeholder shapes, and minimal UI before final building art is produced.

## Spatial route structure

- Buildings exist only in one ground-level layer.
- Above the buildings is an aerial opportunity layer.
- Balloon targets help preserve or increase momentum and may support airborne chains.
- Rare higher-skill aerial objects may include:
  - satellite-like targets that provide strong forward speed while sending the truck downward,
  - plane-like targets that provide exceptional speed but require maintaining the correct altitude and timing interception,
  - other deterministic propulsion or recharge targets.
- Infinite upward momentum must not be possible.
- The intended rhythm is ground destruction, aerial recovery or amplification, and a planned return to the ground route.
- Moving aerial targets must follow deterministic, repeatable schedules or patterns.

## Controls and resources

### Mid-air rotation

- Always available while airborne.
- Does not consume energy.
- Torque and responsiveness are capped.
- Permanent upgrades may improve the cap within balanced limits.

### Directional nudge

- Uses a dedicated energy meter.
- Tapping spends a small amount for fine adjustment.
- Holding spends more and creates a stronger impulse.
- Upgrades may improve capacity, efficiency, or force.
- Energy recharges through skilled play such as clean landings, difficult target chains, valuable hits, and dedicated recharge objects.
- Rare pickups may fully refill it.

### Rear equipment

- One visible swappable rear equipment slot.
- Modules may be passive, use a burst meter, or provide one powerful single activation.
- The compact MVP catalogue should avoid scope creep.
- Equipment charge is regained primarily through active play.

## Scoring and progression

### Scoring

- Base score comes from destruction value.
- Additional score may come from distance, building chains, difficult bounces, aerial target chains, and launch accuracy.
- Money is tied primarily to destruction value.
- Exact values are tuned through playtesting.

### Permanent progression

- Mostly independent upgrade collection with limited logical prerequisites.
- May improve launch, angle control, nudge, rotation, resource capacity, or rear equipment.
- Progression should expand options and planning rather than replace skill.

### Radar progression

The radar begins weak and becomes a late-game planning tool:

1. short-range vague warning that something rare is approaching,
2. basic object classification,
3. increased detection range,
4. distance or ETA information,
5. richer multi-object and moving-target planning support.

The radar must not become an automatic route solver.

### Temporary boosts

- Before a run, the player chooses one main boost from a random selection.
- Smaller fixed-layout single-use pickups may also appear during runs.
- Temporary boosts are allowed in Progression leaderboard attempts.
- They are disabled in Stock attempts.

## Levels and content

- One truck in the MVP.
- Three distinct fixed-layout levels.
- Level layouts are generated only during development, then reviewed, selected, and manually tuned.
- Runtime procedural regeneration is excluded.
- Level 1 starts unlocked.
- Level 2 unlocks through a score threshold on Level 1.
- Level 3 unlocks through a score threshold on Level 2.
- Exact thresholds are tuned later.
- Each level has one fixed visual identity.
- No dynamic weather, day/night variants, seasons, or alternate visual states in the MVP.

## Leaderboards and offline behavior

### Leaderboards

- Anonymous online leaderboards using player-selected display names.
- Separate boards by level, mode/category, and truck model.
- With one MVP truck, each level has Stock and Progression categories.
- Progression boards allow all permanent upgrade levels together.
- Stock boards use a standardized truck configuration.
- Display only rank, name, score, date, truck, level, and category.
- No player profiles, friends, social features, replay links, badges, or public run histories.

### Validation

- Leaderboard submissions use compact run records.
- Records include score breakdown, ruleset and level version, progression state, selected boosts/equipment, important collisions and resource changes, timestamps, and sampled movement data.
- Server-side validation checks plausibility and rejects malformed or obviously impossible runs.
- Exact deterministic server-side physics replay is not required.
- Validation must handle duplicates, replayed records, expiry, clock anomalies, and version mismatches.

### Offline-first behavior

- Gameplay, progression, money, upgrades, achievements, statistics, and unlocks work offline.
- Eligible run records are queued locally and submitted when connectivity returns.
- Internet is used only for leaderboard retrieval/submission, opt-in crash reports, and a possible update check.

## Saves and profile

- One local player profile per installation.
- Save to a temporary file, verify, and replace the primary save safely.
- Keep one previous automatic backup.
- Detect corruption and restore or offer the backup.
- Multiple profiles, profile switching, manual export/import, cloud saves, account login, and cross-device progression are post-MVP.
- Anonymous progression may use a device-bound token and signed ordered progression ledger for reconciliation.
- Recovery-code transfer rotates credentials and allows only one active restored identity at a time.

## Achievements, statistics, and customization

### Achievements

- Up to 10 local achievements.
- Focus on meaningful mastery, experimentation, or milestones.
- May unlock a small number of cosmetics.
- Platform achievement integration is post-MVP.

### Statistics

- One compact statistics screen.
- Use only data already collected for gameplay, progression, balancing, or achievements.
- No graphs, histories, exports, or tracking added solely for the statistics page.

### Customization

- Default plus one alternate paint job.
- Default plus one alternate wheel set.
- Default plus one alternate body/skin option.
- At most one similarly inexpensive additional category.
- Cosmetic only.
- No custom animations, particles, sounds, or gameplay effects.

## Monetization

- The complete game is free to play.
- Revenue may come from optional cosmetic purchases or voluntary support.
- Earned and paid cosmetic paths may coexist.
- No loot boxes, paid random rewards, or gambling-like systems.
- Paid or supporter content must never alter physics, scoring, progression power, gameplay resources, unlock requirements, leaderboard eligibility, or competitive advantage.

## UX, accessibility, localization, and presentation

### Menus and tutorial

- Functional, fast menus.
- Small fades, button feedback, and “New” indicators are allowed.
- No cinematic menu backgrounds, animated garages, elaborate transitions, story, lore, dialogue, or cutscenes.
- No dedicated tutorial level.
- Use one-time contextual hints only for non-obvious mechanics.
- Avoid a skip-fest of obvious instructions.

### Settings

Essential settings only:

- master, music, and SFX volume,
- resolution and fullscreen on Windows,
- graphics quality,
- keyboard and gamepad remapping,
- scalable UI/text,
- screen shake and flash intensity,
- subtitles or visual equivalents for meaningful audio cues,
- language framework,
- Instant Restart preference.

Advanced enthusiast and diagnostic settings are post-MVP.

### Localization

- English only at MVP launch.
- All player-facing text uses a localization-ready system.

### Art and VFX

- Original clean cartoon/vector style.
- Bold silhouettes and readable shapes.
- Gameplay-focused dust, sparks, debris, flashes, simple explosions, and configurable screen shake.
- Dynamic cosmetic budgets may reduce particles and visual debris to preserve frame rate.
- Gameplay physics, scoring, and eligibility remain unchanged across quality profiles.

### Audio

- Menu music.
- Gameplay music.
- Engine, impacts, destruction, pickups, and UI sounds.
- No adaptive soundtrack, announcer, or cinematic audio system.

## Performance

- Stable 60 FPS target on Windows and capable later Android devices.
- Later lower-powered Android fallback may use 30 FPS and reduced cosmetic detail.
- Quality scaling may reduce debris visuals, particles, backgrounds, and cosmetic detail only.
- It must not alter physics, scoring, collision rules, or leaderboard eligibility.

## Crash reporting and diagnostics

- Development builds may contain debug menus, cheats, free camera, overlays, collision visualization, slow motion, spawning, and unlock tools.
- Public release builds expose none of these.
- On the next launch after a crash, offer an opt-in anonymous report.
- Allowed crash data: stack trace, game version, OS/hardware summary, graphics API, active settings, and session log.
- Excluded: save files, screenshots, recordings, personal data, continuous telemetry, and background uploads.
- No gameplay analytics in the MVP.

## Team and workflow constraints

- Plan for a flexible AI-heavy team with roughly 4–6 concurrent implementation agents.
- Potentially two humans may use the workflow concurrently.
- Planning must define contracts, dependencies, file ownership, and integration gates before parallel work.
- A dedicated AI integration role checks cross-lane consistency and prepares recommendations.
- Humans may make local decisions inside accepted subsystem boundaries.
- No human or AI contributor may silently move clearly post-MVP scope into the MVP.
- Technical disagreements use evidence first: prototypes, tests, complexity, performance, MVP impact, and maintainability.
- The integration agent recommends; the project owner breaks unresolved ties.
- If technically viable options remain equivalent, fun wins.

## Originality, licensing, and tone

- This is an original spiritual successor, not a copy.
- Do not copy proprietary code, names, art, audio, branding, or level layouts.
- Original project assets include the truck, buildings, UI, and signature effects.
- Generic external fonts, sounds, particles, backgrounds, or other assets may be used only with clear licensing records.
- Record source, author, license, permitted use, and attribution before inclusion.
- Family-friendly cartoon chaos only.
- No blood, visible injured people, realistic suffering, or graphic consequences.

## Explicitly postponed

- Android release.
- Full accounts, authentication, cloud saves, and cross-device progression.
- Multiple local profiles and save-slot management.
- Replay recording, playback, sharing, and deterministic replay validation.
- Photo mode and automatic highlight capture.
- Daily/weekly challenges, live events, seasons, and rotating content.
- Gameplay analytics, funnels, retention, cohorts, and A/B testing.
- Official mod support and Workshop integration.
- Dynamic weather, day/night cycles, and seasonal variants.
- Adaptive soundtrack and cinematic audio.
- Story, lore, dialogue, cutscenes, cinematic menus, and animated garage presentation.
- Advanced graphics settings, developer console, and enthusiast diagnostics.
- Large customization catalogues and animated cosmetics.
- Social profiles, friends, chat, replay links, and public run histories.
- Public pre-launch roadmap or season commitments.
- Novelty public cheat codes.

## Design principles

All contributors must follow `assembly/design/DESIGN_PRINCIPLES.md`, including:

- Gameplay First.
- The MVP Is Sacred.
- Prototype Before Polish.
- Data Before Bespoke Code.
- Player Skill Over Player Stats.
- Every Object Has a Purpose.
- Predictable, Not Realistic.
- Readability Beats Detail.
- Reuse Before Inventing.
- Evidence Beats Opinion.
- Fun Wins.
- Every Second Should Contain a Decision.

## Open questions

No blocking product questions remain for the requirements stage. Exact balancing values, upgrade costs, thresholds, formulas, and small content counts inside the accepted caps are intentionally deferred to prototyping, planning, and playtesting.

## Acceptance signals

Requirements are ready for planning when the requirements/bootstrap PR is reviewed and merged.

The eventual MVP is accepted when:

- launch, bounce, destruction, aerial recovery, and retry are fun using placeholder assets;
- players understand momentum loss and can improve through practice;
- ground and aerial routes create frequent meaningful decisions;
- normal Survival runs cluster around 5–8 minutes while experts can continue;
- Timed Efficiency creates a distinct objective without duplicating the content stack;
- progression and radar improve tactical planning without replacing skill;
- one truck, three levels, two building types, and the compact object set feel like a complete game;
- the Windows build runs reliably, saves safely, and remains fully playable offline;
- eligible leaderboard records submit when connectivity is available;
- automated tests pass for deterministic scoring, progression transactions, save/load behavior, and compact run-record validation;
- recorded gameplay evidence and a manual acceptance checklist are available.
