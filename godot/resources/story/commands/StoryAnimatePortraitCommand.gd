extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryAnimatePortraitCommand

var character_id: String = ""
var portrait_ids: Array[String] = []
var frame_duration: float = 0.15
var loop_count: int = 0 # 0 = infinite

func execute(scene):
	if scene and scene.has_method("start_portrait_animation"):
		scene.start_portrait_animation(self)
	return null
