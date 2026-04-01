extends BattleChapterBase

func get_opponent_id() -> String:
	return "receptionist"

func get_opponent_name() -> String:
	return "受付嬢"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage1/bg07_guild_hall.png"

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
	bt.deck("res://assets/battle/decks/deck_002.png", {"scale": 0.75, "position": [0, 230]})
	var rec = bt.character("receptionist")
	rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_001.png", {"scale": 0.3, "side": "center", "position": [0, -282]})

# --- Outfit 3: フル装備 ---

func outfit_3(bt):
	var rec = bt.character("receptionist")
	rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_001.png", {"scale": 0.30, "side": "center", "position": [0, -282]})
	rec.band("ギルドの受付嬢を甘く見ないでね。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_002.png", {"scale": 0.3, "side": "center", "position": [0, -282]})
		rec.band("え……うそ……。")
	elif result == "lose":
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_003.png", {"scale": 0.30, "side": "center", "position": [0, -282]})
		rec.band("ふふ、まだまだね。")
	else:
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_004.png", {"scale": 0.30, "side": "center", "position": [0, -282]})
		rec.band("あら、引き分け？")

# --- Outfit 2: 1枚脱いだ ---

func outfit_2(bt):
	var rec = bt.character("receptionist")
	rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
	rec.band("……ちょっと、見ないでよ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_002.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		rec.band("……っ、また負けた……。")
	elif result == "lose":
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_003.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		rec.band("ほら、油断するからよ。")
	else:
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_004.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		rec.band("また引き分け……集中しなさい。")

# --- Outfit 1: あと1枚 ---

func outfit_1(bt):
	var rec = bt.character("receptionist")
	rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
	rec.band("……こ、これ以上は絶対にダメ！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.4})

	if result == "win":
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_002.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		rec.band("いやぁぁぁ！！")
	elif result == "lose":
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_003.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		rec.band("ふぅ……助かった……。")
	else:
		rec.set_portrait("res://assets/characters/stage2_battle/char10_st2_battle_004.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		rec.band("……まだ終わらないの？")
