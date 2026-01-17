extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryLineCommand

var speaker_id: String = ""
var text: String = ""
var portrait_id: String = ""
var side_override: String = ""
var offset: Vector2 = Vector2.ZERO
var wait_for_input: bool = true
var min_duration: float = 0.0
var duration: float = 0.5

func execute(scene):
	return scene.play_line(self)
