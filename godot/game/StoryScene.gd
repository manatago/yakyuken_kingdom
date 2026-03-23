extends Control
class_name StoryScene

const Cmd = preload("res://story/StoryCommands.gd")

signal sequence_started(sequence_id)
signal sequence_finished(sequence_id)
signal advance_requested
signal battle_requested(command)
signal battle_completed(result)
signal terminal_effect_finished

@onready var left_char := $LeftChar
@onready var center_char := $CenterChar
@onready var right_char := $RightChar
const _CHAR_MARGIN := 100.0
@onready var dialogue_band := $DialogueBand
@onready var dialogue_band_speaker := $DialogueBand/VBox/SpeakerLabel
@onready var dialogue_band_body := $DialogueBand/VBox/BodyLabel
@onready var dialogue_band_left := $DialogueBand/InnerLeft
@onready var dialogue_band_left_speaker := $DialogueBand/SpeakerLabelLeft
@onready var dialogue_band_left_body := $DialogueBand/InnerLeft/BodyLabel
@onready var dialogue_band_right := $DialogueBand/InnerRight
@onready var dialogue_band_right_speaker := $DialogueBand/SpeakerLabelRight
@onready var dialogue_band_right_body := $DialogueBand/InnerRight/BodyLabel
@onready var _menu_bar := $DialogueBand/MenuBar
@onready var background_rect := $Background
@onready var background_next_rect := $BackgroundNext
var _cast: Dictionary = {}  # character_id -> StoryCharacter
var _texture_cache: Dictionary = {}
var _sequence_playing := false
var _waiting_for_input := false
var _current_sequence_id := ""
var _current_sequence: Cmd.Sequence = null
var _character_side_cache: Dictionary = {}
var _character_position_cache: Dictionary = {}
var _character_portrait_cache: Dictionary = {}
var _character_portrait_scale_cache: Dictionary = {}
var _active_character_tweens: Dictionary = {}
var _typing_in_progress := false
var _typing_label: Label = null
var _typing_tween: Tween = null
var _char_speed: float = 0.03  # seconds per character
var _pending_signal_relays: Array = []
var _portrait_animation_data: Dictionary = {}
var _portrait_animation_timers: Dictionary = {}
var _suppress_animation_reset := false

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	$Background.visible = true
	left_char.visible = false
	center_char.visible = false
	right_char.visible = false
	_menu_bar.get_node("SkipButton").pressed.connect(_on_skip_pressed)

func _input(event):
	# Reject key echo
	if event is InputEventKey and event.echo:
		return
	var is_advance := false
	if event.is_action_pressed("ui_accept"):
		is_advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered = get_viewport().gui_get_hovered_control()
		if hovered is BaseButton:
			return
		is_advance = true
	if not is_advance:
		return
	# If typing in progress, skip to full text
	if _typing_in_progress:
		_skip_typing()
		get_viewport().set_input_as_handled()
		return
	# Otherwise, advance dialogue
	if _waiting_for_input:
		_trigger_advance()
		get_viewport().set_input_as_handled()

func set_cast(cast: Dictionary) -> void:
	_cast = cast if cast else {}

func is_sequence_playing() -> bool:
	return _sequence_playing

# --- Sequence playback (merged from StorySequence.gd) ---

func play_sequence(sequence: Cmd.Sequence, metadata: Dictionary = {}):
	if sequence == null:
		return
	_sequence_playing = true
	_current_sequence = sequence
	var resolved_id: String = metadata.get("id", sequence.id)
	_current_sequence_id = resolved_id
	sequence_started.emit(resolved_id)
	# Skip to label if specified
	var skip_to: String = metadata.get("skip_to", "")
	var skipping_to_label := not skip_to.is_empty()

	# State to restore when resuming from label
	var last_bg_entry = null
	var last_battle: Cmd.Battle = null

	# Play all commands in the sequence
	for entry in sequence.entries:
		if entry == null:
			continue
		# Skip until we find the target label, but track state
		if skipping_to_label:
			if entry is Cmd.Background:
				last_bg_entry = entry
			if entry is Cmd.SeqLabel and entry.label_name == skip_to:
				skipping_to_label = false
				# Restore last background
				if last_bg_entry:
					last_bg_entry.fade = 0.0
					last_bg_entry.execute(self)
			continue
		if entry is Cmd.Battle:
			last_battle = entry
		if sequence._skipping and entry is Cmd.Background:
			sequence._skipping = false
		var result = entry.execute(self)
		if result is Signal:
			if sequence._skipping:
				_trigger_skip_advance()
			else:
				await result
	_current_sequence_id = ""
	_current_sequence = null
	_sequence_playing = false
	sequence_finished.emit(resolved_id)

