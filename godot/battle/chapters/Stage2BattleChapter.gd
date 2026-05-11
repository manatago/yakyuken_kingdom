extends BattleChapterBase

# Stage2 ボス: レイラ（アサシン）
# 詳細: docs/scenarios/stage2_scenario.txt
# 注: 1戦目は固定敗北（scripted）。再戦（stage2_battle2）で通常勝利可能。

func get_opponent_id() -> String:
	return "layla"

func get_opponent_name() -> String:
	return "レイラ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage2/bg_inn_meeting.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	# レイラ: アサシン技量。強グレード多め
	return [
		{"hand": "rock", "grade": 2}, {"hand": "rock", "grade": 2},
		{"hand": "scissors", "grade": 2}, {"hand": "scissors", "grade": 2}, {"hand": "scissors", "grade": 3},
		{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 2},
	]

func get_opponent_deck_size() -> int:
	return 7

func get_player_deck_size() -> int:
	return 7

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {"scissors": 0.4}

func get_gold_reward() -> Dictionary:
	return {"min": 60, "max": 90}
