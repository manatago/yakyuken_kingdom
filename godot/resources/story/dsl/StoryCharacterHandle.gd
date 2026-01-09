extends RefCounted
class_name StoryCharacterHandle

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

func set_portrait(portrait_id: String):
	return _record(_dsl.show_character(_character_id, {"portrait": portrait_id}))

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