# --- Command handlers ---

func play_line(entry: Cmd.Line):
	var band_cmd := Cmd.Band.new()
	band_cmd.visible = true
	band_cmd.speaker_id = entry.speaker_id
	band_cmd.text = entry.text
	band_cmd.portrait_id = entry.portrait_id
	band_cmd.side_override = entry.side_override
	band_cmd.wait_for_input = entry.wait_for_input
	band_cmd.min_duration = entry.min_duration
	return apply_band_command(band_cmd)

# --- Battle ---

func request_battle(cmd: Cmd.Battle):
	battle_requested.emit(cmd)
	return battle_completed

func complete_battle(result: String):
	battle_completed.emit(result)

# --- Typewriter effect ---

func _start_typewriter(label: Label):
	_typing_label = label
	var total_chars: int = label.text.length()
	if total_chars <= 0:
		return
	label.visible_characters = 0
	_typing_in_progress = true
	_typing_tween = create_tween()
	_typing_tween.tween_property(label, "visible_characters", total_chars, total_chars * _char_speed)
	_typing_tween.finished.connect(_on_typing_finished, CONNECT_ONE_SHOT)

func _skip_typing():
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()
		_typing_tween = null
	if _typing_label and is_instance_valid(_typing_label):
		_typing_label.visible_characters = -1
	_typing_in_progress = false

func _on_typing_finished():
	if _typing_label and is_instance_valid(_typing_label):
		_typing_label.visible_characters = -1
	_typing_in_progress = false
	_typing_tween = null

# --- Input handling ---

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

func _trigger_skip_advance():
	_cleanup_for_skip()
	_waiting_for_input = false
	advance_requested.emit()

func _on_skip_pressed():
	if _current_sequence:
		_current_sequence.skip_to_next_background()
		_cleanup_for_skip()
		_trigger_advance()

func _cleanup_for_skip():
	for rect in _active_character_tweens.keys():
		var tween = _active_character_tweens[rect]
		if tween:
			tween.kill()
	_active_character_tweens.clear()
	for rect in [left_char, center_char, right_char]:
		rect.visible = false
		rect.modulate = Color.WHITE
		rect.scale = Vector2.ONE
		rect.pivot_offset = Vector2.ZERO
	var known_rects := [left_char, center_char, right_char, background_rect, background_next_rect]
	for child in get_children():
		if child == null:
			continue
		if child is TextureRect and child not in known_rects and child.owner == null:
			child.queue_free()
	if background_next_rect.visible:
		background_rect.texture = background_next_rect.texture
		background_rect.modulate = Color.WHITE
		background_next_rect.visible = false
		background_next_rect.modulate = Color(1, 1, 1, 0)
	_hide_inner_bands()
	var anim_ids := _portrait_animation_timers.keys().duplicate()
	for char_id in anim_ids:
		_stop_portrait_animation_by_id(char_id)
	_character_side_cache.clear()
	_character_position_cache.clear()
	_character_portrait_cache.clear()
	_character_portrait_scale_cache.clear()

# --- Character display ---

