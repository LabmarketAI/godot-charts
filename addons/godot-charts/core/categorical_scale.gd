class_name CategoricalScale
extends RefCounted

var domain: PackedStringArray
var range: Array


func _init(categories: PackedStringArray, output_values: Array) -> void:
	domain = categories.duplicate()
	range = output_values.duplicate(true)


func validate(path: String = "/scale") -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if domain.is_empty():
		diagnostics.append(_error("empty-domain", "Categorical scale domain must not be empty.", path + "/domain"))
	if range.is_empty():
		diagnostics.append(_error("empty-range", "Categorical scale range must not be empty.", path + "/range"))
	var seen: Dictionary = {}
	for index: int in domain.size():
		if seen.has(domain[index]):
			diagnostics.append(_error("duplicate-category", "Categorical scale domain values must be unique.", path + "/domain/%d" % index))
		seen[domain[index]] = true
	return diagnostics


func map(value: Variant) -> Variant:
	if value == null or range.is_empty():
		return null
	var index := domain.find(str(value))
	if index < 0:
		return null
	return range[index % range.size()]


func to_dictionary() -> Dictionary:
	return {"type": "categorical", "domain": Array(domain), "range": range.duplicate(true)}


func _error(code: String, message: String, path: String) -> Dictionary:
	return {"severity": "error", "code": code, "message": message, "path": path}
