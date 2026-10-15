extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func collect(value, entries: Dictionary) -> void:
    if value is Array:
        for child in value:
            collect(child, entries)
    elif value is Dictionary:
        if value.get("kind") == "bubble":
            var args = value.args
            entries[JSON.stringify([args[0], args[1].get("side", "center")])] = args
        for child in value.values():
            collect(child, entries)

func rect(node: Control) -> Array:
    var value := node.get_global_rect()
    return [value.position.x, value.position.y, value.size.x, value.size.y]

func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var source := FileAccess.get_file_as_string("res://game/BattleScene.gd")
    var constants_start := source.find("const BUBBLE_SIDE_ANCHORS :=")
    var method_start := source.find("func _apply_bubble_side(")
    var method_end := source.find("var _bubble_indicator:", method_start)
    var adapter := GDScript.new()
    adapter.source_code = "extends Control\nvar speech_bubble\nvar bubble_label\n" + source.substr(constants_start, method_end - constants_start)
    if adapter.reload() != OK:
        quit(1)
        return
    var bridge := Control.new()
    bridge.set_script(adapter)
    bridge.size = Vector2(1920, 1080)
    root.add_child(bridge)
    var bubble = load("res://ui/SpeechBubble.tscn").instantiate()
    bridge.add_child(bubble)
    bridge.speech_bubble = bubble
    bridge.bubble_label = bubble.get_node("BubbleLabel")
    bridge._setup_bubble_style()
    var wrap = load("res://ui/BubbleWrap.gd")
    var entries := {}
    for name in ["godot-prologue-battle", "godot-quest-battles"]:
        collect(JSON.parse_string(FileAccess.get_file_as_string(args[1].path_join(name + ".json"))), entries)
    var cases := []
    for key in entries:
        var entry = entries[key]
        var text: String = entry[0]
        var side: String = entry[1].get("side", "center")
        var wrapped: String = wrap.wrap(text)
        bridge._apply_bubble_side(side)
        bridge.bubble_label.text = wrapped
        bridge._fit_bubble_to_text(wrapped)
        bubble.visible = true
        await process_frame
        cases.append({"text": text, "side": side, "wrapped": wrapped, "rect": rect(bubble), "body": rect(bridge.bubble_label),
            "font_size": bridge.bubble_label.get_theme_font_size("font_size"),
            "line_height": bridge.bubble_label.get_theme_font("font").get_height(34)})
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    file.store_string(JSON.stringify({"scope": "actual-explicit-bubble-controls-known-source-text", "cases": cases,
        "source_hashes": {"game/BattleScene.gd": FileAccess.get_sha256("res://game/BattleScene.gd"),
            "ui/SpeechBubble.tscn": FileAccess.get_sha256("res://ui/SpeechBubble.tscn"),
            "ui/BubbleFit.gd": FileAccess.get_sha256("res://ui/BubbleFit.gd"),
            "ui/BubbleWrap.gd": FileAccess.get_sha256("res://ui/BubbleWrap.gd")}}, "  "))
    file.close()
    bridge.free()
    print("Actual explicit bubble geometry captured: ", cases.size())
    quit(0)
