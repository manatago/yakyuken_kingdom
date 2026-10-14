extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        push_error("Expected output and original Godot project")
        quit(1)
        return
    var source := FileAccess.get_file_as_string(args[1].path_join("game/BattleScene.gd"))
    var start := source.find("func _highlight_target(")
    var end := source.find("func _resolve_target(", start)
    if start < 0 or end < 0:
        push_error("Missing original highlight implementation")
        quit(1)
        return
    var adapter := GDScript.new()
    var blur_start := source.find("func _apply_bg_blur(")
    var blur_end := source.find("func _cleanup(", blur_start)
    adapter.source_code = "extends Control\nvar _highlight_tween: Tween\nvar _highlight_cursor: TextureRect\nvar _arrow_tex: Texture2D\nvar target: Control\nfunc _resolve_target(_name):\n\treturn target\n" + source.substr(start, end - start) + source.substr(blur_start, blur_end - blur_start)
    if adapter.reload() != OK:
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var scene := Control.new()
    scene.set_script(adapter)
    root.add_child(scene)
    var target := TextureRect.new()
    scene.add_child(target)
    target.position = Vector2(300, 200)
    target.size = Vector2(200, 100)
    scene.target = target
    scene._apply_bg_blur(target, 15.0)
    var blur := {"shader": target.material.shader.code, "amount": target.material.get_shader_parameter("blur_amount")}
    var cases := []
    for direction in ["left", "right", "top", "bottom", "auto"]:
        for name in ["hand_panel", "card_bar"]:
            var options := {"direction": direction, "offset_x": 50, "offset_y": 20}
            scene._highlight_target(name, options)
            var cursor = scene._highlight_cursor
            cases.append({"target": name, "rect": [300, 200, 200, 100], "options": options,
                "position": [cursor.position.x, cursor.position.y], "size": [cursor.size.x, cursor.size.y],
                "pivot": [cursor.pivot_offset.x, cursor.pivot_offset.y], "flip_h": cursor.flip_h,
                "rotation": cursor.rotation})
            scene._unhighlight()
            await process_frame
    var pulse := []
    for index in range(41):
        pulse.append(Tween.interpolate_value(1.0, 0.3, float(index) / 100.0, 0.4, Tween.TRANS_SINE, Tween.EASE_IN_OUT))
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    file.store_string(JSON.stringify({"scope": "actual-highlight-method-isolated-controls", "cases": cases,
        "blur": blur,
        "pulse_samples": pulse, "source_hash": FileAccess.get_sha256(args[1].path_join("game/BattleScene.gd"))}, "  "))
    file.close()
    scene.free()
    print("Original highlight geometry and SINE pulse captured")
    quit(0)
