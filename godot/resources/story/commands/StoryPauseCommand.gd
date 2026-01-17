extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryPauseCommand

var duration: float = 0.0

func execute(scene):
	return scene.pause_entry(self)
