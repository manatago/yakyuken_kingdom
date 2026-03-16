extends Control
class_name BattleScene

const Cmd = preload("res://story/StoryCommands.gd")

signal battle_finished(result: String)

enum Hand { ROCK, SCISSORS, PAPER }
enum Grade { NORMAL = 1, BRONZE = 2, SILVER = 3, GOLD = 4, PLATINUM = 5 }

const HAND_NAMES := {
	Hand.ROCK: "グー",
	Hand.SCISSORS: "チョキ",
	Hand.PAPER: "パー",
}

const HAND_KEYS := {
	Hand.ROCK: "rock",
	Hand.SCISSORS: "scissors",
	Hand.PAPER: "paper",
}

const HAND_FROM_KEY := {
	"rock": Hand.ROCK,
	"scissors": Hand.SCISSORS,
	"paper": Hand.PAPER,
}

const GRADE_NAMES := {
	Grade.NORMAL: "ノーマル",
	Grade.BRONZE: "ブロンズ",
	Grade.SILVER: "シルバー",
	Grade.GOLD: "ゴールド",
	Grade.PLATINUM: "プラチナ",
}

const GRADE_COLORS := {
	Grade.NORMAL: Color.WHITE,
	Grade.BRONZE: Color(0.8, 0.5, 0.2),
	Grade.SILVER: Color(0.75, 0.75, 0.8),
	Grade.GOLD: Color(1.0, 0.85, 0.2),
	Grade.PLATINUM: Color(0.85, 0.92, 1.0),
}

# --- Node refs ---
@onready var story_layer := $StoryLayer
@onready var card_bar := $CardBar
@onready var card_selection := $CardBar/CardSelection
@onready var action_prompt := $ActionPrompt
@onready var card_label := $ActionPrompt/VBox/CardLabel
@onready var confirm_button := $ActionPrompt/VBox/ConfirmButton
@onready var player_hp_bar := $PlayerHPPanel/HBox/PlayerHPBar
@onready var player_hp_label := $PlayerHPPanel/HBox/PlayerHPLabel
@onready var opponent_hp_bar := $OpponentHPPanel/HBox/OpponentHPBar
@onready var opponent_hp_label := $OpponentHPPanel/HBox/OpponentHPLabel
@onready var item_slots := $ItemPanel/ItemSlots
@onready var item_panel := $ItemPanel
@onready var speech_bubble := $SpeechBubble
@onready var bubble_label := $SpeechBubble/BubbleLabel
@onready var janken_overlay := $JankenOverlay
@onready var overlay_player_card := $JankenOverlay/PlayerCard
@onready var overlay_opponent_card := $JankenOverlay/OpponentCard
@onready var overlay_result_label := $JankenOverlay/ResultLabel

# --- State ---
var _chapter: BattleChapterBase = null
var _card_paths: Dictionary = {}
var _card_back_tex: Texture2D = null
var _card_textures: Dictionary = {}
var _opponent_outfit: int = 0
var _player_outfit: int = 0

# Card selection state
var _selected_hand: Hand = Hand.ROCK
var _selected_grade: int = Grade.NORMAL
var _selected_button: TextureButton = null
var _hand_selected := false
var _hand_confirmed := false

# Deck & inventory
var _player_inventory: Array = []   # [{hand: "rock", grade: 1}, ...] — all owned cards
var _player_deck: Array = []        # [{hand: Hand, grade: int}, ...] — 9 cards for battle
var _opponent_deck: Array = []      # [{hand: Hand, grade: int}, ...]
var _deck_buttons: Array = []       # [{hand, grade, button, container, used}, ...]
var _captured_by_player: Array = [] # opponent's lost cards
var _captured_by_opponent: Array = [] # player's lost cards

# Deck building state
var _deck_building := false
var _deck_ready := false

# Story scene
var _story_scene: StoryScene = null
var _story_scene_tscn = preload("res://StoryScene.tscn")
var _cast: Dictionary = {}
var _dsl: Cmd = null
var _pending_commands: Array = []
var _deck_rect: TextureRect = null
var _initial_bg_texture: Texture2D = null

