extends BattleChapterBase

func get_opponent_id() -> String:
	return "adventurer_a"

func get_opponent_name() -> String:
	return "冒険者A"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage1/bg07_guild_hall.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

# --- 初期表示（デッキ構築時） ---

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/deck-002.png", {"scale": 0.75, "position": [0, 230]})
	var adv = bt.character("adventurer_a")
	adv.set_portrait("res://assets/characters/stage1/adventurer_a_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})

# --- Outfit 3: フル装備 ---

func outfit_3(bt):
	var adv = bt.character("adventurer_a")
	adv.set_portrait("res://assets/characters/stage1/adventurer_a_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
	adv.band("ヘッ、ビビってんのか？ さっさとカードを出しな！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.6})

	if result == "win":
		adv.band("な……！？ まぐれだ、まぐれ！")
	elif result == "lose":
		adv.band("ガハハ！ やっぱ新顔は弱ぇな！")
	else:
		adv.band("チッ、あいこか。次で決めるぞ！")

# --- Outfit 2: 1枚脱いだ ---

func outfit_2(bt):
	var adv = bt.character("adventurer_a")
	adv.set_portrait("res://assets/characters/stage1/adventurer_a_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
	adv.band("テメェ……調子に乗りやがって……！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		adv.band("嘘だろ……！？")
	elif result == "lose":
		adv.band("ハッ！ まだまだだな！")
	else:
		adv.band("引き分けだと……！？")

# --- Outfit 1: あと1枚 ---

func outfit_1(bt):
	var adv = bt.character("adventurer_a")
	adv.set_portrait("res://assets/characters/stage1/adventurer_a_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
	adv.band("くそっ……こっからが本気だ！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		adv.band("バカな……！")
	elif result == "lose":
		adv.band("ざまぁみろ！")
	else:
		adv.band("まだ終わらねぇぞ！")
