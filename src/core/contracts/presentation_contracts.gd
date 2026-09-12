extends RefCounted
## Presentation receives validated, recursively immutable data and emits commands.

const Values = preload("res://src/core/domain/contract_values.gd")
const Game = preload("res://src/core/contracts/game_contracts.gd")
const Run = preload("res://src/core/contracts/run_contracts.gd")
const World = preload("res://src/core/contracts/world_contracts.gd")
const SUBMISSION_STATUSES := ["unavailable", "pending", "accepted", "rejected"]


static func hud_state(fields: Dictionary) -> Dictionary:
	var value := fields.duplicate(true)
	value["schema_id"] = "hud_state.v1"
	return Values.read_only_copy(value) if validate_hud_state(value).valid else {}


static func validate_hud_state(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "run", "truck", "launch", "resources", "radar"], [], errors):
		return Values.result(errors)
	Values.schema(value, "hud_state.v1", errors)
	Values.append_validation(errors, Run.validate_run_snapshot(value.get("run")), "$.run")
	Values.append_validation(errors, Game.validate_truck_snapshot(value.get("truck")), "$.truck")
	var launch: Variant = value.get("launch")
	if Values.fields(launch, ["ready", "phase", "accuracy"], [], errors, "$.launch"):
		Values.boolean(launch.get("ready"), errors, "$.launch.ready")
		Values.number(launch.get("phase"), errors, "$.launch.phase", 0.0, 1.0)
		Values.number(launch.get("accuracy"), errors, "$.launch.accuracy", 0.0, 1.0)
	var resources: Variant = value.get("resources")
	if Values.fields(resources, ["nudge_capacity", "equipment_capacity"], [], errors, "$.resources"):
		var nudge_valid := Values.number(resources.get("nudge_capacity"), errors, "$.resources.nudge_capacity", 0.0)
		var equipment_valid := Values.number(resources.get("equipment_capacity"), errors, "$.resources.equipment_capacity", 0.0)
		if value.get("truck") is Dictionary:
			var truck: Dictionary = value.truck
			if nudge_valid and _is_number(truck.get("nudge_energy")) and truck.nudge_energy > resources.nudge_capacity:
				Values.error(errors, "$.resources.nudge_capacity", "inconsistent", "Displayed energy cannot exceed its displayed capacity.")
			if equipment_valid and _is_number(truck.get("equipment_charge")) and truck.equipment_charge > resources.equipment_capacity:
				Values.error(errors, "$.resources.equipment_capacity", "inconsistent", "Displayed charge cannot exceed its displayed capacity.")
	Values.append_validation(errors, validate_radar(value.get("radar")), "$.radar")
	return Values.result(errors)


static func validate_radar(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["tier", "detections"], [], errors):
		return Values.result(errors)
	Values.integer(value.get("tier"), errors, "$.tier", 0, 5)
	if not value.get("detections") is Array:
		Values.error(errors, "$.detections", "type", "Expected radar observations.")
		return Values.result(errors)
	for index in value.detections.size():
		var detection: Variant = value.detections[index]
		var path := "$.detections[%d]" % index
		if not Values.fields(detection, ["object_id", "classification", "distance_px", "eta_s", "velocity"], [], errors, path):
			continue
		Values.identifier(detection.get("object_id"), errors, path + ".object_id")
		Values.enum_value(detection.get("classification"), ["unknown"] + World.OBJECT_TYPES, errors, path + ".classification")
		for key in ["distance_px", "eta_s"]:
			if detection.get(key) != null:
				Values.number(detection[key], errors, path + "." + key, 0.0)
		if detection.get("velocity") != null:
			Values.vector(detection.velocity, errors, path + ".velocity")
	return Values.result(errors)


static func results_state(result: Dictionary, submission_status: String = "unavailable") -> Dictionary:
	var value := {"schema_id": "results_state.v1", "result": result.duplicate(true), "submission_status": submission_status}
	return Values.read_only_copy(value) if validate_results_state(value).valid else {}


static func validate_results_state(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "result", "submission_status"], [], errors):
		return Values.result(errors)
	Values.schema(value, "results_state.v1", errors)
	Values.append_validation(errors, Run.validate_run_result(value.get("result")), "$.result")
	Values.enum_value(value.get("submission_status"), SUBMISSION_STATUSES, errors, "$.submission_status")
	return Values.result(errors)


static func screen_state(schema_id: String, fields: Dictionary) -> Dictionary:
	# Later-screen display shells; this does not implement their domain/services.
	var value := fields.duplicate(true)
	value["schema_id"] = schema_id
	return Values.read_only_copy(value) if validate_screen_state(value).valid else {}


static func validate_screen_state(value: Variant) -> Dictionary:
	var errors: Array = []
	if not value is Dictionary:
		Values.error(errors, "$", "type", "Expected a presentation dictionary.")
		return Values.result(errors)
	match value.get("schema_id"):
		"profile_view.v1":
			_validate_profile(value, errors)
		"upgrade_view.v1":
			_validate_upgrades(value, errors)
		"leaderboard_view.v1":
			_validate_leaderboard(value, errors)
		"queue_view.v1":
			Values.fields(value, ["schema_id", "pending_count", "accepted_count", "rejected_count", "status"], [], errors)
			for key in ["pending_count", "accepted_count", "rejected_count"]:
				Values.integer(value.get(key), errors, "$." + key)
			Values.enum_value(value.get("status"), ["idle", "offline", "submitting"], errors, "$.status")
		"settings_view.v1":
			_validate_settings(value, errors)
		_:
			Values.error(errors, "$.schema_id", "unsupported_schema", "Unsupported presentation schema.")
	return Values.result(errors)


