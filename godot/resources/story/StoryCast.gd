extends Resource
class_name StoryCast

var _characters: Dictionary = {}

func add_character(character: StoryCharacter) -> void:
	if character == null:
		return
	if character.id.is_empty():
		push_warning("StoryCharacter is missing id; skipping registration")
		return
	_characters[character.id] = character

func add_characters(characters: Array[StoryCharacter]) -> void:
	for character in characters:
		add_character(character)

func get_character(id: String) -> StoryCharacter:
	return _characters.get(id, null)

func has_character(id: String) -> bool:
	return _characters.has(id)

func all_characters() -> Dictionary:
	return _characters.duplicate(true)
