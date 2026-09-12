extends RefCounted

const Session = preload("res://src/run/run_session.gd")
const Game = preload("res://src/core/contracts/game_contracts.gd")
const Run = preload("res://src/core/contracts/run_contracts.gd")
const Rules = preload("res://src/run/scoring_rules.gd")
const Fixture = preload("res://tests/fixtures/run/fixture_builder.gd")


static func run() -> Array[String]:
	var failures: Array[String] = []
	_lifecycle(failures)
	_ordered_results(failures)
	_duplicate_rewards(failures)
	_invalid_events_are_atomic(failures)
	_timed_boundaries(failures)
	_survival_and_reset(failures)
	_combo_boundaries(failures)
	_distance_snapshots(failures)
	_numeric_bounds(failures)
	return failures


static func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


static func _active(run_id: String, mode: String = "survival") -> RefCounted:
	var session := Session.new()
	session.prepare(run_id, Game.ruleset(mode))
	session.update_truck_snapshot(Fixture.truck(0.0, 100.0))
	session.consume_event(Fixture.launch(run_id))
	return session


static func _lifecycle(failures: Array[String]) -> void:
	var session := Session.new()
	_check(session.snapshot().is_empty() and session.result().is_empty(), "Unprepared session exposes no run.", failures)
	_check(not session.consume_event(Fixture.launch("lifecycle")), "Unprepared launch rejects.", failures)
	_check(not session.prepare("Bad ID", Game.ruleset()), "Invalid preparation rejects.", failures)
	_check(session.prepare("lifecycle", Game.ruleset()), "Valid preparation succeeds.", failures)
	var ready: Dictionary = session.snapshot()
	_check(Run.validate_run_snapshot(ready).valid and ready.state == "ready", "Preparation publishes accepted ready snapshot.", failures)
	_check(ready.is_read_only() and ready.ruleset.is_read_only() and ready.score_breakdown.is_read_only(), "Snapshot freezes nested state.", failures)
	session.advance(100.0)
	_check(session.snapshot() == ready, "Ready state does not count launch preparation time.", failures)
	_check(not session.consume_event(Fixture.stop("lifecycle", 0, 0.0)), "A run cannot finish before launch.", failures)
	_check(not session.consume_event(Fixture.object_event("lifecycle", 0, 0.0, "early")), "A ready truck cannot earn destruction rewards.", failures)
	_check(session.set_paused(true), "Ready run can pause.", failures)
	_check(not session.set_paused(true), "Repeated pause rejects.", failures)
	_check(not session.consume_event(Fixture.launch("lifecycle")), "Paused preparation cannot launch.", failures)
	_check(session.set_paused(false) and session.snapshot().state == "ready", "Resume restores preparation.", failures)
	_check(session.consume_event(Fixture.launch("lifecycle")), "Launch enters running.", failures)
	var launched: Dictionary = session.snapshot()
	_check(not session.consume_event(Fixture.launch("lifecycle", 1)), "Second launch rejects.", failures)
	_check(session.snapshot() == launched, "Rejected second launch does not mutate run.", failures)
	session.advance(2.0)
	_check(session.set_paused(true), "Running run can pause.", failures)
	var paused: Dictionary = session.snapshot()
	session.advance(1000.0)
	session.update_truck_snapshot(Fixture.truck(2.0, 5000.0))
	_check(not session.consume_event(Fixture.object_event("lifecycle", 1, 2.0, "paused")), "Paused run rejects reward event.", failures)
	_check(session.snapshot() == paused, "Pause freezes all displayed game state and clock.", failures)
	_check(session.set_paused(false) and session.snapshot().state == "running", "Resume restores running.", failures)
	_check(not session.set_paused(false), "Resume on unpaused run rejects.", failures)
	_check(session.consume_event(Fixture.stop("lifecycle", 1, 2.0)), "One viability signal ends the run.", failures)
	var completed: Dictionary = session.result()
	_check(Run.validate_run_result(completed).valid, "Completion produces accepted result.", failures)
	_check(completed.is_read_only() and completed.score_breakdown.is_read_only() and completed.eligibility.reasons.is_read_only(), "Result is recursively immutable.", failures)
	_check(not completed.eligibility.eligible and completed.eligibility.reasons == ["debug_build"], "Prototype results do not claim online eligibility.", failures)
	_check(not session.consume_event(Fixture.stop("lifecycle", 2, 2.0)), "Repeated stop cannot complete again.", failures)
	session.advance(20.0)
	session.update_truck_snapshot(Fixture.truck(3.0, 9000.0))
	_check(session.result() == completed and session.snapshot().state == "ended", "Completed result remains frozen.", failures)
	_check(not session.set_paused(true), "Ended run cannot pause.", failures)


