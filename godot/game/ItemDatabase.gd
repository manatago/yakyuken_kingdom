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
	"rock_attract_white": {
		"id": "rock_attract_white",
		"name": "岩寄せの玉・白紋",
		"description": "相手がグーを出す確率+5%（1回）",
		"type": ItemType.CONSUMABLE,
		"effect": "adjust_probability",
		"target_hand": "rock",
		"probability_delta": 0.05,
		"icon_path": "res://assets/items/consumables/rock_attract_white.png",
	},
	"rock_attract_crimson": {
		"id": "rock_attract_crimson",
		"name": "岩寄せの玉・朱紋",
		"description": "相手がグーを出す確率+10%（1回）",
		"type": ItemType.CONSUMABLE,
		"effect": "adjust_probability",
		"target_hand": "rock",
		"probability_delta": 0.10,
		"icon_path": "res://assets/items/consumables/rock_attract_crimson.png",
	},
	"rock_attract_gold": {
		"id": "rock_attract_gold",
		"name": "岩寄せの玉・金紋",
		"description": "相手がグーを出す確率+15%（1回）",
		"type": ItemType.CONSUMABLE,
		"effect": "adjust_probability",
		"target_hand": "rock",
		"probability_delta": 0.15,
		"icon_path": "res://assets/items/consumables/rock_attract_gold.png",
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
		"description": "バトル勝利時にゴールドを20追加で獲得",
		"type": ItemType.EQUIPMENT,
		"effect": "gold_bonus",
		"gold_bonus_amount": 20,
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

static func apply_probability_adjustment(probabilities: Dictionary, target_hand: String, delta: float) -> Dictionary:
	var adjusted := probabilities.duplicate()
	var old_value: float = float(adjusted.get(target_hand, 0.0))
	var new_value: float = clampf(old_value + delta, 0.0, 1.0)
	var remaining_old: float = 1.0 - old_value
	if remaining_old > 0.0:
		var ratio: float = (1.0 - new_value) / remaining_old
		for hand in adjusted:
			if hand != target_hand:
				adjusted[hand] = float(adjusted[hand]) * ratio
	adjusted[target_hand] = new_value
	return adjusted

static func get_capture_count(equipment: Array) -> int:
	for item in equipment:
		if item.get("id", "") == "greed_ring":
			return 2
	return 1

static func get_gold_bonus(equipment: Array) -> int:
	for item in equipment:
		if item.get("id", "") == "gold_charm":
			return int(ITEMS.gold_charm.get("gold_bonus_amount", 0))
	return 0
