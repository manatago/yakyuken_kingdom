extends "res://resources/story/StoryScript.gd"
class_name DefaultStory

const StoryCharacterResource := preload("res://resources/story/StoryCharacter.gd")
const PrologueChapterScript := preload("res://resources/story/chapters/PrologueChapter.gd")
const Stage1ChapterScript := preload("res://resources/story/chapters/Stage1Chapter.gd")

func _init() -> void:
	var cast := StoryCast.new()
	cast.add_characters([
		_character(
			"main",
			"サトシ",
			"Default",
			{
				"Default": "res://assets/characters/char01-1_main_character.png",
				"Isekai": "res://assets/characters/char01-2_main_character.png",
				"Teleport": "res://assets/characters/char01-3_main_character.png",
				"Naked": "res://assets/characters/char01-4_main_character.png",
				"Surprised": "res://assets/characters/char01-5_main_character.png"
			}
		),
		_character(
			"heroine",
			"みのり",
			"Default",
			{
				"Default": "res://assets/characters/char02-1_childhood_friend.png"
			}
		),
		_character(
			"matilda",
			"マチルダ",
			"Default",
			{
				"Default": "res://assets/characters/char03-1_prison_guard.png"
			}
		)
	])
	set_cast(cast)

	register_sequences([
		PrologueChapterScript.build(cast),
		Stage1ChapterScript.build_intro(cast),
		Stage1ChapterScript.build_win(cast),
		Stage1ChapterScript.build_battle_draw(cast),
		Stage1ChapterScript.build_battle_win(cast),
		Stage1ChapterScript.build_battle_lose(cast)
	])

func _character(id: String, display_name: String, default_portrait: String, portraits: Dictionary, default_side: String = "") -> StoryCharacter:
	var data := StoryCharacterResource.new()
	data.id = id
	data.display_name = display_name
	data.default_side = default_side
	data.default_portrait = default_portrait
	data.portraits = portraits
	return data
