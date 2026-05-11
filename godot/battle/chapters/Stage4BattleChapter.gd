extends BattleChapterBase

# Stage4 ボス: セレス（魔法師団長）
# 詳細: docs/scenarios/stage4_scenario.txt
# 注: 1戦目は固定敗北（縛鎖魔法で完敗）。再戦で通常勝利可能。

func get_opponent_id() -> String:
	return "seles"

func get_opponent_name() -> String:
	return "セレス"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage4/bg_dojo_third.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 2}, {"hand": "rock", "grade": 3},
		{"hand": "scissors", "grade": 2}, {"hand": "scissors", "grade": 3},
		{"hand": "paper", "grade": 2}, {"hand": "paper", "grade": 3}, {"hand": "paper", "grade": 3},
	]

func get_opponent_deck_size() -> int:
	return 7

func get_player_deck_size() -> int:
	return 7

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {"rock": 0.35, "paper": 0.35}

func get_gold_reward() -> Dictionary:
	return {"min": 100, "max": 150}
