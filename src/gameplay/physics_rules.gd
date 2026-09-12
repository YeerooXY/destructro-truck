extends RefCounted
## Pure arcade tuning and bounded calculations; no engine body, score, or world rules.

const Game = preload("res://src/core/contracts/game_contracts.gd")
const Values = preload("res://src/core/domain/contract_values.gd")

const LIMITS := {
	"mass": [0.1, 100.0], "body_width": [30.0, 140.0], "body_height": [16.0, 70.0],
	"center_of_mass_y": [-12.0, 12.0], "friction": [0.0, 0.6],
	"linear_damping": [0.0, 1.0], "angular_damping": [0.0, 8.0], "gravity": [100.0, 1800.0],
	"max_speed": [500.0, 2200.0], "max_up_speed": [150.0, 1000.0], "max_down_speed": [300.0, 1800.0],
	"launch_min_speed": [100.0, 1400.0], "launch_max_speed": [300.0, 1800.0],
	"launch_angle_rad": [-0.75, -0.05], "launch_cycle_s": [0.5, 4.0],
	"ground_restitution": [0.0, 0.85], "wreck_restitution": [0.0, 0.9],
	"bounce_tangent_retention": [0.0, 1.0], "bounce_min_impact": [40.0, 300.0],
	"bounce_cooldown_s": [0.1, 1.0], "clean_landing_angle": [0.05, 0.7],
	"clean_landing_refill": [0.0, 15.0], "rotation_acceleration": [0.1, 18.0],
	"max_angular_speed": [0.2, 8.0], "nudge_capacity": [1.0, 300.0],
	"nudge_energy_per_s": [5.0, 100.0], "nudge_acceleration": [50.0, 900.0],
	"equipment_capacity": [0.0, 300.0], "stop_speed": [2.0, 80.0],
	"stop_angular_speed": [0.05, 2.0], "stop_dwell_s": [0.3, 5.0],
	"recovery_grace_s": [0.0, 8.0], "snapshot_hz": [5.0, 30.0],
}


static func defaults() -> Dictionary:
	return {
		"mass": 2.0, "body_width": 76.0, "body_height": 34.0, "center_of_mass_y": 3.0,
		"friction": 0.18, "linear_damping": 0.045, "angular_damping": 0.7, "gravity": 920.0,
		"max_speed": 1600.0, "max_up_speed": 700.0, "max_down_speed": 1100.0,
		"launch_min_speed": 800.0, "launch_max_speed": 1120.0, "launch_angle_rad": -0.349066,
		"launch_cycle_s": 1.5, "ground_restitution": 0.46, "wreck_restitution": 0.64,
		"bounce_tangent_retention": 0.98, "bounce_min_impact": 100.0, "bounce_cooldown_s": 0.18,
		"clean_landing_angle": 0.3, "clean_landing_refill": 3.0,
		"rotation_acceleration": 8.5, "max_angular_speed": 3.4,
		"nudge_capacity": 100.0, "nudge_energy_per_s": 28.0, "nudge_acceleration": 480.0,
		"equipment_capacity": 100.0, "stop_speed": 27.0, "stop_angular_speed": 0.35,
		"stop_dwell_s": 1.4, "recovery_grace_s": 2.0, "snapshot_hz": 12.0,
	}


static func configured(overrides: Dictionary) -> Dictionary:
	var result := defaults()
	for key in overrides:
		if key not in LIMITS:
			return {}
		var errors: Array = []
		if not Values.number(overrides[key], errors, str(key), LIMITS[key][0], LIMITS[key][1]):
			return {}
		result[key] = float(overrides[key])
	if result.launch_min_speed > result.launch_max_speed or result.launch_max_speed > result.max_speed:
		return {}
	if result.max_up_speed > result.max_speed or result.max_down_speed > result.max_speed:
		return {}
	return result


static func bounded_velocity(velocity: Vector2, tuning: Dictionary) -> Vector2:
	if not velocity.is_finite():
		return Vector2.ZERO
	velocity.y = clampf(velocity.y, -tuning.max_up_speed, tuning.max_down_speed)
	return velocity.limit_length(tuning.max_speed)


