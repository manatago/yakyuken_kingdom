extends Control

const DefaultStoryScript := preload("res://story/DefaultStory.gd")

@warning_ignore("unused_signal")
signal result_updated(text)

@export var enable_story_playback := true

@onready var background_rect = $Background
@onready var title_menu = $TitleMenu
@onready var new_game_button = $TitleMenu/NewGameButton
@onready var continue_button = $TitleMenu/ContinueButton
@onready var jump_menu = $JumpMenu
@onready var jump_list = $JumpMenu/JumpList
@onready var back_button = $JumpMenu/BackButton
@onready var battle_result_screen = $BattleResultScreen
@onready var result_title = $BattleResultScreen/ResultMenu/ResultTitle
@onready var result_message = $BattleResultScreen/ResultMenu/ResultMessage
@onready var result_buttons = $BattleResultScreen/ResultMenu/ResultButtons

# デフォルトインベントリ（各ジャンプポイントでも使い回す）
const DEFAULT_INVENTORY: Array = [
	{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1},
	{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1},
	{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1},
]

# 開発用ジャンプ先定義
var _jump_points: Array = [
	{"label": "scene_university", "name": "大学",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_room", "name": "自室",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_lab1", "name": "研究室1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_lab2", "name": "研究室2",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_teleport1", "name": "転送広場1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_teleport2", "name": "転送広場2",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_prison", "name": "牢獄",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "tutorial_start", "name": "チュートリアル",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "after_tutorial", "name": "チュートリアル後〜バトル前",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "battle_start", "name": "本番バトル",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_result:win", "name": "バトル後（勝利）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_result:lose", "name": "バトル後（敗北）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_guild_street", "name": "--- Stage1 ---",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true}, "money": 0}},
	{"label": "scene_guild_street", "name": "ギルド通り", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "scene_analysis", "name": "道中・解析", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "scene_guild_hall", "name": "冒険者ギルド", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "stage1_battle_start", "name": "冒険者Aバトル", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "scene_guild_reception", "name": "ギルド受付", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "_guild_home", "name": "ギルドホーム",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true}, "money": 0}},
]

var story_scene_scene = preload("res://StoryScene.tscn")
var battle_scene_scene = preload("res://BattleScene.tscn")
var guild_home_scene = preload("res://GuildHome.tscn")
const Stage1TownMapScript = preload("res://town/maps/Stage1TownMap.gd")
var story_scene_instance
var story_script: DefaultStory

var is_dialogue_active = false

func _ready():
	GameState.reset()
	GameState.init_default_inventory()
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	back_button.pressed.connect(_on_jump_back)
	title_menu.visible = true
	jump_menu.visible = false

func _on_new_game():
	title_menu.visible = false
	GameState.reset()
	GameState.init_default_inventory()
	_create_story_scene()
	await scenario()

func _on_continue():
	title_menu.visible = false
	_show_jump_menu()

func _show_jump_menu():
	for child in jump_list.get_children():
		child.queue_free()
	# キャラ編集ボタン
	var edit_btn := Button.new()
	edit_btn.text = "▶ キャラ編集モード"
	edit_btn.add_theme_font_size_override("font_size", 20)
	edit_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	edit_btn.pressed.connect(_on_char_edit_mode)
	jump_list.add_child(edit_btn)
	# セパレータ
	var sep := HSeparator.new()
	jump_list.add_child(sep)
	# 通常ジャンプポイント
	for point in _jump_points:
		var btn := Button.new()
		btn.text = point.name
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_jump_selected.bind(point))
		jump_list.add_child(btn)
	jump_menu.visible = true

func _on_jump_selected(point: Dictionary):
	jump_menu.visible = false
	var label_name: String = point.label
	var sequence_id: String = point.get("sequence", "prologue")
	# ジャンプポイントの状態を GameState にセット
	GameState.reset()
	var state: Dictionary = point.get("state", {})
	GameState.apply(state)
	GameState.chapter = sequence_id
	GameState.label = label_name
	if label_name == "_guild_home":
		await _show_guild_home()
		title_menu.visible = true
		return
	if label_name.begins_with("_result:"):
		var result: String = label_name.substr(8)
		_create_story_scene()
		if result == "win":
			await _play_scene("prologue_battle_win")
		elif result == "lose":
			await _play_scene("prologue_battle_lose")
		story_scene_instance.visible = false
		var choice: String = await _show_battle_result_screen(result)
		story_scene_instance.visible = true
		if choice == "next":
			await scenario_from("stage1", "")
		elif choice == "retry":
			GameState.last_battle_result = ""
			await _play_scene_from("prologue", "battle_start")
			var entry = _scenario_order[0]
			await _handle_battle_aftermath(entry, 0)
		story_scene_instance.queue_free()
		story_scene_instance = null
		title_menu.visible = true
	else:
		_create_story_scene()
		await scenario_from(sequence_id, label_name)
		story_scene_instance.queue_free()
		story_scene_instance = null
		title_menu.visible = true

