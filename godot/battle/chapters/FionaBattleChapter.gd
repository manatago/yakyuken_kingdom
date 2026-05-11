extends BattleChapterBase

# Subevent3 ボス: フィオナ（呪われた鎧を装着、HP3バトル想定）
# 詳細: docs/scenarios/subevent3_scenario.txt
# 注: ミニゲームで加護度を削った後の最終カードバトル

func get_opponent_id() -> String:
	return "fiona"

func get_opponent_name() -> String:
	return "フィオナ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/subevent3/bg_noble_room.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	# 呪いの強制勝利ロジック残骸。グレード中心
	return [
		{"hand": "rock", "grade": 2}, {"hand": "rock", "grade": 2},
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
	return {"paper": 0.35}

func get_gold_reward() -> Dictionary:
	return {"min": 100, "max": 150}
