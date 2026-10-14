extends "res://export_prologue_battle.gd"

class MiniContext extends TraceContext:
    func narrator_band(text, speaker = "", icon = ""):
        add("narrator_band", [text, speaker, icon])

func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        push_error("Expected output path and reference project path")
        quit(1)
        return
    var source_path := args[1].path_join("battle/chapters/Subevent3MinigameChapter.gd")
    # Override only UI/animation adapters. Dialogue and choice methods remain original.
    var adapter := GDScript.new()
    adapter.source_code = 'extends "' + source_path + '"\n' + \
        'func _narrate_wait(bt, text: String):\n    bt.add("narrator_band", [text, "", ""])\n' + \
        'func _apply_gauge_change(bt, delta: int):\n    _gauge = clampi(_gauge + delta, 0, GAUGE_MAX)\n    bt.add("gauge", [delta, _gauge])\n'
    if adapter.reload() != OK:
        push_error("Cannot compile original minigame adapter")
        quit(1)
        return
    var chapter = adapter.new()
    var minigame_body: String = FileAccess.get_file_as_string(source_path).get_slice("func minigame(bt):", 1).get_slice("# --- 選択肢適用 ---", 0)
    var boundary_texts := []
    for line in minigame_body.split("\n"):
        var trimmed: String = line.strip_edges()
        if trimmed.begins_with("await _narrate_wait(bt, "):
            boundary_texts.append(JSON.parse_string(trimmed.trim_prefix("await _narrate_wait(bt, ").trim_suffix(")")))
    if boundary_texts.size() != 3 or boundary_texts.has(null):
        push_error("Original minigame boundary text shape changed")
        quit(1)
        return
    var intro := MiniContext.new([])
    await chapter.setup_scene(intro)
    await chapter._play_rules_intro(intro)
    await chapter._play_scripted_intro(intro)
    var intro_gauge: int = chapter._gauge
    var choice_traces := []
    for index in range(chapter.CHOICE_POOL.size()):
        chapter._gauge = intro_gauge
        chapter._current_choices = [chapter.CHOICE_POOL[index]]
        var context := MiniContext.new([])
        await chapter._apply_choice(context, 0)
        choice_traces.append({"index": index, "delta": chapter.CHOICE_POOL[index].delta, "commands": context.commands})
    var pisuke_traces := []
    for cycle in range(3):
        for index in range(chapter.PISUKE_LINES.size()):
            chapter._gauge = intro_gauge
            chapter._pisuke_cycle = cycle
            chapter._pisuke_used = []
            for excluded in range(chapter.PISUKE_LINES.size()):
                if excluded != index:
                    chapter._pisuke_used.append(excluded)
            var context := MiniContext.new([])
            await chapter._apply_pisuke(context)
            var delta: int = -50 if cycle == 0 else (-20 if cycle == 1 else -5)
            pisuke_traces.append({"index": index, "cycle": cycle, "delta": delta, "commands": context.commands})
    var output := {"format": "godot-subevent3-minigame", "version": 1,
        "chapter_path": "res://battle/chapters/Subevent3MinigameChapter.gd",
        "gauge_start": chapter.GAUGE_START, "gauge_max": chapter.GAUGE_MAX, "intro_gauge": intro_gauge,
        "choices": chapter.CHOICE_POOL, "pisuke_lines": chapter.PISUKE_LINES,
        "intro": intro.commands, "choice_traces": choice_traces, "pisuke_traces": pisuke_traces,
        "choice_prompt": boundary_texts[0], "ending": {"win": boundary_texts[1], "lose": boundary_texts[2]},
        "lose_behavior": chapter.get_lose_behavior(), "lose_redirect": chapter.get_lose_redirect()}
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
    print("Exported 18 choice and 15 Pisuke traces from original minigame")
    quit(0)