# Exposed to chapter outfit functions
var opponent_outfit: int:
	get: return _opponent_outfit
var player_outfit: int:
	get: return _player_outfit
var player_deck_count: int:
	get: return _count_remaining_deck()

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirm_button.visible = false
	action_prompt.visible = false
	janken_overlay.visible = false
	speech_bubble.visible = false
	_setup_bubble_style()

func setup(cast: Dictionary, bg_texture: Texture2D = null, inventory: Array = []):
	_cast = cast
	_initial_bg_texture = bg_texture
	_player_inventory = inventory.duplicate(true)

func start_battle(chapter: BattleChapterBase):
	_chapter = chapter
	add_child(_chapter)
	_card_paths = chapter.get_card_paths()
	_card_back_tex = load(chapter.get_card_back())
	_opponent_outfit = chapter.get_opponent_outfit_count()
	_player_outfit = chapter.get_player_outfit_count()
	_dsl = Cmd.new(_cast)
	_captured_by_player.clear()
	_captured_by_opponent.clear()

	# Load card textures
	_card_textures = {
		Hand.ROCK: load(_card_paths.get("rock", "res://assets/battle/cards/rock.png")),
		Hand.SCISSORS: load(_card_paths.get("scissors", "res://assets/battle/cards/scissors.png")),
		Hand.PAPER: load(_card_paths.get("paper", "res://assets/battle/cards/paper.png")),
	}

	# Parse opponent deck
	_opponent_deck.clear()
	for card in chapter.get_opponent_deck():
		_opponent_deck.append({
			"hand": HAND_FROM_KEY.get(card.hand, Hand.ROCK),
			"grade": int(card.grade),
			"used": false,
		})

	# Embedded story scene
	_story_scene = _story_scene_tscn.instantiate()
	story_layer.add_child(_story_scene)
	_story_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_scene.set_cast(_cast)
	if _initial_bg_texture:
		_story_scene.background_rect.texture = _initial_bg_texture
	_apply_bg_blur(_story_scene.background_rect, 15.0)

	# Show battle UI elements
	card_bar.visible = true
	item_panel.visible = true

	# Show opponent before deck building
	if _chapter.has_method("setup_scene"):
		_chapter.call("setup_scene", self)
		await _flush_pending()

	# Deck building phase
	await _deck_building_phase()

	# Build deck card buttons
	_build_deck_buttons()
	_update_score()

	_run_battle()

# ============================================================
# Deck Building Phase
# ============================================================

func _deck_building_phase():
	_deck_building = true
	_deck_ready = false
	_player_deck.clear()

	# Show inventory in item slots
	_refresh_inventory_display()

	# Show instruction
	action_prompt.visible = true
	card_label.text = "デッキに9枚セットしてください"
	confirm_button.text = "準備完了"
	confirm_button.visible = false

	# Wait for player to fill deck
	while not _deck_ready:
		await get_tree().process_frame

	confirm_button.visible = false
	action_prompt.visible = false
	confirm_button.text = "勝負！"
	_deck_building = false

	# Clear inventory display for battle
	_clear_item_display()

func _refresh_inventory_display():
	_clear_item_display()

	# Group inventory by hand+grade, count available (not in deck)
	var counts: Dictionary = {}
	for card in _player_inventory:
		var key := "%s_%d" % [card.hand, int(card.grade)]
		if not counts.has(key):
			counts[key] = {"hand": card.hand, "grade": int(card.grade), "total": 0, "in_deck": 0}
		counts[key].total += 1

	# Count how many of each type are already in deck
	for dc in _player_deck:
		var key := "%s_%d" % [HAND_KEYS[dc.hand], dc.grade]
		if counts.has(key):
			counts[key].in_deck += 1

	# Create buttons for each card type
	var keys = counts.keys()
	keys.sort()
	for key in keys:
		var info = counts[key]
		var available: int = info.total - info.in_deck
		var hand_enum: Hand = HAND_FROM_KEY.get(info.hand, Hand.ROCK)
		var grade: int = info.grade

		var slot := VBoxContainer.new()
		slot.name = "ItemSlot_" + key
		slot.add_theme_constant_override("separation", 2)
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(55, 78)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.texture_normal = _card_textures.get(hand_enum)
		btn.modulate = GRADE_COLORS.get(grade, Color.WHITE)
		btn.disabled = available <= 0
		if available <= 0:
			btn.modulate = Color(0.3, 0.3, 0.3, 0.5)
		btn.pressed.connect(_on_inventory_card_pressed.bind(hand_enum, grade))
		slot.add_child(btn)

		var label := Label.new()
		var grade_short: String = GRADE_NAMES.get(grade, "?")
		label.text = "%s %s x%d" % [HAND_NAMES[hand_enum], grade_short, available]
		var ls := LabelSettings.new()
		ls.font_size = 10
		ls.font_color = GRADE_COLORS.get(grade, Color.WHITE)
		label.label_settings = ls
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(label)

		item_slots.add_child(slot)

