extends RefCounted
class_name DefaultStory

const StoryDsl := preload("res://story/StoryCommands.gd")
const StoryCharacterResource := preload("res://story/StoryCharacter.gd")
const PrologueChapterScript := preload("res://story/chapters/PrologueChapter.gd")


var _cast: Dictionary = {}  # character_id -> StoryCharacter
var _sequences: Dictionary = {}  # sequence_id -> Cmd.Sequence

func _init() -> void:
	_cast = {
		"main": _character("main", "サトシ", ""),
		"heroine": _character("heroine", "みのり", ""),
		"guard": _character("guard", "番兵", ""),
		"matilda": _character("matilda", "マチルダ", ""),
		"receptionist": _character("receptionist", "受付嬢", ""),
		"passerby_male": _character("passerby_male", "通行人の男性", ""),
		"passerby_female": _character("passerby_female", "通行人の女性", ""),
	}
	_build_chapters()

func _build_chapters() -> void:
	var chapters := [
		PrologueChapterScript.new(),
	]
	for chapter in chapters:
		_register_chapter(chapter)

func _register_chapter(chapter) -> void:
	for definition in chapter.get_sequence_builders():
		var sequence_id: String = definition.get("id", "")
		var builder_name: String = definition.get("builder", "")
		if sequence_id.is_empty() or builder_name.is_empty():
			continue
		if not chapter.has_method(builder_name):
			push_warning("Missing builder method %s" % builder_name)
			continue
		var dsl := StoryDsl.new(_cast)
		var sequence = dsl.build(sequence_id, Callable(chapter, builder_name))
		if sequence:
			_sequences[sequence_id] = sequence

func get_cast() -> Dictionary:
	return _cast

func get_sequence(sequence_id: String):
	return _sequences.get(sequence_id, null)

func get_sequence_ids() -> Array:
	return _sequences.keys()

func _character(id: String, display_name: String, default_portrait: String, default_side: String = "", p_display_scale: float = 1.0, p_display_offset_y: float = 0.0) -> StoryCharacter:
	var data := StoryCharacterResource.new()
	data.id = id
	data.display_name = display_name
	data.default_side = default_side
	data.default_portrait = default_portrait
	data.display_scale = p_display_scale
	data.display_offset_y = p_display_offset_y
	return data
