extends Area2D
## One fixed-layout object. Collision callbacks can consume it only once.
signal touched(object_id: String)

var object_id := ""
var definition: Dictionary = {}
var consumed := false
var active := false
var wreck_points := PackedVector2Array()


func configure(id: String, data: Dictionary) -> void:
	object_id = id
	definition = data.duplicate(true)
	collision_layer = 0
	collision_mask = 2
	monitoring = false
	var collision := CollisionShape2D.new()
	var dimensions := Vector2(data["size"][0], data["size"][1])
	if data.object_type == "building":
		var shape := RectangleShape2D.new()
		shape.size = dimensions
		collision.shape = shape
	else:
		var shape := CircleShape2D.new()
		shape.radius = minf(dimensions.x, dimensions.y) / 2.0
		collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _on_body_entered(_body: Node2D) -> void:
	if consumed or not active:
		return
	consumed = true
	set_deferred("monitoring", false)
	touched.emit(object_id)


func set_active(value: bool) -> void:
	active = value
	set_deferred("monitoring", value and not consumed)


func become_wreck() -> void:
	for point in definition.wreck_polygon:
		wreck_points.append(Vector2(point[0], point[1]))
	# Physics shape changes happen outside the active collision query.
	call_deferred("_add_wreck")
	queue_redraw()


func _add_wreck() -> void:
	if not is_inside_tree():
		return
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.set_meta("object_id", object_id + "_wreck")
	body.set_meta("contact_kind", "wreck")
	var polygon := CollisionPolygon2D.new()
	polygon.polygon = wreck_points
	body.add_child(polygon)
	add_child(body)


func _draw() -> void:
	if definition.is_empty():
		return
	var dimensions := Vector2(definition["size"][0], definition["size"][1])
	var body_color := Color("789393")
	var edge := Color("b6c9bf")
	if definition.object_type == "building":
		if consumed:
			if wreck_points.size() >= 3:
				draw_colored_polygon(wreck_points, Color("607879"))
				draw_polyline(wreck_points, edge, 2.0)
			return
		var impulse: Array = definition.exchange.impulse
		var booster := float(impulse[0]) > 0.0 or float(impulse[1]) < 0.0
		if booster:
			body_color = Color("ab795c")
			edge = Color("f0bc84")
		var rect := Rect2(-dimensions / 2.0, dimensions)
		draw_rect(rect, body_color)
		draw_rect(rect, edge, false, 2.0)
		for y in range(int(-dimensions.y / 2.0) + 18, int(dimensions.y / 2.0) - 14, 26):
			for x in range(int(-dimensions.x / 2.0) + 14, int(dimensions.x / 2.0) - 10, 25):
				draw_rect(Rect2(x, y, 10, 12), Color("243d48"))
		if booster:
			draw_line(Vector2(-15, -12), Vector2(0, -30), edge, 5)
			draw_line(Vector2(0, -30), Vector2(15, -12), edge, 5)
	else:
		if consumed:
			return
		var radius := minf(dimensions.x, dimensions.y) / 2.0
		var color := Color("86c6c6") if definition.object_type == "balloon" else Color("d4ef76")
		draw_circle(Vector2.ZERO, radius, color)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color("e4f7eb"), 2)
		draw_line(Vector2(0, radius), Vector2(0, radius + 18), color, 2)
		draw_line(Vector2(-10, 0), Vector2(10, 0), Color("203b46"), 3)
		draw_line(Vector2(0, -10), Vector2(0, 10), Color("203b46"), 3)
