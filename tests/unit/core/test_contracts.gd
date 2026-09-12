extends RefCounted

const Values = preload("res://src/core/domain/contract_values.gd")
const Game = preload("res://src/core/contracts/game_contracts.gd")
const World = preload("res://src/core/contracts/world_contracts.gd")
const Run = preload("res://src/core/contracts/run_contracts.gd")
const Presentation = preload("res://src/core/contracts/presentation_contracts.gd")


static func run() -> Array[String]:
	var failures: Array[String] = []
	_test_rulesets(failures)
	_test_wire_values(failures)
	_test_commands(failures)
	_test_observations(failures)
	_test_events(failures)
	_test_world(failures)
	_test_run(failures)
	_test_presentation(failures)
	_test_malformed_value_resilience(failures)
	return failures


static func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


static func _fixture(name: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/contracts/" + name + ".json"))


static func _has_error(validation: Dictionary, path: String, code: String) -> bool:
	for issue in validation.errors:
		if issue.path == path and issue.code == code:
			return true
	return false


static func _test_rulesets(failures: Array[String]) -> void:
	var good: Variant = _fixture("ruleset.valid")
	_check(Game.validate_ruleset(good).valid, "Known ruleset fixture must validate.", failures)
	_check(Game.validate_ruleset(JSON.parse_string(JSON.stringify(good))).valid, "Ruleset must survive JSON serialization.", failures)
	_check(_has_error(Game.validate_ruleset(_fixture("ruleset.invalid")), "$.level_version", "unsupported_version"), "Unregistered level version must be rejected explicitly.", failures)
	for mode in Game.MODE_IDS:
		for category in Game.CATEGORY_IDS:
			_check(Game.validate_ruleset(Game.ruleset(mode, category)).valid, "Both modes and categories must fit shared ruleset.", failures)
	for field in ["ruleset_version", "physics_tuning_version", "scoring_tuning_version", "level_id", "mode_id", "category_id", "truck_id"]:
		var changed: Dictionary = good.duplicate(true)
		changed[field] = "unknown"
		_check(not Game.validate_ruleset(changed).valid, "Unknown governing reference must reject: " + field, failures)
	var with_path: Dictionary = good.duplicate(true)
	with_path["scene_path"] = "res://not_a_contract.tscn"
	_check(_has_error(Game.validate_ruleset(with_path), "$.scene_path", "unknown_field"), "Ruleset must not accept resource paths.", failures)
	_check(not Game.validate_ruleset(null).valid, "Null rulesets fail cleanly.", failures)


static func _test_wire_values(failures: Array[String]) -> void:
	for invalid in [NAN, INF, Vector2.ZERO, RefCounted.new()]:
		var errors: Array = []
		Values.json_value({"nested": [invalid]}, errors)
		_check(not errors.is_empty(), "Non-JSON/non-finite nested values must fail validation.", failures)
	var errors: Array = []
	_check(not Values.integer(true, errors, "$.integer"), "Boolean must not be accepted as an integer.", failures)
	_check(not Values.integer(1.2, errors, "$.integer"), "Fractional sequence must not be accepted.", failures)
	_check(Values.integer(2.0, [], "$.integer"), "JSON integer-valued floats must be accepted.", failures)
	_check(not Values.identifier("res://level.tscn", errors, "$.id"), "Path must not be a content ID.", failures)
	_check(not Values.vector([1.0, 1.0], errors, "$.direction", true), "Unbounded direction must reject.", failures)
	var source := {"items": [{"value": 7}]}
	var copy: Dictionary = Values.read_only_copy(source)
	source.items[0].value = 99
	_check(copy.items[0].value == 7, "Presentation copies must not alias producer nested state.", failures)
	_check(copy.is_read_only() and copy.items.is_read_only() and copy.items[0].is_read_only(), "Presentation copy must be recursively read-only.", failures)


static func _test_commands(failures: Array[String]) -> void:
	_check(Game.validate_command(_fixture("command_nudge.valid")).valid, "Device-neutral command fixture must validate.", failures)
	_check(_has_error(Game.validate_command(_fixture("command_nudge.invalid")), "$.payload.direction", "vector_length"), "Overlength direction fixture must fail at the documented path.", failures)
	for action in ["launch", "equipment", "pause", "restart", "confirm", "back"]:
		_check(Game.validate_command(Game.command(action, 0, 0.0)).valid, "Device-neutral tap command must validate: " + action, failures)
	_check(Game.validate_command(Game.command("rotate", 1, 1.0, {"axis": -1.0})).valid, "Full left rotation must validate.", failures)
	var nudge := Game.command("nudge", 2, 1.0, {"direction": [0.6, -0.8], "strength": 0.5})
	_check(Game.validate_command(JSON.parse_string(JSON.stringify(nudge))).valid, "Analog nudge must survive JSON round trip.", failures)
	for bad_payload in [{"direction": [1, 1], "strength": 0.5}, {"direction": [0, -1], "strength": 1.1}, {"direction": Vector2.UP, "strength": 1.0}, {"direction": [0, NAN], "strength": 1.0}]:
		_check(not Game.validate_command(Game.command("nudge", 0, 0.0, bad_payload)).valid, "Malformed nudge input must reject.", failures)
	_check(not Game.validate_command(Game.command("launch", 0, 0.0, {"keycode": 32})).valid, "Raw device codes must not enter command payloads.", failures)
	_check(not Game.validate_command(Game.command("rotate", 0, 0.0, {"axis": true})).valid, "Boolean axis must reject.", failures)
	_check(not Game.validate_command(Game.command("unknown", 0, 0.0)).valid, "Unsupported command must reject.", failures)


static func _test_observations(failures: Array[String]) -> void:
	var snapshot := Game.truck_snapshot(1.0, Vector2(10, 20), Vector2(300, -400), 0.25, 0.0, false, 60.0, 0.0, true)
	_check(snapshot.momentum == 500.0, "Snapshot momentum is speed magnitude.", failures)
	_check(Game.validate_truck_snapshot(JSON.parse_string(JSON.stringify(snapshot))).valid, "Normalized truck snapshot must round trip.", failures)
	snapshot.momentum = 501.0
	_check(_has_error(Game.validate_truck_snapshot(snapshot), "$.momentum", "inconsistent"), "Snapshot cannot disagree with its velocity.", failures)
	var surface := Game.contact("warehouse_01", "building", Vector2(100, 200), Vector2.UP)
	_check(Game.validate_contact(surface).valid, "Normalized building contact must validate.", failures)
	surface.normal = [0, 0]
	_check(not Game.validate_contact(surface).valid, "Zero contact normal must reject.", failures)
	_check(Game.validate_contact(Game.contact("unknown", "unknown", Vector2.ZERO, Vector2.UP)).valid, "Unclassified engine contacts normalize without scene references.", failures)
	var request := Game.resource_request("propane_01", 80.0, Vector2(160, -220), 10.0)
	_check(Game.validate_resource_request(request).valid, "Authored cost and reward request must validate.", failures)
	request.speed_cost = -1
	_check(not Game.validate_resource_request(request).valid, "Negative speed cost must reject.", failures)
	request.speed_cost = 0
	request.impulse = [1e100, 0]
	_check(not Game.validate_resource_request(request).valid, "Wire vectors must not overflow Godot Vector2 storage.", failures)


static func _test_events(failures: Array[String]) -> void:
	_check(Game.validate_event_stream(_fixture("events.valid"), "run_01").valid, "Canonical event fixture must validate.", failures)
	var launch := Game.gameplay_event("run_01", 0, "launch", 0.0, "", {"accuracy": 0.9, "speed_px_s": 850.0, "angle_rad": -0.35})
	var interaction := Game.gameplay_event("run_01", 1, "building_destroyed", 1.0, "shed_01", {"definition_id": "shed", "destruction_value": 100, "money_value": 10, "combo_value": 1, "resource_request": Game.resource_request("shed_01", 80, Vector2.ZERO, 0)})
	var stop := Game.gameplay_event("run_01", 2, "viability_lost", 2.0)
	var stream := [launch, interaction, stop]
	_check(Game.validate_event_stream(JSON.parse_string(JSON.stringify(stream)), "run_01").valid, "Ordered normalized events must round trip.", failures)
	_check(Game.validate_event_stream([stop], "run_01", 1, 1.0).valid, "Event stream can continue from its last accepted event.", failures)
	_check(not Game.validate_event_stream([launch, launch], "run_01").valid, "Duplicate event must reject.", failures)
	_check(not Game.validate_event_stream([launch, stop], "run_01").valid, "Event sequence gaps must reject.", failures)
	_check(not Game.validate_event_stream(stream, "another_run").valid, "Cross-run events must reject.", failures)
	stop.run_time_s = 0.5
	_check(not Game.validate_event_stream(stream, "run_01").valid, "Decreasing event time must reject.", failures)
	interaction.payload.resource_request.source_object_id = "another_shed"
	_check(not Game.validate_gameplay_event(interaction).valid, "Interaction and resource request source must agree.", failures)
	var drift := Game.gameplay_event("run_01", 0, "momentum_changed", 0, "", {"before_px_s": 100, "after_px_s": 90, "reason": "drag"})
	_check(Game.validate_gameplay_event(drift).valid, "Momentum observation must not require a scoring decision.", failures)
	drift.payload["score_awarded"] = 10
	_check(not Game.validate_gameplay_event(drift).valid, "Physics event must not smuggle score decisions.", failures)


static func _test_world(failures: Array[String]) -> void:
	var fixed: Dictionary = _fixture("debug_level.valid")
	_check(World.validate_level(fixed).valid, "Authored debug level fixture must validate.", failures)
	_check(World.validate_level(JSON.parse_string(JSON.stringify(fixed))).valid, "Fixed level must survive JSON round trip.", failures)
	var wrong_reference: Dictionary = fixed.duplicate(true)
	wrong_reference.objects[0].definition_id = "missing_building"
	_check(_has_error(World.validate_level(wrong_reference), "$.objects[0].definition_id", "unknown_reference"), "Level must reject missing object definitions.", failures)
	var duplicate: Dictionary = fixed.duplicate(true)
	duplicate.objects.append(duplicate.objects[0].duplicate(true))
	_check(not World.validate_level(duplicate).valid, "Duplicate object IDs must reject before world instantiation.", failures)
	var generated: Dictionary = fixed.duplicate(true)
	generated.layout_kind = "procedural"
	_check(not World.validate_level(generated).valid, "Runtime procedural level definitions must reject.", failures)
	var moving_building: Dictionary = fixed.duplicate(true)
	moving_building.objects[0].schedule = {"kind": "sine", "axis": [0, 1], "amplitude_px": 10, "period_s": 2, "phase_rad": 0}
	_check(not World.validate_level(moving_building).valid, "Ground buildings must have static schedules.", failures)
	_check(not World.validate_schedule({"kind": "sine", "axis": [0, 1], "amplitude_px": 10, "period_s": 0, "phase_rad": 0}).valid, "Zero-period schedules must reject.", failures)
	var bad_wreck: Dictionary = fixed.definitions[0].duplicate(true)
	bad_wreck.wreck_polygon = [[0, 0], [1, 1], [2, 2]]
	_check(not World.validate_object_definition(bad_wreck).valid, "Degenerate wreck collision polygons must reject.", failures)
	bad_wreck.wreck_polygon = [[0, 0], [4, 0], [1, 1], [0, 4]]
	_check(not World.validate_object_definition(bad_wreck).valid, "Concave wreck polygons must reject.", failures)
	bad_wreck.wreck_polygon = []
	for point_index in [0, 2, 4, 1, 3]:
		bad_wreck.wreck_polygon.append(Values.vec(Vector2.RIGHT.rotated(TAU * point_index / 5.0) * 100.0))
	_check(not World.validate_object_definition(bad_wreck).valid, "Self-intersecting star wrecks must reject even when adjacent turns agree.", failures)
	var propane: Dictionary = fixed.definitions[2]
	_check(propane.object_type == "building" and propane.building_type_id == fixed.definitions[0].building_type_id and propane.exchange.impulse[1] < 0, "Propulsion building must remain a data variant of a shared building type.", failures)


static func _test_run(failures: Array[String]) -> void:
	_check(Run.validate_mode_configuration(Run.mode_configuration("survival")).valid, "Survival mode has no countdown.", failures)
	_check(Run.validate_mode_configuration(Run.mode_configuration("timed_efficiency")).valid, "Timed Efficiency shares the mode configuration contract.", failures)
	_check(not Run.validate_mode_configuration(Run.mode_configuration("timed_efficiency", 0.0)).valid, "Timed Efficiency needs a positive duration.", failures)
	_check(not Run.validate_mode_configuration({"schema_id": "mode_configuration.v1", "mode_id": "survival", "time_limit_s": 60}).valid, "A hard time limit cannot enter Survival.", failures)
	var result: Dictionary = _fixture("run_result.valid")
	_check(Run.validate_run_result(JSON.parse_string(JSON.stringify(result))).valid, "Run result must survive JSON round trip.", failures)
	var reconstructed := Run.run_result(result.run_id, result.ruleset, result.end_reason, result.elapsed_s, result.score_breakdown, result.money_earned, result.distance_px, result.destroyed_count, result.best_combo)
	_check(Run.validate_run_result(reconstructed).valid and reconstructed.score_total == 1200, "Run result constructor preserves output arithmetic without scoring formulas.", failures)
	result.score_total += 1
	_check(_has_error(Run.validate_run_result(result), "$.score_total", "inconsistent"), "Result total and breakdown must agree.", failures)
	result.score_total -= 1
	result.end_reason = "time_limit"
	_check(not Run.validate_run_result(result).valid, "Survival must not claim a timer ending.", failures)
	_check(not Run.validate_eligibility({"eligible": true, "reasons": ["debug_build"]}).valid, "Eligibility cannot contradict rejection reasons.", failures)
	var snapshot := Run.run_snapshot({"state": "running", "run_id": "run_01", "ruleset": Game.ruleset(), "elapsed_s": 1.0, "time_remaining_s": null, "score_total": 0, "score_breakdown": Run.empty_score_breakdown(), "money_earned": 0, "distance_px": 10.0, "destroyed_count": 0, "combo": 0, "best_combo": 0})
	_check(Run.validate_run_snapshot(snapshot).valid and snapshot.is_read_only(), "Run snapshot is a validated immutable observation.", failures)
	_check(Run.validate_scoring_input(Run.scoring_input("distance", 120.5, "run_01:7", 1.0)).valid, "Scoring input preserves authored amounts without a formula.", failures)
	_check(not Run.validate_scoring_input(Run.scoring_input("distance", 1.0, "run_01:07", 1.0)).valid, "Scoring inputs use canonical source event references.", failures)


static func _test_presentation(failures: Array[String]) -> void:
	var fixture: Dictionary = _fixture("hud_state.valid")
	_check(Presentation.validate_hud_state(JSON.parse_string(JSON.stringify(fixture))).valid, "HUD fixture must round trip without gameplay nodes.", failures)
	var frozen := Presentation.hud_state(fixture)
	fixture.run.score_breakdown.destruction = 900
	fixture.truck.nudge_energy = 0
	_check(frozen.run.score_breakdown.destruction == 0 and frozen.truck.nudge_energy == 100, "HUD must not alias producer score or resource state.", failures)
	_check(frozen.is_read_only() and frozen.run.is_read_only() and frozen.radar.detections.is_read_only(), "Every HUD collection must be read-only.", failures)
	var bad: Dictionary = _fixture("hud_state.valid")
	bad.resources.nudge_capacity = 99
	_check(Presentation.hud_state(bad).is_empty(), "Invalid HUD state must not be published.", failures)
	var result: Dictionary = _fixture("run_result.valid")
	var results := Presentation.results_state(result)
	_check(Presentation.validate_results_state(results).valid and results.result.score_breakdown.is_read_only(), "Results view must deep-freeze the run result.", failures)
	result.score_total = 1
	_check(results.result.score_total == 1200, "Results view must survive later producer changes.", failures)
	var views := [
		{"schema_id": "profile_view.v1", "display_name": "Driver", "money_balance": 10, "unlocked_levels": ["debug_yard"], "truck_id": "truck_01", "equipped_module_id": ""},
		{"schema_id": "upgrade_view.v1", "money_balance": 10, "items": [{"upgrade_id": "nudge_capacity", "title_key": "UPGRADE_NUDGE", "description_key": "UPGRADE_NUDGE_DESCRIPTION", "level": 0, "max_level": 3, "cost": 100, "available": false, "locked_reason_key": "INSUFFICIENT_MONEY"}]},
		{"schema_id": "leaderboard_view.v1", "ruleset": Game.ruleset(), "status": "unavailable", "rows": []},
		{"schema_id": "queue_view.v1", "pending_count": 0, "accepted_count": 0, "rejected_count": 0, "status": "offline"},
		{"schema_id": "settings_view.v1", "master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 1.0, "resolution": [1280, 720], "fullscreen": false, "graphics_quality": "high", "ui_scale": 1.0, "text_scale": 1.0, "screen_shake": 0.5, "flash_intensity": 0.5, "visual_audio_cues": true, "language_id": "en", "instant_restart": false, "control_labels": [{"action_id": "launch", "binding_label": "Space"}]},
	]
	for view in views:
		var state := Presentation.screen_state(view.schema_id, view)
		_check(not state.is_empty() and state.is_read_only(), "Later-screen contract must publish read-only display data: " + view.schema_id, failures)
		view["domain_object"] = RefCounted.new()
		_check(not Presentation.validate_screen_state(view).valid, "Presentation must reject domain references and unknown fields.", failures)


static func _test_malformed_value_resilience(failures: Array[String]) -> void:
	# Boundary failures must return structured errors, never crash a producer/consumer.
	var hud: Dictionary = _fixture("hud_state.valid")
	var level: Dictionary = _fixture("debug_level.valid")
	var cases := [
		{"value": Game.ruleset(), "validator": Game.validate_ruleset},
		{"value": _fixture("command_nudge.valid"), "validator": Game.validate_command},
		{"value": hud.truck, "validator": Game.validate_truck_snapshot},
		{"value": Game.contact("ground", "ground", Vector2.ZERO, Vector2.UP), "validator": Game.validate_contact},
		{"value": Game.resource_request("shed_01", 70, Vector2.ZERO, 0), "validator": Game.validate_resource_request},
		{"value": _fixture("events.valid")[1], "validator": Game.validate_gameplay_event},
		{"value": level.definitions[0], "validator": World.validate_object_definition},
		{"value": level.definitions[0].exchange, "validator": World.validate_resource_exchange},
		{"value": level.objects[0], "validator": World.validate_object_instance},
		{"value": level.objects[3].schedule, "validator": World.validate_schedule},
		{"value": level, "validator": World.validate_level},
		{"value": Run.mode_configuration("timed_efficiency"), "validator": Run.validate_mode_configuration},
		{"value": Run.scoring_input("distance", 10, "run_01:0", 0), "validator": Run.validate_scoring_input},
		{"value": hud.run, "validator": Run.validate_run_snapshot},
		{"value": _fixture("run_result.valid"), "validator": Run.validate_run_result},
		{"value": {"eligible": false, "reasons": ["debug_build"]}, "validator": Run.validate_eligibility},
		{"value": hud.radar, "validator": Presentation.validate_radar},
		{"value": hud, "validator": Presentation.validate_hud_state},
		{"value": Presentation.results_state(_fixture("run_result.valid")), "validator": Presentation.validate_results_state},
	]
	for test_case in cases:
		for key in test_case.value:
			for replacement in [null, true, [], {}, NAN, Vector2.ONE, RefCounted.new()]:
				var changed: Dictionary = test_case.value.duplicate(true)
				changed[key] = replacement
				var validation: Variant = test_case.validator.call(changed)
				_check(validation is Dictionary and validation.get("valid") is bool and validation.get("errors") is Array, "Malformed field must return a validation result: " + str(key), failures)