static func _mixed_fixture(mode: String) -> RefCounted:
	var session := Session.new()
	session.prepare("fixture", Game.ruleset(mode))
	session.update_truck_snapshot(Fixture.truck(0.0, 100.0))
	var events: Array[Dictionary] = [
		Fixture.launch("fixture", 0, 0.0, 0.8),
		Fixture.object_event("fixture", 1, 1.0, "building_a"),
		Fixture.object_event("fixture", 2, 2.0, "building_b", "building_destroyed", 150.0, 15),
		Fixture.object_event("fixture", 3, 2.5, "balloon_a", "target_collected", 60.0, 6),
		Fixture.object_event("fixture", 4, 3.0, "balloon_b", "target_collected", 80.0, 8),
		Fixture.landing("fixture", 5, 3.2),
		Fixture.landing("fixture", 6, 3.2),
		Fixture.landing("fixture", 7, 4.0),
	]
	for event in events:
		session.consume_event(event)
	session.update_truck_snapshot(Fixture.truck(4.0, 1100.0))
	session.consume_event(Fixture.stop("fixture", 8, 5.0))
	return session


static func _ordered_results(failures: Array[String]) -> void:
	for mode in ["survival", "timed_efficiency"]:
		var first: Dictionary = _mixed_fixture(mode).result()
		var second: Dictionary = _mixed_fixture(mode).result()
		_check(first == second, "Repeated ordered fixture is deterministic: " + mode, failures)
		_check(Run.validate_run_result(first).valid, "Mixed result validates: " + mode, failures)
		var expected := {"destruction": 390, "distance": 100, "building_chain": 37, "bounce": 112, "aerial_chain": 20, "launch": 400}
		_check(first.score_breakdown == expected and first.score_total == 1059, "Hand-calculated component totals match: " + mode, failures)
		_check(first.money_earned == 39 and first.destroyed_count == 2 and first.best_combo == 6, "Money, destruction count and combo match fixture: " + mode, failures)
		_check(first.elapsed_s == 5.0 and first.distance_px == 1000.0, "Distance and duration match fixture: " + mode, failures)
		_check(first.ruleset.mode_id == mode, "Mode metadata stays separate: " + mode, failures)


static func _duplicate_rewards(failures: Array[String]) -> void:
	var session = _active("duplicates")
	var first := Fixture.object_event("duplicates", 1, 1.0, "once")
	_check(session.consume_event(first), "First object contact accepted.", failures)
	var before: Dictionary = session.snapshot()
	_check(not session.consume_event(first), "Identical event ID rejects.", failures)
	_check(session.snapshot() == before, "Identical callback cannot change run state.", failures)
	_check(session.consume_event(Fixture.object_event("duplicates", 2, 1.0, "once")), "New envelope for consumed source is a no-op.", failures)
	_check(session.snapshot() == before, "New event ID cannot duplicate source rewards or combos.", failures)
	_check(session.consume_event(Fixture.object_event("duplicates", 3, 1.0, "once", "target_collected")), "Source protection also spans object event types.", failures)
	_check(session.snapshot() == before, "Changing event kind does not reward the same source twice.", failures)
	_check(session.consume_event(Fixture.object_event("duplicates", 4, 2.0, "next")), "Later legitimate source still works after duplicate envelope.", failures)
	_check(session.snapshot().destroyed_count == 2 and session.snapshot().money_earned == 20, "Only two unique buildings earn money.", failures)
	session.consume_event(Fixture.landing("duplicates", 5, 2.2))
	var bounce_score: int = session.snapshot().score_breakdown.bounce
	session.consume_event(Fixture.landing("duplicates", 6, 2.2, "other_ground"))
	_check(session.snapshot().score_breakdown.bounce == bounce_score, "Multiple collider callbacks in one landing cannot duplicate bounce score.", failures)
	session.consume_event(Fixture.landing("duplicates", 7, 2.3))
	_check(session.snapshot().score_breakdown.bounce == bounce_score, "Bounce cooldown suppresses duplicate contact jitter.", failures)


