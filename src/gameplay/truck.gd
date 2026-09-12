extends RigidBody2D
## One rectangular physics body. Commands and contract dictionaries are the public boundary.

signal gameplay_event(event: Dictionary)
signal snapshot_published(snapshot: Dictionary)

const Game = preload("res://src/core/contracts/game_contracts.gd")
const Values = preload("res://src/core/domain/contract_values.gd")
const Rules = preload("res://src/gameplay/physics_rules.gd")
const FollowCamera = preload("res://src/gameplay/truck_camera.gd")

var _tuning: Dictionary = Rules.defaults()
var _run_id := "debug_run"
var _event_sequence := 0
var _command_sequence := -1
var _command_time := 0.0
var _run_time_s := 0.0
var _charge_time_s := 0.0
var _snapshot_clock := 0.0
var _launched := false
var _simulation_enabled := true
var _viable := true
var _grounded := false
var _energy := 100.0
var _equipment_charge := 0.0
var _rotation_axis := 0.0
var _nudge_direction := Vector2.ZERO
var _nudge_strength := 0.0
var _stop_dwell_s := 0.0
var _airborne_s := 0.0
var _bounce_cooldown := 0.0
var _last_integrated_velocity := Vector2.ZERO
var _launch_pending := Vector2.ZERO
var _resume_pending := false
var _paused_velocity := Vector2.ZERO
var _paused_spin := 0.0
var _reset_pending := true
var _reset_transform := Transform2D.IDENTITY
var _resource_queue: Array[Dictionary] = []
var _consumed_sources: Dictionary = {}
var _contact_history: Dictionary = {}
var _surface_contacts: Dictionary = {}
var _queued_events: Array[Dictionary] = []
var _nudge_event_spent := 0.0
var _nudge_event_impulse := Vector2.ZERO
var _nudge_event_clock := 0.0
var _snapshot: Dictionary = {}
var _collision: CollisionShape2D
var _camera: Camera2D


func _init() -> void:
	name = "Truck"
	collision_layer = 2
	collision_mask = 1
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 8
	custom_integrator = true
	can_sleep = false
	freeze = true
	_collision = CollisionShape2D.new()
	_collision.name = "BodyCollision"
	_collision.shape = RectangleShape2D.new()
	add_child(_collision)
	_apply_configuration()
	_update_snapshot()


func _ready() -> void:
	_camera = FollowCamera.new()
	_camera.name = "FollowCamera"
	add_child(_camera)
	queue_redraw()


func configure(overrides: Dictionary) -> bool:
	if _launched:
		return false
	var checked := Rules.configured(overrides)
	if checked.is_empty():
		return false
	_tuning = Values.read_only_copy(checked)
	_energy = _tuning.nudge_capacity
	_equipment_charge = minf(_equipment_charge, _tuning.equipment_capacity)
	_apply_configuration()
	_update_snapshot()
	queue_redraw()
	return true


func _apply_configuration() -> void:
	mass = _tuning.mass
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2(0.0, _tuning.center_of_mass_y)
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = _tuning.linear_damping
	angular_damp = _tuning.angular_damping
	var material := PhysicsMaterial.new()
	material.friction = _tuning.friction
	material.bounce = 0.0
	physics_material_override = material
	_collision.shape.size = Vector2(_tuning.body_width, _tuning.body_height)


func reset_run(run_id: String, spawn: Vector2 = Vector2(160.0, 520.0)) -> void:
	var errors: Array = []
	if not Values.identifier(run_id, errors, "run_id") or not spawn.is_finite() or absf(spawn.x) > 20000000.0 or absf(spawn.y) > 2000.0:
		return
	freeze = true
	if is_inside_tree():
		global_position = spawn
	else:
		position = spawn
	rotation = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_run_id = run_id
	_event_sequence = 0
	_command_sequence = -1
	_command_time = 0.0
	_run_time_s = 0.0
	_charge_time_s = 0.0
	_snapshot_clock = 0.0
	_launched = false
	_viable = true
	_grounded = false
	_energy = _tuning.nudge_capacity
	_equipment_charge = 0.0
	_rotation_axis = 0.0
	_nudge_direction = Vector2.ZERO
	_nudge_strength = 0.0
	_stop_dwell_s = 0.0
	_airborne_s = 0.0
	_bounce_cooldown = 0.0
	_last_integrated_velocity = Vector2.ZERO
	_launch_pending = Vector2.ZERO
	_resume_pending = false
	_paused_velocity = Vector2.ZERO
	_paused_spin = 0.0
	_reset_pending = true
	_reset_transform = global_transform if is_inside_tree() else transform
	_resource_queue.clear()
	_consumed_sources.clear()
	_contact_history.clear()
	_surface_contacts.clear()
	_queued_events.clear()
	_nudge_event_spent = 0.0
	_nudge_event_impulse = Vector2.ZERO
	_nudge_event_clock = 0.0
	_update_snapshot()
	if is_instance_valid(_camera):
		_camera.reset_follow()


