extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# suggest_bin_count
# ---------------------------------------------------------------------------

func test_suggest_bin_count_empty_returns_one() -> void:
	assert_int(ChartBinner.suggest_bin_count([])).is_equal(1)


func test_suggest_bin_count_single_returns_one() -> void:
	assert_int(ChartBinner.suggest_bin_count([1.0])).is_equal(1)


func test_suggest_bin_count_two() -> void:
	# log2(2) = 1 → ceil(1) + 1 = 2
	assert_int(ChartBinner.suggest_bin_count([1.0, 2.0])).is_equal(2)


func test_suggest_bin_count_eight() -> void:
	# log2(8) = 3 → ceil(3) + 1 = 4
	var data: Array[float] = []
	for i in 8: data.append(float(i))
	assert_int(ChartBinner.suggest_bin_count(data)).is_equal(4)


func test_suggest_bin_count_thirty_two() -> void:
	# log2(32) = 5 → ceil(5) + 1 = 6
	var data: Array[float] = []
	for i in 32: data.append(float(i))
	assert_int(ChartBinner.suggest_bin_count(data)).is_equal(6)


# ---------------------------------------------------------------------------
# auto_bin
# ---------------------------------------------------------------------------

func test_auto_bin_empty_returns_empty() -> void:
	var result := ChartBinner.auto_bin([], 5)
	assert_array(result["edges"]).has_size(0)
	assert_array(result["counts"]).has_size(0)


func test_auto_bin_zero_bins_returns_empty() -> void:
	var result := ChartBinner.auto_bin([1.0, 2.0, 3.0], 0)
	assert_array(result["edges"]).has_size(0)


func test_auto_bin_has_n_plus_one_edges() -> void:
	var data: Array[float] = [0.0, 1.0, 2.0, 3.0, 4.0]
	var result := ChartBinner.auto_bin(data, 5)
	assert_array(result["edges"]).has_size(6)


func test_auto_bin_has_n_counts() -> void:
	var data: Array[float] = [0.0, 1.0, 2.0, 3.0, 4.0]
	var result := ChartBinner.auto_bin(data, 5)
	assert_array(result["counts"]).has_size(5)


func test_auto_bin_counts_sum_equals_total() -> void:
	var data: Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
	var result := ChartBinner.auto_bin(data, 4)
	var total := 0
	for c: int in result["counts"]:
		total += c
	assert_int(total).is_equal(data.size())


func test_auto_bin_single_value_all_counted() -> void:
	var result := ChartBinner.auto_bin([42.0], 3)
	var total := 0
	for c: int in result["counts"]:
		total += c
	assert_int(total).is_equal(1)


func test_auto_bin_identical_values_all_counted() -> void:
	# Identical values trigger the zero-width guard (max_val += 1.0).
	var data: Array[float] = [3.0, 3.0, 3.0, 3.0]
	var result := ChartBinner.auto_bin(data, 3)
	var total := 0
	for c: int in result["counts"]:
		total += c
	assert_int(total).is_equal(4)


func test_auto_bin_max_value_included() -> void:
	# Maximum value must land in the last bin (index clamped), not overflow.
	var data: Array[float] = [0.0, 10.0]
	var result := ChartBinner.auto_bin(data, 5)
	var total := 0
	for c: int in result["counts"]:
		total += c
	assert_int(total).is_equal(2)


# ---------------------------------------------------------------------------
# manual_bin
# ---------------------------------------------------------------------------

func test_manual_bin_empty_data_returns_empty() -> void:
	var result := ChartBinner.manual_bin([], [0.0, 1.0, 2.0])
	assert_array(result["edges"]).has_size(0)


func test_manual_bin_too_few_edges_returns_empty() -> void:
	var result := ChartBinner.manual_bin([1.0, 2.0], [0.0])
	assert_array(result["edges"]).has_size(0)


func test_manual_bin_basic_placement() -> void:
	# Bins: [0,1), [1,2), [2,3]
	var edges: Array[float] = [0.0, 1.0, 2.0, 3.0]
	var data:  Array[float] = [0.5, 1.5, 2.5]
	var result := ChartBinner.manual_bin(data, edges)
	assert_int(result["counts"][0]).is_equal(1)
	assert_int(result["counts"][1]).is_equal(1)
	assert_int(result["counts"][2]).is_equal(1)


func test_manual_bin_out_of_range_ignored() -> void:
	# -1 and 11 are outside [0,10]; 3 → bin 0 [0,5); 5 → bin 1 [5,10]
	var edges: Array[float] = [0.0, 5.0, 10.0]
	var data:  Array[float] = [-1.0, 3.0, 5.0, 11.0]
	var result := ChartBinner.manual_bin(data, edges)
	assert_int(result["counts"][0]).is_equal(1)   # 3.0
	assert_int(result["counts"][1]).is_equal(1)   # 5.0


func test_manual_bin_max_value_in_last_bin() -> void:
	# Exact upper edge (edges[-1]) belongs to the last (closed) bin.
	var edges: Array[float] = [0.0, 5.0, 10.0]
	var data:  Array[float] = [10.0]
	var result := ChartBinner.manual_bin(data, edges)
	assert_int(result["counts"][0]).is_equal(0)
	assert_int(result["counts"][1]).is_equal(1)


func test_manual_bin_total_excludes_out_of_range() -> void:
	# 7.0 > edges[-1]=6.0 → excluded; other 7 values are in range.
	var edges: Array[float] = [0.0, 2.0, 4.0, 6.0]
	var data:  Array[float] = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
	var result := ChartBinner.manual_bin(data, edges)
	var total := 0
	for c: int in result["counts"]:
		total += c
	assert_int(total).is_equal(7)
