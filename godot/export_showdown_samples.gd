extends SceneTree

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 2:
        push_error("Expected output JSON and reference project path")
        quit(1)
        return
    var card := GDScript.new()
    card.source_code = FileAccess.get_file_as_string(args[1].path_join("game/Card.gd")).replace("class_name Card\n", "")
    if card.reload() != OK:
        push_error("Cannot compile original Card")
        quit(1)
        return
    var back_out := []
    for i in range(61):
        back_out.append(Tween.interpolate_value(0.0, 1.0, float(i) / 60.0, 1.0, Tween.TRANS_BACK, Tween.EASE_OUT))
    var reasons := {}
    for hand in ["rock", "scissors", "paper"]:
        for player_grade in range(1, 6):
            for opponent_grade in range(1, 6):
                reasons["%s:%d:%d" % [hand, player_grade, opponent_grade]] = card.format_same_hand_grade_reason(hand, player_grade, opponent_grade)
    var file := FileAccess.open(args[0], FileAccess.WRITE)
    if file == null:
        push_error("Cannot open showdown samples")
        quit(1)
        return
    file.store_string(JSON.stringify({"back_out": back_out, "grade_reasons": reasons}, "  "))
    file.close()
    print("Exported original BACK/OUT samples and 75 grade reasons")
    quit(0)
