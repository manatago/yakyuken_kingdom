extends Control
class_name GuildHome

signal home_action(action: String)
signal battle_encounter(area_id: String, chapter: BattleChapterBase)

@onready var bg_rect := $Background
@onready var menu_bar := $MenuBar
@onready var encounter_portrait := $EncounterPortrait
@onready var narration_band := $NarrationBand
@onready var narration_label := $NarrationBand/NarrationLabel
@onready var nav_row := $NarrationBand/NavRow
@onready var encounter_buttons := $NarrationBand/EncounterButtons
@onready var encounter_speaker := $NarrationBand/EncounterSpeaker
@onready var encounter_right := $NarrationBand/EncounterRight
@onready var encounter_body := $NarrationBand/EncounterRight/BodyLabel

var _town_map: TownMapBase = null
var _areas: Dictionary = {}
var _current_area: String = ""
var _is_in_town := false
var _home_bg_path: String = ""
var _active_modal: Control = null

signal _encounter_choice(accepted: bool)

func _ready():
	narration_band.visible = false
	for btn in menu_bar.get_children():
		if btn is Button:
			btn.pressed.connect(_on_menu_pressed.bind(btn.name))

func setup(bg_texture: Texture2D = null, town_map: TownMapBase = null):
	if bg_texture:
		bg_rect.texture = bg_texture
	if town_map:
		_town_map = town_map
		_areas = town_map.get_areas()
		_home_bg_path = town_map.get_home_background()

func _on_menu_pressed(action: String):
	match action:
		"QuestButton":
			_show_simple_modal("クエストボード", "依頼を選択してバトルに挑もう。\n（準備中）")
		"CardButton":
			_show_card_modal()
		"ItemButton":
			_show_item_modal()
		"EquipButton":
			_show_equip_modal()
		"ShopButton":
			_show_simple_modal("ショップ", "カードやアイテムを売買できます。\n（準備中）")
		"StatusButton":
			_show_simple_modal("ステータス", "冒険者情報・勝敗記録を確認できます。\n（準備中）")
		"TownButton":
			_show_town_modal()
		"StoryButton":
			home_action.emit("next_story")
		"ExitButton":
			home_action.emit("exit")

# --- モーダル共通 ---

func _close_modal():
	if _active_modal and is_instance_valid(_active_modal):
		_active_modal.queue_free()
		_active_modal = null

func _create_modal_base() -> PanelContainer:
	_close_modal()
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.85)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	# 画面中央に配置
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	_active_modal = panel
	return panel

# --- シンプルモーダル（準備中表示） ---

func _show_simple_modal(title: String, body: String):
	var panel := _create_modal_base()
	panel.custom_minimum_size = Vector2(400, 250)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var body_label := Label.new()
	body_label.text = body
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(body_label)

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_close_modal)
	vbox.add_child(close_btn)

# --- カード一覧モーダル ---

func _show_card_modal():
	var panel := _create_modal_base()
	panel.custom_minimum_size = Vector2(500, 400)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "手持ちカード（%d枚）" % GameState.inventory.size()
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	if GameState.inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "カードがありません"
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_label)
	else:
		var card_counts := {}
		for card: Card in GameState.inventory:
			var key := "%s_%d" % [card.hand, card.grade]
			card_counts[key] = card_counts.get(key, 0) + 1

		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 280)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(scroll)

		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 4)
		scroll.add_child(list)

		var sorted_keys := card_counts.keys()
		sorted_keys.sort()
		for key in sorted_keys:
			var parts: PackedStringArray = key.split("_")
			var hand: String = parts[0]
			var grade: int = int(parts[1])
			var count: int = card_counts[key]
			list.add_child(GameState.create_card_label(hand, grade, count, 20, 28))

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_close_modal)
	vbox.add_child(close_btn)

# --- アイテム一覧モーダル ---

func _show_item_modal():
	var panel := _create_modal_base()
	panel.custom_minimum_size = Vector2(500, 400)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "アイテム"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# ゴールド表示
	vbox.add_child(GameState.create_gold_label(GameState.money, 22, 28, "所持金: "))

	if GameState.items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "アイテムがありません"
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_label)
	else:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 280)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(scroll)

		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 4)
		scroll.add_child(list)

		for item in GameState.items:
			list.add_child(GameState.create_item_label(item.get("name", item.id), item.get("count", 1), 20, 28))

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_close_modal)
	vbox.add_child(close_btn)

# --- 装備モーダル ---

