extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture_context(adapter: GDScript, story, id: String, entries: Array, cursor: int, command) -> Dictionary:
    var bridge := Control.new()
    bridge.set_script(adapter)
    bridge.size = Vector2(1920, 1080)
    root.add_child(bridge)
    var scene = load("res://StoryScene.tscn").instantiate()
    bridge.add_child(scene)
    bridge.story_scene_instance = scene
    scene.set_cast(story.get_cast())
    await process_frame
    for index in range(cursor - 1):
        var entry = entries[index]
        if entry is StoryCommands.Battle:
            continue
        if entry is StoryCommands.Band or entry is StoryCommands.Line:
            entry.wait_for_input = false
        if entry is StoryCommands.ShowCharacter:
            entry.appear_duration = 0
            entry.transition = ""
        if entry is StoryCommands.HideCharacter:
            entry.exit_duration = 0
            entry.wait_for_exit = false
            entry.wait_after = 0
        if entry is StoryCommands.Background:
            entry.fade = 0
        if entry is StoryCommands.Pause:
            entry.duration = 0
        if entry is StoryCommands.TerminalEffect:
            continue
        entry.execute(scene)
    var chapter = load(command.chapter_path).new()
    var farewell: Dictionary = chapter.get_farewell("lose")
    bridge.call("run", chapter, scene.background_rect.texture)
    var frames := []
    for index in range(20):
        await process_frame
        if bridge.complete:
            break
        if scene._waiting_for_input:
            var band = scene.dialogue_band
            var body = band.get_node("VBox/BodyLabel")
            var speaker = band.get_node("VBox/SpeakerLabel")
            var body_rect: Rect2 = body.get_global_rect()
            var speaker_rect: Rect2 = speaker.get_global_rect()
            frames.append({"body_text": body.text, "body_visible": body.is_visible_in_tree(),
                "speaker_text": speaker.text, "speaker_visible": speaker.is_visible_in_tree(),
                "body_rect": [body_rect.position.x, body_rect.position.y, body_rect.size.x, body_rect.size.y],
                "speaker_rect": [speaker_rect.position.x, speaker_rect.position.y, speaker_rect.size.x, speaker_rect.size.y],
                "band_visible": band.is_visible_in_tree(), "band_y": band.get_global_rect().position.y,
                "right_visible": scene.right_char.is_visible_in_tree(), "right_flip": scene.right_char.flip_h,
                "filtered": scene._auto_bg_filter_active})
            scene.advance_requested.emit()
    var complete: bool = bridge.complete
    chapter.free()
    bridge.free()
    if not complete:
        push_error("Farewell capture did not finish")
    return {"checkpoint": "original:%s:%d" % [id, cursor], "farewell": farewell, "frames": frames}

func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var source := FileAccess.get_file_as_string("res://game/Main.gd")
    var start := source.find("func _show_battle_farewell_in_scene(")
    var end := source.find("\n# --- リトライ", start)
    var adapter := GDScript.new()
    adapter.source_code = "extends Control\nvar story_scene_instance\nvar complete = false\nfunc run(chapter, bg):\n\tawait _show_battle_farewell_in_scene(chapter, \"lose\", bg)\n\tcomplete = true\n" + source.substr(start, end - start)
    if adapter.reload() != OK:
        quit(1)
        return
    var story = load("res://story/DefaultStory.gd").new()
    var cases := []
    for id in story.get_sequence_ids():
        var entries = story.get_sequence(id).entries
        for index in range(entries.size()):
            var command = entries[index]
            if command is StoryCommands.Battle and not command.is_tutorial and not command.is_minigame:
                cases.append(await capture_context(adapter, story, id, entries, index + 1, command))
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    file.store_string(JSON.stringify({"scope": "actual-main-farewell-from-reconstructed-prefixes", "cases": cases,
        "main_source_hash": FileAccess.get_sha256("res://game/Main.gd"),
        "method_hash": source.substr(start, end - start).sha256_text()}, "  "))
    file.close()
    print("Actual Main farewell controls captured: ", cases.size())
    quit(0)
