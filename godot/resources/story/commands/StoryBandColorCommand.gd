extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryBandColorCommand

var color: Color = Color(0.50, 0.38, 0.18, 0.85)

func execute(scene):
	scene.set_inner_band_color(color)
	return null
