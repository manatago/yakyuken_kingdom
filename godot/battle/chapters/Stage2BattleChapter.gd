extends BattleChapterBase

# Stage2 ボス: レイラ（暗部アサシン）
# 1戦目: 毒+判断遅延で完敗（固定敗北 win_rate=0）
# 2戦目: ミニゲーム成功後の動揺戦（通常 win_rate 0.5前後）

const LAYLA_PORTRAIT := "res://assets/characters/main/layla/clothed/layla_clothed_001.png"

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

# --- 1戦目/2戦目の判定 ---

func _is_first_battle() -> bool:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
	if gs == null:
		return true
	return not gs.flags.get("stage2_first_battle_done", false)

func _win_rate(default_rate: float) -> float:
	# 1戦目は固定敗北
	return 0.0 if _is_first_battle() else default_rate

# --- エントリーポイント ---

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	var layla = bt.character("layla")
	layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})

func outfit_3(bt):
	var layla = bt.character("layla")
	layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		layla.band("...では、検証、開始でございます。")
	else:
		layla.band("...再検証、開始いたします。条件は前回と同様。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.55)})

	if result == "win":
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		layla.band("...っ。お見事です。")
	elif result == "lose":
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		if _is_first_battle():
			layla.band("...一本、いただきました。")
		else:
			layla.band("...サトシ様、お見事です。")
	else:
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		layla.band("...引き分けでございますか。")

func outfit_2(bt):
	var layla = bt.character("layla")
	layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		layla.band("...では、続けます。")
	else:
		layla.band("...首筋の汗、増えてますよ、と仰いますか。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.5)})

	if result == "win":
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		layla.band("...読み、お深いですね。")
	elif result == "lose":
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		layla.band("...二本目、いただきます。")
	else:
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		layla.band("...またですか。")

func outfit_1(bt):
	var layla = bt.character("layla")
	layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		layla.band("...最後の一本、参ります。")
	else:
		layla.band("（涙目）...や、やめっ...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.45)})

	if result == "win":
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		if _is_first_battle():
			layla.band("...一本だけ、お返ししました。")
		else:
			layla.band("...完敗、です。")
	elif result == "lose":
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		if _is_first_battle():
			layla.band("...検証、終了でございます。\n再検証の権利は三日以内、一度のみ。")
		else:
			layla.band("...ふぅ、危なかった。")
	else:
		layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		layla.band("...引き分け。")

func get_lose_behavior() -> String:
	return "continue" if _is_first_battle() else "guild_home"

func get_lose_redirect() -> Dictionary:
	return {} if _is_first_battle() else {"type": "guild_home"}

func get_farewell(_result: String) -> Dictionary:
	return {}
