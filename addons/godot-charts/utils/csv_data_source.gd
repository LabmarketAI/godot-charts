@tool
class_name CSVDataSource
extends ChartDataSource

## A [ChartDataSource] that loads and parses a CSV file from disk.
##
## [b]Expected CSV format[/b]
##
## The first row is treated as a header.  If the first column's data rows are
## non-numeric, that column is used as category labels; otherwise row indices
## are used and all columns become datasets.
##
## Label-column format (first column = category names):
## [codeblock]
## ,Revenue,Expenses
## Jan,1.2,0.9
## Feb,2.8,1.4
## Mar,2.3,2.0
## [/codeblock]
##
## Data-only format (all columns are datasets, rows indexed 0, 1, 2 …):
## [codeblock]
## Revenue,Expenses
## 1.2,0.9
## 2.8,1.4
## 2.3,2.0
## [/codeblock]
##
## [b]Inspector usage[/b]
## Set [member file_path] in the inspector — the file is loaded immediately and
## any connected chart redraws.  Relative paths are resolved from the project
## root ([code]res://[/code]).  Absolute paths are also accepted.
##
## [b]GDScript usage[/b]
## [codeblock]
## var src := CSVDataSource.new()
## if src.load_file("res://data/sales.csv"):
##     my_chart.data_source = src
## [/codeblock]

## Path to the CSV file.  Setting this property loads the file immediately.
@export_file("*.csv") var file_path: String = "" :
	set(v):
		file_path = v
		if v != "":
			load_file(v)

# Cached result of the last successful parse.
var _data: Dictionary = {}


func get_data() -> Dictionary:
	return _data


## Load and parse the CSV at [param path].
## Returns [code]true[/code] on success; pushes an error and returns [code]false[/code]
## on failure.  On success, [signal ChartDataSource.data_updated] is emitted with
## the parsed dictionary so any connected chart redraws immediately.
func load_file(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CSVDataSource: cannot open '%s' (error %d)" % [path, FileAccess.get_open_error()])
		return false

	var lines: Array[String] = []
	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges() != "":
			lines.append(line)
	file.close()

	if lines.size() < 2:
		push_warning("CSVDataSource: '%s' has fewer than 2 non-empty rows; nothing loaded" % path)
		return false

	var header: Array = _split_line(lines[0])
	if header.is_empty():
		push_warning("CSVDataSource: empty header row in '%s'" % path)
		return false

	# Detect whether the first column is a label column (non-numeric data cells).
	var first_data_row: Array = _split_line(lines[1])
	var has_label_col: bool = (
		first_data_row.size() > 0
		and not (first_data_row[0].strip_edges() as String).is_valid_float()
	)

	var dataset_names: Array[String] = []
	var start_col: int = 1 if has_label_col else 0
	for i in range(start_col, header.size()):
		dataset_names.append((header[i] as String).strip_edges())

	if dataset_names.is_empty():
		push_warning("CSVDataSource: no dataset columns found in '%s'" % path)
		return false

	var labels: Array[String] = []
	# One Array[float] per dataset — built in parallel with the row loop.
	var value_cols: Array = []
	for _i in dataset_names.size():
		value_cols.append(PackedFloat64Array())

	for row_idx in range(1, lines.size()):
		var cells: Array = _split_line(lines[row_idx])
		if has_label_col:
			labels.append((cells[0] as String).strip_edges() if cells.size() > 0 else "")
		else:
			labels.append(str(row_idx - 1))

		for ds_idx in dataset_names.size():
			var col: int = ds_idx + start_col
			var raw: String = (cells[col] as String).strip_edges() if col < cells.size() else "0"
			(value_cols[ds_idx] as PackedFloat64Array).append(
				float(raw) if raw.is_valid_float() else 0.0
			)

	var datasets: Array = []
	for ds_idx in dataset_names.size():
		datasets.append({
			"name": dataset_names[ds_idx],
			"values": Array(value_cols[ds_idx]),
		})

	_data = {"labels": Array(labels), "datasets": datasets}
	data_updated.emit(_data)
	return true


## Reload the currently assigned [member file_path].
## Returns [code]false[/code] if no path is set.
func reload() -> bool:
	if file_path == "":
		return false
	return load_file(file_path)


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Split a single CSV line into cells.
## Handles double-quoted fields that may contain commas.
static func _split_line(line: String) -> Array:
	var result: Array = []
	var current: String = ""
	var in_quotes: bool = false
	for ch in line:
		if ch == '"':
			in_quotes = not in_quotes
		elif ch == "," and not in_quotes:
			result.append(current)
			current = ""
		else:
			current += ch
	result.append(current)
	return result
