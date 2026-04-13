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
	{"label": "_subevent_pre:subevent1", "name": "サブイベント1 前半（盗賊団）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true}, "money": 100}},
	{"label": "_subevent_post:subevent1", "name": "サブイベント1 後半（ベルカ決着後）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true}, "money": 100}},
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
	# イベントバトル編集ボタン
	var event_edit_btn := Button.new()
	event_edit_btn.text = "▶ イベントバトル編集"
	event_edit_btn.add_theme_font_size_override("font_size", 20)
	event_edit_btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	event_edit_btn.pressed.connect(_on_event_battle_edit_mode)
	jump_list.add_child(event_edit_btn)
	# ストーリー編集ボタン
	var story_edit_btn := Button.new()
	story_edit_btn.text = "▶ ストーリー編集"
	story_edit_btn.add_theme_font_size_override("font_size", 20)
	story_edit_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	story_edit_btn.pressed.connect(_on_story_edit_mode)
	jump_list.add_child(story_edit_btn)
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
	if label_name.begins_with("_subevent_pre:"):
		var quest_id := label_name.substr(14)
		await _run_subevent_part_standalone(quest_id, "pre")
		if GameState.last_battle_result == "lose":
			await _show_guild_home()
		title_menu.visible = true
		return
	if label_name.begins_with("_subevent_post:"):
		var quest_id := label_name.substr(15)
		await _run_subevent_part_standalone(quest_id, "post")
		title_menu.visible = true
		return
	if label_name.begins_with("_subevent:"):
		var quest_id := label_name.substr(10)
		await _run_subevent_standalone(quest_id)
		if GameState.last_battle_result == "lose":
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
	# 編集モード: 全アイテム・装備品・ゴールドを付与
	GameState.money = 1000
	for item_data in ItemDatabase.get_all_consumables():
		GameState.add_item({"id": item_data.id, "name": item_data.name, "count": 3})
	for equip_data in ItemDatabase.get_all_equipment():
		GameState.equipment.append({"id": equip_data.id, "name": equip_data.name})

	# エリア選択画面
	var bg_path: String = await _show_edit_area_select(encounter_data)

	# 装備選択画面
	await _show_edit_equip_screen()

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
	if edit_result == "win":
		if chapter.can_gain_cards():
			for card in edit_rewards.captured_by_player:
				GameState.add_card(card)
		var gold: int = edit_battle.get_rolled_gold()
		if gold > 0:
			GameState.money += gold
	elif edit_result == "lose":
		if chapter.can_lose_cards():
			for card in edit_rewards.captured_by_opponent:
				GameState.remove_card(card)
		var lost_gold: int = edit_battle.get_lost_gold()
		if lost_gold > 0:
			GameState.money = max(GameState.money - lost_gold, 0)
	_battle_edit_active = false
	edit_battle.queue_free()
	battle_edit_panel.queue_free()

	# バトル後: ストーリーモードで去り際シーン表示
	home.visible = true
	var farewell_line: String = chapter.get_encounter_farewell(edit_result) if chapter.has_method("get_encounter_farewell") else ""
	if not farewell_line.is_empty():
		# 去り際用の編集パネル
		var farewell_edit_panel := _create_edit_overlay(encounter_data)
		add_child(farewell_edit_panel)
		move_child(farewell_edit_panel, get_child_count() - 1)

		# 去り際ポートレートを表示
		var fw_scene_key: String = "farewell_win" if edit_result == "win" else "farewell_lose"
		var farewell_portrait: Dictionary = EncounterDatabase.get_portrait(encounter_data, fw_scene_key)
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

		# farewell ポートレートデータを直接渡して初期値をセット
		var fw_data_for_edit := encounter_data.duplicate()
		fw_data_for_edit["portraits"] = {"encounter": farewell_portrait}
		_connect_edit_to_portrait(farewell_edit_panel, home.encounter_portrait, fw_data_for_edit)

		# クリック待ち
		home._waiting_for_click = true
		await home._click_received
		home._waiting_for_click = false

		home._hide_encounter()
		farewell_edit_panel.queue_free()

	# アイテム・装備品確認画面
	await _show_edit_result_screen(home)
	home.queue_free()

signal _area_selected(bg_path: String)

func _show_edit_area_select(encounter_data: Dictionary) -> String:
	# このキャラが出現するエリアを収集
	var areas: Dictionary = _current_town_map.get_areas()
	var char_areas: Array = []
	for area_id in areas:
		var encounters: Array = _current_town_map.get_encounters(area_id)
		for enc in encounters:
			if enc.id == encounter_data.id:
				char_areas.append({"id": area_id, "name": areas[area_id].name, "bg": areas[area_id].bg})
				break

	# 1つしかなければ選択不要
	if char_areas.size() <= 1:
		if char_areas.size() == 1:
			return char_areas[0].bg
		return _current_town_map.get_home_background()

	# エリア選択UI
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
	panel.custom_minimum_size = Vector2(400, 300)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "エリア選択"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "%s が出現するエリア:" % encounter_data.get("name", "")
	desc.add_theme_font_size_override("font_size", 16)
	vbox.add_child(desc)

	for area in char_areas:
		var btn := Button.new()
		btn.text = area.name
		btn.add_theme_font_size_override("font_size", 20)
		var area_bg: String = area.bg
		btn.pressed.connect(func(): _area_selected.emit(area_bg))
		vbox.add_child(btn)

	var selected_bg: String = await _area_selected
	panel.queue_free()
	return selected_bg

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
	var sorted_keys := card_counts.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		var parts: PackedStringArray = key.split("_")
		vbox.add_child(GameState.create_card_label(parts[0], int(parts[1]), card_counts[key], 16, 22))

	# ゴールド
	vbox.add_child(GameState.create_gold_label(GameState.money, 20, 26, "所持金: "))

	# 装備品
	var equip_label := Label.new()
	equip_label.text = "【装備品】"
	equip_label.add_theme_font_size_override("font_size", 20)
	equip_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(equip_label)
	for eq in GameState.equipment:
		vbox.add_child(GameState.create_item_label(eq.get("name", eq.id), 1, 16, 22))
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
		vbox.add_child(GameState.create_item_label(item.get("name", item.id), item.get("count", 1), 16, 22))
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
	print("[EDIT-PORTRAIT] slider changed. portrait valid=%s has_tex=%s" % [str(is_instance_valid(portrait)), str(portrait.texture != null) if is_instance_valid(portrait) else "N/A"])
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
	portrait.position.x = (vp_size.x - visual_w) / 2.0 + offset_x
	portrait.position.y = vp_size.y - visual_h + offset_y
	# ラベル更新
	var row_parent = sl.scale.get_parent().get_parent()
	var info: Label = row_parent.find_child("InfoLabel", true, false)
	if info:
		info.text = '"scale": %.2f, "position": [%d, %d]' % [s, int(offset_x), int(offset_y)]

var _battle_edit_sl: Dictionary = {}
var _battle_edit_ref = null
var _battle_edit_last_tex: Texture2D = null
var _battle_edit_active := false

func _connect_edit_to_battle(edit_panel: PanelContainer, battle_ref, encounter_data: Dictionary = {}):
	var sl := _get_edit_sliders(edit_panel)
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
	# 画像変更検知用
	_battle_edit_sl = sl
	_battle_edit_ref = battle_ref
	_battle_edit_last_tex = null
	_battle_edit_active = true

func _process(_delta: float):
	if not _battle_edit_active:
		return
	if not is_instance_valid(_battle_edit_ref):
		_battle_edit_active = false
		return
	var story_sc = _battle_edit_ref._story_scene
	if not story_sc:
		return
	var char_rect: TextureRect = _find_visible_char_rect(story_sc)
	if not char_rect:
		return
	# 画像が変わったらスライダーを実際の値に更新
	if char_rect.texture != _battle_edit_last_tex:
		_battle_edit_last_tex = char_rect.texture
		_set_slider_range(_battle_edit_sl.scale, _battle_edit_sl.scale_spin, 0.1, 1.5, 0.01, char_rect.scale.x)
		var vp_size: Vector2 = get_viewport_rect().size
		var tex_size: Vector2 = char_rect.texture.get_size()
		var s: float = char_rect.scale.x
		var visual_w: float = tex_size.x * s
		var visual_h: float = tex_size.y * s
		var base_x: float = (vp_size.x - visual_w) / 2.0
		var base_y: float = vp_size.y - visual_h
		var offset_x: float = char_rect.position.x - base_x
		var offset_y: float = char_rect.position.y - base_y
		_set_slider_range(_battle_edit_sl.x, _battle_edit_sl.x_spin, -500, 500, 1, offset_x)
		_set_slider_range(_battle_edit_sl.y, _battle_edit_sl.y_spin, -600, 300, 1, offset_y)

func _find_visible_char_rect(story_sc) -> TextureRect:
	for rect in [story_sc.center_char, story_sc.left_char, story_sc.right_char]:
		if rect and rect.visible and rect.texture:
			return rect
	return null

func _on_battle_slider(_value: float, sl: Dictionary, battle_ref):
	if not is_instance_valid(battle_ref):
		return
	var story_sc = battle_ref._story_scene
	if not story_sc:
		return
	var char_rect: TextureRect = _find_visible_char_rect(story_sc)
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
		info.text = '"scale": %.2f, "position": [%d, %d]' % [s, int(sl.x.value), int(sl.y.value)]

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
	# chapter_path からチャプターをロード（b.battle() で path のみ指定の場合）
	if cmd.chapter == null and not cmd.chapter_path.is_empty():
		var script = load(cmd.chapter_path)
		if script:
			cmd.chapter = script.new()
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
		if tut_result == "win":
			if cmd.chapter.can_gain_cards():
				for card in tut_rewards.captured_by_player:
					GameState.add_card(card)
			var gold: int = tut_battle.get_rolled_gold()
			if gold > 0:
				GameState.money += gold
		elif tut_result == "lose":
			if cmd.chapter.can_lose_cards():
				for card in tut_rewards.captured_by_opponent:
					GameState.remove_card(card)
			var lost_gold: int = tut_battle.get_lost_gold()
			if lost_gold > 0:
				GameState.money = max(GameState.money - lost_gold, 0)
		tut_battle.queue_free()
		story_scene_instance.visible = true
		story_scene_instance.complete_battle("win")
		return

	var bg_tex: Texture2D = story_scene_instance.background_rect.texture
	story_scene_instance.visible = false
	var lose_behavior: String = cmd.chapter.get_lose_behavior()
	var final_result := "win"

	while true:
		# バトル実行
		var battle_result: Dictionary = await _execute_battle(cmd.chapter, bg_tex)
		final_result = battle_result.result

		if final_result == "win":
			break

		# 負け → ストーリーシーンでfarewell表示
		await _show_battle_farewell_in_scene(cmd.chapter, final_result, bg_tex)

		# リダイレクト判定
		if lose_behavior == "redirect":
			var redirect: Dictionary = cmd.chapter.get_lose_redirect()
			if redirect.get("type", "") == "retry_scene":
				var choice: String = await _show_retry_scene(redirect)
				if choice == "retry":
					continue  # 再バトル
				else:
					final_result = "lose"
					break
			else:
				break
		elif lose_behavior == "abort":
			break
		else:
			break

	cmd.result = final_result
	GameState.last_battle_result = final_result
	story_scene_instance.visible = true
	if final_result == "lose" and lose_behavior != "continue":
		story_scene_instance._abort_sequence = true
	story_scene_instance.complete_battle(final_result)

# --- バトル実行共通関数 ---

func _execute_battle(chapter: BattleChapterBase, bg_tex: Texture2D) -> Dictionary:
	var battle_instance = battle_scene_scene.instantiate()
	add_child(battle_instance)
	battle_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_instance.setup(story_script.get_cast() if story_script else {}, bg_tex, GameState.inventory)
	battle_instance.start_battle(chapter)
	var result: String = await battle_instance.battle_finished

	var rewards = battle_instance.get_battle_rewards()
	if result == "win":
		if chapter.can_gain_cards():
			for card in rewards.captured_by_player:
				GameState.add_card(card)
		var gold: int = battle_instance.get_rolled_gold()
		if gold > 0:
			GameState.money += gold
	elif result == "lose":
		if chapter.can_lose_cards():
			for card in rewards.captured_by_opponent:
				GameState.remove_card(card)
		var lost_gold: int = battle_instance.get_lost_gold()
		if lost_gold > 0:
			GameState.money = max(GameState.money - lost_gold, 0)

	battle_instance.queue_free()
	return {"result": result, "rewards": rewards}

# --- バトル後 farewell 表示（ストーリーシーン内） ---

signal _farewell_dismissed

func _show_battle_farewell_in_scene(chapter: BattleChapterBase, result: String, bg_tex: Texture2D):
	var farewell: Dictionary = chapter.get_farewell(result)
	if farewell.is_empty():
		return

	var narration: String = farewell.get("narration", "")
	var portrait_path: String = farewell.get("portrait", "")
	var text: String = farewell.get("text", "")
	if narration.is_empty() and portrait_path.is_empty() and text.is_empty():
		return

	# ストーリーシーンを再表示
	story_scene_instance.visible = true
	if bg_tex:
		story_scene_instance.background_rect.texture = bg_tex
	story_scene_instance.left_char.visible = false
	story_scene_instance.center_char.visible = false
	story_scene_instance.right_char.visible = false

	var speaker_label: Label = story_scene_instance.dialogue_band.get_node("VBox/SpeakerLabel")
	var body_label: Label = story_scene_instance.dialogue_band.get_node("VBox/BodyLabel")

	# 1. ナレーション表示（キャラなし）
	if not narration.is_empty():
		story_scene_instance.dialogue_band.visible = true
		if speaker_label:
			speaker_label.text = ""
		if body_label:
			body_label.text = narration
		story_scene_instance._waiting_for_input = true
		await story_scene_instance.advance_requested
		story_scene_instance._waiting_for_input = false

	# 2. 敵キャラ表示 + セリフ
	if not portrait_path.is_empty() or not text.is_empty():
		if not portrait_path.is_empty():
			var tex = load(portrait_path)
			if tex:
				var s: float = farewell.get("portrait_scale", 0.5)
				story_scene_instance.right_char.texture = tex
				story_scene_instance.right_char.size = tex.get_size()
				story_scene_instance.right_char.scale = Vector2(s, s)
				var vp_size := get_viewport_rect().size
				var visual_w: float = tex.get_size().x * s
				var visual_h: float = tex.get_size().y * s
				story_scene_instance.right_char.position.x = vp_size.x - visual_w - 100
				story_scene_instance.right_char.position.y = vp_size.y - visual_h
				story_scene_instance.right_char.flip_h = false
				story_scene_instance.right_char.visible = true
				story_scene_instance._char_locked_positions[story_scene_instance.right_char] = story_scene_instance.right_char.position

		if not text.is_empty():
			var speaker_name: String = chapter.get_opponent_name()
			story_scene_instance.dialogue_band.visible = true
			if speaker_label:
				speaker_label.text = speaker_name
			if body_label:
				body_label.text = text

		story_scene_instance._waiting_for_input = true
		await story_scene_instance.advance_requested
		story_scene_instance._waiting_for_input = false

	# クリーンアップ
	story_scene_instance.right_char.visible = false
	story_scene_instance._char_locked_positions.erase(story_scene_instance.right_char)
	story_scene_instance.dialogue_band.visible = false
	story_scene_instance.visible = false

# --- リトライシーン（マチルダ戦用） ---

signal _retry_choice_made(choice: String)

func _show_retry_scene(redirect: Dictionary) -> String:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# 背景画像
	var bg_path: String = redirect.get("background", "")
	if not bg_path.is_empty():
		var bg_tex = load(bg_path)
		if bg_tex:
			var bg_rect := TextureRect.new()
			bg_rect.texture = bg_tex
			bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bg_rect.expand_mode = 1
			bg_rect.stretch_mode = 6
			bg_rect.modulate = Color(0.4, 0.4, 0.4)
			panel.add_child(bg_rect)
			panel.move_child(bg_rect, 0)

	# ナレーション
	var narration: String = redirect.get("narration", "")
	if not narration.is_empty():
		var label := Label.new()
		label.text = narration
		label.add_theme_font_size_override("font_size", 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(label)

	# 選択肢ボタン
	var choices: Array = redirect.get("choices", ["再挑戦する", "ホームに戻る"])
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_row)

	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(200, 50)
		var choice_val: String = "retry" if i == 0 else "home"
		btn.pressed.connect(_on_retry_choice.bind(choice_val))
		btn_row.add_child(btn)

	var choice: String = await _retry_choice_made
	panel.queue_free()
	return choice

func _on_retry_choice(choice: String):
	_retry_choice_made.emit(choice)

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
		elif action.begins_with("quest:"):
			var quest_id := action.trim_prefix("quest:")
			await _run_subevent(quest_id, home)

func _on_town_battle(area_id: String, chapter: BattleChapterBase, home: GuildHome):
	if not chapter:
		home.arrive_at(area_id)
		return
	home.visible = false
	var bg_tex = load(chapter.get_battle_background()) if not chapter.get_battle_background().is_empty() else null
	var battle_result: Dictionary = await _execute_battle(chapter, bg_tex)
	var result: String = battle_result.result
	home.visible = true

	# 去り際シーン（ランダムバトル用）
	if chapter.has_method("get_encounter_farewell"):
		var farewell_line: String = chapter.get_encounter_farewell(result)
		if not farewell_line.is_empty():
			var fw_key: String = "farewell_win" if result == "win" else "farewell_lose"
			var fw_portrait: Dictionary = EncounterDatabase.get_portrait(chapter._data, fw_key) if chapter.has_method("get_encounter_farewell_portrait") else {}
			var fw_path: String = fw_portrait.get("path", "")
			if not fw_path.is_empty():
				var fw_tex = load(fw_path)
				if fw_tex:
					home.encounter_portrait.texture = fw_tex
					home._apply_encounter_portrait(fw_tex, fw_portrait)
			home.encounter_portrait.visible = true
			home.narration_label.visible = false
			home.nav_row.visible = false
			home.encounter_speaker.text = chapter.get_opponent_name()
			home.encounter_speaker.visible = true
			home.encounter_body.text = farewell_line
			home.encounter_right.visible = true
			home.narration_band.visible = true
			home._waiting_for_click = true
			await home._click_received
			home._waiting_for_click = false
			home._hide_encounter()

	home.arrive_at(area_id)

# --- サブイベント実行 ---

const Subevent1ChapterScript := preload("res://story/chapters/Subevent1Chapter.gd")
var _subevent_in_progress := false

const SUBEVENT_CHAPTERS := {
	"subevent1": {
		"name": "盗賊団を解体せよ！",
		"chapter_script": "Subevent1ChapterScript",
		"pre_sequence_id": "subevent1_pre",
		"post_sequence_id": "subevent1_post",
	},
	"subevent2": {"name": "教会の不正を暴け！", "chapter_script": "", "pre_sequence_id": ""},
	"subevent3": {"name": "呪われた鎧を脱がせ！", "chapter_script": "", "pre_sequence_id": ""},
	"subevent4": {"name": "受付嬢を脱がせ！", "chapter_script": "", "pre_sequence_id": ""},
}

func _ensure_subevent_registered(quest_id: String):
	if not story_script:
		story_script = DefaultStoryScript.new()
	if quest_id == "subevent1":
		if not story_script.get_sequence("subevent1_pre"):
			story_script._register_chapter(Subevent1ChapterScript.new())

func _run_subevent(quest_id: String, home: GuildHome):
	var quest_data: Dictionary = SUBEVENT_CHAPTERS.get(quest_id, {})
	if quest_data.is_empty():
		print("[QUEST] Unknown quest: ", quest_id)
		return

	var pre_id: String = quest_data.get("pre_sequence_id", "")
	if pre_id.is_empty():
		print("[QUEST] %s: ストーリー未実装" % quest_data.get("name", quest_id))
		return

	_ensure_subevent_registered(quest_id)

	var pre_seq = story_script.get_sequence(pre_id)
	if not pre_seq:
		print("[QUEST] Sequence not found: ", pre_id)
		return

	# Hide home, show story scene
	home.visible = false
	_subevent_in_progress = true

	if not story_scene_instance:
		story_scene_instance = story_scene_scene.instantiate()
		add_child(story_scene_instance)
		story_scene_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		story_scene_instance.set_cast(story_script.get_cast())
		story_scene_instance.sequence_started.connect(_on_story_sequence_started)
		story_scene_instance.sequence_finished.connect(_on_story_sequence_finished)
		story_scene_instance.battle_requested.connect(_on_battle_requested)
	else:
		story_scene_instance.visible = true

	# 前半ストーリー再生（手下戦 + ベルカ戦を含む）
	await story_scene_instance.play_sequence(pre_seq, {"id": pre_id})

	# バトルで負けたらギルドホームに戻る
	if GameState.last_battle_result == "lose":
		_subevent_in_progress = false
		story_scene_instance.visible = false
		home.visible = true
		return

	# 後半ストーリー再生
	var post_id: String = quest_data.get("post_sequence_id", "")
	if not post_id.is_empty():
		var post_seq = story_script.get_sequence(post_id)
		if post_seq:
			await story_scene_instance.play_sequence(post_seq, {"id": post_id})

	_subevent_in_progress = false
	story_scene_instance.visible = false
	home.visible = true

func _run_subevent_part_standalone(quest_id: String, part: String):
	var quest_data: Dictionary = SUBEVENT_CHAPTERS.get(quest_id, {})
	if quest_data.is_empty():
		print("[QUEST] Unknown quest: ", quest_id)
		return

	var seq_id: String = ""
	if part == "pre":
		seq_id = quest_data.get("pre_sequence_id", "")
	elif part == "post":
		seq_id = quest_data.get("post_sequence_id", "")
	if seq_id.is_empty():
		print("[QUEST] %s %s: 未実装" % [quest_data.get("name", quest_id), part])
		return

	_create_story_scene()
	_ensure_subevent_registered(quest_id)

	var seq = story_script.get_sequence(seq_id)
	if not seq:
		print("[QUEST] Sequence not found: ", seq_id)
		return

	await story_scene_instance.play_sequence(seq, {"id": seq_id})

	if story_scene_instance:
		story_scene_instance.queue_free()
		story_scene_instance = null

func _run_subevent_standalone(quest_id: String):
	var quest_data: Dictionary = SUBEVENT_CHAPTERS.get(quest_id, {})
	if quest_data.is_empty():
		print("[QUEST] Unknown quest: ", quest_id)
		return

	var pre_id: String = quest_data.get("pre_sequence_id", "")
	if pre_id.is_empty():
		print("[QUEST] %s: ストーリー未実装" % quest_data.get("name", quest_id))
		return

	_create_story_scene()
	_ensure_subevent_registered(quest_id)
	_subevent_in_progress = true

	var pre_seq = story_script.get_sequence(pre_id)
	if not pre_seq:
		print("[QUEST] Sequence not found: ", pre_id)
		return

	# 前半（手下戦 + ベルカ戦を含む）
	await story_scene_instance.play_sequence(pre_seq, {"id": pre_id})

	# バトルで負けたら終了
	if GameState.last_battle_result == "lose":
		_subevent_in_progress = false
		if story_scene_instance:
			story_scene_instance.queue_free()
			story_scene_instance = null
		return

	# 後半
	var post_id: String = quest_data.get("post_sequence_id", "")
	if not post_id.is_empty():
		var post_seq = story_script.get_sequence(post_id)
		if post_seq:
			await story_scene_instance.play_sequence(post_seq, {"id": post_id})

	_subevent_in_progress = false
	if story_scene_instance:
		story_scene_instance.queue_free()
		story_scene_instance = null

# --- ストーリー編集モード ---

const STORY_EDIT_SEQUENCES := [
	{"id": "subevent1_pre", "name": "サブイベント1 前半（盗賊団）", "chapter": "Subevent1ChapterScript"},
	{"id": "subevent1_post", "name": "サブイベント1 後半（盗賊団決着）", "chapter": "Subevent1ChapterScript"},
	{"id": "prologue", "name": "プロローグ"},
	{"id": "stage1", "name": "ステージ1"},
]

signal _story_edit_selected(index: int)

func _on_story_edit_mode():
	jump_menu.visible = false
	# Show sequence selection
	for child in jump_list.get_children():
		child.queue_free()
	var title_label := Label.new()
	title_label.text = "ストーリー編集 — シーケンス選択"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jump_list.add_child(title_label)
	for i in STORY_EDIT_SEQUENCES.size():
		var seq_entry = STORY_EDIT_SEQUENCES[i]
		var btn := Button.new()
		btn.text = seq_entry.name
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_story_edit_emit_selected.bind(i))
		jump_list.add_child(btn)
	var back_btn := Button.new()
	back_btn.text = "戻る"
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_story_edit_emit_selected.bind(-1))
	jump_list.add_child(back_btn)
	jump_menu.visible = true

	var selected: int = await _story_edit_selected
	jump_menu.visible = false
	if selected < 0:
		_show_jump_menu()
		return

	var entry = STORY_EDIT_SEQUENCES[selected]
	await _run_story_edit(entry)
	title_menu.visible = true