func set_simulation_enabled(enabled: bool) -> void:
	if enabled == _simulation_enabled:
		return
	if not enabled and _launched and _viable:
		_paused_velocity = linear_velocity
		_paused_spin = angular_velocity
	if enabled and _launched and _viable:
		_resume_pending = true
	_simulation_enabled = enabled
	freeze = not enabled or not _launched or not _viable
	if not enabled:
		_rotation_axis = 0.0
		_nudge_strength = 0.0


func accept_command(command: Dictionary) -> bool:
	if not _simulation_enabled or not _viable or not Game.validate_command(command).valid:
		return false
	if command.sequence <= _command_sequence or command.run_time_s < _command_time:
		return false
	if command.action_id not in ["launch", "rotate", "nudge"]:
		return false
	if command.action_id == "launch" and _launched:
		return false
	_command_sequence = int(command.sequence)
	_command_time = float(command.run_time_s)
	match command.action_id:
		"launch":
			var feedback := Rules.launch_feedback(_charge_time_s, _tuning)
			# Capture the frozen start pose before the server can deliver an older state.
			_reset_transform = global_transform if is_inside_tree() else transform
			_launch_pending = Rules.launch_velocity(feedback.accuracy, _tuning)
			_launched = true
			freeze = false
			_emit("launch", "", {"accuracy": feedback.accuracy, "speed_px_s": _launch_pending.length(), "angle_rad": _tuning.launch_angle_rad})
		"rotate":
			_rotation_axis = float(command.payload.axis)
		"nudge":
			_nudge_direction = Values.to_vector(command.payload.direction)
			_nudge_strength = float(command.payload.strength)
	return true


func accept_contact(contact: Dictionary) -> bool:
	if not _launched or not _viable or not _simulation_enabled or not Game.validate_contact(contact).valid:
		return false
	var key := str(contact.kind) + ":" + str(contact.object_id)
	var once: bool = contact.kind in ["building", "aerial_target", "pickup"]
	if _contact_history.has(key) and (once or _run_time_s - float(_contact_history[key]) < 0.2):
		return false
	_contact_history[key] = _run_time_s
	_emit("contact", contact.object_id, {"contact": contact})
	return true


func request_resources(request: Dictionary, reason: String = "building") -> bool:
	if not _launched or not _viable or not _simulation_enabled or reason not in ["building", "target", "pickup", "equipment"]:
		return false
	if not Rules.validate_resource_limits(request, _tuning) or _consumed_sources.has(request.source_object_id):
		return false
	# Accepted requests reserve the source immediately, even before the next physics step.
	_consumed_sources[request.source_object_id] = true
	_resource_queue.append({"request": request.duplicate(true), "reason": reason})
	return true


func get_snapshot() -> Dictionary:
	return _snapshot


func get_launch_feedback() -> Dictionary:
	var feedback := Rules.launch_feedback(_charge_time_s, _tuning)
	feedback["ready"] = not _launched and _simulation_enabled
	return Values.read_only_copy(feedback)


func get_launch_meter() -> float:
	return float(get_launch_feedback().phase)


func is_viable() -> bool:
	return _viable


func get_tuning() -> Dictionary:
	return Values.read_only_copy(_tuning)


