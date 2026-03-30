extends TownMapBase
class_name Stage1TownMap

var _db := EncounterDatabase.new()

func get_home_background() -> String:
	return "res://assets/backgrounds/stage1/bg07_st1_001.png"

func get_home_connections() -> Array:
	return ["guild_street", "market", "tavern"]

func get_all_encounter_chars() -> Dictionary:
	return _db.get_all_chars()

# エリアごとの出現キャラ（weight = 出現重み）
var _area_encounters := {
	"guild_street": [
		{"char": "thug_a", "weight": 5},
		{"char": "thug_b", "weight": 3},
	],
	"market": [
		{"char": "merchant", "weight": 5},
		{"char": "thug_a", "weight": 2},
	],
	"tavern": [
		{"char": "drunk", "weight": 5},
		{"char": "thug_a", "weight": 3},
		{"char": "thug_b", "weight": 2},
	],
	"slum": [
		{"char": "thug_b", "weight": 5},
		{"char": "thug_a", "weight": 4},
		{"char": "bandit", "weight": 3},
	],
	"outside": [
		{"char": "bandit", "weight": 5},
		{"char": "thug_b", "weight": 3},
	],
	"port": [
		{"char": "sailor", "weight": 5},
		{"char": "merchant", "weight": 3},
	],
}

func get_encounters(area_id: String) -> Array:
	var entries: Array = _area_encounters.get(area_id, [])
	var result: Array = []
	for entry in entries:
		var char_data: Dictionary = _db.get_char(entry.char)
		if char_data.is_empty():
			continue
		var combined := char_data.duplicate()
		combined["weight"] = entry.weight
		result.append(combined)
	return result

func get_areas() -> Dictionary:
	return {
		"guild_street": {
			"name": "ギルド通り",
			"bg": "res://assets/backgrounds/stage1/bg06_st1_001.png",
			"description": "商店や冒険者が行き交うメイン通り。\n時々チンピラに絡まれることも。",
			"connections": ["guild_home", "market", "slum", "tavern", "outside"],
			"battle_rate": 0.6,
			"enemy_strength": 1,
		},
		"market": {
			"name": "市場広場",
			"bg": "res://assets/backgrounds/stage1/bg08_st1_001.png",
			"description": "露店や行商人が並ぶ賑やかな広場。\n比較的安全な場所。",
			"connections": ["guild_home", "guild_street", "port", "tavern"],
			"battle_rate": 0.5,
			"enemy_strength": 1,
		},
		"tavern": {
			"name": "酒場",
			"bg": "res://assets/backgrounds/stage1/bg09_st1_001.png",
			"description": "冒険者の溜まり場。酔っ払いが多い。\n情報収集には最適だが、絡まれることも。",
			"connections": ["guild_home", "guild_street", "market"],
			"battle_rate": 0.6,
			"enemy_strength": 1,
		},
		"slum": {
			"name": "スラム街",
			"bg": "res://assets/backgrounds/stage1/bg10_st1_001.png",
			"description": "治安の悪い裏通り。\n危険だが、レアなカードが手に入ることも。",
			"connections": ["guild_street"],
			"battle_rate": 0.7,
			"enemy_strength": 2,
		},
		"outside": {
			"name": "城壁の外",
			"bg": "res://assets/backgrounds/stage1/bg11_st1_001.png",
			"description": "城壁の外の荒野。\n強い相手が多いが、報酬も大きい。",
			"connections": ["guild_street"],
			"battle_rate": 0.8,
			"enemy_strength": 3,
		},
		"port": {
			"name": "港",
			"bg": "res://assets/backgrounds/stage1/bg12_st1_001.png",
			"description": "交易船が行き来する波止場。\n異国の商人や船乗りがいる。",
			"connections": ["market"],
			"battle_rate": 0.6,
			"enemy_strength": 2,
		},
	}
