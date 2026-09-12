# First-playable consumer API

Load scripts explicitly:

```gdscript
const Game = preload("res://src/core/contracts/game_contracts.gd")
const World = preload("res://src/core/contracts/world_contracts.gd")
const Run = preload("res://src/core/contracts/run_contracts.gd")
const Presentation = preload("res://src/core/contracts/presentation_contracts.gd")
```

Every `validate_*` method accepts a Variant and returns the validation shape in [CONVENTIONS.md](CONVENTIONS.md). Constructors expect typed, trusted producer inputs. All dictionary/array payloads are copied. `Run.run_snapshot`, `Presentation.hud_state`, `Presentation.results_state`, and `Presentation.screen_state` also validate and recursively freeze the published data; they return `{}` if invalid.

## References and input

`Game.ruleset(mode_id = "survival", category_id = "stock", level_id = "debug_yard")` identifies `ruleset_debug_v1`, `physics_debug_v1`, `scoring_debug_v1`, `debug_yard_v1`, and `truck_01`. The other mode is `timed_efficiency`; the other category is `progression`. The first playable registers only the debug yard. Future fixed levels require explicit version registration. `Game.PIXELS_PER_METRE` is `100.0`.

`Game.command(action_id, sequence, run_time_s, payload = {})` creates `player_command.v1`. Commands are run-scoped by their receiving session; they contain no raw device codes. `launch`, `equipment`, `pause`, `restart`, `confirm`, and `back` have empty payloads. Launch is a single timing-gauge tap. `rotate` has `{axis: -1..1}`. `nudge` has `{direction: [x, y], strength: 0..1}`; direction length is at most one. The input adapter emits rotation/nudge state once per active physics tick, so holding nudge spends the runtime-owned per-tick amount; tapping produces fewer active ticks. Command sequence is separate from gameplay-event sequence.

## Truck, contacts, resources, events

`Game.truck_snapshot(run_time_s, position: Vector2, velocity: Vector2, rotation_rad, angular_velocity_rad_s, grounded, nudge_energy, equipment_charge = 0.0, viable = true)` produces `truck_snapshot.v1`. Wire positions/velocities are arrays. `momentum` is velocity magnitude in pixels/second. `viable` is the physics lane's observation, not a calculation in this contract. The producer should set it explicitly. Resource capacities and actual force/speed caps belong to runtime tuning, not the snapshot.

`Game.contact(object_id, kind, point: Vector2, normal: Vector2)` produces `contact.v1`. Kinds are `ground`, `building`, `wreck`, `aerial_target`, `pickup`, and `unknown`. Normals must have unit length. Use a stable content ID such as `yard_ground` or `unknown`, never a node path or instance ID.

`Game.resource_request(source_object_id, speed_cost, impulse: Vector2, nudge_refill, equipment_refill = 0.0)` produces `resource_request.v1`. Costs/refills are finite and nonnegative; impulse is an authored velocity change. Physics applies deterministic costs, caps, and refills, then reports actual observations. A request does not claim the full authored reward was applied when a cap is reached.

`Game.gameplay_event(run_id, sequence, event_type, run_time_s, source_object_id = "", payload = {})` produces the canonical envelope. It includes `event_id = run_id + ":" + sequence`. The coordinator resequences producer-local events before run rules consume them.

| Event type | Required payload |
| --- | --- |
| `launch` | `accuracy` 0..1, `speed_px_s` ≥0, `angle_rad` |
| `contact` | `contact` (`contact.v1`) |
| `building_destroyed`, `target_collected`, `pickup_collected` | `definition_id`, `destruction_value` ≥0, integer `money_value` ≥0, `combo_value` ≥0, `resource_request` |
| `landed` | `contact`, `impact_speed_px_s` ≥0, `clean` boolean |
| `nudge_used` | `energy_spent` ≥0, `impulse` |
| `momentum_changed` | `before_px_s` ≥0, `after_px_s` ≥0, `reason` |
| `viability_lost` | Empty dictionary |

Momentum reasons are `building`, `target`, `pickup`, `landing`, `nudge`, `drag`, `launch`, and `equipment`. World-interaction sources must be nonempty and match the enclosed resource request. `destruction_value`, `money_value`, and `combo_value` are authored inputs; the contract does not award them or compute a score. Duplicate one-shot world interactions remain the world/run owners' responsibility; event-stream validation covers sequence/identity ordering.

`Game.validate_event_stream(events, run_id, last_sequence = -1, last_run_time_s = 0.0)` requires contiguous ordering. A new stream begins at zero. Equal timestamps are allowed; decreasing times, duplicates, gaps, and cross-run events reject. Incremental consumers supply their last accepted sequence and simulation time.

## Authored fixed world

`World.resource_exchange(speed_cost = 0, impulse = Vector2.ZERO, nudge_refill = 0, equipment_refill = 0, destruction_value = 0, money_value = 0, combo_value = 0)` returns the shared authored exchange dictionary.

`World.object_definition(definition_id, object_type, size: Vector2, exchange, wreck_polygon = [], visual_profile = "debug", building_type_id = "")` creates `world_object.v1`. Object types are `building`, `balloon`, `satellite`, `plane`, `recharge`, and `pickup`. The intact collision shape is a centered rectangle of positive `size`. Buildings require a type ID and one convex authored wreck polygon with 3–16 distinct local vertices. Other types require an empty building type ID and empty wreck array. Building state vocabulary is only `intact` and `destroyed`.