static func _validate_profile(value: Dictionary, errors: Array) -> void:
	Values.fields(value, ["schema_id", "display_name", "money_balance", "unlocked_levels", "truck_id", "equipped_module_id"], [], errors)
	Values.text_value(value.get("display_name"), errors, "$.display_name", 32)
	Values.integer(value.get("money_balance"), errors, "$.money_balance")
	Values.enum_value(value.get("truck_id"), [Game.TRUCK_ID], errors, "$.truck_id")
	Values.identifier(value.get("equipped_module_id"), errors, "$.equipped_module_id", true)
	if not value.get("unlocked_levels") is Array:
		Values.error(errors, "$.unlocked_levels", "type", "Expected level identifiers.")
		return
	for index in value.unlocked_levels.size():
		Values.enum_value(value.unlocked_levels[index], Game.LEVEL_VERSIONS.keys(), errors, "$.unlocked_levels[%d]" % index)


static func _validate_upgrades(value: Dictionary, errors: Array) -> void:
	Values.fields(value, ["schema_id", "money_balance", "items"], [], errors)
	Values.integer(value.get("money_balance"), errors, "$.money_balance")
	if not value.get("items") is Array:
		Values.error(errors, "$.items", "type", "Expected upgrade display items.")
		return
	for index in value.items.size():
		var item: Variant = value.items[index]
		var path := "$.items[%d]" % index
		if not Values.fields(item, ["upgrade_id", "title_key", "description_key", "level", "max_level", "cost", "available", "locked_reason_key"], [], errors, path):
			continue
		Values.identifier(item.get("upgrade_id"), errors, path + ".upgrade_id")
		for key in ["title_key", "description_key"]:
			Values.text_value(item.get(key), errors, path + "." + key, 128)
		Values.text_value(item.get("locked_reason_key"), errors, path + ".locked_reason_key", 128, true)
		var level_valid := Values.integer(item.get("level"), errors, path + ".level")
		var max_valid := Values.integer(item.get("max_level"), errors, path + ".max_level", 1)
		if level_valid and max_valid and item.level > item.max_level:
			Values.error(errors, path + ".level", "inconsistent", "Displayed upgrade level cannot exceed its maximum.")
		Values.integer(item.get("cost"), errors, path + ".cost")
		Values.boolean(item.get("available"), errors, path + ".available")


static func _validate_leaderboard(value: Dictionary, errors: Array) -> void:
	Values.fields(value, ["schema_id", "ruleset", "status", "rows"], [], errors)
	Values.append_validation(errors, Game.validate_ruleset(value.get("ruleset")), "$.ruleset")
	Values.enum_value(value.get("status"), ["idle", "loading", "ready", "unavailable", "error"], errors, "$.status")
	if not value.get("rows") is Array:
		Values.error(errors, "$.rows", "type", "Expected leaderboard rows.")
		return
	for index in value.rows.size():
		var row: Variant = value.rows[index]
		var path := "$.rows[%d]" % index
		if not Values.fields(row, ["rank", "display_name", "score", "date_utc", "truck_id", "level_id", "category_id"], [], errors, path):
			continue
		Values.integer(row.get("rank"), errors, path + ".rank", 1)
		Values.text_value(row.get("display_name"), errors, path + ".display_name", 32)
		Values.integer(row.get("score"), errors, path + ".score")
		Values.text_value(row.get("date_utc"), errors, path + ".date_utc", 32)
		Values.enum_value(row.get("truck_id"), [Game.TRUCK_ID], errors, path + ".truck_id")
		Values.enum_value(row.get("level_id"), Game.LEVEL_VERSIONS.keys(), errors, path + ".level_id")
		Values.enum_value(row.get("category_id"), Game.CATEGORY_IDS, errors, path + ".category_id")


static func _validate_settings(value: Dictionary, errors: Array) -> void:
	Values.fields(value, ["schema_id", "master_volume", "music_volume", "sfx_volume", "resolution", "fullscreen", "graphics_quality", "ui_scale", "text_scale", "screen_shake", "flash_intensity", "visual_audio_cues", "language_id", "instant_restart", "control_labels"], [], errors)
	for key in ["master_volume", "music_volume", "sfx_volume", "screen_shake", "flash_intensity"]:
		Values.number(value.get(key), errors, "$." + key, 0.0, 1.0)
	for key in ["fullscreen", "visual_audio_cues", "instant_restart"]:
		Values.boolean(value.get(key), errors, "$." + key)
	Values.enum_value(value.get("graphics_quality"), ["low", "medium", "high"], errors, "$.graphics_quality")
	Values.enum_value(value.get("language_id"), ["en"], errors, "$.language_id")
	for key in ["ui_scale", "text_scale"]:
		Values.number(value.get(key), errors, "$." + key, 0.5, 3.0)
	if Values.vector(value.get("resolution"), errors, "$.resolution"):
		Values.integer(value.resolution[0], errors, "$.resolution[0]", 1)
		Values.integer(value.resolution[1], errors, "$.resolution[1]", 1)
	if not value.get("control_labels") is Array:
		Values.error(errors, "$.control_labels", "type", "Expected device-neutral action labels.")
		return
	for index in value.control_labels.size():
		var binding: Variant = value.control_labels[index]
		var path := "$.control_labels[%d]" % index
		if Values.fields(binding, ["action_id", "binding_label"], [], errors, path):
			Values.enum_value(binding.get("action_id"), Game.ACTION_IDS, errors, path + ".action_id")
			Values.text_value(binding.get("binding_label"), errors, path + ".binding_label", 128)


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
