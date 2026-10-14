extends "res://export_subevent3_minigame.gd"

class ExpressionContext extends MiniContext:
    func dialogue_band(speaker, text, wait_for_input = true):
        add("dialogue_band", [speaker, text, wait_for_input])
    func hide_dialogue_band():
        add("hide_dialogue_band", [])

func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        quit(1)
        return
    var source_path: String = args[1].path_join("battle/chapters/Stage2MinigameChapter.gd")
    var source: String = FileAccess.get_file_as_string(source_path)
    var question_line := ""
    for line in source.get_slice("func minigame(bt):", 1).get_slice("# --- 導入 ---", 0).split("\n"):
        if line.strip_edges().begins_with('bt.narrator_band("ピー助:'):
            question_line = line.strip_edges()
    var lock_pattern := RegEx.new()
    lock_pattern.compile('_pisuke_button.disabled = \\(_turns_done < ([0-9]+)\\)')
    var lock_match = lock_pattern.search(source)
    if question_line.is_empty() or lock_match == null:
        push_error("Stage 2 question/lock source shape changed")
        quit(1)
        return
    var adapter := GDScript.new()
    adapter.source_code = 'extends "' + source_path + '"\nfunc _update_gauge_display():\n    pass\n' + \
        'func capture_question(bt):\n    bt.set_bubble_side("bottom-left")\n    ' + question_line + '\n    await bt.wait(0.0)\n'
    if adapter.reload() != OK:
        push_error("Cannot compile original Stage 2 minigame")
        quit(1)
        return
    var chapter = adapter.new()
    var intro := ExpressionContext.new([])
    await chapter.setup_scene(intro)
    await chapter._play_intro(intro)
    await chapter._play_briefing(intro)
    var traces := []
    var questions := []
    for scene in range(chapter.SCENES.size()):
        chapter._current_scene = chapter.SCENES[scene]
        var question := ExpressionContext.new([])
        await chapter.capture_question(question)
        questions.append(question.commands)
        for pick in chapter.CHOICE_KEYS + ["_pisuke"]:
            chapter._gauge = chapter.GAUGE_START
            chapter._current_scene = chapter.SCENES[scene]
            var context := ExpressionContext.new([])
            if pick == "_pisuke":
                await chapter._apply_pisuke(context)
            else:
                await chapter._apply_choice(context, pick)
            traces.append({"scene": scene, "pick": pick, "delta": chapter._gauge - chapter.GAUGE_START,
                "commands": context.commands})
    var expressions := {}
    for key in chapter.CHOICE_KEYS:
        var expression: Dictionary = chapter.EXPRESSIONS[key]
        var color: Color = expression.color
        expressions[key] = {"choice": expression.choice, "badge": expression.badge,
            "color": [color.r, color.g, color.b, color.a]}
    var endings := []
    var body: String = FileAccess.get_file_as_string(source_path).get_slice("func minigame(bt):", 1).get_slice("# --- 導入 ---", 0)
    var pattern := RegEx.new()
    pattern.compile('bt.dialogue_band\\("narrator", (".*"), true\\)')
    for match_result in pattern.search_all(body):
        endings.append(JSON.parse_string(match_result.get_string(1)))
    if endings.size() != 2 or endings.has(null):
        push_error("Stage 2 ending source shape changed")
        quit(1)
        return
    var output := {"format": "godot-stage2-minigame", "version": 1,
        "chapter_path": "res://battle/chapters/Stage2MinigameChapter.gd",
        "gauge_start": chapter.GAUGE_START, "gauge_max": chapter.GAUGE_MAX,
        "hit_delta": chapter.HIT_DELTA, "miss_delta": chapter.MISS_DELTA,
        "pisuke_unlock_turn": int(lock_match.get_string(1)), "choice_keys": chapter.CHOICE_KEYS,
        "expressions": expressions, "scenes": chapter.SCENES, "intro": intro.commands,
        "traces": traces, "questions": questions, "ending": {"win": endings[0], "lose": endings[1]}}
    chapter.free()
    var temporary_path: String = args[0] + ".tmp"
    var file := FileAccess.open(temporary_path, FileAccess.WRITE)
    if file == null:
        quit(1)
        return
    file.store_string(JSON.stringify(output, "  "))
    file.close()
    if DirAccess.rename_absolute(temporary_path, args[0]) != OK:
        quit(1)
        return
    print("Exported 10 original Stage 2 scenes and 50 response traces")
    quit(0)
