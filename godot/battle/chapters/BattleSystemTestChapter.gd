extends BattleChapterBase
class_name BattleSystemTestChapter

const TEST_BACKGROUND := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const TEST_OPPONENT_PORTRAIT := "res://assets/characters/mob/guard/default/guard_default_024.png"

func get_opponent_id() -> String:
	return "matilda"

func get_opponent_name() -> String:
	return "マチルダ"

func get_battle_background() -> String:
	return TEST_BACKGROUND

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1},
		{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1},
		{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1},
	]

func get_opponent_deck_size() -> int:
	return 9

func get_player_deck_size() -> int:
	return 9

func has_bayes_eye() -> bool:
	return true

func get_gold_reward() -> Dictionary:
	return {"min": 20, "max": 20}

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})
	var matilda = bt.character("matilda")
	matilda.set_portrait(TEST_OPPONENT_PORTRAIT, {
		"scale": 0.8,
		"side": "center",
		"position": [0, -199],
	})
	matilda.band("カードとアイテムの効果、確かめていこうか。")

func outfit_3(bt):
	await _play_round(bt)

func outfit_2(bt):
	await _play_round(bt)

func outfit_1(bt):
	await _play_round(bt)

func _play_round(bt):
	var selection = await bt.select_hand()
	await bt.janken(selection)
