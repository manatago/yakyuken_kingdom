extends "res://resources/story/commands/StoryCommand.gd"
class_name StoryShowCharacterCommand

var character_id: String = ""
var portrait_id: String = ""
var side_override: String = ""
var position_mode: String = ""
var position: Vector2 = Vector2.ZERO
var appear_effect: String = ""
var appear_from: String = ""
var appear_duration: float = 0.0
var appear_distance: float = 200.0

func execute(scene):
	scene.show_character_command(self)
