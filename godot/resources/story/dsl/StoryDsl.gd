extends RefCounted
class_name StoryDsl

# --- Command classes (data) ---

class Base extends Resource:
	func execute(_scene):
		return null

class Line extends Base:
	var speaker_id: String = ""
	var text: String = ""
	var portrait_id: String = ""
	var side_override: String = ""
	var offset: Vector2 = Vector2.ZERO
	var wait_for_input: bool = true
	var min_duration: float = 0.0
	var duration: float = 0.5
	func execute(scene):
		return scene.play_line(self)

class Background extends Base:
	var path: String = ""
	var fade: float = 0.0
	func execute(scene):
		scene.show_background_entry(self)

class Pause extends Base:
	var duration: float = 0.0
	func execute(scene):
		return scene.pause_entry(self)

class ShowCharacter extends Base:
	var character_id: String = ""
	var portrait_id: String = ""
	var side_override: String = ""
	var position_mode: String = ""
	var position: Vector2 = Vector2.ZERO
	var appear_effect: String = ""
	var appear_from: String = ""
	var appear_duration: float = 0.0
	var appear_distance: float = 200.0
	var portrait_scale: float = 0.0
	var transition: String = ""
	var transition_duration: float = 0.3
	var flip: int = -1
	func execute(scene):
		scene.show_character_command(self)

class HideCharacter extends Base:
	var character_id: String = ""
	var side_override: String = ""
	var exit_effect: String = ""
	var exit_to: String = ""
	var exit_duration: float = 0.0
	var exit_distance: float = 200.0
	var wait_for_exit: bool = false
	var wait_after: float = 0.0
	func execute(scene):
		return scene.hide_character_entry(self)

class Band extends Base:
	var visible: bool = true
	var speaker_id: String = ""
	var text: String = ""
	var wait_for_input: bool = false
	var min_duration: float = 0.0
	var portrait_id: String = ""
	var side_override: String = ""
	var clear_text: bool = false
	func execute(scene):
		return scene.apply_band_command(self)

class BandColor extends Base:
	var color: Color = Color(0.50, 0.38, 0.18, 0.85)
	func execute(scene):
		scene.set_inner_band_color(color)
		return null

class HideDialogue extends Base:
	func execute(scene):
		return scene.hide_dialogue_command(self)

class AnimatePortrait extends Base:
	var character_id: String = ""
	var portrait_ids: Array[String] = []
	var frame_duration: float = 0.15
	var loop_count: int = 0
	func execute(scene):
		if scene and scene.has_method("start_portrait_animation"):
			scene.start_portrait_animation(self)
		return null

class StopPortraitAnimation extends Base:
	var character_id: String = ""
	func execute(scene):
		if scene and scene.has_method("stop_portrait_animation"):
			scene.stop_portrait_animation(self)
		return null

class MicroMotion extends Base:
	var mode: String = ""
	var params: Dictionary = {}
	func execute(scene):
		if scene == null or not scene.has_method("play_micro_motion"):
			return null
		return scene.play_micro_motion(self)

class Sequence extends RefCounted:
	var id: String = ""
	var entries: Array = []
	var _skipping := false
	func skip_to_next_background():
		_skipping = true

# --- DSL (factory API) ---

var _cast: Dictionary = {}  # character_id -> StoryCharacter
var _protagonist_id: String = ""
var _band_colors: Dictionary = {
	"amber": Color(0.50, 0.38, 0.18, 0.85),
	"teal": Color(0.15, 0.35, 0.42, 0.85),
	"royal_blue": Color(0.18, 0.25, 0.55, 0.85),
	"terracotta": Color(0.55, 0.30, 0.20, 0.85),
	"wine": Color(0.50, 0.20, 0.25, 0.85),
	"rose": Color(0.48, 0.28, 0.30, 0.85),
	"sand_gold": Color(0.48, 0.40, 0.22, 0.85),
	"slate_blue": Color(0.28, 0.32, 0.48, 0.85),
	"indigo": Color(0.12, 0.10, 0.28, 0.85),
	"deep_purple": Color(0.30, 0.20, 0.45, 0.85),
}

func _init(cast: Dictionary = {}) -> void:
	_cast = cast

func character(id: String) -> CharacterHandle:
	return CharacterHandle.new(self, id)

func line(character_id: String, text: String, extra: Dictionary = {}):
	var entry := Line.new()
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
	var entry := Background.new()
	entry.path = path
	entry.fade = fade
	return entry

func pause(duration: float):
	var entry := Pause.new()
	entry.duration = duration
	return entry

func show_character(character_id: String, extra: Dictionary = {}):
	var entry := ShowCharacter.new()
	entry.character_id = character_id
	entry.portrait_id = extra.get("portrait", "")
	entry.side_override = extra.get("side", "")
	entry.position_mode = extra.get("position_mode", "")
	entry.position = extra.get("position", Vector2.ZERO)
	entry.appear_effect = extra.get("appear_effect", "")
	entry.appear_from = extra.get("appear_from", "")
	entry.appear_duration = extra.get("appear_duration", 0.0)
	entry.appear_distance = extra.get("appear_distance", 200.0)
	entry.portrait_scale = extra.get("portrait_scale", 0.0)
	entry.transition = extra.get("transition", "")
	entry.transition_duration = extra.get("transition_duration", 0.3)
	entry.flip = extra.get("flip", -1)
	return entry

func hide_character(character_id: String, extra: Dictionary = {}):
	var entry := HideCharacter.new()
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
	return HideDialogue.new()

func micro_motion(mode: String, extra: Dictionary = {}):
	var entry := MicroMotion.new()
	entry.mode = mode
	entry.params = extra.duplicate()
	return entry

