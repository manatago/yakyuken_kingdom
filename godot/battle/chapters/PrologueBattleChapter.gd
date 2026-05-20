extends BattleChapterBase

var _first_call := {"outfit_3": true, "outfit_2": true, "outfit_1": true}

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

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1},
		{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1},
		{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1},
	]

func get_opponent_deck_size() -> int:
	return 9

func get_player_deck_size() -> int:
	return 9

func can_lose_cards() -> bool:
	return false

func can_gain_cards() -> bool:
	return false

func get_gold_reward() -> Dictionary:
	return {"min": 10, "max": 30}

# --- チュートリアル ---

func tutorial(bt):
	var matilda = bt.character("matilda")
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_024.png", {"scale": 0.80, "side": "center", "position": [0, -160]})

	bt.set_bubble_side("left")

	matilda.band("周りの風景が変わっただろう。これがこの世界のバトルシステム「じゃんけん」だ。")
	# アイテムボックスの説明
	bt.highlight("item_panel")
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_007.png", {"scale": 0.914, "side": "center", "position": [0, -199]})
	matilda.band("左にあるのがアイテムボックスだ。")
	matilda.band("バトル中に使えるアイテムがここに表示される。", {"append": true})
	matilda.band("今は何もないけど、運が良ければ勝率をあげるアイテムなんかを手に入れることができる", {"append": true})
	# matilda.band("勝率をあげるアイテムが代表的だな。運が良ければ手に入れることができる。", {"append": true})
	matilda.band("噂じゃ、伝説のアイテムなるものがあるみたいだが、、、眉唾もんだ。", {"append": true})
	bt.unhighlight()

	# カードの説明
	bt.highlight("hand_panel", {"offset_x": 50})
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_008.png", {"scale": 0.914, "side": "center", "position": [0, -199]})
	matilda.band("右にあるのが手持ちカードだ。")
	matilda.band("グー、チョキ、パーの3種類がある。", {"append": true})
	matilda.band("カード自体にはグレードがある。", {"append": true})
	matilda.band("同じ手を出した時、グレードが高い方が勝つのさ。", {"append": true})
	bt.unhighlight()

	# デッキ構築の説明
	bt.highlight("card_bar")
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_009.png", {"scale": 0.914, "side": "center", "position": [0, -199]})
	matilda.band("下のデッキに9枚セットしな。手持ちからカードを選んでデッキに入れるんだ。")
	matilda.band("カードボックスのカードをクリックするとデッキに登録される。", {"append": true})
	matilda.band("デッキのカードをクリックするとアイテムボックスに戻るんだ。", {"append": true})
	matilda.band("面倒なら「自動」ボタンで一発だ。")
	matilda.band("「準備完了」をクリックすると、デッキが完成する。", {"append": true})
	bt.unhighlight()
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_005.png", {"scale": 0.40, "side": "center", "position": [0, -199]})

	# デッキ構築を実行させる
	await bt.build_deck()

	# カード選択の説明
	bt.highlight("card_bar")
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_009.png", {"scale": 0.914, "side": "center", "position": [0, -199]})
	matilda.band("よし、デッキができたな。次はカードの選択だ。")
	matilda.band("「カードを選択してください」って表示されたら、", {"append": true})
	matilda.band("出したいカードをクリックするとカードが選択される。", {"append": true})
	matilda.band("「勝負！」を押すと、じゃんけんが始まる。", {"append": true})
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_011.png", {"scale": 0.40, "side": "center", "position": [0, -348]})
	matilda.band("最初は特別にグーを出してやるから、お前はパーを出しな。", {"append": true})
	bt.unhighlight()
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_005.png", {"scale": 0.40, "side": "center", "position": [0, -199]})
	var selection = await bt.select_hand()


	# 勝負の説明
	bt.highlight("action_prompt")
	bt.unhighlight()

	# 実際にじゃんけん（必ずグー）
	var result = await bt.janken(selection, {"fixed": "rock"})

	if result == "win":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_013.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		matilda.band("ほら、勝っただろ？")
		bt.highlight("item_panel")
		# matilda.band("勝つと相手のカードをもらえるんだ。")
		# matilda.band("負けたら逆に取られるから気をつけな。")
		bt.unhighlight()
	elif result == "lose":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_012.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		matilda.band("...あんた、パーを出せって言っただろ。")
		matilda.band("まぁいい、次で取り返しな。", {"append": true})
	else:
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_006.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		matilda.band("あいこか。同じグレードだと引き分けになる。")

	# HPの説明
	bt.highlight("opponent_hp", {"offset_y": 20})
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_010.png", {"scale": 0.914, "side": "center", "position": [0, -199]})

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
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_006.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
	matilda.band("もう一回やってみな。\n今度は好きなカードを選びな。")
	selection = await bt.select_hand()
	result = await bt.janken(selection, {"win_rate": 0.8})

	if result == "win":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_013.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		matilda.band("思ったよりやるな。")
	else:
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_012.png", {"scale": 0.4, "side": "center", "position": [0, -199]})
		matilda.band("見た目通り弱いな。")

	# 締め
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_010.png", {"scale": 0.914, "side": "center", "position": [0, -199]})
	matilda.band("これがじゃんけんバトルの基本だ。", {"append": true})
	matilda.band("カードの使い方、グレードの活かし方...", {"append": true})
	matilda.band("勝つための戦略を考えるのが醍醐味さ。", {"append": true})
	matilda.band("ルールは理解したか？本番はもっと厳しいからな。", {"append": true})