func _show_character(character_data: StoryCharacter, portrait_name: String, side: String, position_mode: String = "", position_value: Vector2 = Vector2.ZERO, portrait_scale: float = 0.0):
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
	var character_id := character_data.id if character_data else ""
	if portrait_scale > 0.0:
		if not character_id.is_empty():
			_character_portrait_scale_cache[character_id] = portrait_scale
	var char_scale: float
	if portrait_scale > 0.0:
		char_scale = portrait_scale
	elif not character_id.is_empty() and _character_portrait_scale_cache.has(character_id):
		char_scale = _character_portrait_scale_cache[character_id]
	else:
		char_scale = character_data.display_scale if character_data else 1.0
	_reset_rect_with_scale(target_rect, side, char_scale)
	var base_pos := target_rect.position
	var target_pos := _resolve_character_position(character_id, side, position_mode, position_value, base_pos)
	if not target_pos.is_equal_approx(base_pos):
		target_rect.position = target_pos
	var char_offset_y: float = character_data.display_offset_y if character_data else 0.0
	_apply_display_offset_y(target_rect, char_offset_y)
	if character_data and not character_data.id.is_empty():
		if not _suppress_animation_reset:
			_stop_portrait_animation_by_id(character_data.id)
		_character_side_cache[character_data.id] = side
		_character_position_cache[character_data.id] = target_pos - base_pos
		_character_portrait_cache[character_data.id] = resolved_portrait
	return target_rect

func hide_character_entry(entry: Cmd.HideCharacter):
	var side := _resolve_character_side(entry.character_id, entry.side_override)
	var target_rect := _get_rect_for_side(side)
	if not target_rect:
		return null
	var pos_offset: Vector2 = _character_position_cache.get(entry.character_id, Vector2.ZERO)
	var target_pos: Vector2 = _default_side_position(side) + pos_offset
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

