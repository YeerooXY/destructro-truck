# Shared contract conventions

These are the first-playable contracts for tasks 1.1–1.7. They describe data at subsystem boundaries; gameplay behavior and balance formulas belong to their owning lanes. Load each GDScript explicitly with `preload`, without relying on editor-generated global class caches.

## Wire values and versions

- Boundary values are JSON-safe dictionaries, arrays, strings, booleans, finite numbers, and null. Nodes, Resources, Callables, Vector2 values, and scene/file paths are never wire values. Constructors accept Vector2 for convenience and immediately convert it to `[x, y]`.
- Each top-level contract has a `schema_id`, such as `truck_snapshot.v1`. Required fields are explicit. Optional fields have documented defaults. Unknown fields and unknown enum/schema values fail validation; they do not silently change behavior.
- Content IDs are lowercase letters, digits, underscores, and hyphens, beginning with a letter or digit; IDs have at most 64 characters. Run IDs use the same grammar. Content references contain IDs and version IDs, never resource paths.
- Gameplay compatibility uses exact supported identifiers for ruleset, physics tuning, scoring tuning, truck, and level version. A schema change and a tuning/content change are independent. Register a new supported reference before consuming it. The initial debug versions do not imply release leaderboard eligibility.
- Coordinates use Godot's 2D convention: positive X right, positive Y down. Distances and positions are pixels; linear velocity and impulses expressed as velocity change use pixels/second. `Game.PIXELS_PER_METRE = 100.0` is the shared unit conversion for metres; score weights remain run-owned. Angles and angular velocity use radians and radians/second. Vector components are bounded to ±1e9 to avoid overflow when converted to Godot Vector2 storage; this structural ceiling is not a gameplay speed cap.
- `run_time_s` is finite, nonnegative active simulation time in seconds. It starts at zero and does not advance while paused. It is not wall-clock time. Input sequences and gameplay-event sequences are independent, strictly increasing nonnegative safe integers for a run. JSON integer-valued floats are accepted for integer fields; booleans are not numbers. All numeric values must be finite.
- Structural validation reports `{ "valid": bool, "errors": [{ "path": string, "code": string, "message": string }] }`. It does not clamp or repair data. Constructors build data; consumers validate untrusted boundaries before acting. Validation never computes score, money awards, physics, or unlocks.
- `Run.run_snapshot` and presentation constructors validate before copying/freeze and return `{}` on invalid input. Call their matching validator to retrieve failure details. The result constructor sums an already calculated score breakdown; this is consistency arithmetic, not a scoring formula.

## Ownership, ordering, and copying

The input adapter emits device-neutral commands. Physics/world publish observations and authored reward inputs. Run rules calculate scores and publish presentation data. Presentation receives a recursively read-only deep copy, preventing both nested writes and aliasing back into the producer's state.

The run coordinator assigns one global event sequence in deterministic producer order. `event_id` is `<run_id>:<sequence>`. A consumer rejects duplicate IDs/sequences, decreasing timestamps, gaps, and events from another run before applying them. A new stream starts at sequence zero; a continuation provides the last accepted sequence/time. Equal timestamps are allowed; sequence breaks ties. Producers must not independently assign conflicting global sequence numbers.

The `contact` event describes observation only. World interaction events (`building_destroyed`, `target_collected`, `pickup_collected`) contain authored inputs, never a computed score. A world object emits its one-shot interaction once per run. Wreck/ground contacts may recur and cannot grant the intact building reward again.

## Files and tests

- `src/core/contracts/game_contracts.gd`: supported IDs, ruleset references, commands, snapshots, contacts, event envelopes, event stream validation.
- `src/core/contracts/world_contracts.gd`: shared resource exchange, binary building/wreck definitions, aerial/pickup definitions, deterministic schedules, fixed level data.
- `src/core/contracts/run_contracts.gd`: lifecycle, mode configuration, scoring inputs, results, eligibility reasons.
- `src/core/contracts/presentation_contracts.gd`: read-only HUD, results, and later-screen presentation schemas.
- `src/core/domain/contract_values.gd`: validation and JSON/copy primitives only.
- `tests/fixtures/contracts/<name>.valid.json` and `<name>.invalid.json`: wire examples, including one fixed debug level. Invalid fixtures document the intended rejected field in the fixture README.
- `tests/unit/core/test_contracts.gd`: `extends RefCounted`, `static func run() -> Array[String]`; the integration-owned headless runner invokes it.

The first playable includes no persistence, compact run record, network DTO, identity, or crash-report contracts; these remain tasks 1.8–1.13. Later presentation shells define display data only and do not imply their gameplay/services are implemented.
