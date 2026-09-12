extends Node2D
## Isolated physics laboratory: F6, Space launches, arrows rotate, WASD nudge, R resets.

const Truck = preload("res://src/gameplay/truck.gd")
const Game = preload("res://src/core/contracts/game_contracts.gd")

var truck: RigidBody2D
var _sequence := 0
var _run := 0


func _ready() -> void:
	add_surface("lab_floor", Vector2(12000.0, 595.0), Vector2(28000.0, 70.0), "ground")
	add_surface("lab_wreck", Vector2(1300.0, 549.0), Vector2(140.0, 24.0), "wreck", -0.13)
	truck = Truck.new()
	add_child(truck)
	truck.reset_run("lab_0")
	queue_redraw()


func add_surface(object_id: String, at: Vector2, size: Vector2, kind: String, angle: float = 0.0) -> void:
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
		ramp.points = PackedVector2Array([Vector2(-80.0, 11.0), Vector2(80.0, -20.0), Vector2(80.0, 11.0)])
		collider.shape = ramp
		body.rotation = 0.0
	else:
		var shape := RectangleShape2D.new()
		shape.size = size
		collider.shape = shape
	body.add_child(collider)
	add_child(body)


func _physics_process(_delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_R):
		_run += 1
		_sequence = 0
		truck.reset_run("lab_" + str(_run))
	if Input.is_physical_key_pressed(KEY_SPACE) and truck.get_launch_feedback().ready:
		_command("launch")
	_command("rotate", {"axis": float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))})
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	_command("nudge", {"direction": [direction.x, direction.y], "strength": 1.0 if direction != Vector2.ZERO else 0.0})


func _command(action: String, payload: Dictionary = {}) -> void:
	truck.accept_command(Game.command(action, _sequence, truck.get_snapshot().run_time_s, payload))
	_sequence += 1


func _draw() -> void:
	draw_rect(Rect2(-2000.0, 560.0, 28000.0, 90.0), Color("3a6674"))
	draw_line(Vector2(-2000.0, 560.0), Vector2(26000.0, 560.0), Color("83bdc4"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(1220.0, 560.0), Vector2(1380.0, 529.0), Vector2(1380.0, 560.0)]), Color("947f56"))
