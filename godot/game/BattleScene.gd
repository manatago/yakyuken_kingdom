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
@onready var auto_button := $ActionPrompt/VBox/ButtonRow/AutoButton
@onready var confirm_button := $ActionPrompt/VBox/ButtonRow/ConfirmButton
@onready var player_hp_bar := $PlayerHPPanel/VBox/PlayerHPBarFrame/PlayerHPBar
@onready var player_hp_bar_frame := $PlayerHPPanel/VBox/PlayerHPBarFrame
@onready var player_hp_label := $PlayerHPPanel/VBox/PlayerHPLabel
@onready var opponent_hp_bar := $OpponentHPPanel/VBox/OpponentHPBarFrame/OpponentHPBar
@onready var opponent_hp_bar_frame := $OpponentHPPanel/VBox/OpponentHPBarFrame
@onready var opponent_hp_label := $OpponentHPPanel/VBox/OpponentHPLabel
@onready var item_slots := $ItemPanel/ItemSlots
@onready var item_panel := $ItemPanel
@onready var hand_panel := $HandPanel
@onready var hand_slots := $HandPanel/HandSlots
@onready var bayes_eye_panel := $BayesEyePanel
@onready var bayes_rock_bar := $BayesEyePanel/Rows/RockRow/Bar
@onready var bayes_rock_pct := $BayesEyePanel/Rows/RockRow/Pct
@onready var bayes_scissors_bar := $BayesEyePanel/Rows/ScissorsRow/Bar
@onready var bayes_scissors_pct := $BayesEyePanel/Rows/ScissorsRow/Pct
@onready var bayes_paper_bar := $BayesEyePanel/Rows/PaperRow/Bar
@onready var bayes_paper_pct := $BayesEyePanel/Rows/PaperRow/Pct
@onready var speech_bubble := $SpeechBubble
@onready var bubble_label := $SpeechBubble/BubbleLabel
@onready var janken_overlay := $JankenOverlay
@onready var overlay_player_card := $JankenOverlay/PlayerCard
@onready var overlay_opponent_card := $JankenOverlay/OpponentCard
@onready var overlay_result_image := $JankenOverlay/ResultImage

# --- State ---
var _chapter: BattleChapterBase = null
var _card_paths: Dictionary = {}
var _card_back_tex: Texture2D = null
var _card_textures: Dictionary = {}
var _opponent_outfit: int = 0
var _player_outfit: int = 0
var _player_deck_size: int = 9

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

# アイテム使用状態（ラウンドごとにリセット）
var _round_item_effect: String = ""  # "protect_card", "protect_hp", "intimidate", ""

# 結果強制モード（イベントバトル編集用）
var force_result_mode := false
var _forced_result: String = ""  # "win", "lose", "draw"

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
	auto_button.pressed.connect(_on_auto_pressed)
	confirm_button.visible = false
	auto_button.visible = false
	action_prompt.visible = false
	janken_overlay.visible = false
	speech_bubble.visible = false
	_setup_bubble_style()

func setup(cast: Dictionary, bg_texture: Texture2D = null, inventory: Array = []):
	_cast = cast
	_initial_bg_texture = bg_texture
	_player_inventory = inventory.duplicate(true)

var _is_tutorial := false

func start_battle(chapter: BattleChapterBase, is_tutorial := false):
	_chapter = chapter
	_is_tutorial = is_tutorial
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

	# Parse opponent deck (built from hand randomly)
	_opponent_deck.clear()
	for card in chapter.get_opponent_deck():
		_opponent_deck.append({
			"hand": HAND_FROM_KEY.get(card.hand, Hand.ROCK),
			"grade": int(card.grade),
			"used": false,
		})
	# Load opponent tendency
	_opponent_tendency = chapter.get_opponent_tendency()
	_player_deck_size = chapter.get_player_deck_size()

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
		# デバッグ: setup_scene 後のキャラ位置
		if _story_scene:
			for rect in [_story_scene.center_char, _story_scene.left_char, _story_scene.right_char]:
				if rect and rect.visible:
					print("[SETUP_AFTER] pos=%s scale=%s size=%s" % [str(rect.position), str(rect.scale), str(rect.size)])

	if _is_tutorial:
		# Tutorial mode: show hand panel, let tutorial function control the flow
		hand_panel.visible = true
		_refresh_inventory_display()
		_update_score()
		_run_battle()
	else:
		# Normal mode: deck building then battle
		await _deck_building_phase()
		_build_deck_buttons()
		_update_score()
		# デッキ構築後にキャラ画像の位置を再配置（デッキ構築中のずれを修正）
		if _story_scene and _chapter.has_method("setup_scene"):
			_chapter.call("setup_scene", self)
			await _flush_pending()
		_run_battle()

# ============================================================
# Deck Building Phase
# ============================================================

func _deck_building_phase():
	_deck_building = true
	_deck_ready = false
	_player_deck.clear()

	# Show hand cards panel for deck building
	hand_panel.visible = true
	_refresh_inventory_display()

	# Show instruction
	action_prompt.visible = true
	card_label.text = "デッキに%d枚セットしてください" % _player_deck_size
	confirm_button.text = "準備完了"
	confirm_button.visible = false
	auto_button.visible = true

	# Wait for player to fill deck
	while not _deck_ready:
		await get_tree().process_frame

	confirm_button.visible = false
	auto_button.visible = false
	action_prompt.visible = false
	confirm_button.text = "勝負！"
	_deck_building = false

	# Hide hand panel after deck building
	hand_panel.visible = false
	_clear_hand_display()

