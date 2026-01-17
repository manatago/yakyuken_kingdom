extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryBackgroundCommand

var path: String = ""
var fade: float = 0.0

func execute(scene):
	scene.show_background_entry(self)
