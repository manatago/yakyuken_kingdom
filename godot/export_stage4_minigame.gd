extends "res://export_stage2_minigame.gd"

func reset_chapter(chapter, gauge: int):
    chapter._gauge = gauge
    chapter._last_zone = chapter._get_zone(gauge)
    chapter._turns_in_current_zone = 0
    chapter._light_used = []
    chapter._strong_used = []
    chapter._miss_used = []

func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        quit(1)
        return
    var source_path: String = args[1].path_join("battle/chapters/Stage4MinigameChapter.gd")
    var base_path: String = args[1].path_join("battle/MinigameChapterBase.gd")
    if FileAccess.get_file_as_string(base_path) != FileAccess.get_file_as_string("res://battle/MinigameChapterBase.gd"):
        push_error("Registered minigame base differs from reference")
        quit(1)
        return
    # Preserve the original gauge/threshold/zone logic; only replace UI adapters.
    var adapter := GDScript.new()
    adapter.source_code = 'extends "' + source_path + '"\nvar trace_context\n' + \
        'func _spawn_floating_number(delta: int):\n    trace_context.add("gauge", [delta, _gauge])\n' + \
        'func _narrate_wait(bt, text: String):\n    if text.is_empty():\n        return\n    bt.dialogue_band("narrator", text, true)\n    await bt.wait(0.0)\n    bt.hide_dialogue_band()\n    await bt.wait(0.0)\n'
    if adapter.reload() != OK:
        push_error("Cannot compile original Stage 4 minigame")
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
    var body: String = FileAccess.get_file_as_string(base_path).get_slice("func minigame(bt):", 1).get_slice("# --- ゾーン判定 ---", 0)
    var prompt := ""
    for line in body.split("\n"):
        var trimmed := line.strip_edges()
        if trimmed.begins_with('await _narrate_wait(bt, "'):
            prompt = JSON.parse_string(trimmed.trim_prefix("await _narrate_wait(bt, ").trim_suffix(")"))
    if prompt.is_empty():
        push_error("Original strength prompt source shape changed")
        quit(1)
        return
    await chapter._narrate_wait(intro, prompt)
    var intro_gauge: int = chapter._gauge
    var traces := []
    var support_traces := []
    for gauge in [110, 75, 35]:
        var zone: String = chapter._get_zone(gauge)
        for pool_name in ["light", "strong", "miss"]:
            var pool: Array = chapter.LIGHT_POOL if pool_name == "light" else chapter.STRONG_POOL if pool_name == "strong" else chapter.MISS_POOL
            for index in range(pool.size()):
                reset_chapter(chapter, gauge)
                var choice: Dictionary = pool[index].duplicate(true)
                choice.pool_type = pool_name
                choice.pool_idx = index
                chapter._current_choices = [choice]
                var context := ExpressionContext.new([])
                chapter.trace_context = context
                await chapter._apply_choice(context, 0)
                traces.append({"zone": zone, "initial_gauge": gauge, "pool": pool_name, "index": index,
                    "final_gauge": chapter._gauge, "commands": context.commands})
        for index in range(3):
            reset_chapter(chapter, gauge)
            for other in range(3):
                if other != index:
                    if zone == "red":
                        chapter._light_used.append(other)
                    else:
                        chapter._strong_used.append(other)
            var context := ExpressionContext.new([])
            chapter.trace_context = context
            await chapter._apply_pisuke(context)
            support_traces.append({"zone": zone, "initial_gauge": gauge, "index": index,
                "final_gauge": chapter._gauge, "commands": context.commands})
    var zones := []
    var gauge_traces := []
    for value in range(config.gauge_max + 1):
        zones.append(chapter._get_zone(value))
        for delta in [-40, 5]:
            reset_chapter(chapter, value)
            var context := ExpressionContext.new([])
            chapter.trace_context = context
            await chapter._apply_gauge_change(context, delta, false)
            gauge_traces.append({"initial_gauge": value, "delta": delta,
                "final_gauge": chapter._gauge, "commands": context.commands})
    var output := {"format": "godot-stage4-minigame", "version": 1, "config": config,
        "chapter_path": "res://battle/chapters/Stage4MinigameChapter.gd",
        "light_pool": chapter.LIGHT_POOL, "strong_pool": chapter.STRONG_POOL, "miss_pool": chapter.MISS_POOL,
        "intro": intro.commands, "intro_gauge": intro_gauge, "zones": zones,
        "traces": traces, "pisuke_traces": support_traces, "gauge_traces": gauge_traces}
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
    print("Exported 30 original Stage 4 zone choices and 9 support traces")
    quit(0)
