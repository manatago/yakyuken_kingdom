extends BattleChapterBase

# Stage6 ボス: 王女アレクシア
# 詳細: docs/scenarios/stage6_scenario.txt
# 注: 1戦目は固定敗北（勅令・絶対王政の特殊ルール）。再戦は通常バトル。

func get_opponent_id() -> String:
	return "princess"

func get_opponent_name() -> String:
	return "王女アレクシア"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage6/bg_royal_hall.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 3}, {"hand": "rock", "grade": 3},
		{"hand": "scissors", "grade": 3}, {"hand": "scissors", "grade": 3},
		{"hand": "paper", "grade": 3}, {"hand": "paper", "grade": 3}, {"hand": "paper", "grade": 3},
	]

func get_opponent_deck_size() -> int:
	return 7

func get_player_deck_size() -> int:
	return 7

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {}

func get_gold_reward() -> Dictionary:
	return {"min": 150, "max": 250}
