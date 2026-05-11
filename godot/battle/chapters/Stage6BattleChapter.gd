extends BattleChapterBase

# Stage6 ボス: 王女アレクシア
# 1戦目: 勅令で3本必敗（固定敗北）
# 2戦目: 最悪マナーで秘技封印後の通常戦

const PRINCESS_PORTRAIT := "res://assets/characters/main/princess/clothed/princess_clothed_001.png"

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

func _is_first_battle() -> bool:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
	if gs == null: return true
	return not gs.flags.get("stage6_first_battle_done", false)

func _win_rate(default_rate: float) -> float:
	return 0.0 if _is_first_battle() else default_rate

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})
	var princess = bt.character("princess")
	princess.set_portrait(PRINCESS_PORTRAIT, {"scale": 0.45, "side": "center", "position": [0, -260]})

func outfit_3(bt):
	var princess = bt.character("princess")
	princess.set_portrait(PRINCESS_PORTRAIT, {"scale": 0.45, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		princess.band("第一勝負。...勅令、発動。")
	else:
		princess.band("（扇で顔を覆う）\n...では、第二勝負、開始、いたします。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.5)})

	if result == "win":
		princess.band("...！")
	elif result == "lose":
		princess.band("...一本。")
	else:
		princess.band("...引き分け。")

func outfit_2(bt):
	var princess = bt.character("princess")
	princess.set_portrait(PRINCESS_PORTRAIT, {"scale": 0.45, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		princess.band("...予告通り。")
	else:
		princess.band("...貴方の手、読めません...。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.5)})

	if result == "win":
		princess.band("...。")
	elif result == "lose":
		princess.band("...二本目。")
	else:
		princess.band("...またあいこ。")

func outfit_1(bt):
	var princess = bt.character("princess")
	princess.set_portrait(PRINCESS_PORTRAIT, {"scale": 0.45, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		princess.band("...勝負、つかせていただきます。")
	else:
		princess.band("...覚悟、決めます。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.4)})

	if result == "win":
		if _is_first_battle():
			princess.band("...奇跡を、見ました。")
		else:
			princess.band("...敗北を、認めます。")
	elif result == "lose":
		if _is_first_battle():
			princess.band("...第一勝負、予告通り、私の勝利でございます。")
		else:
			princess.band("...粘りました。")
	else:
		princess.band("...粘り強い、お方ですね。")

func get_lose_behavior() -> String:
	return "continue" if _is_first_battle() else "guild_home"

func get_lose_redirect() -> Dictionary:
	return {} if _is_first_battle() else {"type": "guild_home"}

func get_farewell(_result: String) -> Dictionary:
	return {}
