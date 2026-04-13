extends BattleChapterBase

# 盗賊ジン（斥候）戦 — 1回勝負

func get_opponent_id() -> String:
	return "jin"

func get_opponent_name() -> String:
	return "盗賊ジン"

func get_battle_background() -> String:
	return "res://assets/backgrounds/prologue/bg06_prison_arena.png"

func get_opponent_outfit_count() -> int:
	return 1

func get_player_outfit_count() -> int:
	return 1

func get_opponent_hand() -> Array:
	return [
		{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1},
		{"hand": "rock", "grade": 1},
	]

func get_opponent_deck_size() -> int:
	return 3

func get_player_deck_size() -> int:
	return 3

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {"scissors": 2.0}

func get_gold_reward() -> Dictionary:
	return {"min": 3, "max": 8}

func get_lose_behavior() -> String:
	return "abort"

func get_lose_redirect() -> Dictionary:
	return {"type": "guild_home"}

func get_farewell(result: String) -> Dictionary:
	if result == "lose":
		return {
			"narration": "サトシは盗賊ジンに敗北した。\nこれ以上先に進むのは危険だ……。",
			"portrait": "res://assets/characters/subevent1/jin_st2_001.png",
			"portrait_scale": 0.33,
			"text": "へっ！ 雑魚が！ 出直してこい！",
		}
	return {}

# --- バトル演出 ---

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/deck_002.png", {"scale": 0.75, "position": [0, 230]})
	var jin = bt.character("jin")
	jin.set_portrait("res://assets/characters/subevent1_battle/jin_battle_001.png", {"scale": 0.33, "side": "center", "position": [0, -199]})

func outfit_1(bt):
	var jin = bt.character("jin")
	jin.set_portrait("res://assets/characters/subevent1_battle/jin_battle_001.png", {"scale": 0.33, "side": "center", "position": [0, -199]})
	jin.band("俺の「疾風のハサミ」を食らいな！")

	var selection = await bt.select_hand()
	await bt.janken(selection)