func _run_story_edit(entry: Dictionary):
	var sequence_id: String = entry.id

	_create_story_scene()

	# Register subevent chapters
	if entry.has("chapter") and entry.chapter == "Subevent1ChapterScript":
		if not story_script.get_sequence("subevent1_pre"):
			story_script._register_chapter(Subevent1ChapterScript.new())

	var seq = story_script.get_sequence(sequence_id)
	if not seq:
		print("[STORY_EDIT] Sequence not found: ", sequence_id)
		return

	var entries: Array = seq.entries
	if entries.is_empty():
		print("[STORY_EDIT] No entries in sequence")
		return

	# Build edit panel
	var edit_panel := _create_story_edit_panel()
	add_child(edit_panel)
	move_child(edit_panel, get_child_count() - 1)

	var idx := 0
	var auto_timer := 0.0
	var auto_interval := 2.0
	_story_edit_nav_action = ""
	_story_edit_auto_mode = false

	var prev_btn: Button = edit_panel.get_node("VBox/NavRow/PrevBtn")
	var next_btn: Button = edit_panel.get_node("VBox/NavRow/NextBtn")
	var auto_btn: Button = edit_panel.get_node("VBox/NavRow/AutoBtn")
	var side_btn: Button = edit_panel.get_node("VBox/NavRow/SideBtn")
	var save_btn: Button = edit_panel.get_node("VBox/NavRow/SaveBtn")
	var exit_btn: Button = edit_panel.get_node("VBox/NavRow/ExitBtn")
	var idx_label: Label = edit_panel.get_node("VBox/InfoRow/IdxLabel")
	var cmd_label: Label = edit_panel.get_node("VBox/InfoRow/CmdLabel")

	prev_btn.pressed.connect(_story_edit_set_nav.bind("prev"))
	next_btn.pressed.connect(_story_edit_set_nav.bind("next"))
	auto_btn.pressed.connect(_story_edit_toggle_auto.bind(auto_btn))
	side_btn.pressed.connect(_story_edit_toggle_side.bind(edit_panel))
	save_btn.pressed.connect(_story_edit_set_nav.bind("save"))
	exit_btn.pressed.connect(_story_edit_set_nav.bind("exit"))

	# Track source file for saving
	var source_file: String = ""
	if entry.has("chapter") and entry.chapter == "Subevent1ChapterScript":
		source_file = "res://story/chapters/Subevent1Chapter.gd"
	elif sequence_id == "prologue":
		source_file = "res://story/chapters/PrologueChapter.gd"
	elif sequence_id == "stage1":
		source_file = "res://story/chapters/Stage1Chapter.gd"
	_story_edit_source_file = source_file

	# Disable StoryScene input handling in edit mode
	story_scene_instance._waiting_for_input = false

	# Execute first command
	_story_edit_execute_to(entries, idx, story_scene_instance)
	_story_edit_update_info(idx_label, cmd_label, entries, idx)
	_story_edit_update_sliders(edit_panel, story_scene_instance)

	# Main edit loop
	while true:
		_story_edit_nav_action = ""

		if _story_edit_auto_mode:
			auto_timer += get_process_delta_time()
			if auto_timer >= auto_interval:
				auto_timer = 0.0
				_story_edit_nav_action = "next"

		await get_tree().process_frame

		if _story_edit_nav_action == "":
			continue

		if _story_edit_nav_action == "exit":
			break
		elif _story_edit_nav_action == "save":
			_story_edit_save_current(entries, idx, edit_panel)
		elif _story_edit_nav_action == "prev":
			if idx > 0:
				idx -= 1
				_story_edit_reset_scene(story_scene_instance)
				_story_edit_execute_to(entries, idx, story_scene_instance)
				_story_edit_update_info(idx_label, cmd_label, entries, idx)
				_story_edit_update_sliders(edit_panel, story_scene_instance)
			_story_edit_auto_mode = false
			auto_btn.text = "自動"
		elif _story_edit_nav_action == "next":
			if idx < entries.size() - 1:
				idx += 1
				var e = entries[idx]
				if e != null and not (e is StoryCommands.Battle):
					_story_edit_execute_single(e, story_scene_instance)
				_story_edit_update_info(idx_label, cmd_label, entries, idx)
				_story_edit_update_sliders(edit_panel, story_scene_instance)
			else:
				_story_edit_auto_mode = false
				auto_btn.text = "自動"

	edit_panel.queue_free()
	if story_scene_instance:
		story_scene_instance.queue_free()
		story_scene_instance = null

