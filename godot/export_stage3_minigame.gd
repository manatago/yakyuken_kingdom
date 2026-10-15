extends "res://export_stage2_minigame.gd"

func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        quit(1)
        return
    var source_path: String = args[1].path_join("battle/chapters/Stage3MinigameChapter.gd")
    var source := FileAccess.get_file_as_string(source_path)
    var adapter := GDScript.new()
    adapter.source_code = 'extends "' + source_path + '"\nfunc _update_gauge_display():\n    pass\n'
    if adapter.reload() != OK:
        push_error("Cannot compile original Stage 3 minigame")
        quit(1)
        return
    var chapter = adapter.new()
    var intro := ExpressionContext.new([])
    await chapter.setup_scene(intro)
    await chapter._play_intro(intro)
    await chapter._play_scripted_opening(intro)
    var traces := []
    for book in chapter.CHAPTERS.keys():
        for evidence in chapter.EVIDENCES.keys():
            chapter._gauge = chapter.GAUGE_START
            chapter._used_combo_keys = []
            var context := ExpressionContext.new([])
            await chapter._apply_choice(context, book, evidence)
            traces.append({"chapter": book, "evidence": evidence,
                "delta": chapter._gauge - chapter.GAUGE_START, "commands": context.commands})
    var repeat_traces := []
    var pisuke_traces := []
    for combo in chapter.VALID_COMBOS:
        var key: String = "%s|%s" % [combo.chapter, combo.evidence]
        chapter._gauge = chapter.GAUGE_START
        chapter._used_combo_keys = [key]
        var repeated := ExpressionContext.new([])
        await chapter._apply_choice(repeated, combo.chapter, combo.evidence)
        repeat_traces.append({"chapter": combo.chapter, "evidence": combo.evidence,
            "delta": chapter._gauge - chapter.GAUGE_START, "commands": repeated.commands})
        chapter._gauge = chapter.GAUGE_START
        chapter._used_combo_keys = []
        # Leave exactly this combo unused to capture the original randomized branch.
        for other in chapter.VALID_COMBOS:
            var other_key: String = "%s|%s" % [other.chapter, other.evidence]
            if other_key != key:
                chapter._used_combo_keys.append(other_key)
        var support := ExpressionContext.new([])
        await chapter._apply_pisuke(support)
        pisuke_traces.append({"chapter": combo.chapter, "evidence": combo.evidence,
            "delta": chapter._gauge - chapter.GAUGE_START, "commands": support.commands})
    var endings := []
    var body: String = source.get_slice("func minigame(bt):", 1).get_slice("# --- 導入 ---", 0)
    var pattern := RegEx.new()
    pattern.compile('bt.dialogue_band\\("narrator", (".*"), true\\)')
    for match_result in pattern.search_all(body):
        endings.append(JSON.parse_string(match_result.get_string(1)))
    if endings.size() != 2 or endings.has(null):
        push_error("Stage 3 ending source shape changed")
        quit(1)
        return
    var output := {"format": "godot-stage3-minigame", "version": 1,
        "chapter_path": "res://battle/chapters/Stage3MinigameChapter.gd",
        "gauge_start": chapter.GAUGE_START, "gauge_max": chapter.GAUGE_MAX,
        "hit_delta": chapter.HIT_DELTA, "miss_delta": chapter.MISS_DELTA,
        "chapters": chapter.CHAPTERS, "evidences": chapter.EVIDENCES,
        "hit_chapter_keys": chapter.HIT_CHAPTER_KEYS, "miss_chapter_keys": chapter.MISS_CHAPTER_KEYS,
        "hit_evidence_keys": chapter.HIT_EVIDENCE_KEYS, "miss_evidence_keys": chapter.MISS_EVIDENCE_KEYS,
        "valid_combos": chapter.VALID_COMBOS, "intro": intro.commands,
        "traces": traces, "repeat_traces": repeat_traces, "pisuke_traces": pisuke_traces,
        "ending": {"win": endings[0], "lose": endings[1]}}
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
    print("Exported 225 original Stage 3 pairs, 7 repeats and 7 support traces")
    quit(0)