func _apply_character_exit_effect(target_rect: TextureRect, entry: Cmd.HideCharacter, side: String, character_id: String, target_pos: Vector2) -> Tween:
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
	var delta_x: float = 0.0
	var delta_y: float = 0.0
	match direction:
		"left":
			delta_x = -distance
		"right":
			delta_x = distance
		"up", "top":
			delta_y = -distance
		"down", "bottom":
			delta_y = distance
		_:
			pass
	var end_x: float = target_rect.position.x + delta_x
	var end_y: float = target_rect.position.y + delta_y
	if effect == "slide":
		if not is_zero_approx(delta_x):
			tween.tween_property(target_rect, "position:x", end_x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if not is_zero_approx(delta_y):
			tween.parallel().tween_property(target_rect, "position:y", end_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		_register_character_tween(target_rect, tween)
		return tween
	elif effect == "fade_slide":
		if not is_zero_approx(delta_x):
			tween.tween_property(target_rect, "position:x", end_x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if not is_zero_approx(delta_y):
			tween.parallel().tween_property(target_rect, "position:y", end_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(target_rect, "modulate:a", 0.0, duration)
		tween.finished.connect(func():
			_hide_character_control(target_rect, side, character_id))
		_register_character_tween(target_rect, tween)
		return tween
	elif effect == "shrink" or effect == "fade_shrink":
		var current_scale := target_rect.scale
		var current_pos := target_rect.position
		var visual_center := current_pos + target_rect.size * current_scale * 0.5
		target_rect.pivot_offset = Vector2.ZERO
		tween.tween_property(target_rect, "scale", Vector2.ZERO, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(target_rect, "position", visual_center, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
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
		_character_portrait_scale_cache.erase(character_id)
		_stop_portrait_animation_by_id(character_id)

# --- Portrait animation ---

func start_portrait_animation(entry: Cmd.AnimatePortrait):
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

func stop_portrait_animation(entry: Cmd.StopPortraitAnimation):
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
	var character_data: StoryCharacter = _cast.get(character_id)
	if character_data == null:
		return
	var side: String = _character_side_cache.get(character_id, character_data.default_side)
	_suppress_animation_reset = true
	_show_character(character_data, portrait_name, side)
	_suppress_animation_reset = false

# --- Rect/position utilities ---

func _reset_character_transform(target_rect: Control):
	if target_rect == null:
		return
	target_rect.modulate = Color.WHITE
	var side := "left"
	if target_rect == right_char:
		side = "right"
	elif target_rect == center_char:
		side = "center"
	_reset_rect_with_scale(target_rect, side, 1.0)

func _reset_rect_with_scale(target_rect: Control, side: String, scale_factor: float) -> void:
	target_rect.pivot_offset = Vector2.ZERO
	var tex: Texture2D = target_rect.texture if target_rect is TextureRect else null
	var tex_size := tex.get_size() if tex else target_rect.size
	target_rect.size = tex_size
	var s := scale_factor if scale_factor > 0.0 else 1.0
	target_rect.scale = Vector2(s, s)
	var vp_size := get_viewport_rect().size
	var visual_w := tex_size.x * s
	var visual_h := tex_size.y * s
	target_rect.position.y = vp_size.y - visual_h
	if target_rect == left_char:
		target_rect.position.x = _CHAR_MARGIN
	elif target_rect == right_char:
		target_rect.position.x = vp_size.x - visual_w - _CHAR_MARGIN
	elif target_rect == center_char:
		target_rect.position.x = (vp_size.x - visual_w) / 2.0

func _create_cross_fade_snapshot(source: TextureRect) -> TextureRect:
	var snapshot := TextureRect.new()
	snapshot.texture = source.texture
	snapshot.size = source.size
	snapshot.position = source.position
	snapshot.scale = source.scale
	snapshot.pivot_offset = source.pivot_offset
	snapshot.modulate = source.modulate
	snapshot.flip_h = source.flip_h
	snapshot.expand_mode = source.expand_mode
	snapshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(snapshot)
	move_child(snapshot, source.get_index())
	return snapshot

func _run_cross_fade(old_snapshot: TextureRect, new_rect: TextureRect, duration: float) -> void:
	new_rect.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(new_rect, "modulate:a", 1.0, duration)
	tween.finished.connect(func():
		if is_instance_valid(old_snapshot):
			old_snapshot.queue_free())


func _apply_display_offset_y(target_rect: Control, offset_y: float) -> void:
	if is_zero_approx(offset_y):
		return
	target_rect.position.y += offset_y

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

# --- Background ---

func show_background_entry(entry: Cmd.Background):
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

func apply_bg_filter(entry: Cmd.BgFilter):
	if not entry.enabled:
		background_rect.material = null
		return
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float darken : hint_range(0.0, 1.0) = 0.3;
uniform float desaturate : hint_range(0.0, 1.0) = 0.3;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Desaturate
	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desat = mix(tex.rgb, vec3(gray), desaturate);
	// Darken
	vec3 darkened = desat * (1.0 - darken);
	COLOR = vec4(darkened, tex.a);
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("darken", entry.darken)
	mat.set_shader_parameter("desaturate", entry.desaturate)
	background_rect.material = mat

func play_terminal_effect(entry: Cmd.TerminalEffect):
	# Create overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Fade in black overlay
	var fade_in := create_tween()
	fade_in.tween_property(overlay, "color:a", 0.6, 0.3)
	await fade_in.finished

	# Create terminal text label
	var terminal := RichTextLabel.new()
	terminal.bbcode_enabled = true
	terminal.scroll_active = false
	terminal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	terminal.add_theme_font_size_override("normal_font_size", 18)
	terminal.add_theme_color_override("default_color", Color(0.2, 1.0, 0.3))
	terminal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Add padding
	terminal.offset_left = 60
	terminal.offset_top = 40
	terminal.offset_right = -60
	terminal.offset_bottom = -40
	add_child(terminal)

	# Glitch flash at start
	overlay.color = Color(0.1, 0.3, 0.1, 0.7)
	await get_tree().create_timer(0.05).timeout
	overlay.color = Color(0, 0, 0, 0.6)
	await get_tree().create_timer(0.1).timeout

	# Type out each line
	var full_text := ""
	for i in range(entry.lines.size()):
		var line: String = entry.lines[i]
		for ch_idx in range(line.length()):
			full_text += line[ch_idx]
			terminal.text = full_text + "█"
			await get_tree().create_timer(entry.char_delay).timeout
		full_text += "\n"
		terminal.text = full_text
		if i < entry.lines.size() - 1:
			await get_tree().create_timer(entry.line_delay).timeout

	# Blink cursor a few times
	for blink in range(3):
		terminal.text = full_text + "█"
		await get_tree().create_timer(0.3).timeout
		terminal.text = full_text
		await get_tree().create_timer(0.3).timeout

	# Hold
	await get_tree().create_timer(entry.hold_time).timeout

	# Flash and fade out
	overlay.color = Color(0.2, 1.0, 0.3, 0.4)
	await get_tree().create_timer(0.08).timeout

	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(overlay, "color:a", 0.0, 0.4)
	fade_out.tween_property(terminal, "modulate:a", 0.0, 0.3)
	await fade_out.finished

	terminal.queue_free()
	overlay.queue_free()
	terminal_effect_finished.emit()

func pause_entry(entry: Cmd.Pause):
	if entry.duration <= 0.0:
		return null
	return get_tree().create_timer(entry.duration).timeout

func hide_dialogue_command(_entry: Cmd.HideDialogue):
	_hide_inner_bands()

# --- ShowCharacter command ---

func show_character_command(entry: Cmd.ShowCharacter):
	if entry.character_id.is_empty():
		return
	var char_data: StoryCharacter = _cast.get(entry.character_id)
	if char_data == null:
		return
	var side := _resolve_character_side(entry.character_id, entry.side_override)
	var target_rect := _get_rect_for_side(side)
	var do_cross_fade := entry.transition == "cross_fade" and target_rect != null and target_rect.visible and target_rect.texture != null
	var old_snapshot: TextureRect = null
	if do_cross_fade:
		old_snapshot = _create_cross_fade_snapshot(target_rect)
	var result_rect: TextureRect = _show_character(char_data, entry.portrait_id, side, entry.position_mode, entry.position, entry.portrait_scale)
	if result_rect == null:
		if old_snapshot:
			old_snapshot.queue_free()
		return
	if entry.flip >= 0:
		result_rect.flip_h = (entry.flip == 1)
	elif side == "right":
		result_rect.flip_h = true
	else:
		result_rect.flip_h = false
	if do_cross_fade and old_snapshot:
		_run_cross_fade(old_snapshot, result_rect, entry.transition_duration)
	else:
		var target_pos: Vector2 = result_rect.position
		_apply_character_entry_effect(result_rect, entry, target_pos, side)

func _apply_character_entry_effect(target_rect: TextureRect, entry: Cmd.ShowCharacter, target_pos: Vector2, side: String):
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
		var final_scale := target_rect.scale
		var final_pos := target_rect.position
		var visual_center := final_pos + target_rect.size * final_scale * 0.5
		target_rect.pivot_offset = Vector2.ZERO
		target_rect.scale = Vector2.ZERO
		target_rect.position = visual_center
		if effect == "fade_grow":
			target_rect.modulate = Color(1, 1, 1, 0)
		tween.tween_property(target_rect, "scale", final_scale, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(target_rect, "position", final_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
	var end_x: float = target_rect.position.x
	var end_y: float = target_rect.position.y
	var delta_x: float = 0.0
	var delta_y: float = 0.0
	match direction:
		"left":
			delta_x = -distance
		"right":
			delta_x = distance
		"up", "top":
			delta_y = -distance
		"down", "bottom":
			delta_y = distance
		_:
			pass
	if effect == "slide":
		var tween := create_tween()
		target_rect.position.x = end_x + delta_x
		target_rect.position.y = end_y + delta_y
		if not is_zero_approx(delta_x):
			tween.tween_property(target_rect, "position:x", end_x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if not is_zero_approx(delta_y):
			tween.parallel().tween_property(target_rect, "position:y", end_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_register_character_tween(target_rect, tween)
	elif effect == "fade_slide":
		var tween := create_tween()
		target_rect.position.x = end_x + delta_x
		target_rect.position.y = end_y + delta_y
		target_rect.modulate = Color(1, 1, 1, 0)
		if not is_zero_approx(delta_x):
			tween.tween_property(target_rect, "position:x", end_x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if not is_zero_approx(delta_y):
			tween.parallel().tween_property(target_rect, "position:y", end_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(target_rect, "modulate:a", 1.0, duration)
		_register_character_tween(target_rect, tween)
	else:
		target_rect.modulate = Color.WHITE

# --- Band ---

func set_inner_band_color(color: Color) -> void:
	# Bubble image keeps original colors (no tinting)
	var hover_color := Color(color.r + 0.12, color.g + 0.12, color.b + 0.12, color.a)
	for btn in _menu_bar.get_children():
		if btn is Button:
			var style_normal: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()
			style_normal.bg_color = color
			btn.add_theme_stylebox_override("normal", style_normal)
			var style_hover: StyleBoxFlat = btn.get_theme_stylebox("hover").duplicate()
			style_hover.bg_color = hover_color
			btn.add_theme_stylebox_override("hover", style_hover)

func _hide_inner_bands() -> void:
	dialogue_band_left.visible = false
	dialogue_band_right.visible = false
	dialogue_band_left_speaker.visible = false
	dialogue_band_right_speaker.visible = false

func _set_narrator_vbox_visible(vis: bool) -> void:
	for child in dialogue_band.get_node("VBox").get_children():
		child.visible = vis

func apply_band_command(entry: Cmd.Band):
	if not dialogue_band:
		return null
	if not entry.visible:
		dialogue_band.visible = false
		_hide_inner_bands()
		return null
	dialogue_band.visible = true
	var char_data: StoryCharacter = null
	var side := ""
	if not entry.speaker_id.is_empty() and entry.speaker_id != "narrator":
		char_data = _cast.get(entry.speaker_id)
		if char_data:
			side = _resolve_character_side(entry.speaker_id, entry.side_override)
	var band_speaker: Label
	var band_body: Label
	if side == "left" or side == "right":
		_set_narrator_vbox_visible(false)
		if side == "left":
			dialogue_band_left.visible = true
			dialogue_band_right.visible = false
			band_speaker = dialogue_band_left_speaker
			band_body = dialogue_band_left_body
			dialogue_band_right_speaker.visible = false
		else:
			dialogue_band_left.visible = false
			dialogue_band_right.visible = true
			band_speaker = dialogue_band_right_speaker
			band_body = dialogue_band_right_body
			dialogue_band_left_speaker.visible = false
		# Dark text for bubble background
		band_body.add_theme_color_override("font_color", Color(0.15, 0.12, 0.18))
	else:
		_hide_inner_bands()
		_set_narrator_vbox_visible(true)
		band_speaker = dialogue_band_speaker
		band_body = dialogue_band_body
	if entry.clear_text or not entry.text.is_empty():
		band_body.text = entry.text
		# Start typewriter effect
		if not entry.text.is_empty() and entry.wait_for_input:
			_start_typewriter(band_body)
	if char_data:
		_show_character(char_data, entry.portrait_id, side)
		if not char_data.display_name.is_empty():
			band_speaker.visible = true
			band_speaker.text = char_data.display_name
		else:
			band_speaker.visible = false
	else:
		band_speaker.visible = false
	if entry.wait_for_input:
		return _prepare_wait_for_advance(entry.min_duration)
	return null

# --- Texture loading ---

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

# --- Side/position resolution ---

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
	var rect := _get_rect_for_side(side)
	var vp_size := get_viewport_rect().size
	var tex: Texture2D = rect.texture if rect is TextureRect and rect.texture else null
	var tex_size := tex.get_size() if tex else (rect.size if rect else Vector2.ZERO)
	var s: float = rect.scale.x if rect else 1.0
	var visual_w := tex_size.x * s
	var visual_h := tex_size.y * s
	var x: float
	match side:
		"left":
			x = _CHAR_MARGIN
		"right":
			x = vp_size.x - visual_w - _CHAR_MARGIN
		"center":
			x = (vp_size.x - visual_w) / 2.0
		_:
			x = _CHAR_MARGIN
	return Vector2(x, vp_size.y - visual_h)

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

func _resolve_character_position(character_id: String, side: String, position_mode: String, position_value: Vector2, base: Vector2 = Vector2.ZERO) -> Vector2:
	var mode := position_mode.strip_edges().to_lower()
	match mode:
		"absolute":
			return position_value
		"offset":
			return base + position_value
		"normalized":
			var vp_size := get_viewport_rect().size
			return Vector2(vp_size.x * position_value.x, vp_size.y * position_value.y)
		_:
			if not character_id.is_empty() and _character_position_cache.has(character_id):
				return base + _character_position_cache[character_id]
			return base

class _SignalRelay:
	extends RefCounted
	signal completed