func _story_edit_emit_selected(index: int):
	_story_edit_selected.emit(index)

func _story_edit_toggle_side(edit_panel: PanelContainer):
	if not story_scene_instance:
		return
	# Collect visible character rects
	var visible_rects: Array = []
	for side in ["left", "right", "center"]:
		var rect: TextureRect = story_scene_instance.get(side + "_char")
		if rect and rect.visible and rect.texture:
			visible_rects.append(rect)
	if visible_rects.is_empty():
		return
	# Find current index and cycle to next
	var current_idx := visible_rects.find(_story_edit_slider_target)
	var next_idx := (current_idx + 1) % visible_rects.size()
	_story_edit_slider_target = visible_rects[next_idx]
	# Update sliders to match new target
	_story_edit_update_sliders(edit_panel, story_scene_instance)

func _story_edit_set_nav(action: String):
	_story_edit_nav_action = action

func _story_edit_toggle_auto(auto_btn: Button):
	_story_edit_auto_mode = not _story_edit_auto_mode
	auto_btn.text = "停止" if _story_edit_auto_mode else "自動"

func _story_edit_execute_single(e, scene):
	# Execute a single command with animations disabled
	if e is StoryCommands.ShowCharacter:
		var saved_effect: String = e.appear_effect
		var saved_duration: float = e.appear_duration
		var saved_transition: String = e.transition
		var saved_transition_dur: float = e.transition_duration
		e.appear_effect = ""
		e.appear_duration = 0.0
		e.transition = ""
		e.transition_duration = 0.0
		e.execute(scene)
		e.appear_effect = saved_effect
		e.appear_duration = saved_duration
		e.transition = saved_transition
		e.transition_duration = saved_transition_dur
	elif e is StoryCommands.HideCharacter:
		var saved_effect: String = e.exit_effect
		var saved_duration: float = e.exit_duration
		e.exit_effect = ""
		e.exit_duration = 0.0
		e.execute(scene)
		e.exit_effect = saved_effect
		e.exit_duration = saved_duration
	else:
		e.execute(scene)
	scene._waiting_for_input = false

