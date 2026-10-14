extends "res://capture_story_skip.gd"

var _runner = null
var _main_path := "res://game/Main.gd"

func method_source(source: String, name: String) -> String:
    var start := source.find("func " + name + "(")
    var end := source.find("\nfunc ", start + 1)
    return source.substr(start, (source.length() if end < 0 else end) - start)

func perform_action(scene) -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() == 4:
        _main_path = args[3].path_join("game/Main.gd")
    # Preserve Main's actual bridge; hold its external battle I/O pending.
    var adapter := """extends Control
class BattleStub extends Control:
    signal battle_finished(result)
    var force_result_selector_mode = false
    var calls = []
    var chapters = []
    func setup(_cast, _background, _inventory): pass
    func start_battle(_chapter, tutorial = false, minigame = false):
        chapters.append(_chapter)
        calls.append({"kind": "pending_battle", "tutorial": tutorial, "minigame": minigame})
    func get_battle_rewards(): return {"captured_by_player": [], "captured_by_opponent": []}
    func get_rolled_gold(): return 0
    func get_lost_gold(): return 0
class BattleFactory extends RefCounted:
    var calls = []
    var chapters = []
    func instantiate():
        var battle = BattleStub.new()
        battle.calls = calls
        battle.chapters = chapters
        return battle
signal pending_normal_result(result)
var story_scene_instance = null
var story_script = null
var GameState = null
var battle_scene_scene = BattleFactory.new()
var _jump_force_result_selector_mode = false
var calls = []
var chapters = []
func _load_script_fresh(path): return load(path)
func _execute_battle(_chapter, _background, _selector):
    chapters.append(_chapter)
    calls.append({"kind": "pending_battle", "tutorial": false, "minigame": false})
    return await pending_normal_result
func _show_battle_farewell_in_scene(_chapter, _result, _background): pass
func _show_retry_scene(_redirect): return "home"
func _play_scene(_id): pass
func _show_choice_overlay(_labels): return "home"
func _should_skip_common_lose_narration(_cmd): return true
func _play_common_lose_narration(_cmd): pass
"""
    adapter = adapter.replace("    ", "\t")
    adapter += method_source(FileAccess.get_file_as_string(_main_path), "_on_battle_requested")
    var script := GDScript.new()
    script.source_code = adapter
    if script.reload() != OK:
        push_error("Cannot compile actual Main Skip bridge")
        quit(1)
        return
    _runner = script.new()
    root.add_child(_runner)
    _runner.GameState = root.get_node("GameState")
    _runner.story_script = load("res://story/DefaultStory.gd").new()
    _runner.story_scene_instance = scene
    _runner.battle_scene_scene.calls = _runner.calls
    _runner.battle_scene_scene.chapters = _runner.chapters
    scene.battle_requested.connect(_runner._on_battle_requested)
    scene._on_skip_pressed()

func allows_sequence_end() -> bool:
    return true

func capture_scope() -> String:
    return "actual-story-loop-main-bridge-with-pending-battle-io"

func action_details() -> Dictionary:
    var result := {"pending_battles": _runner.calls.duplicate(true), "main_source_hash": FileAccess.get_sha256(_main_path),
        "story_visible": _runner.story_scene_instance.visible}
    # Release test-held coroutines only after recording the pending-I/O boundary.
    for child in _runner.get_children():
        child.battle_finished.emit("win")
    _runner.pending_normal_result.emit({"result": "win"})
    await process_frame
    for chapter in _runner.chapters:
        if is_instance_valid(chapter):
            chapter.free()
    _runner.free()
    return result
