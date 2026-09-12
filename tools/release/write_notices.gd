extends SceneTree


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/windows")
	var file := FileAccess.open("res://builds/windows/THIRD-PARTY-NOTICES.txt", FileAccess.WRITE)
	file.store_line("Destructro Truck first playable\nOriginal project code and placeholder drawings are in the project repository.\n")
	file.store_line("Godot Engine\n" + Engine.get_license_text())
	file.store_line("\nBundled component copyright information:\n" + JSON.stringify(Engine.get_copyright_info(), "  "))
	file.store_line("\nBundled third-party licenses:\n" + JSON.stringify(Engine.get_license_info(), "  "))
	print("Exported engine and bundled dependency notices.")
	quit()
