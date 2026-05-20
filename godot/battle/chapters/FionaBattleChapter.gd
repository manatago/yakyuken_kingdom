extends BattleChapterBase

# Subevent3 ボス: フィオナ（呪われた鎧、加護弱体化後の通常戦）
# 単一バトル（ミニゲーム成功で加護弱体→通常戦）

const FIONA_PORTRAIT := "res://assets/characters/main/fiona/clothed/fiona_clothed_001.png"

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

func setup_scene(bt):
	# デッキ構築フェーズ用: カード台座のみ。対戦相手は最初の outfit で登場させる。
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})

func outfit_3(bt):
	var fiona = bt.character("fiona")
	# 最初の outfit: 対戦相手が右からフェードインで登場
	fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260], "appear_effect": "fade_slide", "appear_from": "right", "appear_duration": 0.4})
	fiona.band("...は、はい...お、お願い、します...。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.55})

	if result == "win":
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...あ...！")
	elif result == "lose":
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...あの、ご、ごめんなさい...。")
	else:
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...あ、あいこ、です...。")

func outfit_2(bt):
	var fiona = bt.character("fiona")
	fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	fiona.band("...呪い、まだ、効いて...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...や、やった...？")
	elif result == "lose":
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...ご、ごめん、なさい...！")
	else:
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...！")

func outfit_1(bt):
	var fiona = bt.character("fiona")
	fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
	fiona.band("...ぁ...こ、これで、最後...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.45})

	if result == "win":
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...！ や、やった、です...呪いが、解けます...！")
	elif result == "lose":
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...ぁ...そんな...呪いが、まだ...！")
	else:
		fiona.set_portrait(FIONA_PORTRAIT, {"scale": 0.5, "side": "center", "position": [0, -260]})
		fiona.band("...！")

func get_lose_behavior() -> String:
	return "redirect"

func get_lose_redirect() -> Dictionary:
	# 敗北時: 呪い復活→セバス絶叫→ギルドホーム
	return {
		"type": "story_sequence_then_guild_home",
		"sequence_id": "subevent3_battle_lose",
	}

func get_farewell(_result: String) -> Dictionary:
	return {}