func _refresh_inventory_display():
	_clear_hand_display()

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

	# Create buttons for each card type in hand panel
	var keys = counts.keys()
	keys.sort()
	for key in keys:
		var info = counts[key]
		var available: int = info.total - info.in_deck
		var hand_enum: Hand = HAND_FROM_KEY.get(info.hand, Hand.ROCK)
		var grade: int = info.grade

		var slot := HBoxContainer.new()
		slot.name = "HandSlot_" + key
		slot.add_theme_constant_override("separation", 6)

		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(42, 60)
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
		label.text = "%s%s x%d" % [HAND_NAMES[hand_enum], grade_short, available]
		var ls := LabelSettings.new()
		ls.font_size = 22
		ls.font_color = Color(0.95, 0.9, 0.8)
		ls.outline_color = Color(0.1, 0.08, 0.05, 0.8)
		ls.outline_size = 3
		label.label_settings = ls
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot.add_child(label)

		hand_slots.add_child(slot)

func _on_inventory_card_pressed(hand: Hand, grade: int):
	if not _deck_building:
		return
	if _player_deck.size() >= _player_deck_size:
		return

	# Check availability
	@warning_ignore("unused_variable")
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

	if _player_deck.size() >= _player_deck_size:
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

func _clear_hand_display():
	for child in hand_slots.get_children():
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
		_pending_commands.append({"_battle_bubble": true, "text": command.text, "append": command.append})
		return
	_pending_commands.append(command)

# --- Card & Item selection ---

func force_select_hand(hand: Hand) -> Dictionary:
	# ピー助がカードを強制選択する演出
	await _flush_pending()
	_set_cards_enabled(false)
	action_prompt.visible = true
	card_label.text = "カードを選択してください"
	var _has_bayes: bool = _chapter and _chapter.has_method("has_bayes_eye") and _chapter.has_bayes_eye()
	if _has_bayes:
		_show_bayes_eye_immediate()

	await get_tree().create_timer(0.5).timeout

	# 指定されたカードを自動選択
	for entry in _deck_buttons:
		if entry.hand == hand and not entry.used:
			_selected_hand = hand
			_selected_grade = entry.grade
			_selected_button = entry.button
			_hand_selected = true
			var check: Label = entry.container.get_node_or_null("CheckMark")
			if check:
				check.visible = true
			_update_bayes_display()
			break

	await get_tree().create_timer(0.8).timeout

	# 勝負ボタンを自動クリック
	confirm_button.visible = true
	await get_tree().create_timer(0.5).timeout

	# 確定処理
	_set_cards_enabled(false)
	confirm_button.visible = false
	action_prompt.visible = false
	if _has_bayes:
		_hide_bayes_eye_immediate()
	_consume_selected_card()
	_update_score()
	return {"hand": _selected_hand, "grade": _selected_grade, "item": null}

func select_hand() -> Dictionary:
	await _flush_pending()
	_round_item_effect = ""
	_set_cards_enabled(true)
	_hand_selected = false
	_hand_confirmed = false
	_selected_button = null
	_deselect_all_cards()
	action_prompt.visible = true
	card_label.text = "カードを選択してください"
	confirm_button.visible = false
	_show_item_buttons()
	if force_result_mode:
		_show_force_result_buttons()
	# Show Bayes Eye during card selection (if chapter supports it)
	var _has_bayes: bool = _chapter and _chapter.has_method("has_bayes_eye") and _chapter.has_bayes_eye()
	if _has_bayes:
		_show_bayes_eye_immediate()
	while not _hand_confirmed:
		await get_tree().process_frame
	_set_cards_enabled(false)
	confirm_button.visible = false
	action_prompt.visible = false
	_clear_item_buttons()
	_clear_force_result_buttons()
	if _has_bayes:
		_hide_bayes_eye_immediate()
	_consume_selected_card()
	_update_score()
	return {"hand": _selected_hand, "grade": _selected_grade, "item": _round_item_effect}

# --- Janken overlay ---

func janken(selection: Dictionary, ai_opts: Dictionary = {}) -> String:
	await _flush_pending()
	var player_hand: Hand = selection.get("hand", Hand.ROCK)
	var player_grade: int = selection.get("grade", Grade.NORMAL)
	var opp_pick := _pick_opponent_card(player_hand, ai_opts)
	var opponent_hand: Hand = opp_pick.hand
	var opponent_grade: int = opp_pick.grade
	var result := _judge_with_grade(player_hand, player_grade, opponent_hand, opponent_grade)
	# 結果強制モード: 結果に合わせて相手の手も変更
	if force_result_mode and not _forced_result.is_empty():
		print("[FORCE] original=%s forced=%s" % [result, _forced_result])
		result = _forced_result
		_forced_result = ""
		match result:
			"win":
				# プレイヤーが勝つ手を相手に出させる
				match player_hand:
					Hand.ROCK: opponent_hand = Hand.SCISSORS
					Hand.SCISSORS: opponent_hand = Hand.PAPER
					Hand.PAPER: opponent_hand = Hand.ROCK
			"lose":
				# プレイヤーが負ける手を相手に出させる
				match player_hand:
					Hand.ROCK: opponent_hand = Hand.PAPER
					Hand.SCISSORS: opponent_hand = Hand.ROCK
					Hand.PAPER: opponent_hand = Hand.SCISSORS
			"draw":
				opponent_hand = player_hand

	await _play_janken_overlay(player_hand, opponent_hand, result)

	if result == "win":
		_opponent_outfit -= 1
		_captured_by_player.append({"hand": HAND_KEYS[opponent_hand], "grade": opponent_grade})
	elif result == "lose":
		# 鉄の盾: HPが減らない
		if _round_item_effect != "protect_hp":
			_player_outfit -= 1
		# 身代わりカード: カードを取られない
		if _round_item_effect != "protect_card":
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
	# Tutorial mode: single function, no outfit loop
	if _is_tutorial and _chapter.has_method("tutorial"):
		await _chapter.call("tutorial", self)
		await _flush_pending()
		# 報酬メッセージ
		await _show_reward_message()
		_cleanup()
		battle_finished.emit("win")
		return

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
		final_result = "draw"
	elif _count_remaining_deck() <= 0:
		final_result = "lose"
	elif _count_remaining_opponent_deck() <= 0:
		final_result = "win"
	else:
		final_result = "draw"

	# 報酬/損失メッセージ
	if final_result == "win":
		await _show_reward_message()
	elif final_result == "lose":
		await _show_loss_message()

	_cleanup()
	battle_finished.emit(final_result)