func _physics_process(delta: float) -> void:
	# Never emit from an engine contact callback: world consumers may replace colliders.
	if not _simulation_enabled:
		return
	_flush_events()
	# A consumer may pause/end the run while receiving one of the queued events.
	if not _simulation_enabled:
		return
	if not _launched:
		_charge_time_s += delta
		return
	if not _viable:
		freeze = true
		return
	_run_time_s += delta
	_snapshot_clock += delta
	if _snapshot_clock >= 1.0 / _tuning.snapshot_hz:
		_snapshot_clock = fmod(_snapshot_clock, 1.0 / _tuning.snapshot_hz)
		_update_snapshot()
		snapshot_published.emit(_snapshot)
	queue_redraw()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not _simulation_enabled or not _launched or not _viable:
		return
	var delta := minf(state.step, 0.1)
	var velocity := state.linear_velocity
	var reset_this_step := _reset_pending
	if _reset_pending:
		state.transform = _reset_transform
		state.angular_velocity = 0.0
		velocity = Vector2.ZERO
		_reset_pending = false
	if _resume_pending:
		velocity = _paused_velocity
		state.angular_velocity = _paused_spin
		_last_integrated_velocity = velocity
		_resume_pending = false
	if _launch_pending != Vector2.ZERO:
		velocity = _launch_pending
		_launch_pending = Vector2.ZERO
		_last_integrated_velocity = velocity
	_bounce_cooldown = maxf(0.0, _bounce_cooldown - delta)
	# Existing manifold contacts describe the old pose until the next server step.
	var contact_result: Dictionary = {"velocity": velocity, "grounded": false} if reset_this_step else _read_surface_contacts(state, velocity)
	velocity = contact_result.velocity
	_grounded = contact_result.grounded
	_airborne_s = 0.0 if _grounded else _airborne_s + delta
	for queued in _resource_queue:
		var before := velocity.length()
		var changed := Rules.apply_resource(velocity, _energy, _equipment_charge, queued.request, _tuning)
		velocity = changed.velocity
		_energy = changed.energy
		_equipment_charge = changed.charge
		_emit("momentum_changed", queued.request.source_object_id, {"before_px_s": before, "after_px_s": velocity.length(), "reason": queued.reason})
	_resource_queue.clear()
	var nudge := Rules.nudge_step(_nudge_direction, _nudge_strength, _energy, delta, _tuning)
	if nudge.energy_spent > 0.0:
		_energy = maxf(0.0, _energy - float(nudge.energy_spent))
		velocity += nudge.impulse
		_nudge_event_spent += float(nudge.energy_spent)
		_nudge_event_impulse += nudge.impulse
	_nudge_event_clock += delta
	if _nudge_event_spent > 0.0 and (_nudge_event_clock >= 0.1 or nudge.energy_spent == 0.0):
		_publish_nudge_use()
	velocity *= exp(-float(_tuning.linear_damping) * delta)
	velocity.y += float(_tuning.gravity) * delta
	velocity = Rules.bounded_velocity(velocity, _tuning)
	var spin := state.angular_velocity * exp(-float(_tuning.angular_damping) * delta)
	spin = Rules.rotation_step(spin, _rotation_axis, delta, not _grounded, _tuning)
	if not is_finite(spin):
		spin = 0.0
	var stop := Rules.stop_dwell(velocity, spin, _grounded, _energy, _stop_dwell_s, delta, _tuning)
	_stop_dwell_s = stop.dwell_s
	if stop.lost:
		_lose_viability()
		velocity = Vector2.ZERO
		spin = 0.0
	var body_transform := state.transform
	if not body_transform.origin.is_finite() or absf(body_transform.origin.x) > 20000000.0 or body_transform.origin.y > 1800.0 or body_transform.origin.y < -2000.0:
		_lose_viability()
		body_transform.origin = Vector2(clampf(body_transform.origin.x, -1000.0, 20000000.0), 520.0) if body_transform.origin.is_finite() else Vector2(160.0, 520.0)
		body_transform = Transform2D(0.0, body_transform.origin)
		velocity = Vector2.ZERO
		spin = 0.0
	state.transform = body_transform
	state.linear_velocity = velocity
	state.angular_velocity = spin
	_last_integrated_velocity = velocity
	_update_snapshot(state.transform.origin, velocity, state.transform.get_rotation(), spin)


