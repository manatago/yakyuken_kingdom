extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func rect(control: Control) -> Array:
    var value := control.get_global_rect()
    return [value.position.x, value.position.y, value.size.x, value.size.y]

func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Expected inventory geometry output")
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var state = root.get_node("GameState")
    var database = load("res://game/ItemDatabase.gd")
    state.money = 75
    var shield: Dictionary = database.get_item("iron_shield").duplicate(true)
    shield["count"] = 2
    var substitute: Dictionary = database.get_item("substitute_card").duplicate(true)
    substitute["count"] = 1
    state.items = [shield, substitute]
    state.equipment = [database.get_item("gold_charm").duplicate(true)]
    var scene = load("res://StoryScene.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    var viewers := {}
    var lifecycle := {}
    for key in ["item", "equip", "empty_item", "empty_equip"]:
        var kind: String = key.trim_prefix("empty_")
        if key.begins_with("empty_"):
            state.items = []
            state.equipment = []
        scene.call("_on_" + kind + "_pressed")
        await process_frame
        await process_frame
        var panel = scene._story_modal
        var controls: Array = panel.get_child(0).get_children()
        var scroll = controls[2 if kind == "item" else 1]
        var rows := []
        if scroll is ScrollContainer:
            for row in scroll.get_child(0).get_children():
                var icon = row.get_child(0)
                if not icon.texture:
                    push_error("Original inventory icon is not imported")
                    quit(1)
                    return
                rows.append({"rect": rect(row), "icon_rect": rect(icon), "text_rect": rect(row.get_child(1)),
                    "text": row.get_child(1).text})
        viewers[key] = {"rect": rect(panel), "title_rect": rect(controls[0]),
            "close_rect": rect(controls.back()), "rows": rows}
        viewers[key]["scroll_rect" if scroll is ScrollContainer else "empty_rect"] = rect(scroll)
        if kind == "item":
            var gold = controls[1]
            viewers[key]["gold"] = {"rect": rect(gold), "icon_rect": rect(gold.get_child(0)),
                "text_rect": rect(gold.get_child(1)), "text": gold.get_child(1).text}
        if key == "item":
            state.money = 999
            state.items = []
            scene.get_node("DialogueBand").visible = false
            await process_frame
            lifecycle = {"visible_with_hidden_band": panel.is_visible_in_tree(),
                "gold_after_state_change": controls[1].get_child(1).text,
                "rows_after_state_change": scroll.get_child(0).get_child_count()}
            scene.visible = false
            await process_frame
            lifecycle["visible_with_hidden_scene"] = panel.is_visible_in_tree()
            scene.visible = true
            await process_frame
            lifecycle["visible_after_scene_return"] = panel.is_visible_in_tree()
            scene.get_node("DialogueBand").visible = true
            state.money = 75
            state.items = [shield, substitute]
        scene._close_story_modal()
        await process_frame
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if not file:
        push_error("Cannot write inventory geometry")
        quit(1)
        return
    file.store_string(JSON.stringify({"scope": "actual-imported-populated-story-inventory", "viewers": viewers,
        "lifecycle": lifecycle,
        "icon_hash": FileAccess.get_sha256("res://assets/ui/icons/gold.png"),
        "source_hashes": {"StoryScene.tscn": FileAccess.get_sha256("res://StoryScene.tscn"),
            "game/StoryScene.gd": FileAccess.get_sha256("res://game/StoryScene.gd"),
            "game/GameState.gd": FileAccess.get_sha256("res://game/GameState.gd")}}, "  "))
    file.close()
    scene.free()
    print("Actual imported inventory geometry captured")
    quit(0)
