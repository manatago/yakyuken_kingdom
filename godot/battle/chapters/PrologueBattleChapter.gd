extends BattleChapterBase

func get_opponent_id() -> String:
	return "matilda"

func get_opponent_name() -> String:
	return "マチルダ"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

# --- 初期表示 ---

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/table01-001.png", {"scale": 1.25, "position": [0, 170]})
	var matilda = bt.character("matilda")
	matilda.set_portrait("res://assets/characters/prologue_battle/char04_pg_battle_001.png", {"scale": 0.95, "side": "center", "position": [0, -197]})

# --- Outfit 3: フル装備 ---

func outfit_3(bt):
	var matilda = bt.character("matilda")
	matilda.band("さあ、始めようか。手加減はしないよ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		matilda.band("へえ……やるじゃないか。")
	elif result == "lose":
		matilda.band("甘いね。")
	else:
		matilda.band("あいこか。次で決めな。")

# --- Outfit 2: 1枚脱いだ状態 ---

func outfit_2(bt):
	var matilda = bt.character("matilda")

	matilda.set_portrait("res://assets/characters/prologue_battle/char04_pg_battle_001.png", {"scale": 0.95, "side": "center"})
	matilda.band("ちっ……まだまだ終わらないよ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		matilda.band("……っ、調子に乗るんじゃないよ。")
	elif result == "lose":
		matilda.band("ふふ、まだ甘いね。")
	else:
		matilda.band("あいこか。集中しな。")

# --- Outfit 1: あと1枚 ---

func outfit_1(bt):
	var matilda = bt.character("matilda")

	matilda.set_portrait("res://assets/characters/prologue_battle/char04_pg_battle_001.png", {"scale": 0.95, "side": "center"})
	matilda.band("……ここからが本気だよ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		matilda.band("…………。")
	elif result == "lose":
		matilda.band("ふふ。")
	else:
		matilda.band("まだ続くよ。")

# --- 決着 ---

func victory(bt):
	var matilda = bt.character("matilda")

	matilda.set_portrait("res://assets/characters/prologue_battle/char04_pg_battle_001.png", {"scale": 0.95, "side": "center"})
	matilda.band("……認めてやるよ。あんた、筋がいい。")
	bt.narrator_band("マチルダは悔しそうに、しかしどこか嬉しそうな表情を浮かべた。")

func defeat(bt):
	var matilda = bt.character("matilda")

	matilda.set_portrait("res://assets/characters/prologue_battle/char04_pg_battle_001.png", {"scale": 0.95, "side": "center"})
	matilda.band("残念だったね。もう少し修行してきな。")
	bt.narrator_band("マチルダは勝ち誇った表情を浮かべた。")