func _on_jump_back():
	jump_menu.visible = false
	title_menu.visible = true

# --- キャラ編集モード ---

signal _char_edit_selected(char_id: String)

func _on_char_edit_mode():
	print("[EDIT] _on_char_edit_mode called")
	jump_menu.visible = false
	if not _current_town_map:
		_current_town_map = Stage1TownMapScript.new()
	var chars: Dictionary = _current_town_map.get_all_encounter_chars()
	if chars.is_empty():
		title_menu.visible = true
		return
	print("[EDIT] chars count: %d" % chars.size())
	await _show_char_select(chars)

func _show_char_select(chars: Dictionary):
	print("[EDIT] _show_char_select called")
	for child in jump_list.get_children():
		child.queue_free()
	var back_btn2 := Button.new()
	back_btn2.text = "← 戻る"
	back_btn2.add_theme_font_size_override("font_size", 20)
	back_btn2.pressed.connect(func():
		jump_menu.visible = false
		title_menu.visible = true)
	jump_list.add_child(back_btn2)
	var sep := HSeparator.new()
	jump_list.add_child(sep)
	for char_id in chars:
		var char_data: Dictionary = chars[char_id]
		var btn := Button.new()
		btn.text = char_data.get("name", char_id)
		btn.add_theme_font_size_override("font_size", 20)
		var cid: String = char_id  # ラムダ用にローカルコピー
		btn.pressed.connect(func():
			print("[EDIT] button pressed: %s" % cid)
			_char_edit_selected.emit(cid))
		jump_list.add_child(btn)
	jump_menu.visible = true
	# 選択待ちループ
	while true:
		var selected_id: String = await _char_edit_selected
		print("[EDIT] selected: %s" % selected_id)
		jump_menu.visible = false
		await _run_char_edit_test(chars[selected_id])
		# テスト終了 → キャラ選択に戻る
		for child2 in jump_list.get_children():
			child2.queue_free()
		back_btn2 = Button.new()
		back_btn2.text = "← 戻る"
		back_btn2.add_theme_font_size_override("font_size", 20)
		back_btn2.pressed.connect(func():
			jump_menu.visible = false
			title_menu.visible = true)
		jump_list.add_child(back_btn2)
		sep = HSeparator.new()
		jump_list.add_child(sep)
		for char_id2 in chars:
			var char_data2: Dictionary = chars[char_id2]
			var btn2 := Button.new()
			btn2.text = char_data2.get("name", char_id2)
			btn2.add_theme_font_size_override("font_size", 20)
			btn2.pressed.connect(func(): _char_edit_selected.emit(char_id2))
			jump_list.add_child(btn2)
		jump_menu.visible = true

signal _edit_setup_done

