extends RefCounted
## Run vocabulary and output structure. Scoring formulas remain in src/run.

const Values = preload("res://src/core/domain/contract_values.gd")
const Game = preload("res://src/core/contracts/game_contracts.gd")
const RUN_STATES := ["preparing", "ready", "running", "paused", "ended"]
const END_REASONS := ["momentum_depleted", "time_limit", "abandoned", "out_of_bounds", "debug_stop"]
const SCORE_CATEGORIES := ["destruction", "distance", "building_chain", "bounce", "aerial_chain", "launch"]
const ELIGIBILITY_REASONS := ["debug_build", "unsupported_version", "stock_modified", "invalid_events", "invalid_result", "abandoned"]


static func mode_configuration(mode_id: String, timed_duration_s: float = 60.0) -> Dictionary:
	return {"schema_id": "mode_configuration.v1", "mode_id": mode_id, "time_limit_s": timed_duration_s if mode_id == "timed_efficiency" else null}


static func validate_mode_configuration(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "mode_id", "time_limit_s"], [], errors):
		return Values.result(errors)
	Values.schema(value, "mode_configuration.v1", errors)
	Values.enum_value(value.get("mode_id"), Game.MODE_IDS, errors, "$.mode_id")
	if Values.same_string(value.get("mode_id"), "survival"):
		if value.get("time_limit_s") != null:
			Values.error(errors, "$.time_limit_s", "mode_configuration", "Survival has no hard time limit.")
	elif Values.same_string(value.get("mode_id"), "timed_efficiency"):
		if Values.number(value.get("time_limit_s"), errors, "$.time_limit_s", 0.0) and value.time_limit_s == 0:
			Values.error(errors, "$.time_limit_s", "range", "Timed Efficiency needs a positive duration.")
	return Values.result(errors)


static func empty_score_breakdown() -> Dictionary:
	var breakdown: Dictionary = {}
	for category in SCORE_CATEGORIES:
		breakdown[category] = 0
	return breakdown


static func scoring_input(category: String, amount: float, source_event_id: String, run_time_s: float) -> Dictionary:
	return {"schema_id": "scoring_input.v1", "category": category, "amount": amount, "source_event_id": source_event_id, "run_time_s": run_time_s}


static func validate_scoring_input(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "category", "amount", "source_event_id", "run_time_s"], [], errors):
		return Values.result(errors)
	Values.schema(value, "scoring_input.v1", errors)
	Values.enum_value(value.get("category"), SCORE_CATEGORIES, errors, "$.category")
	Values.number(value.get("amount"), errors, "$.amount", 0.0)
	Values.number(value.get("run_time_s"), errors, "$.run_time_s", 0.0)
	if Values.text_value(value.get("source_event_id"), errors, "$.source_event_id", 81):
		var parts: PackedStringArray = value.source_event_id.split(":")
		if parts.size() != 2 or not parts[1].is_valid_int():
			Values.error(errors, "$.source_event_id", "event_reference", "Expected a canonical run_id:sequence reference.")
		else:
			Values.identifier(parts[0], errors, "$.source_event_id")
			Values.integer(parts[1].to_int(), errors, "$.source_event_id")
			if str(parts[1].to_int()) != parts[1]:
				Values.error(errors, "$.source_event_id", "event_reference", "Event sequence must use canonical integer text.")
	return Values.result(errors)


static func run_snapshot(fields: Dictionary) -> Dictionary:
	var value := fields.duplicate(true)
	value["schema_id"] = "run_snapshot.v1"
	if not validate_run_snapshot(value).valid:
		return {}
	return Values.read_only_copy(value)


static func validate_run_snapshot(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "state", "run_id", "ruleset", "elapsed_s", "time_remaining_s", "score_total", "score_breakdown", "money_earned", "distance_px", "destroyed_count", "combo", "best_combo"], [], errors):
		return Values.result(errors)
	Values.schema(value, "run_snapshot.v1", errors)
	Values.enum_value(value.get("state"), RUN_STATES, errors, "$.state")
	Values.identifier(value.get("run_id"), errors, "$.run_id")
	Values.append_validation(errors, Game.validate_ruleset(value.get("ruleset")), "$.ruleset")
	Values.number(value.get("elapsed_s"), errors, "$.elapsed_s", 0.0)
	if value.get("ruleset") is Dictionary and Values.same_string(value.ruleset.get("mode_id"), "survival"):
		if value.get("time_remaining_s") != null:
			Values.error(errors, "$.time_remaining_s", "mode_configuration", "Survival has no countdown.")
	else:
		Values.number(value.get("time_remaining_s"), errors, "$.time_remaining_s", 0.0)
	_validate_score(value, errors)
	Values.integer(value.get("money_earned"), errors, "$.money_earned")
	Values.number(value.get("distance_px"), errors, "$.distance_px", 0.0)
	Values.integer(value.get("destroyed_count"), errors, "$.destroyed_count")
	var combo_valid := Values.integer(value.get("combo"), errors, "$.combo")
	var best_valid := Values.integer(value.get("best_combo"), errors, "$.best_combo")
	if combo_valid and best_valid and value.combo > value.best_combo:
		Values.error(errors, "$.best_combo", "inconsistent", "Best combo cannot be smaller than the current combo.")
	return Values.result(errors)


