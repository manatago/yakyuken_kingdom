extends "res://capture_story_skip.gd"

var _requests := []

func perform_action(scene) -> void:
    scene.battle_requested.connect(func(command):
        _requests.append({"chapter_path": command.chapter_path, "is_tutorial": command.is_tutorial,
            "is_minigame": command.is_minigame}))
    scene._on_skip_pressed()

func allows_sequence_end() -> bool:
    return true

func capture_scope() -> String:
    return "skip-sequence-loop-with-battle-signals-unhandled"

func action_details() -> Dictionary:
    return {"battle_requests": _requests, "battle_completion_signals_emitted": 0}
