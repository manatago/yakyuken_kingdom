extends SceneTree

# Bounded developer probe of the real Skip handler and sequence loop.
# The prefix is reconstructed without temporal effects; the suffix runs normally.
func _initialize() -> void:
    call_deferred("capture")

func perform_action(scene) -> void:
    scene._on_skip_pressed()

func capture_scope() -> String:
    return "single-skip-from-reconstructed-prefix"

func action_details() -> Dictionary:
    return {}

func allows_sequence_end() -> bool:
    return false

func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 3 and args.size() != 4:
        push_error("Expected sequence, cursor and output JSON")
        quit(1)
        return
    root.size = Vector2i(1920, 1080)
    var story = load("res://story/DefaultStory.gd").new()
    var sequence = story.get_sequence(args[0])
    var cursor := int(args[1])
    if not sequence or cursor < 1 or cursor > sequence.entries.size():
        push_error("Invalid Skip probe cursor")
        quit(1)
        return
    var scene = load("res://StoryScene.tscn").instantiate()
    root.add_child(scene)
    scene.set_cast(story.get_cast())
    await process_frame
    for i in range(cursor - 1):
        var entry = sequence.entries[i]
        if entry is StoryCommands.Battle:
            push_error("Skip probe prefix cannot cross a battle")
            quit(1)
            return
        if entry is StoryCommands.Band or entry is StoryCommands.Line:
            entry.wait_for_input = false
        if entry is StoryCommands.ShowCharacter:
            entry.appear_duration = 0.0
            entry.transition = ""
        if entry is StoryCommands.HideCharacter:
            entry.exit_duration = 0.0
            entry.wait_after = 0.0
        if entry is StoryCommands.Background:
            entry.fade = 0.0
        if entry is StoryCommands.Pause:
            entry.duration = 0.0
        if entry is StoryCommands.TerminalEffect:
            entry.char_delay = 0.0
            entry.line_delay = 0.0
            entry.hold_time = 0.0
        var result = entry.execute(scene)
        if result is Signal:
            await result
    var suffix := StoryCommands.Sequence.new()
    suffix.id = sequence.id
    suffix.entries = sequence.entries.slice(cursor - 1)
    scene.call_deferred("play_sequence", suffix)
    for frame in range(300):
        await process_frame
        if scene._waiting_for_input:
            break
    if not scene._waiting_for_input:
        push_error("Skip probe did not reach initial input wait")
        quit(1)
        return
    await perform_action(scene)
    for frame in range(300):
        await process_frame
        if scene._waiting_for_input and not suffix._skipping:
            break
        if allows_sequence_end() and not scene._sequence_playing:
            break
    var ended: bool = allows_sequence_end() and not scene._sequence_playing
    if not ended and (not scene._waiting_for_input or suffix._skipping):
        push_error("Skip probe did not stop at the next background")
        quit(1)
        return
    var dialogue: Dictionary = scene.capture_dialogue()
    var displayed_text: String = dialogue.l_body if dialogue.l_visible else dialogue.r_body if dialogue.r_visible else dialogue.n_body
    var matches := []
    for i in range(cursor, sequence.entries.size()):
        var entry = sequence.entries[i]
        if (entry is StoryCommands.Band or entry is StoryCommands.Line) and entry.wait_for_input and entry.text == displayed_text:
            matches.append(i + 1)
    if not ended and matches.size() != 1:
        push_error("Skip probe final input boundary is not unique")
        quit(1)
        return
    var output := {"scope": capture_scope(), "sequence": args[0], "cursor": cursor,
        "end_cursor": sequence.entries.size() if ended else matches[0],
        "source_hashes": {"game/StoryScene.gd": FileAccess.get_sha256("res://game/StoryScene.gd"),
            "story/StoryCommands.gd": FileAccess.get_sha256("res://story/StoryCommands.gd")},
        "background": root.get_node("GameState").background, "dialogue": dialogue,
        "side_cache": scene._character_side_cache.duplicate(), "position_cache": scene._character_position_cache.duplicate()}
    var details: Dictionary = await action_details()
    if not details.is_empty():
        output["action_details"] = details
    var file := FileAccess.open(args[2], FileAccess.WRITE)
    if not file:
        push_error("Cannot write Skip probe")
        quit(1)
        return
    file.store_string(JSON.stringify(output, "  "))
    file.close()
    scene._abort_sequence = true
    scene._trigger_advance()
    scene.free()
    print("Actual original Skip captured")
    quit(0)
