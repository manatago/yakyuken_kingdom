extends BattleChapterBase
class_name RandomBattleChapter

# エンカウントデータから動的に設定されるパラメータ
var _data: Dictionary = {}
var _opponent_id: String = ""
var _opponent_name: String = ""
var _opponent_hand: Array = []
var _tendency: Dictionary = {}
var _bayes_eye: bool = true
var _battle_bg: String = ""

func setup_from_encounter(data: Dictionary):
	_data = data
	_opponent_id = data.get("id", "")
	_opponent_name = data.get("name", "")
	_tendency = data.get("tendency", {})
	_bayes_eye = data.get("bayes_eye", true)
	_battle_bg = data.get("battle_bg", "")
	_opponent_hand = data.get("hand", [
		Card.new("rock", 1),
		Card.new("scissors", 1),
		Card.new("paper", 1),
	])

# --- 必須オーバーライド ---

func get_opponent_id() -> String:
	return _opponent_id

func get_opponent_name() -> String:
	return _opponent_name

func get_opponent_outfit_count() -> int:
	return EncounterDatabase.RANDOM_BATTLE_HP

func get_player_outfit_count() -> int:
	return EncounterDatabase.RANDOM_BATTLE_HP

func get_opponent_hand() -> Array:
	return _opponent_hand

func get_opponent_deck_size() -> int:
	return EncounterDatabase.RANDOM_BATTLE_DECK_SIZE

func get_player_deck_size() -> int:
	return EncounterDatabase.RANDOM_BATTLE_PLAYER_DECK_SIZE

# --- 任意オーバーライド ---

func get_battle_background() -> String:
	return _battle_bg

func has_bayes_eye() -> bool:
	return _bayes_eye

func get_opponent_tendency() -> Dictionary:
	return _tendency

func get_gold_reward() -> Dictionary:
	return _data.get("gold_reward", {"min": 5, "max": 20})

func get_encounter_farewell(result: String) -> String:
	var key: String
	match result:
		"win":  key = "farewells_win"
		"lose": key = "farewells_lose"
		_:      return ""
	return EncounterDatabase.pick_line(_data, key)

func get_encounter_farewell_portrait(result: String) -> Dictionary:
	var scene_key: String = "farewell_win" if result == "win" else "farewell_lose"
	return EncounterDatabase.get_portrait(_data, scene_key)

# --- 簡易演出 ---

func _get_battle_portrait() -> Dictionary:
	return EncounterDatabase.get_portrait(_data, "battle")

func setup_scene(bt):
	bt.deck("res://assets/battle/decks/deck_003.png", {"scale": 0.75, "position": [0, 150]})
	var portrait: Dictionary = _get_battle_portrait()
	var p_path: String = portrait.get("path", "")
	if p_path.is_empty():
		return
	var char_handle = bt.character(_opponent_id)
	char_handle.set_portrait(p_path, {
		"scale": portrait.get("scale", 0.4),
		"side": portrait.get("side", "center"),
		"position": portrait.get("position", [0, -199]),
	})

func outfit_1(bt):
	var portrait: Dictionary = _get_battle_portrait()
	var char_handle = bt.character(_opponent_id)
	var p_path: String = portrait.get("path", "")
	if not p_path.is_empty():
		char_handle.set_portrait(p_path, {
			"scale": portrait.get("scale", 0.4),
			"side": portrait.get("side", "center"),
			"position": portrait.get("position", [0, -199]),
		})
	# バトル開始セリフ
	var start_line: String = EncounterDatabase.pick_line(_data, "battle_start")
	if not start_line.is_empty():
		char_handle.band(start_line)

	var selection = await bt.select_hand()
	await bt.janken(selection)