func _read_surface_contacts(state: PhysicsDirectBodyState2D, velocity: Vector2) -> Dictionary:
	var supporting := false
	var bounced := false
	var next_contacts: Dictionary = {}
	for index in state.get_contact_count():
		var normal := state.get_contact_local_normal(index).normalized()
		if not normal.is_finite() or normal.length_squared() < 0.5:
			continue
		var body := state.get_contact_collider_object(index)
		var kind := "unknown"
		var object_id := "unknown"
		if is_instance_valid(body):
			kind = str(body.get_meta("contact_kind", "unknown"))
			object_id = str(body.get_meta("object_id", "unknown"))
		if kind not in Game.CONTACT_KINDS:
			kind = "unknown"
		var contact := Game.contact(object_id, kind, state.get_contact_collider_position(index), normal)
		if not Game.validate_contact(contact).valid:
			continue
		var key := object_id + ":" + kind
		next_contacts[key] = true
		if not _surface_contacts.has(key):
			accept_contact(contact)
		if kind not in ["ground", "wreck"] or normal.y > -0.45:
			continue
		supporting = true
		var impact := maxf(0.0, -_last_integrated_velocity.dot(normal))
		if not bounced and not _surface_contacts.has(key) and _airborne_s > 0.05 and _bounce_cooldown <= 0.0 and impact >= _tuning.bounce_min_impact:
			var clean: bool = absf(wrapf(state.transform.get_rotation(), -PI, PI)) <= _tuning.clean_landing_angle
			velocity = Rules.bounce_velocity(_last_integrated_velocity, normal, kind, _tuning)
			_bounce_cooldown = _tuning.bounce_cooldown_s
			bounced = true
			if clean:
				_energy = minf(_tuning.nudge_capacity, _energy + _tuning.clean_landing_refill)
			_emit("landed", object_id, {"contact": contact, "impact_speed_px_s": impact, "clean": clean})
	_surface_contacts = next_contacts
	return {"velocity": velocity, "grounded": supporting and not bounced and velocity.y > -35.0}


func _lose_viability() -> void:
	if not _viable:
		return
	_publish_nudge_use()
	_viable = false
	_emit("viability_lost")


func _publish_nudge_use() -> void:
	if _nudge_event_spent <= 0.0:
		return
	_emit("nudge_used", "", {"energy_spent": _nudge_event_spent, "impulse": Values.vec(_nudge_event_impulse)})
	_nudge_event_spent = 0.0
	_nudge_event_impulse = Vector2.ZERO
	_nudge_event_clock = 0.0


func _emit(event_type: String, source: String = "", payload: Dictionary = {}) -> void:
	var event := Game.gameplay_event(_run_id, _event_sequence, event_type, _run_time_s, source, payload)
	_event_sequence += 1
	_queued_events.append(Values.read_only_copy(event))


func _flush_events() -> void:
	while _simulation_enabled and not _queued_events.is_empty():
		var event: Dictionary = _queued_events.pop_front()
		gameplay_event.emit(event)


func _update_snapshot(at_position: Vector2 = position, velocity: Vector2 = linear_velocity, angle: float = rotation, spin: float = angular_velocity) -> void:
	_snapshot = Values.read_only_copy(Game.truck_snapshot(_run_time_s, at_position, velocity, wrapf(angle, -PI, PI), spin, _grounded, _energy, _equipment_charge, _viable))


func _draw() -> void:
	var size := Vector2(_tuning.body_width, _tuning.body_height)
	# Original code-drawn debug silhouette. Only BodyCollision participates in physics.
	draw_rect(Rect2(-size * 0.5, size), Color("e6a640"))
	draw_rect(Rect2(-size * 0.5, size), Color("273842"), false, 3.0)
	draw_rect(Rect2(Vector2(7.0, -size.y * 0.5 + 4.0), Vector2(24.0, 11.0)), Color("86d4e0"))
	draw_line(Vector2(0.0, -size.y * 0.5), Vector2(0.0, size.y * 0.5), Color("8e642c"), 2.0)
	for wheel_x in [-size.x * 0.3, size.x * 0.3]:
		var center := Vector2(wheel_x, size.y * 0.5 - 2.0)
		draw_circle(center, 10.0, Color("182b35"))
		draw_circle(center, 4.0, Color("a6c1c7"))
	draw_rect(Rect2(Vector2(-size.x * 0.5 - 7.0, -8.0), Vector2(7.0, 16.0)), Color("527c89"))
	if _nudge_strength > 0.0 and _energy > 0.0 and _launched:
		var direction := _nudge_direction.rotated(-rotation)
		draw_line(-direction * 27.0, -direction * (38.0 + sin(_run_time_s * 38.0) * 5.0), Color("7cece0"), 6.0)
