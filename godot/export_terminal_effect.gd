extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func accept(scene) -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_ENTER
    event.pressed = true
    scene._input(event)

func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Expected terminal output JSON")
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var scene = load("res://StoryScene.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    var story = load("res://story/DefaultStory.gd").new()
    var entry = story.get_sequence("stage1").entries[52]
    entry.execute(scene)
    var terminal: RichTextLabel = null
    for frame in range(1200):
        await process_frame
        for child in scene.get_children():
            if child is RichTextLabel:
                terminal = child
        if terminal and not terminal.text.is_empty():
            break
    if not terminal or terminal.text.is_empty():
        push_error("Terminal did not type")
        quit(1)
        return
    accept(scene)
    var full_text: String = "\n".join(entry.lines) + "\n█"
    for frame in range(1200):
        await process_frame
        if terminal.text == full_text:
            break
    if terminal.text != full_text:
        push_error("Terminal skip did not show original full text")
        quit(1)
        return
    await process_frame
    var rect: Rect2 = terminal.get_global_rect()
    var color: Color = terminal.get_theme_color("default_color")
    var style := {"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
        "font_size": terminal.get_theme_font_size("normal_font_size"), "color": [color.r, color.g, color.b, color.a]}
    accept(scene)
    var first_wait_accept_stays_open: bool = scene._terminal_active
    accept(scene)
    for frame in range(1200):
        await process_frame
        if not scene._terminal_active:
            break
    if scene._terminal_active:
        push_error("Terminal second wait accept did not close")
        quit(1)
        return
    var output := {"scope": "isolated-actual-terminal-input", "sequence": "stage1", "cursor": 53,
        "source_hash": FileAccess.get_sha256("res://game/StoryScene.gd"), "full_text": full_text,
        "style": style,
        "first_wait_accept_stays_open": first_wait_accept_stays_open, "second_wait_accept_closes": not scene._terminal_active}
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if not file:
        push_error("Cannot write terminal capture")
        quit(1)
        return
    file.store_string(JSON.stringify(output, "  "))
    file.close()
    scene.free()
    print("Actual terminal input captured")
    quit(0)
