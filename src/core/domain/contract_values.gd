extends RefCounted
## Small, deterministic wire-value helpers. No gameplay rules live here.

const MAX_SAFE_INTEGER := 9007199254740991
const MAX_WIRE_DEPTH := 32
const MAX_VECTOR_COMPONENT := 1000000000.0


static func result(errors: Array) -> Dictionary:
	return {"valid": errors.is_empty(), "errors": errors}


static func error(errors: Array, path: String, code: String, message: String) -> void:
	errors.append({"path": path, "code": code, "message": message})


static func fields(value: Variant, required: Array, optional: Array, errors: Array, path: String = "$") -> bool:
	if not value is Dictionary:
		error(errors, path, "type", "Expected a dictionary.")
		return false
	for key in required:
		if not value.has(key):
			error(errors, path + "." + str(key), "required", "Missing required field.")
	for key in value:
		if not key is String or (key not in required and key not in optional):
			error(errors, path + "." + str(key), "unknown_field", "Unknown field.")
	return true


static func schema(value: Dictionary, expected: String, errors: Array, path: String = "$") -> void:
	if not same_string(value.get("schema_id"), expected):
		error(errors, path + ".schema_id", "unsupported_schema", "Expected " + expected + ".")


static func same_string(left: Variant, right: Variant) -> bool:
	# Godot's Variant equality can throw for unlike types (for example bool/String).
	return left is String and right is String and left == right


static func number(value: Variant, errors: Array, path: String, minimum: float = -INF, maximum: float = INF) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		error(errors, path, "type", "Expected a number.")
		return false
	if not is_finite(float(value)):
		error(errors, path, "non_finite", "Numbers must be finite.")
		return false
	if value < minimum or value > maximum:
		error(errors, path, "range", "Number is outside its allowed range.")
		return false
	return true


static func integer(value: Variant, errors: Array, path: String, minimum: int = 0, maximum: int = MAX_SAFE_INTEGER) -> bool:
	if not number(value, errors, path, minimum, maximum):
		return false
	if float(value) != floor(float(value)):
		error(errors, path, "integer", "Expected an integer-valued number.")
		return false
	return true


static func boolean(value: Variant, errors: Array, path: String) -> bool:
	if not value is bool:
		error(errors, path, "type", "Expected a boolean.")
		return false
	return true


static func text_value(value: Variant, errors: Array, path: String, maximum_length: int = 256, allow_empty: bool = false) -> bool:
	if not value is String:
		error(errors, path, "type", "Expected a string.")
		return false
	if (value.is_empty() and not allow_empty) or value.length() > maximum_length:
		error(errors, path, "length", "String length is outside its allowed range.")
		return false
	return true


static func identifier(value: Variant, errors: Array, path: String, allow_empty: bool = false) -> bool:
	if not text_value(value, errors, path, 64, allow_empty):
		return false
	if value.is_empty():
		return allow_empty
	for index in value.length():
		var character: int = value.unicode_at(index)
		var alphanumeric := (character >= 97 and character <= 122) or (character >= 48 and character <= 57)
		if not alphanumeric and (index == 0 or character not in [45, 95]):
			error(errors, path, "id_format", "IDs use lowercase letters, digits, underscores, and hyphens.")
			return false
	return true


static func enum_value(value: Variant, choices: Array, errors: Array, path: String) -> bool:
	if not value is String or value not in choices:
		error(errors, path, "unknown_value", "Unsupported identifier.")
		return false
	return true


static func vector(value: Variant, errors: Array, path: String, unit_bounded: bool = false) -> bool:
	if not value is Array or value.size() != 2:
		error(errors, path, "vector", "Expected a two-number [x, y] array.")
		return false
	var x_valid := number(value[0], errors, path + "[0]", -MAX_VECTOR_COMPONENT, MAX_VECTOR_COMPONENT)
	var y_valid := number(value[1], errors, path + "[1]", -MAX_VECTOR_COMPONENT, MAX_VECTOR_COMPONENT)
	if x_valid and y_valid and unit_bounded:
		var length_squared := float(value[0]) * float(value[0]) + float(value[1]) * float(value[1])
		if length_squared > 1.000001:
			error(errors, path, "vector_length", "Vector length must be at most one.")
			return false
	return x_valid and y_valid


static func vec(value: Vector2) -> Array:
	return [value.x, value.y]


static func to_vector(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


static func append_validation(errors: Array, validation: Dictionary, path: String) -> void:
	for issue in validation.errors:
		error(errors, path + str(issue.path).trim_prefix("$"), issue.code, issue.message)


static func json_value(value: Variant, errors: Array, path: String = "$", depth: int = 0) -> bool:
	var before := errors.size()
	if depth > MAX_WIRE_DEPTH:
		error(errors, path, "depth", "Wire value is nested too deeply.")
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			pass
		TYPE_INT, TYPE_FLOAT:
			number(value, errors, path)
		TYPE_ARRAY:
			for index in value.size():
				json_value(value[index], errors, path + "[%d]" % index, depth + 1)
		TYPE_DICTIONARY:
			for key in value:
				if not key is String:
					error(errors, path, "key_type", "JSON object keys must be strings.")
				else:
					json_value(value[key], errors, path + "." + key, depth + 1)
		_:
			error(errors, path, "wire_type", "Only JSON-safe values cross contracts.")
	return errors.size() == before


static func read_only_copy(value: Variant) -> Variant:
	# Call only after validation: unlike duplicate(true), this also freezes children.
	if value is Dictionary:
		var copy: Dictionary = {}
		for key in value:
			copy[key] = read_only_copy(value[key])
		copy.make_read_only()
		return copy
	if value is Array:
		var copy: Array = []
		for item in value:
			copy.append(read_only_copy(item))
		copy.make_read_only()
		return copy
	return value
