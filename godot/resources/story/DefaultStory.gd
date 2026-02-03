extends "res://resources/story/StoryScript.gd"
class_name DefaultStory

const StoryCharacterResource := preload("res://resources/story/StoryCharacter.gd")
const PrologueChapterScript := preload("res://resources/story/chapters/PrologueChapter.gd")
const Stage1ChapterScript := preload("res://resources/story/chapters/Stage1Chapter.gd")
const MicroMotionDemoChapterScript := preload("res://resources/story/chapters/MicroMotionDemoChapter.gd")

const ENABLE_MICRO_MOTION_DEMO := true # デモが不要な場合は false にするか、_chapters から削除してください。

var _chapters: Array = []

func _init() -> void:
	var cast := StoryCast.new()
	cast.add_characters([
		_character(
			"main",
			"サトシ",
			"Default",
			{
				"Default": "res://assets/characters/char01-001_smile.png",
				"default_smile": "res://assets/characters/char01-001_smile.png",
				"default_surprise": "res://assets/characters/char01-002_surprise.png",
				"default_annoyed": "res://assets/characters/char01-003_annoyed.png",
				"default_thinking": "res://assets/characters/char01-004_thinking.png",
				"default_smirk": "res://assets/characters/char01-005_smirk.png",
				"default_surprise2": "res://assets/characters/char01-006_surprise2.png",
				"default_white_coat": "res://assets/characters/char01-007_white_coat.png",
				"default_white_coat_surprise": "res://assets/characters/char01-008_white_coat_surprise.png",
				"default_white_coat_surprise_closed_eyes": "res://assets/characters/char01-008-2_white_coat_surprise.png",
				"teleport_white_coat": "res://assets/characters/char01-009_teleport_white_coat.png",
				"teleport_naked": "res://assets/characters/char01-010_teleport_naked.png",
				"naked": "res://assets/characters/char01-011_naked.png",
				"isekai_anxious": "res://assets/characters/char01-012_isekai_anxious.png",
			}
		),
		_character(
			"heroine",
			"みのり",
			"default",
			{
				"default": "res://assets/characters/char02-1_childhood_friend.png"
			}
		),
		_character(
			"guard",
			"番兵",
			"default",
			{
				"default": "res://assets/characters/char03-1_guard.png"
			}
		),
		_character(
			"matilda",
			"マチルダ",
			"default",
			{
				"default": "res://assets/characters/char04-1_prison_guard.png"
			}
		)
	])
	set_cast(cast)

	_build_chapters(cast)
	_register_chapters(cast)

func _build_chapters(cast: StoryCast) -> void:
	_chapters.clear()
	if ENABLE_MICRO_MOTION_DEMO and MicroMotionDemoChapterScript:
		_chapters.append(MicroMotionDemoChapterScript.new())
	_chapters.append(PrologueChapterScript.new())
	_chapters.append(Stage1ChapterScript.new())

func _register_chapters(cast: StoryCast) -> void:
	for chapter in _chapters:
		if chapter:
			chapter.register_sequences(self, cast)

func _character(id: String, display_name: String, default_portrait: String, portraits: Dictionary, default_side: String = "") -> StoryCharacter:
	var data := StoryCharacterResource.new()
	data.id = id
	data.display_name = display_name
	data.default_side = default_side
	data.default_portrait = default_portrait
	data.portraits = portraits
	return data
