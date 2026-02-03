extends SceneTree

const TestRunner := preload("res://tests/TestRunner.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.name = "TestRunner"
	get_root().add_child(runner)