static func launch_feedback(charge_time_s: float, tuning: Dictionary) -> Dictionary:
	var phase := fposmod(charge_time_s / tuning.launch_cycle_s, 1.0)
	# One complete left-right cycle. Centre is the ideal hit, twice per cycle.
	var cursor := 1.0 - absf(phase * 2.0 - 1.0)
	var accuracy := clampf(1.0 - absf(cursor - 0.5) * 2.0, 0.0, 1.0)
	return {"phase": cursor, "accuracy": accuracy}


static func launch_velocity(accuracy: float, tuning: Dictionary) -> Vector2:
	var speed := lerpf(tuning.launch_min_speed, tuning.launch_max_speed, clampf(accuracy, 0.0, 1.0))
	return bounded_velocity(Vector2.from_angle(tuning.launch_angle_rad) * speed, tuning)


static func validate_resource_limits(request: Variant, tuning: Dictionary) -> bool:
	if not Game.validate_resource_request(request).valid:
		return false
	# Check the wire numbers before converting to float32 Vector2, which may overflow.
	if request.speed_cost > 5000.0 or request.nudge_refill > tuning.nudge_capacity or request.equipment_refill > tuning.equipment_capacity:
		return false
	if absf(request.impulse[0]) > 3000.0 or absf(request.impulse[1]) > 3000.0:
		return false
	return Values.to_vector(request.impulse).length() <= 3000.0


static func apply_resource(velocity: Vector2, energy: float, charge: float, request: Dictionary, tuning: Dictionary) -> Dictionary:
	if not validate_resource_limits(request, tuning):
		return {"valid": false}
	var speed := velocity.length()
	var after_cost := velocity.normalized() * maxf(0.0, speed - float(request.speed_cost)) if speed > 0.001 else Vector2.ZERO
	return {
		"valid": true,
		"velocity": bounded_velocity(after_cost + Values.to_vector(request.impulse), tuning),
		"energy": clampf(energy + request.nudge_refill, 0.0, tuning.nudge_capacity),
		"charge": clampf(charge + request.equipment_refill, 0.0, tuning.equipment_capacity),
	}


static func nudge_step(direction: Vector2, strength: float, energy: float, delta: float, tuning: Dictionary) -> Dictionary:
	if not direction.is_finite() or not is_finite(strength) or not is_finite(delta) or delta <= 0.0 or direction.length_squared() < 0.0001:
		return {"energy_spent": 0.0, "impulse": Vector2.ZERO}
	var requested: float = tuning.nudge_energy_per_s * clampf(strength, 0.0, 1.0) * minf(delta, 0.1)
	var spent := minf(maxf(energy, 0.0), requested)
	return {"energy_spent": spent, "impulse": direction.normalized() * (spent / tuning.nudge_energy_per_s) * tuning.nudge_acceleration}


static func rotation_step(current: float, axis: float, delta: float, airborne: bool, tuning: Dictionary) -> float:
	var result := current
	if airborne:
		result += clampf(axis, -1.0, 1.0) * tuning.rotation_acceleration * delta
	return clampf(result, -tuning.max_angular_speed, tuning.max_angular_speed)


static func bounce_velocity(incoming: Vector2, normal: Vector2, kind: String, tuning: Dictionary) -> Vector2:
	var approach := incoming.dot(normal)
	if approach >= -tuning.bounce_min_impact or kind not in ["ground", "wreck"]:
		return incoming
	var tangent := incoming - normal * approach
	var restitution: float = tuning.wreck_restitution if kind == "wreck" else tuning.ground_restitution
	return bounded_velocity(tangent * tuning.bounce_tangent_retention - normal * approach * restitution, tuning)


static func stop_dwell(velocity: Vector2, angular_speed: float, grounded: bool, energy: float, previous: float, delta: float, tuning: Dictionary) -> Dictionary:
	var stalled: bool = grounded and velocity.length() < tuning.stop_speed and absf(angular_speed) < tuning.stop_angular_speed
	var dwell := previous + delta if stalled else 0.0
	# Recovery energy provides a short chance to act, not permanent immunity to stopping.
	var threshold: float = tuning.stop_dwell_s + (tuning.recovery_grace_s if energy > 0.01 else 0.0)
	return {"dwell_s": dwell, "lost": stalled and dwell >= threshold}
