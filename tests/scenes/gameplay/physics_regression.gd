extends SceneTree
## Real 60Hz Godot physics regression, run with --headless --script this file.

const Truck = preload("res://src/gameplay/truck.gd")
const Game = preload("res://src/core/contracts/game_contracts.gd")

var _failures: Array[String] = []
var _events: Array = []
var _snapshots := 0
var _truck: RigidBody2D
var _world: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_world = Node2D.new()
	root.add_child(_world)
	_surface("test_floor", Vector2(12000.0, 595.0), Vector2(30000.0, 70.0), "ground")
	_surface("test_wreck", Vector2(1200.0, 550.0), Vector2(160.0, 20.0), "wreck", -0.1)
	_truck = Truck.new()
	_world.add_child(_truck)
	_truck.gameplay_event.connect(_event)
	_truck.snapshot_published.connect(func(_snapshot: Dictionary): _snapshots += 1)
	_truck.reset_run("live_run")
	await _steps(23)
	_check(_truck.accept_command(Game.command("launch", 0, 0.0)), "Launch rejected in tree.")
	_truck.set_simulation_enabled(false)
	await _steps(5)
	_check(_count("launch") == 0 and _truck.get_snapshot().run_time_s == 0.0, "Pending launch event or clock leaked through pause.")
	_truck.set_simulation_enabled(true)
	await _steps(120)
	_check(_truck.get_snapshot().position[0] > 1000.0, "Truck did not travel through real physics.")
	_check(_count("landed") > 0, "Ground/wreck collision never published a landing.")
	_check(_count("contact") < 20, "Resting contacts spammed observations.")
	_check(_count("launch") == 1, "Launch event count was not exactly one.")
	_check(Game.validate_event_stream(_events, "live_run").valid, "Real physics emitted an invalid local event stream.")
	var frozen: Dictionary = _truck.get_snapshot()
	_truck.set_simulation_enabled(false)
	await _steps(20)
	_check(_truck.get_snapshot() == frozen, "Disabled simulation advanced state or time.")
	_truck.set_simulation_enabled(true)
	await _steps(2)
	_check(_truck.get_snapshot().run_time_s > frozen.run_time_s, "Resume did not advance active time.")
	_check(_truck.get_snapshot().momentum > frozen.momentum * 0.8, "Resume discarded stored body velocity.")
	var before_speed: float = _truck.get_snapshot().momentum
	var cost := Game.resource_request("cost_a", before_speed + 500.0, Vector2.ZERO, 0.0)
	_check(_truck.request_resources(cost) and not _truck.request_resources(cost), "Live source deduplication failed.")
	await _steps(3)
	_check(_truck.get_snapshot().momentum < 150.0, "Queued speed cost failed to stop forward travel.")
	_check(_truck.accept_command(Game.command("nudge", 1, _truck.get_snapshot().run_time_s, {"direction": [1.0, -1.0].map(func(v): return v / sqrt(2.0)), "strength": 1.0})), "Held nudge rejected.")
	await _steps(245)
	_check(_truck.get_snapshot().nudge_energy < 4.0, "Held nudge failed to consume energy over time.")
	_truck.accept_command(Game.command("nudge", 2, _truck.get_snapshot().run_time_s, {"direction": [0.0, 0.0], "strength": 0.0}))
	# Repeated resets exercise PhysicsServer synchronization and clear held controls.
	for index in 10:
		_truck.reset_run("live_restart_" + str(index))
		_events.clear()
		_snapshots = 0
		await _steps(2)
		_check(absf(_truck.position.x - 160.0) < 0.01 and absf(_truck.position.y - 520.0) < 0.01, "Reset transform drifted while frozen.")
		_check(_truck.accept_command(Game.command("launch", 0, 0.0)), "Launch after reset failed.")
		await _steps(5)
		_check(_truck.get_snapshot().position[0] > 170.0, "Physics server kept stale transform or launch after reset.")
		_check(Game.validate_event_stream(_events, "live_restart_" + str(index)).valid, "Restart reused event IDs or ordering.")
	# Continuous rotation through collisions and capped impulses must stay finite.
	_truck.reset_run("spin_stress")
	_events.clear()
	_truck.accept_command(Game.command("launch", 0, 0.0))
	_truck.accept_command(Game.command("rotate", 1, 0.0, {"axis": 1.0}))
	for index in 12:
		_truck.request_resources(Game.resource_request("stress_" + str(index), 0.0, Vector2(2200.0, -450.0), 0.0), "target")
		await _steps(90)
	_check(_truck.get_snapshot().nudge_energy == _truck.get_tuning().nudge_capacity, "Free aerial rotation spent nudge energy.")
	_check(Game.validate_event_stream(_events, "spin_stress").valid, "Rotating collision stream became invalid.")
	_truck.reset_run("instant_restart")
	_truck.accept_command(Game.command("launch", 0, 0.0))
	await _steps(4)
	_check(_truck.get_snapshot().position[0] > 160.0 and _truck.get_snapshot().position[0] < 230.0, "Same-frame restart/launch kept an old transform.")
	_check(absf(_truck.get_snapshot().rotation_rad) < 0.05 and absf(_truck.get_snapshot().angular_velocity_rad_s) < 0.05, "Same-frame restart/launch kept old rotation.")
	# Inverted landing and a long unattended run must eventually stop, once.
	_truck.reset_run("inverted")
	_events.clear()
	_snapshots = 0
	_truck.rotation = PI
	_truck.accept_command(Game.command("launch", 0, 0.0))
	await _steps(4200)
	_check(not _truck.is_viable(), "Long inverted run never reached eventual stop.")
	_check(_count("viability_lost") == 1, "Eventual stop did not publish exactly once.")
	_check(_count("contact") < 80 and _count("landed") < 35, "Long resting run emitted unbounded contact/bounce events.")
	_check(_snapshots < 900, "Snapshot frequency exceeded configured rate.")
	_check(Game.validate_event_stream(_events, "inverted").valid, "Inverted/stopping physics stream is invalid.")
	print("PHYSICS_REGRESSION events=", _events.size(), " snapshots=", _snapshots, " final=", JSON.stringify(_truck.get_snapshot()))
	for failure in _failures:
		printerr("FAIL: ", failure)
	print("PHYSICS_RESULT failures=", _failures.size())
	_world.queue_free()
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _steps(count: int) -> void:
	for index in count:
		await physics_frame
		var snapshot: Dictionary = _truck.get_snapshot()
		if not Game.validate_truck_snapshot(snapshot).valid:
			_check(false, "Live truck emitted invalid/NaN state.")
			return
		if snapshot.momentum > _truck.get_tuning().max_speed + 0.01 or absf(snapshot.angular_velocity_rad_s) > _truck.get_tuning().max_angular_speed + 0.01:
			_check(false, "Live truck escaped velocity bounds.")
			return


func _surface(object_id: String, at: Vector2, size: Vector2, kind: String, angle: float = 0.0) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.rotation = angle
	body.collision_layer = 1
	body.collision_mask = 2
	body.set_meta("object_id", object_id)
	body.set_meta("contact_kind", kind)
	var collider := CollisionShape2D.new()
	if kind == "wreck":
		var ramp := ConvexPolygonShape2D.new()
		ramp.points = PackedVector2Array([Vector2(-80.0, 10.0), Vector2(80.0, -20.0), Vector2(80.0, 10.0)])
		collider.shape = ramp
		body.rotation = 0.0
	else:
		var shape := RectangleShape2D.new()
		shape.size = size
		collider.shape = shape
	body.add_child(collider)
	_world.add_child(body)


func _event(event: Dictionary) -> void:
	_events.append(event)


func _count(event_type: String) -> int:
	var count := 0
	for event in _events:
		if event.event_type == event_type:
			count += 1
	return count


func _check(ok: bool, message: String) -> void:
	if not ok and message not in _failures:
		_failures.append(message)
