extends SceneTree
## Excluded from exports. Captures actual rendered frames and a short input-driven run.
const Game = preload("res://src/core/contracts/game_contracts.gd")
var game
var sequence := 0


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	game = load("res://src/bootstrap/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await RenderingServer.frame_post_draw
	_save("menu.png")
	for frame in range(90):
		await physics_frame
	game.start_run("survival")
	for frame in range(180):
		if game.paused:
			game.set_paused(false)
		if game.truck.get_launch_feedback().accuracy > 0.97:
			break
		await physics_frame
	await RenderingServer.frame_post_draw
	_save("launch.png")
	_send("launch")
	for frame in range(900):
		if game.paused:
			game.set_paused(false)
		if game.displaying_results:
			break
		var snapshot: Dictionary = game.truck.get_snapshot()
		_send("rotate", {"axis": clampf(-wrapf(float(snapshot.rotation_rad), -PI, PI) * 1.7 - float(snapshot.angular_velocity_rad_s) * 0.3, -1, 1)})
		var lift := frame < 500 and float(snapshot.position[1]) > 420 and float(snapshot.velocity[0]) > 220
		_send("nudge", {"direction": [0.0, -1.0] if lift else [0.0, 0.0], "strength": 1.0 if lift else 0.0})
		await physics_frame
		if frame in [120, 300, 600]:
			await RenderingServer.frame_post_draw
			_save("gameplay_%d.png" % frame)
	await RenderingServer.frame_post_draw
	_save("latest.png")
	print("CAPTURE_RUN ", JSON.stringify({"state": game.session.snapshot().state, "elapsed_s": game.session.snapshot().elapsed_s, "events": game.event_counts, "rejected_events": game.rejected_events}))
	for frame in range(120):
		await physics_frame
	game.queue_free()
	await process_frame
	quit()


func _send(action: String, payload: Dictionary = {}) -> void:
	sequence += 1
	game._command(Game.command(action, sequence, game.session.snapshot().elapsed_s, payload))


func _save(filename: String) -> void:
	var picture := root.get_texture().get_image()
	picture.save_png("res://artifacts/" + filename)
	print("CAPTURE ", filename)
