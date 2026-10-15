extends SceneTree

# Geometry adapter, not a full playthrough: temporal effects and battles are not run.
func _initialize() -> void:
    call_deferred("export_geometry")

func export_geometry() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Expected geometry output JSON")
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var story = load("res://story/DefaultStory.gd").new()
    var sequences := []
    var ignored_battles := 0
    var viewport := Vector2.ZERO
    for id in story.get_sequence_ids():
        var scene = load("res://StoryScene.tscn").instantiate()
        root.add_child(scene)
        scene.set_cast(story.get_cast())
        await process_frame
        viewport = scene.get_viewport_rect().size
        if viewport != Vector2(1920, 1080):
            push_error("Unexpected original geometry viewport: " + str(viewport))
            quit(1)
            return
        var frames := []
        var cursor := 0
        for entry in story.get_sequence(id).entries:
            cursor += 1
            if entry is StoryCommands.Battle:
                ignored_battles += 1
                continue
            if entry is StoryCommands.ShowCharacter:
                entry.appear_duration = 0.0
                entry.transition = ""
                entry.execute(scene)
            elif entry is StoryCommands.HideCharacter:
                entry.exit_duration = 0.0
                entry.wait_for_exit = false
                entry.wait_after = 0.0
                entry.execute(scene)
            elif entry is StoryCommands.Band or entry is StoryCommands.Line:
                entry.wait_for_input = false
                entry.execute(scene)
            else:
                continue
            var slots := []
            for side in ["left", "center", "right"]:
                var rect = scene._get_rect_for_side(side)
                if not rect.visible or not rect.texture:
                    continue
                slots.append({"side": side, "path": rect.texture.resource_path,
                    "position": [rect.position.x, rect.position.y], "scale": rect.scale.x,
                    "size": [rect.texture.get_width(), rect.texture.get_height()],
                    "rect_size": [rect.size.x, rect.size.y], "flipped": rect.flip_h})
            frames.append({"cursor": cursor, "slots": slots})
        sequences.append({"id": id, "frames": frames})
        scene.free()
        await process_frame
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if not file:
        push_error("Cannot write geometry output")
        quit(1)
        return
    file.store_string(JSON.stringify({"scope": "standalone-portrait-geometry", "version": 1,
        "viewport": [viewport.x, viewport.y], "ignored_battles": ignored_battles, "sequences": sequences}, "  "))
    file.close()
    print("Original standalone geometry exported: ", sequences.size(), " sequences")
    quit(0)
