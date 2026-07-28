@tool
class_name ChartData2D
extends Resource

## Shared x-axis labels and parallel numeric datasets.

@export var labels := PackedStringArray():
	set(value):
		labels = value
		emit_changed()
@export var datasets: Array[ChartDataset2D] = []:
	set(value):
		_disconnect_datasets()
		datasets = value
		_connect_datasets()
		emit_changed()


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


func _connect_datasets() -> void:
	for dataset in datasets:
		if dataset != null and not dataset.changed.is_connected(_on_dataset_changed):
			dataset.changed.connect(_on_dataset_changed)


func _disconnect_datasets() -> void:
	for dataset in datasets:
		if dataset != null and dataset.changed.is_connected(_on_dataset_changed):
			dataset.changed.disconnect(_on_dataset_changed)


func _on_dataset_changed() -> void:
	emit_changed()
