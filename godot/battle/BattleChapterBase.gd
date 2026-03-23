extends Node
class_name BattleChapterBase

# --- Basic info (override in subclasses) ---

func get_opponent_id() -> String:
	return ""

func get_opponent_name() -> String:
	return ""

func get_card_paths() -> Dictionary:
	return {
		"rock": "res://assets/battle/cards/rock.png",
		"scissors": "res://assets/battle/cards/scissors.png",
		"paper": "res://assets/battle/cards/paper.png",
	}

func get_card_back() -> String:
	return "res://assets/battle/cards/card_back.png"

func get_battle_background() -> String:
	return ""

func get_opponent_outfit_count() -> int:
	return 3

func get_player_outfit_count() -> int:
	return 3

func get_opponent_deck() -> Array:
	# Default: 9 normal cards (3 of each)
	# Card format: {"hand": "rock"/"scissors"/"paper", "grade": 1-5}
	# Grade: 1=ノーマル, 2=ブロンズ, 3=シルバー, 4=ゴールド, 5=プラチナ
	return [
		{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1},
		{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1},
		{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1},
	]

# --- Scene setup (override to show opponent before deck building) ---
# Called before deck building phase. Use to display opponent character, deck, etc.
# func setup_scene(bt): ...

# --- Outfit stage functions (override in subclasses) ---
# Called when opponent has N pieces of clothing remaining.
# bt (BattleScene) provides:
#   bt.character(id)       → CharacterHandle (same as story DSL)
#   bt.narrator_band(text)
#   bt.background(path, fade)
#   bt.pause(duration)
#   bt.select_hand()       → waits for player card selection, returns Dictionary
#   bt.janken(selection)   → plays overlay animation, returns "win"/"lose"/"draw"
#   bt.opponent_outfit     → current opponent outfit count
#   bt.player_outfit       → current player outfit count
#   bt.player_deck_count   → remaining cards in player deck
#
# Note: Player character is NOT shown in battle. Only opponent + narrator.

# func outfit_3(bt): ...
# func outfit_2(bt): ...
# func outfit_1(bt): ...
# Note: victory/defeat is handled by the story scene, not the battle chapter.
