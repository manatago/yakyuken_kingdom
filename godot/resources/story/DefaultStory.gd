extends "res://resources/story/StoryScript.gd"
class_name DefaultStory

const StoryCharacterResource := preload("res://resources/story/StoryCharacter.gd")
const PrologueChapterScript := preload("res://resources/story/chapters/PrologueChapter.gd")
const Stage1ChapterScript := preload("res://resources/story/chapters/Stage1Chapter.gd")
const DemoChapterScript := preload("res://resources/story/chapters/DemoChapter.gd")

const ENABLE_DEMO := false # デモが不要な場合は false にするか、_chapters から削除してください。

var _chapters: Array = []

func _init() -> void:
	var cast := StoryCast.new()
	cast.add_characters([
		_character("main", "サトシ",
			"res://assets/characters/char01-001_smile.png", {}),
		_character("heroine", "みのり",
			"res://assets/characters/char02-1_childhood_friend.png", {}, "", 1.45, 40.0),
		_character("guard", "番兵",
			"res://assets/characters/char03-1_guard.png", {}),
		_character("matilda", "マチルダ",
			"res://assets/characters/char04-1_prison_guard.png", {})
	])
	set_cast(cast)

	_build_chapters(cast)
	_register_chapters(cast)

func _build_chapters(cast: StoryCast) -> void:
	_chapters.clear()
	if ENABLE_DEMO and DemoChapterScript:
		_chapters.append(DemoChapterScript.new())
	_chapters.append(PrologueChapterScript.new())
	_chapters.append(Stage1ChapterScript.new())

func _register_chapters(cast: StoryCast) -> void:
	for chapter in _chapters:
		if chapter:
			chapter.register_sequences(self, cast)

func _character(id: String, display_name: String, default_portrait: String, portraits: Dictionary, default_side: String = "", p_display_scale: float = 1.0, p_display_offset_y: float = 0.0) -> StoryCharacter:
	var data := StoryCharacterResource.new()
	data.id = id
	data.display_name = display_name
	data.default_side = default_side
	data.default_portrait = default_portrait
	data.portraits = portraits
	data.display_scale = p_display_scale
	data.display_offset_y = p_display_offset_y
	return data
