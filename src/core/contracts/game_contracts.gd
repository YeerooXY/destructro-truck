extends RefCounted
## First-playable shared IDs and device/scene-neutral boundaries.

const Values = preload("res://src/core/domain/contract_values.gd")

const RULESET_VERSION := "ruleset_debug_v1"
const PHYSICS_TUNING_VERSION := "physics_debug_v1"
const SCORING_TUNING_VERSION := "scoring_debug_v1"
const TRUCK_ID := "truck_01"
const PIXELS_PER_METRE := 100.0
const LEVEL_VERSIONS := {"debug_yard": "debug_yard_v1"}
const MODE_IDS := ["survival", "timed_efficiency"]
const CATEGORY_IDS := ["stock", "progression"]
const ACTION_IDS := ["launch", "rotate", "nudge", "equipment", "pause", "restart", "confirm", "back"]
const CONTACT_KINDS := ["ground", "building", "wreck", "aerial_target", "pickup", "unknown"]
const EVENT_TYPES := ["launch", "contact", "building_destroyed", "target_collected", "pickup_collected", "landed", "nudge_used", "momentum_changed", "viability_lost"]


static func ruleset(mode_id: String = "survival", category_id: String = "stock", level_id: String = "debug_yard") -> Dictionary:
	return {
		"schema_id": "ruleset.v1", "ruleset_version": RULESET_VERSION,
		"physics_tuning_version": PHYSICS_TUNING_VERSION, "scoring_tuning_version": SCORING_TUNING_VERSION,
		"level_id": level_id, "level_version": LEVEL_VERSIONS.get(level_id, ""),
		"mode_id": mode_id, "category_id": category_id, "truck_id": TRUCK_ID,
	}


static func validate_ruleset(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "ruleset_version", "physics_tuning_version", "scoring_tuning_version", "level_id", "level_version", "mode_id", "category_id", "truck_id"], [], errors):
		return Values.result(errors)
	Values.schema(value, "ruleset.v1", errors)
	Values.enum_value(value.get("ruleset_version"), [RULESET_VERSION], errors, "$.ruleset_version")
	Values.enum_value(value.get("physics_tuning_version"), [PHYSICS_TUNING_VERSION], errors, "$.physics_tuning_version")
	Values.enum_value(value.get("scoring_tuning_version"), [SCORING_TUNING_VERSION], errors, "$.scoring_tuning_version")
	Values.enum_value(value.get("mode_id"), MODE_IDS, errors, "$.mode_id")
	Values.enum_value(value.get("category_id"), CATEGORY_IDS, errors, "$.category_id")
	Values.enum_value(value.get("truck_id"), [TRUCK_ID], errors, "$.truck_id")
	if Values.enum_value(value.get("level_id"), LEVEL_VERSIONS.keys(), errors, "$.level_id"):
		if not Values.same_string(value.get("level_version"), LEVEL_VERSIONS[value.level_id]):
			Values.error(errors, "$.level_version", "unsupported_version", "Level version does not match its registered ID.")
	return Values.result(errors)


static func command(action_id: String, sequence: int, run_time_s: float, payload: Dictionary = {}) -> Dictionary:
	return {"schema_id": "player_command.v1", "action_id": action_id, "sequence": sequence, "run_time_s": run_time_s, "payload": payload.duplicate(true)}


static func validate_command(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "action_id", "sequence", "run_time_s", "payload"], [], errors):
		return Values.result(errors)
	Values.schema(value, "player_command.v1", errors)
	Values.integer(value.get("sequence"), errors, "$.sequence")
	Values.number(value.get("run_time_s"), errors, "$.run_time_s", 0.0)
	if not Values.enum_value(value.get("action_id"), ACTION_IDS, errors, "$.action_id"):
		return Values.result(errors)
	var payload: Variant = value.get("payload")
	match value.action_id:
		"rotate":
			if Values.fields(payload, ["axis"], [], errors, "$.payload"):
				Values.number(payload.get("axis"), errors, "$.payload.axis", -1.0, 1.0)
		"nudge":
			if Values.fields(payload, ["direction", "strength"], [], errors, "$.payload"):
				Values.vector(payload.get("direction"), errors, "$.payload.direction", true)
				Values.number(payload.get("strength"), errors, "$.payload.strength", 0.0, 1.0)
		_:
			Values.fields(payload, [], [], errors, "$.payload")
	return Values.result(errors)


static func truck_snapshot(run_time_s: float, position: Vector2, velocity: Vector2, rotation_rad: float, angular_velocity_rad_s: float, grounded: bool, nudge_energy: float, equipment_charge: float = 0.0, viable: bool = true) -> Dictionary:
	return {
		"schema_id": "truck_snapshot.v1", "run_time_s": run_time_s,
		"position": Values.vec(position), "velocity": Values.vec(velocity),
		"rotation_rad": rotation_rad, "angular_velocity_rad_s": angular_velocity_rad_s,
		"grounded": grounded, "momentum": velocity.length(), "viable": viable,
		"nudge_energy": nudge_energy, "equipment_charge": equipment_charge,
	}


