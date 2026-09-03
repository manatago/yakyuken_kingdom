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
		"icon_path": "res://assets/items/consumables/substitute_card.png",
	},
	"iron_shield": {
		"id": "iron_shield",
		"name": "鉄の盾",
		"description": "負けてもHPが減らない（1回）",
		"type": ItemType.CONSUMABLE,
		"effect": "protect_hp",
		"icon_path": "res://assets/items/consumables/iron_shield.png",
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
	"scissors_attract_white": {
		"id": "scissors_attract_white", "name": "刃招きの珠・白紋", "description": "相手がチョキを出す確率+5%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "scissors", "probability_delta": 0.05,
		"icon_path": "res://assets/items/consumables/scissors_attract_white.png",
	},
	"scissors_attract_crimson": {
		"id": "scissors_attract_crimson", "name": "刃招きの珠・朱紋", "description": "相手がチョキを出す確率+10%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "scissors", "probability_delta": 0.10,
		"icon_path": "res://assets/items/consumables/scissors_attract_crimson.png",
	},
	"scissors_attract_gold": {
		"id": "scissors_attract_gold", "name": "刃招きの珠・金紋", "description": "相手がチョキを出す確率+15%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "scissors", "probability_delta": 0.15,
		"icon_path": "res://assets/items/consumables/scissors_attract_gold.png",
	},
	"paper_attract_white": {
		"id": "paper_attract_white", "name": "紙招きの毬・白紋", "description": "相手がパーを出す確率+5%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "paper", "probability_delta": 0.05,
		"icon_path": "res://assets/items/consumables/paper_attract_white.png",
	},
	"paper_attract_crimson": {
		"id": "paper_attract_crimson", "name": "紙招きの毬・朱紋", "description": "相手がパーを出す確率+10%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "paper", "probability_delta": 0.10,
		"icon_path": "res://assets/items/consumables/paper_attract_crimson.png",
	},
	"paper_attract_gold": {
		"id": "paper_attract_gold", "name": "紙招きの毬・金紋", "description": "相手がパーを出す確率+15%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "paper", "probability_delta": 0.15,
		"icon_path": "res://assets/items/consumables/paper_attract_gold.png",
	},
	"rock_break_white": {
		"id": "rock_break_white", "name": "岩砕きの札・白紋", "description": "相手がグーを出す確率-5%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "rock", "probability_delta": -0.05,
		"icon_path": "res://assets/items/consumables/rock_break_white.png",
	},
	"rock_break_crimson": {
		"id": "rock_break_crimson", "name": "岩砕きの札・朱紋", "description": "相手がグーを出す確率-10%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "rock", "probability_delta": -0.10,
		"icon_path": "res://assets/items/consumables/rock_break_crimson.png",
	},
	"rock_break_gold": {
		"id": "rock_break_gold", "name": "岩砕きの札・金紋", "description": "相手がグーを出す確率-15%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "rock", "probability_delta": -0.15,
		"icon_path": "res://assets/items/consumables/rock_break_gold.png",
	},
	"scissors_dull_white": {
		"id": "scissors_dull_white", "name": "刃鈍りの符・白紋", "description": "相手がチョキを出す確率-5%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "scissors", "probability_delta": -0.05,
		"icon_path": "res://assets/items/consumables/scissors_dull_white.png",
	},
	"scissors_dull_crimson": {
		"id": "scissors_dull_crimson", "name": "刃鈍りの符・朱紋", "description": "相手がチョキを出す確率-10%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "scissors", "probability_delta": -0.10,
		"icon_path": "res://assets/items/consumables/scissors_dull_crimson.png",
	},
	"scissors_dull_gold": {
		"id": "scissors_dull_gold", "name": "刃鈍りの符・金紋", "description": "相手がチョキを出す確率-15%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "scissors", "probability_delta": -0.15,
		"icon_path": "res://assets/items/consumables/scissors_dull_gold.png",
	},
	"paper_seal_white": {
		"id": "paper_seal_white", "name": "紙封じの栞・白紋", "description": "相手がパーを出す確率-5%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "paper", "probability_delta": -0.05,
		"icon_path": "res://assets/items/consumables/paper_seal_white.png",
	},
	"paper_seal_crimson": {
		"id": "paper_seal_crimson", "name": "紙封じの栞・朱紋", "description": "相手がパーを出す確率-10%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "paper", "probability_delta": -0.10,
		"icon_path": "res://assets/items/consumables/paper_seal_crimson.png",
	},
	"paper_seal_gold": {
		"id": "paper_seal_gold", "name": "紙封じの栞・金紋", "description": "相手がパーを出す確率-15%（1回）",
		"type": ItemType.CONSUMABLE, "effect": "adjust_probability", "target_hand": "paper", "probability_delta": -0.15,
		"icon_path": "res://assets/items/consumables/paper_seal_gold.png",
	},
	"rank_up_talisman": {
		"id": "rank_up_talisman", "name": "格上げの札", "description": "選んだカードの格を上げる（効果調整中）",
		"type": ItemType.CONSUMABLE, "effect": "rank_up", "battle_usable": false,
		"icon_path": "res://assets/items/consumables/rank_up_talisman.png",
	},
	"smoke_bomb": {
		"id": "smoke_bomb", "name": "逃げ足の煙玉", "description": "戦闘から離脱する（効果調整中）",
		"type": ItemType.CONSUMABLE, "effect": "escape", "battle_usable": false,
		"icon_path": "res://assets/items/consumables/smoke_bomb.png",
	},
	# --- 装備品 ---
	"greed_ring": {
		"id": "greed_ring",
		"name": "強欲の指輪",
		"description": "勝利時にカードを2枚取得",
		"type": ItemType.EQUIPMENT,
		"effect": "double_capture",
		"icon_path": "res://assets/items/equipment/greed_ring.png",
	},
	"gold_charm": {
		"id": "gold_charm",
		"name": "金運のお守り",
		"description": "バトル勝利時にゴールドを20追加で獲得",
		"type": ItemType.EQUIPMENT,
		"effect": "gold_bonus",
		"gold_bonus_amount": 20,
		"icon_path": "res://assets/items/equipment/gold_charm.png",
	},
	"rare_find_pendant": {
		"id": "rare_find_pendant", "name": "掘り出し物のペンダント", "description": "珍しい相手を見つけやすくなる装飾品（効果調整中）",
		"type": ItemType.EQUIPMENT, "effect": "rare_encounter",
		"icon_path": "res://assets/items/equipment/rare_find_pendant.png",
	},
	"crystal_fragment": {
		"id": "crystal_fragment", "name": "水晶の破片", "description": "砕けた真言の水晶球の欠片（効果調整中）",
		"type": ItemType.EQUIPMENT, "effect": "crystal_fragment",
		"icon_path": "res://assets/items/equipment/crystal_fragment.png",
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

static func is_battle_usable(item: Dictionary) -> bool:
	return item.get("battle_usable", true)

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

static func format_gold_reward_summary(base_gold: int, gold_bonus: int) -> String:
	return "%dG + %dG（金運のお守り）" % [base_gold, gold_bonus]
