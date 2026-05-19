extends BattleChapterBase

# Stage3 ボス: マグダレナ（教会大司祭）
# 1戦目: 信仰の光で完敗（固定敗北）
# 2戦目: 妄想ミニゲーム成功後の動揺戦

const MAG_PORTRAIT := "res://assets/characters/main/magdalena/clothed/magdalena_clothed_001.png"

func get_opponent_id() -> String:
	return "magdalena"

func get_opponent_name() -> String:
	return "マグダレナ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/subevent2/bg02_church_interior.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 2}, {"hand": "rock", "grade": 3},
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
	return {"paper": 0.4}

func get_gold_reward() -> Dictionary:
	return {"min": 80, "max": 120}

func _is_first_battle() -> bool:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
	if gs == null: return true
	return not gs.flags.get("stage3_first_battle_done", false)

func _win_rate(default_rate: float) -> float:
	return 0.0 if _is_first_battle() else default_rate

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	var mag = bt.character("magdalena")
	mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})

func outfit_3(bt):
	var mag = bt.character("magdalena")
	mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		mag.band("神よ、光あれ。")
	else:
		mag.band("...ええ。罪人の魂、わたくしが受け止めましょう。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.55)})

	if result == "win":
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		mag.band("...神は、今日は別のお考えのようでございます。")
	elif result == "lose":
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		mag.band("...神の御加護、ここに。")
	else:
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		mag.band("...引き分け、ですか。")

func outfit_2(bt):
	var mag = bt.character("magdalena")
	mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		mag.band("...次は、ございませんよ。")
	else:
		mag.band("...っ！ そ、その朗読は──！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.5)})

	if result == "win":
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		mag.band("...わたくしの読み、外れた...？")
	elif result == "lose":
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		mag.band("...神は、まだ私に勝利を授けてくださる。")
	else:
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		mag.band("...またあいこ。困ったお方ですね。")

func outfit_1(bt):
	var mag = bt.character("magdalena")
	mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		mag.band("...神の御前で、これ以上の屈辱は許されません。")
	else:
		mag.band("...っ！ お願い、もう、見ないで...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.45)})

	if result == "win":
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		if _is_first_battle():
			mag.band("...神が、今、一瞬目を逸らされました。")
		else:
			mag.band("...完敗、です。本の返却、嫌がらせの停止、承諾いたします。")
	elif result == "lose":
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		if _is_first_battle():
			mag.band("...勝負、ありました。神は、今日、私にお味方くださいました。")
		else:
			mag.band("...ふぅ、危なかった。")
	else:
		mag.set_portrait(MAG_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		mag.band("...粘り強い方ですわね。")

func get_lose_behavior() -> String:
	return "continue" if _is_first_battle() else "guild_home"

func get_lose_redirect() -> Dictionary:
	return {} if _is_first_battle() else {"type": "guild_home"}

func get_farewell(_result: String) -> Dictionary:
	return {}
