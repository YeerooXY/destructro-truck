extends RefCounted
## Authored content only. These contracts do not instantiate or simulate objects.

const Values = preload("res://src/core/domain/contract_values.gd")
const Game = preload("res://src/core/contracts/game_contracts.gd")
const OBJECT_TYPES := ["building", "balloon", "satellite", "plane", "recharge", "pickup"]
const BUILDING_STATES := ["intact", "destroyed"]


static func resource_exchange(speed_cost: float = 0.0, impulse: Vector2 = Vector2.ZERO, nudge_refill: float = 0.0, equipment_refill: float = 0.0, destruction_value: float = 0.0, money_value: int = 0, combo_value: float = 0.0) -> Dictionary:
	return {"speed_cost": speed_cost, "impulse": Values.vec(impulse), "nudge_refill": nudge_refill, "equipment_refill": equipment_refill, "destruction_value": destruction_value, "money_value": money_value, "combo_value": combo_value}


static func validate_resource_exchange(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["speed_cost", "impulse", "nudge_refill", "equipment_refill", "destruction_value", "money_value", "combo_value"], [], errors):
		return Values.result(errors)
	for key in ["speed_cost", "nudge_refill", "equipment_refill", "destruction_value", "combo_value"]:
		Values.number(value.get(key), errors, "$." + key, 0.0)
	Values.integer(value.get("money_value"), errors, "$.money_value")
	Values.vector(value.get("impulse"), errors, "$.impulse")
	return Values.result(errors)


static func object_definition(definition_id: String, object_type: String, size: Vector2, exchange: Dictionary, wreck_polygon: Array = [], visual_profile: String = "debug", building_type_id: String = "") -> Dictionary:
	return {
		"schema_id": "world_object.v1", "definition_id": definition_id, "object_type": object_type,
		"size": Values.vec(size), "exchange": exchange.duplicate(true),
		"wreck_polygon": wreck_polygon.duplicate(true), "visual_profile": visual_profile,
		"building_type_id": building_type_id,
	}


static func validate_object_definition(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "definition_id", "object_type", "size", "exchange", "wreck_polygon", "visual_profile", "building_type_id"], [], errors):
		return Values.result(errors)
	Values.schema(value, "world_object.v1", errors)
	Values.identifier(value.get("definition_id"), errors, "$.definition_id")
	Values.enum_value(value.get("object_type"), OBJECT_TYPES, errors, "$.object_type")
	Values.identifier(value.get("visual_profile"), errors, "$.visual_profile")
	if Values.vector(value.get("size"), errors, "$.size"):
		if value["size"][0] <= 0 or value["size"][1] <= 0:
			Values.error(errors, "$.size", "range", "Collision rectangle dimensions must be positive.")
	Values.append_validation(errors, validate_resource_exchange(value.get("exchange")), "$.exchange")
	if Values.same_string(value.get("object_type"), "building"):
		Values.identifier(value.get("building_type_id"), errors, "$.building_type_id")
		_validate_wreck(value.get("wreck_polygon"), errors)
	else:
		if not Values.same_string(value.get("building_type_id"), ""):
			Values.error(errors, "$.building_type_id", "inapplicable", "Only buildings have a building type.")
		if not value.get("wreck_polygon") is Array or not value.wreck_polygon.is_empty():
			Values.error(errors, "$.wreck_polygon", "inapplicable", "Only buildings leave collidable wrecks.")
	return Values.result(errors)


static func _validate_wreck(polygon: Variant, errors: Array) -> void:
	if not polygon is Array or polygon.size() < 3 or polygon.size() > 16:
		Values.error(errors, "$.wreck_polygon", "polygon", "Wrecks use one convex polygon with 3–16 distinct vertices.")
		return
	var valid := true
	for index in polygon.size():
		if not Values.vector(polygon[index], errors, "$.wreck_polygon[%d]" % index):
			valid = false
	if not valid:
		return
	var winding := 0.0
	for index in polygon.size():
		var a := Values.to_vector(polygon[index])
		var b := Values.to_vector(polygon[(index + 1) % polygon.size()])
		var c := Values.to_vector(polygon[(index + 2) % polygon.size()])
		var cross := (b - a).cross(c - b)
		if is_zero_approx(cross) or (winding != 0.0 and signf(cross) != winding):
			Values.error(errors, "$.wreck_polygon", "convex_polygon", "Wreck vertices must form a nondegenerate convex perimeter.")
			return
		winding = signf(cross)
		# Consistent adjacent turns alone also accept star-shaped self-intersections.
		# A convex perimeter places every other vertex on the same side of each edge.
		for vertex_index in polygon.size():
			if vertex_index == index or vertex_index == (index + 1) % polygon.size():
				continue
			var side := (b - a).cross(Values.to_vector(polygon[vertex_index]) - a)
			if is_zero_approx(side) or signf(side) != winding:
				Values.error(errors, "$.wreck_polygon", "convex_polygon", "Wreck perimeter must not intersect itself or fold inward.")
				return
		for other_index in range(index + 1, polygon.size()):
			if a.is_equal_approx(Values.to_vector(polygon[other_index])):
				Values.error(errors, "$.wreck_polygon", "duplicate_vertex", "Wreck vertices must be distinct.")
				return


