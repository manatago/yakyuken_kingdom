extends RefCounted
class_name CardBattleChapterBase

## Override this to provide a descriptive identifier (e.g. "prologue")
func get_id() -> String:
    return "default"

## Path to CharacterData (.tres) used for HUD portrait and quotes
func opponent_resource_path() -> String:
    return ""

## Dictionary of texture paths for the three hands. Keys should be "rock", "scissors", "paper".
func card_texture_paths() -> Dictionary:
    return {}

## Texture path for the card back art
func card_back_texture_path() -> String:
    return ""

func battle_background_texture_path() -> String:
    return ""

## Called when Main scene needs the prompt text above the hand selection
func select_prompt_text() -> String:
    return "カードを選んでください"

## Called when Main scene displays the final overall result
func final_result_texts() -> Dictionary:
    return {
        "win": "You Win!",
        "lose": "You Lose...",
        "draw": "Draw",
    }

## Win rate distribution controlling CPU bias. Keys: player/draw/cpu (player lose rate)
func win_rate_config() -> Dictionary:
    return {
        "player": 0.7,
        "draw": 0.2,
        "cpu": 0.1,
    }

## Optional hook for future per-chapter tweaks in Main scene
func configure_main(_main_node):
    pass

## Optional hook for future per-chapter tweaks in Table3D scene
func configure_table(_table_node):
    pass
