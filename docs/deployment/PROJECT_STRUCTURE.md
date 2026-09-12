# First playable foundation

Godot 4.7.2 standard edition, GDScript, Compatibility renderer, Windows x86_64.
Engine binaries live in ignored `.tools/`; builds and recordings are also ignored.
No machine-wide PATH change or service is required.

`src/bootstrap/game.gd` is explicitly owned by the integration role. It wires
physics, world, run-domain, and presentation adapters together. Each adapter owns
its state and communicates through validated plain-data contracts. No gameplay
autoloads or mutable global singleton state are required.

Unit suites live below `tests/unit/`, use a `test_*.gd` filename, and expose a
`run() -> Array[String]` method. An empty array means success. The shared runner
fails when no tests are found. Integration scenes live under `tests/integration/`.

The Windows export includes runtime resources and fixed JSON level data, with
explicit exclusions for tests, tools, planning, backend and evidence. A pack audit
loads the main scene and its dependencies outside the source project.
Automation and development controls belong in excluded test scenes, not the game.
There are no online endpoints or credentials in this prototype.

The early prototype is for physics/interaction feedback. Formal backlog acceptance
remains separate; passing an automated test does not establish that gameplay feels
good or that the full 7.6 milestone's dependencies are complete.