func _story_edit_execute_to(entries: Array, target_idx: int, scene):
	for i in range(target_idx + 1):
		var e = entries[i]
		if e == null:
			continue
		if e is StoryCommands.Battle:
			continue
		_story_edit_execute_single(e, scene)

func _story_edit_reset_scene(scene):
	# Reset character visibility
	scene.left_char.visible = false
	scene.center_char.visible = false
	scene.right_char.visible = false
	scene.dialogue_band.visible = false
	scene._character_side_cache.clear()

func _story_edit_update_info(idx_label: Label, cmd_label: Label, entries: Array, idx: int):
	idx_label.text = "%d / %d" % [idx + 1, entries.size()]
	var e = entries[idx]
	if e == null:
		cmd_label.text = "(null)"
	elif e is StoryCommands.Band:
		var speaker: String = e.speaker_id if not e.speaker_id.is_empty() else "narrator"
		var text_preview: String = e.text.substr(0, 30).replace("\n", " ")
		cmd_label.text = "Band [%s]: %s..." % [speaker, text_preview]
	elif e is StoryCommands.ShowCharacter:
		cmd_label.text = "Show [%s] side=%s" % [e.character_id, e.side_override]
	elif e is StoryCommands.HideCharacter:
		cmd_label.text = "Hide [%s]" % e.character_id
	elif e is StoryCommands.Background:
		cmd_label.text = "BG: %s" % e.path.get_file()
	elif e is StoryCommands.SeqLabel:
		cmd_label.text = "Label: %s" % e.label_name
	elif e is StoryCommands.Battle:
		cmd_label.text = "Battle: %s" % e.chapter_path.get_file()
	elif e is StoryCommands.HideDialogue:
		cmd_label.text = "HideDialogue"
	else:
		cmd_label.text = "(other)"

