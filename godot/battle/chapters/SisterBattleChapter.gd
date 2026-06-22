extends BattleChapterBase

func get_opponent_id() -> String:
	return "sister_head"

func get_opponent_name() -> String:
	return "シスター長"

func get_battle_background() -> String:
	return "res://assets/backgrounds/subevent2/bg05_church_peep_room.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	# シスター長: 心理戦型 — バランス + グレード混在
	return [
		{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 2},
		{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 2},
		{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 2},
	]

func get_opponent_deck_size() -> int:
	return 7

func get_player_deck_size() -> int:
	return 7

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	# 心理戦型: パーを好む（迷いを突く）
	return {"paper": 0.3}

func get_gold_reward() -> Dictionary:
	return {"min": 50, "max": 80}

# --- エントリーポイント ---

func setup_scene(bt):
	sister_setup_scene(bt)

func outfit_3(bt):
	await sister_outfit_3(bt)

func outfit_2(bt):
	await sister_outfit_2(bt)

func outfit_1(bt):
	await sister_outfit_1(bt)

# =============================================
# シスター長戦（サブイベント2 ボス）
# 専用バトル立ち絵 12 枚: 3 outfit × (開始/勝/負/あいこ)
#   001=開始, 002=プレイヤー勝利, 003=プレイヤー敗北, 004=あいこ
# =============================================

const SISTER_CLOTHED_START   := "res://assets/characters/main/sister_head/clothed/sister_head_clothed_janken_001.png"
const SISTER_CLOTHED_WIN     := "res://assets/characters/main/sister_head/clothed/sister_head_clothed_janken_002.png"
const SISTER_CLOTHED_LOSE    := "res://assets/characters/main/sister_head/clothed/sister_head_clothed_janken_003.png"
const SISTER_CLOTHED_DRAW    := "res://assets/characters/main/sister_head/clothed/sister_head_clothed_janken_004.png"
const SISTER_UNDERWEAR_START := "res://assets/characters/main/sister_head/underwear/sister_head_underwear_janken_001.png"
const SISTER_UNDERWEAR_WIN   := "res://assets/characters/main/sister_head/underwear/sister_head_underwear_janken_002.png"
const SISTER_UNDERWEAR_LOSE  := "res://assets/characters/main/sister_head/underwear/sister_head_underwear_janken_003.png"
const SISTER_UNDERWEAR_DRAW  := "res://assets/characters/main/sister_head/underwear/sister_head_underwear_janken_004.png"
const SISTER_TOPLESS_START   := "res://assets/characters/main/sister_head/topless/sister_head_topless_janken_001.png"
const SISTER_TOPLESS_WIN     := "res://assets/characters/main/sister_head/topless/sister_head_topless_janken_002.png"
const SISTER_TOPLESS_LOSE    := "res://assets/characters/main/sister_head/topless/sister_head_topless_janken_003.png"
const SISTER_TOPLESS_DRAW    := "res://assets/characters/main/sister_head/topless/sister_head_topless_janken_004.png"

func sister_setup_scene(bt):
	# デッキ構築フェーズ用: カード台座のみ。対戦相手は最初の outfit で登場させる。
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})

# --- シスター長 Outfit 3: フル装備 ---

