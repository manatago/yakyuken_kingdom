extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryMicroMotionCommand

var mode: String = ""
var params: Dictionary = {}

func execute(scene):
	if scene == null:
		return null
	if not scene.has_method("play_micro_motion"):
		return null
	return scene.play_micro_motion(self)
