extends BattleChapterBase

# Stage5 ボス: フェリア（騎士団長、プラチナの三種カード保有）
# 詳細: docs/scenarios/stage5_scenario.txt
# 注: 1戦目は固定敗北。再戦で通常勝利可能。

func get_opponent_id() -> String:
	return "feria"

func get_opponent_name() -> String:
	return "フェリア"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage5/bg_training_ground.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	# プラチナ加護: 強グレードのみ
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
	return {"min": 120, "max": 180}