func _on_inventory_card_pressed(hand: Hand, grade: int):
	if not _deck_building:
		return
	if _player_deck.size() >= 9:
		return

	# Check availability
	var key_str := "%s_%d" % [HAND_KEYS[hand], grade]
	var total := 0
	for card in _player_inventory:
		if card.hand == HAND_KEYS[hand] and int(card.grade) == grade:
			total += 1
	var in_deck := 0
	for dc in _player_deck:
		if dc.hand == hand and dc.grade == grade:
			in_deck += 1
	if in_deck >= total:
		return

	_player_deck.append({"hand": hand, "grade": grade})
	_refresh_inventory_display()
	_refresh_deck_preview()

	if _player_deck.size() >= 9:
		confirm_button.visible = true

func _refresh_deck_preview():
	# Show deck cards in card_selection area
	for child in card_selection.get_children():
		child.queue_free()

	for i in range(_player_deck.size()):
		var dc = _player_deck[i]
		var container := Control.new()
		container.custom_minimum_size = Vector2(70, 100)
		container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var btn := TextureButton.new()
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.texture_normal = _card_textures.get(dc.hand)
		btn.modulate = GRADE_COLORS.get(dc.grade, Color.WHITE)
		btn.pressed.connect(_on_deck_preview_pressed.bind(i))
		container.add_child(btn)

		card_selection.add_child(container)

func _on_deck_preview_pressed(index: int):
	if not _deck_building:
		return
	if index < 0 or index >= _player_deck.size():
		return
	_player_deck.remove_at(index)
	confirm_button.visible = false
	_refresh_inventory_display()
	_refresh_deck_preview()

func _clear_item_display():
	for child in item_slots.get_children():
		child.queue_free()

# ============================================================
# Public API — called from chapter outfit functions
# ============================================================

func character(id: String) -> Cmd.CharacterHandle:
	return Cmd.CharacterHandle.new(_dsl, id, Callable(self, "_add_command"))

func background(path: String, fade := 0.0):
	_add_command(_dsl.background(path, fade))

func pause(duration: float):
	_add_command(_dsl.pause(duration))

func narrator_band(text: String):
	_pending_commands.append({"_battle_bubble": true, "text": text})

func show_band():
	_add_command(_dsl.band_show())

func hide_band():
	_add_command(_dsl.band_hide())

func band_color(color_or_name):
	_add_command(_dsl.band_color(color_or_name))

func hide_dialogue():
	_add_command(_dsl.hide_dialogue())

func deck(path: String, extra: Dictionary = {}):
	if path.is_empty():
		if _deck_rect:
			_deck_rect.visible = false
	else:
		_setup_deck(path, extra)

func _setup_deck(path: String, extra: Dictionary = {}):
	var tex = load(path)
	if not tex is Texture2D:
		return
	if not _deck_rect:
		_deck_rect = TextureRect.new()
		_deck_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_deck_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_deck_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_story_scene.add_child(_deck_rect)
		_story_scene.move_child(_deck_rect, 2)
	_deck_rect.texture = tex
	_deck_rect.visible = true
	var s: float = extra.get("scale", 1.0)
	var tex_size: Vector2 = tex.get_size()
	var vp_size := _story_scene.get_viewport_rect().size
	var scaled_w := tex_size.x * s
	var scaled_h := tex_size.y * s
	_deck_rect.size = Vector2(scaled_w, scaled_h)
	var base_x := (vp_size.x - scaled_w) / 2.0
	var base_y := vp_size.y - scaled_h
	var pos_offset = extra.get("position", null)
	if pos_offset is Array and pos_offset.size() >= 2:
		base_x += pos_offset[0]
		base_y += pos_offset[1]
	elif pos_offset is Vector2:
		base_x += pos_offset.x
		base_y += pos_offset.y
	_deck_rect.position = Vector2(base_x, base_y)