`World.object_instance(object_id, definition_id, position: Vector2, schedule = {kind: "static"})` creates a placement. A moving aerial schedule is `{kind: "sine", axis: [unit_x, unit_y], amplitude_px, period_s, phase_rad}` and means `base_position + axis * amplitude_px * sin(TAU * run_time_s / period_s + phase_rad)`. Its period is positive and its phase uses active run time; no random clock/seed is included.

`World.level(level_id, length_px, ground_y, spawn_position: Vector2, definitions, objects)` creates `level.v1` with `layout_kind: "fixed"`. Validation checks schema/version, duplicate IDs, unresolved definitions, object shapes, and schedules. Ground buildings are static. Level data has no runtime generator or scene references. `tests/fixtures/contracts/debug_level.valid.json` contains two base building types, a propulsion variant sharing one of them, and a moving balloon. Values are examples, not release balance.

## Run state and results

`Run.mode_configuration(mode_id, timed_duration_s = 60.0)` uses a null time limit for Survival and a positive duration for Timed Efficiency. Sixty seconds is the first-playable tuning choice, not a final balance claim.

Run states are `preparing`, `ready`, `running`, `paused`, and `ended`. The run owner orchestrates transitions: preparation leads to ready, launch to running, pause suspends active time, and an end produces results. End reasons are `momentum_depleted`, `time_limit`, `abandoned`, `out_of_bounds`, and `debug_stop`; Survival cannot use `time_limit`.

`Run.run_snapshot(fields)` adds `schema_id: "run_snapshot.v1"` and publishes these required fields: `state`, `run_id`, `ruleset`, `elapsed_s`, `time_remaining_s`, `score_total`, `score_breakdown`, `money_earned`, `distance_px`, `destroyed_count`, `combo`, `best_combo`. Survival remaining time is null; Timed remaining time is nonnegative. Scores, money, counts, and combos are nonnegative safe integers.

Score breakdown always contains all six keys: `destruction`, `distance`, `building_chain`, `bounce`, `aerial_chain`, and `launch`. `Run.empty_score_breakdown()` initializes them to zero. `Run.scoring_input(category, amount, source_event_id, run_time_s)` preserves a nonnegative raw amount and canonical event reference; conversion to points is run-owned.

`Run.run_result(run_id, ruleset_ref, end_reason, elapsed_s, score_breakdown, money_earned, distance_px, destroyed_count, best_combo, eligibility = {eligible: false, reasons: ["debug_build"]})` creates `run_result.v1`. It adds `score_total` by summing an already calculated breakdown. Validation checks arithmetic agreement. Eligibility reasons are `debug_build`, `unsupported_version`, `stock_modified`, `invalid_events`, `invalid_result`, and `abandoned`; they describe an outcome, not a network requirement. Debug default ineligibility does not implement submission or validation services.

## Read-only presentation

`Presentation.hud_state(fields)` wraps `run` (`run_snapshot.v1`), `truck` (`truck_snapshot.v1`), `launch: {ready, phase, accuracy}`, `resources: {nudge_capacity, equipment_capacity}`, and `radar: {tier, detections}`. Phase and accuracy are 0..1. Displayed resource values cannot exceed displayed capacities. Radar tier is 0..5; each detection has `object_id`, `classification`, `distance_px`, `eta_s`, and `velocity`. Classification may be `unknown` or a world object type. Distance, ETA, and velocity can be null when capability does not reveal them. Radar capability rules remain run-owned.

`Presentation.results_state(result, submission_status = "unavailable")` wraps a RunResult and a status in `unavailable`, `pending`, `accepted`, or `rejected`.

`Presentation.screen_state(schema_id, fields)` provides later-screen display shells. Their services and screens are outside this milestone. All fields below are required, even when arrays or optional strings are empty.

| Schema | Fields |
| --- | --- |
| `profile_view.v1` | `display_name`, `money_balance`, `unlocked_levels`, `truck_id`, `equipped_module_id` (empty means none) |
| `upgrade_view.v1` | `money_balance`, `items`; each item has `upgrade_id`, `title_key`, `description_key`, `level`, `max_level`, `cost`, `available`, `locked_reason_key` (empty means none) |
| `leaderboard_view.v1` | `ruleset`, `status`, `rows`; each row contains only `rank`, `display_name`, `score`, `date_utc`, `truck_id`, `level_id`, `category_id` |
| `queue_view.v1` | `pending_count`, `accepted_count`, `rejected_count`, `status` (`idle`, `offline`, `submitting`) |
| `settings_view.v1` | `master_volume`, `music_volume`, `sfx_volume`, `resolution`, `fullscreen`, `graphics_quality`, `ui_scale`, `text_scale`, `screen_shake`, `flash_intensity`, `visual_audio_cues`, `language_id`, `instant_restart`, `control_labels` |

Leaderboard view status is `idle`, `loading`, `ready`, `unavailable`, or `error`. Display names are at most 32 characters. Volume/effect fractions are 0..1, UI/text scales are 0.5..3, quality is `low`/`medium`/`high`, and MVP language is `en`. Control labels contain `action_id` and `binding_label`; actual remapping remains input-owned. Text keys are localization keys, not instructions for a particular visual layout.