func _run_char_edit_test(encounter_data: Dictionary):
	GameState.reset()
	GameState.init_default_inventory()
	# 編集モード: 全アイテム・装備品を付与
	for item_data in ItemDatabase.get_all_consumables():
		GameState.add_item({"id": item_data.id, "name": item_data.name, "count": 3})
	for equip_data in ItemDatabase.get_all_equipment():
		GameState.equipment.append({"id": equip_data.id, "name": equip_data.name})

	# 装備選択画面
	await _show_edit_equip_screen()

	# エリア背景を探す（このキャラが出現する最初のエリア）
	var areas: Dictionary = _current_town_map.get_areas()
	var bg_path: String = _current_town_map.get_home_background()
	for area_id in areas:
		var encounters: Array = _current_town_map.get_encounters(area_id)
		for enc in encounters:
			if enc.id == encounter_data.id:
				bg_path = areas[area_id].get("bg", bg_path)
				break

	# GuildHome を表示してエンカウントを強制発生
	var home: GuildHome = guild_home_scene.instantiate()
	add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_tex = load(bg_path) if not bg_path.is_empty() else null
	home.setup(bg_tex, _current_town_map)

	# エンカウント用の編集パネルを作成
	var edit_panel := _create_edit_overlay(encounter_data)
	add_child(edit_panel)
	move_child(edit_panel, get_child_count() - 1)
	_connect_edit_to_portrait(edit_panel, home.encounter_portrait, encounter_data)

	# エンカウント表示を強制実行
	print("[EDIT] showing encounter for: %s" % encounter_data.get("name", ""))
	home.narration_band.visible = true
	home.narration_label.text = "【キャラ編集モード】"

	var accepted: bool = await home._show_encounter(encounter_data)
	print("[EDIT] encounter result: accepted=%s" % str(accepted))
	# エンカウント用パネルを破棄
	edit_panel.queue_free()
	if not accepted:
		home.queue_free()
		return

	# バトル実行
	var chapter := RandomBattleChapter.new()
	encounter_data["battle_bg"] = bg_path
	chapter.setup_from_encounter(encounter_data)
	home.visible = false

	# バトル用の編集パネルを新規作成
	var battle_edit_panel := _create_edit_overlay(encounter_data)
	add_child(battle_edit_panel)

	var edit_battle = battle_scene_scene.instantiate()
	add_child(edit_battle)
	edit_battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edit_battle.setup(story_script.get_cast() if story_script else {}, bg_tex, GameState.inventory)
	edit_battle.start_battle(chapter)
	move_child(battle_edit_panel, get_child_count() - 1)
	_connect_edit_to_battle(battle_edit_panel, edit_battle, encounter_data)

	var edit_result: String = await edit_battle.battle_finished
	var edit_rewards = edit_battle.get_battle_rewards()
	if edit_result == "win" and chapter.can_gain_cards():
		for card in edit_rewards.captured_by_player:
			GameState.add_card(card)
	edit_battle.queue_free()
	battle_edit_panel.queue_free()

	# バトル後: ストーリーモードで去り際シーン表示
	home.visible = true
	var farewell_line: String = chapter.get_farewell(edit_result)
	if not farewell_line.is_empty():
		# 去り際用の編集パネル
		var farewell_edit_panel := _create_edit_overlay(encounter_data)
		add_child(farewell_edit_panel)
		move_child(farewell_edit_panel, get_child_count() - 1)

		# 去り際ポートレートを表示
		var farewell_portrait: Dictionary = EncounterDatabase.get_portrait(encounter_data, "farewell")
		var fw_path: String = farewell_portrait.get("path", "")
		if not fw_path.is_empty():
			var fw_tex = load(fw_path)
			if fw_tex:
				home.encounter_portrait.texture = fw_tex
				home._apply_encounter_portrait(fw_tex, farewell_portrait)
		home.encounter_portrait.visible = true
		home.narration_label.visible = false
		home.nav_row.visible = false
		home.encounter_speaker.text = encounter_data.get("name", "")
		home.encounter_speaker.visible = true
		home.encounter_body.text = farewell_line
		home.encounter_right.visible = true
		home.narration_band.visible = true

		_connect_edit_to_portrait(farewell_edit_panel, home.encounter_portrait, encounter_data)
		# スライダーの初期値をfarewell設定に変更
		var fw_sl := _get_edit_sliders(farewell_edit_panel)
		var fw_init_scale: float = farewell_portrait.get("scale", 0.5)
		var fw_init_pos = farewell_portrait.get("position", [0, 0])
		var fw_init_x: float = fw_init_pos[0] if fw_init_pos is Array and fw_init_pos.size() >= 2 else 0.0
		var fw_init_y: float = fw_init_pos[1] if fw_init_pos is Array and fw_init_pos.size() >= 2 else 0.0
		_set_slider_range(fw_sl.scale, fw_sl.scale_spin, 0.1, 1.5, 0.01, fw_init_scale)
		_set_slider_range(fw_sl.x, fw_sl.x_spin, -500, 500, 1, fw_init_x)
		_set_slider_range(fw_sl.y, fw_sl.y_spin, -600, 300, 1, fw_init_y)

		# クリック待ち
		home._waiting_for_click = true
		await home._click_received
		home._waiting_for_click = false

		home._hide_encounter()
		farewell_edit_panel.queue_free()

	# アイテム・装備品確認画面
	await _show_edit_result_screen(home)
	home.queue_free()