func _add_command(command):
	if command == null:
		return
	# Intercept band commands → convert to battle speech bubble
	if command is Cmd.Band and not command.text.is_empty():
		_pending_commands.append({"_battle_bubble": true, "text": command.text})
		return
	_pending_commands.append(command)

# --- Card & Item selection ---

func select_hand() -> Dictionary:
	await _flush_pending()
	_set_cards_enabled(true)
	_hand_selected = false
	_hand_confirmed = false
	_selected_button = null
	_deselect_all_cards()
	action_prompt.visible = true
	card_label.text = "カードを選択してください"
	confirm_button.visible = false
	# Show remaining inventory during selection
	_show_battle_item_display()
	while not _hand_confirmed:
		await get_tree().process_frame
	_set_cards_enabled(false)
	confirm_button.visible = false
	action_prompt.visible = false
	_consume_selected_card()
	_clear_item_display()
	_update_score()
	return {"hand": _selected_hand, "grade": _selected_grade, "item": null}

# --- Janken overlay ---

func janken(selection: Dictionary) -> String:
	await _flush_pending()
	var player_hand: Hand = selection.get("hand", Hand.ROCK)
	var player_grade: int = selection.get("grade", Grade.NORMAL)
	var opp_pick := _pick_opponent_card()
	var opponent_hand: Hand = opp_pick.hand
	var opponent_grade: int = opp_pick.grade
	var result := _judge_with_grade(player_hand, player_grade, opponent_hand, opponent_grade)

	await _play_janken_overlay(player_hand, opponent_hand, result)

	if result == "win":
		_opponent_outfit -= 1
		# Capture opponent's card
		_captured_by_player.append({"hand": HAND_KEYS[opponent_hand], "grade": opponent_grade})
	elif result == "lose":
		_player_outfit -= 1
		# Opponent captures player's card
		_captured_by_opponent.append({"hand": HAND_KEYS[player_hand], "grade": player_grade})
	elif result == "draw":
		# True draw (same hand, same grade) — refund both
		_refund_card(player_hand, player_grade)
		_refund_opponent_card(opponent_hand, opponent_grade)
	_update_score()
	return result

# ============================================================
# Internal battle flow
# ============================================================

func _run_battle():
	while _opponent_outfit > 0 and _player_outfit > 0:
		# Check if player deck is empty
		if _count_remaining_deck() <= 0:
			break
		# Check if opponent deck is empty
		if _count_remaining_opponent_deck() <= 0:
			break

		var func_name := "outfit_%d" % _opponent_outfit
		if _chapter.has_method(func_name):
			await _chapter.call(func_name, self)
			await _flush_pending()

	# Determine result
	var final_result: String
	if _opponent_outfit <= 0:
		final_result = "win"
	elif _player_outfit <= 0:
		final_result = "lose"
	elif _count_remaining_deck() <= 0 and _count_remaining_opponent_deck() <= 0:
		# Both decks empty simultaneously
		final_result = "draw"
	elif _count_remaining_deck() <= 0:
		# Player deck empty first = lose
		final_result = "lose"
	elif _count_remaining_opponent_deck() <= 0:
		# Opponent deck empty first = win
		final_result = "win"
	else:
		final_result = "draw"

	var end_func: String
	if final_result == "win":
		end_func = "victory"
	elif final_result == "lose":
		end_func = "defeat"
	else:
		end_func = ""

	if not end_func.is_empty() and _chapter.has_method(end_func):
		await _chapter.call(end_func, self)
		await _flush_pending()

	_cleanup()
	battle_finished.emit(final_result)

