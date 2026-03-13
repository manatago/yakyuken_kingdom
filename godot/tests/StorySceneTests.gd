extends TestSuite
class_name StorySceneTests

const StoryScenePacked := preload("res://StoryScene.tscn")
const StoryScriptResource := preload("res://resources/story/DefaultStory.gd")
const Cmd := preload("res://resources/story/StoryCommands.gd")

var _story_scene = null
var _story_script = null

func get_name() -> String:
	return "StoryScene"

func get_tests() -> Array:
	return [
		{"name": "show_dialogue_updates_bubbles", "callable": Callable(self, "_show_dialogue_updates_bubbles")},
		{"name": "show_character_applies_texture", "callable": Callable(self, "_show_character_applies_texture")},
		{"name": "hide_character_entry_hides_side", "callable": Callable(self, "_hide_character_entry_hides_side")},
		{"name": "band_dialogue_shows_band_panel", "callable": Callable(self, "_band_dialogue_shows_band_panel")}
	]

func before_each() -> void:
	_story_scene = StoryScenePacked.instantiate()
	_story_scene._ready()
	_story_script = StoryScriptResource.new()
	_story_scene.set_cast(_story_script.get_cast())

func after_each() -> void:
	_story_scene = null
	_story_script = null

func _show_dialogue_updates_bubbles() -> bool:
	var offset := Vector2(12, -6)
	_story_scene.show_dialogue("left", "テストメッセージ", offset)
	var left_bubble = _story_scene.left_bubble
	return (
		expect_true(left_bubble.visible, "Left bubble should be visible")
		and expect_false(_story_scene.right_bubble.visible, "Right bubble should be hidden")
		and expect_equals(left_bubble.text, "テストメッセージ", "Bubble text should match")
		and expect_equals(left_bubble.position, _story_scene.left_bubble_default_pos + offset, "Offset should be applied")
	)

func _show_character_applies_texture() -> bool:
	var char_data = _story_script.get_cast().get("main")
	_story_scene._show_character(char_data, "Default", "left")
	return (
		expect_true(_story_scene.left_char.visible, "Left character should be visible")
		and expect_true(_story_scene.left_char.texture != null, "Texture should be applied")
	)

func _hide_character_entry_hides_side() -> bool:
	var char_data = _story_script.get_cast().get("matilda")
	_story_scene._show_character(char_data, "Default", "right")
	var entry := Cmd.HideCharacter.new()
	entry.character_id = "matilda"
	_story_scene.hide_character_entry(entry)
	return expect_false(_story_scene.right_char.visible, "Right character should be hidden after leave entry")

func _band_dialogue_shows_band_panel() -> bool:
	var band_command := Cmd.Band.new()
	band_command.visible = true
	band_command.speaker_id = "narrator"
	band_command.text = "バンド表示テスト"
	_story_scene.apply_band_command(band_command)
	var band = _story_scene.get_node("DialogueBand")
	var body_label = band.get_node("VBox/BodyLabel")
	return (
		expect_true(band.visible, "Band panel should be visible")
		and expect_equals(body_label.text, band_command.text, "Band text should match")
	)