static func object_instance(object_id: String, definition_id: String, position: Vector2, schedule: Dictionary = {"kind": "static"}) -> Dictionary:
	return {"object_id": object_id, "definition_id": definition_id, "position": Values.vec(position), "schedule": schedule.duplicate(true)}


static func validate_schedule(value: Variant) -> Dictionary:
	var errors: Array = []
	if not value is Dictionary:
		Values.error(errors, "$", "type", "Expected a schedule dictionary.")
		return Values.result(errors)
	if not Values.enum_value(value.get("kind"), ["static", "sine"], errors, "$.kind"):
		return Values.result(errors)
	if value.kind == "static":
		Values.fields(value, ["kind"], [], errors)
	else:
		Values.fields(value, ["kind", "axis", "amplitude_px", "period_s", "phase_rad"], [], errors)
		if Values.vector(value.get("axis"), errors, "$.axis", true):
			if not is_equal_approx(Values.to_vector(value.axis).length_squared(), 1.0):
				Values.error(errors, "$.axis", "normal_length", "Schedule axis must be unit length.")
		Values.number(value.get("amplitude_px"), errors, "$.amplitude_px", 0.0, Values.MAX_VECTOR_COMPONENT)
		if Values.number(value.get("period_s"), errors, "$.period_s", 0.0) and value.period_s == 0:
			Values.error(errors, "$.period_s", "range", "A repeating schedule needs a positive period.")
		Values.number(value.get("phase_rad"), errors, "$.phase_rad")
	return Values.result(errors)


static func validate_object_instance(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["object_id", "definition_id", "position", "schedule"], [], errors):
		return Values.result(errors)
	Values.identifier(value.get("object_id"), errors, "$.object_id")
	Values.identifier(value.get("definition_id"), errors, "$.definition_id")
	Values.vector(value.get("position"), errors, "$.position")
	Values.append_validation(errors, validate_schedule(value.get("schedule")), "$.schedule")
	return Values.result(errors)


static func level(level_id: String, length_px: float, ground_y: float, spawn_position: Vector2, definitions: Array, objects: Array) -> Dictionary:
	return {
		"schema_id": "level.v1", "level_id": level_id,
		"level_version": Game.LEVEL_VERSIONS.get(level_id, ""), "layout_kind": "fixed",
		"length_px": length_px, "ground_y": ground_y, "spawn_position": Values.vec(spawn_position),
		"definitions": definitions.duplicate(true), "objects": objects.duplicate(true),
	}


static func validate_level(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "level_id", "level_version", "layout_kind", "length_px", "ground_y", "spawn_position", "definitions", "objects"], [], errors):
		return Values.result(errors)
	Values.schema(value, "level.v1", errors)
	if Values.enum_value(value.get("level_id"), Game.LEVEL_VERSIONS.keys(), errors, "$.level_id"):
		if not Values.same_string(value.get("level_version"), Game.LEVEL_VERSIONS[value.level_id]):
			Values.error(errors, "$.level_version", "unsupported_version", "Level version does not match its registered ID.")
	Values.enum_value(value.get("layout_kind"), ["fixed"], errors, "$.layout_kind")
	if Values.number(value.get("length_px"), errors, "$.length_px", 0.0, Values.MAX_VECTOR_COMPONENT) and value.length_px == 0:
		Values.error(errors, "$.length_px", "range", "Fixed levels need positive length.")
	Values.number(value.get("ground_y"), errors, "$.ground_y", -Values.MAX_VECTOR_COMPONENT, Values.MAX_VECTOR_COMPONENT)
	Values.vector(value.get("spawn_position"), errors, "$.spawn_position")
	if not value.get("definitions") is Array or not value.get("objects") is Array:
		Values.error(errors, "$", "type", "Definitions and objects must be arrays.")
		return Values.result(errors)
	var definitions: Dictionary = {}
	for index in value.definitions.size():
		var definition: Variant = value.definitions[index]
		var validation := validate_object_definition(definition)
		Values.append_validation(errors, validation, "$.definitions[%d]" % index)
		if validation.valid:
			if definitions.has(definition.definition_id):
				Values.error(errors, "$.definitions[%d].definition_id" % index, "duplicate_id", "Definition IDs must be unique.")
			definitions[definition.definition_id] = definition
	var object_ids: Dictionary = {}
	for index in value.objects.size():
		var instance: Variant = value.objects[index]
		var validation := validate_object_instance(instance)
		Values.append_validation(errors, validation, "$.objects[%d]" % index)
		if not validation.valid:
			continue
		if object_ids.has(instance.object_id):
			Values.error(errors, "$.objects[%d].object_id" % index, "duplicate_id", "Object IDs must be unique within a level.")
		object_ids[instance.object_id] = true
		if not definitions.has(instance.definition_id):
			Values.error(errors, "$.objects[%d].definition_id" % index, "unknown_reference", "Object references an unknown or invalid definition.")
		elif definitions[instance.definition_id].object_type == "building" and instance.schedule.kind != "static":
			Values.error(errors, "$.objects[%d].schedule" % index, "building_schedule", "Ground buildings are fixed; only aerial opportunities may move.")
	return Values.result(errors)