func _show_edit_equip_screen():
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(550, 500)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "装備・アイテム選択"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 装備品（着脱ボタン付き）
	var equip_title := Label.new()
	equip_title.text = "【装備品】クリックで着脱"
	equip_title.add_theme_font_size_override("font_size", 20)
	equip_title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(equip_title)

	var equip_container := VBoxContainer.new()
	equip_container.name = "EquipList"
	equip_container.add_theme_constant_override("separation", 4)
	vbox.add_child(equip_container)

	# アイテム
	var item_title := Label.new()
	item_title.text = "【消耗品】"
	item_title.add_theme_font_size_override("font_size", 20)
	item_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(item_title)

	var item_container := VBoxContainer.new()
	item_container.name = "ItemList"
	item_container.add_theme_constant_override("separation", 4)
	vbox.add_child(item_container)

	# バトルへ進むボタン
	var start_btn := Button.new()
	start_btn.text = "バトルへ進む"
	start_btn.add_theme_font_size_override("font_size", 20)
	start_btn.pressed.connect(func(): _edit_setup_done.emit())
	vbox.add_child(start_btn)

	# 装備品リストを描画
	_refresh_equip_list(equip_container)
	_refresh_item_list(item_container)

	await _edit_setup_done
	panel.queue_free()

func _refresh_equip_list(container: VBoxContainer):
	for child in container.get_children():
		child.queue_free()
	for equip_data in ItemDatabase.get_all_equipment():
		var is_equipped: bool = GameState.has_equipment(equip_data.id)
		var btn := Button.new()
		if is_equipped:
			btn.text = "✓ %s — %s" % [equip_data.name, equip_data.description]
			btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.8))
		else:
			btn.text = "  %s — %s" % [equip_data.name, equip_data.description]
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		btn.add_theme_font_size_override("font_size", 16)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var eid: String = equip_data.id
		btn.pressed.connect(func():
			if GameState.has_equipment(eid):
				GameState.unequip(eid)
			else:
				GameState.equipment.append({"id": eid, "name": equip_data.name})
			_refresh_equip_list(container))
		container.add_child(btn)

func _refresh_item_list(container: VBoxContainer):
	for child in container.get_children():
		child.queue_free()
	for item in GameState.items:
		var item_info: Dictionary = ItemDatabase.get_item(item.id)
		if item_info.is_empty():
			continue
		var row := Label.new()
		row.text = "  %s ×%d — %s" % [item.get("name", item.id), item.get("count", 1), item_info.get("description", "")]
		row.add_theme_font_size_override("font_size", 16)
		container.add_child(row)

func _show_edit_result_screen(home: GuildHome):
	# バトル後のアイテム・装備品確認
	home.narration_label.visible = false
	home.nav_row.visible = false
	home.encounter_portrait.visible = false
	home.encounter_speaker.visible = false
	home.encounter_right.visible = false
	home.narration_band.visible = true

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(500, 450)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "バトル結果 — アイテム確認"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# カード内訳
	var card_title := Label.new()
	card_title.text = "【カード: %d枚】" % GameState.inventory.size()
	card_title.add_theme_font_size_override("font_size", 20)
	card_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(card_title)
	var card_counts := {}
	for card: Card in GameState.inventory:
		var key := "%s_%d" % [card.hand, card.grade]
		card_counts[key] = card_counts.get(key, 0) + 1
	var hand_names := {"rock": "グー", "scissors": "チョキ", "paper": "パー"}
	var grade_names := {1: "ノーマル", 2: "ブロンズ", 3: "シルバー", 4: "ゴールド", 5: "プラチナ"}
	var sorted_keys := card_counts.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		var parts: PackedStringArray = key.split("_")
		var h_name: String = hand_names.get(parts[0], parts[0])
		var g: int = int(parts[1])
		var g_name: String = grade_names.get(g, "G%d" % g)
		var row := Label.new()
		row.text = "  %s（%s）× %d" % [h_name, g_name, card_counts[key]]
		row.add_theme_font_size_override("font_size", 16)
		vbox.add_child(row)

	# ゴールド
	var gold_label := Label.new()
	gold_label.text = "所持金: %d ゴールド" % GameState.money
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	vbox.add_child(gold_label)

	# 装備品
	var equip_label := Label.new()
	equip_label.text = "【装備品】"
	equip_label.add_theme_font_size_override("font_size", 20)
	equip_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(equip_label)
	for eq in GameState.equipment:
		var row := Label.new()
		row.text = "  %s" % eq.get("name", eq.id)
		row.add_theme_font_size_override("font_size", 16)
		vbox.add_child(row)
	if GameState.equipment.is_empty():
		var empty := Label.new()
		empty.text = "  なし"
		empty.add_theme_font_size_override("font_size", 16)
		vbox.add_child(empty)

	# アイテム残数
	var item_label := Label.new()
	item_label.text = "【アイテム残数】"
	item_label.add_theme_font_size_override("font_size", 20)
	item_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(item_label)
	for item in GameState.items:
		var row := Label.new()
		row.text = "  %s ×%d" % [item.get("name", item.id), item.get("count", 1)]
		row.add_theme_font_size_override("font_size", 16)
		vbox.add_child(row)
	if GameState.items.is_empty():
		var empty := Label.new()
		empty.text = "  なし"
		empty.add_theme_font_size_override("font_size", 16)
		vbox.add_child(empty)

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): _edit_setup_done.emit())
	vbox.add_child(close_btn)

	await _edit_setup_done
	panel.queue_free()

