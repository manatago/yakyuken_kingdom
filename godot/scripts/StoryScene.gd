extends Control
class_name StoryScene

const StoryCast := preload("res://resources/story/StoryCast.gd")
const StoryShowCharacterCommand := preload("res://resources/story/commands/StoryShowCharacterCommand.gd")
const StoryHideDialogueCommand := preload("res://resources/story/commands/StoryHideDialogueCommand.gd")
const StoryHideCharacterCommand := preload("res://resources/story/commands/StoryHideCharacterCommand.gd")


signal sequence_started(sequence_id)
signal sequence_finished(sequence_id)
signal advance_requested

@onready var left_char := $LeftChar
@onready var center_char := $CenterChar
@onready var right_char := $RightChar
@onready var left_bubble := $LeftChar/SpeechBubbleLeft
@onready var center_bubble := $CenterChar/SpeechBubbleCenter
@onready var right_bubble := $RightChar/SpeechBubbleRight
@onready var left_bubble_default_pos: Vector2 = left_bubble.position
@onready var center_bubble_default_pos: Vector2 = center_bubble.position
@onready var right_bubble_default_pos: Vector2 = right_bubble.position
@onready var left_char_default_pos: Vector2 = left_char.position
@onready var center_char_default_pos: Vector2 = center_char.position
@onready var right_char_default_pos: Vector2 = right_char.position
@onready var dialogue_band := $DialogueBand
@onready var dialogue_band_speaker := $DialogueBand/VBox/SpeakerLabel
@onready var dialogue_band_body := $DialogueBand/VBox/BodyLabel
@onready var background_rect := $Background
@onready var background_next_rect := $BackgroundNext

var _cast: StoryCast = StoryCast.new()
var _texture_cache: Dictionary = {}
var _sequence_playing := false
var _waiting_for_input := false
var _current_sequence_id := ""
var _character_side_cache: Dictionary = {}
var _character_position_cache: Dictionary = {}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	$Background.visible = true
	left_char.visible = false
	center_char.visible = false
	right_char.visible = false
	left_bubble.visible = false
	center_bubble.visible = false
	right_bubble.visible = false

func _unhandled_input(event):
	if not _waiting_for_input:
		return
	if event.is_action_pressed("ui_accept"):
		_trigger_advance()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_trigger_advance()

func set_cast(cast: StoryCast) -> void:
	_cast = cast if cast else StoryCast.new()

func is_sequence_playing() -> bool:
	return _sequence_playing

func play_sequence(sequence: StorySequence, metadata: Dictionary = {}):
	if sequence == null:
		return
	_sequence_playing = true
	var resolved_id: String = metadata.get("id", sequence.id)
	_current_sequence_id = resolved_id
	sequence_started.emit(resolved_id)
	await sequence.play(self)
	_hide_bubbles()
	_current_sequence_id = ""
	_sequence_playing = false
	sequence_finished.emit(resolved_id)

func play_line(entry: StoryLineCommand):
	var character_id := entry.speaker_id
	var side := _resolve_character_side(character_id, entry.side_override)
	var character_data: StoryCharacter = null
	if not character_id.is_empty():
		character_data = _cast.get_character(character_id)
	if character_data:
		_show_character(character_data, entry.portrait_id, side)
	elif side.is_empty():
		side = "left"

	show_dialogue(side, entry.text, entry.offset)

	if entry.wait_for_input:
		return _prepare_wait_for_advance(entry.min_duration)
	elif entry.duration > 0.0:
		return get_tree().create_timer(entry.duration).timeout
	return null

func _prepare_wait_for_advance(min_duration: float) -> Signal:
	_waiting_for_input = false
	if min_duration > 0.0:
		var timer := get_tree().create_timer(min_duration)
		timer.timeout.connect(_on_wait_timer_finished, CONNECT_ONE_SHOT)
	else:
		_enable_waiting_for_input()
	return advance_requested

func _on_wait_timer_finished():
	_enable_waiting_for_input()

func _enable_waiting_for_input():
	_waiting_for_input = true

func _trigger_advance():
	if not _waiting_for_input:
		return
	_waiting_for_input = false
	advance_requested.emit()

func _show_character(character_data: StoryCharacter, portrait_name: String, side: String, position_mode: String = "", position_value: Vector2 = Vector2.ZERO):
	var texture_path: String = character_data.get_portrait_path(portrait_name)
	if texture_path.is_empty():
		return null
	var tex := _get_texture(texture_path)
	if tex == null:
		return null
	var target_rect := _get_rect_for_side(side)
	if target_rect == null:
		return null
	target_rect.texture = tex
	target_rect.visible = true
	_reset_character_transform(target_rect)
	var target_pos := _resolve_character_position(side, position_mode, position_value)
	target_rect.position = target_pos
	if character_data and not character_data.id.is_empty():
		_character_side_cache[character_data.id] = side
		_character_position_cache[character_data.id] = target_pos
	return target_rect

