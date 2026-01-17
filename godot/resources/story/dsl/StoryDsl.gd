extends RefCounted
class_name StoryDsl

const StoryCommand := preload("res://resources/story/commands/StoryCommand.gd")
const StoryLineCommand := preload("res://resources/story/commands/StoryLineCommand.gd")
const StoryBackgroundCommand := preload("res://resources/story/commands/StoryBackgroundCommand.gd")
const StoryPauseCommand := preload("res://resources/story/commands/StoryPauseCommand.gd")
const StoryShowCharacterCommand := preload("res://resources/story/commands/StoryShowCharacterCommand.gd")
const StoryBandCommand := preload("res://resources/story/commands/StoryBandCommand.gd")
const StoryHideDialogueCommand := preload("res://resources/story/commands/StoryHideDialogueCommand.gd")
const StoryAnimatePortraitCommand := preload("res://resources/story/commands/StoryAnimatePortraitCommand.gd")
const StoryStopPortraitAnimationCommand := preload("res://resources/story/commands/StoryStopPortraitAnimationCommand.gd")
const StorySequence := preload("res://resources/story/StorySequence.gd")
const StoryCharacterHandle := preload("res://resources/story/dsl/StoryCharacterHandle.gd")

var _cast: StoryCast
var _protagonist_id: String = ""

func _init(cast: StoryCast) -> void:
	_cast = cast

func character(id: String) -> StoryCharacterHandle:
	return StoryCharacterHandle.new(self, id)

func line(character_id: String, text: String, extra: Dictionary = {}):
	var entry := StoryLineCommand.new()
	entry.speaker_id = character_id
	entry.text = text
	entry.portrait_id = extra.get("portrait", "")
	entry.side_override = extra.get("side", "")
	entry.offset = extra.get("offset", Vector2.ZERO)
	entry.wait_for_input = extra.get("wait_for_input", true)
	entry.min_duration = extra.get("min_duration", 0.0)
	entry.duration = extra.get("duration", 0.5)
	return entry

func aside(text: String, extra: Dictionary = {}):
	return line("", text, extra)

func background(path: String, fade := 0.0):
	var entry := StoryBackgroundCommand.new()
	entry.path = path
	entry.fade = fade
	return entry

func pause(duration: float):
	var entry := StoryPauseCommand.new()
	entry.duration = duration
	return entry

func show_character(character_id: String, extra: Dictionary = {}):
	var entry := StoryShowCharacterCommand.new()
	entry.character_id = character_id
	entry.portrait_id = extra.get("portrait", "")
	entry.side_override = extra.get("side", "")
	entry.position_mode = extra.get("position_mode", "")
	entry.position = extra.get("position", Vector2.ZERO)
	entry.appear_effect = extra.get("appear_effect", "")
	entry.appear_from = extra.get("appear_from", "")
	entry.appear_duration = extra.get("appear_duration", 0.0)
	entry.appear_distance = extra.get("appear_distance", 200.0)
	return entry

func hide_character(character_id: String, extra: Dictionary = {}):
	var entry := StoryHideCharacterCommand.new()
	entry.character_id = character_id
	entry.side_override = extra.get("side", "")
	entry.exit_effect = extra.get("exit_effect", "")
	entry.exit_to = extra.get("exit_to", "")
	entry.exit_duration = extra.get("exit_duration", 0.0)
	entry.exit_distance = extra.get("exit_distance", 200.0)
	entry.wait_for_exit = extra.get("wait_for_exit", false)
	entry.wait_after = extra.get("wait_after", 0.0)
	return entry

func band(text: String, extra: Dictionary = {}):
	return _band_command(
		true,
		text,
		extra.get("speaker_id", ""),
		extra.get("wait_for_input", false),
		extra.get("min_duration", 0.0),
		extra.get("portrait", ""),
		extra.get("side", "")
	)

func band_show():
	return _band_command(true)

func band_narrator(text: String, wait_for_input := true, min_duration := 0.0):
	return _band_command(true, text, "narrator", wait_for_input, min_duration)

func band_protagonist(text: String, wait_for_input := true, min_duration := 0.0):
	return _band_command(true, text, _resolve_protagonist_id(), wait_for_input, min_duration)

