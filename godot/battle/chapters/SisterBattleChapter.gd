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
# ※専用バトル立ち絵が未作成のため、subevent2/ の感情差分画像を流用
# =============================================

const SISTER_BATTLE_NORMAL := "res://assets/characters/subevent2/sister_head_001.png"
const SISTER_BATTLE_SARCASM := "res://assets/characters/subevent2/sister_head_002.png"
const SISTER_BATTLE_SAD := "res://assets/characters/subevent2/sister_head_003.png"
const SISTER_BATTLE_ANGRY := "res://assets/characters/subevent2/sister_head_004.png"
const SISTER_BATTLE_COMPOSED := "res://assets/characters/subevent2/sister_head_005.png"
const SISTER_BATTLE_DEFEAT := "res://assets/characters/subevent2/sister_head_006.png"
const SISTER_BATTLE_SHOUT := "res://assets/characters/subevent2/sister_head_007.png"
const SISTER_BATTLE_LAUGH := "res://assets/characters/subevent2/sister_head_008.png"

func sister_setup_scene(bt):
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})
	var sister = bt.character("sister_head")
	sister.set_portrait(SISTER_BATTLE_NORMAL, {"scale": 0.60, "side": "center", "position": [0, -260]})

# --- シスター長 Outfit 3: フル装備 ---

func sister_outfit_3(bt):
	var sister = bt.character("sister_head")
	sister.set_portrait(SISTER_BATTLE_COMPOSED, {"scale": 0.60, "side": "center", "position": [0, -260]})
	sister.band("...神の御前で、正直になりましょうか。\n迷いは、私にはお見通しよ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection)

	if result == "win":
		sister.set_portrait(SISTER_BATTLE_ANGRY, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("...あら。悪運だけはお強いようね。")
	elif result == "lose":
		sister.set_portrait(SISTER_BATTLE_LAUGH, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("ふふ。読み通りよ。\n...あなたの迷い、手に取るように分かる。")
	else:
		sister.set_portrait(SISTER_BATTLE_NORMAL, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("あら、偶然ね。...次は、そうはいきませんわ。")

# --- シスター長 Outfit 2: 1枚脱いだ ---

func sister_outfit_2(bt):
	var sister = bt.character("sister_head")
	sister.set_portrait(SISTER_BATTLE_SARCASM, {"scale": 0.60, "side": "center", "position": [0, -260]})
	sister.band("...こんなはずでは、と思ってる？\nふふ、ここからが本番ですわ。")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.5})

	if result == "win":
		sister.set_portrait(SISTER_BATTLE_SAD, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("...まさか、私の読みを裏切るなんて。")
	elif result == "lose":
		sister.set_portrait(SISTER_BATTLE_LAUGH, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("ご覧なさい。これが「神の裁き」よ。")
	else:
		sister.set_portrait(SISTER_BATTLE_COMPOSED, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("...あいこ。面白い冒険者ね、あなた。")

# --- シスター長 Outfit 1: あと1枚 ---

func sister_outfit_1(bt):
	var sister = bt.character("sister_head")
	sister.set_portrait(SISTER_BATTLE_SHOUT, {"scale": 0.60, "side": "center", "position": [0, -260]})
	sister.band("...っ！ こんな...こんな屈辱、許さない...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": 0.4})

	if result == "win":
		sister.set_portrait(SISTER_BATTLE_DEFEAT, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("...そんな。わたしが...負けた...。")
	elif result == "lose":
		sister.set_portrait(SISTER_BATTLE_COMPOSED, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("...ふう。危なかった。\nあなたも、もう終わりよ。")
	else:
		sister.set_portrait(SISTER_BATTLE_ANGRY, {"scale": 0.60, "side": "center", "position": [0, -260]})
		sister.band("...まだ、粘るの？ 往生際が悪いですわ。")

func get_lose_behavior() -> String:
	return "abort"

func get_lose_redirect() -> Dictionary:
	return {"type": "guild_home"}

func get_farewell(result: String) -> Dictionary:
	if result == "lose":
		return {
			"narration": "サトシはシスター長に敗北し、\n「覗き魔・三度目の現行犯」として教会の地下牢に放り込まれた...。",
			"portrait": SISTER_BATTLE_LAUGH,
			"portrait_scale": 0.60,
			"text": "神の裁きよ。...罪を悔い改めなさい。",
		}
	return {}