func _show_equip_modal():
	var panel := _create_modal_base()
	panel.custom_minimum_size = Vector2(500, 400)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "装備"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	if GameState.equipment.is_empty():
		var empty_label := Label.new()
		empty_label.text = "装備品がありません"
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_label)
	else:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 280)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(scroll)
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 4)
		scroll.add_child(list)
		for item in GameState.equipment:
			list.add_child(GameState.create_item_label(item.get("name", item.id), 1, 20, 28))

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_close_modal)
	vbox.add_child(close_btn)

# --- 街に出るモーダル ---

func _show_town_modal():
	if not _town_map:
		_show_simple_modal("街に出る", "街のデータがありません。")
		return

	var panel := _create_modal_base()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "どこに行く？"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	vbox.add_child(grid)

	var connections: Array = _town_map.get_home_connections()
	for area_id in connections:
		var area: Dictionary = _areas.get(area_id, {})
		if area.is_empty():
			continue
		var btn := _create_thumbnail_button(area.name, area.get("bg", ""))
		btn.pressed.connect(func():
			_close_modal()
			_on_navigate(area_id)
		)
		grid.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.pressed.connect(_close_modal)
	vbox.add_child(close_btn)

	_is_in_town = true

func _create_thumbnail_button(text: String, bg_path: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 150)
	btn.add_theme_font_size_override("font_size", 18)
	btn.text = text

	if not bg_path.is_empty():
		var tex = load(bg_path)
		if tex:
			btn.icon = tex
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			btn.expand_icon = true

	return btn

# --- エリアナビゲーション（バンド表示） ---

func _on_navigate(destination_id: String):
	var dest_area: Dictionary = _areas.get(destination_id, {})
	if dest_area.is_empty():
		return
	_show_area(destination_id)

var _waiting_for_click := false

func _show_area(area_id: String, skip_encounter := false):
	_current_area = area_id
	var area: Dictionary = _areas.get(area_id, {})
	if area.is_empty():
		return

	# 背景変更
	var tex = load(area.bg)
	if tex:
		bg_rect.texture = tex

	# バンド: 説明文のみ表示（ボタンなし）
	narration_label.text = area.get("description", "")
	_clear_nav_row()
	menu_bar.visible = false
	narration_band.visible = true

	# エンカウント判定（到着直後、クリック待ちの前に決める）
	var encounter: Dictionary = {}
	if not skip_encounter:
		encounter = _roll_encounter(area_id)

	if not encounter.is_empty():
		# エンカウント発生 → クリック/エンターで遭遇演出へ
		await _wait_for_click()
		var accepted: bool = await _show_encounter(encounter)
		if accepted:
			var chapter := RandomBattleChapter.new()
			encounter["battle_bg"] = area.get("bg", "")
			chapter.setup_from_encounter(encounter)
			battle_encounter.emit(area_id, chapter)
			return
	else:
		# エンカウントなし → そのまま行き先ボタン表示
		pass

	_show_nav_buttons(area_id)

func _wait_for_click():
	_waiting_for_click = true
	await _click_received
	_waiting_for_click = false

signal _click_received

func _input(event: InputEvent):
	if not _waiting_for_click:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# スライダーやボタン上のクリックは無視
		var hovered = get_viewport().gui_get_hovered_control()
		if hovered is BaseButton or hovered is Slider or hovered is SpinBox or hovered is LineEdit:
			return
		# 編集パネル内のクリックも無視
		if hovered and _is_in_edit_panel(hovered):
			return
		_click_received.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_click_received.emit()

func _is_in_edit_panel(control: Control) -> bool:
	var node = control
	while node:
		if node is PanelContainer:
			return true
		node = node.get_parent()
	return false

func _show_nav_buttons(area_id: String):
	_clear_nav_row()
	var area: Dictionary = _areas.get(area_id, {})
	var connections: Array = area.get("connections", [])
	for conn_id in connections:
		if conn_id == "guild_home":
			_add_band_button("ギルドに戻る", _on_return_guild)
		else:
			var conn_area: Dictionary = _areas.get(conn_id, {})
			if conn_area.is_empty():
				continue
			_add_band_button(conn_area.name, _on_navigate.bind(conn_id))

func arrive_at(area_id: String):
	_close_modal()
	_show_area(area_id, true)

func _on_return_guild():
	_is_in_town = false
	_current_area = ""
	if not _home_bg_path.is_empty():
		var tex = load(_home_bg_path)
		if tex:
			bg_rect.texture = tex
	narration_band.visible = false
	menu_bar.visible = true

# --- バンドボタン ---

func _clear_nav_row():
	for child in nav_row.get_children():
		child.queue_free()