static func _invalid_events_are_atomic(failures: Array[String]) -> void:
	var session = _active("invalid")
	var malformed: Array[Dictionary] = []
	var event := Fixture.object_event("invalid", 1, 10.0, "object")
	event.payload.money_value = -1
	malformed.append(event)
	event = Fixture.object_event("invalid", 1, 10.0, "object")
	event.payload.destruction_value = NAN
	malformed.append(event)
	event = Fixture.object_event("invalid", 1, 10.0, "object")
	event.payload.resource_request.source_object_id = "someone_else"
	malformed.append(event)
	event = Fixture.object_event("invalid", 1, 10.0, "object")
	event.payload.money_value = 1000001
	malformed.append(event)
	event = Fixture.object_event("invalid", 1, 10.0, "object")
	event.payload.combo_value = 100000000.0
	malformed.append(event)
	event = Fixture.object_event("invalid", 1, 10.0, "object")
	event["extra"] = true
	malformed.append(event)
	event = Fixture.object_event("invalid", 1, 10.0, "object")
	event.erase("payload")
	malformed.append(event)
	malformed.append(Fixture.object_event("wrong_run", 1, 10.0, "object"))
	malformed.append(Fixture.object_event("invalid", 2, 10.0, "object"))
	event = Fixture.landing("invalid", 1, 10.0)
	event.source_object_id = "wrong_surface"
	malformed.append(event)
	event = Fixture.object_event("invalid", 1, 10.0, "object")
	event.event_id = "forged"
	malformed.append(event)
	for index in malformed.size():
		var before: Dictionary = session.snapshot()
		_check(not session.consume_event(malformed[index]), "Malformed event rejects, case " + str(index), failures)
		_check(session.snapshot() == before, "Malformed event cannot advance clock, combo or rewards, case " + str(index), failures)
	_check(session.consume_event(Fixture.object_event("invalid", 1, 1.0, "object")), "Invalid inputs do not poison sequence or reserve source.", failures)
	var after: Dictionary = session.snapshot()
	_check(not session.consume_event(Fixture.object_event("invalid", 2, 0.5, "stale")), "Decreasing event time rejects.", failures)
	_check(session.snapshot() == after, "Stale event rejection is atomic.", failures)
	session.advance(2.0)
	_check(not session.consume_event(Fixture.object_event("invalid", 2, 2.0, "stale")), "Event older than authoritative clock rejects.", failures)
	_check(session.consume_event(Fixture.object_event("invalid", 2, 3.0, "next")), "Rejected stale event leaves the next sequence reusable.", failures)