func _create_edit_overlay(encounter_data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.78
	panel.anchor_right = 0.99
	panel.anchor_top = 0.02
	panel.anchor_bottom = 0.45
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "編集: %s" % encounter_data.get("name", "")
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(title)

	# スケール
	var scale_row := _create_slider_row("スケール", "ScaleSlider", 0.1, 1.5, 0.01, 0.4, "%.2f")
	vbox.add_child(scale_row)
	var scale_slider: HSlider = scale_row.get_node("ScaleSlider")

	# X位置
	var x_row := _create_slider_row("X", "XSlider", -500, 500, 1, 0, "%d")
	vbox.add_child(x_row)
	var x_slider: HSlider = x_row.get_node("XSlider")

	# Y位置
	var y_row := _create_slider_row("Y", "YSlider", -600, 300, 1, -199, "%d")
	vbox.add_child(y_row)
	var y_slider: HSlider = y_row.get_node("YSlider")

	# 現在の値表示
	var info := Label.new()
	info.name = "InfoLabel"
	info.text = "スライダーで調整 → 即反映"
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(info)

	# コピーボタン
	var copy_btn := Button.new()
	copy_btn.text = "設定値をコピー"
	copy_btn.add_theme_font_size_override("font_size", 14)
	copy_btn.pressed.connect(func():
		var s: float = scale_slider.value
		var x: int = int(x_slider.value)
		var y: int = int(y_slider.value)
		var text: String = '"scale": %.2f, "side": "center", "position": [%d, %d],' % [s, x, y]
		DisplayServer.clipboard_set(text)
		info.text = "コピーしました！"
	)
	vbox.add_child(copy_btn)

	return panel

func _create_slider_row(label_text: String, slider_name: String, min_val: float, max_val: float, step_val: float, default_val: float, _fmt: String = "") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.custom_minimum_size = Vector2(55, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.name = slider_name
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step_val
	slider.value = default_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 20)
	row.add_child(slider)

	var spin := SpinBox.new()
	spin.name = slider_name + "Spin"
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step_val
	spin.value = default_val
	spin.custom_minimum_size = Vector2(70, 0)
	spin.add_theme_font_size_override("font_size", 12)
	row.add_child(spin)

	# スライダーとスピンボックスを双方向連携（ループ防止）
	var updating := [false]
	slider.value_changed.connect(func(v: float):
		if updating[0]:
			return
		updating[0] = true
		if is_instance_valid(spin):
			spin.value = v
		updating[0] = false)
	spin.value_changed.connect(func(v: float):
		if updating[0]:
			return
		updating[0] = true
		if is_instance_valid(slider):
			slider.value = v
		updating[0] = false)

	return row

var _edit_target_rect: TextureRect = null

func _get_edit_sliders(edit_panel: PanelContainer) -> Dictionary:
	var vbox: VBoxContainer = edit_panel.get_child(0)
	return {
		"scale": vbox.find_child("ScaleSlider", true, false) as HSlider,
		"scale_spin": vbox.find_child("ScaleSliderSpin", true, false) as SpinBox,
		"x": vbox.find_child("XSlider", true, false) as HSlider,
		"x_spin": vbox.find_child("XSliderSpin", true, false) as SpinBox,
		"y": vbox.find_child("YSlider", true, false) as HSlider,
		"y_spin": vbox.find_child("YSliderSpin", true, false) as SpinBox,
	}

func _set_slider_range(slider: HSlider, spin: SpinBox, min_v: float, max_v: float, step_v: float, val: float):
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = val
	if spin:
		spin.min_value = min_v
		spin.max_value = max_v
		spin.step = step_v
		spin.value = val

func _connect_edit_to_portrait(edit_panel: PanelContainer, portrait: TextureRect, encounter_data: Dictionary = {}):
	_edit_target_rect = portrait
	var sl := _get_edit_sliders(edit_panel)
	# エンカウントデータからポートレート設定を読む
	var portrait_data: Dictionary = EncounterDatabase.get_portrait(encounter_data, "encounter")
	var init_scale: float = portrait_data.get("scale", 0.5)
	var init_pos = portrait_data.get("position", [0, 0])
	var init_x: float = init_pos[0] if init_pos is Array and init_pos.size() >= 2 else 0.0
	var init_y: float = init_pos[1] if init_pos is Array and init_pos.size() >= 2 else 0.0
	_set_slider_range(sl.scale, sl.scale_spin, 0.1, 1.5, 0.01, init_scale)
	_set_slider_range(sl.x, sl.x_spin, -500, 500, 1, init_x)
	_set_slider_range(sl.y, sl.y_spin, -600, 300, 1, init_y)
	sl.scale.value_changed.connect(_on_portrait_slider.bind(sl, portrait))
	sl.x.value_changed.connect(_on_portrait_slider.bind(sl, portrait))
	sl.y.value_changed.connect(_on_portrait_slider.bind(sl, portrait))

func _on_portrait_slider(_value: float, sl: Dictionary, portrait: TextureRect):
	if not is_instance_valid(portrait) or not portrait.texture:
		return
	var s: float = sl.scale.value
	var offset_x: float = sl.x.value
	var offset_y: float = sl.y.value
	var tex_size: Vector2 = portrait.texture.get_size()
	portrait.size = tex_size
	portrait.scale = Vector2(s, s)
	var vp_size: Vector2 = get_viewport_rect().size
	var visual_w: float = tex_size.x * s
	var visual_h: float = tex_size.y * s
	# バンド上端に合わせて配置
	var band_top: float = vp_size.y - 264.0
	portrait.position.x = (vp_size.x - visual_w) / 2.0 + offset_x
	portrait.position.y = band_top - visual_h + offset_y
	# ラベル更新
	var row_parent = sl.scale.get_parent().get_parent()
	var info: Label = row_parent.find_child("InfoLabel", true, false)
	if info:
		info.text = '"scale": %.2f, "position": [%d, %d]' % [s, int(offset_x), int(offset_y)]

func _connect_edit_to_battle(edit_panel: PanelContainer, battle_ref, encounter_data: Dictionary = {}):
	var sl := _get_edit_sliders(edit_panel)
	# バトル用ポートレート設定から初期値を取得
	var portrait_data: Dictionary = EncounterDatabase.get_portrait(encounter_data, "battle")
	var init_scale: float = portrait_data.get("scale", 0.4)
	var init_pos = portrait_data.get("position", [0, -199])
	var init_x: float = init_pos[0] if init_pos is Array and init_pos.size() >= 2 else 0.0
	var init_y: float = init_pos[1] if init_pos is Array and init_pos.size() >= 2 else -199.0
	_set_slider_range(sl.scale, sl.scale_spin, 0.1, 1.5, 0.01, init_scale)
	_set_slider_range(sl.x, sl.x_spin, -500, 500, 1, init_x)
	_set_slider_range(sl.y, sl.y_spin, -600, 300, 1, init_y)
	sl.scale.value_changed.connect(_on_battle_slider.bind(sl, battle_ref))
	sl.x.value_changed.connect(_on_battle_slider.bind(sl, battle_ref))
	sl.y.value_changed.connect(_on_battle_slider.bind(sl, battle_ref))

func _on_battle_slider(_value: float, sl: Dictionary, battle_ref):
	if not is_instance_valid(battle_ref):
		return
	var story_sc = battle_ref._story_scene
	if not story_sc:
		return
	var char_rect: TextureRect = null
	for rect in [story_sc.center_char, story_sc.left_char, story_sc.right_char]:
		if rect and rect.visible and rect.texture:
			char_rect = rect
			break
	if not char_rect:
		return
	var s: float = sl.scale.value
	var tex_size: Vector2 = char_rect.texture.get_size()
	char_rect.size = tex_size
	char_rect.scale = Vector2(s, s)
	var vp_size: Vector2 = get_viewport_rect().size
	var visual_w: float = tex_size.x * s
	var visual_h: float = tex_size.y * s
	char_rect.position.x = (vp_size.x - visual_w) / 2.0 + sl.x.value
	char_rect.position.y = vp_size.y - visual_h + sl.y.value
	var row_parent2 = sl.scale.get_parent().get_parent()
	var info: Label = row_parent2.find_child("InfoLabel", true, false)
	if info:
		info.text = '{"scale": %.2f, "position": [%d, %d]}' % [s, int(sl.x.value), int(sl.y.value)]

func _create_story_scene():
	story_scene_instance = story_scene_scene.instantiate()
	add_child(story_scene_instance)
	story_scene_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if background_rect and background_rect.get_parent() == self:
		var insert_index = background_rect.get_index() + 1
		move_child(story_scene_instance, insert_index)
	else:
		move_child(story_scene_instance, 0)
	story_script = DefaultStoryScript.new()
	story_scene_instance.set_cast(story_script.get_cast())
	story_scene_instance.sequence_started.connect(_on_story_sequence_started)
	story_scene_instance.sequence_finished.connect(_on_story_sequence_finished)
	story_scene_instance.battle_requested.connect(_on_battle_requested)

# --- SCENARIO & STAGES ---

var _scenario_order: Array = [
	{"id": "prologue", "battle_win": "prologue_battle_win", "battle_lose": "prologue_battle_lose"},
	{"id": "stage1", "battle_win": "stage1_battle_win", "battle_lose": "stage1_battle_lose"},
]

func scenario():
	await _run_scenario_from(0, "")

func scenario_from(sequence_id: String, label_name: String = ""):
	for i in range(_scenario_order.size()):
		if _scenario_order[i].id == sequence_id:
			await _run_scenario_from(i, label_name)
			return
	await _run_scenario_from(0, "")

func _run_scenario_from(start_index: int, label_name: String):
	for i in range(start_index, _scenario_order.size()):
		var entry: Dictionary = _scenario_order[i]
		var seq_id: String = entry.id
		GameState.chapter = seq_id
		if not label_name.is_empty():
			GameState.label = label_name
			await _play_scene_from(seq_id, label_name)
			label_name = ""
		else:
			GameState.label = ""
			await _play_scene(seq_id)
		await _handle_battle_aftermath(entry, i)
	await _show_guild_home()

func _handle_battle_aftermath(entry: Dictionary, scene_index: int):
	if GameState.last_battle_result.is_empty():
		return
	var result: String = GameState.last_battle_result
	GameState.last_battle_result = ""
	var win_seq_id: String = entry.get("battle_win", "")
	var lose_seq_id: String = entry.get("battle_lose", "")
	if result == "win" and not win_seq_id.is_empty():
		await _play_scene(win_seq_id)
	elif result == "lose" and not lose_seq_id.is_empty():
		await _play_scene(lose_seq_id)
	story_scene_instance.visible = false
	var choice: String = await _show_battle_result_screen(result)
	story_scene_instance.visible = true
	if choice == "retry":
		GameState.last_battle_result = ""
		await _play_scene_from(entry.id, "battle_start")
		await _handle_battle_aftermath(entry, scene_index)

func _play_scene(sequence_key):
	var seq = story_script.get_sequence(sequence_key)
	if seq:
		await story_scene_instance.play_sequence(seq, {"id": sequence_key})

func _play_scene_from(sequence_key: String, label_name: String):
	var seq = story_script.get_sequence(sequence_key)
	if seq:
		await story_scene_instance.play_sequence(seq, {"id": sequence_key, "skip_to": label_name})

func _on_story_sequence_started(_sequence_id):
	is_dialogue_active = true

func _on_story_sequence_finished(_sequence_id):
	is_dialogue_active = false

# --- Battle bridge ---

func _on_battle_requested(cmd):
	if cmd.chapter == null:
		story_scene_instance.complete_battle("win")
		return

	if cmd.is_tutorial:
		story_scene_instance.visible = false
		var tut_battle = battle_scene_scene.instantiate()
		add_child(tut_battle)
		tut_battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tut_battle.setup(story_script.get_cast(), story_scene_instance.background_rect.texture, GameState.inventory)
		tut_battle.start_battle(cmd.chapter, true)
		var tut_result: String = await tut_battle.battle_finished
		var tut_rewards = tut_battle.get_battle_rewards()
		if tut_result == "win" and cmd.chapter.can_gain_cards():
			for card in tut_rewards.captured_by_player:
				GameState.add_card(card)
		elif tut_result == "lose" and cmd.chapter.can_lose_cards():
			for card in tut_rewards.captured_by_opponent:
				GameState.remove_card(card)
		tut_battle.queue_free()
		story_scene_instance.visible = true
		story_scene_instance.complete_battle("win")
		return

	story_scene_instance.visible = false
	var battle_instance = battle_scene_scene.instantiate()
	add_child(battle_instance)
	battle_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_instance.setup(story_script.get_cast(), story_scene_instance.background_rect.texture, GameState.inventory)
	battle_instance.start_battle(cmd.chapter)
	var result: String = await battle_instance.battle_finished

	var rewards = battle_instance.get_battle_rewards()
	if result == "win" and cmd.chapter.can_gain_cards():
		for card in rewards.captured_by_player:
			GameState.add_card(card)
	elif result == "lose" and cmd.chapter.can_lose_cards():
		for card in rewards.captured_by_opponent:
			GameState.remove_card(card)

	battle_instance.queue_free()
	cmd.result = result
	GameState.last_battle_result = result
	story_scene_instance.visible = true
	story_scene_instance.complete_battle(result)

# --- Battle Result Screen ---

signal _result_choice_made(choice: String)

func _show_battle_result_screen(result: String) -> String:
	for child in result_buttons.get_children():
		child.queue_free()

	if result == "win":
		result_title.text = "勝利！"
		result_message.text = "見事な勝利です！次の章へ進みますか？"
		_add_result_button("次の章へ", "next")
		_add_result_button("タイトルに戻る", "title")
	elif result == "lose":
		result_title.text = "敗北..."
		result_message.text = "残念...再戦しますか？"
		_add_result_button("再戦する", "retry")
		_add_result_button("タイトルに戻る", "title")
	else:
		result_title.text = "引き分け"
		result_message.text = "決着がつきませんでした。"
		_add_result_button("再戦する", "retry")
		_add_result_button("タイトルに戻る", "title")

	battle_result_screen.visible = true
	var choice: String = await _result_choice_made
	battle_result_screen.visible = false
	return choice

func _add_result_button(text: String, choice: String):
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): _result_choice_made.emit(choice))
	result_buttons.add_child(btn)

