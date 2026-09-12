extends Node2D
## The only world owner. It emits content inputs, never final score or money.
signal contact_detected(contact: Dictionary)
signal resource_requested(request: Dictionary, reason: String)
signal gameplay_event(event: Dictionary)

const Game = preload("res://src/core/contracts/game_contracts.gd")
const World = preload("res://src/core/contracts/world_contracts.gd")
const ObjectRuntime = preload("res://src/world/world_object.gd")
var data: Dictionary = {}
var definitions: Dictionary = {}
var objects: Dictionary = {}
var placements: Dictionary = {}
var run_time_s := 0.0
var run_id := "prototype"
var event_sequence := 0
var active := false:
	set(value):
		active = value
		for object in objects.values():
			object.set_active(value)


func load_level(path: String, id: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"valid": false, "errors": [{"message": "Cannot read fixed level."}]}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var validation: Dictionary = World.validate_level(parsed)
	if not validation.valid:
		return validation
	data = parsed.duplicate(true)
	run_id = id
	for definition in data.definitions:
		definitions[definition.definition_id] = definition
	_make_ground()
	for placement in data.objects:
		var object := ObjectRuntime.new()
		object.configure(placement.object_id, definitions[placement.definition_id])
		object.position = Vector2(placement.position[0], placement.position[1])
		objects[placement.object_id] = object
		placements[placement.object_id] = placement
		object.touched.connect(_interact)
		add_child(object)
	queue_redraw()
	return validation


func _make_ground() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.set_meta("object_id", "yard_ground")
	body.set_meta("contact_kind", "ground")
	body.position = Vector2(float(data.length_px) / 2.0, float(data.ground_y) + 200)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# Ground continues after the fixed content route; no artificial finish timer.
	shape.size = Vector2(float(data.length_px) + 200000.0, 400)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func advance(time_s: float) -> void:
	run_time_s = time_s
	for id in objects:
		var object = objects[id]
		if object.consumed:
			continue
		var placement: Dictionary = placements[id]
		var schedule: Dictionary = placement.schedule
		if schedule.kind == "sine":
			var axis := Vector2(schedule.axis[0], schedule.axis[1])
			object.position = Vector2(placement.position[0], placement.position[1]) + axis * float(schedule.amplitude_px) * sin(TAU * time_s / float(schedule.period_s) + float(schedule.phase_rad))


func _interact(id: String) -> void:
	if not active or not objects.has(id):
		return
	var object = objects[id]
	var definition: Dictionary = object.definition
	var building: bool = definition.object_type == "building"
	var kind := "building" if building else "aerial_target"
	contact_detected.emit(Game.contact(id, kind, object.position, Vector2.UP))
	var exchange: Dictionary = definition.exchange
	var request := Game.resource_request(id, exchange.speed_cost, Vector2(exchange.impulse[0], exchange.impulse[1]), exchange.nudge_refill, exchange.equipment_refill)
	resource_requested.emit(request, "building" if building else "target")
	event_sequence += 1
	var payload := {"definition_id": definition.definition_id, "destruction_value": exchange.destruction_value,
		"money_value": exchange.money_value, "combo_value": exchange.combo_value, "resource_request": request}
	gameplay_event.emit(Game.gameplay_event(run_id, event_sequence, "building_destroyed" if building else "target_collected", run_time_s, id, payload))
	if building:
		object.become_wreck()
	else:
		object.queue_redraw()


func _draw() -> void:
	if data.is_empty():
		return
	var ground_y: float = data.ground_y
	draw_rect(Rect2(-100000, ground_y, 220000, 1600), Color("284047"))
	draw_line(Vector2(-100000, ground_y), Vector2(120000, ground_y), Color("aac4b3"), 3)
	for x in range(-1000, int(data.length_px) + 4000, 200):
		draw_line(Vector2(x, ground_y + 4), Vector2(x - 30, ground_y + 34), Color("3c5860"), 2)
		if x % 1000 == 0:
			draw_line(Vector2(x, ground_y), Vector2(x, ground_y + 55), Color("6b8888"), 2)
	# Authored launch marking, not an extra physics object.
	draw_line(Vector2(100, ground_y - 2), Vector2(265, ground_y - 2), Color("d4ef76"), 6)
