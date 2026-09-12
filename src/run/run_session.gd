extends RefCounted
## Deterministic first-playable lifecycle. Only contract dictionaries enter this lane.

const Game = preload("res://src/core/contracts/game_contracts.gd")
const Run = preload("res://src/core/contracts/run_contracts.gd")
const Values = preload("res://src/core/domain/contract_values.gd")
const Rules = preload("res://src/run/scoring_rules.gd")

var _state := "preparing"
var _resume_state := ""
var _run_id := ""
var _ruleset: Dictionary = {}
var _mode: Dictionary = {}
var _elapsed_s := 0.0
var _clock_compensation := 0.0
var _sequence := -1
var _last_event_time := 0.0
var _score: Dictionary = Run.empty_score_breakdown()
var _score_total := 0
var _money := 0
var _destroyed_count := 0
var _seen_sources: Dictionary = {}
var _landing_time := -INF
var _combo := 0
var _best_combo := 0
var _combo_time := -INF
var _building_chain := 0
var _building_time := -INF
var _aerial_chain := 0
var _aerial_time := -INF
var _bounce_chain := 0
var _bounce_time := -INF
var _has_origin := false
var _origin_x := 0.0
var _distance_px := 0.0
var _snapshot_time := -1.0
var _result: Dictionary = {}


func prepare(run_id: String, ruleset: Dictionary) -> bool:
	var errors: Array = []
	if not Values.identifier(run_id, errors, "$.run_id") or not Game.validate_ruleset(ruleset).valid:
		return false
	if ruleset.scoring_tuning_version != Rules.VERSION:
		return false
	# Preparation is also the explicit restart boundary. Validation precedes reset.
	_state = "ready"
	_resume_state = ""
	_run_id = run_id
	_ruleset = Values.read_only_copy(ruleset)
	_mode = Values.read_only_copy(Run.mode_configuration(ruleset.mode_id, Rules.TIMED_DURATION_S))
	_elapsed_s = 0.0
	_clock_compensation = 0.0
	_sequence = -1
	_last_event_time = 0.0
	_score = Run.empty_score_breakdown()
	_score_total = 0
	_money = 0
	_destroyed_count = 0
	_seen_sources.clear()
	_landing_time = -INF
	_combo = 0
	_best_combo = 0
	_combo_time = -INF
	_building_chain = 0
	_building_time = -INF
	_aerial_chain = 0
	_aerial_time = -INF
	_bounce_chain = 0
	_bounce_time = -INF
	_has_origin = false
	_origin_x = 0.0
	_distance_px = 0.0
	_snapshot_time = -1.0
	_result = Values.read_only_copy({})
	return true


func set_paused(paused: bool) -> bool:
	if paused:
		if _state not in ["ready", "running"]:
			return false
		_resume_state = _state
		_state = "paused"
		return true
	if _state != "paused":
		return false
	_state = _resume_state
	_resume_state = ""
	return true


func consume_event(event: Dictionary) -> bool:
	if _state not in ["ready", "running"]:
		return false
	# The entire input is checked before clocks, sequence cursors, or rewards change.
	if not Game.validate_gameplay_event(event).valid or not _within_limits(event):
		return false
	if event.run_id != _run_id or int(event.sequence) != _sequence + 1:
		return false
	var time_s := float(event.run_time_s)
	if time_s < _last_event_time or time_s < _elapsed_s:
		return false
	if _state == "ready":
		if event.event_type != "launch" or time_s != 0.0:
			return false
	elif event.event_type == "launch":
		return false
	if _state == "running" and _timed() and time_s >= float(_mode.time_limit_s):
		# A valid cutoff event may close the run, but its payload earns nothing.
		_move_clock(float(_mode.time_limit_s))
		_finish("time_limit")
		return false
	_sequence = int(event.sequence)
	_last_event_time = time_s
	_move_clock(time_s)
	match event.event_type:
		"launch":
			_state = "running"
			_add_score("launch", Rules.points(float(event.payload.accuracy) * Rules.LAUNCH_MAX_POINTS))
		"building_destroyed", "target_collected", "pickup_collected":
			# A new envelope for an already consumed world source is an accepted no-op.
			# Consuming the sequence lets later legitimate events continue normally.
			if not _seen_sources.has(event.source_object_id):
				_seen_sources[event.source_object_id] = true
				_reward_object(event)
		"landed":
			_reward_landing(event)
		"viability_lost":
			_finish("momentum_depleted")
	return true