# --- 初期表示（デッキ構築時） ---

func setup_scene(bt):
	# デッキ構築フェーズ用: カード台座のみ。対戦相手は最初の outfit で登場させる。
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})

# --- Outfit 3: フル装備 ---

func outfit_3(bt):
	var matilda = bt.character("matilda")
	# 最初の outfit: 対戦相手が右からフェードインで登場
	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_024.png", {"scale": 0.80, "side": "center", "position": [0, -160], "appear_effect": "fade_slide", "appear_from": "right", "appear_duration": 0.4})
	matilda.band("さあ、始めようか。手加減はしないよ。")

	var selection = await bt.select_hand()
	var ai_opts := {"fixed": "rock"} if _first_call["outfit_3"] else {}
	_first_call["outfit_3"] = false
	var result = await bt.janken(selection, ai_opts)

	if result == "win":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_014.png", {"scale": 0.40, "side": "center", "position": [0, -255]})
		matilda.band("くっ、変態の癖に。")
		#todo:5枚の紙芝居を入れる
		await bt.play_video("res://assets/videos/prologue_win_1.ogv")

	elif result == "lose":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_015.png", {"scale": 0.40, "side": "center", "position": [0, -255]})
		matilda.band("やっぱり、真剣勝負も弱いわね。ふっ。")

	else:
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_012.png", {"scale": 0.40, "side": "center", "position": [0, -255]})
		matilda.band("あいこか。首がつながったな。")

# --- Outfit 2: 1枚脱いだ状態 ---

func outfit_2(bt):
	var matilda = bt.character("matilda")

	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_016.png", {"scale": 0.80, "side": "center", "position": [0, -260]})
	matilda.band("あんまり、じろじろ見るんじゃないぞ")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.6})

	if result == "win":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_017.png", {"scale": 0.80, "side": "center", "position": [0, -215]})
		matilda.band("...っ、負けた...")
		#todo:5枚の紙芝居を入れる
		await bt.play_video("res://assets/videos/prologue_win_2.ogv")
	elif result == "lose":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_018.png", {"scale": 0.8, "side": "center", "position": [0, -199]})
		matilda.band("よし、勝ったぞ")
	else:
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_019.png", {"scale": 0.8, "side": "center", "position": [0, -210]})
		matilda.band("あいこか。命拾いしたな。")

# --- Outfit 1: あと1枚 ---

func outfit_1(bt):
	var matilda = bt.character("matilda")

	matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_020.png", {"scale": 0.80, "side": "center", "position": [0, -204],})
	matilda.band("...変態、こっちをみるな")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.6})

	if result == "win":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_021.png", {"scale": 0.80, "side": "center", "position": [0, -204]})
		matilda.band("...変態に見られる...。")
		#todo:5枚の紙芝居を入れる
		await bt.play_video("res://assets/videos/prologue_win_3.ogv")
	elif result == "lose":
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_022.png", {"scale": 0.80, "side": "center", "position": [0, -204]})
		matilda.band("ふう、勝ったぞ。")
	else:
		matilda.set_portrait("res://assets/characters/mob/guard/default/guard_default_023.png", {"scale": 0.80, "side": "center", "position": [0, -204]})
		matilda.band("さっさと、次やるよ。")

func get_lose_behavior() -> String:
	return "redirect"

func get_lose_redirect() -> Dictionary:
	return {
		"type": "story_sequence",
		"sequence_id": "prologue_battle_lose",
		"choices": ["再挑戦する", "ホームに戻る"],
	}

func get_farewell(_result: String) -> Dictionary:
	# 敗北演出はストーリーシーケンス側で行うため farewell は空
	return {}
