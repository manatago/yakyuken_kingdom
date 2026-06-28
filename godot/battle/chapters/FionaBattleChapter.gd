extends BattleChapterBase

# Subevent3 ボス: フィオナ（呪われた鎧、加護弱体化後の通常戦）
# 単一バトル（ミニゲーム成功で加護弱体→通常戦）

# 野球拳バトル用 立ち絵 (3 ステージ × 4 結果 = 12 枚)
const FIONA_CLOTHED_START   := "res://assets/characters/main/fiona/clothed/fiona_clothed_janken_001.png"
const FIONA_CLOTHED_WIN     := "res://assets/characters/main/fiona/clothed/fiona_clothed_janken_002.png"
const FIONA_CLOTHED_LOSE    := "res://assets/characters/main/fiona/clothed/fiona_clothed_janken_003.png"
const FIONA_CLOTHED_DRAW    := "res://assets/characters/main/fiona/clothed/fiona_clothed_janken_004.png"
const FIONA_UNDERWEAR_START := "res://assets/characters/main/fiona/underwear/fiona_underwear_janken_001.png"
const FIONA_UNDERWEAR_WIN   := "res://assets/characters/main/fiona/underwear/fiona_underwear_janken_002.png"
const FIONA_UNDERWEAR_LOSE  := "res://assets/characters/main/fiona/underwear/fiona_underwear_janken_003.png"
const FIONA_UNDERWEAR_DRAW  := "res://assets/characters/main/fiona/underwear/fiona_underwear_janken_004.png"
const FIONA_TOPLESS_START   := "res://assets/characters/main/fiona/topless/fiona_topless_janken_001.png"
const FIONA_TOPLESS_WIN     := "res://assets/characters/main/fiona/topless/fiona_topless_janken_002.png"
const FIONA_TOPLESS_LOSE    := "res://assets/characters/main/fiona/topless/fiona_topless_janken_003.png"
const FIONA_TOPLESS_DRAW    := "res://assets/characters/main/fiona/topless/fiona_topless_janken_004.png"

func get_opponent_id() -> String:
	return "fiona"

func get_opponent_name() -> String:
	return "フィオナ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/subevent3/bg_noble_room.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 2}, {"hand": "rock", "grade": 2},
		{"hand": "scissors", "grade": 2}, {"hand": "scissors", "grade": 2},
		{"hand": "paper", "grade": 2}, {"hand": "paper", "grade": 2}, {"hand": "paper", "grade": 3},
	]

func get_opponent_deck_size() -> int:
	return 7

func get_player_deck_size() -> int:
	return 7

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {"paper": 0.35}

func get_gold_reward() -> Dictionary:
	return {"min": 100, "max": 150}

func setup_scene(bt):
	# デッキ構築フェーズ用: カード台座のみ。対戦相手は最初の outfit で登場させる。
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})

func outfit_3(bt):
	var fiona = bt.character("fiona")
	# 最初の outfit: 対戦相手が右からフェードインで登場
	fiona.set_portrait(FIONA_CLOTHED_START, {"scale": 0.77, "side": "center", "position": [0, -60], "appear_effect": "fade_slide", "appear_from": "right", "appear_duration": 0.4})
	fiona.band("...は、はい...お、お願い、します...。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.55})

	if result == "win":
		fiona.set_portrait(FIONA_CLOTHED_WIN, {"scale": 0.73, "side": "center", "position": [0, -110]})
		fiona.band("...あ...！")
		# 紙芝居 1敗目: 服を脱ぐ (4枚)
		await bt.wait(0.0)
		fiona.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_clothes_001.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_clothes_002.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_clothes_003.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_clothes_004.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/backgrounds/subevent3/bg_noble_room.png")
		# 紙芝居のバブル群を UI 非表示のまま消化してから UI を戻す
		await bt.wait(0.0)
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	elif result == "lose":
		fiona.set_portrait(FIONA_CLOTHED_LOSE, {"scale": 0.76, "side": "center", "position": [0, -95]})
		fiona.band("...あの、ご、ごめんなさい...。")
	else:
		fiona.set_portrait(FIONA_CLOTHED_DRAW, {"scale": 0.77, "side": "center", "position": [0, -80]})
		fiona.band("...あ、あいこ、です...。")

func outfit_2(bt):
	var fiona = bt.character("fiona")
	fiona.set_portrait(FIONA_UNDERWEAR_START, {"scale": 0.77, "side": "center", "position": [0, -77]})
	fiona.band("...呪い、まだ、効いて...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		fiona.set_portrait(FIONA_UNDERWEAR_WIN, {"scale": 0.77, "side": "center", "position": [0, -82]})
		fiona.band("...や、やった...？")
		# 紙芝居 2敗目: ブラを脱ぐ (5枚)
		await bt.wait(0.0)
		fiona.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_bra_001.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_bra_002.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_bra_003.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_bra_004.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_bra_005.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/backgrounds/subevent3/bg_noble_room.png")
		# 紙芝居のバブル群を UI 非表示のまま消化してから UI を戻す
		await bt.wait(0.0)
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	elif result == "lose":
		fiona.set_portrait(FIONA_UNDERWEAR_LOSE, {"scale": 0.77, "side": "center", "position": [0, -85]})
		fiona.band("...ご、ごめん、なさい...！")
	else:
		fiona.set_portrait(FIONA_UNDERWEAR_DRAW, {"scale": 0.77, "side": "center", "position": [0, -93]})
		fiona.band("...！")

func outfit_1(bt):
	var fiona = bt.character("fiona")
	fiona.set_portrait(FIONA_TOPLESS_START, {"scale": 0.77, "side": "center", "position": [0, -79]})
	fiona.band("...ぁ...こ、これで、最後...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.45})

	if result == "win":
		fiona.set_portrait(FIONA_TOPLESS_WIN, {"scale": 0.76, "side": "center", "position": [0, -102]})
		fiona.band("...！ や、やった、です...呪いが、解けます...！")
		# 紙芝居 3敗目: パンツを脱ぐ (13枚)
		await bt.wait(0.0)
		fiona.leave()
		bt.deck("")
		bt.set_battle_ui_visible(false)
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_001.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_002.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_003.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_004.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_005.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_006.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_007.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_008.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_009.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_010.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_011.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_012.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/characters/main/fiona/undressing/fiona_undressing_panty_013.png")
		bt.bubble("...", {"side": "right"})
		bt.background("res://assets/backgrounds/subevent3/bg_noble_room.png")
		# 紙芝居のバブル群を UI 非表示のまま消化してから UI を戻す
		await bt.wait(0.0)
		bt.set_battle_ui_visible(true)
		bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.5, "position": [0, 180]})
	elif result == "lose":
		fiona.set_portrait(FIONA_TOPLESS_LOSE, {"scale": 0.77, "side": "center", "position": [0, -84]})
		fiona.band("...ぁ...そんな...呪いが、まだ...！")
	else:
		fiona.set_portrait(FIONA_TOPLESS_DRAW, {"scale": 0.77, "side": "center", "position": [0, -67]})
		fiona.band("...！")

func get_lose_behavior() -> String:
	return "redirect"

func get_lose_redirect() -> Dictionary:
	# 敗北時: 呪い復活→セバス絶叫→ギルドホーム
	return {
		"type": "story_sequence_then_guild_home",
		"sequence_id": "subevent3_battle_lose",
	}

func get_farewell(_result: String) -> Dictionary:
	return {}
