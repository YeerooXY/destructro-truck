extends SceneTree
## Synthetic lifecycle attacks through integrated seams; no physical gamepad claim.
const Game = preload("res://src/core/contracts/game_contracts.gd")
var game
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	game = load("res://src/bootstrap/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run("survival")
	await physics_frame
	# Both legal commands arrive before the queued launch is published.
	game._command(Game.command("launch", 1, 0.0))
	game.set_paused(true)
	for frame in range(3):
		await physics_frame
	game.set_paused(false)
	for frame in range(5):
		await physics_frame
	var race_state: Dictionary = game.session.snapshot()
	print("ATTACK_LAUNCH_PAUSE ", JSON.stringify({"state": race_state.state, "elapsed_s": race_state.elapsed_s, "launch_ready": game.truck.get_launch_feedback().ready, "events": game.event_counts}))
	_check(race_state.state == "running", "Launch followed by immediate pause loses its queued authoritative event.")

	game.start_run("survival")
	game._command(Game.command("launch", 1, 0.0))
	for frame in range(4):
		await physics_frame
	game.set_paused(true)
	# Exercise the actual callback invoked by joy_connection_changed.
	game.input_adapter._connection_changed(0, false)
	print("ATTACK_DISCONNECT_PAUSED ", JSON.stringify({"paused": game.paused, "state": game.session.snapshot().state, "screen": game.view.screen}))
	_check(game.paused, "Disconnect while paused resumes the game.")

	game.start_run("survival")
	var old_run_id: String = game.run_id
	var object_id: String = game.world.data.objects[0].object_id
	var definition: Dictionary = game.world.objects[object_id].definition
	var exchange: Dictionary = definition.exchange
	var request := Game.resource_request(object_id, exchange.speed_cost, Vector2(exchange.impulse[0], exchange.impulse[1]), exchange.nudge_refill, exchange.equipment_refill)
	var payload := {"definition_id": definition.definition_id, "destruction_value": exchange.destruction_value, "money_value": exchange.money_value, "combo_value": exchange.combo_value, "resource_request": request}
	var stale := Game.gameplay_event(old_run_id, 20, "building_destroyed", 0.0, object_id, payload)
	game.start_run("survival")
	game._command(Game.command("launch", 1, 0.0))
	for frame in range(3):
		await physics_frame
	var before_score: int = game.session.snapshot().score_total
	game._event(stale)
	var after_score: int = game.session.snapshot().score_total
	print("ATTACK_STALE_EVENT ", JSON.stringify({"source_run_id": old_run_id, "current_run_id": game.run_id, "before_score": before_score, "after_score": after_score, "destroyed_count": game.session.snapshot().destroyed_count}))
	_check(before_score == after_score, "Bootstrap rewrites a previous run event into the current run and awards it.")
	var duplicate_score: int = game.session.snapshot().score_total
	game._event(stale)
	_check(game.session.snapshot().score_total == duplicate_score, "Repeated world source awards score twice.")

	game.start_run("survival")
	game._command(Game.command("launch", 1, 0.0))
	for frame in range(3):
		await physics_frame
	var paused_object = game.world.objects[game.world.data.objects[0].object_id]
	game.set_paused(true)
	# A callback already queued by physics must not consume an inactive target.
	paused_object._on_body_entered(game.truck)
	print("ATTACK_PAUSED_WORLD ", JSON.stringify({"consumed": paused_object.consumed, "destroyed_count": game.session.snapshot().destroyed_count}))
	_check(not paused_object.consumed, "World target consumes a deferred contact while paused.")
	game.set_paused(false)
	# Repeated starts intentionally happen before detached overlays are freed.
	for attempt in range(4):
		game.start_run("survival")
	_check(game.view.screen == "gameplay", "Rapid same-frame restarts leave the wrong screen.")
	print("ATTACK_RAPID_RESTART screen=", game.view.screen)

	game.queue_free()
	await process_frame
	for failure in failures:
		printerr("RED_TEAM_FAIL: ", failure)
	print("RED_TEAM_PROTOTYPE failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
