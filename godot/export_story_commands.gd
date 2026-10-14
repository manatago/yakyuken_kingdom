extends SceneTree

func _initialize() -> void:
    call_deferred("export_commands")

func serialize(value):
    if value is Vector2:
        return {"type": "Vector2", "x": value.x, "y": value.y}
    if value is Color:
        return {"type": "Color", "r": value.r, "g": value.g, "b": value.b, "a": value.a}
    if value is Array:
        var values := []
        for entry in value:
            values.append(serialize(entry))
        return values
    if value is Dictionary:
        var values := {}
        for key in value:
            values[key] = serialize(value[key])
        return values
    if value == null or value is String or value is bool or value is int or value is float:
        return value
    push_error("Unsupported story property: " + str(value))
    return null

func properties(value) -> Dictionary:
    var result := {}
    for property in value.get_property_list():
        if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name != "chapter":
            result[property.name] = serialize(value.get(property.name))
    return result

func command_kind(command) -> String:
    if command is StoryCommands.Line: return "line"
    if command is StoryCommands.Background: return "background"
    if command is StoryCommands.BgFilter: return "bg_filter"
    if command is StoryCommands.TerminalEffect: return "terminal_effect"
    if command is StoryCommands.Pause: return "pause"
    if command is StoryCommands.ShowCharacter: return "show_character"
    if command is StoryCommands.HideCharacter: return "hide_character"
    if command is StoryCommands.Band: return "band"
    if command is StoryCommands.SetFlag: return "set_flag"
    if command is StoryCommands.BandColor: return "band_color"
    if command is StoryCommands.HideDialogue: return "hide_dialogue"
    if command is StoryCommands.AnimatePortrait: return "animate_portrait"
    if command is StoryCommands.StopPortraitAnimation: return "stop_portrait_animation"
    if command is StoryCommands.Battle: return "battle"
    if command is StoryCommands.MicroMotion: return "micro_motion"
    if command is StoryCommands.SeqLabel: return "label"
    push_error("Unsupported story command")
    return "unsupported"

func export_commands() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Expected output JSON path")
        quit(1)
        return
    var story = load("res://story/DefaultStory.gd").new()
    var cast := {}
    for id in story.get_cast():
        cast[id] = properties(story.get_cast()[id])
    var sequences := []
    for id in story.get_sequence_ids():
        var commands := []
        for entry in story.get_sequence(id).entries:
            commands.append({"kind": command_kind(entry), "parameters": properties(entry)})
        sequences.append({"id": id, "commands": commands})
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if file == null:
        push_error("Cannot open story output")
        quit(1)
        return
    file.store_string(JSON.stringify({"format": "godot-story-commands", "version": 1,
        "cast": cast, "portrait_layouts": load("res://story/PortraitLayout.gd").LAYOUT,
        "sequences": sequences}, "  "))
    file.close()
    print("Exported original sequences: ", sequences.size())
    quit(0)