# --- アイテム使用UI ---

func _show_item_buttons():
	_clear_item_buttons()
	for item in GameState.items:
		var item_info: Dictionary = ItemDatabase.get_item(item.id)
		if item_info.is_empty() or item_info.type != ItemDatabase.ItemType.CONSUMABLE:
			continue
		var btn := Button.new()
		btn.text = "%s ×%d" % [item.get("name", item.id), item.get("count", 1)]
		btn.add_theme_font_size_override("font_size", 14)
		btn.tooltip_text = item_info.get("description", "")
		var icon_tex = load(GameState.DEFAULT_ITEM_ICON_PATH)
		if icon_tex:
			btn.icon = icon_tex
			btn.expand_icon = true
		var item_id: String = item.id
		btn.pressed.connect(_on_item_used.bind(item_id, btn))
		item_slots.add_child(btn)

func _clear_item_buttons():
	for child in item_slots.get_children():
		child.queue_free()

func _on_item_used(item_id: String, btn: Button):
	if not _round_item_effect.is_empty():
		return  # 1ラウンド1個まで
	var item_info: Dictionary = ItemDatabase.get_item(item_id)
	if item_info.is_empty():
		return
	_round_item_effect = item_info.get("effect", "")
	GameState.remove_item(item_id, 1)
	btn.disabled = true
	btn.text = "使用済み"
	# 威圧の札: ベイズアイを更新
	if _round_item_effect == "intimidate":
		_update_bayes_display()
	# アイテムパネルを更新
	_show_item_buttons()

# --- 結果強制ボタン（イベントバトル編集用） ---

var _force_result_container: PanelContainer = null

func _show_force_result_buttons():
	_clear_force_result_buttons()
	# アイテムパネルの右側に配置
	_force_result_container = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	_force_result_container.add_theme_stylebox_override("panel", style)
	_force_result_container.layout_mode = 1
	_force_result_container.anchor_left = 0.17
	_force_result_container.anchor_top = 0.35
	_force_result_container.anchor_right = 0.30
	_force_result_container.anchor_bottom = 0.70
	_force_result_container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_force_result_container)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_force_result_container.add_child(vbox)

	var title := Label.new()
	title.text = "── 結果強制 ──"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for entry in [["勝ち", "win", Color(0.3, 0.8, 0.3)], ["負け", "lose", Color(0.8, 0.3, 0.3)], ["引き分け", "draw", Color(0.6, 0.6, 0.6)]]:
		var btn := Button.new()
		btn.text = entry[0]
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", entry[2])
		var res: String = entry[1]
		var container_ref := vbox
		btn.pressed.connect(func():
			_forced_result = res
			for child in container_ref.get_children():
				if child is Button:
					child.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0)))
		vbox.add_child(btn)

func _clear_force_result_buttons():
	if _force_result_container and is_instance_valid(_force_result_container):
		_force_result_container.queue_free()
		_force_result_container = null
	# _forced_result はリセットしない（janken で使用される）

var _rolled_gold: int = 0
var _lost_gold: int = 0

signal _result_panel_closed

func _show_reward_message():
	_rolled_gold = _chapter.roll_gold() if _chapter else 0
	var has_cards: bool = _chapter.can_gain_cards() and not _captured_by_player.is_empty()
	if not has_cards and _rolled_gold <= 0:
		return
	var panel := _create_result_panel("報酬を獲得しました！", Color(0.2, 0.8, 0.3))
	var vbox: VBoxContainer = panel.get_child(0)
	if has_cards:
		for card in _captured_by_player:
			vbox.add_child(GameState.create_card_label(card.hand, int(card.grade), 1, 20, 28))
	if _rolled_gold > 0:
		vbox.add_child(GameState.create_gold_label(_rolled_gold, 20, 28))
	_add_result_close_button(vbox)
	await _result_panel_closed
	panel.queue_free()

func _show_loss_message():
	var has_cards: bool = _chapter.can_lose_cards() and not _captured_by_opponent.is_empty()
	var reward := _chapter.get_gold_reward()
	if not reward.is_empty():
		var max_gold: int = reward.get("max", 0)
		var min_gold: int = reward.get("min", 0)
		_lost_gold = (min_gold + max_gold) / 2 / 2
	else:
		_lost_gold = 0
	if not has_cards and _lost_gold <= 0:
		return
	var panel := _create_result_panel("奪われました……", Color(0.9, 0.3, 0.3))
	var vbox: VBoxContainer = panel.get_child(0)
	if has_cards:
		for card in _captured_by_opponent:
			vbox.add_child(GameState.create_card_label(card.hand, int(card.grade), 1, 20, 28))
	if _lost_gold > 0:
		vbox.add_child(GameState.create_gold_label(_lost_gold, 20, 28, "-"))
	_add_result_close_button(vbox)
	await _result_panel_closed
	panel.queue_free()

