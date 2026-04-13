extends BattleChapterBase

# 盗賊マルコ（用心棒）戦 — 1回勝負

func get_opponent_id() -> String:
	return "marco"

func get_opponent_name() -> String:
	return "盗賊マルコ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/prologue/bg06_prison_arena.png"

func get_opponent_outfit_count() -> int:
	return 1

func get_player_outfit_count() -> int:
	return 1

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 1},
		{"hand": "scissors", "grade": 1},
		{"hand": "paper", "grade": 1},
	]

func get_opponent_deck_size() -> int:
	return 3

func get_player_deck_size() -> int:
	return 3

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {}

func get_gold_reward() -> Dictionary:
	return {"min": 5, "max": 10}

func get_lose_behavior() -> String:
	return "abort"

func get_lose_redirect() -> Dictionary:
	return {"type": "guild_home"}

func get_farewell(result: String) -> Dictionary:
	if result == "lose":
		return {
			"narration": "サトシは盗賊マルコに敗北した。\nこれ以上先に進むのは危険だ……。",
			"portrait": "res://assets/characters/subevent1/marco_st2_001.png",
			"portrait_scale": 0.34,
			"text": "…………。帰れ。",
		}
	return {}

# --- バトル演出 ---

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/deck_002.png", {"scale": 0.75, "position": [0, 230]})
	var marco = bt.character("marco")
	marco.set_portrait("res://assets/characters/subevent1_battle/marco_battle_001.png", {"scale": 0.35, "side": "center", "position": [0, -199]})

func outfit_1(bt):
	var marco = bt.character("marco")
	marco.set_portrait("res://assets/characters/subevent1_battle/marco_battle_001.png", {"scale": 0.35, "side": "center", "position": [0, -199]})
	marco.band("…………。")

	var selection = await bt.select_hand()
	await bt.janken(selection)