# --- Guild Home ---

var _current_town_map: TownMapBase = null

func _show_guild_home():
	if story_scene_instance:
		story_scene_instance.visible = false
	if not _current_town_map:
		_current_town_map = Stage1TownMapScript.new()
	var home = guild_home_scene.instantiate()
	add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_tex = load(_current_town_map.get_home_background())
	home.setup(bg_tex, _current_town_map)
	home.battle_encounter.connect(_on_town_battle.bind(home))
	while true:
		var action: String = await home.home_action
		if action == "exit":
			home.queue_free()
			if story_scene_instance:
				story_scene_instance.queue_free()
				story_scene_instance = null
			title_menu.visible = true
			return
		elif action == "next_story":
			home.queue_free()
			if story_scene_instance:
				story_scene_instance.visible = true
			return

func _on_town_battle(area_id: String, chapter: BattleChapterBase, home: GuildHome):
	if not chapter:
		home.arrive_at(area_id)
		return
	home.visible = false
	var battle_instance = battle_scene_scene.instantiate()
	add_child(battle_instance)
	battle_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_tex = load(chapter.get_battle_background()) if not chapter.get_battle_background().is_empty() else null
	battle_instance.setup(story_script.get_cast() if story_script else {}, bg_tex, GameState.inventory)
	battle_instance.start_battle(chapter)
	var result: String = await battle_instance.battle_finished
	var rewards = battle_instance.get_battle_rewards()
	if result == "win":
		for card in rewards.captured_by_player:
			GameState.add_card(card)
	elif result == "lose" and chapter.can_lose_cards():
		for card in rewards.captured_by_opponent:
			GameState.remove_card(card)
	battle_instance.queue_free()
	home.visible = true
	home.arrive_at(area_id)
