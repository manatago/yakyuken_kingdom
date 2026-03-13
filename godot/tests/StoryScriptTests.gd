extends TestSuite
class_name StoryScriptTests

const StoryScriptResource := preload("res://resources/story/DefaultStory.gd")
const Cmd := preload("res://resources/story/StoryCommands.gd")

func get_name() -> String:
	return "StoryScript"

func get_tests() -> Array:
	return [
		{
			"name": "characters_are_registered",
			"callable": Callable(self, "_characters_are_registered")
		},
		{
			"name": "sequence_returns_dialogue_sequence",
			"callable": Callable(self, "_sequence_returns_dialogue_sequence")
		},
		{
			"name": "prologue_has_entries",
			"callable": Callable(self, "_prologue_has_entries")
		},
		{
			"name": "prologue_has_main_lines",
			"callable": Callable(self, "_prologue_has_main_lines")
		},
		{
			"name": "prologue_has_background_switches",
			"callable": Callable(self, "_prologue_has_background_switches")
		}
	]

func _characters_are_registered() -> bool:
	var story_script: DefaultStory = StoryScriptResource.new()
	var characters: Dictionary = story_script.get_cast()
	if not expect_false(characters.is_empty(), "Character library should not be empty"):
		return false
	for char_id in characters.keys():
		var data: StoryCharacter = characters[char_id]
		if not expect_equals(data.id, char_id, "Character id should match dictionary key"):
			return false
	return true

func _sequence_returns_dialogue_sequence() -> bool:
	var story_script: DefaultStory = StoryScriptResource.new()
	var sequence = story_script.get_sequence("prologue")
	return expect_true(sequence is Cmd.Sequence, "get_sequence should return a Cmd.Sequence")

func _prologue_has_entries() -> bool:
	var story_script: DefaultStory = StoryScriptResource.new()
	var sequence = story_script.get_sequence("prologue")
	if not expect_true(sequence is Cmd.Sequence, "Prologue should return Cmd.Sequence"):
		return false
	return expect_true(sequence.entries.size() > 0, "Prologue sequence must contain entries")

func _prologue_has_main_lines() -> bool:
	var story_script: DefaultStory = StoryScriptResource.new()
	var sequence = story_script.get_sequence("prologue")
	if not expect_true(sequence is Cmd.Sequence, "Prologue should return Cmd.Sequence"):
		return false
	for entry in sequence.entries:
		if entry is Cmd.Line and entry.speaker_id == "main":
			return true
		if entry is Cmd.Band and entry.speaker_id == "main":
			return true
	return fail("Prologue should contain at least one line or band for main")

func _prologue_has_background_switches() -> bool:
	var story_script: DefaultStory = StoryScriptResource.new()
	var sequence = story_script.get_sequence("prologue")
	if not expect_true(sequence is Cmd.Sequence, "Prologue should return Cmd.Sequence"):
		return false
	for entry in sequence.entries:
		if entry is Cmd.Background:
			return true
	return fail("Prologue should include at least one background entry")


