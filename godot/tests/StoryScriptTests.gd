extends TestSuite
class_name StoryScriptTests

const StoryScriptResource := preload("res://resources/story/DefaultStory.gd")
const StoryBackgroundCommand := preload("res://resources/story/commands/StoryBackgroundCommand.gd")
const StoryLineCommand := preload("res://resources/story/commands/StoryLineCommand.gd")

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
		},
		{
			"name": "stage_intro_has_matilda_lines",
			"callable": Callable(self, "_stage_intro_has_matilda_lines")
		}
	]

func _characters_are_registered() -> bool:
	var story_script: StoryScript = StoryScriptResource.new()
	var characters: Dictionary = story_script.get_cast().all_characters()
	if not expect_false(characters.is_empty(), "Character library should not be empty"):
		return false
	for char_id in characters.keys():
		var data: StoryCharacter = characters[char_id]
		if not expect_equals(data.id, char_id, "Character id should match dictionary key"):
			return false
	return true

func _sequence_returns_dialogue_sequence() -> bool:
	var story_script: StoryScript = StoryScriptResource.new()
	var sequence = story_script.get_sequence("battle_draw")
	return expect_true(sequence is StorySequence, "get_sequence should return a StorySequence")

func _prologue_has_entries() -> bool:
	var story_script: StoryScript = StoryScriptResource.new()
	var sequence = story_script.get_sequence("prologue")
	if not expect_true(sequence is StorySequence, "Prologue should return StorySequence"):
		return false
	return expect_true(sequence.entries.size() > 0, "Prologue sequence must contain entries")

func _prologue_has_main_lines() -> bool:
	var story_script: StoryScript = StoryScriptResource.new()
	var sequence = story_script.get_sequence("prologue")
	if not expect_true(sequence is StorySequence, "Prologue should return StorySequence"):
		return false
	for entry in sequence.entries:
		if entry is StoryLineCommand and entry.speaker_id == "main":
			return true
	return fail("Prologue should contain at least one line for main")

func _prologue_has_background_switches() -> bool:
	var story_script: StoryScript = StoryScriptResource.new()
	var sequence = story_script.get_sequence("prologue")
	if not expect_true(sequence is StorySequence, "Prologue should return StorySequence"):
		return false
	for entry in sequence.entries:
		if entry is StoryBackgroundCommand:
			return true
	return fail("Prologue should include at least one background entry")

func _stage_intro_has_matilda_lines() -> bool:
	var story_script: StoryScript = StoryScriptResource.new()
	var sequence = story_script.get_sequence("stage1_intro")
	if not expect_true(sequence is StorySequence, "Stage intro should return StorySequence"):
		return false
	for entry in sequence.entries:
		if entry is StoryLineCommand and entry.speaker_id == "matilda":
			return true
	return fail("Stage1 intro should contain lines for matilda")
