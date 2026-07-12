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

## Next action

Complete guided intake, review and merge the requirements/bootstrap pull request, then start a fresh Planning Agent context from merged repository files.
