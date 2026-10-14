extends "res://export_stage2_minigame.gd"

func reset_chapter(chapter, gauge: int):
    chapter._gauge = gauge
    chapter._last_zone = chapter._get_zone(gauge)
    chapter._turns_in_current_zone = 0
    chapter._red_used = []
    chapter._strong_used = []

func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        quit(1)
        return
    var source_path: String = args[1].path_join("battle/chapters/Stage5MinigameChapter.gd")
    if FileAccess.get_file_as_string(args[1].path_join("battle/MinigameChapterBase.gd")) != FileAccess.get_file_as_string("res://battle/MinigameChapterBase.gd"):
        push_error("Registered minigame base differs from reference")
        quit(1)
        return
    var adapter := GDScript.new()
    adapter.source_code = 'extends "' + source_path + '"\nvar trace_context\n' + \
        'func _spawn_floating_number(delta: int):\n    trace_context.add("gauge", [delta, _gauge])\n' + \
        'func _narrate_wait(bt, text: String):\n    if text.is_empty():\n        return\n    bt.dialogue_band("narrator", text, true)\n    await bt.wait(0.0)\n    bt.hide_dialogue_band()\n    await bt.wait(0.0)\n'
    if adapter.reload() != OK:
        push_error("Cannot compile original Stage 5 minigame")
        quit(1)
        return
    var chapter = adapter.new()
    var config: Dictionary = chapter._get_config()
    var intro := ExpressionContext.new([])
    chapter.trace_context = intro
    reset_chapter(chapter, config.gauge_start)
    await chapter.setup_scene(intro)
    await chapter._play_rules_intro(intro)
    await chapter._play_scripted_intro(intro)
    var intro_gauge: int = chapter._gauge
    var questions := []
    var traces := []
    for pool_name in ["red", "strong"]:
        var pool: Array = chapter.QUESTIONS_RED if pool_name == "red" else chapter.QUESTIONS_STRONG
        var gauge: int = 110 if pool_name == "red" else 75
        for index in range(pool.size()):
            reset_chapter(chapter, gauge)
            chapter._active_question = pool[index]
            var context := ExpressionContext.new([])
            await chapter._display_question(context)
            questions.append({"pool": pool_name, "index": index, "data": pool[index], "commands": context.commands})
            for pick in range(pool[index].misses.size() + 2):
                reset_chapter(chapter, gauge)
                context = ExpressionContext.new([])
                chapter.trace_context = context
                var choice := {}
                if pick == 0:
                    choice = {"pool_type": "hit"}
                elif pick == 1:
                    choice = {"is_pisuke": true}
                else:
                    choice = {"pool_type": "miss", "miss_data": pool[index].misses[pick - 2]}
                chapter._current_choices = [choice]
                await chapter._apply_choice(context, 0)
                traces.append({"pool": pool_name, "question": index, "pick": pick,
                    "initial_gauge": gauge, "final_gauge": chapter._gauge, "commands": context.commands})
    var zones := []
    var gauge_traces := []
    for value in range(config.gauge_max + 1):
        zones.append(chapter._get_zone(value))
        for delta in [-40, 5]:
            reset_chapter(chapter, value)
            var context := ExpressionContext.new([])
            chapter.trace_context = context
            await chapter._apply_gauge_change(context, delta, false)
            gauge_traces.append({"initial_gauge": value, "delta": delta, "final_gauge": chapter._gauge, "commands": context.commands})
    var win := ExpressionContext.new([])
    await chapter._play_pre_collected_evidence(win)
    await chapter._narrate_wait(win, config.win_narration)
    var lose := ExpressionContext.new([])
    await chapter._narrate_wait(lose, config.lose_narration)
    var output := {"format": "godot-stage5-minigame", "version": 1, "config": config,
        "intro": intro.commands, "intro_gauge": intro_gauge, "questions": questions,
        "traces": traces, "zones": zones, "gauge_traces": gauge_traces, "win": win.commands, "lose": lose.commands}
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
    print("Exported original Stage 5 questions, responses and victory evidence")
    quit(0)
