extends Node

const Game = preload("res://src/core/contracts/game_contracts.gd")
const Presentation = preload("res://src/core/contracts/presentation_contracts.gd")
const Values = preload("res://src/core/domain/contract_values.gd")
const Truck = preload("res://src/gameplay/truck.gd")
const Level = preload("res://src/world/level_runtime.gd")
const Session = preload("res://src/run/run_session.gd")
const View = preload("res://src/ui/presentation.gd")
const InputAdapter = preload("res://src/ui/input_adapter.gd")

var truck
var world
var session
var view
var input_adapter
var event_sequence := -1
var run_serial := 0
var run_id := "preview"
var mode_id := "survival"
var playing := false
var paused := false
var displaying_results := false
var rejected_events := 0
var event_counts: Dictionary = {}
var last_error := ""


func _ready() -> void:
	input_adapter = InputAdapter.new()
	add_child(input_adapter)
	input_adapter.command_emitted.connect(_command)
	input_adapter.pause_requested.connect(func(): set_paused(true))
	view = View.new()
	add_child(view)
	view.intent.connect(_intent)
	input_adapter.device_changed.connect(func(is_pad: bool): view.gamepad = is_pad)
	if not _build_run("survival"):
		return
	_show_menu()


func _build_run(selected_mode: String) -> bool:
	playing = false
	input_adapter.enabled = false
	for previous in [truck, world]:
		if is_instance_valid(previous):
			if previous.get_parent() == self:
				remove_child(previous)
			previous.queue_free()
	truck = null
	world = null
	run_serial += 1
	run_id = "yard_run_%d" % run_serial
	mode_id = selected_mode
	event_sequence = -1
	rejected_events = 0
	event_counts.clear()
	paused = false
	displaying_results = false
	session = Session.new()
	if not session.prepare(run_id, Game.ruleset(mode_id)):
		return _fail("Run configuration was rejected.")
	world = Level.new()
	add_child(world)
	var validation: Dictionary = world.load_level("res://levels/test_yard.json", run_id)
	if not validation.valid:
		return _fail("The test yard failed validation: " + str(validation.errors))
	truck = Truck.new()
	add_child(truck)
	truck.reset_run(run_id, Vector2(world.data.spawn_position[0], world.data.spawn_position[1]))
	truck.set_simulation_enabled(false)
	session.update_truck_snapshot(truck.get_snapshot())
	world.contact_detected.connect(func(contact: Dictionary): truck.accept_contact(contact))
	world.resource_requested.connect(func(request: Dictionary, reason: String): truck.request_resources(request, reason))
	world.gameplay_event.connect(_event)
	truck.gameplay_event.connect(_event)
	truck.snapshot_published.connect(_truck_snapshot)
	input_adapter.reset()
	return true


func start_run(selected_mode: String) -> void:
	if selected_mode not in Game.MODE_IDS:
		return
	if not _build_run(selected_mode):
		return
	playing = true
	world.active = true
	truck.set_simulation_enabled(true)
	input_adapter.enabled = true
	view.show_gameplay()


func _show_menu() -> void:
	playing = false
	paused = false
	input_adapter.enabled = false
	if is_instance_valid(truck):
		truck.set_simulation_enabled(false)
	if is_instance_valid(world):
		world.active = false
	view.show_menu()


func _intent(action: String, value: Variant) -> void:
	match action:
		"start": start_run(str(value))
		"restart": start_run(mode_id)
		"menu": _show_menu()
		"controls": view.show_controls()
		"pause": set_paused(true)
		"resume": set_paused(false)
		"exit": get_tree().quit()


func _command(command: Dictionary) -> void:
	if not Game.validate_command(command).valid:
		return
	match command.action_id:
		"pause":
			set_paused(not paused)
		"restart":
			start_run(mode_id)
		_:
			if playing and not paused and not displaying_results:
				truck.accept_command(command)


func set_paused(value: bool) -> void:
	if not playing or displaying_results or paused == value:
		return
	if not session.set_paused(value):
		return
	paused = value
	world.active = not value
	truck.set_simulation_enabled(not value)
	if value:
		view.show_pause()
	else:
		input_adapter.refresh_axes()
		view.show_gameplay()


func _event(source: Dictionary) -> void:
	if not playing or paused or displaying_results:
		return
	if source.get("run_id") != run_id:
		return
	if not Game.validate_gameplay_event(source).valid:
		rejected_events += 1
		return
	# Both producers enter one ordered event stream. Neither owns the score.
	var timestamp: float = session.snapshot().elapsed_s
	var event := Game.gameplay_event(run_id, event_sequence + 1, source.event_type, timestamp, source.source_object_id, source.payload)
	if not session.consume_event(event):
		rejected_events += 1
		printerr("Rejected integrated event: ", event)
		return
	event_sequence += 1
	event_counts[event.event_type] = int(event_counts.get(event.event_type, 0)) + 1
	match event.event_type:
		"launch": view.feedback("GREAT LAUNCH" if float(event.payload.accuracy) > 0.85 else "HERE WE GO")
		"building_destroyed": view.feedback("BUILDING DOWN — SPEED SPENT")
		"target_collected": view.feedback("MOMENTUM RESTORED")
		"landed":
			if event.payload.clean:
				view.feedback("CLEAN LANDING")


func _truck_snapshot(snapshot: Dictionary) -> void:
	if not playing or paused or displaying_results:
		return
	# Timestamp the observation in the same clock used for normalized events.
	# The producer's local clock starts inside its own fixed-tick callback.
	var observed := snapshot.duplicate(true)
	observed.run_time_s = session.snapshot().elapsed_s
	session.update_truck_snapshot(Values.read_only_copy(observed))


func _physics_process(delta: float) -> void:
	if not playing or paused or displaying_results:
		return
	session.advance(delta)
	var run: Dictionary = session.snapshot()
	input_adapter.run_time_s = run.elapsed_s
	world.advance(run.elapsed_s)
	if run.state == "ended":
		displaying_results = true
		world.active = false
		truck.set_simulation_enabled(false)
		view.show_results(session.result())


func _process(_delta: float) -> void:
	if not playing or not is_instance_valid(truck):
		return
	var tuning: Dictionary = truck.get_tuning()
	var model := Presentation.hud_state({"run": session.snapshot(), "truck": truck.get_snapshot(),
		"launch": truck.get_launch_feedback(), "resources": {"nudge_capacity": tuning.nudge_capacity, "equipment_capacity": tuning.equipment_capacity},
		"radar": {"tier": 0, "detections": []}})
	view.render_hud(model)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing:
		set_paused(true)


func _fail(message: String) -> bool:
	last_error = message
	push_error(message)
	playing = false
	view.show_error(message)
	return false
