extends RefCounted

const Rules = preload("res://src/gameplay/physics_rules.gd")
const Truck = preload("res://src/gameplay/truck.gd")
const Game = preload("res://src/core/contracts/game_contracts.gd")


static func run() -> Array[String]:
	var failures: Array[String] = []
	var tuning := Rules.defaults()
	_check(not Rules.configured({"mass": 4.0}).is_empty(), "Valid mass tuning was rejected.", failures)
	for bad in [{"max_speed": INF}, {"friction": -1.0}, {"launch_min_speed": 1400.0, "launch_max_speed": 900.0}, {"unknown": 1.0}]:
		_check(Rules.configured(bad).is_empty(), "Unsafe tuning accepted: " + str(bad), failures)
	var original := Vector2(300.0, -400.0)
	var cost := Game.resource_request("house_a", 100.0, Vector2.ZERO, 0.0)
	var changed := Rules.apply_resource(original, 50.0, 0.0, cost, tuning)
	_check(changed.valid and is_equal_approx(changed.velocity.length(), 400.0), "Speed cost did not subtract fixed speed magnitude.", failures)
	_check(changed.velocity.normalized().is_equal_approx(original.normalized()), "Speed cost changed direction.", failures)
	var exhausted := Rules.apply_resource(original, 0.0, 0.0, Game.resource_request("house_b", 700.0, Vector2.ZERO, 0.0), tuning)
	_check(exhausted.velocity == Vector2.ZERO, "Excessive cost reversed or retained momentum.", failures)
	var impulse := Rules.apply_resource(Vector2(1500.0, -600.0), 99.0, 98.0, Game.resource_request("target_a", 0.0, Vector2(1200.0, -1200.0), 10.0, 10.0), tuning)
	_check(impulse.velocity.length() <= tuning.max_speed + 0.001 and impulse.velocity.y >= -tuning.max_up_speed, "Impulse escaped speed/height bounds.", failures)
	_check(impulse.energy == tuning.nudge_capacity and impulse.charge == tuning.equipment_capacity, "Refill escaped resource capacity.", failures)
	for bad in [Game.resource_request("bad_a", -1.0, Vector2.ZERO, 0.0), Game.resource_request("bad_b", 0.0, Vector2(INF, 0.0), 0.0), Game.resource_request("bad_c", 0.0, Vector2(3001.0, 0.0), 0.0), Game.resource_request("bad_d", 0.0, Vector2.ZERO, 101.0)]:
		_check(not Rules.apply_resource(original, 10.0, 0.0, bad, tuning).valid, "Malformed or excessive resource request accepted.", failures)
	var huge := Game.resource_request("huge", 0.0, Vector2.ZERO, 0.0)
	huge.impulse = [1.0e100, 0.0]
	_check(not Rules.validate_resource_limits(huge, tuning), "Finite wire overflow was accepted.", failures)
	var ground := Rules.bounce_velocity(Vector2(700.0, 300.0), Vector2.UP, "ground", tuning)
	var wreck := Rules.bounce_velocity(Vector2(700.0, 300.0), Vector2.UP, "wreck", tuning)
	_check(ground.y < 0.0 and wreck.y < ground.y, "Ground and wreck bounce tuning are not distinct.", failures)
	_check(ground.length() < Vector2(700.0, 300.0).length() and wreck.length() < Vector2(700.0, 300.0).length(), "Bounce created kinetic energy.", failures)
	_check(Rules.bounce_velocity(Vector2(20.0, 2.0), Vector2.UP, "ground", tuning) == Vector2(20.0, 2.0), "Tiny resting contact retriggered bounce.", failures)
	var spent := 0.0
	var pushed := Vector2.ZERO
	for index in 60:
		var step := Rules.nudge_step(Vector2(1.0, -1.0), 1.0, tuning.nudge_capacity - spent, 1.0 / 60.0, tuning)
		spent += step.energy_spent
		pushed += step.impulse
	_check(is_equal_approx(spent, tuning.nudge_energy_per_s), "Held nudge energy is not time based.", failures)
	_check(is_equal_approx(pushed.length(), tuning.nudge_acceleration), "Held diagonal nudge gained or lost force.", failures)
	var partial := Rules.nudge_step(Vector2.UP, 1.0, 0.1, 1.0 / 60.0, tuning)
	_check(is_equal_approx(partial.energy_spent, 0.1) and partial.impulse.length() < 2.0, "Last fraction of nudge energy overdraws or gives full impulse.", failures)
	_check(Rules.nudge_step(Vector2.UP, 1.0, 0.0, 0.016, tuning).impulse == Vector2.ZERO, "Depleted nudge produced impulse.", failures)
	var spin := 0.0
	for index in 36000:
		spin = Rules.rotation_step(spin, 1.0, 1.0 / 60.0, true, tuning)
	_check(spin == tuning.max_angular_speed, "Long rotation escaped cap.", failures)
	_check(Rules.rotation_step(0.0, 1.0, 0.1, false, tuning) == 0.0, "Grounded rotation applied aerial control.", failures)
	_check(not Rules.stop_dwell(Vector2.ZERO, 0.0, false, 0.0, 10.0, 0.016, tuning).lost, "Apex or temporary airborne stall ended the run.", failures)
	_check(not Rules.stop_dwell(Vector2.ZERO, 0.0, true, 100.0, 1.5, 0.016, tuning).lost, "Remaining recovery energy gave no reaction window.", failures)
	_check(Rules.stop_dwell(Vector2.ZERO, 0.0, true, 100.0, 4.0, 0.016, tuning).lost, "Unused recovery energy prevented eventual stop forever.", failures)
	var truck := Truck.new()
	truck.reset_run("unit_run")
	_check(truck is RigidBody2D and truck.get_child_count() == 1 and truck.get_child(0) is CollisionShape2D, "Truck requires more than one rectangular physics body.", failures)
	_check(Game.validate_truck_snapshot(truck.get_snapshot()).valid, "Initial truck snapshot violates contract.", failures)
	_check(truck.get_snapshot().is_read_only() and truck.get_snapshot().position.is_read_only(), "Snapshot allows nested mutation.", failures)
	_check(truck.accept_command(Game.command("launch", 0, 0.0)), "First launch was rejected.", failures)
	_check(not truck.accept_command(Game.command("launch", 1, 0.0)), "Duplicate launch was accepted.", failures)
	_check(truck.request_resources(cost) and not truck.request_resources(cost), "Resource source was not reserved once before physics tick.", failures)
	_check(truck.accept_command(Game.command("rotate", 2, 0.1, {"axis": 1.0})) and not truck.accept_command(Game.command("rotate", 2, 0.1, {"axis": -1.0})), "Duplicate command was not rejected.", failures)
	_check(not truck.accept_command(Game.command("rotate", 3, 0.05, {"axis": 0.0})), "Decreasing command time was accepted.", failures)
	for index in 100:
		truck.reset_run("restart_" + str(index))
		_check(truck.get_snapshot().momentum == 0.0 and truck.get_snapshot().nudge_energy == tuning.nudge_capacity and truck.get_launch_feedback().ready, "Reset left stale physics state.", failures)
		_check(truck.accept_command(Game.command("launch", 0, 0.0)) and truck.request_resources(cost), "Reset did not clear command/source deduplication.", failures)
	truck.free()
	return failures


static func _check(ok: bool, message: String, failures: Array[String]) -> void:
	if not ok:
		failures.append(message)