func advance(delta: float) -> void:
	if _state != "running" or not is_finite(delta) or delta <= 0.0:
		return
	# Compensated addition avoids accumulating a timer frame of rounding error.
	var increment := delta - _clock_compensation
	var next_time := _elapsed_s + increment
	if not is_finite(next_time):
		return
	_clock_compensation = (next_time - _elapsed_s) - increment
	_elapsed_s = next_time
	if _timed() and _elapsed_s >= float(_mode.time_limit_s):
		_elapsed_s = float(_mode.time_limit_s)
		_clock_compensation = 0.0
		_expire_chains()
		_finish("time_limit")
		return
	_expire_chains()


func update_truck_snapshot(truck_snapshot: Dictionary) -> void:
	if _state not in ["ready", "running"] or not Game.validate_truck_snapshot(truck_snapshot).valid:
		return
	var time_s := float(truck_snapshot.run_time_s)
	if time_s <= _snapshot_time or time_s > _elapsed_s:
		return
	if _timed() and time_s >= float(_mode.time_limit_s):
		return
	# Position alone informs distance. Velocity and viable never decide run endings.
	var x := float(truck_snapshot.position[0])
	_snapshot_time = time_s
	if not _has_origin:
		_has_origin = true
		_origin_x = x
		return
	if _state != "running":
		return
	_distance_px = maxf(_distance_px, maxf(0.0, x - _origin_x))
	var desired_distance_score := Rules.distance_points(_distance_px)
	_add_score("distance", maxi(0, desired_distance_score - int(_score.distance)))


func snapshot() -> Dictionary:
	if _run_id.is_empty():
		return {}
	return Run.run_snapshot({
		"state": _state, "run_id": _run_id, "ruleset": _ruleset,
		"elapsed_s": _elapsed_s,
		"time_remaining_s": maxf(0.0, float(_mode.time_limit_s) - _elapsed_s) if _timed() else null,
		"score_total": _score_total, "score_breakdown": _score,
		"money_earned": _money, "distance_px": _distance_px, "destroyed_count": _destroyed_count,
		"combo": _combo, "best_combo": _best_combo,
	})


func result() -> Dictionary:
	return _result


func _timed() -> bool:
	return _mode.get("mode_id") == "timed_efficiency"


func _move_clock(time_s: float) -> void:
	if time_s > _elapsed_s:
		_elapsed_s = time_s
		_clock_compensation = 0.0
	_expire_chains()


func _expire_chains() -> void:
	# The deadline is inclusive: a new contact exactly on the window still chains.
	if _elapsed_s - _combo_time > Rules.COMBO_WINDOW_S:
		_combo = 0
	if _elapsed_s - _building_time > Rules.COMBO_WINDOW_S:
		_building_chain = 0
	if _elapsed_s - _aerial_time > Rules.COMBO_WINDOW_S:
		_aerial_chain = 0
	if _elapsed_s - _bounce_time > Rules.BOUNCE_WINDOW_S:
		_bounce_chain = 0


