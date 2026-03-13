extends TestSuite
class_name StorySequenceRuntimeTests

const Cmd := preload("res://story/StoryCommands.gd")
const MockStoryScene := preload("res://tests/mocks/MockStoryScene.gd")

func get_name() -> String:
	return "StorySequence"

func get_tests() -> Array:
	return [
		{"name": "line_entry_calls_scene", "callable": Callable(self, "_line_entry_calls_scene")},
	]

func _line_entry_calls_scene() -> bool:
	var scene := MockStoryScene.new()
	var entry := Cmd.Line.new()
	scene.play_line_result = "ok"
	var result = entry.execute(scene)
	return expect_true(scene.play_line_calls.size() == 1 and scene.play_line_calls[0] == entry, "play_line should be called with the entry") and expect_equals(result, "ok", "apply should return the scene result")