static func _timed_boundaries(failures: Array[String]) -> void:
	var session = _active("timed", "timed_efficiency")
	session.advance(59.999999)
	_check(session.snapshot().state == "running", "Timed run remains active just below cutoff.", failures)
	_check(session.consume_event(Fixture.object_event("timed", 1, 59.999999, "before")), "Reward immediately before cutoff is accepted.", failures)
	var before: Dictionary = session.snapshot()
	_check(not session.consume_event(Fixture.object_event("timed", 2, 60.0, "at_cutoff")), "Event at exact cutoff earns nothing.", failures)
	var completed: Dictionary = session.result()
	_check(completed.elapsed_s == 60.0 and completed.end_reason == "time_limit", "Timed result uses exact duration and time-limit reason.", failures)
	_check(completed.score_total == before.score_total and completed.money_earned == before.money_earned, "Cutoff event cannot add score or money.", failures)
	_check(not session.consume_event(Fixture.object_event("timed", 2, 61.0, "late")), "Late reward rejects.", failures)
	session.advance(100.0)
	_check(session.result() == completed and session.snapshot().time_remaining_s == 0.0, "Timed result remains immutable after cutoff.", failures)
	var frames = _active("frames", "timed_efficiency")
	for index in range(3600):
		frames.advance(1.0 / 60.0)
	_check(frames.snapshot().state == "ended" and frames.result().elapsed_s == 60.0, "3600 sixty-Hz ticks hit sixty seconds without timer drift.", failures)
	var overshoot = _active("overshoot", "timed_efficiency")
	overshoot.advance(600.0)
	_check(overshoot.result().elapsed_s == 60.0, "Oversized valid frame clamps timed completion to exact cutoff.", failures)
	var malformed = _active("malformed_cutoff", "timed_efficiency")
	var invalid := Fixture.object_event("malformed_cutoff", 1, 60.0, "bad")
	invalid.payload.destruction_value = INF
	_check(not malformed.consume_event(invalid) and malformed.snapshot().elapsed_s == 0.0, "Malformed future event cannot expire a valid timed run.", failures)


static func _survival_and_reset(failures: Array[String]) -> void:
	var session = _active("survival")
	session.advance(86400.0 * 30.0)
	_check(session.snapshot().state == "running" and session.snapshot().time_remaining_s == null, "Survival remains active after thirty days without a hidden hard cap.", failures)
	var time_s: float = session.snapshot().elapsed_s
	session.update_truck_snapshot(Fixture.truck(time_s, 2000.0, false))
	_check(session.snapshot().state == "running", "Even a nonviable truck snapshot cannot end a run without the stop event.", failures)
	session.consume_event(Fixture.object_event("survival", 1, time_s, "same_source"))
	session.consume_event(Fixture.stop("survival", 2, time_s))
	var previous: Dictionary = session.result()
	var bad_rules := Game.ruleset()
	bad_rules.scoring_tuning_version = "unsupported"
	_check(not session.prepare("invalid_reset", bad_rules) and session.result() == previous, "Invalid reset leaves completed run intact.", failures)
	_check(session.prepare("restarted", Game.ruleset("timed_efficiency")), "Explicit preparation restarts an ended session.", failures)
	var reset: Dictionary = session.snapshot()
	_check(reset.state == "ready" and reset.elapsed_s == 0.0 and reset.score_total == 0 and reset.combo == 0 and reset.best_combo == 0 and reset.money_earned == 0 and reset.distance_px == 0.0, "Restart clears every transient output.", failures)
	_check(session.result().is_empty(), "Restart has no stale result.", failures)
	_check(not session.consume_event(Fixture.object_event("survival", 3, time_s, "late_old_run")), "Prior run events reject after reset.", failures)
	_check(session.consume_event(Fixture.launch("restarted")), "Restart accepts a fresh sequence zero launch.", failures)
	_check(session.consume_event(Fixture.object_event("restarted", 1, 1.0, "same_source")), "Restart clears world-source duplicate history.", failures)
	_check(session.snapshot().destroyed_count == 1 and session.snapshot().combo == 1, "Restart begins a new combo and count.", failures)