func sister_outfit_3(bt):
	var sister = bt.character("sister_head")
	# 最初の outfit: 対戦相手が右からフェードインで登場
	sister.set_portrait(SISTER_CLOTHED_START, {"scale": 0.42, "side": "center", "position": [0, 0], "appear_effect": "fade_slide", "appear_from": "right", "appear_duration": 0.4})
	sister.band("...神の御前で、正直になりましょうか。\n迷いは、私にはお見通しよ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		sister.set_portrait(SISTER_CLOTHED_WIN, {"scale": 0.42, "side": "center", "position": [0, 11]})
		sister.band("...あら。悪運だけはお強いようね。")
		# 紙芝居 1敗目: 上脱ぎ (4枚)
		await bt.wait(0.0)
		sister.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_cloth_001.png")
		bt.bubble("この私が脱ぐことになるなんて・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_cloth_002.png")
		bt.bubble("(男の人に見られちゃうなんて・・・・)", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_cloth_003.png")
		bt.bubble("な、なんか、・・・\nうまく脱げなくて・・・", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_cloth_004.png")
		bt.bubble("こ、これでいいんですよ・・・ね・・・", {"side": "right"})
		bt.background("res://assets/backgrounds/subevent2/bg05_church_peep_room.png")
		# 紙芝居のバブル群を UI 非表示のまま消化してから UI を戻す
		await bt.wait(0.0)
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	elif result == "lose":
		sister.set_portrait(SISTER_CLOTHED_LOSE, {"scale": 0.42, "side": "center", "position": [0, 6]})
		sister.band("ふふ。読み通りよ。\n...あなたの迷い、手に取るように分かる。")
	else:
		sister.set_portrait(SISTER_CLOTHED_DRAW, {"scale": 0.42, "side": "center", "position": [0, 14]})
		sister.band("あら、偶然ね。...次は、そうはいきませんわ。")

# --- シスター長 Outfit 2: 1枚脱いだ ---

func sister_outfit_2(bt):
	var sister = bt.character("sister_head")
	sister.set_portrait(SISTER_UNDERWEAR_START, {"scale": 0.80, "side": "center", "position": [0, -71]})
	sister.band("...こんなはずでは、と思ってる？\nふふ、ここからが本番ですわ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		sister.set_portrait(SISTER_UNDERWEAR_WIN, {"scale": 0.80, "side": "center", "position": [0, -66]})
		sister.band("...まさか、私の読みを裏切るなんて。")
		# 紙芝居 2敗目: ブラ脱ぎ (7枚)
		await bt.wait(0.0)
		sister.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_bra_001.png")
		bt.bubble("（ま、まさかおっぱい見せることになるなんて・・・）", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_bra_002.png")
		bt.bubble("・・・・・・・・・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_bra_003.png")
		bt.bubble("や、やっぱブラ・・・外さなきゃ\nだめ・・ですか？", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_bra_004.png")
		bt.bubble("こ・・・これでいですよね？", {"side": "right"})
		bt.bubble("いや、乳首までじっくり\n確認しないと・・・", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_bra_005.png")
		bt.bubble("はぁ・・・はぁっ・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_bra_006.png")
		bt.bubble("も、もう・・・いいですか？", {"side": "right"})
		bt.bubble("だめです。手を下ろして・・・", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_bra_007.png")
		bt.bubble("はい・・・・・・", {"side": "right"})
		bt.background("res://assets/backgrounds/subevent2/bg05_church_peep_room.png")
		# 紙芝居のバブル群を UI 非表示のまま消化してから UI を戻す
		await bt.wait(0.0)
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	elif result == "lose":
		sister.set_portrait(SISTER_UNDERWEAR_LOSE, {"scale": 0.80, "side": "center", "position": [0, -45]})
		sister.band("ご覧なさい。これが「神の裁き」よ。")
	else:
		sister.set_portrait(SISTER_UNDERWEAR_DRAW, {"scale": 0.80, "side": "center", "position": [0, -40]})
		sister.band("...あいこ。面白い冒険者ね、あなた。")

# --- シスター長 Outfit 1: あと1枚 ---

func sister_outfit_1(bt):
	var sister = bt.character("sister_head")
	sister.set_portrait(SISTER_TOPLESS_START, {"scale": 0.80, "side": "center", "position": [0, -59]})
	sister.band("...っ！ こんな...こんな屈辱、許さない...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.4})

	if result == "win":
		sister.set_portrait(SISTER_TOPLESS_WIN, {"scale": 0.80, "side": "center", "position": [0, -55]})
		sister.band("...そんな。わたしが...負けた...。")
		# 紙芝居 3敗目: パンツ脱ぎ (16枚)
		await bt.wait(0.0)
		sister.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_001.png")
		bt.bubble("これ・・・・脱ぐん・・・ですよね・・・・", {"side": "right"})
		bt.bubble("ルールですからね。", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_002.png")
		bt.bubble("わ・・・わかりました・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_003.png")
		bt.bubble("ほ、本当に、脱いじゃいますよ・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_004.png")
		bt.bubble("後ろから見るのは反則です！", {"side": "right"})
		bt.bubble("いや、別にそんなルールないし・・・", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_005.png")
		bt.bubble("前もだ、だめです！", {"side": "right"})
		bt.bubble("いや、どっちから見ろと・・・", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_006.png")
		bt.bubble("もう・・・おとなしくしててください！", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_007.png")
		bt.bubble("（これ脱いじゃったら・・・・もう・・・）", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_008.png")
		bt.bubble("脱ぎました・・・\nこれで終わり・・・ですよね？", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_009.png")
		bt.bubble("え・・・いや・・・\n私のなんて見ても・・・\nつまんないですよ？", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_010.png")
		bt.bubble("ほ、ほら・・・・\n仮にも神に仕える身ですし", {"side": "right"})
		bt.bubble("だからこそより興奮します。", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_011.png")
		bt.bubble("こ、これで、・・・・・", {"side": "right"})
		bt.bubble("よく見えないですね。", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_012.png")
		bt.bubble("そんな・・・・\n意地悪言わないで・・・・", {"side": "right"})
		bt.bubble("もっと足を開いて！", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_013.png")
		bt.bubble("ひんっ・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_014.png")
		bt.bubble("も、もうこれ以上は・・・・", {"side": "right"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_015.png")
		bt.bubble("な、何をするんですか！", {"side": "right"})
		bt.bubble("いや、近眼なもので・・・", {"side": "left"})
		bt.background("res://assets/characters/main/sister_head/clothed/sister_head_undressing_panty_016.png")
		bt.bubble("（・・・・・・・・）", {"side": "right"})
		bt.background("res://assets/backgrounds/subevent2/bg05_church_peep_room.png")
		# 紙芝居のバブル群を UI 非表示のまま消化してから UI を戻す
		await bt.wait(0.0)
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	elif result == "lose":
		sister.set_portrait(SISTER_TOPLESS_LOSE, {"scale": 0.80, "side": "center", "position": [0, -46]})
		sister.band("...ふう。危なかった。\nあなたも、もう終わりよ。")
	else:
		sister.set_portrait(SISTER_TOPLESS_DRAW, {"scale": 0.80, "side": "center", "position": [0, -64]})
		sister.band("...まだ、粘るの？ 往生際が悪いですわ。")

func get_lose_behavior() -> String:
	return "redirect"

func get_lose_redirect() -> Dictionary:
	# 敗北時は地下牢→脱獄→ギルド帰還シーケンス → 共通ロスト・ナレーション
	# → ギルドホーム送還
	return {
		"type": "story_sequence_then_guild_home",
		"sequence_id": "subevent2_battle_lose",
	}

func get_farewell(result: String) -> Dictionary:
	# 敗北演出はシーケンス側に委譲（farewell は空）
	return {}
