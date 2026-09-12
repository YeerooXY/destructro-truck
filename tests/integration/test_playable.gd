extends SceneTree
## Drives real scenes through their command boundary. No score/velocity injection.
const Game = preload("res://src/core/contracts/game_contracts.gd")
var failures: Array[String] = []
var game
var command_sequence := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://src/bootstrap/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_check(game.view.screen == "menu", "Startup menu missing.")
	game.start_run("survival")
	await physics_frame
	_check(game.world.objects.size() == 36, "Fixed yard did not load exactly once.")
	for frame in range(180):
		if game.truck.get_launch_feedback().accuracy > 0.97:
			break
		await physics_frame
	_send("launch")
	for frame in range(30):
		await physics_frame
	game.set_paused(true)
	var before: Dictionary = game.truck.get_snapshot()
	var before_time: float = game.session.snapshot().elapsed_s
	for frame in range(20):
		await physics_frame
	_check(game.truck.get_snapshot().position == before.position, "Truck moved while paused.")
	_check(game.session.snapshot().elapsed_s == before_time, "Run timer advanced while paused.")
	game.set_paused(false)
	for frame in range(7200):
		if game.displaying_results:
			break
		var snapshot: Dictionary = game.truck.get_snapshot()
		var axis := clampf(-wrapf(float(snapshot.rotation_rad), -PI, PI) * 1.7 - float(snapshot.angular_velocity_rad_s) * 0.3, -1, 1)
		_send("rotate", {"axis": axis})
		# A simple legal steering policy to exercise aerial recovery, then exhausts.
		var lift := frame < 500 and float(snapshot.position[1]) > 420 and float(snapshot.velocity[0]) > 220
		_send("nudge", {"direction": [0.0, -1.0] if lift else [0.0, 0.0], "strength": 1.0 if lift else 0.0})
		await physics_frame
	_check(game.rejected_events == 0, "Integrated event stream contains rejected events.")
	_check(game.displaying_results, "Survival did not eventually stop in the exhausted test yard.")
	_check(int(game.event_counts.get("building_destroyed", 0)) > 0, "No real building collision/destruction observed.")
	_check(int(game.event_counts.get("target_collected", 0)) > 0, "No aerial recovery observed with legal inputs.")
	_check(int(game.event_counts.get("viability_lost", 0)) == 1, "Eventual stop must be emitted once.")
	var recorded_distance: float = game.session.snapshot().distance_px
	var physical_distance: float = game.truck.get_snapshot().position[0] - 160.0
	_check(recorded_distance > 500.0 and absf(recorded_distance - physical_distance) < 200.0, "Distance observation clock did not track the truck.")
	_check(game.session.snapshot().score_breakdown.distance > 0, "Distance earned no score.")
	print("PLAYABLE_RUN ", JSON.stringify({"run": game.session.snapshot(), "events": game.event_counts, "physics": game.truck.get_snapshot()}))
	for index in range(8):
		game.start_run("timed_efficiency" if index % 2 else "survival")
		await physics_frame
		await process_frame
		_check(game.session.snapshot().score_total == 0, "Restart retained score.")
		_check(game.world.objects.size() == 36, "Restart retained duplicate world objects.")
		_check(game.event_counts.is_empty(), "Restart retained event state.")
		_check(game.truck.get_snapshot().nudge_energy == 100.0, "Restart retained depleted nudge energy.")
		_check(game.view.screen == "gameplay", "Restart retained overlay.")
	# Real event routing, independently of the steering helper above.
	game.start_run("survival")
	await physics_frame
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	for frame in range(5):
		await physics_frame
	_check(game.session.snapshot().state == "running", "Keyboard Space did not route to launch.")
	key.pressed = false
	Input.parse_input_event(key)
	game.start_run("survival")
	await physics_frame
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.device = 0
	button.pressed = true
	Input.parse_input_event(button)
	for frame in range(5):
		await physics_frame
	_check(game.session.snapshot().state == "running", "Gamepad A event did not route to launch.")
	button.pressed = false
	Input.parse_input_event(button)
	game.queue_free()
	await process_frame
	for failure in failures:
		printerr("FAIL: ", failure)
	print("PLAYABLE_TEST failures=", failures.size())
	quit(0 if failures.is_empty() else 1)


func _send(action: String, payload: Dictionary = {}) -> void:
	command_sequence += 1
	game._command(Game.command(action, command_sequence, game.session.snapshot().elapsed_s, payload))


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