func _create_result_panel(title_text: String, title_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 24
	style.content_margin_top = 16
	style.content_margin_right = 24
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(400, 200)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", title_color)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	return panel

func _add_result_close_button(vbox: VBoxContainer):
	var btn := Button.new()
	btn.text = "OK"
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(func(): _result_panel_closed.emit())
	vbox.add_child(btn)

func get_rolled_gold() -> int:
	return _rolled_gold

func get_lost_gold() -> int:
	return _lost_gold

# Returns battle results for Main.gd to process inventory changes
# --- 動画再生 ---

signal _video_finished

func play_video(path: String):
	var stream = load(path)
	if not stream:
		push_warning("Video not found: %s" % path)
		return

	# セリフ表示を完了させてから動画再生
	await _flush_pending()

	# 全UIを隠す
	var hidden_nodes: Array = []
	for child in get_children():
		if child is CanvasItem and child.visible:
			child.visible = false
			hidden_nodes.append(child)

	# 黒背景
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 動画プレイヤー（縦横比維持、中央配置）
	var player := VideoStreamPlayer.new()
	player.stream = stream
	player.expand = true
	player.bus = &"Master"
	add_child(player)

	# 動画開始して、サイズ取得後にリサイズ
	player.play()
	await get_tree().process_frame
	var video_size := player.get_video_texture().get_size() if player.get_video_texture() else Vector2(832, 1104)
	var vp_size := get_viewport_rect().size
	var scale_ratio: float = minf(vp_size.x / video_size.x, vp_size.y / video_size.y)
	var display_w: float = video_size.x * scale_ratio
	var display_h: float = video_size.y * scale_ratio
	player.position = Vector2((vp_size.x - display_w) / 2.0, (vp_size.y - display_h) / 2.0)
	player.size = Vector2(display_w, display_h)

	# 動画終了またはクリック/エンターで停止
	var finished := false
	player.finished.connect(func(): finished = true)
	while not finished:
		if Input.is_action_just_pressed("ui_accept"):
			break
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var hovered = get_viewport().gui_get_hovered_control()
			if not (hovered is Slider or hovered is SpinBox or _is_in_panel(hovered)):
				break
		await get_tree().process_frame

	player.stop()
	player.queue_free()
	bg.queue_free()

	# UIを元に戻す
	for node in hidden_nodes:
		if is_instance_valid(node):
			node.visible = true

func get_battle_rewards() -> Dictionary:
	return {
		"captured_by_player": _captured_by_player.duplicate(true),
		"captured_by_opponent": _captured_by_opponent.duplicate(true),
	}

# --- Janken overlay animation ---

func _play_janken_overlay(player_hand: Hand, opponent_hand: Hand, result: String):
	janken_overlay.visible = true
	overlay_result_image.visible = false

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

	# 3. Player card flips first
	var plr_tex_path: String = _card_paths.get(HAND_KEYS[player_hand], "")
	var flip_plr_hide := create_tween()
	flip_plr_hide.tween_property(overlay_player_card, "scale:x", 0.0, 0.3)
	await flip_plr_hide.finished
	if not plr_tex_path.is_empty():
		overlay_player_card.texture = load(plr_tex_path)
	var flip_plr_show := create_tween()
	flip_plr_show.tween_property(overlay_player_card, "scale:x", 1.0, 0.3)
	await flip_plr_show.finished

	await get_tree().create_timer(0.4).timeout

	# 4. Opponent card flips last
	var opp_tex_path: String = _card_paths.get(HAND_KEYS[opponent_hand], "")
	var flip_opp_hide := create_tween()
	flip_opp_hide.tween_property(overlay_opponent_card, "scale:x", 0.0, 0.3)
	await flip_opp_hide.finished
	if not opp_tex_path.is_empty():
		overlay_opponent_card.texture = load(opp_tex_path)
	var flip_opp_show := create_tween()
	flip_opp_show.tween_property(overlay_opponent_card, "scale:x", 1.0, 0.3)
	await flip_opp_show.finished

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
	overlay_result_image.texture = _result_textures.get(outcome)
	overlay_result_image.pivot_offset = overlay_result_image.size / 2.0
	overlay_result_image.scale = Vector2(0.3, 0.3)
	overlay_result_image.modulate = Color(1, 1, 1, 0)
	overlay_result_image.visible = true
	var pop := create_tween()
	pop.set_parallel(true)
	pop.tween_property(overlay_result_image, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(overlay_result_image, "modulate:a", 1.0, 0.3)
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
	# Update Bayes Eye when card is selected
	if bayes_eye_panel.visible:
		_update_bayes_display()

func _on_confirm_pressed():
	if _deck_building:
		if _player_deck.size() >= _player_deck_size:
			_deck_ready = true
	elif _hand_selected:
		_hand_confirmed = true

func _on_auto_pressed():
	if not _deck_building:
		return
	# Clear current deck
	_player_deck.clear()
	# Build deck: distribute cards evenly across types, prefer higher grades
	var available: Array = _player_inventory.duplicate(true)
	# Sort by grade descending so higher grades are picked first
	available.sort_custom(func(a, b): return int(a.grade) > int(b.grade))
	# Round-robin across hand types for balance
	var by_type: Dictionary = {"rock": [], "scissors": [], "paper": []}
	for card in available:
		by_type[card.hand].append(card)
	var added := 0
	var round_idx := 0
	while added < _player_deck_size:
		var picked_any := false
		for hand_key in ["rock", "scissors", "paper"]:
			if added >= _player_deck_size:
				break
			if round_idx < by_type[hand_key].size():
				var card = by_type[hand_key][round_idx]
				_player_deck.append({"hand": HAND_FROM_KEY[card.hand], "grade": int(card.grade)})
				added += 1
				picked_any = true
		round_idx += 1
		if not picked_any:
			break
	_refresh_inventory_display()
	_refresh_deck_preview()
	if _player_deck.size() >= _player_deck_size:
		confirm_button.visible = true

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

	# Split into story commands, bubble commands, and highlight commands
	var story_batch: Array = []
	for cmd in cmds:
		if cmd is Dictionary and cmd.has("_battle_bubble"):
			# Flush any accumulated story commands first
			if not story_batch.is_empty():
				var seq := Cmd.Sequence.new()
				seq.entries = story_batch.duplicate()
				story_batch.clear()
				await _story_scene.play_sequence(seq)
			var is_append: bool = cmd.get("append", false)
			# Close previous bubble if starting a new one (not append)
			if not is_append and speech_bubble.visible:
				await _hide_bubble()
			await _show_bubble(cmd.text, is_append)
		elif cmd is Dictionary and cmd.has("_highlight"):
			_highlight_target(cmd.target, cmd.get("options", {}))
		elif cmd is Dictionary and cmd.has("_unhighlight"):
			_unhighlight()
		elif cmd is Dictionary and cmd.has("_bubble_side"):
			_apply_bubble_side(cmd.side)
		elif cmd is Dictionary and cmd.has("_show_bayes"):
			_show_bayes_eye_immediate()
		elif cmd is Dictionary and cmd.has("_hide_bayes"):
			_hide_bayes_eye_immediate()
		else:
			story_batch.append(cmd)

	# Flush remaining story commands
	if not story_batch.is_empty():
		var seq := Cmd.Sequence.new()
		seq.entries = story_batch
		await _story_scene.play_sequence(seq)

	# Close bubble after all commands
	if speech_bubble.visible:
		await _hide_bubble()

# --- Bayes Eye: probability calculation ---

var _opponent_tendency: Dictionary = {}

func get_bayes_probability(with_grade_effect: bool = false) -> Dictionary:
	# デッキの残りカードから基本確率を計算
	var counts := {Hand.ROCK: 0, Hand.SCISSORS: 0, Hand.PAPER: 0}
	var total := 0
	for entry in _opponent_deck:
		if not entry.used:
			counts[entry.hand] += 1
			total += 1
	if total == 0:
		return {Hand.ROCK: 0.33, Hand.SCISSORS: 0.33, Hand.PAPER: 0.34}

	var prob := {}
	for hand in counts:
		prob[hand] = float(counts[hand]) / float(total)

	# 癖補正を適用
	if not _opponent_tendency.is_empty():
		for key in _opponent_tendency:
			var hand_enum: Hand = HAND_FROM_KEY.get(key, -1)
			if hand_enum >= 0 and prob.has(hand_enum):
				prob[hand_enum] += _opponent_tendency[key]
		# 正規化（合計を1.0にする、負の値は0にクランプ）
		var sum := 0.0
		for hand in prob:
			prob[hand] = max(prob[hand], 0.0)
			sum += prob[hand]
		if sum > 0:
			for hand in prob:
				prob[hand] /= sum

	# 威圧の札: 相手が負ける手+20%（比率維持方式）
	if with_grade_effect and _round_item_effect == "intimidate" and _hand_selected:
		var player_hand_key: String = HAND_KEYS.get(_selected_hand, "rock")
		var lose_hand_key: String = Card.LOSES_TO[player_hand_key]
		var lose_hand_enum: Hand = HAND_FROM_KEY.get(lose_hand_key, Hand.ROCK)
		var old_lose: float = prob.get(lose_hand_enum, 0.0)
		var new_lose: float = old_lose + 0.20
		prob[lose_hand_enum] = new_lose
		var remaining_old: float = 0.0
		for h in prob:
			if h != lose_hand_enum:
				remaining_old += prob[h]
		if remaining_old > 0.0:
			var remaining_new: float = 1.0 - new_lose
			var ratio: float = remaining_new / remaining_old
			for h in prob:
				if h != lose_hand_enum:
					prob[h] *= ratio

	# グレード補正（カード選択後のみ）
	if with_grade_effect and _selected_grade > 1 and _hand_selected:
		var player_hand_key: String = HAND_KEYS.get(_selected_hand, "rock")
		var str_probs := {}
		for hand_enum in prob:
			str_probs[HAND_KEYS.get(hand_enum, "rock")] = prob[hand_enum]
		var adjusted := Card.apply_grade_effect(player_hand_key, _selected_grade, str_probs)
		prob = {}
		for key in adjusted:
			prob[HAND_FROM_KEY.get(key, Hand.ROCK)] = adjusted[key]

	return prob

func show_bayes_eye():
	_pending_commands.append({"_show_bayes": true})

func hide_bayes_eye():
	_pending_commands.append({"_hide_bayes": true})

func _show_bayes_eye_immediate():
	_update_bayes_display()
	bayes_eye_panel.visible = true

func _hide_bayes_eye_immediate():
	bayes_eye_panel.visible = false

func _update_bayes_display():
	var with_grade: bool = _hand_selected and _selected_grade > 1
	var prob := get_bayes_probability(with_grade)
	var rock_pct: int = int(prob.get(Hand.ROCK, 0.0) * 100)
	var scissors_pct: int = int(prob.get(Hand.SCISSORS, 0.0) * 100)
	var paper_pct: int = int(prob.get(Hand.PAPER, 0.0) * 100)
	# 合計100%に調整
	var diff: int = 100 - rock_pct - scissors_pct - paper_pct
	if diff != 0:
		# 最大のものに差分を加算
		if rock_pct >= scissors_pct and rock_pct >= paper_pct:
			rock_pct += diff
		elif scissors_pct >= paper_pct:
			scissors_pct += diff
		else:
			paper_pct += diff

	bayes_rock_bar.value = rock_pct
	bayes_rock_pct.text = "%d%%" % rock_pct
	bayes_scissors_bar.value = scissors_pct
	bayes_scissors_pct.text = "%d%%" % scissors_pct
	bayes_paper_bar.value = paper_pct
	bayes_paper_pct.text = "%d%%" % paper_pct

	# バーの色（確率が高いほど赤く）
	_style_bayes_bar(bayes_rock_bar, rock_pct)
	_style_bayes_bar(bayes_scissors_bar, scissors_pct)
	_style_bayes_bar(bayes_paper_bar, paper_pct)

var _silver_tex: ImageTexture = null
var _dark_metal_tex: ImageTexture = null
var _gold_border_tex: ImageTexture = null

func _get_silver_texture() -> ImageTexture:
	if _silver_tex:
		return _silver_tex
	# Generate metallic silver gradient (1px wide, 32px tall)
	var img := Image.create(1, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		var t: float = float(y) / 31.0
		# Metal gradient: dark → bright highlight → medium → dark
		var v: float
		if t < 0.15:
			v = lerp(0.4, 0.6, t / 0.15)
		elif t < 0.25:
			v = lerp(0.6, 0.95, (t - 0.15) / 0.1)  # Bright specular
		elif t < 0.4:
			v = lerp(0.95, 0.7, (t - 0.25) / 0.15)  # Fade from highlight
		elif t < 0.7:
			v = lerp(0.7, 0.6, (t - 0.4) / 0.3)
		else:
			v = lerp(0.6, 0.35, (t - 0.7) / 0.3)
		# Gold metallic tint
		img.set_pixel(0, y, Color(v, v * 0.8, v * 0.3, 1.0))
	_silver_tex = ImageTexture.create_from_image(img)
	return _silver_tex

func _get_dark_metal_texture() -> ImageTexture:
	if _dark_metal_tex:
		return _dark_metal_tex
	# Generate dark metallic gradient (1px wide, 32px tall)
	var img := Image.create(1, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		var t: float = float(y) / 31.0
		var v: float
		if t < 0.15:
			v = lerp(0.25, 0.35, t / 0.15)
		elif t < 0.25:
			v = lerp(0.35, 0.48, (t - 0.15) / 0.1)
		elif t < 0.4:
			v = lerp(0.48, 0.35, (t - 0.25) / 0.15)
		elif t < 0.7:
			v = lerp(0.35, 0.3, (t - 0.4) / 0.3)
		else:
			v = lerp(0.3, 0.22, (t - 0.7) / 0.3)
		img.set_pixel(0, y, Color(v * 0.9, v * 0.92, v, 1.0))
	_dark_metal_tex = ImageTexture.create_from_image(img)
	return _dark_metal_tex

func _get_gold_border_texture() -> ImageTexture:
	if _gold_border_tex:
		return _gold_border_tex
	# Generate gold metallic gradient (1px wide, 16px tall)
	var img := Image.create(1, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		var t: float = float(y) / 15.0
		var v: float
		if t < 0.2:
			v = lerp(0.5, 0.9, t / 0.2)
		elif t < 0.35:
			v = lerp(0.9, 1.0, (t - 0.2) / 0.15)
		elif t < 0.6:
			v = lerp(1.0, 0.7, (t - 0.35) / 0.25)
		else:
			v = lerp(0.7, 0.4, (t - 0.6) / 0.4)
		img.set_pixel(0, y, Color(v, v * 0.8, v * 0.3, 1.0))
	_gold_border_tex = ImageTexture.create_from_image(img)
	return _gold_border_tex

func _style_bayes_bar(bar: ProgressBar, _pct: int):
	bar.material = null
	# Silver metallic fill using texture
	var fill := StyleBoxTexture.new()
	fill.texture = _get_silver_texture()
	fill.content_margin_left = 8
	fill.content_margin_right = 8 if _pct >= 100 else 0
	bar.add_theme_stylebox_override("fill", fill)
	# Dark metallic background (same gradient style but darker)
	var bg := StyleBoxTexture.new()
	bg.texture = _get_dark_metal_texture()
	bg.content_margin_left = 2
	bg.content_margin_top = 2
	bg.content_margin_right = 2
	bg.content_margin_bottom = 2
	bar.add_theme_stylebox_override("background", bg)

# --- AI / Opponent card pick ---

func _pick_opponent_card(player_hand: Hand, ai_opts: Dictionary = {}) -> Dictionary:
	var target_hand: Hand

	if ai_opts.has("fixed"):
		target_hand = HAND_FROM_KEY.get(ai_opts["fixed"], Hand.ROCK)
	else:
		# プレイヤーのカードグレードを取得
		var player_grade: int = _selected_grade if _selected_grade > 0 else 1
		var player_hand_key: String = HAND_KEYS.get(player_hand, "rock")
		target_hand = _pick_by_probability(player_hand_key, player_grade)

	return _consume_opponent_card(target_hand)

func _pick_by_probability(player_hand_key: String = "", player_grade: int = 1) -> Hand:
	var prob := get_bayes_probability(true)
	# グレード補正を適用
	if player_grade > 1 and not player_hand_key.is_empty():
		var str_probs := {}
		for hand_enum in prob:
			str_probs[HAND_KEYS.get(hand_enum, "rock")] = prob[hand_enum]
		var adjusted := Card.apply_grade_effect(player_hand_key, player_grade, str_probs)
		prob = {}
		for key in adjusted:
			prob[HAND_FROM_KEY.get(key, Hand.ROCK)] = adjusted[key]
	var roll: float = randf()
	var cumulative := 0.0
	for hand in [Hand.ROCK, Hand.SCISSORS, Hand.PAPER]:
		cumulative += prob.get(hand, 0.0)
		if roll <= cumulative:
			return hand
	return Hand.ROCK


func _consume_opponent_card(target_hand: Hand) -> Dictionary:
	# Try to find a matching card in opponent deck
	for i in range(_opponent_deck.size()):
		if not _opponent_deck[i].used and _opponent_deck[i].hand == target_hand:
			_opponent_deck[i].used = true
			return {"hand": _opponent_deck[i].hand, "grade": _opponent_deck[i].grade}
	# Fallback: pick any available card
	for i in range(_opponent_deck.size()):
		if not _opponent_deck[i].used:
			_opponent_deck[i].used = true
			return {"hand": _opponent_deck[i].hand, "grade": _opponent_deck[i].grade}
	return {"hand": Hand.ROCK, "grade": Grade.NORMAL}

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
	@warning_ignore("unused_variable")
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
	player_hp_bar.add_theme_stylebox_override("background", bg_style)
	opponent_hp_bar.add_theme_stylebox_override("background", bg_style.duplicate())

	# Border on the bar frame
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = Color(0.6, 0.5, 0.3, 0.9)
	frame_style.corner_radius_top_left = 3
	frame_style.corner_radius_top_right = 3
	frame_style.corner_radius_bottom_right = 3
	frame_style.corner_radius_bottom_left = 3
	player_hp_bar_frame.add_theme_stylebox_override("panel", frame_style)
	opponent_hp_bar_frame.add_theme_stylebox_override("panel", frame_style.duplicate())

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

# --- Tutorial ---

var _highlight_tween: Tween = null
var _highlight_cursor: TextureRect = null
var _arrow_tex: Texture2D = preload("res://assets/ui/arrow2.png")
var _result_textures: Dictionary = {
	"win": preload("res://assets/ui/result_win.png"),
	"lose": preload("res://assets/ui/result_lose.png"),
	"draw": preload("res://assets/ui/result_draw.png"),
}

func build_deck():
	await _flush_pending()
	await _deck_building_phase()
	_build_deck_buttons()
	_update_score()

func force_build_deck(cards: Array):
	# 指定されたカードで強制的にデッキを構築（チュートリアル用）
	await _flush_pending()
	_player_deck.clear()
	for card in cards:
		var hand_enum: Hand = HAND_FROM_KEY.get(card.get("hand", "rock"), Hand.ROCK)
		var grade: int = int(card.get("grade", 1))
		_player_deck.append({"hand": hand_enum, "grade": grade})
	_build_deck_buttons()
	_update_score()

func highlight(target: String, options: Dictionary = {}):
	_pending_commands.append({"_highlight": true, "target": target, "options": options})

func unhighlight():
	_pending_commands.append({"_unhighlight": true})

func _highlight_target(target_name: String, options: Dictionary = {}):
	_unhighlight()
	var node: Control = _resolve_target(target_name)
	if node == null:
		return
	# Create finger cursor
	_highlight_cursor = TextureRect.new()
	_highlight_cursor.texture = _arrow_tex
	_highlight_cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_highlight_cursor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_highlight_cursor.custom_minimum_size = Vector2(192, 108)
	_highlight_cursor.size = Vector2(192, 108)
	_highlight_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_highlight_cursor)
	var target_rect: Rect2 = node.get_global_rect()

	# Direction: "left", "right", "top", "bottom" or auto-detect
	var direction: String = options.get("direction", "auto")
	# Offset adjustment
	var offset_x: float = options.get("offset_x", 0.0)
	var offset_y: float = options.get("offset_y", 0.0)

	if direction == "auto":
		# card_bar is full-width at bottom → default to top (pointing down)
		if target_name == "card_bar":
			direction = "top"
		else:
			var vp_center_x: float = get_viewport_rect().size.x / 2.0
			if target_rect.position.x + target_rect.size.x / 2.0 > vp_center_x:
				direction = "left"
			else:
				direction = "right"

	match direction:
		"right":
			# Arrow to the right of target, pointing left
			_highlight_cursor.position = Vector2(
				target_rect.position.x + target_rect.size.x - 44,
				target_rect.position.y + target_rect.size.y / 2.0 - 54
			)
			_highlight_cursor.flip_h = true
			_highlight_cursor.rotation = 0
		"left":
			# Arrow to the left of target, pointing right
			_highlight_cursor.position = Vector2(
				target_rect.position.x - 198,
				target_rect.position.y + target_rect.size.y / 2.0 - 54
			)
			_highlight_cursor.flip_h = false
			_highlight_cursor.rotation = 0
		"top":
			# Arrow above target, pointing down
			_highlight_cursor.position = Vector2(
				target_rect.position.x + target_rect.size.x / 2.0 - 96,
				target_rect.position.y - 114
			)
			_highlight_cursor.flip_h = false
			_highlight_cursor.rotation = deg_to_rad(90)
		"bottom":
			# Arrow below target, pointing up
			_highlight_cursor.position = Vector2(
				target_rect.position.x + target_rect.size.x / 2.0 - 96,
				target_rect.position.y + target_rect.size.y + 6
			)
			_highlight_cursor.flip_h = false
			_highlight_cursor.rotation = deg_to_rad(-90)

	_highlight_cursor.position += Vector2(offset_x, offset_y)
	_highlight_cursor.pivot_offset = Vector2(96, 54)
	# Pulse animation
	_highlight_tween = create_tween()
	_highlight_tween.set_loops()
	_highlight_tween.tween_property(_highlight_cursor, "scale", Vector2(1.3, 1.3), 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_highlight_tween.tween_property(_highlight_cursor, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _unhighlight():
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()
		_highlight_tween = null
	if _highlight_cursor and is_instance_valid(_highlight_cursor):
		_highlight_cursor.queue_free()
		_highlight_cursor = null

func _resolve_target(target_name: String) -> Control:
	match target_name:
		"item_panel": return item_panel
		"hand_panel": return hand_panel
		"card_bar": return card_bar
		"action_prompt": return action_prompt
		"speech_bubble": return speech_bubble
		"opponent_hp": return $OpponentHPPanel
		"player_hp": return $PlayerHPPanel
	return null

func set_bubble_side(side: String):
	_pending_commands.append({"_bubble_side": true, "side": side})

func _apply_bubble_side(side: String):
	# Hide bubble instantly before repositioning to prevent flash
	if speech_bubble.visible:
		speech_bubble.visible = false
		speech_bubble.modulate = Color.WHITE
	match side:
		"left":
			speech_bubble.anchor_left = 0.04
			speech_bubble.anchor_right = 0.32
			speech_bubble.anchor_top = 0.05
			speech_bubble.anchor_bottom = 0.32
		"right":
			speech_bubble.anchor_left = 0.68
			speech_bubble.anchor_right = 0.96
			speech_bubble.anchor_top = 0.05
			speech_bubble.anchor_bottom = 0.32
		"center":
			speech_bubble.anchor_left = 0.25
			speech_bubble.anchor_right = 0.75
			speech_bubble.anchor_top = 0.05
			speech_bubble.anchor_bottom = 0.32
		"bottom-left":
			speech_bubble.anchor_left = 0.02
			speech_bubble.anchor_right = 0.35
			speech_bubble.anchor_top = 0.55
			speech_bubble.anchor_bottom = 0.82
		"bottom-right":
			speech_bubble.anchor_left = 0.65
			speech_bubble.anchor_right = 0.98
			speech_bubble.anchor_top = 0.55
			speech_bubble.anchor_bottom = 0.82

func _setup_bubble_style():
	bubble_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))

var _bubble_indicator: Label = null
var _indicator_tween: Tween = null

func _show_bubble(text: String, append: bool = false):
	if append and speech_bubble.visible:
		# Append to existing text
		bubble_label.text += "\n" + text
	else:
		# New bubble
		bubble_label.text = text
		speech_bubble.visible = true
		speech_bubble.modulate = Color(1, 1, 1, 0)
		var fade_in := create_tween()
		fade_in.tween_property(speech_bubble, "modulate:a", 1.0, 0.2)
		await fade_in.finished

	# Show ▼ indicator
	_show_indicator()

	# Wait for click/input
	await _wait_for_input()

	# Hide indicator
	_hide_indicator()

func _hide_bubble():
	var fade_out := create_tween()
	fade_out.tween_property(speech_bubble, "modulate:a", 0.0, 0.15)
	await fade_out.finished
	speech_bubble.visible = false

func _show_indicator():
	if _bubble_indicator and is_instance_valid(_bubble_indicator):
		return
	_bubble_indicator = Label.new()
	_bubble_indicator.text = "▼"
	var ls := LabelSettings.new()
	ls.font_size = 16
	ls.font_color = Color(0.4, 0.35, 0.25, 0.8)
	_bubble_indicator.label_settings = ls
	_bubble_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bubble_indicator.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_bubble_indicator.offset_left = -30
	_bubble_indicator.offset_top = -24
	_bubble_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech_bubble.add_child(_bubble_indicator)
	# Pulse
	_indicator_tween = create_tween()
	_indicator_tween.set_loops()
	_indicator_tween.tween_property(_bubble_indicator, "modulate:a", 0.3, 0.5)
	_indicator_tween.tween_property(_bubble_indicator, "modulate:a", 1.0, 0.5)

func _hide_indicator():
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()
		_indicator_tween = null
	if _bubble_indicator and is_instance_valid(_bubble_indicator):
		_bubble_indicator.queue_free()
		_bubble_indicator = null

func _wait_for_input():
	# Wait for any current press to be released first
	while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_accept"):
		await get_tree().process_frame
	# Wait one extra frame to prevent double-trigger
	await get_tree().process_frame
	# Then wait for a new press
	while true:
		if Input.is_action_just_pressed("ui_accept"):
			await get_tree().process_frame
			return
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# スライダーやボタン上のクリックは無視
			var hovered = get_viewport().gui_get_hovered_control()
			if not (hovered is Slider or hovered is SpinBox or hovered is LineEdit or _is_in_panel(hovered)):
				await get_tree().process_frame
				return
		await get_tree().process_frame

func _is_in_panel(control) -> bool:
	if control == null:
		return false
	var node = control
	while node:
		if node is PanelContainer:
			return true
		node = node.get_parent()
	return false

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
