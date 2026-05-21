extends BattleChapterBase

func get_opponent_id() -> String:
	return "receptionist"

func get_opponent_name() -> String:
	return "受付嬢"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage1/bg07_st1_001.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 2},
		{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 2},
		{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 2},
	]

func get_opponent_deck_size() -> int:
	return 9

func get_player_deck_size() -> int:
	return 9

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {"paper": 0.5}

func get_gold_reward() -> Dictionary:
	return {"min": 30, "max": 50}

# --- 初期表示 ---

func setup_scene(bt):
	# デッキ構築フェーズ用: カード台座のみ。対戦相手は最初の outfit で登場させる。
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})

# --- Outfit 3: フル装備 ---

func outfit_3(bt):
	var rec = bt.character("receptionist")
	# 最初の outfit: 対戦相手が右からフェードインで登場
	rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_001.png", {"scale": 0.55, "side": "center", "position": [0, 120], "appear_effect": "fade_slide", "appear_from": "right", "appear_duration": 0.4})
	rec.band("ギルドの受付嬢を甘く見ないでね。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_002.png", {"scale": 0.50, "side": "center", "position": [0, 0]})
		rec.band("え...うそ...。")
	elif result == "lose":
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_003.png", {"scale": 0.50, "side": "center", "position": [0, 0]})
		rec.band("ふふ、まだまだね。")
	else:
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_004.png", {"scale": 0.50, "side": "center", "position": [0, 0]})
		rec.band("あら、引き分け？")

# --- Outfit 2: 1枚脱いだ ---

func outfit_2(bt):
	var rec = bt.character("receptionist")
	rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_005.png", {"scale": 0.45, "side": "center", "position": [0, -114]})
	rec.band("...ちょっと、見ないでよ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_006.png", {"scale": 0.50, "side": "center", "position": [0, 0]})
		rec.band("...っ、また負けた...。")
	elif result == "lose":
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_007.png", {"scale": 0.40, "side": "center", "position": [0, -195]})
		rec.band("ほら、油断するからよ。")
	else:
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_008.png", {"scale": 0.45, "side": "center", "position": [0, -100]})
		rec.band("また引き分け...集中しなさい。")

# --- Outfit 1: あと1枚 ---

func outfit_1(bt):
	var rec = bt.character("receptionist")
	rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_009.png", {"scale": 0.45, "side": "center", "position": [0, -105]})
	rec.band("...こ、これ以上は絶対にダメ！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.4})

	if result == "win":
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_010.png", {"scale": 0.45, "side": "center", "position": [0, -120]})
		rec.band("いやぁぁぁ！！")
	elif result == "lose":
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_011.png", {"scale": 0.45, "side": "center", "position": [0, -100]})
		rec.band("ふぅ...助かった...。")
	else:
		rec.set_portrait("res://assets/characters/main/receptionist/topless/receptionist_topless_012.png", {"scale": 0.45, "side": "center", "position": [0, -100]})
		rec.band("...まだ終わらないの？")
