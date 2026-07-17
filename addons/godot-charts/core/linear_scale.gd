class_name LinearScale
extends RefCounted

var domain_min: float
var domain_max: float
var range_min: float
var range_max: float
var clamp: bool


func _init(minimum: float, maximum: float, output_minimum: float = 0.0, output_maximum: float = 1.0, should_clamp: bool = false) -> void:
	domain_min = minimum
	domain_max = maximum
	range_min = output_minimum
	range_max = output_maximum
	clamp = should_clamp


func validate(path: String = "/scale") -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if not is_finite(domain_min) or not is_finite(domain_max):
		diagnostics.append(_error("non-finite-domain", "Linear scale domain must be finite.", path + "/domain"))
	elif domain_min >= domain_max:
		diagnostics.append(_error("invalid-domain", "Linear scale minimum must be less than its maximum.", path + "/domain"))
	if not is_finite(range_min) or not is_finite(range_max) or range_min == range_max:
		diagnostics.append(_error("invalid-range", "Linear scale range must be finite and non-zero.", path + "/range"))
	return diagnostics


func map(value: Variant) -> Variant:
	if value == null or not (value is int or value is float):
		return null
	var numeric := float(value)
	if not is_finite(numeric) or domain_min >= domain_max:
		return null
	var unit := (numeric - domain_min) / (domain_max - domain_min)
	if clamp:
		unit = clampf(unit, 0.0, 1.0)
	return lerpf(range_min, range_max, unit)


func invert(value: float) -> Variant:
	if not is_finite(value) or range_min == range_max:
		return null
	var unit := (value - range_min) / (range_max - range_min)
	if clamp:
		unit = clampf(unit, 0.0, 1.0)
	return lerpf(domain_min, domain_max, unit)


func to_dictionary() -> Dictionary:
	return {"type": "linear", "domain": [domain_min, domain_max], "range": [range_min, range_max], "clamp": clamp}


func _error(code: String, message: String, path: String) -> Dictionary:
	return {"severity": "error", "code": code, "message": message, "path": path}
