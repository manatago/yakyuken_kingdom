extends SceneTree

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        push_error("Expected original Main.gd and output JSON")
        quit(1)
        return
    var source := FileAccess.get_file_as_string(args[0])
    var adapter := "extends RefCounted\n"
    var hashes := {}
    for declaration in ["const DEFAULT_INVENTORY:", "var _jump_points:", "const STORY_EDIT_SEQUENCES", "const EVENT_BATTLE_CHAPTERS"]:
        var start := source.find(declaration)
        var end := source.find("\n]", start)
        if start < 0 or end < 0:
            push_error("Missing original declaration " + declaration)
            quit(1)
            return
        var declaration_source := source.substr(start, end + 2 - start)
        adapter += declaration_source + "\n"
        hashes[declaration] = declaration_source.sha256_text()
    var script := GDScript.new()
    script.source_code = adapter
    if script.reload() != OK:
        quit(1)
        return
    var data = script.new()
    var constants := script.get_script_constant_map()
    var output := FileAccess.open(args[1], FileAccess.WRITE)
    if output == null:
        quit(1)
        return
    output.store_string(JSON.stringify({"format": "godot-developer-tools", "version": 1,
        "jump_points": data._jump_points, "story_targets": constants.STORY_EDIT_SEQUENCES,
        "battle_targets": constants.EVENT_BATTLE_CHAPTERS, "source_hashes": hashes}, "  ", true) + "\n")
    output.close()
    quit(0)
