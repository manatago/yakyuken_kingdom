extends Node
class_name TestRunner

const TestSuite := preload("res://tests/TestSuite.gd")
const StoryScriptTests := preload("res://tests/StoryScriptTests.gd")
const StorySequenceRuntimeTests := preload("res://tests/StorySequenceRuntimeTests.gd")
const StorySceneTests := preload("res://tests/StorySceneTests.gd")

var _suites := []

func _ready():
	print_rich("[color=purple]TestRunner starting...[/color]")
	_suites = [
		StoryScriptTests.new(),
		StorySequenceRuntimeTests.new(),
		StorySceneTests.new()
	]
	# tree_enteredの後に非同期テストを開始
	_start_tests.call_deferred()

func _start_tests() -> void:
	await _run_all()

func _run_all() -> void:
	var total := 0
	var failed := 0
	print_rich("[color=cyan]Running Godot tests...[/color]")
	for suite in _suites:
		suite.set_context(self)
		print_rich("[color=yellow]Suite: %s[/color]" % suite.get_name())
		var result := await _run_suite(suite)
		total += result.get("total", 0)
		failed += result.get("failed", 0)
	var summary := "Tests: %d, Failed: %d" % [total, failed]
	if failed == 0:
		print_rich("[color=green]%s[/color]" % summary)
	else:
		push_error(summary)
	get_tree().quit(failed)

func _run_suite(suite: TestSuite) -> Dictionary:
	var suite_total := 0
	var suite_failed := 0
	for test_desc in suite.get_tests():
		suite_total += 1
		var name: String = test_desc.get("name", "unnamed_test")
		var callable: Callable = test_desc.get("callable", Callable())
		suite.before_each()
		var passed := false
		if callable.is_valid():
			var result = await _call_test(callable)
			passed = bool(result)
		else:
			push_error("Invalid callable for %s" % name)
		suite.after_each()
		if passed:
			print_rich("[color=green][PASS][/color] %s/%s" % [suite.get_name(), name])
		else:
			suite_failed += 1
			push_error("[FAIL] %s/%s" % [suite.get_name(), name])
	return {
		"total": suite_total,
		"failed": suite_failed
	}

func _call_test(callable: Callable):
	return await callable.call()