func _reward_object(event: Dictionary) -> void:
	var payload: Dictionary = event.payload
	var value := float(payload.destruction_value)
	_add_score("destruction", Rules.points(value))
	_money += mini(int(payload.money_value), Rules.MAX_MONEY - _money)
	if event.event_type == "building_destroyed":
		_destroyed_count = mini(_destroyed_count + 1, Values.MAX_SAFE_INTEGER)
	if float(payload.combo_value) <= 0.0:
		return
	_add_combo()
	if event.event_type == "building_destroyed":
		_building_chain = mini(_building_chain + 1, Rules.MAX_COMBO)
		_building_time = _elapsed_s
		_add_score("building_chain", Rules.points(value * (Rules.multiplier(_building_chain) - 1.0)))
	elif event.event_type == "target_collected":
		_aerial_chain = mini(_aerial_chain + 1, Rules.MAX_COMBO)
		_aerial_time = _elapsed_s
		_add_score("aerial_chain", Rules.points(value * (Rules.multiplier(_aerial_chain) - 1.0)))


func _reward_landing(event: Dictionary) -> void:
	var time_s := float(event.run_time_s)
	# Same contact callback under new event IDs cannot award multiple bounce points.
	# One truck can land only once during the shared physics bounce cooldown.
	if time_s - _landing_time < Rules.BOUNCE_MIN_GAP_S:
		return
	_landing_time = time_s
	_aerial_chain = 0
	_aerial_time = -INF
	if event.payload.clean:
		_bounce_chain = mini(_bounce_chain + 1, Rules.MAX_COMBO)
		_bounce_time = time_s
		_add_combo()
		_add_score("bounce", Rules.points(Rules.CLEAN_BOUNCE_POINTS * Rules.multiplier(_bounce_chain)))
	else:
		_bounce_chain = 0
		_bounce_time = -INF
		_combo = 0
		_combo_time = -INF
		_add_score("bounce", Rules.points(Rules.BOUNCE_POINTS))


func _add_combo() -> void:
	_combo = mini(_combo + 1, Rules.MAX_COMBO)
	_best_combo = maxi(_best_combo, _combo)
	_combo_time = _elapsed_s


func _add_score(category: String, amount: int) -> void:
	var allowed := mini(maxi(amount, 0), Rules.MAX_SCORE - _score_total)
	_score[category] = int(_score[category]) + allowed
	_score_total += allowed


func _finish(reason: String) -> void:
	if _state != "running":
		return
	_state = "ended"
	_result = Values.read_only_copy(Run.run_result(_run_id, _ruleset, reason, _elapsed_s,
		_score, _money, _distance_px, _destroyed_count, _best_combo))


func _within_limits(event: Dictionary) -> bool:
	var payload: Dictionary = event.payload
	match event.event_type:
		"launch":
			return payload.speed_px_s > 0.0 and payload.speed_px_s <= 5000.0 and absf(float(payload.angle_rad)) <= TAU
		"building_destroyed", "target_collected", "pickup_collected":
			var request: Dictionary = payload.resource_request
			return payload.destruction_value <= Rules.MAX_EVENT_VALUE and payload.money_value <= Rules.MAX_EVENT_MONEY and payload.combo_value <= Rules.MAX_EVENT_COMBO \
				and request.speed_cost <= 5000.0 and request.nudge_refill <= 100.0 and request.equipment_refill <= 100.0 \
				and _vector_magnitude_within(request.impulse, 3000.0)
		"landed":
			return event.source_object_id == payload.contact.object_id and payload.contact.kind in ["ground", "wreck"] \
				and payload.impact_speed_px_s > 0.0 and payload.impact_speed_px_s <= 5000.0
		"contact":
			return event.source_object_id == payload.contact.object_id
		"nudge_used":
			return payload.energy_spent <= 100.0 and _vector_magnitude_within(payload.impulse, 3000.0)
		"momentum_changed":
			return payload.before_px_s <= 5000.0 and payload.after_px_s <= 5000.0
	return true


func _vector_magnitude_within(value: Array, maximum: float) -> bool:
	return float(value[0]) * float(value[0]) + float(value[1]) * float(value[1]) <= maximum * maximum