var _story_edit_slider_target: TextureRect = null
var _story_edit_nav_action := ""
var _story_edit_auto_mode := false
var _story_edit_source_file := ""

func _story_edit_update_sliders(edit_panel: PanelContainer, scene):
	var sl := _get_edit_sliders(edit_panel)
	if sl.is_empty():
		return

	# Keep current target if still visible, otherwise find a visible one
	var target_rect: TextureRect = null
	var char_label: Label = edit_panel.find_child("CharLabel", true, false)
	if _story_edit_slider_target and is_instance_valid(_story_edit_slider_target) and _story_edit_slider_target.visible and _story_edit_slider_target.texture:
		target_rect = _story_edit_slider_target
	else:
		for side in ["left", "right", "center"]:
			var rect: TextureRect = scene.get(side + "_char")
			if rect and rect.visible and rect.texture:
				target_rect = rect

	# Update target reference
	_story_edit_slider_target = target_rect

	if target_rect and target_rect.texture:
		var current_scale := target_rect.scale.x
		var current_pos := target_rect.position
		# Reverse-calculate offset from base position (side-aware)
		var base_pos: Vector2 = _story_edit_get_base_pos(target_rect, current_scale)
		var offset_x: float = current_pos.x - base_pos.x
		var offset_y: float = current_pos.y - base_pos.y
		# Update slider values
		sl.scale.value = current_scale
		if sl.scale_spin: sl.scale_spin.value = current_scale
		sl.x.value = offset_x
		if sl.x_spin: sl.x_spin.value = offset_x
		sl.y.value = offset_y
		if sl.y_spin: sl.y_spin.value = offset_y
		if char_label:
			if target_rect == scene.left_char:
				char_label.text = "LEFT"
			elif target_rect == scene.right_char:
				char_label.text = "RIGHT"
			elif target_rect == scene.center_char:
				char_label.text = "CENTER"
	elif char_label:
		char_label.text = "(none)"

