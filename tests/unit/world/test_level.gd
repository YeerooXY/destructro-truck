extends RefCounted
const World = preload("res://src/core/contracts/world_contracts.gd")


static func run() -> Array[String]:
	var failures: Array[String] = []
	var file := FileAccess.open("res://levels/test_yard.json", FileAccess.READ)
	if file == null:
		return ["Fixed test yard is missing."]
	var level: Variant = JSON.parse_string(file.get_as_text())
	var validation := World.validate_level(level)
	if not validation.valid:
		return ["Fixed test yard rejected: " + str(validation.errors)]
	var bad: Dictionary = level.duplicate(true)
	bad.objects[1].object_id = bad.objects[0].object_id
	if World.validate_level(bad).valid:
		failures.append("Duplicate world IDs accepted; destruction could become ambiguous.")
	bad = level.duplicate(true)
	bad.objects[0].definition_id = "missing_object"
	if World.validate_level(bad).valid:
		failures.append("Missing object definition was accepted.")
	bad = level.duplicate(true)
	bad.layout_kind = "procedural"
	if World.validate_level(bad).valid:
		failures.append("Runtime procedural layout was accepted.")
	var building_types: Dictionary = {}
	for definition in level.definitions:
		if definition.object_type == "building":
			building_types[definition.building_type_id] = true
	if building_types.size() != 2:
		failures.append("Test yard must exercise the two shared building types.")
	return failures
