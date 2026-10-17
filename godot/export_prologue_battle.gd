extends SceneTree

# Execute original script branches with explicit fixture outcomes. This records
# its instructions; it does not claim to reproduce the random battle engine.
class TraceCharacter extends RefCounted:
    var context
    var id: String
    func _init(p_context, p_id):
        context = p_context
        id = p_id
    func set_portrait(path, options = {}): context.add("set_portrait", [id, path, options])
    func band(text, options = {}): context.add("band", [id, text, options])
    func leave(options = {}): context.add("leave", [id, options])

class TraceContext extends RefCounted:
    var commands := []
    var outcomes := []
    var result_index := 0
    func _init(results): outcomes = results.duplicate()
    func add(kind: String, args: Array): commands.append({"kind": kind, "args": args})
    func character(id): return TraceCharacter.new(self, id)
    func set_bubble_side(side): add("set_bubble_side", [side])
    func highlight(target, options = {}): add("highlight", [target, options])
    func unhighlight(): add("unhighlight", [])
    func build_deck(): add("build_deck", [])
    func select_hand():
        add("select_hand", [])
        return 0
    func janken(selection, options = {}):
        var result = outcomes[result_index]
        result_index += 1
        add("janken", [selection, options, result])
        return result
    func deck(path, options = {}): add("deck", [path, options])
    func wait(duration): add("wait", [duration])
    func set_battle_ui_visible(value): add("set_battle_ui_visible", [value])
    func background(path): add("background", [path])
    func bubble(text, options = {}): add("bubble", [text, options])

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() > 0 and FileAccess.file_exists(args[0] + ".bak"):
        push_error("Editor backup exists; export to a separate file and reconcile edits instead of overwriting " + args[0])
        quit(1)
        return
    call_deferred("export_traces")

func export_traces() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Expected output JSON path")
        quit(1)
        return
    var script = load("res://battle/chapters/PrologueBattleChapter.gd")
    var traces := []
    for first in ["win", "lose", "draw"]:
        for second in ["win", "lose", "draw"]:
            var chapter = script.new()
            var context = TraceContext.new([first, second])
            await chapter.tutorial(context)
            traces.append({"method": "tutorial", "outcomes": [first, second], "commands": context.commands})
            chapter.free()
    for method in ["outfit_3", "outfit_2", "outfit_1"]:
        for result in ["win", "lose", "draw"]:
            var chapter = script.new()
            for repeated in [false, true]:
                var context = TraceContext.new([result])
                await chapter.call(method, context)
                traces.append({"method": method, "outcomes": [result], "repeated": repeated, "commands": context.commands})
            chapter.free()
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if file == null:
        push_error("Cannot open trace output")
        quit(1)
        return
    file.store_string(JSON.stringify({"format": "godot-battle-traces", "version": 1,
        "chapter_path": "res://battle/chapters/PrologueBattleChapter.gd", "traces": traces}, "  "))
    file.close()
    print("Exported ", traces.size(), " original prologue battle branch traces")
    quit(0)