static func _combo_boundaries(failures: Array[String]) -> void:
	var session = _active("combo")
	session.consume_event(Fixture.object_event("combo", 1, 1.0, "first"))
	session.consume_event(Fixture.object_event("combo", 2, 4.0, "on_window"))
	_check(session.snapshot().combo == 2 and session.snapshot().score_breakdown.building_chain == 25, "Exact three-second combo deadline is inclusive.", failures)
	session.advance(3.000001)
	_check(session.snapshot().combo == 0 and session.snapshot().best_combo == 2, "Timeout clears current combo but preserves best.", failures)
	session.consume_event(Fixture.object_event("combo", 3, 7.000001, "after_window"))
	_check(session.snapshot().combo == 1 and session.snapshot().score_breakdown.building_chain == 25, "First destruction after timeout earns no chain bonus.", failures)
	session.consume_event(Fixture.object_event("combo", 4, 7.1, "air_a", "target_collected"))
	session.consume_event(Fixture.landing("combo", 5, 7.2))
	session.consume_event(Fixture.object_event("combo", 6, 7.3, "air_b", "target_collected"))
	_check(session.snapshot().score_breakdown.aerial_chain == 0, "Landing breaks an aerial chain.", failures)
	session.consume_event(Fixture.landing("combo", 7, 7.5, "yard_ground", false))
	_check(session.snapshot().combo == 0, "Rough landing clears the current combo.", failures)
	var bounded = _active("bounded")
	for index in range(1, 101):
		bounded.consume_event(Fixture.object_event("bounded", index, float(index) * 0.1, "building_%d" % index))
	_check(bounded.snapshot().score_breakdown.building_chain == 19100, "Building chain multiplier stops at three times base value.", failures)


static func _distance_snapshots(failures: Array[String]) -> void:
	var session = _active("distance")
	session.advance(2.0)
	session.update_truck_snapshot(Fixture.truck(1.0, 1100.0))
	_check(session.snapshot().distance_px == 1000.0 and session.snapshot().score_breakdown.distance == 100, "Distance uses forward displacement from preparation origin.", failures)
	session.update_truck_snapshot(Fixture.truck(1.5, 600.0))
	session.update_truck_snapshot(Fixture.truck(2.0, 1100.0))
	_check(session.snapshot().distance_px == 1000.0, "Driving backward and forward cannot farm distance.", failures)
	var before: Dictionary = session.snapshot()
	session.update_truck_snapshot(Fixture.truck(1.0, 9999.0))
	session.update_truck_snapshot(Fixture.truck(3.0, 9999.0))
	var invalid := Fixture.truck(2.0, 9999.0)
	invalid.position[0] = NAN
	session.update_truck_snapshot(invalid)
	_check(session.snapshot() == before, "Old, future, duplicate-time and malformed snapshots cannot mutate distance.", failures)
	session.advance(1.0)
	session.update_truck_snapshot(Fixture.truck(3.0, 1109.99))
	_check(session.snapshot().score_breakdown.distance == 100, "Distance points round down once from total forward distance.", failures)
	session.advance(1.0)
	session.update_truck_snapshot(Fixture.truck(4.0, 1110.0))
	_check(session.snapshot().score_breakdown.distance == 101, "Fractional forward distance contributes when the next whole point is reached.", failures)


static func _numeric_bounds(failures: Array[String]) -> void:
	var session = _active("numbers")
	var before: Dictionary = session.snapshot()
	for delta in [NAN, INF, -1.0, 0.0]:
		session.advance(delta)
	_check(session.snapshot() == before, "Invalid clock deltas never mutate state.", failures)
	var event := Fixture.object_event("numbers", 1, 1.0, "huge", "building_destroyed", 1.0e100)
	_check(not session.consume_event(event) and session.snapshot() == before, "Huge finite values reject before integer conversion or state mutation.", failures)
	_check(Rules.points(1.0e100) == Rules.MAX_SCORE and Rules.points(NAN) == 0, "Score rounding helper safely bounds extreme values.", failures)
	_check(session.consume_event(Fixture.object_event("numbers", 1, 1.0, "fractional", "building_destroyed", 12.99, 7)), "Fractional destruction values are valid.", failures)
	_check(session.snapshot().score_breakdown.destruction == 12 and session.snapshot().money_earned == 7, "Each destruction contribution rounds down while money remains separate.", failures)