func _create_story_edit_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -200
	panel.offset_bottom = 0

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Navigation row
	var nav_row := HBoxContainer.new()
	nav_row.name = "NavRow"
	nav_row.add_theme_constant_override("separation", 8)
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(nav_row)

	var prev_btn := Button.new()
	prev_btn.name = "PrevBtn"
	prev_btn.text = "◀ 前へ"
	prev_btn.add_theme_font_size_override("font_size", 16)
	nav_row.add_child(prev_btn)

	var next_btn := Button.new()
	next_btn.name = "NextBtn"
	next_btn.text = "次へ ▶"
	next_btn.add_theme_font_size_override("font_size", 16)
	nav_row.add_child(next_btn)

	var auto_btn := Button.new()
	auto_btn.name = "AutoBtn"
	auto_btn.text = "自動"
	auto_btn.add_theme_font_size_override("font_size", 16)
	nav_row.add_child(auto_btn)

	var side_btn := Button.new()
	side_btn.name = "SideBtn"
	side_btn.text = "L/R"
	side_btn.add_theme_font_size_override("font_size", 16)
	side_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5))
	nav_row.add_child(side_btn)

	var save_btn := Button.new()
	save_btn.name = "SaveBtn"
	save_btn.text = "決定"
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	nav_row.add_child(save_btn)

	var exit_btn := Button.new()
	exit_btn.name = "ExitBtn"
	exit_btn.text = "終了"
	exit_btn.add_theme_font_size_override("font_size", 16)
	exit_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	nav_row.add_child(exit_btn)

	# Info row
	var info_row := HBoxContainer.new()
	info_row.name = "InfoRow"
	info_row.add_theme_constant_override("separation", 12)
	vbox.add_child(info_row)

	var idx_label := Label.new()
	idx_label.name = "IdxLabel"
	idx_label.text = "0 / 0"
	idx_label.add_theme_font_size_override("font_size", 14)
	idx_label.custom_minimum_size = Vector2(80, 0)
	info_row.add_child(idx_label)

	var cmd_label := Label.new()
	cmd_label.name = "CmdLabel"
	cmd_label.text = ""
	cmd_label.add_theme_font_size_override("font_size", 14)
	cmd_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cmd_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_row.add_child(cmd_label)

	var char_label := Label.new()
	char_label.name = "CharLabel"
	char_label.text = ""
	char_label.add_theme_font_size_override("font_size", 14)
	char_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	info_row.add_child(char_label)

	# Sliders (reuse existing pattern)
	var scale_row := _create_slider_row("スケール", "ScaleSlider", 0.1, 2.0, 0.01, 0.5, "%.2f")
	vbox.add_child(scale_row)
	var x_row := _create_slider_row("X", "XSlider", -500, 500, 1, 0, "%d")
	vbox.add_child(x_row)
	var y_row := _create_slider_row("Y", "YSlider", -800, 400, 1, 0, "%d")
	vbox.add_child(y_row)

	# Connect sliders to story edit handler
	var scale_slider: HSlider = scale_row.get_node("ScaleSlider")
	var x_slider: HSlider = x_row.get_node("XSlider")
	var y_slider: HSlider = y_row.get_node("YSlider")
	scale_slider.value_changed.connect(_on_story_edit_slider.bind(panel))
	x_slider.value_changed.connect(_on_story_edit_slider.bind(panel))
	y_slider.value_changed.connect(_on_story_edit_slider.bind(panel))

	return panel

