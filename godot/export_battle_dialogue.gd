extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func rect(node: Control) -> Array:
    var value := node.get_global_rect()
    return [value.position.x, value.position.y, value.size.x, value.size.y]

func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var source := FileAccess.get_file_as_string("res://game/BattleScene.gd")
    var start := source.find("func _position_battle_dialogue_band(")
    var end := source.find("\nfunc ", start + 1)
    var narrator_start := source.find("func narrator_band(")
    var narrator_end := source.find("\nfunc ", narrator_start + 1)
    var adapter := GDScript.new()
    adapter.source_code = "extends Control\nvar _is_minigame = false\nvar _story_scene\n" + source.substr(start, end - start)
    if adapter.reload() != OK:
        quit(1)
        return
    var bridge := Control.new()
    bridge.set_script(adapter)
    bridge.size = Vector2(1920, 1080)
    root.add_child(bridge)
    var scene = load("res://StoryScene.tscn").instantiate()
    bridge.add_child(scene)
    bridge._story_scene = scene
    var character = load("res://story/StoryCharacter.gd").new()
    character.id = "speaker"
    character.display_name = "マチルダ"
    character.default_side = "center"
    scene.set_cast({"speaker": character})
    var commands = load("res://story/StoryCommands.gd")
    var cases := []
    for mode in ["battle", "selection", "minigame"]:
        for speaker in ["speaker", "narrator"]:
            var band = scene.dialogue_band
            band.offset_top = -220
            band.offset_bottom = 0
            bridge._is_minigame = mode == "minigame"
            bridge._position_battle_dialogue_band(mode == "selection")
            var entry = commands.Band.new()
            entry.speaker_id = speaker
            entry.side_override = "center"
            entry.text = "原本の会話欄を確認する。"
            entry.wait_for_input = false
            scene.apply_band_command(entry)
            await process_frame
            await process_frame
            var label = scene.dialogue_band_body
            var speaker_label = scene.dialogue_band_speaker
            cases.append({"mode": mode, "speaker": speaker, "band": rect(band),
                "body": rect(label), "speaker_rect": rect(speaker_label), "speaker_visible": speaker_label.visible,
                "font_size": label.get_theme_font_size("font_size"), "speaker_font_size": speaker_label.get_theme_font_size("font_size"),
                "text_color": [label.get_theme_color("font_color").r, label.get_theme_color("font_color").g,
                    label.get_theme_color("font_color").b, label.get_theme_color("font_color").a],
                "line_height": label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")),
                "color": [band.get_theme_stylebox("panel").bg_color.r, band.get_theme_stylebox("panel").bg_color.g,
                    band.get_theme_stylebox("panel").bg_color.b, band.get_theme_stylebox("panel").bg_color.a]})
    var palettes := []
    var story = load("res://story/DefaultStory.gd").new()
    for id in story.get_sequence_ids():
        for entry in story.get_sequence(id).entries:
            if entry is StoryCommands.BandColor:
                entry.execute(scene)
                var button = scene.get_node("DialogueBand/MenuBar").get_child(0)
                var normal: Color = button.get_theme_stylebox("normal").bg_color
                var hover: Color = button.get_theme_stylebox("hover").bg_color
                palettes.append({"color": [entry.color.r, entry.color.g, entry.color.b, entry.color.a],
                    "normal": [normal.r, normal.g, normal.b, normal.a], "hover": [hover.r, hover.g, hover.b, hover.a]})
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    file.store_string(JSON.stringify({"scope": "actual-central-battle-dialogue-controls", "cases": cases, "palettes": palettes,
        "method_hashes": {"_position_battle_dialogue_band": source.substr(start, end - start).sha256_text(),
            "narrator_band": source.substr(narrator_start, narrator_end - narrator_start).sha256_text()},
        "source_hashes": {"game/BattleScene.gd": FileAccess.get_sha256("res://game/BattleScene.gd"),
            "game/StoryScene.gd": FileAccess.get_sha256("res://game/StoryScene.gd"), "StoryScene.tscn": FileAccess.get_sha256("res://StoryScene.tscn")}}, "  "))
    file.close()
    bridge.free()
    print("Actual battle dialogue geometry captured")
    quit(0)
