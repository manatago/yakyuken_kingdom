extends BattleChapterBase

# ガルド（副首領）戦 — 1回勝負

func get_opponent_id() -> String:
	return "gald"

func get_opponent_name() -> String:
	return "ガルド"

func get_battle_background() -> String:
	return "res://assets/backgrounds/prologue/bg06_prison_arena.png"

func get_opponent_outfit_count() -> int:
	return 1

func get_player_outfit_count() -> int:
	return 1

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1},
		{"hand": "scissors", "grade": 1},
	]

func get_opponent_deck_size() -> int:
	return 3

func get_player_deck_size() -> int:
	return 3

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {"rock": 2.0}

func get_gold_reward() -> Dictionary:
	return {"min": 8, "max": 15}

func get_lose_behavior() -> String:
	return "abort"

func get_lose_redirect() -> Dictionary:
	return {"type": "guild_home"}

func get_farewell(result: String) -> Dictionary:
	if result == "lose":
		return {
			"narration": "サトシはガルドに敗北した。\nこれ以上先に進むのは危険だ……。",
			"portrait": "res://assets/characters/subevent1/gald_st2_002.png",
			"portrait_scale": 0.33,
			"text": "ガハハ！ 帰んな、弱虫！",
		}
	return {}

# --- バトル演出 ---

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/deck_002.png", {"scale": 0.75, "position": [0, 230]})
	var gald = bt.character("gald")
	gald.set_portrait("res://assets/characters/subevent1_battle/gald_battle_001.png", {"scale": 0.34, "side": "center", "position": [0, -199]})

func outfit_1(bt):
	var gald = bt.character("gald")
	gald.set_portrait("res://assets/characters/subevent1_battle/gald_battle_001.png", {"scale": 0.34, "side": "center", "position": [0, -199]})
	gald.band("ガハハ！ 俺の拳で吹っ飛ばしてやる！")

	var selection = await bt.select_hand()
	await bt.janken(selection)