func _story_edit_get_base_pos(target: TextureRect, s: float) -> Vector2:
	# Calculate base position the same way StoryScene._reset_rect_with_scale does
	if not story_scene_instance or not target or not target.texture:
		return Vector2.ZERO
	var tex_size: Vector2 = target.texture.get_size()
	var vp_size: Vector2 = get_viewport_rect().size
	var visual_w: float = tex_size.x * s
	var visual_h: float = tex_size.y * s
	var base_x: float
	if target == story_scene_instance.left_char:
		base_x = 100.0  # _CHAR_MARGIN
	elif target == story_scene_instance.right_char:
		base_x = vp_size.x - visual_w - 100.0
	else:  # center
		base_x = (vp_size.x - visual_w) / 2.0
	return Vector2(base_x, vp_size.y - visual_h)

func _on_story_edit_slider(_value: float, panel: PanelContainer):
	if not _story_edit_slider_target or not is_instance_valid(_story_edit_slider_target):
		return
	if not _story_edit_slider_target.texture:
		return
	var sl := _get_edit_sliders(panel)
	if sl.is_empty():
		return
	var s: float = sl.scale.value
	var tex_size: Vector2 = _story_edit_slider_target.texture.get_size()
	_story_edit_slider_target.size = tex_size
	_story_edit_slider_target.scale = Vector2(s, s)
	var base_pos: Vector2 = _story_edit_get_base_pos(_story_edit_slider_target, s)
	var new_pos := Vector2(base_pos.x + sl.x.value, base_pos.y + sl.y.value)
	_story_edit_slider_target.position = new_pos
	# Update position lock so _process doesn't revert
	if story_scene_instance and story_scene_instance._char_locked_positions.has(_story_edit_slider_target):
		story_scene_instance._char_locked_positions[_story_edit_slider_target] = new_pos
	var output := '"scale": %.2f, "position": [%d, %d]' % [s, int(sl.x.value), int(sl.y.value)]
	print("[STORY_EDIT] %s" % output)