func hide_character_entry(entry: StoryHideCharacterCommand):
	var side := _resolve_character_side(entry.character_id, entry.side_override)
	var target_rect := _get_rect_for_side(side)
	if not target_rect:
		return
	var target_pos: Vector2 = _character_position_cache.get(entry.character_id, _default_side_position(side))
	if not _apply_character_exit_effect(target_rect, entry, side, entry.character_id, target_pos):
		_hide_character_control(target_rect, side, entry.character_id)

func _hide_character_by_side(side: String):
	var target_rect := _get_rect_for_side(side)
	if target_rect:
		target_rect.visible = false

func _apply_character_exit_effect(target_rect: TextureRect, entry: StoryHideCharacterCommand, side: String, character_id: String, target_pos: Vector2) -> bool:
	if target_rect == null:
		return false
	var effect := entry.exit_effect.strip_edges().to_lower()
	if effect.is_empty():
		return false
	var duration: float = max(entry.exit_duration, 0.0)
	if duration <= 0.0:
		return false
	var default_pos: Vector2 = target_pos
	var tween := create_tween()
	if effect == "fade":
		tween.tween_property(target_rect, "modulate:a", 0.0, duration)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		return true
	var direction := entry.exit_to.strip_edges().to_lower()
	if direction.is_empty():
		direction = "right" if side == "right" else "left"
	var distance := entry.exit_distance
	if distance <= 0.0:
		distance = 200.0
	var end_pos := default_pos
	match direction:
		"left":
			end_pos.x = default_pos.x - distance
		"right":
			end_pos.x = default_pos.x + distance
		"up", "top":
			end_pos.y = default_pos.y - distance
		"down", "bottom":
			end_pos.y = default_pos.y + distance
		_:
			pass
	if effect == "slide":
		tween.tween_property(target_rect, "position", end_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		return true
	elif effect == "fade_slide":
		tween.tween_property(target_rect, "position", end_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(target_rect, "modulate:a", 0.0, duration)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		return true
	else:
		return false

func _hide_character_control(target_rect: TextureRect, side: String, character_id: String):
	if target_rect == null:
		return
	target_rect.visible = false
	target_rect.modulate = Color.WHITE
	target_rect.position = _default_side_position(side)
	if not character_id.is_empty():
		_character_side_cache.erase(character_id)
		_character_position_cache.erase(character_id)

func _reset_character_transform(target_rect: Control):
	if target_rect == null:
		return
	target_rect.modulate = Color.WHITE
	if target_rect == right_char:
		target_rect.position = right_char_default_pos
	elif target_rect == center_char:
		target_rect.position = center_char_default_pos
	else:
		target_rect.position = left_char_default_pos

func show_background_entry(entry: StoryBackgroundCommand):
	if entry.path.is_empty():
		return
	var tex := _get_texture(entry.path)
	if tex == null:
		return
	if not background_rect or not background_next_rect:
		background_rect.texture = tex
		background_rect.visible = true
		background_rect.modulate = Color.WHITE
		return
	var fade_time: float = max(entry.fade, 0.0)
	if fade_time <= 0.0 or not background_rect.texture:
		background_rect.texture = tex
		background_rect.visible = true
		background_rect.modulate = Color.WHITE
		background_next_rect.visible = false
		return
	background_next_rect.texture = tex
	background_next_rect.modulate = Color(1, 1, 1, 0)
	background_next_rect.visible = true
	var tween := create_tween()
	tween.finished.connect(func():
		background_rect.texture = tex
		background_rect.visible = true
		background_rect.modulate = Color.WHITE
		background_next_rect.visible = false
		background_next_rect.modulate = Color(1, 1, 1, 0))
	tween.tween_property(background_next_rect, "modulate:a", 1.0, fade_time)
	tween.tween_property(background_rect, "modulate:a", 0.0, fade_time)

func pause_entry(entry: StoryPauseCommand):
	if entry.duration <= 0.0:
		return null
	return get_tree().create_timer(entry.duration).timeout

func _hide_bubbles():
	left_bubble.visible = false
	center_bubble.visible = false
	right_bubble.visible = false

func show_dialogue(side: String, text: String, offset: Vector2 = Vector2.ZERO):
	left_bubble.visible = false
	center_bubble.visible = false
	right_bubble.visible = false
	var target := left_bubble
	var default_pos: Vector2 = left_bubble_default_pos
	if side == "right":
		target = right_bubble
		default_pos = right_bubble_default_pos
	elif side == "center":
		target = center_bubble
		default_pos = center_bubble_default_pos
	target.text = text
	target.position = default_pos + offset
	target.visible = true

func hide_dialogue_command(_entry: StoryHideDialogueCommand):
	_hide_bubbles()

func show_character_command(entry: StoryShowCharacterCommand):
	if entry.character_id.is_empty():
		return
	var char_data: StoryCharacter = _cast.get_character(entry.character_id)
	if char_data == null:
		return
	var side := _resolve_character_side(entry.character_id, entry.side_override)
	var target_rect: TextureRect = _show_character(char_data, entry.portrait_id, side, entry.position_mode, entry.position)
	if target_rect == null:
		return
	var target_pos: Vector2 = _character_position_cache.get(entry.character_id, target_rect.position)
	_apply_character_entry_effect(target_rect, entry, target_pos, side)

func _apply_character_entry_effect(target_rect: TextureRect, entry: StoryShowCharacterCommand, target_pos: Vector2, side: String):
	if target_rect == null:
		return
	var effect := entry.appear_effect.strip_edges().to_lower()
	if effect.is_empty():
		return
	var duration: float = max(entry.appear_duration, 0.0)
	if duration <= 0.0:
		return
	var default_pos: Vector2 = target_pos
	if effect == "fade":
		var tween := create_tween()
		target_rect.modulate = Color(1, 1, 1, 0)
		tween.tween_property(target_rect, "modulate:a", 1.0, duration)
		return
	var direction := entry.appear_from.strip_edges().to_lower()
	if direction.is_empty():
		direction = "right" if side == "right" else ("left" if side == "left" else "top")
	var distance := entry.appear_distance
	if distance <= 0.0:
		distance = 200.0
	var start_pos := default_pos
	match direction:
		"left":
			start_pos.x = default_pos.x - distance
		"right":
			start_pos.x = default_pos.x + distance
		"up", "top":
			start_pos.y = default_pos.y - distance
		"down", "bottom":
			start_pos.y = default_pos.y + distance
		_:
			pass
	if effect == "slide":
		var tween := create_tween()
		target_rect.position = start_pos
		tween.tween_property(target_rect, "position", default_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	elif effect == "fade_slide":
		var tween := create_tween()
		target_rect.position = start_pos
		target_rect.modulate = Color(1, 1, 1, 0)
		tween.tween_property(target_rect, "position", default_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(target_rect, "modulate:a", 1.0, duration)
	else:
		# Unknown effect; snap to default
		target_rect.position = default_pos
		target_rect.modulate = Color.WHITE

func apply_band_command(entry: StoryBandCommand):
	if not dialogue_band:
		return null
	dialogue_band.visible = entry.visible
	if not entry.visible:
		return null
	if entry.clear_text or not entry.text.is_empty():
		dialogue_band_body.text = entry.text

	var char_data: StoryCharacter = null
	if not entry.speaker_id.is_empty():
		char_data = _cast.get_character(entry.speaker_id)
	if char_data:
		var side := _resolve_character_side(entry.speaker_id, entry.side_override)
		_show_character(char_data, entry.portrait_id, side)
		if not char_data.display_name.is_empty():
			dialogue_band_speaker.visible = true
			dialogue_band_speaker.text = char_data.display_name
		else:
			dialogue_band_speaker.visible = false
	else:
		dialogue_band_speaker.visible = false

	if entry.wait_for_input:
		return _prepare_wait_for_advance(entry.min_duration)
	return null

func _get_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var texture := _load_texture(path)
	if texture:
		_texture_cache[path] = texture
	return texture

func _load_texture(resource_path: String) -> Texture2D:
	var resource = load(resource_path)
	if resource is Texture2D:
		return resource
	if resource:
		return null
	var image := Image.new()
	var err := image.load(resource_path)
	if err != OK:
		var absolute_path := ProjectSettings.globalize_path(resource_path)
		if absolute_path != resource_path:
			err = image.load(absolute_path)
	if err == OK:
		return ImageTexture.create_from_image(image)
	return null

func _get_rect_for_side(side: String) -> TextureRect:
	match side:
		"left":
			return left_char
		"right":
			return right_char
		"center":
			return center_char
		_:
			return left_char

func _default_side_position(side: String) -> Vector2:
	match side:
		"left":
			return left_char_default_pos
		"right":
			return right_char_default_pos
		"center":
			return center_char_default_pos
		_:
			return left_char_default_pos

func _resolve_character_side(character_id: String, requested_side: String) -> String:
	if not requested_side.is_empty():
		return requested_side
	if not character_id.is_empty() and _character_side_cache.has(character_id):
		return _character_side_cache[character_id]
	if not left_char.visible:
		return "left"
	if not right_char.visible:
		return "right"
	if not center_char.visible:
		return "center"
	return "left"

func _resolve_character_position(side: String, position_mode: String, position_value: Vector2) -> Vector2:
	var mode := position_mode.strip_edges().to_lower()
	var base := _default_side_position(side)
	match mode:
		"absolute":
			return position_value
		"offset":
			return base + position_value
		"normalized":
			var size := get_viewport_rect().size
			return Vector2(size.x * position_value.x, size.y * position_value.y)
		_:
			return base