static func validate_truck_snapshot(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "run_time_s", "position", "velocity", "rotation_rad", "angular_velocity_rad_s", "grounded", "momentum", "viable", "nudge_energy", "equipment_charge"], [], errors):
		return Values.result(errors)
	Values.schema(value, "truck_snapshot.v1", errors)
	Values.number(value.get("run_time_s"), errors, "$.run_time_s", 0.0)
	Values.vector(value.get("position"), errors, "$.position")
	var velocity_valid := Values.vector(value.get("velocity"), errors, "$.velocity")
	Values.number(value.get("rotation_rad"), errors, "$.rotation_rad")
	Values.number(value.get("angular_velocity_rad_s"), errors, "$.angular_velocity_rad_s")
	Values.boolean(value.get("grounded"), errors, "$.grounded")
	Values.boolean(value.get("viable"), errors, "$.viable")
	var momentum_valid := Values.number(value.get("momentum"), errors, "$.momentum", 0.0)
	if velocity_valid and momentum_valid:
		var speed := Values.to_vector(value.velocity).length()
		if not is_equal_approx(float(value.momentum), speed):
			Values.error(errors, "$.momentum", "inconsistent", "Momentum snapshot must equal velocity magnitude.")
	Values.number(value.get("nudge_energy"), errors, "$.nudge_energy", 0.0)
	Values.number(value.get("equipment_charge"), errors, "$.equipment_charge", 0.0)
	return Values.result(errors)


static func contact(object_id: String, kind: String, point: Vector2, normal: Vector2) -> Dictionary:
	return {"schema_id": "contact.v1", "object_id": object_id, "kind": kind, "point": Values.vec(point), "normal": Values.vec(normal)}


static func validate_contact(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "object_id", "kind", "point", "normal"], [], errors):
		return Values.result(errors)
	Values.schema(value, "contact.v1", errors)
	Values.identifier(value.get("object_id"), errors, "$.object_id")
	Values.enum_value(value.get("kind"), CONTACT_KINDS, errors, "$.kind")
	Values.vector(value.get("point"), errors, "$.point")
	if Values.vector(value.get("normal"), errors, "$.normal", true):
		if not is_equal_approx(Values.to_vector(value.normal).length_squared(), 1.0):
			Values.error(errors, "$.normal", "normal_length", "Contact normals must have unit length.")
	return Values.result(errors)


static func resource_request(source_object_id: String, speed_cost: float, impulse: Vector2, nudge_refill: float, equipment_refill: float = 0.0) -> Dictionary:
	return {
		"schema_id": "resource_request.v1", "source_object_id": source_object_id,
		"speed_cost": speed_cost, "impulse": Values.vec(impulse),
		"nudge_refill": nudge_refill, "equipment_refill": equipment_refill,
	}


static func validate_resource_request(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "source_object_id", "speed_cost", "impulse", "nudge_refill", "equipment_refill"], [], errors):
		return Values.result(errors)
	Values.schema(value, "resource_request.v1", errors)
	Values.identifier(value.get("source_object_id"), errors, "$.source_object_id")
	for key in ["speed_cost", "nudge_refill", "equipment_refill"]:
		Values.number(value.get(key), errors, "$." + key, 0.0)
	Values.vector(value.get("impulse"), errors, "$.impulse")
	return Values.result(errors)


static func gameplay_event(run_id: String, sequence: int, event_type: String, run_time_s: float, source_object_id: String = "", payload: Dictionary = {}) -> Dictionary:
	return {
		"schema_id": "gameplay_event.v1", "event_id": run_id + ":" + str(sequence),
		"run_id": run_id, "sequence": sequence, "event_type": event_type,
		"run_time_s": run_time_s, "source_object_id": source_object_id,
		"payload": payload.duplicate(true),
	}


