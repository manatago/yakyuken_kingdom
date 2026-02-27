extends Resource
class_name StoryCharacter

@export var id: String = ""
@export var display_name: String = ""
@export var default_side: String = "left"
@export var default_portrait: String = ""
@export var portraits: Dictionary = {}
@export var display_scale: float = 1.0
@export var display_offset_y: float = 0.0

func resolve_side(side_override: String) -> String:
	return side_override if not side_override.is_empty() else default_side

func get_portrait_path(portrait_id: String) -> String:
	var resolved_id := portrait_id if not portrait_id.is_empty() else default_portrait
	if resolved_id.begins_with("res://"):
		return resolved_id
	return portraits.get(resolved_id, "")