static func run_result(run_id: String, ruleset_ref: Dictionary, end_reason: String, elapsed_s: float, score_breakdown: Dictionary, money_earned: int, distance_px: float, destroyed_count: int, best_combo: int, eligibility: Dictionary = {"eligible": false, "reasons": ["debug_build"]}) -> Dictionary:
	var score_total := 0
	for category in SCORE_CATEGORIES:
		score_total += int(score_breakdown.get(category, 0))
	return {
		"schema_id": "run_result.v1", "run_id": run_id, "ruleset": ruleset_ref.duplicate(true),
		"end_reason": end_reason, "elapsed_s": elapsed_s,
		"score_total": score_total, "score_breakdown": score_breakdown.duplicate(true),
		"money_earned": money_earned, "distance_px": distance_px, "destroyed_count": destroyed_count,
		"best_combo": best_combo, "eligibility": eligibility.duplicate(true),
	}


static func validate_eligibility(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["eligible", "reasons"], [], errors):
		return Values.result(errors)
	Values.boolean(value.get("eligible"), errors, "$.eligible")
	if not value.get("reasons") is Array:
		Values.error(errors, "$.reasons", "type", "Expected an array of reason codes.")
		return Values.result(errors)
	var seen: Array = []
	for index in value.reasons.size():
		var reason: Variant = value.reasons[index]
		Values.enum_value(reason, ELIGIBILITY_REASONS, errors, "$.reasons[%d]" % index)
		if reason in seen:
			Values.error(errors, "$.reasons[%d]" % index, "duplicate_value", "Eligibility reasons must not repeat.")
		seen.append(reason)
	if value.get("eligible") is bool and value.eligible and not value.reasons.is_empty():
		Values.error(errors, "$.reasons", "inconsistent", "Eligible results have no rejection reasons.")
	if value.get("eligible") is bool and not value.eligible and value.reasons.is_empty():
		Values.error(errors, "$.reasons", "required", "Ineligible results need at least one reason.")
	return Values.result(errors)


static func validate_run_result(value: Variant) -> Dictionary:
	var errors: Array = []
	if not Values.fields(value, ["schema_id", "run_id", "ruleset", "end_reason", "elapsed_s", "score_total", "score_breakdown", "money_earned", "distance_px", "destroyed_count", "best_combo", "eligibility"], [], errors):
		return Values.result(errors)
	Values.schema(value, "run_result.v1", errors)
	Values.identifier(value.get("run_id"), errors, "$.run_id")
	Values.append_validation(errors, Game.validate_ruleset(value.get("ruleset")), "$.ruleset")
	Values.enum_value(value.get("end_reason"), END_REASONS, errors, "$.end_reason")
	if Values.same_string(value.get("end_reason"), "time_limit") and value.get("ruleset") is Dictionary and Values.same_string(value.ruleset.get("mode_id"), "survival"):
		Values.error(errors, "$.end_reason", "mode_configuration", "Survival cannot end from a time limit.")
	Values.number(value.get("elapsed_s"), errors, "$.elapsed_s", 0.0)
	_validate_score(value, errors)
	Values.integer(value.get("money_earned"), errors, "$.money_earned")
	Values.number(value.get("distance_px"), errors, "$.distance_px", 0.0)
	Values.integer(value.get("destroyed_count"), errors, "$.destroyed_count")
	Values.integer(value.get("best_combo"), errors, "$.best_combo")
	Values.append_validation(errors, validate_eligibility(value.get("eligibility")), "$.eligibility")
	return Values.result(errors)


static func _validate_score(value: Dictionary, errors: Array) -> void:
	var total_valid := Values.integer(value.get("score_total"), errors, "$.score_total")
	var breakdown: Variant = value.get("score_breakdown")
	if not Values.fields(breakdown, SCORE_CATEGORIES, [], errors, "$.score_breakdown"):
		return
	var breakdown_valid := true
	var sum := 0
	for category in SCORE_CATEGORIES:
		if Values.integer(breakdown.get(category), errors, "$.score_breakdown." + category):
			sum += int(breakdown[category])
		else:
			breakdown_valid = false
	if total_valid and breakdown_valid and sum != value.score_total:
		Values.error(errors, "$.score_total", "inconsistent", "Score total must equal the published breakdown.")
