class_name ChartBinner

## Static utility class for histogram binning — API mirrors matplotlib hist().
##
## All methods are static; no instance is needed.
##
## [b]Usage[/b]
## [codeblock]
## var result := ChartBinner.auto_bin(values, 10)
## var edges: Array  = result["edges"]   # n_bins + 1 floats
## var counts: Array = result["counts"]  # n_bins ints
## [/codeblock]


## Automatically bins [param data] into [param n_bins] equal-width buckets.
## Returns [code]{"edges": Array[float], "counts": Array[int]}[/code].
## [param edges] has [code]n_bins + 1[/code] elements; consecutive pairs define each bin.
## The last bin is closed on both sides (includes the maximum value).
static func auto_bin(data: Array[float], n_bins: int = 10) -> Dictionary:
	if data.is_empty() or n_bins <= 0:
		return {"edges": [], "counts": []}

	var min_val: float = data[0]
	var max_val: float = data[0]
	for v in data:
		if v < min_val: min_val = v
		if v > max_val: max_val = v

	# Avoid a zero-width range (all values identical).
	if is_equal_approx(min_val, max_val):
		max_val = min_val + 1.0

	var bin_width: float = (max_val - min_val) / float(n_bins)

	var edges: Array[float] = []
	for i in range(n_bins + 1):
		edges.append(min_val + i * bin_width)

	var counts: Array[int] = []
	counts.resize(n_bins)
	counts.fill(0)

	for v in data:
		var idx: int = int((v - min_val) / bin_width)
		# Clamp so the maximum value falls into the last bin, not out-of-range.
		idx = clampi(idx, 0, n_bins - 1)
		counts[idx] += 1

	return {"edges": edges, "counts": counts}


## Bins [param data] using the explicit [param edges] array (must be sorted, ≥ 2 values).
## Returns [code]{"edges": Array[float], "counts": Array[int]}[/code].
## Values outside [code][edges[0], edges[-1]][/code] are silently ignored.
## The last bin is closed on both sides (includes [code]edges[-1][/code]).
static func manual_bin(data: Array[float], edges: Array[float]) -> Dictionary:
	if data.is_empty() or edges.size() < 2:
		return {"edges": [], "counts": []}

	var n_bins: int = edges.size() - 1
	var lo: float = edges[0]
	var hi: float = edges[n_bins]

	var counts: Array[int] = []
	counts.resize(n_bins)
	counts.fill(0)

	for v in data:
		if v < lo or v > hi:
			continue
		# Linear scan — acceptable for typical chart use (< 100 bins, < 100k points).
		var placed := false
		for i in n_bins:
			var right_edge: float = edges[i + 1]
			# Last bin: closed interval; all others: half-open [left, right).
			if i == n_bins - 1:
				if v <= right_edge:
					counts[i] += 1
					placed = true
					break
			else:
				if v < right_edge:
					counts[i] += 1
					placed = true
					break
		# v == lo and lo == right_edge[0] edge case handled by first bin.
		if not placed and v == lo:
			counts[0] += 1

	return {"edges": edges, "counts": counts}


## Suggests an appropriate bin count for [param data] using Sturges' rule:
## [code]k = ceil(log2(n)) + 1[/code].  Returns 1 for empty or single-element arrays.
## This matches matplotlib's default [code]bins="sturges"[/code] heuristic.
static func suggest_bin_count(data: Array[float]) -> int:
	var n: int = data.size()
	if n <= 1:
		return 1
	return int(ceil(log(float(n)) / log(2.0))) + 1
