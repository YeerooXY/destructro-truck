# Destructro Truck Handoff

## Current lifecycle phase

Repository ready; guided requirements intake is in progress on `assembly/bootstrap-destructro-truck`.

## Source of truth

- `project_workspace.json`
- `assembly/intake/project_intake.json` after guided intake
- `assembly/requirements/REQUIREMENTS.md`

## Known facts

- Public repository: `YeerooXY/destructro-truck`
- Default branch: `main`
- Project direction: original spiritual successor inspired by an existing Ninja Kiwi truck-destruction game.
- No proprietary code, names, artwork, audio, branding, or level layouts will be copied.
- MVP platform: Windows PC.
- First post-MVP platform: Android, with mobile-aware controls and UI considered from the start.
- Multiplayer direction: asynchronous competition through comparable run results rather than shared real-time physics.
- Run structure: multiple auto-generated levels whose layouts remain fixed across repeat playthroughs; variety comes from having several distinct levels rather than regenerating each run.
- Player control during a run is deliberately limited: the launch determines most momentum, while the player may apply small nudges to the truck. Nudge strength/control authority can be improved through later-defined upgrades.
- A run ends when the truck loses enough momentum to become effectively immobilized. There is no truck damage or durability system in the MVP.
- Buildings act as primary bounce/jump surfaces, but the truck may also bounce from the ground when impact speed and angle are sufficient.
- Building destruction uses a hybrid model: authored breakable sections and impact thresholds provide predictable structure and scoring, while detached chunks and debris use real physics. Intact and partially destroyed sections may still serve as bounce surfaces.
- Presentation: 2D side view with 2D gameplay physics.
- Engine and scripting language: Godot with GDScript.
- Scoring uses a composite model: destruction value is the base, with additional score from distance, consecutive building hits, difficult bounces, and launch accuracy. Earned money remains tied primarily to destruction value, while composite score is suitable for rankings and comparison.
- Progression is hybrid: most truck, launch, control, and equipment improvements are permanent, while temporary run-specific boosts add variability and tactical choices. The exact boost pool and acquisition method will be defined later.
- PC MVP online scope: anonymous online leaderboards with player-selected display names and per-level score submission. Full accounts, authentication, cloud saves, profiles, and synchronized progression are explicitly post-MVP.
- MVP content target: three distinct fixed-layout levels, one truck, a compact permanent upgrade set, several temporary run-specific boosts, and separate online leaderboards per level.
- Launch system: launch speed is determined by a timing challenge from the beginning. Ramp angle is initially fixed; a permanent upgrade unlocks a second timing challenge that lets the player influence launch angle. Later upgrades may improve the usable angle range or timing forgiveness.
- Leaderboards are separated by level and truck model. Within a truck's progression category, all permanent upgrade levels compete together, so a starter and fully upgraded version share the same board and progression provides a deliberate competitive incentive. A separate stock category uses a standardized version of that truck for fair skill comparison. With the one-truck MVP, this means progression and stock boards for each of the three levels.
- Temporary run-specific boosts are allowed on Progression leaderboard attempts and disabled on Stock leaderboard attempts.

## Next action

Complete guided intake, review and merge the requirements/bootstrap pull request, then start a fresh Planning Agent context from merged repository files.
