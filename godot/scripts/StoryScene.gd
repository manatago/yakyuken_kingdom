extends Control
class_name StoryScene

const StoryCast := preload("res://resources/story/StoryCast.gd")
const StoryShowCharacterCommand := preload("res://resources/story/commands/StoryShowCharacterCommand.gd")
const StoryHideDialogueCommand := preload("res://resources/story/commands/StoryHideDialogueCommand.gd")
const StoryHideCharacterCommand := preload("res://resources/story/commands/StoryHideCharacterCommand.gd")
const StoryMicroMotionCommand := preload("res://resources/story/commands/StoryMicroMotionCommand.gd")
const MicroMotionShowcaseScene := preload("res://resources/story/micromotion/MicroMotionShowcase.tscn")


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
@onready var _left_char_default_offset_left: float = left_char.offset_left
@onready var _left_char_default_offset_right: float = left_char.offset_right
@onready var _left_char_default_offset_top: float = left_char.offset_top
@onready var _right_char_default_offset_left: float = right_char.offset_left
@onready var _right_char_default_offset_right: float = right_char.offset_right
@onready var _right_char_default_offset_top: float = right_char.offset_top
@onready var _center_char_default_offset_left: float = center_char.offset_left
@onready var _center_char_default_offset_right: float = center_char.offset_right
@onready var _center_char_default_offset_top: float = center_char.offset_top
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
var _character_portrait_cache: Dictionary = {}
var _active_character_tweens: Dictionary = {}
var _pending_signal_relays: Array = []
var _portrait_animation_data: Dictionary = {}
var _portrait_animation_timers: Dictionary = {}
var _suppress_animation_reset := false
var _micro_motion_showcase: MicroMotionShowcase = null

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
	_ensure_micro_motion_showcase()

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

func play_micro_motion(entry: StoryMicroMotionCommand):
	if entry == null:
		return null
	_ensure_micro_motion_showcase()
	if _micro_motion_showcase == null:
		return null
	var params := entry.params if entry.params else {}
	return _micro_motion_showcase.play(entry.mode, params)

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


func _ensure_micro_motion_showcase() -> void:
	if _micro_motion_showcase:
		return
	if MicroMotionShowcaseScene == null:
		return
	_micro_motion_showcase = MicroMotionShowcaseScene.instantiate()
	add_child(_micro_motion_showcase)
	move_child(_micro_motion_showcase, get_child_count() - 1)
	_micro_motion_showcase.visible = false


func _show_character(character_data: StoryCharacter, portrait_name: String, side: String, position_mode: String = "", position_value: Vector2 = Vector2.ZERO):
	var resolved_portrait := portrait_name
	if resolved_portrait.is_empty():
		if not character_data.id.is_empty() and _character_portrait_cache.has(character_data.id):
			resolved_portrait = _character_portrait_cache[character_data.id]
		else:
			resolved_portrait = character_data.default_portrait
	var texture_path: String = character_data.get_portrait_path(resolved_portrait)
	if texture_path.is_empty() and resolved_portrait != character_data.default_portrait:
		resolved_portrait = character_data.default_portrait
		texture_path = character_data.get_portrait_path(resolved_portrait)
	if texture_path.is_empty():
		return null
	var tex := _get_texture(texture_path)
	if tex == null:
		return null
	var target_rect := _get_rect_for_side(side)
	if target_rect == null:
		return null
	var was_visible := target_rect.visible
	target_rect.texture = tex
	target_rect.visible = true
	if not was_visible:
		target_rect.modulate = Color.WHITE
		target_rect.scale = Vector2.ONE
		target_rect.pivot_offset = Vector2.ZERO
	# Always reset offsets to defaults, then recompute position and display adjustments.
	# This ensures display_scale and display_offset_y are applied consistently
	# regardless of prior position overrides.
	_reset_rect_width(target_rect)
	var character_id := character_data.id if character_data else ""
	var target_pos := _resolve_character_position(character_id, side, position_mode, position_value)
	# Apply position as offset delta instead of setting position directly.
	# Setting Control.position recalculates ALL four offsets (including offset_bottom),
	# which causes height to shrink on each call due to offset_bottom accumulation.
	var default_pos := _default_side_position(side)
	var pos_delta := target_pos - default_pos
	if not pos_delta.is_zero_approx():
		target_rect.offset_left += pos_delta.x
		target_rect.offset_top += pos_delta.y
	var char_scale: float = character_data.display_scale if character_data else 1.0
	_apply_display_scale(target_rect, char_scale)
	var char_offset_y: float = character_data.display_offset_y if character_data else 0.0
	_apply_display_offset_y(target_rect, char_offset_y)
	if character_data and not character_data.id.is_empty():
		if not _suppress_animation_reset:
			_stop_portrait_animation_by_id(character_data.id)
		_character_side_cache[character_data.id] = side
		_character_position_cache[character_data.id] = target_pos
		_character_portrait_cache[character_data.id] = resolved_portrait
	return target_rect

