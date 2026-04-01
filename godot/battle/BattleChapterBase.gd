extends Node
class_name BattleChapterBase

# --- 必須オーバーライド（派生クラスで定義すること） ---
# デフォルト値を持たない。設定漏れ時は push_error で警告。

func get_opponent_id() -> String:
	push_error("BattleChapterBase.get_opponent_id() must be overridden")
	return ""

func get_opponent_name() -> String:
	push_error("BattleChapterBase.get_opponent_name() must be overridden")
	return ""

func get_opponent_outfit_count() -> int:
	push_error("BattleChapterBase.get_opponent_outfit_count() must be overridden")
	return 1

func get_player_outfit_count() -> int:
	push_error("BattleChapterBase.get_player_outfit_count() must be overridden")
	return 1

func get_opponent_hand() -> Array:
	push_error("BattleChapterBase.get_opponent_hand() must be overridden")
	return []

func get_opponent_deck_size() -> int:
	push_error("BattleChapterBase.get_opponent_deck_size() must be overridden")
	return 3

func get_player_deck_size() -> int:
	push_error("BattleChapterBase.get_player_deck_size() must be overridden")
	return 3

# --- 任意オーバーライド（合理的なデフォルトあり） ---

func get_battle_background() -> String:
	return ""

func get_card_paths() -> Dictionary:
	return {
		"rock": "res://assets/battle/cards/rock.png",
		"scissors": "res://assets/battle/cards/scissors.png",
		"paper": "res://assets/battle/cards/paper.png",
	}

func get_card_back() -> String:
	return "res://assets/battle/cards/card_back.png"

func has_bayes_eye() -> bool:
	return false

func get_opponent_tendency() -> Dictionary:
	return {}

func can_lose_cards() -> bool:
	return true

func can_gain_cards() -> bool:
	return true

func get_gold_reward() -> Dictionary:
	# {"min": 最小値, "max": 最大値} — 勝利時にランダムでゴールド取得
	# 空Dictionaryなら報酬なし
	return {}

func roll_gold() -> int:
	var reward := get_gold_reward()
	if reward.is_empty():
		return 0
	var min_gold: int = reward.get("min", 0)
	var max_gold: int = reward.get("max", 0)
	if max_gold <= min_gold:
		return min_gold
	return randi_range(min_gold, max_gold)

# --- 共通ロジック ---

func get_opponent_deck() -> Array:
	var hand := get_opponent_hand()
	var deck_size := get_opponent_deck_size()
	if hand.size() <= deck_size:
		return hand.duplicate(true)
	var shuffled := hand.duplicate(true)
	shuffled.shuffle()
	return shuffled.slice(0, deck_size)

# --- Scene setup / Outfit functions (override in subclasses) ---
# bt (BattleScene) provides:
#   bt.character(id)       → CharacterHandle
#   bt.narrator_band(text)
#   bt.select_hand()       → waits for player card selection
#   bt.janken(selection)   → plays animation, returns "win"/"lose"/"draw"
#
# func setup_scene(bt): ...
# func tutorial(bt): ...
# func outfit_N(bt): ...
