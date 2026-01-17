extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryBandCommand

var visible: bool = true
var speaker_id: String = ""
var text: String = ""
var wait_for_input: bool = false
var min_duration: float = 0.0
var portrait_id: String = ""
var side_override: String = ""
var clear_text: bool = false

func execute(scene):
	return scene.apply_band_command(self)
