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

# --- チュートリアル（ベイズ・アイ） ---

func tutorial(bt):
	var adv = bt.character("adventurer_a")
	adv.set_portrait("res://assets/characters/stage1/adventurer_a_battle_001.png", {"scale": 0.4, "side": "center", "position": [0, -199]})

	bt.set_bubble_side("left")

	# ピー助がベイズ・アイの使い方を教える
	bt.narrator_band("ピー助:（サトシの肩から）\nおい、サトシ。初めての実戦だ。ベイズ・アイの使い方を教えてやる。")

	bt.narrator_band("ピー助:\nまず、相手のカード構成をスキャンする。\nこいつのデッキはノーマルカードばかりだ。グレード差で負けることはない。")

	# デッキ構築
	bt.highlight("hand_panel", {"offset_x": 50})
	bt.narrator_band("ピー助:\n手持ちのカードを確認しろ。今のお前もノーマルばかりだが、\n数の配分が重要だ。相手の傾向に合わせてデッキを組め。")
	bt.unhighlight()

	bt.highlight("card_bar")
	bt.narrator_band("ピー助:\nデッキに9枚セットしろ。分からなければ「自動」でいい。")
	bt.unhighlight()

	await bt.build_deck()

	# カード選択の説明
	bt.narrator_band("ピー助:\nよし、デッキができた。次はカードを選ぶ番だ。")

	bt.narrator_band("ピー助:\nベイズ・アイが起動してるから、相手の次の手の確率が見えるはずだ。\n確率が高い手に勝てるカードを出せ。それが「予測勝ち」だ。")

	bt.narrator_band("ピー助:\nまずは1回やってみろ。こいつは単純だから読みやすいはずだ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.8})

	if result == "win":
		bt.narrator_band("ピー助:\nゲコッ！ いいぞ！ データを信じれば勝てる。それがベイズ・アイだ。")
	elif result == "lose":
		bt.narrator_band("ピー助:\nおいおい……。確率はあくまで「傾向」だ。100%じゃない。\nだが何度もやれば、確率通りに収束する。もう一回だ。")
	else:
		bt.narrator_band("ピー助:\nあいこか。同じグレードだとこうなる。\nグレードの高いカードを手に入れれば、あいこでも勝てるようになる。")

	# もう一回
	bt.narrator_band("ピー助:\nもう一回やるぞ。今度は自分で確率を読んで判断しろ。")
	selection = await bt.select_hand()
	result = await bt.janken(selection, {"win_rate": 0.7})

	if result == "win":
		bt.narrator_band("ピー助:\nよし、感覚を掴んだな。お前、筋がいいぞ。")
	else:
		bt.narrator_band("ピー助:\nまあ、実戦は経験がモノを言う。数をこなせ。")

	# 締め
	bt.narrator_band("ピー助:\nベイズ・アイの基本は以上だ。\n確率を見て、最適な手を選ぶ。単純だが、奥は深い。")
	bt.narrator_band("ピー助:\nさあ、本番だ。こいつを叩きのめしてやれ。")

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
