extends SceneTree
## Run from an empty temporary project, so source-tree files cannot mask exclusions.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not ProjectSettings.load_resource_pack(args[0], true):
		printerr("PACKAGE_AUDIT failed: cannot load exported pack")
		quit(1)
		return
	var failed := false
	for path in ["res://src/bootstrap/main.tscn", "res://src/gameplay/truck.gd", "res://src/run/run_session.gd"]:
		if not ResourceLoader.exists(path):
			printerr("PACKAGE_AUDIT missing: ", path)
			failed = true
	if not FileAccess.file_exists("res://levels/test_yard.json"):
		printerr("PACKAGE_AUDIT fixed level missing")
		failed = true
	if not failed and not (load("res://src/bootstrap/main.tscn") is PackedScene):
		printerr("PACKAGE_AUDIT main scene dependencies cannot load")
		failed = true
	for folder in ["tests", "tools", "docs", "assembly", "backend", "artifacts", ".tools"]:
		if DirAccess.dir_exists_absolute("res://" + folder):
			printerr("PACKAGE_AUDIT development directory included: ", folder)
			failed = true
	print("PACKAGE_AUDIT ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
