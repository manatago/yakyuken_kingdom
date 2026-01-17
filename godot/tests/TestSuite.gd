extends RefCounted
class_name TestSuite

var _context = null

func set_context(ctx):
	_context = ctx

func get_context():
	return _context

func get_name() -> String:
	return get_class()

func get_tests() -> Array:
	return []

func before_each() -> void:
	pass

func after_each() -> void:
	pass

func expect_true(condition: bool, message := "") -> bool:
	if condition:
		return true
	return _fail(message if not message.is_empty() else "Expected condition to be true")

func expect_false(condition: bool, message := "") -> bool:
	return expect_true(not condition, message if not message.is_empty() else "Expected condition to be false")

func expect_equals(actual, expected, message := "") -> bool:
	if actual == expected:
		return true
	var display := message if not message.is_empty() else "Expected %s but got %s" % [expected, actual]
	return _fail(display)

func fail(message: String) -> bool:
	return _fail(message)

func _fail(message: String) -> bool:
	push_error("[TEST] %s" % message)
	return false
