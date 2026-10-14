extends "res://export_prologue_battle.gd"

class AdventurerContext extends TraceContext:
    func narrator_band(text, speaker = "", icon_path = ""):
        add("narrator_band", [text, speaker, icon_path])
    func force_build_deck(cards): add("force_build_deck", [cards])
    func force_select_hand(hand):
        add("force_select_hand", [hand])
        return {"hand": hand, "grade": 1, "item": null}
    func show_bayes_eye(): add("show_bayes_eye", [])
    func hide_bayes_eye(): add("hide_bayes_eye", [])

func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Expected output JSON path")
        quit(1)
        return
    var script = load("res://battle/chapters/Stage1BattleChapter.gd")
    var chapter = script.new()
    var traces := []
    for result in ["win", "lose", "draw"]:
        var context = AdventurerContext.new([result])
        await chapter.tutorial(context)
        traces.append({"method": "tutorial", "outcomes": [result], "commands": context.commands})
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if file == null:
        push_error("Cannot open trace output")
        chapter.free()
        quit(1)
        return
    file.store_string(JSON.stringify({"format": "godot-battle-traces", "version": 1,
        "chapter_path": "res://battle/chapters/Stage1BattleChapter.gd",
        "opponent_id": chapter.get_opponent_id(), "background": chapter.get_battle_background(),
        "opponent_deck": chapter.get_opponent_hand(), "player_hp": chapter.get_player_outfit_count(),
        "opponent_hp": chapter.get_opponent_outfit_count(), "gold_reward": chapter.get_gold_reward(),
        "opponent_tendency": chapter.get_opponent_tendency(), "traces": traces}, "  "))
    file.close()
    chapter.free()
    print("Exported ", traces.size(), " original Stage 1 tutorial traces")
    quit(0)