static func validate_gameplay_event(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "event_id", "run_id", "sequence", "event_type", "run_time_s", "source_object_id", "payload"], [], errors):
		return Values.result(errors)
	Values.schema(value, "gameplay_event.v1", errors)
	var run_valid := Values.identifier(value.get("run_id"), errors, "$.run_id")
	var sequence_valid := Values.integer(value.get("sequence"), errors, "$.sequence")
	if run_valid and sequence_valid and not Values.same_string(value.get("event_id"), str(value.run_id) + ":" + str(int(value.sequence))):
		Values.error(errors, "$.event_id", "inconsistent", "Event ID must be run_id:sequence.")
	Values.number(value.get("run_time_s"), errors, "$.run_time_s", 0.0)
	Values.identifier(value.get("source_object_id"), errors, "$.source_object_id", true)
	if Values.enum_value(value.get("event_type"), EVENT_TYPES, errors, "$.event_type"):
		_validate_event_payload(value.event_type, value.get("payload"), errors)
	if value.get("event_type") in ["building_destroyed", "target_collected", "pickup_collected"]:
		if Values.same_string(value.get("source_object_id", ""), ""):
			Values.error(errors, "$.source_object_id", "required", "World interactions need a source object ID.")
		var payload: Variant = value.get("payload")
		if payload is Dictionary and payload.get("resource_request") is Dictionary:
			if not Values.same_string(payload.resource_request.get("source_object_id"), value.get("source_object_id")):
				Values.error(errors, "$.payload.resource_request.source_object_id", "inconsistent", "Resource request source must match the event source.")
	return Values.result(errors)


static func _validate_event_payload(event_type: String, payload: Variant, errors: Array) -> void:
	match event_type:
		"launch":
			if Values.fields(payload, ["accuracy", "speed_px_s", "angle_rad"], [], errors, "$.payload"):
				Values.number(payload.get("accuracy"), errors, "$.payload.accuracy", 0.0, 1.0)
				Values.number(payload.get("speed_px_s"), errors, "$.payload.speed_px_s", 0.0)
				Values.number(payload.get("angle_rad"), errors, "$.payload.angle_rad")
		"contact":
			if Values.fields(payload, ["contact"], [], errors, "$.payload"):
				Values.append_validation(errors, validate_contact(payload.get("contact")), "$.payload.contact")
		"building_destroyed", "target_collected", "pickup_collected":
			if Values.fields(payload, ["definition_id", "destruction_value", "money_value", "combo_value", "resource_request"], [], errors, "$.payload"):
				Values.identifier(payload.get("definition_id"), errors, "$.payload.definition_id")
				Values.number(payload.get("destruction_value"), errors, "$.payload.destruction_value", 0.0)
				Values.integer(payload.get("money_value"), errors, "$.payload.money_value")
				Values.number(payload.get("combo_value"), errors, "$.payload.combo_value", 0.0)
				Values.append_validation(errors, validate_resource_request(payload.get("resource_request")), "$.payload.resource_request")
		"landed":
			if Values.fields(payload, ["contact", "impact_speed_px_s", "clean"], [], errors, "$.payload"):
				Values.append_validation(errors, validate_contact(payload.get("contact")), "$.payload.contact")
				Values.number(payload.get("impact_speed_px_s"), errors, "$.payload.impact_speed_px_s", 0.0)
				Values.boolean(payload.get("clean"), errors, "$.payload.clean")
		"nudge_used":
			if Values.fields(payload, ["energy_spent", "impulse"], [], errors, "$.payload"):
				Values.number(payload.get("energy_spent"), errors, "$.payload.energy_spent", 0.0)
				Values.vector(payload.get("impulse"), errors, "$.payload.impulse")
		"momentum_changed":
			if Values.fields(payload, ["before_px_s", "after_px_s", "reason"], [], errors, "$.payload"):
				Values.number(payload.get("before_px_s"), errors, "$.payload.before_px_s", 0.0)
				Values.number(payload.get("after_px_s"), errors, "$.payload.after_px_s", 0.0)
				Values.enum_value(payload.get("reason"), ["building", "target", "pickup", "landing", "nudge", "drag", "launch", "equipment"], errors, "$.payload.reason")
		"viability_lost":
			Values.fields(payload, [], [], errors, "$.payload")


static func validate_event_stream(events: Variant, run_id: String, last_sequence: int = -1, last_run_time_s: float = 0.0) -> Dictionary:
	var errors: Array = []
	Values.identifier(run_id, errors, "$.run_id")
	Values.integer(last_sequence, errors, "$.last_sequence", -1)
	Values.number(last_run_time_s, errors, "$.last_run_time_s", 0.0)
	if not events is Array:
		Values.error(errors, "$", "type", "Expected an event array.")
		return Values.result(errors)
	var expected_sequence := last_sequence + 1
	var previous_time := last_run_time_s
	for index in events.size():
		var event: Variant = events[index]
		var validation := validate_gameplay_event(event)
		Values.append_validation(errors, validation, "$[%d]" % index)
		if not validation.valid:
			continue
		if event.run_id != run_id:
			Values.error(errors, "$[%d].run_id" % index, "wrong_run", "Event belongs to a different run.")
		if event.sequence != expected_sequence:
			Values.error(errors, "$[%d].sequence" % index, "event_order", "Expected the next sequence exactly; duplicates and gaps reject.")
		if event.run_time_s < previous_time:
			Values.error(errors, "$[%d].run_time_s" % index, "time_order", "Event time must not decrease.")
		expected_sequence += 1
		previous_time = event.run_time_s
	return Values.result(errors)
