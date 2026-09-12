extends Camera2D
## Presentation-only follow; never writes truck state.

var _truck: Node2D
var _shake_intensity := 1.0
var _shake_remaining := 0.0
var _shake_elapsed := 0.0
var _shake_amount := 0.0


func _ready() -> void:
	top_level = true
	position_smoothing_enabled = false
	ignore_rotation = true
	enabled = true
	_truck = get_parent() as Node2D
	reset_follow()


func set_shake_intensity(value: float) -> void:
	_shake_intensity = clampf(value, 0.0, 1.0) if is_finite(value) else 0.0
	if _shake_intensity == 0.0:
		offset = Vector2.ZERO


func request_shake(amount: float = 4.0, duration_s: float = 0.18) -> void:
	if not is_finite(amount) or not is_finite(duration_s):
		return
	_shake_amount = clampf(amount, 0.0, 12.0)
	_shake_remaining = clampf(duration_s, 0.0, 0.5)
	_shake_elapsed = 0.0


func reset_follow() -> void:
	_shake_remaining = 0.0
	offset = Vector2.ZERO
	if is_instance_valid(_truck):
		global_position = Vector2(maxf(640.0, _truck.global_position.x + 230.0), minf(310.0, _truck.global_position.y - 180.0))
	reset_smoothing()


func _process(delta: float) -> void:
	if not is_instance_valid(_truck) or not _truck.has_method("get_snapshot"):
		return
	var snapshot: Dictionary = _truck.get_snapshot()
	var velocity_x := float(snapshot.velocity[0])
	var ahead := clampf(velocity_x * 0.28, 180.0, 390.0)
	var target := Vector2(maxf(640.0, _truck.global_position.x + ahead), minf(320.0, _truck.global_position.y - 140.0))
	global_position = global_position.lerp(target, 1.0 - exp(-5.0 * delta))
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	_shake_elapsed += delta
	var scale := minf(_shake_remaining / 0.12, 1.0) * _shake_amount * _shake_intensity
	offset = Vector2(sin(_shake_elapsed * 89.0), cos(_shake_elapsed * 113.0)) * scale
