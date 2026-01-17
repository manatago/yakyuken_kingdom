extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryStopPortraitAnimationCommand

var character_id: String = ""

func execute(scene):
	if scene and scene.has_method("stop_portrait_animation"):
		scene.stop_portrait_animation(self)
	return null
