extends SceneTree

# Execute unchanged Main control-flow methods; replace only UI/battle I/O with trace adapters.
func _initialize() -> void:
    call_deferred("export_flow")

func method_source(source: String, name: String) -> String:
    var start := source.find("func " + name + "(")
    if start < 0:
        push_error("Missing original Main method " + name)
        return ""
    var end := source.find("\nfunc ", start + 1)
    return source.substr(start, (source.length() if end < 0 else end) - start)

func export_flow() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        push_error("Expected output JSON and reference Godot project")
        quit(1)
        return
    var main_path := args[1].path_join("game/Main.gd")
    var source := FileAccess.get_file_as_string(main_path)
    var state = root.get_node_or_null("GameState")
    if state == null:
        push_error("Original GameState autoload is required")
        quit(1)
        return
    var previous_state := {"chapter": state.chapter, "label": state.label, "last_battle_result": state.last_battle_result}
    var order_start := source.find("var _scenario_order: Array = [")
    var order_end := source.find("\n]\n", order_start)
    if order_start < 0 or order_end < 0:
        push_error("Cannot find original scenario order")
        quit(1)
        return
    var adapter := """extends Control
class TraceScene extends RefCounted:
    var visible = true
    var background_rect = {"texture": null}
    var _abort_sequence = false
    var calls = []
    func complete_battle(result): calls.append({"kind": "complete_battle", "result": result})
var story_scene_instance = TraceScene.new()
var GameState = null
var battle_scene_scene = null
var story_script = null
var _jump_force_result_selector_mode = false
var calls = []
var choices = []
var results = []
func _play_scene(id):
    calls.append({"kind": "scene", "id": id})
    if id == "prologue" and not results.is_empty(): GameState.last_battle_result = results.pop_front()
func _play_scene_from(id, label):
    calls.append({"kind": "scene_from", "id": id, "label": label})
    if not results.is_empty(): GameState.last_battle_result = results.pop_front()
func _show_guild_home(): calls.append({"kind": "guild_home"})
func _show_battle_result_screen(result):
    var choice = choices.pop_front()
    calls.append({"kind": "result_choice", "result": result, "choice": choice})
    return choice
func _execute_battle(_chapter, _background, _selector):
    var result = results.pop_front()
    calls.append({"kind": "battle", "result": result})
    return {"result": result}
func _show_battle_farewell_in_scene(_chapter, result, _background): calls.append({"kind": "farewell", "result": result})
func _show_choice_overlay(labels):
    var choice = choices.pop_front()
    calls.append({"kind": "redirect_choice", "labels": labels, "choice": choice})
    return choice
func _show_retry_scene(_redirect): return _show_choice_overlay(["retry", "home"])
func _should_skip_common_lose_narration(_cmd): return false
func _play_common_lose_narration(_cmd): calls.append({"kind": "common_lose"})
func _load_script_fresh(_path): return null
"""
    adapter = adapter.replace("    ", "\t")
    adapter += source.substr(order_start, order_end + 3 - order_start) + "\n"
    for name in ["_run_scenario_from", "_handle_battle_aftermath", "_on_battle_requested"]:
        var method := method_source(source, name)
        if method.is_empty():
            quit(1)
            return
        adapter += method + "\n"
    var script := GDScript.new()
    script.source_code = adapter
    if script.reload() != OK:
        push_error("Cannot compile original Main flow adapter")
        quit(1)
        return
    var scenario_traces := []
    for result in ["win", "lose", "draw"]:
        for choice in (["next", "title"] if result == "win" else ["retry", "title"]):
            state.last_battle_result = ""
            var runner = script.new()
            runner.GameState = state
            runner.results = [result, "win"] if choice == "retry" else [result]
            runner.choices = [choice, "next"] if choice == "retry" else [choice]
            runner.story_scene_instance.calls = runner.calls
            await runner._run_scenario_from(0, "")
            scenario_traces.append({"result": result, "choice": choice, "commands": runner.calls})
            runner.free()
    var chapter_path := args[1].path_join("battle/chapters/PrologueBattleChapter.gd")
    var chapter = load(chapter_path).new()
    var bridge_traces := []
    for fixture in [{"results": ["win"], "choices": []}, {"results": ["lose", "win"], "choices": ["retry"]},
        {"results": ["lose"], "choices": ["home"]}, {"results": ["draw", "win"], "choices": ["retry"]},
        {"results": ["draw"], "choices": ["home"]}]:
        state.last_battle_result = ""
        var runner = script.new()
        runner.GameState = state
        runner.results = fixture.results.duplicate()
        runner.choices = fixture.choices.duplicate()
        runner.story_scene_instance.calls = runner.calls
        var command := {"chapter_path": "", "chapter": chapter, "is_minigame": false, "is_tutorial": false, "result": ""}
        await runner._on_battle_requested(command)
        bridge_traces.append({"results": fixture.results, "choices": fixture.choices, "commands": runner.calls,
            "final_result": command.result, "abort_sequence": runner.story_scene_instance._abort_sequence})
        runner.free()
    var result_adapter := """extends Control
signal _result_choice_made(choice: String)
var result_title = Label.new()
var result_message = Label.new()
var result_buttons = HBoxContainer.new()
var battle_result_screen = Control.new()
func select_button(index): result_buttons.get_child(index).pressed.emit()
"""
    result_adapter += method_source(source, "_show_battle_result_screen") + "\n" + method_source(source, "_add_result_button")
    var result_script := GDScript.new()
    result_script.source_code = result_adapter
    if result_script.reload() != OK:
        push_error("Cannot compile original result screen adapter")
        quit(1)
        return
    var result_screens := []
    for result in ["win", "lose", "draw"]:
        var screen := {"result": result, "title": "", "message": "", "buttons": []}
        for index in range(2):
            var runner = result_script.new()
            runner.add_child(runner.battle_result_screen)
            runner.battle_result_screen.add_child(runner.result_title)
            runner.battle_result_screen.add_child(runner.result_message)
            runner.battle_result_screen.add_child(runner.result_buttons)
            runner.call_deferred("select_button", index)
            var choice: String = await runner._show_battle_result_screen(result)
            screen.title = runner.result_title.text
            screen.message = runner.result_message.text
            screen.buttons.append({"label": runner.result_buttons.get_child(index).text, "choice": choice})
            runner.queue_free()
            await process_frame
        result_screens.append(screen)
    var hashes := {}
    for path in ["game/Main.gd", "battle/chapters/PrologueBattleChapter.gd", "battle/BattleChapterBase.gd"]:
        hashes[path] = FileAccess.get_file_as_string(args[1].path_join(path)).sha256_text()
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if file == null:
        push_error("Cannot open original Main flow output")
        quit(1)
        return
    var order_runner = script.new()
    var scenario_order: Array = order_runner._scenario_order
    order_runner.free()
    file.store_string(JSON.stringify({"format": "godot-main-flow", "version": 1, "source_hashes": hashes,
        "scenario_order": scenario_order, "scenario_traces": scenario_traces, "bridge_traces": bridge_traces, "result_screens": result_screens,
        "matilda_redirect": chapter.get_lose_redirect(), "matilda_lose_behavior": chapter.get_lose_behavior()}, "  "))
    file.close()
    chapter.free()
    state.chapter = previous_state.chapter
    state.label = previous_state.label
    state.last_battle_result = previous_state.last_battle_result
    print("Exported original Main: 6 scenario traces, 5 Matilda bridge traces")
    quit(0)