func animate_portrait(character_id: String, portraits: Array, frame_duration: float = 0.15, loop_count: int = 0):
	var entry := AnimatePortrait.new()
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
	var entry := StopPortraitAnimation.new()
	entry.character_id = character_id
	return entry

func register_band_color(name: String, color: Color) -> void:
	_band_colors[name] = color

func band_color(color_or_name):
	var entry := BandColor.new()
	if color_or_name is Color:
		entry.color = color_or_name
	elif color_or_name is String and _band_colors.has(color_or_name):
		entry.color = _band_colors[color_or_name]
	else:
		push_warning("band_color: unknown color '%s'" % str(color_or_name))
	return entry

func set_protagonist_id(id: String):
	if id.is_empty():
		return
	_protagonist_id = id

func build(sequence_id: String, builder_func: Callable) -> Sequence:
	var commands: Array = []
	var proxy := _CommandCollector.new(self, commands)
	if builder_func.is_valid():
		builder_func.call(proxy)
	var seq := Sequence.new()
	seq.id = sequence_id
	seq.entries = commands
	return seq

func get_cast() -> Dictionary:
	return _cast

func _band_command(p_visible: bool, text: String = "", speaker_id: String = "", wait_for_input: bool = false, min_duration: float = 0.0, portrait_id: String = "", side_override: String = "", clear_text: bool = false):
	var entry := Band.new()
	entry.visible = p_visible
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
	if _cast.has("main"):
		return "main"
	for id in _cast.keys():
		return id
	return ""

# --- CharacterHandle ---

class CharacterHandle:
	var _dsl: StoryDsl
	var _character_id: String
	var _on_command: Callable = Callable()

	func _init(dsl: StoryDsl, character_id: String, on_command: Callable = Callable()) -> void:
		_dsl = dsl
		_character_id = character_id
		_on_command = on_command

	func _record(command):
		if command and _on_command.is_valid():
			_on_command.call(command)
		return command

	func say(text: String, extra: Dictionary = {}):
		return _record(_dsl.line(_character_id, text, extra))

	func said(text: String, extra: Dictionary = {}):
		return say(text, extra)

	func think(text: String, extra: Dictionary = {}):
		return _record(_dsl.aside(text, extra))

	func show(extra: Dictionary = {}):
		var options := extra.duplicate()
		if options.has("position") and not options.has("position_mode"):
			options["position_mode"] = "offset"
		return _record(_dsl.show_character(_character_id, options))

	func appear(extra: Dictionary = {}):
		var options := extra.duplicate()
		if not options.has("appear_effect"):
			options["appear_effect"] = "fade"
		if not options.has("appear_duration"):
			options["appear_duration"] = 0.35
		if options.has("position") and not options.has("position_mode"):
			options["position_mode"] = "offset"
		return _record(_dsl.show_character(_character_id, options))

	func stay_left():
		return _record(_dsl.show_character(_character_id, {"side": "left"}))

	func stay_right():
		return _record(_dsl.show_character(_character_id, {"side": "right"}))

	func set_portrait(portrait_id: String, scale: float = 0.0, duration: float = 0.3, position: Variant = null, transition: String = "cross_fade", flip: int = -1):
		var opts := {"portrait": portrait_id}
		if scale > 0.0:
			opts["portrait_scale"] = scale
		if position != null and position is Vector2:
			opts["position_mode"] = "offset"
			opts["position"] = position
		if not transition.is_empty() and duration > 0.0:
			opts["transition"] = transition
			opts["transition_duration"] = duration
		if flip >= 0:
			opts["flip"] = flip
		return _record(_dsl.show_character(_character_id, opts))

	func animate_portrait(portrait_ids: Array, frame_duration: float = 0.15, loop_count: int = 0):
		return _record(_dsl.animate_portrait(_character_id, portrait_ids, frame_duration, loop_count))

	func stop_portrait_animation():
		return _record(_dsl.stop_portrait_animation(_character_id))

	func leave(extra: Dictionary = {}):
		var options := extra.duplicate()
		if not options.has("side"):
			options["side"] = ""
		return _record(_dsl.hide_character(_character_id, options))

	func band(text: String, extra: Dictionary = {}):
		var options := extra.duplicate()
		if not options.has("speaker_id"):
			options["speaker_id"] = _character_id
		if not options.has("wait_for_input"):
			options["wait_for_input"] = true
		return _record(_dsl.band(text, options))

	func hide_dialogue():
		return _record(_dsl.hide_dialogue())

	func get_character_id() -> String:
		return _character_id

# --- _CommandCollector (proxy for build()) ---

class _CommandCollector:
	var _dsl: StoryDsl
	var _commands: Array

	func _init(dsl: StoryDsl, commands: Array) -> void:
		_dsl = dsl
		_commands = commands

	func _add_command(command):
		if command:
			_commands.append(command)

	func character(id: String) -> CharacterHandle:
		return CharacterHandle.new(_dsl, id, Callable(self, "_add_command"))

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

	func register_band_color(name: String, color: Color):
		_dsl.register_band_color(name, color)

	func band_color(color_or_name):
		_add_command(_dsl.band_color(color_or_name))

	func hide_dialogue():
		_add_command(_dsl.hide_dialogue())

	func animate_portrait(character_id: String, portraits: Array, frame_duration: float = 0.15, loop_count: int = 0):
		_add_command(_dsl.animate_portrait(character_id, portraits, frame_duration, loop_count))

	func stop_portrait_animation(character_id: String):
		_add_command(_dsl.stop_portrait_animation(character_id))

	func micro_motion(mode: String, extra: Dictionary = {}):
		_add_command(_dsl.micro_motion(mode, extra))
