extends "res://export_prologue_battle.gd"

# Capture canonical instructions/configuration; random outcomes are explicit fixtures.
func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() < 1 or args.size() > 2:
        push_error("Expected output JSON path and optional reference project path")
        quit(1)
        return
    var chapters := []
    for name in ["ThiefJin", "ThiefMarco", "ThiefGald", "Belka", "Sister", "Fiona", "Receptionist"]:
        var path = "res://battle/chapters/" + name + "BattleChapter.gd"
        var source_path = path if args.size() == 1 else args[1].path_join("battle/chapters/" + name + "BattleChapter.gd")
        var chapter = load(source_path).new()
        var setup = TraceContext.new([])
        await chapter.setup_scene(setup)
        var traces := []
        for hp in range(chapter.get_opponent_outfit_count(), 0, -1):
            for result in ["win", "lose", "draw"]:
                var context = TraceContext.new([result])
                await chapter.call("outfit_" + str(hp), context)
                traces.append({"method": "outfit_" + str(hp), "outcomes": [result], "commands": context.commands})
        chapters.append({"chapter_path": path, "opponent_id": chapter.get_opponent_id(),
            "opponent_name": chapter.get_opponent_name(), "background": chapter.get_battle_background(),
            "opponent_deck": chapter.get_opponent_hand(), "player_deck_size": chapter.get_player_deck_size(),
            "opponent_deck_size": chapter.get_opponent_deck_size(), "player_hp": chapter.get_player_outfit_count(),
            "opponent_hp": chapter.get_opponent_outfit_count(), "opponent_tendency": chapter.get_opponent_tendency(),
            "bayes_eye": chapter.has_bayes_eye(), "gold_reward": chapter.get_gold_reward(),
            "item_rewards": chapter.get_item_rewards() if chapter.has_method("get_item_rewards") else [],
            "can_lose_cards": chapter.can_lose_cards(), "can_gain_cards": chapter.can_gain_cards(),
            "lose_behavior": chapter.get_lose_behavior(), "lose_redirect": chapter.get_lose_redirect(),
            "farewell": {"win": chapter.get_farewell("win"), "lose": chapter.get_farewell("lose"), "draw": chapter.get_farewell("draw")},
            "setup": setup.commands, "traces": traces})
        chapter.free()
    var narration_path = "res://battle/SatoshiLoseNarrations.gd" if args.size() == 1 else args[1].path_join("battle/SatoshiLoseNarrations.gd")
    # The reference project may declare a class already registered in this project.
    # Compile its unchanged implementation without registering a second global name.
    var narrations := GDScript.new()
    narrations.source_code = FileAccess.get_file_as_string(narration_path).replace("class_name SatoshiLoseNarrations\n", "")
    if narrations.reload() != OK:
        push_error("Cannot compile original loss narrations")
        quit(1)
        return
    var temporary_path = args[0] + ".tmp"
    var file := FileAccess.open(temporary_path, FileAccess.WRITE)
    if file == null:
        push_error("Cannot open trace output")
        quit(1)
        return
    file.store_string(JSON.stringify({"format": "godot-quest-battle-traces", "version": 1, "chapters": chapters,
        "lose_narrations": {"patterns": narrations.PATTERNS, "ids": narrations.ALL_IDS,
            "replacement_cost": narrations.REPLACEMENT_COST}}, "  "))
    file.close()
    if DirAccess.rename_absolute(temporary_path, args[0]) != OK:
        push_error("Cannot replace trace output")
        quit(1)
        return
    print("Exported ", chapters.size(), " original quest battle chapters")
    quit(0)