# Returns battle results for Main.gd to process inventory changes
func get_battle_rewards() -> Dictionary:
	return {
		"captured_by_player": _captured_by_player.duplicate(true),
		"captured_by_opponent": _captured_by_opponent.duplicate(true),
	}

# --- Janken overlay animation ---

func _play_janken_overlay(player_hand: Hand, opponent_hand: Hand, result: String):
	janken_overlay.visible = true
	overlay_result_label.visible = false

	var vp_size := get_viewport_rect().size
	var card_w := 200.0
	var card_h := 300.0
	var center_y := (vp_size.y - card_h) / 2.0 - 80.0
	var player_end_x := vp_size.x / 2.0 - card_w - 30.0
	var opponent_end_x := vp_size.x / 2.0 + 30.0

	overlay_player_card.texture = _card_back_tex
	overlay_opponent_card.texture = _card_back_tex
	overlay_player_card.size = Vector2(card_w, card_h)
	overlay_opponent_card.size = Vector2(card_w, card_h)
	overlay_player_card.pivot_offset = Vector2(card_w / 2.0, card_h / 2.0)
	overlay_opponent_card.pivot_offset = Vector2(card_w / 2.0, card_h / 2.0)
	overlay_player_card.scale = Vector2.ONE
	overlay_opponent_card.scale = Vector2.ONE
	overlay_player_card.position = Vector2(-card_w - 50, center_y)
	overlay_opponent_card.position = Vector2(vp_size.x + 50, center_y)
	overlay_player_card.visible = false
	overlay_opponent_card.visible = false

	# 1. Opponent card slides in from right
	overlay_opponent_card.visible = true
	var slide_opp := create_tween()
	slide_opp.tween_property(overlay_opponent_card, "position:x", opponent_end_x, 1.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await slide_opp.finished

	await get_tree().create_timer(0.3).timeout

	# 2. Player card slides in from left
	overlay_player_card.visible = true
	var slide_plr := create_tween()
	slide_plr.tween_property(overlay_player_card, "position:x", player_end_x, 1.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await slide_plr.finished

	await get_tree().create_timer(0.5).timeout

	# 3. Opponent card flips
	var opp_tex_path: String = _card_paths.get(HAND_KEYS[opponent_hand], "")
	var flip_opp_hide := create_tween()
	flip_opp_hide.tween_property(overlay_opponent_card, "scale:x", 0.0, 0.3)
	await flip_opp_hide.finished
	if not opp_tex_path.is_empty():
		overlay_opponent_card.texture = load(opp_tex_path)
	var flip_opp_show := create_tween()
	flip_opp_show.tween_property(overlay_opponent_card, "scale:x", 1.0, 0.3)
	await flip_opp_show.finished

	await get_tree().create_timer(0.4).timeout

	# 4. Player card flips
	var plr_tex_path: String = _card_paths.get(HAND_KEYS[player_hand], "")
	var flip_plr_hide := create_tween()
	flip_plr_hide.tween_property(overlay_player_card, "scale:x", 0.0, 0.3)
	await flip_plr_hide.finished
	if not plr_tex_path.is_empty():
		overlay_player_card.texture = load(plr_tex_path)
	var flip_plr_show := create_tween()
	flip_plr_show.tween_property(overlay_player_card, "scale:x", 1.0, 0.3)
	await flip_plr_show.finished

	# Show result
	_show_overlay_result(result)
	await get_tree().create_timer(1.5).timeout

	# Fade out overlay
	var fade_out := create_tween()
	fade_out.tween_property(janken_overlay, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	janken_overlay.visible = false
	janken_overlay.modulate = Color.WHITE

func _show_overlay_result(outcome: String):
	match outcome:
		"win":
			overlay_result_label.text = "WIN!"
			overlay_result_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		"lose":
			overlay_result_label.text = "LOSE..."
			overlay_result_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.8))
		"draw":
			overlay_result_label.text = "DRAW"
			overlay_result_label.add_theme_color_override("font_color", Color.WHITE)
	overlay_result_label.pivot_offset = overlay_result_label.size / 2.0
	overlay_result_label.scale = Vector2(0.3, 0.3)
	overlay_result_label.modulate = Color(1, 1, 1, 0)
	overlay_result_label.visible = true
	var pop := create_tween()
	pop.set_parallel(true)
	pop.tween_property(overlay_result_label, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(overlay_result_label, "modulate:a", 1.0, 0.3)
	await pop.finished

# --- Card button handlers ---

func _on_card_button_pressed(container: Control, btn: TextureButton, hand: Hand, grade: int):
	if btn.disabled:
		return
	_deselect_all_cards()
	_selected_hand = hand
	_selected_grade = grade
	_selected_button = btn
	_hand_selected = true
	var check: Label = container.get_node_or_null("CheckMark")
	if check:
		check.visible = true
	confirm_button.visible = true

func _on_confirm_pressed():
	if _deck_building:
		if _player_deck.size() >= 9:
			_deck_ready = true
	elif _hand_selected:
		_hand_confirmed = true

func _deselect_all_cards():
	for entry in _deck_buttons:
		var check: Label = entry.container.get_node_or_null("CheckMark")
		if check:
			check.visible = false
	_selected_button = null

func _consume_selected_card():
	if _selected_button == null:
		return
	for entry in _deck_buttons:
		if entry.button == _selected_button:
			entry.used = true
			_selected_button.disabled = true
			_selected_button.material = null
			_selected_button.modulate = Color(0.4, 0.4, 0.4, 0.6)
			var check: Label = entry.container.get_node_or_null("CheckMark")
			if check:
				check.visible = false
			break
	_selected_button = null

func _refund_card(hand: Hand, grade: int):
	for i in range(_deck_buttons.size() - 1, -1, -1):
		var entry = _deck_buttons[i]
		if entry.hand == hand and entry.grade == grade and entry.used:
			entry.used = false
			entry.button.disabled = false
			entry.button.modulate = Color.WHITE
			if grade > Grade.NORMAL:
				entry.button.material = _create_grade_glow_material(grade)
			break

func _refund_opponent_card(hand: Hand, grade: int):
	for i in range(_opponent_deck.size() - 1, -1, -1):
		if _opponent_deck[i].hand == hand and _opponent_deck[i].grade == grade and _opponent_deck[i].used:
			_opponent_deck[i].used = false
			break

# --- Flush commands ---

func _flush_pending():
	if _pending_commands.is_empty():
		return
	var cmds := _pending_commands.duplicate()
	_pending_commands.clear()

	# Split into story commands and bubble commands, process in order
	var story_batch: Array = []
	for cmd in cmds:
		if cmd is Dictionary and cmd.has("_battle_bubble"):
			# Flush any accumulated story commands first
			if not story_batch.is_empty():
				var seq := Cmd.Sequence.new()
				seq.entries = story_batch.duplicate()
				story_batch.clear()
				await _story_scene.play_sequence(seq)
			# Show bubble and wait for input
			await _show_bubble(cmd.text)
		else:
			story_batch.append(cmd)

	# Flush remaining story commands
	if not story_batch.is_empty():
		var seq := Cmd.Sequence.new()
		seq.entries = story_batch
		await _story_scene.play_sequence(seq)

# --- AI / Opponent card pick ---

func _pick_opponent_card() -> Dictionary:
	# Collect available cards
	var available: Array = []
	for i in range(_opponent_deck.size()):
		if not _opponent_deck[i].used:
			available.append(i)

	if available.is_empty():
		return {"hand": Hand.ROCK, "grade": Grade.NORMAL}

	# Random pick from available
	var pick_idx: int = available[randi() % available.size()]
	_opponent_deck[pick_idx].used = true
	return {"hand": _opponent_deck[pick_idx].hand, "grade": _opponent_deck[pick_idx].grade}

func _count_remaining_deck() -> int:
	var count := 0
	for entry in _deck_buttons:
		if not entry.used:
			count += 1
	return count

func _count_remaining_opponent_deck() -> int:
	var count := 0
	for entry in _opponent_deck:
		if not entry.used:
			count += 1
	return count

# --- Judgment ---

func _judge_with_grade(player_hand: Hand, player_grade: int, opponent_hand: Hand, opponent_grade: int) -> String:
	if player_hand != opponent_hand:
		# Normal janken rules
		if (player_hand == Hand.ROCK and opponent_hand == Hand.SCISSORS) or \
		   (player_hand == Hand.SCISSORS and opponent_hand == Hand.PAPER) or \
		   (player_hand == Hand.PAPER and opponent_hand == Hand.ROCK):
			return "win"
		return "lose"
	# Same hand — compare grade
	if player_grade > opponent_grade:
		return "win"
	elif player_grade < opponent_grade:
		return "lose"
	return "draw"

# --- HUD ---

func _update_score():
	var plr_max: int = _chapter.get_player_outfit_count()
	var opp_max: int = _chapter.get_opponent_outfit_count()
	var remaining := _count_remaining_deck()

	# Update HP bars
	player_hp_bar.max_value = plr_max
	player_hp_bar.value = _player_outfit
	opponent_hp_bar.max_value = opp_max
	opponent_hp_bar.value = _opponent_outfit

	# Style HP bars
	var plr_style := StyleBoxFlat.new()
	var plr_ratio: float = float(_player_outfit) / float(plr_max) if plr_max > 0 else 0.0
	plr_style.bg_color = Color(0.2, 0.7, 0.3, 0.9)
	plr_style.corner_radius_top_left = 3
	plr_style.corner_radius_top_right = 3
	plr_style.corner_radius_bottom_right = 3
	plr_style.corner_radius_bottom_left = 3
	player_hp_bar.add_theme_stylebox_override("fill", plr_style)

	var opp_style := StyleBoxFlat.new()
	opp_style.bg_color = Color(0.8, 0.2, 0.2, 0.9)
	opp_style.corner_radius_top_left = 3
	opp_style.corner_radius_top_right = 3
	opp_style.corner_radius_bottom_right = 3
	opp_style.corner_radius_bottom_left = 3
	opponent_hp_bar.add_theme_stylebox_override("fill", opp_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.12, 0.2, 0.8)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.corner_radius_bottom_left = 3
	player_hp_bar.add_theme_stylebox_override("background", bg_style)
	opponent_hp_bar.add_theme_stylebox_override("background", bg_style.duplicate())

	player_hp_label.text = "HP: %d/%d" % [_player_outfit, plr_max]
	opponent_hp_label.text = "HP: %d/%d" % [_opponent_outfit, opp_max]
	card_label.text = "手札からカードを選べ  残り %d枚" % remaining

func _set_cards_enabled(enabled: bool):
	for entry in _deck_buttons:
		if entry.used:
			entry.button.disabled = true
		else:
			entry.button.disabled = not enabled

func _build_deck_buttons():
	# Clear card_selection area
	for child in card_selection.get_children():
		child.queue_free()
	_deck_buttons.clear()

	for card in _player_deck:
		var hand: Hand = card.hand
		var grade: int = card.grade

		var container := Control.new()
		container.custom_minimum_size = Vector2(70, 100)
		container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var btn := TextureButton.new()
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.texture_normal = _card_textures.get(hand)
		btn.disabled = true
		btn.pressed.connect(_on_card_button_pressed.bind(container, btn, hand, grade))
		if grade > Grade.NORMAL:
			btn.material = _create_grade_glow_material(grade)
		container.add_child(btn)

		# Grade label at bottom
		if grade > Grade.NORMAL:
			var grade_label := Label.new()
			grade_label.text = GRADE_NAMES.get(grade, "")
			var gls := LabelSettings.new()
			gls.font_size = 10
			gls.font_color = GRADE_COLORS.get(grade, Color.WHITE)
			gls.outline_color = Color(0, 0, 0, 0.8)
			gls.outline_size = 3
			grade_label.label_settings = gls
			grade_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			grade_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(grade_label)

		var check := Label.new()
		check.name = "CheckMark"
		check.text = "✓"
		var ls := LabelSettings.new()
		ls.font_color = Color.GREEN
		ls.font_size = 48
		ls.outline_color = Color.GREEN
		ls.outline_size = 12
		check.label_settings = ls
		check.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		check.visible = false
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(check)

		card_selection.add_child(container)
		_deck_buttons.append({"hand": hand, "grade": grade, "button": btn, "container": container, "used": false})

func _show_battle_item_display():
	_clear_item_display()
	# Show remaining deck cards grouped by type+grade
	var counts: Dictionary = {}
	for entry in _deck_buttons:
		if entry.used:
			continue
		var key := "%s_%d" % [HAND_KEYS[entry.hand], entry.grade]
		if not counts.has(key):
			counts[key] = {"hand": entry.hand, "grade": entry.grade, "count": 0}
		counts[key].count += 1

	var keys = counts.keys()
	keys.sort()
	for key in keys:
		var info = counts[key]
		var label := Label.new()
		var grade_name: String = GRADE_NAMES.get(info.grade, "?")
		label.text = "%s%s x%d" % [grade_name, HAND_NAMES[info.hand], info.count]
		var ls := LabelSettings.new()
		ls.font_size = 14
		ls.font_color = GRADE_COLORS.get(info.grade, Color.WHITE)
		label.label_settings = ls
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_slots.add_child(label)

func _setup_bubble_style():
	bubble_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))

