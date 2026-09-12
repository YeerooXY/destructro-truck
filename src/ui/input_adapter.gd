extends Node
## All hardware input terminates here. Consumers receive device-neutral commands.
signal command_emitted(value: Dictionary)
signal device_changed(gamepad: bool)
signal pause_requested

const Game = preload("res://src/core/contracts/game_contracts.gd")
var enabled := false
var run_time_s := 0.0
var sequence := 0
var gamepad_active := false
var previous_rotation := 0.0
var nudging := false


func _ready() -> void:
	_bind("truck_launch", [KEY_SPACE], [JOY_BUTTON_A])
	_bind("truck_restart", [KEY_R], [JOY_BUTTON_Y])
	_bind("truck_pause", [KEY_ESCAPE], [JOY_BUTTON_START])
	_bind("truck_left", [KEY_A], [])
	_bind("truck_right", [KEY_D], [])
	_bind("nudge_left", [KEY_LEFT], [])
	_bind("nudge_right", [KEY_RIGHT], [])
	_bind("nudge_up", [KEY_UP], [])
	_bind("nudge_down", [KEY_DOWN], [])
	Input.joy_connection_changed.connect(_connection_changed)


func reset() -> void:
	sequence = 0
	run_time_s = 0.0
	previous_rotation = 0.0
	nudging = false


func refresh_axes() -> void:
	# Pausing clears physics controls; held input must be republished on resume.
	previous_rotation = 2.0
	nudging = true


func _bind(action: String, keys: Array, buttons: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.2)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	for button in buttons:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25):
		_set_device(true)
	elif event is InputEventKey or event is InputEventMouseButton:
		_set_device(false)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventKey and event.echo:
		return
	for mapping in [["truck_launch", "launch"], ["truck_restart", "restart"], ["truck_pause", "pause"]]:
		if event.is_action_pressed(mapping[0]):
			_emit(mapping[1])
			get_viewport().set_input_as_handled()
			return


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	var rotate_axis := Input.get_axis("truck_left", "truck_right")
	var nudge := Input.get_vector("nudge_left", "nudge_right", "nudge_up", "nudge_down")
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		var pad: int = pads[0]
		var left_x := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		if absf(left_x) > 0.2 and is_zero_approx(rotate_axis):
			rotate_axis = left_x
		var right_stick := Vector2(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y))
		if right_stick.length() > 0.22 and nudge.is_zero_approx():
			nudge = right_stick.limit_length()
	if not is_equal_approx(rotate_axis, previous_rotation):
		_emit("rotate", {"axis": rotate_axis})
		previous_rotation = rotate_axis
	if not nudge.is_zero_approx():
		_emit("nudge", {"direction": [nudge.normalized().x, nudge.normalized().y], "strength": minf(1.0, nudge.length())})
		nudging = true
	elif nudging:
		_emit("nudge", {"direction": [0.0, 0.0], "strength": 0.0})
		nudging = false


func _emit(action: String, payload: Dictionary = {}) -> void:
	sequence += 1
	command_emitted.emit(Game.command(action, sequence, run_time_s, payload))


func _set_device(value: bool) -> void:
	if value != gamepad_active:
		gamepad_active = value
		device_changed.emit(value)


func _connection_changed(_device: int, connected: bool) -> void:
	if not connected and enabled:
		pause_requested.emit()
	if not connected:
		_set_device(false)
