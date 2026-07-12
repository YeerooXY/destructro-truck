# Destructro Truck Handoff

## Current lifecycle phase

Guided requirements intake is complete on `assembly/bootstrap-destructro-truck`.

The requirements/bootstrap pull request is the approval boundary. Planning must not begin from this branch as if the requirements were accepted; the PR must first be reviewed and merged into `main`.

## Authoritative candidate artifacts

- `project_workspace.json`
- `assembly/intake/project_intake.json`
- `assembly/requirements/REQUIREMENTS.md`
- `assembly/design/MVP_VISION.md`
- `assembly/design/DESIGN_PRINCIPLES.md`
- `assembly/context/handoff.md`

## Product summary

**Destructro Truck is a score-driven 2D arcade game about converting momentum into destruction and destruction rewards back into momentum through increasingly skillful routing.**

The Windows MVP uses Godot and GDScript and contains one truck, three fixed-layout levels, two data-driven building types, one ground-level building layer, aerial recovery opportunities, Survival and Timed Efficiency modes, compact progression, offline-first saves, and anonymous online leaderboards.

## Important scope boundaries

- Buildings have only intact and destroyed states.
- Any truck contact destroys an intact building and removes a fixed amount of speed.
- Destroyed buildings leave one simple collidable wreck shape; smaller debris is visual only.
- Prototype mechanics with placeholder shapes, debug hitboxes, and minimal UI before final art.
- No replay system, photo mode, runtime procedural levels, gameplay analytics, live events, mod support, cloud saves, multiple profiles, or full accounts in the MVP.
- Android is the first post-MVP platform, not part of the Windows MVP acceptance boundary.
- The complete game is free to play; paid content is cosmetic-only or voluntary support and provides no competitive advantage.
- The project must remain an original spiritual successor and must not copy proprietary code, assets, names, branding, audio, or level layouts.

## Team and workflow constraints

- Optimize later planning for a flexible AI-heavy team with approximately 4–6 concurrent implementation agents.
- Potentially two humans may use the workflow concurrently.
- Planning must define shared contracts, repository/file ownership, dependencies, and integration gates before parallel implementation.
- Use a dedicated AI integration role to check cross-lane consistency and prepare recommendations.
- Humans may make local decisions within accepted subsystem boundaries.
- No contributor may silently move clearly post-MVP scope into the MVP.
- Resolve technical disagreements through evidence first; the project owner breaks unresolved ties.
- When viable technical options are otherwise equivalent, fun wins.

## Remaining questions

No blocking product questions remain for the requirements stage. Exact balancing values, upgrade prices, thresholds, formulas, and small content counts inside accepted caps are intentionally deferred to prototypes, planning, and playtesting.

## Next lifecycle action

1. Review the requirements/bootstrap pull request.
2. Merge it into `main` if accepted.
3. Start a fresh Planning Agent context from the merged repository files.
4. The Planning Agent must read `project_workspace.json`, the merged intake and requirements, the design principles, the MVP vision, the current source tree, and the copied planning workflow instructions.
5. Planning should create architecture, module boundaries, interfaces, file ownership, verification strategy, role prompts, and implementation lanes—but not the final task backlog.

Do not continue intake or begin implementation tasks from chat memory. Git and merged pull requests are authoritative.
