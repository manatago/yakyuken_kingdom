extends CardBattleChapterBase
class_name PrologueBattleChapter

const OPPONENT_PATH := "res://resources/characters/DefaultGirl.tres"
const CARD_ROCK := "res://assets/battle/cards/rock.jpg"
const CARD_SCISSORS := "res://assets/battle/cards/scissors.jpg"
const CARD_PAPER := "res://assets/battle/cards/paper.jpg"
const CARD_BACK := "res://assets/battle/cards/card_back.png"
const BATTLE_BG := "res://assets/backgrounds/bg06_prison_arena.png"

func get_id() -> String:
    return "prologue"

func opponent_resource_path() -> String:
    return OPPONENT_PATH

func card_texture_paths() -> Dictionary:
    return {
        "rock": CARD_ROCK,
        "scissors": CARD_SCISSORS,
        "paper": CARD_PAPER,
    }

func card_back_texture_path() -> String:
    return CARD_BACK

func battle_background_texture_path() -> String:
    return BATTLE_BG

func select_prompt_text() -> String:
    return "カードを選んでください"

func final_result_texts() -> Dictionary:
    return {
        "win": "You Win!",
        "lose": "You Lose...",
        "draw": "Draw",
    }

func win_rate_config() -> Dictionary:
    return {
        "player": 0.7,
        "draw": 0.2,
        "cpu": 0.1,
    }
