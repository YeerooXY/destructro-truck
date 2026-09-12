extends SceneTree

var failures: Array[String] = []
var suites_run := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var suites: Array[String] = []
	_collect("res://tests/unit", suites)
	suites.sort()
	if suites.is_empty():
		failures.append("No unit test suites were discovered.")
	for path in suites:
		var script = load(path)
		if script == null or not script.can_instantiate():
			failures.append("Cannot load suite: " + path)
			continue
		var suite = script.new()
		if not suite.has_method("run"):
			failures.append("Suite has no run method: " + path)
			continue
		var result = suite.run()
		if not result is Array:
			failures.append("Invalid suite result: " + path)
			continue
		suites_run += 1
		for failure in result:
			failures.append(path + ": " + str(failure))
		print("SUITE ", path, ": ", "PASS" if result.is_empty() else "FAIL")
	for failure in failures:
		printerr("FAIL: ", failure)
	print("TEST_RESULT suites=", suites_run, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)


func _collect(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			result.append(path.path_join(file))
	for folder in dir.get_directories():
		_collect(path.path_join(folder), result)