func hide_character_entry(entry: StoryHideCharacterCommand):
	var side := _resolve_character_side(entry.character_id, entry.side_override)
	var target_rect := _get_rect_for_side(side)
	if not target_rect:
		return null
	var target_pos: Vector2 = _character_position_cache.get(entry.character_id, _default_side_position(side))
	var tween := _apply_character_exit_effect(target_rect, entry, side, entry.character_id, target_pos)
	if tween:
		if entry.wait_for_exit:
			return _wrap_signal_with_delay(tween.finished, entry.wait_after)
		elif entry.wait_after > 0.0:
			return _create_delay_signal(entry.wait_after)
		return null
	_hide_character_control(target_rect, side, entry.character_id)
	if entry.wait_after > 0.0:
		return _create_delay_signal(entry.wait_after)
	return null

func _hide_character_by_side(side: String):
	var target_rect := _get_rect_for_side(side)
	if target_rect:
		target_rect.visible = false

func _apply_character_exit_effect(target_rect: TextureRect, entry: StoryHideCharacterCommand, side: String, character_id: String, target_pos: Vector2) -> Tween:
	if target_rect == null:
		return null
	var effect := entry.exit_effect.strip_edges().to_lower()
	if effect.is_empty():
		return null
	var duration: float = max(entry.exit_duration, 0.0)
	if duration <= 0.0:
		return null
	var default_pos: Vector2 = target_pos
	_cancel_character_tween(target_rect)
	var tween := create_tween()
	if effect == "fade":
		tween.tween_property(target_rect, "modulate:a", 0.0, duration)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		_register_character_tween(target_rect, tween)
		return tween
	var direction := entry.exit_to.strip_edges().to_lower()
	if direction.is_empty():
		direction = "right" if side == "right" else "left"
	var distance := entry.exit_distance
	if distance <= 0.0:
		distance = 200.0
	# Use offset-based animation to preserve display_scale adjustments.
	var offset_delta_x: float = 0.0
	var offset_delta_y: float = 0.0
	match direction:
		"left":
			offset_delta_x = -distance
		"right":
			offset_delta_x = distance
		"up", "top":
			offset_delta_y = -distance
		"down", "bottom":
			offset_delta_y = distance
		_:
			pass
	var end_offset_left: float = target_rect.offset_left + offset_delta_x
	var end_offset_top: float = target_rect.offset_top + offset_delta_y
	if effect == "slide":
		if not is_zero_approx(offset_delta_x):
			tween.tween_property(target_rect, "offset_left", end_offset_left, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if not is_zero_approx(offset_delta_y):
			tween.parallel().tween_property(target_rect, "offset_top", end_offset_top, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		_register_character_tween(target_rect, tween)
		return tween
	elif effect == "fade_slide":
		if not is_zero_approx(offset_delta_x):
			tween.tween_property(target_rect, "offset_left", end_offset_left, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if not is_zero_approx(offset_delta_y):
			tween.parallel().tween_property(target_rect, "offset_top", end_offset_top, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(target_rect, "modulate:a", 0.0, duration)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		_register_character_tween(target_rect, tween)
		return tween
	elif effect == "shrink" or effect == "fade_shrink":
		target_rect.pivot_offset = target_rect.size * 0.5
		var scale_tween := tween.tween_property(target_rect, "scale", Vector2.ZERO, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		if effect == "fade_shrink":
			tween.parallel().tween_property(target_rect, "modulate:a", 0.0, duration)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		_register_character_tween(target_rect, tween)
		return tween
	else:
		return null

func _hide_character_control(target_rect: TextureRect, side: String, character_id: String):
	if target_rect == null:
		return
	_cancel_character_tween(target_rect)
	target_rect.visible = false
	target_rect.modulate = Color.WHITE
	target_rect.scale = Vector2.ONE
	target_rect.pivot_offset = Vector2.ZERO
	target_rect.position = _default_side_position(side)
	if not character_id.is_empty():
		_character_side_cache.erase(character_id)
		_character_position_cache.erase(character_id)
		_character_portrait_cache.erase(character_id)
		_stop_portrait_animation_by_id(character_id)

func start_portrait_animation(entry: StoryAnimatePortraitCommand):
	if entry == null or entry.character_id.is_empty():
		return
	_stop_portrait_animation_by_id(entry.character_id)
	var frames: Array[String] = []
	for portrait in entry.portrait_ids:
		if typeof(portrait) == TYPE_STRING and not portrait.is_empty():
			frames.append(portrait)
	if frames.is_empty():
		return
	var data = {
		"frames": frames,
		"index": 0,
		"frame_duration": max(entry.frame_duration, 0.05),
		"loop_count": max(entry.loop_count, 0),
		"completed_cycles": 0,
	}
	_portrait_animation_data[entry.character_id] = data
	_apply_portrait_frame(entry.character_id, frames[0])
	if frames.size() > 1:
		_schedule_next_portrait_frame(entry.character_id)

func stop_portrait_animation(entry: StoryStopPortraitAnimationCommand):
	if entry == null:
		return
	_stop_portrait_animation_by_id(entry.character_id)

func _stop_portrait_animation_by_id(character_id: String):
	if character_id.is_empty():
		return
	var timer: Timer = _portrait_animation_timers.get(character_id, null)
	if timer:
		timer.stop()
		timer.queue_free()
		_portrait_animation_timers.erase(character_id)
	_portrait_animation_data.erase(character_id)

func _schedule_next_portrait_frame(character_id: String):
	var data = _portrait_animation_data.get(character_id, null)
	if data == null:
		return
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = data.frame_duration
	add_child(timer)
	timer.timeout.connect(func(): _on_portrait_animation_tick(character_id), CONNECT_ONE_SHOT)
	timer.start()
	_portrait_animation_timers[character_id] = timer

func _on_portrait_animation_tick(character_id: String):
	var timer: Timer = _portrait_animation_timers.get(character_id, null)
	if timer:
		timer.queue_free()
		_portrait_animation_timers.erase(character_id)
	var data = _portrait_animation_data.get(character_id, null)
	if data == null:
		return
	var frames: Array = data.frames
	if frames.is_empty():
		_portrait_animation_data.erase(character_id)
		return
	data.index = (data.index + 1) % frames.size()
	if data.index == 0 and data.loop_count > 0:
		data.completed_cycles += 1
		if data.completed_cycles >= data.loop_count:
			_portrait_animation_data.erase(character_id)
			return
	_apply_portrait_frame(character_id, frames[data.index])
	_schedule_next_portrait_frame(character_id)

func _apply_portrait_frame(character_id: String, portrait_name: String):
	if character_id.is_empty():
		return
	var character_data: StoryCharacter = _cast.get_character(character_id)
	if character_data == null:
		return
	var side: String = _character_side_cache.get(character_id, character_data.default_side)
	_suppress_animation_reset = true
	_show_character(character_data, portrait_name, side)
	_suppress_animation_reset = false

func _reset_character_transform(target_rect: Control):
	if target_rect == null:
		return
	target_rect.modulate = Color.WHITE
	target_rect.scale = Vector2.ONE
	target_rect.pivot_offset = Vector2.ZERO
	_reset_rect_width(target_rect)
	if target_rect == right_char:
		target_rect.position = right_char_default_pos
	elif target_rect == center_char:
		target_rect.position = center_char_default_pos
	else:
		target_rect.position = left_char_default_pos

func _apply_display_scale(target_rect: Control, scale_factor: float) -> void:
	if scale_factor <= 0.0 or is_equal_approx(scale_factor, 1.0):
		return
	# Compute extra width as delta from default rect width.
	# Expand directionally to avoid screen-edge clipping:
	#   RightChar: expand leftward only (right edge stays fixed)
	#   LeftChar:  expand rightward only (left edge stays fixed)
	#   CenterChar: expand symmetrically
	var default_width: float
	if target_rect == left_char:
		default_width = _left_char_default_offset_right - _left_char_default_offset_left
	elif target_rect == right_char:
		default_width = _right_char_default_offset_right - _right_char_default_offset_left
	elif target_rect == center_char:
		default_width = _center_char_default_offset_right - _center_char_default_offset_left
	else:
		return
	var extra_width: float = default_width * (scale_factor - 1.0)
	if target_rect == right_char:
		target_rect.offset_left -= extra_width
	elif target_rect == left_char:
		target_rect.offset_right += extra_width
	else:
		target_rect.offset_left -= extra_width / 2.0
		target_rect.offset_right += extra_width / 2.0

func _reset_rect_width(target_rect: Control) -> void:
	if target_rect == left_char:
		target_rect.offset_left = _left_char_default_offset_left
		target_rect.offset_right = _left_char_default_offset_right
		target_rect.offset_top = _left_char_default_offset_top
	elif target_rect == right_char:
		target_rect.offset_left = _right_char_default_offset_left
		target_rect.offset_right = _right_char_default_offset_right
		target_rect.offset_top = _right_char_default_offset_top
	elif target_rect == center_char:
		target_rect.offset_left = _center_char_default_offset_left
		target_rect.offset_right = _center_char_default_offset_right
		target_rect.offset_top = _center_char_default_offset_top

func _apply_display_offset_y(target_rect: Control, offset_y: float) -> void:
	if is_zero_approx(offset_y):
		return
	target_rect.offset_top += offset_y

func _cancel_character_tween(target_rect: TextureRect):
	if target_rect == null:
		return
	var tween = _active_character_tweens.get(target_rect, null)
	if tween:
		tween.kill()
		_active_character_tweens.erase(target_rect)

func _register_character_tween(target_rect: TextureRect, tween):
	if target_rect == null or tween == null:
		return
	_active_character_tweens[target_rect] = tween
	tween.finished.connect(func():
		if _active_character_tweens.get(target_rect) == tween:
			_active_character_tweens.erase(target_rect))

func _create_delay_signal(duration: float):
	if duration <= 0.0:
		return null
	return get_tree().create_timer(duration).timeout

func _wrap_signal_with_delay(base_signal: Signal, delay: float):
	if base_signal == null:
		return null
	if delay <= 0.0:
		return base_signal
	var relay := _SignalRelay.new()
	_pending_signal_relays.append(relay)
	base_signal.connect(func():
		var timer := get_tree().create_timer(delay)
		timer.timeout.connect(func():
			_emit_signal_relay(relay), CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)
	return relay.completed

func _emit_signal_relay(relay: _SignalRelay):
	if relay == null:
		return
	if relay in _pending_signal_relays:
		_pending_signal_relays.erase(relay)
	relay.completed.emit()

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
	_cancel_character_tween(target_rect)
	var default_pos: Vector2 = target_pos
	if effect == "fade":
		var tween := create_tween()
		target_rect.modulate = Color(1, 1, 1, 0)
		tween.tween_property(target_rect, "modulate:a", 1.0, duration)
		_register_character_tween(target_rect, tween)
		return
	elif effect == "grow" or effect == "fade_grow":
		var tween := create_tween()
		target_rect.pivot_offset = target_rect.size * 0.5
		target_rect.scale = Vector2.ZERO
		if effect == "fade_grow":
			target_rect.modulate = Color(1, 1, 1, 0)
		tween.tween_property(target_rect, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if effect == "fade_grow":
			tween.parallel().tween_property(target_rect, "modulate:a", 1.0, duration)
		_register_character_tween(target_rect, tween)
		return
	var direction := entry.appear_from.strip_edges().to_lower()
	if direction.is_empty():
		direction = "right" if side == "right" else ("left" if side == "left" else "top")
	var distance := entry.appear_distance
	if distance <= 0.0:
		distance = 200.0
	# Use offset-based animation instead of position-based.
	# Setting Control.position recalculates ALL four offsets, which destroys
	# display_scale and display_offset_y adjustments applied by _show_character.
	var end_offset_left: float = target_rect.offset_left
	var end_offset_top: float = target_rect.offset_top
	var offset_delta_x: float = 0.0
	var offset_delta_y: float = 0.0
	match direction:
		"left":
			offset_delta_x = -distance
		"right":
			offset_delta_x = distance
		"up", "top":
			offset_delta_y = -distance
		"down", "bottom":
			offset_delta_y = distance
		_:
			pass
	if effect == "slide":
		var tween := create_tween()
		target_rect.offset_left = end_offset_left + offset_delta_x
		target_rect.offset_top = end_offset_top + offset_delta_y
		if not is_zero_approx(offset_delta_x):
			tween.tween_property(target_rect, "offset_left", end_offset_left, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if not is_zero_approx(offset_delta_y):
			tween.parallel().tween_property(target_rect, "offset_top", end_offset_top, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_register_character_tween(target_rect, tween)
	elif effect == "fade_slide":
		var tween := create_tween()
		target_rect.offset_left = end_offset_left + offset_delta_x
		target_rect.offset_top = end_offset_top + offset_delta_y
		target_rect.modulate = Color(1, 1, 1, 0)
		if not is_zero_approx(offset_delta_x):
			tween.tween_property(target_rect, "offset_left", end_offset_left, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if not is_zero_approx(offset_delta_y):
			tween.parallel().tween_property(target_rect, "offset_top", end_offset_top, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(target_rect, "modulate:a", 1.0, duration)
		_register_character_tween(target_rect, tween)
	elif effect == "grow" or effect == "fade_grow":
		# Already handled earlier
		pass
	else:
		# Unknown effect; keep current offsets (display adjustments intact)
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

func _resolve_character_position(character_id: String, side: String, position_mode: String, position_value: Vector2) -> Vector2:
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
			if not character_id.is_empty() and _character_position_cache.has(character_id):
				return _character_position_cache[character_id]
			return base

class _SignalRelay:
	extends RefCounted
	signal completed
