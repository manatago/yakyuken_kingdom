extends "res://capture_story_skip.gd"

var _details := {}

func perform_action(scene) -> void:
    scene._skip_typing()
    scene._on_item_pressed()
    await process_frame
    scene._story_modal.get_child(0).get_children().back().grab_focus()
    var before: Dictionary = scene.capture_dialogue()
    var echo := InputEventKey.new()
    echo.keycode = KEY_ENTER
    echo.pressed = true
    echo.echo = true
    Input.parse_input_event(echo)
    await process_frame
    _details["echo_preserves_dialogue"] = scene.capture_dialogue() == before
    var accept := InputEventKey.new()
    accept.keycode = KEY_ENTER
    accept.pressed = true
    Input.parse_input_event(accept)
    await process_frame
    _details["viewer_stays_open"] = scene._story_modal != null

func capture_scope() -> String:
    return "ui-accept-with-focused-viewer-close"

func action_details() -> Dictionary:
    return _details
