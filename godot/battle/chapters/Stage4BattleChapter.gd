extends BattleChapterBase

# Stage4 ボス: セレス（魔法師団長）
# 1戦目: 縛鎖魔法で完敗（固定敗北）
# 2戦目: ミニゲームで縛鎖封印後の通常戦

const SELES_PORTRAIT := "res://assets/characters/main/seles/clothed/seles_clothed_001.png"

func get_opponent_id() -> String:
	return "seles"

func get_opponent_name() -> String:
	return "セレス"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage4/bg_dojo_third.png"

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_hand() -> Array:
	return [
		{"hand": "rock", "grade": 2}, {"hand": "rock", "grade": 3},
		{"hand": "scissors", "grade": 2}, {"hand": "scissors", "grade": 3},
		{"hand": "paper", "grade": 2}, {"hand": "paper", "grade": 3}, {"hand": "paper", "grade": 3},
	]

func get_opponent_deck_size() -> int:
	return 7

func get_player_deck_size() -> int:
	return 7

func has_bayes_eye() -> bool:
	return true

func get_opponent_tendency() -> Dictionary:
	return {"rock": 0.35, "paper": 0.35}

func get_gold_reward() -> Dictionary:
	return {"min": 100, "max": 150}

func _is_first_battle() -> bool:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
	if gs == null: return true
	return not gs.flags.get("stage4_first_battle_done", false)

func _win_rate(default_rate: float) -> float:
	return 0.0 if _is_first_battle() else default_rate

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/pedestal_01_marble.png", {"scale": 0.55, "position": [0, 180]})
	var seles = bt.character("seles")
	seles.set_portrait(SELES_PORTRAIT, {"scale": 0.45, "side": "center", "position": [0, -260]})

func outfit_3(bt):
	var seles = bt.character("seles")
	seles.set_portrait(SELES_PORTRAIT, {"scale": 0.45, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		seles.band("縛鎖、発動。")
	else:
		seles.band("...そ、そんな、はずは...縛鎖は、私の...完璧な、はず...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.5)})

	if result == "win":
		seles.band("...貴殿の、読み...！")
	elif result == "lose":
		if _is_first_battle():
			seles.band("一本。...貴殿の「読み」は、確かに冴えているようだ。\nだが、貴殿の手が封じられていれば、それも、意味をなさぬ。")
		else:
			seles.band("...一本、いただきます。")
	else:
		seles.band("...引き分け。")

func outfit_2(bt):
	var seles = bt.character("seles")
	seles.set_portrait(SELES_PORTRAIT, {"scale": 0.45, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		seles.band("縛鎖、発動。")
	else:
		seles.band("...こ、これは...私の、魔法が...私自身に...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.5)})

	if result == "win":
		seles.band("...信じ難い。")
	elif result == "lose":
		seles.band("...二本目、いただきます。")
	else:
		seles.band("...またですか。")

func outfit_1(bt):
	var seles = bt.character("seles")
	seles.set_portrait(SELES_PORTRAIT, {"scale": 0.45, "side": "center", "position": [0, -260]})
	if _is_first_battle():
		seles.band("縛鎖、発動。")
	else:
		seles.band("...ぁ、ぁぁ...這う...這い、ます...！")

	var selection = await bt.select_hand()
	var result = await bt.janken(selection, {"win_rate": _win_rate(0.45)})

	if result == "win":
		if _is_first_battle():
			seles.band("...惜しい。")
		else:
			seles.band("...完敗、だ。検証は、完了した。")
	elif result == "lose":
		if _is_first_battle():
			seles.band("...予想通りだ。貴殿の『読み』は、出せる手が封じられていれば、\nただの無駄知識に過ぎぬ。")
		else:
			seles.band("...助かった。")
	else:
		seles.band("...粘りますね。")

func get_lose_behavior() -> String:
	return "continue" if _is_first_battle() else "guild_home"

func get_lose_redirect() -> Dictionary:
	return {} if _is_first_battle() else {"type": "guild_home"}

func get_farewell(_result: String) -> Dictionary:
	return {}
