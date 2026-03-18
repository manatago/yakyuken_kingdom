extends BattleChapterBase

func get_opponent_id() -> String:
	return "matilda"

func get_opponent_name() -> String:
	return "マチルダ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/prologue/bg05_prison_cell.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

# --- 初期表示 ---

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/deck-002.png", {"scale": 0.75, "position": [0, 230]})
	var matilda = bt.character("matilda")
	matilda.set_portrait("res://assets/characters/prologue_battle/char04_pg_battle_001.png", {"scale": 0.95, "side": "center", "position": [0, -197]})

# --- チュートリアル ---

func tutorial(bt):
	var matilda = bt.character("matilda")
	matilda.set_portrait("res://assets/characters/prologue_battle/char04_pg_battle_001.png", {"scale": 0.95, "side": "center", "position": [0, -197]})

	bt.set_bubble_side("left")

	matilda.band("周りの風景が変わっただろう。これがこの世界のバトルシステム「じゃんけん」だ。")
	# アイテムボックスの説明
	bt.highlight("item_panel")
	matilda.band("左にあるのがアイテムボックスだ。")
	matilda.band("バトル中に使えるアイテムがここに表示される。", {"append": true})
	matilda.band("今は何もないけど、運が良ければ勝率をあげるアイテムなんかを手に入れることができる", {"append": true})
	# matilda.band("勝率をあげるアイテムが代表的だな。運が良ければ手に入れることができる。", {"append": true})
	matilda.band("噂じゃ、伝説のアイテムなるものがあるみたいだが、、、眉唾もんだ。", {"append": true})
	bt.unhighlight()

	# カードの説明
	bt.highlight("hand_panel", {"offset_x": 50})
	matilda.band("右にあるのが手持ちカードだ。")
	matilda.band("グー、チョキ、パーの3種類がある。", {"append": true})
	matilda.band("カード自体にはグレードがある。", {"append": true})
	matilda.band("同じ手を出した時、グレードが高い方が勝つのさ。", {"append": true})
	bt.unhighlight()

	# デッキ構築の説明
	bt.highlight("card_bar")
	matilda.band("下のデッキに9枚セットしな。手持ちからカードを選んでデッキに入れるんだ。")
	matilda.band("カードボックスのカードをクリックするとデッキに登録される。", {"append": true})
	matilda.band("デッキのカードをクリックするとアイテムボックスに戻るんだ。", {"append": true})
	matilda.band("面倒なら「自動」ボタンで一発だ。")
	matilda.band("「準備完了」をクリックすると、デッキが完成する。", {"append": true})
	bt.unhighlight()

	# デッキ構築を実行させる
	await bt.build_deck()

	# カード選択の説明
	bt.highlight("card_bar")
	matilda.band("よし、デッキができたな。次はカードの選択だ。")
	matilda.band("「カードを選択してください」って表示されたら、", {"append": true})
	matilda.band("出したいカードをクリックするとカードが選択される。", {"append": true})
	matilda.band("「勝負！」を押すと、じゃんけんが始まる。", {"append": true})
	matilda.band("最初は特別にグーを出してやるから、お前はパーを出しな。", {"append": true})
	bt.unhighlight()

	var selection = await bt.select_hand()

	# 勝負の説明
	bt.highlight("action_prompt")
	bt.unhighlight()

	# 実際にじゃんけん（必ずグー）
	var result = await bt.janken(selection, {"fixed": "rock"})

	if result == "win":
		matilda.band("ほら、勝っただろ？")
		bt.highlight("item_panel")
		# matilda.band("勝つと相手のカードをもらえるんだ。")
		# matilda.band("負けたら逆に取られるから気をつけな。")
		bt.unhighlight()
	elif result == "lose":
		matilda.band("……あんた、パーを出せって言っただろ。")
		matilda.band("まぁいい、次で取り返しな。", {"append": true})
	else:
		matilda.band("あいこか。同じグレードだと引き分けになる。")

	# HPの説明
	bt.highlight("opponent_hp", {"offset_y": 20})
	matilda.band("カードで勝負がつくと、どちらかのHPが減る。")
	matilda.band("上が相手のHPだ。", {"append": true})
	matilda.band("勝負に勝つと相手のHPが減る", {"append": true})
	bt.unhighlight()
	bt.highlight("player_hp")
	matilda.band("右下があんたのHPだ。")
	matilda.band("勝負に負けると自分のHPが減る", {"append": true})
	matilda.band("3回負けたらゲームオーバーだ。", {"append": true})
	matilda.band("逆に相手を3回倒せば勝ちさ。", {"append": true})
	bt.unhighlight()

	# もう一回練習
	matilda.band("もう一回やってみな。\n今度は好きなカードを選びな。")
	selection = await bt.select_hand()
	result = await bt.janken(selection, {"win_rate": 0.8})

	if result == "win":
		matilda.band("思ったよりやるな。")
	else:
		matilda.band("見た目通り弱いな。")

	# 締め
	matilda.band("これがじゃんけんバトルの基本だ。", {"append": true})
	matilda.band("カードの使い方、グレードの活かし方……", {"append": true})
	matilda.band("勝つための戦略を考えるのが醍醐味さ。", {"append": true})
	matilda.band("ルールは理解したか？本番はもっと厳しいからな。", {"append": true})

# --- Outfit 3: フル装備 ---

func outfit_3(bt):
	var matilda = bt.character("matilda")
	matilda.band("さあ、始めようか。手加減はしないよ。最初はグー！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"fixed": "rock"})

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
	var result = await bt.janken(selection, {"win_rate": 0.6})

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
	var result = await bt.janken(selection, {"win_rate": 0.6})

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
