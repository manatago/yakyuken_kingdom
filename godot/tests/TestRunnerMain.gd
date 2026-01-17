extends SceneTree

const TestRunner := preload("res://tests/TestRunner.gd")

func _initialize() -> void:
	var root_node := Node.new()
	root_node.name = "TestRoot"
	root_node.add_child(TestRunner.new())
	root = root_node
