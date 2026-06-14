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
	# デッキ構築フェーズ用: カード台座のみ。対戦相手は最初の outfit で登場させる。
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})

# --- ベルカ Outfit 3: フル装備 ---

func belka_outfit_3(bt):
	var belka = bt.character("belka")
	# 最初の outfit: 対戦相手が右からフェードインで登場
	belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_001.png", {"scale": 0.39, "side": "center", "position": [20, -222], "appear_effect": "fade_slide", "appear_from": "right", "appear_duration": 0.4})
	belka.band("へっ、ボクに勝てると思ってんの？")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_002.png", {"scale": 0.39, "side": "center", "position": [0, -227]})
		belka.band("...っ！ やるじゃん...。")
		# 紙芝居 1敗目: 上脱ぎ (3枚)
		await bt.wait(0.0)
		belka.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_cloth_001.png")
		bt.bubble("くそっ・・・\n仕方ないな・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_cloth_002.png")
		bt.bubble("次は絶対お前を脱がしてやるからな！", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_cloth_003.png")
		bt.bubble("（もう負けられない・・・・）", {"side": "right"})
		bt.background("res://assets/backgrounds/prologue/bg06_prison_arena.png")
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})
	elif result == "lose":
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_003.png", {"scale": 0.39, "side": "center", "position": [0, -199]})
		belka.band("ゲハハ！ ボクの読み、甘く見んなよ。")
	else:
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_004.png", {"scale": 0.39, "side": "center", "position": [0, -194]})
		belka.band("あいこ？ ...ふーん、なかなかやるね。")

# --- ベルカ Outfit 2: 1枚脱いだ ---

func belka_outfit_2(bt):
	var belka = bt.character("belka")
	belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_005.png", {"scale": 0.39, "side": "center", "position": [0, -207]})
	belka.band("...ちっ、調子乗んなよ。ここからが本気だ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_006.png", {"scale": 0.49, "side": "center", "position": [0, -49]})
		belka.band("...マジかよ。あんた、ボクの手を読んでるだろ。")
		# 紙芝居 2敗目: ブラ脱ぎ (7枚)
		await bt.wait(0.0)
		belka.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_bra_001.png")
		bt.bubble("や、やっぱり脱がないと、ダメか？", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_bra_002.png")
		bt.bubble("ま、まぁ・・・\nルールだしな・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_bra_003.png")
		bt.bubble("脱ぐところ見るんじゃねーよ！", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_bra_004.png")
		bt.bubble("な、なぁ・・・・\nこれでいいよな・・・・", {"side": "right"})
		bt.bubble("（思ったより恥ずかしがるな・・・・）", {"side": "left"})
		bt.bubble("いいわけないだろ！", {"side": "left"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_bra_005.png")
		bt.bubble("わ、私のなんて見ても・・・・\nしょうがないだろ・・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_bra_006.png")
		bt.bubble("な、なぁ・・・\nも、もういいよな？", {"side": "right"})
		bt.bubble("いや、まだ10分は見たい。", {"side": "left"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_bra_007.png")
		bt.bubble("お前どんだけおっぱい好きなんだよ・・・・", {"side": "right"})
		bt.background("res://assets/backgrounds/prologue/bg06_prison_arena.png")
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})
	elif result == "lose":
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_007.png", {"scale": 0.39, "side": "center", "position": [0, -203]})
		belka.band("へへっ、まだまだだね。")
	else:
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_008.png", {"scale": 0.39, "side": "center", "position": [0, -201]})
		belka.band("...また引き分けかよ。しつこいヤツだな。")

# --- ベルカ Outfit 1: あと1枚 ---

func belka_outfit_1(bt):
	var belka = bt.character("belka")
	belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_009.png", {"scale": 0.39, "side": "center", "position": [0, -194]})
	belka.band("...っ！ こ、これ以上はダメだって！ 見んな！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.4})

	if result == "win":
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_010.png", {"scale": 0.39, "side": "center", "position": [0, -175]})
		belka.band("う、うそだろ...ボクが...負けた...！")
		# 紙芝居 3敗目: パンツ脱ぎ (16枚)
		await bt.wait(0.0)
		belka.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_001.png")
		bt.bubble("な、なぁ。お前の要求通りにするから\nここで終わりってことにしないか？", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_002.png")
		bt.bubble("いやいや、ルールはルールだから。", {"side": "left"})
		bt.bubble("え・・・\nいや・・・・\nちょっ・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_003.png")
		bt.bubble("ちょっと待って！\n見えちゃう！見えちゃうからっ！", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_004.png")
		bt.bubble("淡々と脱がすなーっ！", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_005.png")
		bt.bubble("お前・・・・\nこれ以上・・・", {"side": "right"})
		bt.bubble("とりあえず立ってみて", {"side": "left"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_006.png")
		bt.bubble("なぁ、もうこの辺でいいだろ？", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_007.png")
		bt.bubble("いや、ちょ・・・\nやめ・・・・\n見えちゃうっ！", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_008.png")
		bt.bubble("やだぁ・・・・・・", {"side": "right"})
		bt.bubble("とりあえず後ろに手を回そうか", {"side": "left"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_009.png")
		bt.bubble("（気の強い女が涙目で全裸・・・・\nこれは良いものだ・・・・）", {"side": "left"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_010.png")
		bt.bubble("（もう全部見られちゃった・・・\n誰にも見られたことないのに・・・・）", {"side": "right"})
		bt.bubble("ものは相談だが・・・・\nこれを履いてみてくれないか？", {"side": "left"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_011.png")
		bt.bubble("靴下？今更靴下履いたところで\n焼け石に水だけど・・・・\nまぁ全裸よりマシかな・・・", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_012.png")
		bt.bubble("こんな感じでいいのか？", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_013.png")
		bt.bubble("あれ？なんか・・・\n全裸より・・・恥ずかしいかも・・・", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_014.png")
		bt.bubble("（なんで・・・なんで靴下履いた方が\n恥ずかしいんだ・・・・？）", {"side": "right"})
		bt.bubble("さぁ、足を開いて！", {"side": "left"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_015.png")
		bt.bubble("こ・・・こう・・・か？", {"side": "right"})
		bt.background("res://assets/characters/main/belka/clothed/belka_undressing_panty_016.png")
		bt.bubble("（凄ぇ・・・・先端着衣の威力・・・\nパネぇっす・・・・・）", {"side": "left"})
		bt.background("res://assets/backgrounds/prologue/bg06_prison_arena.png")
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})
	elif result == "lose":
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_011.png", {"scale": 0.39, "side": "center", "position": [0, -202]})
		belka.band("...ふぅ。危なかった...。")
	else:
		belka.set_portrait("res://assets/characters/main/belka/nude/belka_nude_012.png", {"scale": 0.39, "side": "center", "position": [0, -217]})
		belka.band("...まだ続くのかよ...勘弁してくれ...。")

func get_lose_behavior() -> String:
	return "abort"

func get_lose_redirect() -> Dictionary:
	return {"type": "guild_home"}

func get_farewell(result: String) -> Dictionary:
	if result == "lose":
		return {
			"narration": "サトシはベルカに敗北した。\n盗賊団のアジトから撤退するしかない...。",
			"portrait": "res://assets/characters/main/belka/nude/belka_nude_003.png",
			"portrait_scale": 0.64,
			"text": "ゲハハ！ ボクに勝てると思ったのかよ？\n出直してきな！",
		}
	return {}
