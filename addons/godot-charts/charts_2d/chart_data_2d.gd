@tool
class_name ChartData2D
extends Resource

## Shared x-axis labels and parallel numeric datasets.
##
## Longitudinal data is aligned by index: every dataset must contain exactly
## one value for every label. Use append_sample() when streaming categories so
## the label and every series advance atomically. An omitted series value is
## stored as NAN, which renderers treat as an intentional gap.

@export var labels := PackedStringArray():
	set(value):
		labels = value
		if not _batching_changes:
			emit_changed()
@export var datasets: Array[ChartDataset2D] = []:
	set(value):
		_disconnect_datasets()
		datasets = value
		_connect_datasets()
		if not _batching_changes:
			emit_changed()

var _batching_changes := false


func _init(
		category_labels: PackedStringArray = PackedStringArray(),
		series: Array[ChartDataset2D] = []
) -> void:
	labels = category_labels
	datasets = series
	_connect_datasets()


func finite_value_range(visible_only: bool = true) -> Variant:
	var found := false
	var minimum := INF
	var maximum := -INF
	for dataset in datasets:
		if dataset == null or (visible_only and not dataset.visible):
			continue
		for value in dataset.values:
			if not is_finite(value):
				continue
			found = true
			minimum = minf(minimum, value)
			maximum = maxf(maximum, value)
	return Vector2(minimum, maximum) if found else null


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var category_labels_seen := {}
	for index in labels.size():
		var category_label := labels[index]
		if category_labels_seen.has(category_label):
			errors.append(
				"Duplicate category label '%s' at index %d." \
				% [category_label, index])
		else:
			category_labels_seen[category_label] = true

	var dataset_labels_seen := {}
	for index in datasets.size():
		var dataset := datasets[index]
		if dataset == null:
			errors.append("Dataset at index %d is null." % index)
			continue
		if dataset.label.is_empty():
			errors.append("Dataset at index %d has an empty label." % index)
		elif dataset_labels_seen.has(dataset.label):
			errors.append(
				"Duplicate dataset label '%s' at index %d." \
				% [dataset.label, index])
		else:
			dataset_labels_seen[dataset.label] = true
		if dataset.values.size() != labels.size():
			errors.append(
				"Dataset '%s' has %d values for %d labels." \
				% [dataset.label, dataset.values.size(), labels.size()])
	return errors


## Adds one shared category and one value per dataset. Missing keys become NAN
## gaps. Invalid input rejects the complete append without partial mutation.
func append_sample(category_label: String, values_by_dataset: Dictionary) -> Error:
	if not validation_errors().is_empty() or labels.has(category_label):
		return ERR_INVALID_DATA
	var known_labels := {}
	for dataset in datasets:
		known_labels[dataset.label] = true
	for key in values_by_dataset:
		if not known_labels.has(str(key)):
			return ERR_INVALID_PARAMETER

	var next_values: Array[PackedFloat32Array] = []
	for dataset in datasets:
		var values := dataset.values.duplicate()
		var value: float = NAN
		if values_by_dataset.has(dataset.label):
			var candidate: Variant = values_by_dataset[dataset.label]
			if not candidate is int and not candidate is float:
				return ERR_INVALID_PARAMETER
			value = float(candidate)
		values.append(value)
		next_values.append(values)

	var next_labels := labels.duplicate()
	next_labels.append(category_label)
	_batching_changes = true
	labels = next_labels
	for index in datasets.size():
		datasets[index].values = next_values[index]
	_batching_changes = false
	emit_changed()
	return OK


func _connect_datasets() -> void:
	for dataset in datasets:
		if dataset != null and not dataset.changed.is_connected(_on_dataset_changed):
			dataset.changed.connect(_on_dataset_changed)


func _disconnect_datasets() -> void:
	for dataset in datasets:
		if dataset != null and dataset.changed.is_connected(_on_dataset_changed):
			dataset.changed.disconnect(_on_dataset_changed)


func _on_dataset_changed() -> void:
	if not _batching_changes:
		emit_changed()
