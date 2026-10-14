extends SceneTree

# Developer-only capture of actual controls, not replacement story logic.
func _initialize() -> void:
    call_deferred("export_geometry")

func rect_values(control: Control) -> Array:
    var rect := control.get_global_rect()
    return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func color_values(color: Color) -> Array:
    return [color.r, color.g, color.b, color.a]

func export_geometry() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Expected output JSON path")
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var scene = load("res://StoryScene.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    scene.get_node("DialogueBand").visible = true
    await process_frame
    var menu = scene.get_node("DialogueBand/MenuBar")
    var buttons := []
    for button in menu.get_children():
        buttons.append({"id": button.name, "text": button.text, "rect": rect_values(button),
            "font_size": button.get_theme_font_size("font_size")})
    var viewers := {}
    var first_button = menu.get_child(0)
    var styles := {"normal": color_values(first_button.get_theme_stylebox("normal").bg_color),
        "hover": color_values(first_button.get_theme_stylebox("hover").bg_color),
        "font": color_values(first_button.get_theme_color("font_color")),
        "font_hover": color_values(first_button.get_theme_color("font_hover_color"))}
    for kind in ["item", "equip"]:
        scene.call("_on_" + kind + "_pressed")
        await process_frame
        await process_frame
        viewers[kind] = {"rect": rect_values(scene._story_modal)}
        scene._close_story_modal()
        await process_frame
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if not file:
        push_error("Cannot write original menu geometry")
        quit(1)
        return
    file.store_string(JSON.stringify({"scope": "story-menu-controls-empty-inventory", "version": 1,
        "source_hashes": {"StoryScene.tscn": FileAccess.get_sha256("res://StoryScene.tscn"),
            "game/StoryScene.gd": FileAccess.get_sha256("res://game/StoryScene.gd"),
            "game/GameState.gd": FileAccess.get_sha256("res://game/GameState.gd")},
        "viewport": [root.size.x, root.size.y], "menu_rect": rect_values(menu),
        "buttons": buttons, "viewers": viewers, "styles": styles}, "  "))
    file.close()
    scene.free()
    print("Original menu controls captured")
    quit(0)
