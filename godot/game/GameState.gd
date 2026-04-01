extends Node

# =============================================================
# GameState — ゲーム全体の状態を一元管理するシングルトン (autoload)
# =============================================================

const GOLD_ICON_PATH := "res://assets/ui/icons/gold.png"
const DEFAULT_ITEM_ICON_PATH := "res://assets/ui/icons/gold.png"  # アイテムアイコン仮
const CARD_ICON_PATHS := {
	"rock": "res://assets/battle/cards/rock.png",
	"scissors": "res://assets/battle/cards/scissors.png",
	"paper": "res://assets/battle/cards/paper.png",
}
const HAND_NAMES := {"rock": "グー", "scissors": "チョキ", "paper": "パー"}
const GRADE_NAMES := {1: "ノーマル", 2: "ブロンズ", 3: "シルバー", 4: "ゴールド", 5: "プラチナ"}
const GRADE_COLORS := {
	1: Color(1.0, 1.0, 1.0),
	2: Color(0.8, 0.5, 0.2),
	3: Color(0.75, 0.75, 0.8),
	4: Color(1.0, 0.84, 0.0),
	5: Color(0.6, 0.9, 1.0),
}

# アイコン + テキストの行を生成する汎用ヘルパー
static func _create_icon_row(icon_path: String, text: String, font_size: int = 18, icon_size: int = 24, font_color: Color = Color.WHITE, modulate_color: Color = Color.WHITE) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	var icon := TextureRect.new()
	var tex = load(icon_path)
	if tex:
		icon.texture = tex
		icon.expand_mode = 1
		icon.stretch_mode = 5
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.modulate = modulate_color
	hbox.add_child(icon)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_color)
	hbox.add_child(lbl)
	return hbox

# ゴールド表示
static func create_gold_label(amount: int, font_size: int = 20, icon_size: int = 28, prefix: String = "") -> HBoxContainer:
	return _create_icon_row(GOLD_ICON_PATH, "%s%d" % [prefix, amount], font_size, icon_size, Color(0.9, 0.75, 0.3))

# カード表示
static func create_card_label(hand: String, grade: int, count: int = 1, font_size: int = 18, icon_size: int = 24) -> HBoxContainer:
	var icon_path: String = CARD_ICON_PATHS.get(hand, CARD_ICON_PATHS["rock"])
	var hand_name: String = HAND_NAMES.get(hand, hand)
	var grade_name: String = GRADE_NAMES.get(grade, "G%d" % grade)
	var grade_color: Color = GRADE_COLORS.get(grade, Color.WHITE)
	var text: String = "%s（%s）" % [hand_name, grade_name]
	if count > 1:
		text += " × %d" % count
	return _create_icon_row(icon_path, text, font_size, icon_size, Color.WHITE, grade_color)

# アイテム表示（仮アイコン）
static func create_item_label(item_name: String, count: int = 1, font_size: int = 18, icon_size: int = 24) -> HBoxContainer:
	var text: String = item_name
	if count > 1:
		text += " × %d" % count
	return _create_icon_row(DEFAULT_ITEM_ICON_PATH, text, font_size, icon_size)

# --- プレイヤーデータ ---
var inventory: Array[Card] = []  # 手持ちカード
var items: Array = []            # [{"id": "potion", "name": "勝率の薬", "count": 1}, ...]
var equipment: Array = []        # [{"id": "greed_ring", "name": "強欲の指輪", "effect": "..."}, ...]
var money: int = 0
var flags: Dictionary = {}       # {"guild_registered": true, ...}

# --- ストーリー進行 ---
var chapter: String = ""     # "prologue", "stage1"
var label: String = ""       # 現在のラベル
var scenario_index: int = 0

# --- 画面状態 ---
var background: String = ""
var band_color: String = "royal_blue"
var characters_on_screen: Dictionary = {}

# --- 街 ---
var current_area: String = ""
var town_map_id: String = ""

# --- バトル ---
var last_battle_result: String = ""

# =============================================================
# 状態の一括セット / 取得
# =============================================================

