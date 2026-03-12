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
var portrait_scale: float = 0.0  # 0 = use character default
var transition: String = ""  # "cross_fade"
var transition_duration: float = 0.3
var flip: int = -1  # -1 = default (side-based), 0 = no flip, 1 = flip

func execute(scene):
	scene.show_character_command(self)
