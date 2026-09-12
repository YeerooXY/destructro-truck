extends SceneTree
## Development-only authoring tool. Shipped runs read the resulting fixed JSON.
const World = preload("res://src/core/contracts/world_contracts.gd")


func _initialize() -> void:
	var shed_wreck := [[-45, 45], [10, 22], [45, 45]]
	var warehouse_wreck := [[-64, 58], [0, 24], [64, 58]]
	var definitions := [
		World.object_definition("shed", "building", Vector2(90, 90), World.resource_exchange(65, Vector2.ZERO, 0, 0, 100, 10, 1), shed_wreck, "debug_shed", "light"),
		World.object_definition("warehouse", "building", Vector2(128, 116), World.resource_exchange(110, Vector2.ZERO, 0, 0, 220, 22, 1), warehouse_wreck, "debug_warehouse", "heavy"),
		World.object_definition("propane_shed", "building", Vector2(90, 90), World.resource_exchange(50, Vector2(230, -370), 16, 0, 150, 15, 1), shed_wreck, "debug_propane", "light"),
		World.object_definition("balloon", "balloon", Vector2(70, 70), World.resource_exchange(0, Vector2(135, -100), 20, 0, 65, 0, 1), [], "debug_balloon"),
	]
	var objects: Array = []
	var buildings := [[680, "shed"], [1350, "propane_shed"], [2080, "warehouse"], [2760, "shed"], [3440, "propane_shed"], [4380, "warehouse"], [5110, "shed"], [5770, "propane_shed"], [6720, "warehouse"], [7420, "shed"], [8120, "propane_shed"], [9040, "warehouse"], [9720, "shed"], [10350, "propane_shed"], [11350, "warehouse"]]
	for index in buildings.size():
		var definition_id: String = buildings[index][1]
		var half_height := 58 if definition_id == "warehouse" else 45
		objects.append(World.object_instance("building_%02d" % index, definition_id, Vector2(buildings[index][0], 560 - half_height)))
	var balloons := [[955, 430], [1155, 360], [1640, 330], [1880, 280], [2330, 435], [3060, 425], [3740, 310], [4040, 270], [4650, 430], [5400, 420], [6070, 325], [6400, 275], [7050, 425], [7770, 410], [8440, 320], [8740, 270], [9370, 425], [10020, 420], [10680, 320], [11040, 285], [11700, 440]]
	for index in balloons.size():
		objects.append(World.object_instance("balloon_%02d" % index, "balloon", Vector2(balloons[index][0], balloons[index][1])))
	var level := World.level("debug_yard", 12500, 560, Vector2(160, 520), definitions, objects)
	var validation := World.validate_level(level)
	if not validation.valid:
		printerr(validation)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://levels")
	var file := FileAccess.open("res://levels/test_yard.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(level, "\t") + "\n")
	print("Authored fixed test yard: ", objects.size(), " objects.")
	quit()
