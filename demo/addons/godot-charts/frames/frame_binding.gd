class_name FrameBinding
extends RefCounted

const KINDS: PackedStringArray = ["static_plot", "live_plot", "stream", "derived", "snapshot"]
const REPRESENTATION_POLICIES: PackedStringArray = ["follow_source", "suggest_source", "user_locked", "derived"]

var kind: String
var source_id: String
var representation_policy: String
var source_revision: int
var metadata: Dictionary


func _init(binding_kind: String = "static_plot", binding_source_id: String = "unbound", policy: String = "follow_source", revision: int = 0, binding_metadata: Dictionary = {}) -> void:
	kind = binding_kind
	source_id = binding_source_id
	representation_policy = policy
	source_revision = revision
	metadata = binding_metadata.duplicate(true)


func validate(path: String = "/binding") -> Array[Dictionary]:
	var diagnostics: Array[Dictionary] = []
	if kind not in KINDS:
		diagnostics.append(_error("invalid-binding-kind", "Binding kind is not supported.", path + "/kind"))
	if source_id.is_empty():
		diagnostics.append(_error("empty-binding-source", "Binding source identity must not be empty.", path + "/source_id"))
	if representation_policy not in REPRESENTATION_POLICIES:
		diagnostics.append(_error("invalid-representation-policy", "Representation policy is not supported.", path + "/representation_policy"))
	if source_revision < 0:
		diagnostics.append(_error("invalid-source-revision", "Source revision must be non-negative.", path + "/source_revision"))
	return diagnostics


func to_dictionary() -> Dictionary:
	return {
		"kind": kind,
		"source_id": source_id,
		"representation_policy": representation_policy,
		"source_revision": source_revision,
		"metadata": metadata.duplicate(true),
	}


static func from_dictionary(value: Dictionary) -> RefCounted:
	return FrameBinding.new(
		str(value.get("kind", "static_plot")),
		str(value.get("source_id", "unbound")),
		str(value.get("representation_policy", "follow_source")),
		int(value.get("source_revision", 0)),
		value.get("metadata", {}),
	)


func _error(code: String, message: String, path: String) -> Dictionary:
	return {"severity": "error", "code": code, "message": message, "path": path}
