extends SceneTree
# ランダムバトル編集のフェーズ遷移検証: ◀(prev) / ▶(next) / 戻る(exit) で
# 編集パネルが期待通りのアクション文字列を返すかを直接検証する。
# 実行: Godot --path godot --headless --script res://tests/RunRandomPhaseNav.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[PHASE] PASS: %s" % msg)
	else:
		printerr("[PHASE] FAIL: %s" % msg)
		_fails += 1

# パネルを作って await した状態で、指定ボタンを emit して返り値を確認する
func _drive(main_inst, button_name: String, expected: String, label: String):
	var panel: PanelContainer = main_inst._create_edit_overlay({"name": "test"})
	main_inst.add_child(panel)
	await process_frame
	# coroutine を fire-and-forget で開始（結果は別途確認）
	var result: Array = [""]
	var coro = func():
		result[0] = await main_inst._random_wait_phase_action(panel)
	coro.call()
	await process_frame
	# 指定ボタンを押す
	var btn: Button = panel.find_child(button_name, true, false)
	if not btn:
		_check(false, "%s: button %s not found" % [label, button_name])
		panel.queue_free()
		return
	btn.pressed.emit()
	# 結果が入るまで数フレーム待つ
	for _w in range(10):
		await process_frame
		if result[0] != "":
			break
	_check(result[0] == expected, "%s: %s -> '%s' (expected '%s')" % [label, button_name, result[0], expected])
	panel.queue_free()
	await process_frame

func _initialize():
	printerr("[PHASE] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	await _drive(main_inst, "PrevBtn", "prev", "PrevBtn press")
	await _drive(main_inst, "NextBtn", "next", "NextBtn press")
	await _drive(main_inst, "EditBackButton", "exit", "EditBackButton press")

	printerr("[PHASE] done, fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
