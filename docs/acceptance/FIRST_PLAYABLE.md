# First playable evidence and scope

This branch implements an early prototype for handling feedback. It does not
accept milestone 7.6, the complete offline game, or the public MVP release.

## Implemented areas

- Shared first-playable contracts and typed validation (1.1–1.7).
- Project skeleton, local tests, Windows checks and export tooling (6.1–6.3 areas).
- Rectangular rigid body, launch, contacts, fixed speed/resource exchange, bounce,
  rotation, nudge, camera, snapshots, stop detection, and regressions (Agent 2).
- Fixed test-yard loading, data-driven buildings, one-time wreck replacement,
  balloons, resource requests, and development-only layout authoring (Agent 3 subset).
- Run lifecycle, both modes, pause, deterministic scoring/money/combos and immutable
  results (Agent 4 subset 4.1–4.7).
- Minimal menu, controls, keyboard/gamepad action mapping, HUD, launch, pause,
  results, and restart (Agent 5 prototype subset; later screen tasks remain open).
- Real-engine integration and targeted adversarial review (Agents 7/8 prototype scope).

These are implementation/evidence mappings, not automatic accepted-task statuses.
The canonical backlog remains unchanged. The apparent early milestone ordering
conflict is recorded in `docs/red_team/reviews/RT-0001-first-playable-plan.md`.

## Repeatable checks

`tools/build/check.ps1` imports the project and runs:

1. Discovered contract, physics, run-domain and world unit suites.
2. Real full-scene integration through collision, recovery, score, stop, results,
   pause, rapid restart, and synthetic keyboard/gamepad button routing.
3. Isolated physics regression including malformed/extreme requests, prolonged
   rotation, inverted landings, same-frame reset/launch, and resource depletion.
4. Red Team boundary attacks for launch/pause, disconnected controllers, stale
   events, paused objects, duplicate rewards, and repeated same-frame restarts.

Wrappers require success markers and fail on engine/script errors even when Godot
returns zero. Tests and automation are excluded from exported resources.

`tools/build/export.ps1` adds a Windows release export, license notices, and a pack
audit launched from an empty project. That audit checks runtime and fixed level
resources exist while test/tool/planning/backend/evidence directories are absent.
It also starts the exported executable from outside the source directory and
checks startup logs for engine errors. The ZIP includes exactly the executable,
playtest guide, and bundled dependency notices.

## Visual evidence

`tests/integration/capture_playable.gd` drives real input commands in the native
renderer and captures menu, launch, gameplay, and final frames. Run it with Godot's
`--write-movie artifacts/first-playable.avi --fixed-fps 60` for a recording.
Capture helpers are excluded from exports. No generated mock screenshots are used.

## Recorded checkpoint (2026-09-12)

Godot `4.7.2.stable.official.ed1daf0bf` on Windows passed four discovered unit
suites, full-scene integration, the physics regression, the adversarial boundary
fixture, package inspection, and standalone exported startup. Raw build output is
preserved in [evidence/build.log](evidence/build.log).

The headless integration policy produced a 14.25-second run with 8 destroyed
buildings, 3 collected targets, 71.79 metres of progress and 4,195 points. It
ended through viability detection with no rejected events. These numbers describe
one scripted handling experiment, not the final Survival balance.

The separately recorded native run reached results after 10.22 seconds with 5
buildings and 1 target. See the [14-second recording](evidence/first-playable.mp4),
[menu](evidence/menu.png), [gameplay](evidence/gameplay.png), and
[results](evidence/results.png). The capture uses scripted inputs and the real
Windows renderer at 1280 by 720; it is not a human playtest. Its different route
also means it is not a claim of identical physics across render schedules.

Artifact hashes and the exact ZIP file list are in
[evidence/artifacts.json](evidence/artifacts.json). The local distributable is
`builds/Destructro-Truck-First-Playable.zip`.

The first selected-scene export omitted preloaded runtime scripts. The pack audit
detected that failure. The corrected preset exports runtime resources with explicit
development-directory exclusions, and the final pack audit and startup both pass.

## Important integration fixes

- Physics and run-domain callbacks begin their clocks at different points in a
  fixed frame. The integration adapter timestamps event and snapshot observations
  in the authoritative run clock. Distance is tested against physical displacement.
- Pausing preserves queued physics events and body momentum.
- A controller disconnect requests pause idempotently.
- A source event's run ID is checked before resequencing, preventing old rewards
  from crossing a restart boundary.
- Paused objects do not consume themselves. Repeated restarts clear overlays,
  world objects, commands, score, resources, and event sequences.

## Remaining acceptance

Playtesting for feel is pending. Final art/audio, permanent progression, saves,
equipment, radar, unlocks, achievements, settings/remapping, the three product
levels, online services and public release verification remain outside this
prototype. Future work must follow the accepted backlog and preserve these boundaries.
