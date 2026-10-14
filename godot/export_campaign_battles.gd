extends "res://export_prologue_battle.gd"

# Execute unchanged chapter methods with the same GameState flag they read in game.
func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        push_error("Expected output JSON and reference Godot project")
        quit(1)
        return
    var state = root.get_node_or_null("GameState")
    if state == null:
        push_error("Original GameState autoload is required")
        quit(1)
        return
    var previous_flags: Dictionary = state.flags.duplicate(true)
    var chapters := []
    for stage in range(2, 7):
        var path := "res://battle/chapters/Stage%dBattleChapter.gd" % stage
        var script = load(args[1].path_join("battle/chapters/Stage%dBattleChapter.gd" % stage))
        if script == null:
            push_error("Cannot load original campaign chapter")
            quit(1)
            return
        for first in [true, false]:
            state.flags = {"stage%d_first_battle_done" % stage: not first}
            var chapter = script.new()
            if chapter._is_first_battle() != first:
                push_error("Original chapter flag selection differs")
                quit(1)
                return
            var setup := TraceContext.new([])
            await chapter.setup_scene(setup)
            var traces := []
            for hp in range(chapter.get_opponent_outfit_count(), 0, -1):
                for outcome in ["win", "lose", "draw"]:
                    var context := TraceContext.new([outcome])
                    await chapter.call("outfit_%d" % hp, context)
                    traces.append({"method": "outfit_%d" % hp, "outcomes": [outcome], "commands": context.commands})
            chapters.append({"chapter_path": path, "first_battle": first,
                "flag_key": "stage%d_first_battle_done" % stage,
                "opponent_id": chapter.get_opponent_id(), "opponent_name": chapter.get_opponent_name(),
                "background": chapter.get_battle_background(), "opponent_deck": chapter.get_opponent_hand(),
                "player_deck_size": chapter.get_player_deck_size(), "opponent_deck_size": chapter.get_opponent_deck_size(),
                "player_hp": chapter.get_player_outfit_count(), "opponent_hp": chapter.get_opponent_outfit_count(),
                "opponent_tendency": chapter.get_opponent_tendency(), "bayes_eye": chapter.has_bayes_eye(),
                "gold_reward": chapter.get_gold_reward(), "item_rewards": chapter.get_item_rewards() if chapter.has_method("get_item_rewards") else [],
                "card_reward": chapter.get_card_reward() if chapter.has_method("get_card_reward") else {},
                "can_lose_cards": chapter.can_lose_cards(), "can_gain_cards": chapter.can_gain_cards(),
                "lose_behavior": chapter.get_lose_behavior(), "lose_redirect": chapter.get_lose_redirect(),
                "farewell": {"win": chapter.get_farewell("win"), "lose": chapter.get_farewell("lose"), "draw": chapter.get_farewell("draw")},
                "setup": setup.commands, "traces": traces})
            chapter.free()
    state.flags = previous_flags
    var temporary_path: String = args[0] + ".tmp"
    var file := FileAccess.open(temporary_path, FileAccess.WRITE)
    if file == null:
        quit(1)
        return
    file.store_string(JSON.stringify({"format": "godot-campaign-battle-traces", "version": 1, "chapters": chapters}, "  "))
    file.close()
    if DirAccess.rename_absolute(temporary_path, args[0]) != OK:
        quit(1)
        return
    print("Exported 10 original campaign configurations and 90 result traces")
    quit(0)
