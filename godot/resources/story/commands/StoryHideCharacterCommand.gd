extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryHideCharacterCommand

var character_id: String = ""
var side_override: String = ""
var exit_effect: String = ""
var exit_to: String = ""
var exit_duration: float = 0.0
var exit_distance: float = 200.0
var wait_for_exit: bool = false
var wait_after: float = 0.0

func execute(scene):
	return scene.hide_character_entry(self)