func band_hide():
	return _band_command(false)

func band_clear_text():
	return _band_command(true, "", "", false, 0.0, "", "", true)

func hide_dialogue():
	return StoryHideDialogueCommand.new()

func animate_portrait(character_id: String, portraits: Array, frame_duration: float = 0.15, loop_count: int = 0):
	var entry := StoryAnimatePortraitCommand.new()
	entry.character_id = character_id
	var frames: Array[String] = []
	for item in portraits:
		if typeof(item) == TYPE_STRING:
			frames.append(item)
	entry.portrait_ids = frames
	entry.frame_duration = frame_duration
	entry.loop_count = loop_count
	return entry

func stop_portrait_animation(character_id: String):
	var entry := StoryStopPortraitAnimationCommand.new()
	entry.character_id = character_id
	return entry

func set_protagonist_id(id: String):
	if id.is_empty():
		return
	_protagonist_id = id

func sequence(sequence_id: String, commands: Array[StoryCommand]) -> StorySequence:
	var seq := StorySequence.new()
	seq.id = sequence_id
	seq.entries = commands
	return seq

func build(sequence_id: String, builder_func: Callable) -> StorySequence:
	var commands: Array[StoryCommand] = []
	var proxy := _CommandCollector.new(self, commands)
	if builder_func.is_valid():
		builder_func.call(proxy)
	return sequence(sequence_id, commands)

class _CommandCollector:
	var _dsl: StoryDsl
	var _commands: Array[StoryCommand]

	func _init(dsl: StoryDsl, commands: Array[StoryCommand]) -> void:
		_dsl = dsl
		_commands = commands

	func _add_command(command):
		if command:
			_commands.append(command)

	func character(id: String) -> StoryCharacterHandle:
		return StoryCharacterHandle.new(_dsl, id, Callable(self, "_add_command"))

	func background(path: String, fade := 0.0):
		_add_command(_dsl.background(path, fade))

	func pause(duration: float):
		_add_command(_dsl.pause(duration))

	func line(character_id: String, text: String, extra: Dictionary = {}):
		_add_command(_dsl.line(character_id, text, extra))

	func aside(text: String, extra: Dictionary = {}):
		_add_command(_dsl.aside(text, extra))

	func show_character(character_id: String, extra: Dictionary = {}):
		_add_command(_dsl.show_character(character_id, extra))

	func band(text: String, extra: Dictionary = {}):
		_add_command(_dsl.band(text, extra))

	func hide_band():
		_add_command(_dsl.band_hide())

	func show_band():
		_add_command(_dsl.band_show())

	func narrator_band(text: String):
		_add_command(_dsl.band_narrator(text))

	func protagonist_band(text: String):
		_add_command(_dsl.band_protagonist(text))

	func set_protagonist(character_id: String):
		_dsl.set_protagonist_id(character_id)

	func clear_band_text():
		_add_command(_dsl.band_clear_text())

	func hide_dialogue():
		_add_command(_dsl.hide_dialogue())

	func animate_portrait(character_id: String, portraits: Array, frame_duration: float = 0.15, loop_count: int = 0):
		_add_command(_dsl.animate_portrait(character_id, portraits, frame_duration, loop_count))

	func stop_portrait_animation(character_id: String):
		_add_command(_dsl.stop_portrait_animation(character_id))

func get_cast() -> StoryCast:
	return _cast

func _band_command(visible: bool, text: String = "", speaker_id: String = "", wait_for_input: bool = false, min_duration: float = 0.0, portrait_id: String = "", side_override: String = "", clear_text: bool = false):
	var entry := StoryBandCommand.new()
	entry.visible = visible
	entry.text = text
	entry.speaker_id = speaker_id
	entry.wait_for_input = wait_for_input
	entry.min_duration = min_duration
	entry.portrait_id = portrait_id
	entry.side_override = side_override
	entry.clear_text = clear_text
	return entry

func _resolve_protagonist_id() -> String:
	if not _protagonist_id.is_empty():
		return _protagonist_id
	if _cast and _cast.has_character("main"):
		return "main"
	var all_chars := _cast.all_characters()
	for id in all_chars.keys():
		return id
	return ""
