extends BattleChapterBase

# Stage5 ボス: フェリア（騎士団長、プラチナ三種カード）
# 1戦目: プラチナ加護で完敗（固定敗北）
# 2戦目: 心鏡の珠でプラチナ封印後の通常戦

const FERIA_PORTRAIT := "res://assets/characters/main/feria/clothed/feria_clothed_001.png"

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

func _is_first_battle() -> bool:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
	if gs == null: return true
	return not gs.flags.get("stage5_first_battle_done", false)

func _win_rate(default_rate: float) -> float:
	return 0.0 if _is_first_battle() else default_rate

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	var feria = bt.character("feria")
	feria.set_portrait(FERIA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})

func outfit_3(bt):
	var feria = bt.character("feria")
	feria.set_portrait(FERIA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		feria.band("プラチナのグー。")
	else:
		feria.band("...神器が、応答しない...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.5)})

	if result == "win":
		feria.band("...！")
	elif result == "lose":
		feria.band("...一本。")
	else:
		feria.band("...引き分け。")

func outfit_2(bt):
	var feria = bt.character("feria")
	feria.set_portrait(FERIA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		feria.band("プラチナのチョキ。")
	else:
		feria.band("う、うるさい！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.5)})

	if result == "win":
		feria.band("...貴様...！")
	elif result == "lose":
		feria.band("...二本目。")
	else:
		feria.band("...粘るな。")

func outfit_1(bt):
	var feria = bt.character("feria")
	feria.set_portrait(FERIA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		feria.band("プラチナのパー。")
	else:
		feria.band("（涙目）や、やめっ...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.4)})

	if result == "win":
		if _is_first_battle():
			feria.band("...惜しい。")
		else:
			feria.band("...完敗だ。")
	elif result == "lose":
		if _is_first_battle():
			feria.band("勝負、あり。")
		else:
			feria.band("...助かった。")
	else:
		feria.band("...決着を、急げ。")

func get_lose_behavior() -> String:
	return "continue" if _is_first_battle() else "guild_home"

func get_lose_redirect() -> Dictionary:
	return {} if _is_first_battle() else {"type": "guild_home"}

func get_farewell(_result: String) -> Dictionary:
	return {}
