extends BattleChapterBase

func get_opponent_id() -> String:
	return "adventurer_a"

func get_opponent_name() -> String:
	return "冒険者A"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage1/bg07_guild_hall.png"

# ランダムバトル: HP1、デッキ3枚
func get_opponent_outfit_count() -> int:
	return 1

func get_player_outfit_count() -> int:
	return 1

func get_opponent_hand() -> Array:
	# 冒険者A: グー2枚、パー1枚（脳筋タイプ）
	return [
		{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1},
		{"hand": "paper", "grade": 1},
	]

func get_opponent_deck_size() -> int:
	return 3

func get_player_deck_size() -> int:
	return 3

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	# 脳筋の癖: グーを出しやすい（基本67% + 補正 → 約90%）
	return {"rock": 2.33}

func get_gold_reward() -> Dictionary:
	return {"min": 5, "max": 15}

# --- チュートリアル（ベイズ・アイ） ---

func tutorial(bt):
	var adv = bt.character("adventurer_a")
	adv.set_portrait("res://assets/characters/stage1_battle/char09_st1_battle_001.png", {"scale": 0.6, "side": "center", "position": [0, -145]})

	# ピー助: 情報提供（右下）
	bt.set_bubble_side("bottom-right")
	bt.narrator_band("ピー助:（サトシの肩から）\nおい、サトシ。落ち着け。\nこいつのデッキはスキャン済みだ。ノーマルカードしかない雑魚だ。")

	bt.narrator_band("ピー助:\nランダムバトルのルールを教えてやる。\nHPは1だ。1回負けたら終了。\nデッキは3枚。3回引き分けたらドローで終わりだ。")

	# サトシ（左下）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:（心の声）\n1回負けたら終了……。シビアだな。")

	# ピー助（右下）
	bt.set_bubble_side("bottom-right")
	bt.narrator_band("ピー助:\nデッキは俺が組んでやる。グー、チョキ、パー各1枚だ。こいつ相手ならこれで十分だ。")

	# デッキ強制構築（グー、チョキ、パー各1枚）
	await bt.force_build_deck([
		{"hand": "rock", "grade": 1},
		{"hand": "scissors", "grade": 1},
		{"hand": "paper", "grade": 1},
	])

	# サトシ（左下）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:（心の声）\nデッキが勝手にセットされた……。まあ、ピー助に任せるか。")

	bt.narrator_band("サトシ:（心の声）\nよし……。ベイズ・アイを起動する……！")

	# ベイズ・アイ表示
	bt.show_bayes_eye()

	bt.narrator_band("サトシ:（心の声）\n……見える。確率が表示されてる。\nグーの確率が圧倒的に高い……。")

	# ピー助（右下）
	bt.set_bubble_side("bottom-right")
	bt.narrator_band("ピー助:\nこういう脳筋タイプはな、最初は必ずグーを出すんだよ。\n「力こそ正義」って顔に書いてあるだろ。")

	bt.narrator_band("ピー助:\n初めての実戦だ。最初の一手だけは俺が選んでやる。\nお前の手、借りるぞ。")

	# ピー助がパーを強制選択（アニメーション付き）
	var selection = await bt.force_select_hand(BattleScene.Hand.PAPER)

	# サトシ（左下）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\nうわっ、手が勝手に……！ パー……？")

	# ピー助（右下）
	bt.set_bubble_side("bottom-right")
	bt.narrator_band("ピー助:\nグーが90%だ。パーを出しゃ勝てる。\n確率が一番高い手に勝てるカードを出す。これが「予測勝ち」だ。")

	# じゃんけん実行（相手は必ずグー）
	var result = await bt.janken(selection, {"fixed": "rock"})

	bt.hide_bayes_eye()

	# サトシ（左下）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:（心の声）\n勝った……！ 本当にグーを出してきた……！\n確率通りだ……。この感覚、覚えたぞ。")

	# ピー助（右下）
	bt.set_bubble_side("bottom-right")
	bt.narrator_band("ピー助:\nよし、感覚は掴んだな。ここからは自分の力でやれ。\nデータを信じろ。")

# --- 初期表示（デッキ構築時） ---

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/deck_002.png", {"scale": 0.75, "position": [0, 230]})
	var adv = bt.character("adventurer_a")
	adv.set_portrait("res://assets/characters/stage1_battle/char09_st1_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})

# --- Outfit 3: フル装備 ---

func outfit_3(bt):
	var adv = bt.character("adventurer_a")
	adv.set_portrait("res://assets/characters/stage1_battle/char09_st1_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
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
	adv.set_portrait("res://assets/characters/stage1_battle/char09_st1_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
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
	adv.set_portrait("res://assets/characters/stage1_battle/char09_st1_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
	adv.band("くそっ……こっからが本気だ！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		adv.band("バカな……！")
	elif result == "lose":
		adv.band("ざまぁみろ！")
	else:
		adv.band("まだ終わらねぇぞ！")