func _show_bubble(text: String):
	bubble_label.text = text
	speech_bubble.visible = true
	speech_bubble.modulate = Color(1, 1, 1, 0)
	var fade_in := create_tween()
	fade_in.tween_property(speech_bubble, "modulate:a", 1.0, 0.2)
	await fade_in.finished

	# Wait for click/input to dismiss
	await _wait_for_input()

	var fade_out := create_tween()
	fade_out.tween_property(speech_bubble, "modulate:a", 0.0, 0.15)
	await fade_out.finished
	speech_bubble.visible = false

func _wait_for_input():
	var input_received := false
	while not input_received:
		if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			input_received = true
			# Wait one frame to prevent double-trigger
			await get_tree().process_frame
		else:
			await get_tree().process_frame

func _create_grade_glow_material(grade: int) -> ShaderMaterial:
	var glow_color: Color = GRADE_COLORS.get(grade, Color.WHITE)
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.3;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Edge glow: stronger near edges
	float edge_x = min(UV.x, 1.0 - UV.x) * 2.0;
	float edge_y = min(UV.y, 1.0 - UV.y) * 2.0;
	float edge = 1.0 - min(edge_x, edge_y);
	edge = smoothstep(0.6, 1.0, edge);
	vec4 glow = glow_color * edge * glow_strength;
	COLOR = tex + glow;
	COLOR.a = tex.a;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("glow_color", glow_color)
	match grade:
		Grade.BRONZE: mat.set_shader_parameter("glow_strength", 0.25)
		Grade.SILVER: mat.set_shader_parameter("glow_strength", 0.35)
		Grade.GOLD: mat.set_shader_parameter("glow_strength", 0.5)
		Grade.PLATINUM: mat.set_shader_parameter("glow_strength", 0.65)
	return mat

