extends SceneTree
## Development-only measurement of legal-input yard runs under candidate physics tuning.
const Game = preload("res://src/core/contracts/game_contracts.gd")

var game
var command_sequence := 0
var last_interaction_s := 0.0
var yard_exit_s := -1.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://src/bootstrap/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var candidates := [[0.025, 0.012, "standard"], [0.18, 0.045, "none"], [0.18, 0.045, "standard"], [0.18, 0.045, "recovery"]]
	for candidate in candidates:
		game.start_run("survival")
		game.truck.configure({"friction": candidate[0], "linear_damping": candidate[1]})
		game.world.gameplay_event.connect(_event)
		last_interaction_s = 0.0
		yard_exit_s = -1.0
		await physics_frame
		for frame in range(180):
			if game.truck.get_launch_feedback().accuracy > 0.97:
				break
			await physics_frame
		_send("launch")
		for frame in range(30):
			await physics_frame
		game.set_paused(true)
		for frame in range(20):
			await physics_frame
		game.set_paused(false)
		for frame in range(7200):
			if game.displaying_results:
				break
			var snapshot: Dictionary = game.truck.get_snapshot()
			if yard_exit_s < 0.0 and snapshot.position[0] >= 12500.0:
				yard_exit_s = snapshot.run_time_s
			var axis := clampf(-wrapf(float(snapshot.rotation_rad), -PI, PI) * 1.7 - float(snapshot.angular_velocity_rad_s) * 0.3, -1, 1)
			_send("rotate", {"axis": 0.0 if candidate[2] == "none" else axis})
			var lift := frame < 500 and float(snapshot.position[1]) > 420.0 and float(snapshot.velocity[0]) > 220.0
			var direction := Vector2.UP if lift else Vector2.ZERO
			if candidate[2] == "none":
				direction = Vector2.ZERO
			if candidate[2] == "recovery":
				if snapshot.position[1] > 420.0:
					direction = Vector2(0.7, -0.7) if snapshot.velocity[0] < 350.0 else Vector2.UP
			_send("nudge", {"direction": [direction.x, direction.y], "strength": 1.0 if direction != Vector2.ZERO else 0.0})
			await physics_frame
		var result: Dictionary = game.session.snapshot()
		print("TUNING_PROBE ", JSON.stringify({"friction": candidate[0], "damping": candidate[1], "policy": candidate[2], "stop_s": result.elapsed_s, "last_interaction_s": last_interaction_s, "yard_exit_s": yard_exit_s, "distance_px": result.distance_px, "events": game.event_counts, "rejected_events": game.rejected_events}))
	game.queue_free()
	await process_frame
	quit()


func _send(action: String, payload: Dictionary = {}) -> void:
	command_sequence += 1
	game._command(Game.command(action, command_sequence, game.session.snapshot().elapsed_s, payload))


func _event(event: Dictionary) -> void:
	if event.event_type in ["building_destroyed", "target_collected", "pickup_collected"]:
		last_interaction_s = game.session.snapshot().elapsed_s
