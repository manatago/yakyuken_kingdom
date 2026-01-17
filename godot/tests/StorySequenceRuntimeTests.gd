extends TestSuite
class_name StorySequenceRuntimeTests

const StorySequence := preload("res://resources/story/StorySequence.gd")
const StoryLineCommand := preload("res://resources/story/commands/StoryLineCommand.gd")
const MockStoryScene := preload("res://tests/mocks/MockStoryScene.gd")
const MockDialogueEntry := preload("res://tests/mocks/MockDialogueEntry.gd")

func get_name() -> String:
	return "StorySequence"

func get_tests() -> Array:
	return [
		{"name": "line_entry_calls_scene", "callable": Callable(self, "_line_entry_calls_scene")},
		{"name": "sequence_runs_all_entries", "callable": Callable(self, "_sequence_runs_all_entries")},
		{"name": "sequence_awaits_signal_entries", "callable": Callable(self, "_sequence_awaits_signal_entries")}
	]

func _line_entry_calls_scene() -> bool:
	var scene := MockStoryScene.new()
	var entry := StoryLineCommand.new()
	scene.play_line_result = "ok"
	var result = entry.execute(scene)
	return expect_true(scene.play_line_calls.size() == 1 and scene.play_line_calls[0] == entry, "play_line should be called with the entry") and expect_equals(result, "ok", "apply should return the scene result")

func _sequence_runs_all_entries() -> bool:
	var entry_a := MockDialogueEntry.new()
	entry_a.identifier = "A"
	var entry_b := MockDialogueEntry.new()
	entry_b.identifier = "B"
	var sequence := StorySequence.new()
	sequence.entries = [entry_a, entry_b]
	await sequence.play(MockStoryScene.new())
	return expect_true(entry_a.applied and entry_b.applied, "All entries should be applied")

func _sequence_awaits_signal_entries() -> bool:
	var signal_entry := MockDialogueEntry.new()
	signal_entry.returns_signal = true
	var sequence := StorySequence.new()
	sequence.entries = [signal_entry]
	await sequence.play(MockStoryScene.new())
	return expect_true(signal_entry.signal_emitted, "Sequence should await signal entries")
