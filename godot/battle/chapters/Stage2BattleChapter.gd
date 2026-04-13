extends BattleChapterBase

func get_opponent_id() -> String:
	return "belka"

func get_opponent_name() -> String:
	return "ベルカ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/prologue/bg06_prison_arena.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	# ベルカ: 読み型 — バランス良く高グレードも混在
	return [
		{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 2},
		{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 2},
		{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 2}, {"hand": "paper", "grade": 2},
	]

func get_opponent_deck_size() -> int:
	return 9

func get_player_deck_size() -> int:
	return 9

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	# 読み型: わずかにパー寄り（プレイヤーのグー傾向を読む）
	return {"paper": 0.4}

func get_gold_reward() -> Dictionary:
	return {"min": 40, "max": 60}

# --- エントリーポイント（バトルシステムから呼ばれる） ---

func setup_scene(bt):
	belka_setup_scene(bt)

func outfit_3(bt):
	await belka_outfit_3(bt)

func outfit_2(bt):
	await belka_outfit_2(bt)

func outfit_1(bt):
	await belka_outfit_1(bt)

# =============================================
# ベルカ・マニエラ戦（サブイベント1 ボス）
# =============================================

func belka_setup_scene(bt):
	bt.deck("res://assets/battle/decks/deck_002.png", {"scale": 0.75, "position": [0, 230]})
	var belka = bt.character("belka")
	belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_001.png", {"scale": 0.64, "side": "center", "position": [0, -275]})

# --- ベルカ Outfit 3: フル装備 ---

func belka_outfit_3(bt):
	var belka = bt.character("belka")
	belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_001.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
	belka.band("へっ、ボクに勝てると思ってんの？")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_002.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("……っ！ やるじゃん……。")
	elif result == "lose":
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_003.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("ゲハハ！ ボクの読み、甘く見んなよ。")
	else:
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_004.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("あいこ？ ……ふーん、なかなかやるね。")

# --- ベルカ Outfit 2: 1枚脱いだ ---

func belka_outfit_2(bt):
	var belka = bt.character("belka")
	belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_005.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
	belka.band("……ちっ、調子乗んなよ。ここからが本気だ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_006.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("……マジかよ。あんた、ボクの手を読んでるだろ。")
	elif result == "lose":
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_007.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("へへっ、まだまだだね。")
	else:
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_008.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("……また引き分けかよ。しつこいヤツだな。")

# --- ベルカ Outfit 1: あと1枚 ---

func belka_outfit_1(bt):
	var belka = bt.character("belka")
	belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_009.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
	belka.band("……っ！ こ、これ以上はダメだって！ 見んな！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.4})

	if result == "win":
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_010.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("う、うそだろ……ボクが……負けた……！")
	elif result == "lose":
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_011.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("……ふぅ。危なかった……。")
	else:
		belka.set_portrait("res://assets/characters/subevent1_battle/belka_battle_012.png", {"scale": 0.64, "side": "center", "position": [0, -275]})
		belka.band("……まだ続くのかよ……勘弁してくれ……。")

func get_lose_behavior() -> String:
	return "abort"

func get_lose_redirect() -> Dictionary:
	return {"type": "guild_home"}

func get_farewell(result: String) -> Dictionary:
	if result == "lose":
		return {
			"narration": "サトシはベルカに敗北した。\n盗賊団のアジトから撤退するしかない……。",
			"portrait": "res://assets/characters/subevent1_battle/belka_battle_003.png",
			"portrait_scale": 0.64,
			"text": "ゲハハ！ ボクに勝てると思ったのかよ？\n出直してきな！",
		}
	return {}
