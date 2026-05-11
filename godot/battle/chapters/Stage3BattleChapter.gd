extends BattleChapterBase

# Stage3 ボス: マグダレナ（教会大司祭）
# 詳細: docs/scenarios/stage3_scenario.txt
# 注: 1戦目は固定敗北（scripted）。再戦で通常勝利可能。

func get_opponent_id() -> String:
	return "magdalena"

func get_opponent_name() -> String:
	return "マグダレナ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/subevent2/bg02_church_interior.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 2}, {"hand": "rock", "grade": 3},
		{"hand": "scissors", "grade": 2}, {"hand": "scissors", "grade": 2},
		{"hand": "paper", "grade": 2}, {"hand": "paper", "grade": 2}, {"hand": "paper", "grade": 3},
	]

func get_opponent_deck_size() -> int:
	return 7

func get_player_deck_size() -> int:
	return 7

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {"paper": 0.4}

func get_gold_reward() -> Dictionary:
	return {"min": 80, "max": 120}
