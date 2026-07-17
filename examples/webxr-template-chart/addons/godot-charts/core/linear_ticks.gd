class_name LinearTicks
extends RefCounted


static func generate(domain_min: float, domain_max: float, target_count: int = 5) -> Array[float]:
	if not is_finite(domain_min) or not is_finite(domain_max) or domain_min >= domain_max:
		return []
	target_count = clampi(target_count, 2, 12)
	var step: float = _nice_step((domain_max - domain_min) / float(target_count - 1))
	var first: float = ceil(domain_min / step) * step
	var last: float = floor(domain_max / step) * step
	var result: Array[float] = []
	var value: float = first
	while value <= last + step * 1.0e-9 and result.size() < 32:
		result.append(0.0 if is_zero_approx(value) else value)
		value += step
	return result


static func format(value: float, step: float) -> String:
	if not is_finite(value) or not is_finite(step) or step <= 0.0:
		return "∅"
	var magnitude := absf(value)
	if magnitude >= 1.0e6 or (magnitude > 0.0 and magnitude < 1.0e-4):
		return "%.3e" % value
	var decimals := clampi(int(ceil(-log(step) / log(10.0))), 0, 8) if step < 1.0 else 0
	return String.num(value, decimals)


static func _nice_step(raw_step: float) -> float:
	var exponent := floor(log(raw_step) / log(10.0))
	var power := pow(10.0, exponent)
	var fraction := raw_step / power
	var nice_fraction := 1.0
	if fraction > 5.0:
		nice_fraction = 10.0
	elif fraction > 2.0:
		nice_fraction = 5.0
	elif fraction > 1.0:
		nice_fraction = 2.0
	return nice_fraction * power
