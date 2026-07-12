# Destructro Truck Handoff

## Current lifecycle phase

Guided requirements intake is paused at an explicit handoff checkpoint on `assembly/bootstrap-destructro-truck`. Resume from repository files in a fresh chat; do not reconstruct decisions from memory or restart intake.

## Source of truth

- `project_workspace.json`
- `assembly/intake/project_intake.json` after guided intake
- `assembly/requirements/REQUIREMENTS.md`
- `assembly/context/handoff.md`
- `assembly/context/NEW_CHAT_RESUME.md`

## Known facts

- Public repository: `YeerooXY/destructro-truck`
- Default branch: `main`
- Project direction: original spiritual successor inspired by an existing Ninja Kiwi truck-destruction game.
- No proprietary code, names, artwork, audio, branding, or level layouts will be copied.
- MVP platform: Windows PC.
- First post-MVP platform: Android, with mobile-aware controls and UI considered from the start.
- Primary MVP audience: score-chasing arcade players. The game should remain approachable for casual players while design decisions prioritize mastery, route optimization, upgrade strategy, repeat attempts, and leaderboard competition.
- Typical successful runs should last roughly 5–8 minutes, giving enough room for routes, airborne chains, recovery moments, and upgrade expression without making ordinary retries exhausting.
- The main survival-style run must not end because of a fixed time limit. Exceptionally skilled players may continue beyond the normal 5–8 minute target as long as they preserve momentum and remain viable. A separate timed efficiency mode, focused on maximizing results within a fixed duration, is a supported direction distinct from the longer survival format.
- Input architecture uses a unified action system. The Windows MVP supports both keyboard and gamepad, with gameplay actions routed through an abstraction that also supports future touch buttons, analog values, and press-versus-hold strength without redesigning gameplay logic.
- Accessibility baseline includes remappable keyboard and gamepad controls, scalable UI and text, separate music and sound-effect volume controls, adjustable screen shake and flash intensity, subtitles or visual equivalents for meaningful audio cues, and gameplay information that never relies on color alone.
- Monetization direction: the complete game is free to play. Optional revenue may come from cosmetic-only items such as truck skins or visual customization and from a voluntary support-the-creator option. Paid or supporter content must never alter physics, scoring, progression power, gameplay resources, unlock requirements, leaderboard eligibility, or competitive advantage.
- Cosmetic acquisition uses both earned and paid paths. Some cosmetics unlock through achievements, progression milestones, and challenges; additional supporter cosmetics may be purchased directly. Randomized loot boxes, paid random rewards, and gambling-like cosmetic mechanics are excluded.
- Multiplayer direction: asynchronous competition through comparable run results rather than shared real-time physics.
- Run structure: multiple auto-generated levels whose layouts remain fixed across repeat playthroughs; variety comes from having several distinct levels rather than regenerating each run.
- Player control during a run is deliberately limited: the launch determines most momentum, while the player may apply small nudges to the truck. Nudge strength/control authority can be improved through later-defined upgrades.
- Mid-air control uses a hybrid model: left/right input applies controlled rotation so the player can prepare collision and landing angles, while a separately limited directional nudge applies a small impulse. This is intended to reduce frustrating randomness without allowing full flight control; upgrades may improve rotational torque, nudge strength, or available nudge energy.
- The basic directional nudge uses a dedicated energy meter. Tapping spends a small amount for fine correction; holding spends more energy and produces a stronger impulse. Permanent upgrades may improve meter capacity, energy efficiency, or impulse force.
- Nudge energy recharges through skillful play rather than passive recovery. Clean landings, difficult airborne target chains, valuable target hits, and dedicated pickups restore controlled amounts; rare pickups may fully refill the meter. Exact recharge values and anti-snowball caps will be tuned during balancing.
- Mid-air rotation is always available while airborne and does not consume an energy resource. Rotational torque and responsiveness are deliberately capped so angular inertia and timing remain meaningful; permanent upgrades may improve the cap within balanced limits.
- A run ends when the truck loses enough momentum to become effectively immobilized. There is no truck damage or durability system in the MVP.
- Buildings act as primary bounce/jump surfaces, but the truck may also bounce from the ground when impact speed and angle are sufficient.
- Building destruction uses a hybrid model: authored breakable sections and impact thresholds provide predictable structure and scoring, while detached chunks and debris use real physics. Intact and partially destroyed sections may still serve as bounce surfaces.
- Presentation: 2D side view with 2D gameplay physics.
- Visual direction: clean original cartoon/vector art with bold silhouettes, simple scalable shapes, readable debris, and exaggerated impact effects. The style must remain clear on both Windows and Android-sized displays.
- Content tone is family-friendly cartoon chaos. Environments are empty or stylized; destruction uses exaggerated crashes, dust clouds, sparks, and debris without blood, visible injured people, realistic suffering, or graphic consequences.
- Asset sourcing uses a hybrid pipeline. The truck, buildings, UI, and signature impact effects are original project assets; clearly licensed generic sounds, particles, fonts, and background elements may be used where appropriate. Every external asset must have its source, author, license, permitted use, and any attribution requirement recorded in the repository before inclusion.
- Engine and scripting language: Godot with GDScript.
- Performance target uses scalable quality profiles. The Windows MVP and capable Android devices target a stable 60 FPS. Lower-powered Android devices may use a 30 FPS fallback with reduced debris counts, particles, background detail, and other cosmetic effects while preserving identical gameplay physics, scoring, collision rules, and leaderboard eligibility.
- Scoring uses a composite model: destruction value is the base, with additional score from distance, consecutive building hits, difficult bounces, and launch accuracy. Earned money remains tied primarily to destruction value, while composite score is suitable for rankings and comparison.
- Progression is hybrid: most truck, launch, control, and equipment improvements are permanent, while temporary run-specific boosts add variability and tactical choices.
- Permanent upgrades are organized as a mostly independent collection rather than a fully branching tree. Some upgrades have logical prerequisites, while most can be purchased separately. A swappable rear equipment slot provides visible permanent modules such as boosters, stabilizers, or impact-focused devices; the exact module catalogue will be defined later.
- Rear equipment uses a module-specific activation model. Some modules are passive; some provide a player-controlled boost meter that can be spent in shorter bursts during a run; and some provide a single, substantially stronger one-time activation.
- Boost-meter energy is primarily regained through active play: destroying valuable structures, maintaining destruction combos, and striking designated recharge obstacles can partially refill the meter. Rare one-time recharge pickups restore the meter completely.
- Levels must use vertical airspace as meaningful gameplay rather than empty travel time. Airborne obstacles, targets, recharge objects, and pickups may create routes above the ground alongside building-based paths.
- Airborne objects use a deterministic mix: most are fixed, while selected targets move on repeatable patterns or schedules identical for every attempt. Balloon-like propulsion targets impart a forward impulse when hit. Carefully chaining an entire target sequence to preserve or increase momentum must be possible but deliberately difficult.
- Temporary boost acquisition is hybrid: before a run, the player chooses one main boost from a random selection; smaller single-use boost pickups may also appear within the fixed level layout and activate when collected or struck.
- PC MVP online scope: anonymous online leaderboards with player-selected display names and per-level score submission. Full accounts, authentication, cloud saves, profiles, and synchronized progression are explicitly post-MVP.
- Leaderboard anti-cheat for the MVP uses compact run-record submission with server-side plausibility validation. Submissions include the score breakdown, level and ruleset version, progression state, selected boosts and equipment, key collisions and resource changes, timestamps, and sampled movement data. The server rejects malformed or impossible runs using configurable validation rules; exact deterministic server-side physics replay is not required for the MVP.
- Gameplay, money earning, upgrades, and level progression remain available offline. Completed leaderboard-eligible runs are stored locally as signed compact run records and automatically queued for submission when connectivity returns. The backend must handle record expiry, duplicate submissions, replayed records, clock anomalies, and ruleset-version mismatches.
- Anonymous progression uses a device-bound profile token and a signed progression ledger. Offline earnings and purchases are recorded as ordered signed transactions and reconciled with the backend when connectivity returns. The backend validates balances, transaction ordering, duplicate or replayed entries, and impossible progression states without requiring registration or login. Account-based recovery and cross-device transfer remain post-MVP.
- Anonymous recovery uses a recovery code as a one-time profile transfer mechanism rather than a cloning mechanism. Redeeming the code on a new installation rotates the profile credentials, revokes the previous device token, invalidates previously issued recovery material, and allows only one active device-bound profile identity at a time. The backend must rate-limit recovery attempts, reject replayed codes, and prevent two installations from submitting progression or leaderboard records under the same restored identity concurrently.
- MVP content target: three distinct fixed-layout levels, one truck, a compact permanent upgrade set, several temporary run-specific boosts, and separate online leaderboards per level.
- Level generation is a development-time authoring tool: candidate layouts are generated, reviewed, tested, selected, and manually tuned before shipping. All players receive the same final three layouts; levels are not procedurally regenerated at runtime.
- Level progression is sequential and score-gated: Level 1 starts unlocked; reaching a defined score threshold on Level 1 unlocks Level 2, and reaching a defined score threshold on Level 2 unlocks Level 3. Exact threshold values will be tuned during balancing.
- Launch system: launch speed is determined by a timing challenge from the beginning. Ramp angle is initially fixed; a permanent upgrade unlocks a second timing challenge that lets the player influence launch angle. Later upgrades may improve the usable angle range or timing forgiveness.
- Leaderboards are separated by level and truck model. Within a truck's progression category, all permanent upgrade levels compete together, so a starter and fully upgraded version share the same board and progression provides a deliberate competitive incentive. A separate stock category uses a standardized version of that truck for fair skill comparison. With the one-truck MVP, this means progression and stock boards for each of the three levels.
- Temporary run-specific boosts are allowed on Progression leaderboard attempts and disabled on Stock leaderboard attempts.
- MVP acceptance proof requires a downloadable Windows build, recorded gameplay evidence, a manual acceptance checklist, and automated tests for deterministic scoring, progression transactions, save/load behavior, compact run-record validation, and other non-visual core logic. Extensive automated physics replay and broad end-to-end gameplay automation are not required for the MVP.

## Resume checkpoint

- Last accepted decision: normal successful runs target 5–8 minutes, but the survival-style mode has no hard time cap for players skilled enough to continue; a separate timed efficiency mode is also supported.
- Intake is not yet formally closed or accepted as complete.
- In the new chat, first read `assembly/context/NEW_CHAT_RESUME.md` and this file from branch `assembly/bootstrap-destructro-truck`.
- Do not repeat settled questions.
- Continue with exactly one high-impact unresolved question, unless the user explicitly asks to close intake and produce the requirements/bootstrap PR.
- Do not begin architecture, implementation task splitting, or full planning until intake is explicitly accepted.

## Next action

Resume guided intake from the next unresolved high-impact product decision.
