class_name ItemDatabase
extends RefCounted

# アイテム種別
enum ItemType { CONSUMABLE, EQUIPMENT }

# 全アイテム定義
const ITEMS := {
	# --- 消耗品 ---
	"substitute_card": {
		"id": "substitute_card",
		"name": "身代わりカード",
		"description": "負けてもカードを取られない（1回）",
		"type": ItemType.CONSUMABLE,
		"effect": "protect_card",
	},
	"iron_shield": {
		"id": "iron_shield",
		"name": "鉄の盾",
		"description": "負けてもHPが減らない（1回）",
		"type": ItemType.CONSUMABLE,
		"effect": "protect_hp",
	},
	"intimidation": {
		"id": "intimidation",
		"name": "威圧の札",
		"description": "相手が負ける手の確率+20%（1回）",
		"type": ItemType.CONSUMABLE,
		"effect": "intimidate",
	},
	# --- 装備品 ---
	"greed_ring": {
		"id": "greed_ring",
		"name": "強欲の指輪",
		"description": "勝利時にカードを2枚取得",
		"type": ItemType.EQUIPMENT,
		"effect": "double_capture",
	},
	"gold_charm": {
		"id": "gold_charm",
		"name": "金運のお守り",
		"description": "バトル勝利時にゴールドも獲得",
		"type": ItemType.EQUIPMENT,
		"effect": "gold_bonus",
	},
}

static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})

static func get_all_consumables() -> Array:
	var result: Array = []
	for id in ITEMS:
		if ITEMS[id].type == ItemType.CONSUMABLE:
			result.append(ITEMS[id])
	return result

static func get_all_equipment() -> Array:
	var result: Array = []
	for id in ITEMS:
		if ITEMS[id].type == ItemType.EQUIPMENT:
			result.append(ITEMS[id])
	return result

static func get_all_items() -> Array:
	var result: Array = []
	for id in ITEMS:
		result.append(ITEMS[id])
	return result