func _story_edit_save_current(entries: Array, idx: int, edit_panel: PanelContainer):
	var e = entries[idx]
	if not (e is StoryCommands.ShowCharacter):
		print("[STORY_EDIT] Current command is not ShowCharacter, cannot save")
		return
	if _story_edit_source_file.is_empty():
		print("[STORY_EDIT] No source file set")
		return

	var sl := _get_edit_sliders(edit_panel)
	if sl.is_empty():
		return

	var new_scale: float = sl.scale.value
	var new_x: int = int(sl.x.value)
	var new_y: int = int(sl.y.value)

	# 1. Update command object (session)
	e.portrait_scale = new_scale
	e.position = Vector2(new_x, new_y)
	e.position_mode = "offset"

	# 2. Save to file
	var portrait_id: String = e.portrait_id
	if portrait_id.is_empty():
		print("[STORY_EDIT] No portrait_id on command, cannot find line in source")
		return

	# Find the line in source file that contains this portrait path
	var abs_path: String = ProjectSettings.globalize_path(_story_edit_source_file)
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if not file:
		print("[STORY_EDIT] Cannot open file: %s" % abs_path)
		return
	var lines: PackedStringArray = file.get_as_text().split("\n")
	file.close()

	# Search for the line with this portrait
	var portrait_filename: String = portrait_id.get_file()
	var found_line := -1
	for i in range(lines.size()):
		if portrait_filename in lines[i] and ("set_portrait" in lines[i] or "portrait" in lines[i]):
			# Check if this is a set_portrait or appear with this portrait
			if '"scale"' in lines[i] or '"portrait_scale"' in lines[i]:
				found_line = i
				# Don't break — we want the last match up to current command
				# Actually we need to match the right occurrence

	# Better approach: find all lines with this portrait and pick by order
	var matches: Array = []
	for i in range(lines.size()):
		if portrait_filename in lines[i] and '"scale"' in lines[i]:
			matches.append(i)

	if matches.is_empty():
		print("[STORY_EDIT] Could not find line with portrait: %s" % portrait_filename)
		return

	# Count how many ShowCharacter commands before idx use this portrait
	var occurrence := 0
	for i in range(idx + 1):
		var cmd = entries[i]
		if cmd is StoryCommands.ShowCharacter and cmd.portrait_id.get_file() == portrait_filename:
			if i == idx:
				break
			occurrence += 1

	if occurrence >= matches.size():
		occurrence = matches.size() - 1
	found_line = matches[occurrence]

	# Replace scale and position in the line
	var line: String = lines[found_line]
	var regex_scale := RegEx.new()
	regex_scale.compile('"scale":\\s*[\\d.]+')
	line = regex_scale.sub(line, '"scale": %.2f' % new_scale)

	var regex_pos := RegEx.new()
	regex_pos.compile('"position":\\s*\\[[^\\]]*\\]')
	line = regex_pos.sub(line, '"position": [%d, %d]' % [new_x, new_y])

	lines[found_line] = line

	# Write back
	var write_file := FileAccess.open(abs_path, FileAccess.WRITE)
	if not write_file:
		print("[STORY_EDIT] Cannot write file: %s" % abs_path)
		return
	write_file.store_string("\n".join(lines))
	write_file.close()

	print("[STORY_EDIT] SAVED line %d: %s" % [found_line + 1, portrait_filename])
	print('[STORY_EDIT]   "scale": %.2f, "position": [%d, %d]' % [new_scale, new_x, new_y])

# --- イベントバトル編集モード ---

const EVENT_BATTLE_CHAPTERS := [
	{"id": "prologue", "name": "プロローグ（マチルダ戦）", "path": "res://battle/chapters/PrologueBattleChapter.gd", "bg": "res://assets/backgrounds/prologue/bg05_prison_cell.png"},
	{"id": "stage1", "name": "ステージ1（冒険者A戦）", "path": "res://battle/chapters/Stage1BattleChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_guild_hall.png"},
	{"id": "stage2", "name": "ステージ2（受付嬢戦）", "path": "res://battle/chapters/ReceptionistBattleChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_guild_hall.png"},
	{"id": "subevent1_boss", "name": "サブイベント1（ベルカ戦）", "path": "res://battle/chapters/Stage2BattleChapter.gd", "bg": "res://assets/backgrounds/prologue/bg06_prison_arena.png"},
]

signal _event_chapter_selected(index: int)

func _on_event_battle_edit_mode():
	jump_menu.visible = false
	await _show_event_chapter_select()

func _show_event_chapter_select():
	for child in jump_list.get_children():
		child.queue_free()
	var back_btn := Button.new()
	back_btn.text = "← 戻る"
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(func():
		jump_menu.visible = false
		title_menu.visible = true)
	jump_list.add_child(back_btn)
	var sep := HSeparator.new()
	jump_list.add_child(sep)

	for i in range(EVENT_BATTLE_CHAPTERS.size()):
		var ch_info: Dictionary = EVENT_BATTLE_CHAPTERS[i]
		var btn := Button.new()
		btn.text = ch_info.name
		btn.add_theme_font_size_override("font_size", 20)
		var idx: int = i
		btn.pressed.connect(func(): _event_chapter_selected.emit(idx))
		jump_list.add_child(btn)
	jump_menu.visible = true

	while true:
		var selected_idx: int = await _event_chapter_selected
		jump_menu.visible = false
		await _run_event_battle_edit(EVENT_BATTLE_CHAPTERS[selected_idx])
		# チャプター選択に戻る
		for child2 in jump_list.get_children():
			child2.queue_free()
		var back_btn2 := Button.new()
		back_btn2.text = "← 戻る"
		back_btn2.add_theme_font_size_override("font_size", 20)
		back_btn2.pressed.connect(func():
			jump_menu.visible = false
			title_menu.visible = true)
		jump_list.add_child(back_btn2)
		var sep2 := HSeparator.new()
		jump_list.add_child(sep2)
		for i2 in range(EVENT_BATTLE_CHAPTERS.size()):
			var ch_info2: Dictionary = EVENT_BATTLE_CHAPTERS[i2]
			var btn2 := Button.new()
			btn2.text = ch_info2.name
			btn2.add_theme_font_size_override("font_size", 20)
			var idx2: int = i2
			btn2.pressed.connect(func(): _event_chapter_selected.emit(idx2))
			jump_list.add_child(btn2)
		jump_menu.visible = true

func _run_event_battle_edit(ch_info: Dictionary):
	GameState.reset()
	GameState.init_default_inventory()
	GameState.money = 1000

	var script_res = load(ch_info.path)
	if not script_res:
		return
	var chapter = script_res.new()
	var bg_tex = load(ch_info.bg) if not ch_info.bg.is_empty() else null

	# スライダーパネル作成
	var edit_panel := _create_edit_overlay({"name": ch_info.name})
	add_child(edit_panel)

	# バトル開始
	var event_battle = battle_scene_scene.instantiate()
	add_child(event_battle)
	event_battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not story_script:
		story_script = DefaultStoryScript.new()
	event_battle.setup(story_script.get_cast(), bg_tex, GameState.inventory)
	event_battle.force_result_mode = true
	event_battle.start_battle(chapter)
	move_child(edit_panel, get_child_count() - 1)
	_connect_edit_to_battle(edit_panel, event_battle, {})

	var result: String = await event_battle.battle_finished
	_battle_edit_active = false
	event_battle.queue_free()
	edit_panel.queue_free()