func _add_band_button(text: String, callback: Callable):
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 18)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.18, 0.28, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.3, 0.25, 0.4, 0.9)
	btn.add_theme_stylebox_override("hover", hover)
	btn.pressed.connect(callback)
	nav_row.add_child(btn)

# --- ランダムエンカウント ---

func _roll_encounter(area_id: String) -> Dictionary:
	if not _town_map:
		return {}
	var area: Dictionary = _areas.get(area_id, {})
	var battle_rate: float = area.get("battle_rate", 0.0)
	if randf() > battle_rate:
		return {}
	# エンカウント発生 → 出現キャラ抽選
	var encounters: Array = _town_map.get_encounters(area_id)
	if encounters.is_empty():
		return {}
	return _weighted_pick(encounters)

func _weighted_pick(encounters: Array) -> Dictionary:
	var total_weight := 0.0
	for e in encounters:
		total_weight += e.get("weight", 1.0)
	var roll := randf() * total_weight
	var cumulative := 0.0
	for e in encounters:
		cumulative += e.get("weight", 1.0)
		if roll <= cumulative:
			return e
	return encounters.back()

func _show_encounter(encounter: Dictionary) -> bool:
	# キャラ画像表示（side + scale + position 方式）
	var portrait_data: Dictionary = EncounterDatabase.get_portrait(encounter, "encounter")
	var portrait_path: String = portrait_data.get("path", "")
	if not portrait_path.is_empty():
		var tex = load(portrait_path)
		if tex:
			encounter_portrait.texture = tex
			_apply_encounter_portrait(tex, portrait_data)
	encounter_portrait.visible = true

	# バンド内: 通常要素を隠してエンカウントUIに切替
	narration_label.visible = false
	nav_row.visible = false

	# バンド右側: 話者名（吹き出しの上）+ 吹き出し（セリフ）
	encounter_speaker.text = encounter.get("name", "")
	encounter_speaker.visible = true
	encounter_body.text = EncounterDatabase.pick_line(encounter, "greetings")
	encounter_right.visible = true

	# バンド左側: 選択ボタン
	for child in encounter_buttons.get_children():
		child.queue_free()
	var accept_btn := Button.new()
	accept_btn.text = "受けて立つ"
	accept_btn.add_theme_font_size_override("font_size", 18)
	_style_encounter_button(accept_btn, Color(0.3, 0.15, 0.1, 0.9), Color(0.7, 0.4, 0.2, 0.8))
	accept_btn.pressed.connect(func(): _encounter_choice.emit(true))
	encounter_buttons.add_child(accept_btn)
	var flee_btn := Button.new()
	flee_btn.text = "逃げる"
	flee_btn.add_theme_font_size_override("font_size", 18)
	_style_encounter_button(flee_btn, Color(0.15, 0.15, 0.25, 0.9), Color(0.4, 0.4, 0.6, 0.8))
	flee_btn.pressed.connect(func(): _encounter_choice.emit(false))
	encounter_buttons.add_child(flee_btn)
	encounter_buttons.visible = true

	var accepted: bool = await _encounter_choice
	_hide_encounter()
	return accepted

func _apply_encounter_portrait(tex: Texture2D, portrait_data: Dictionary):
	var s: float = portrait_data.get("scale", 0.5)
	var side: String = portrait_data.get("side", "center")
	var pos = portrait_data.get("position", [0, 0])
	var offset_x: float = pos[0] if pos is Array and pos.size() >= 2 else 0.0
	var offset_y: float = pos[1] if pos is Array and pos.size() >= 2 else 0.0

	# アンカーを無効化してピクセル配置
	encounter_portrait.set_anchors_preset(Control.PRESET_TOP_LEFT)
	encounter_portrait.size = tex.get_size()
	encounter_portrait.scale = Vector2(s, s)

	var vp_size: Vector2 = get_viewport_rect().size
	var visual_w: float = tex.get_size().x * s
	var visual_h: float = tex.get_size().y * s

	match side:
		"left":
			encounter_portrait.position.x = 40.0 + offset_x
		"right":
			encounter_portrait.position.x = vp_size.x - visual_w - 40.0 + offset_x
		_:  # center
			encounter_portrait.position.x = (vp_size.x - visual_w) / 2.0 + offset_x
	encounter_portrait.position.y = vp_size.y - visual_h + offset_y

func _hide_encounter():
	encounter_portrait.visible = false
	encounter_speaker.visible = false
	encounter_right.visible = false
	encounter_buttons.visible = false
	narration_label.visible = true
	nav_row.visible = true

func _style_encounter_button(btn: Button, bg_color: Color, border_color: Color):
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = bg_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