func _apply_bg_blur(bg_rect: TextureRect, amount: float = 3.0):
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform float blur_amount : hint_range(0.0, 8.0) = 3.0;
void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE * blur_amount;
	vec4 col = texture(TEXTURE, UV) * 0.16;
	col += texture(TEXTURE, UV + vec2(ps.x, 0.0)) * 0.12;
	col += texture(TEXTURE, UV - vec2(ps.x, 0.0)) * 0.12;
	col += texture(TEXTURE, UV + vec2(0.0, ps.y)) * 0.12;
	col += texture(TEXTURE, UV - vec2(0.0, ps.y)) * 0.12;
	col += texture(TEXTURE, UV + vec2(ps.x, ps.y)) * 0.09;
	col += texture(TEXTURE, UV - vec2(ps.x, ps.y)) * 0.09;
	col += texture(TEXTURE, UV + vec2(ps.x, -ps.y)) * 0.09;
	col += texture(TEXTURE, UV - vec2(ps.x, -ps.y)) * 0.09;
	COLOR = col;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("blur_amount", amount)

	bg_rect.material = mat

func _cleanup():
	_deck_rect = null
	if _story_scene:
		_story_scene.queue_free()
		_story_scene = null
	if _chapter and _chapter.get_parent() == self:
		remove_child(_chapter)
		_chapter.queue_free()
		_chapter = null