func apply(data: Dictionary) -> void:
	inventory.clear()
	for card_data in data.get("inventory", []):
		inventory.append(Card.from_dict(card_data))
	items = data.get("items", []).duplicate(true)
	equipment = data.get("equipment", []).duplicate(true)
	money = data.get("money", 0)
	flags = data.get("flags", {}).duplicate(true)
	chapter = data.get("chapter", "")
	label = data.get("label", "")
	scenario_index = data.get("scenario_index", 0)
	background = data.get("background", "")
	band_color = data.get("band_color", "royal_blue")
	characters_on_screen = data.get("characters_on_screen", {}).duplicate(true)
	current_area = data.get("current_area", "")
	town_map_id = data.get("town_map_id", "")
	last_battle_result = data.get("last_battle_result", "")

func to_dict() -> Dictionary:
	var inv_array: Array = []
	for card in inventory:
		inv_array.append(card.to_dict())
	return {
		"inventory": inv_array,
		"items": items.duplicate(true),
		"equipment": equipment.duplicate(true),
		"money": money,
		"flags": flags.duplicate(true),
		"chapter": chapter,
		"label": label,
		"scenario_index": scenario_index,
		"background": background,
		"band_color": band_color,
		"characters_on_screen": characters_on_screen.duplicate(true),
		"current_area": current_area,
		"town_map_id": town_map_id,
		"last_battle_result": last_battle_result,
	}

# =============================================================
# 初期化
# =============================================================

func reset() -> void:
	inventory.clear()
	items.clear()
	equipment.clear()
	money = 0
	flags.clear()
	chapter = ""
	label = ""
	scenario_index = 0
	background = ""
	band_color = "royal_blue"
	characters_on_screen.clear()
	current_area = ""
	town_map_id = ""
	last_battle_result = ""

func init_default_inventory() -> void:
	if inventory.is_empty():
		for hand_key in ["rock", "scissors", "paper"]:
			for i in range(3):
				inventory.append(Card.new(hand_key, 1))

# =============================================================
# インベントリ操作
# =============================================================

func add_card(card) -> void:
	if card is Card:
		inventory.append(card.duplicate_card())
	elif card is Dictionary:
		inventory.append(Card.from_dict(card))

func remove_card(card) -> void:
	var h: String = card.hand if card is Card else card.get("hand", "")
	var g: int = card.grade if card is Card else int(card.get("grade", 1))
	for i in range(inventory.size()):
		if inventory[i].hand == h and inventory[i].grade == g:
			inventory.remove_at(i)
			return

# =============================================================
# アイテム操作
# =============================================================

func add_item(item: Dictionary) -> void:
	for existing in items:
		if existing.id == item.id:
			existing.count = existing.get("count", 1) + item.get("count", 1)
			return
	items.append(item.duplicate())

func remove_item(item_id: String, count: int = 1) -> bool:
	for i in range(items.size()):
		if items[i].id == item_id:
			items[i].count = items[i].get("count", 1) - count
			if items[i].count <= 0:
				items.remove_at(i)
			return true
	return false

func get_item_count(item_id: String) -> int:
	for item in items:
		if item.id == item_id:
			return item.get("count", 1)
	return 0

# =============================================================
# 装備操作
# =============================================================

func equip(item_id: String) -> bool:
	# アイテム一覧から装備に移動
	for i in range(items.size()):
		if items[i].id == item_id:
			var item: Dictionary = items[i].duplicate()
			item.count = 1
			equipment.append(item)
			remove_item(item_id, 1)
			return true
	return false

func unequip(item_id: String) -> bool:
	for i in range(equipment.size()):
		if equipment[i].id == item_id:
			var item: Dictionary = equipment[i].duplicate()
			equipment.remove_at(i)
			add_item(item)
			return true
	return false

func has_equipment(item_id: String) -> bool:
	for item in equipment:
		if item.id == item_id:
			return true
	return false

# =============================================================
# セーブ / ロード
# =============================================================

func save_to_file(slot: int) -> void:
	var data := to_dict()
	data["save_version"] = 1
	data["timestamp"] = Time.get_unix_time_from_system()
	var json := JSON.stringify(data, "\t")
	var file := FileAccess.open("user://save_%d.json" % slot, FileAccess.WRITE)
	if file:
		file.store_string(json)

func load_from_file(slot: int) -> Dictionary:
	var path := "user://save_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}

func has_save(slot: int) -> bool:
	return FileAccess.file_exists("user://save_%d.json" % slot)
