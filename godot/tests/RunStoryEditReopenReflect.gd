extends SceneTree
# 同一セッション中に「保存 → 編集を閉じる → 同じシーケンスを開き直す」で
# 保存値が反映されているかを検証する。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditReopenReflect.gd

func _check(cond: bool, msg: String):
	if cond:
		printerr("[RR] PASS: %s" % msg)
	else:
		printerr("[RR] FAIL: %s" % msg)

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _find_visible_card(layout: Control) -> PanelContainer:
	for nm in ["StoryEditCard_Left", "StoryEditCard_Right"]:
		var c: PanelContainer = layout.find_child(nm, true, false)
		if c and c.visible and c.has_meta("bound_rect"):
			var r = c.get_meta("bound_rect")
			if is_instance_valid(r):
				return c
	return null

func _drive_open(main_inst, entry: Dictionary) -> Control:
	var coro = func():
		await main_inst._run_story_edit(entry)
	coro.call()
	for _w in range(80): await process_frame
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			return child
	return null

func _exit(layout: Control):
	if not layout: return
	var nav: PanelContainer = layout.find_child("StoryEditNavBar", true, false)
	if nav:
		var exit_btn: Button = nav.find_child("ExitBtn", true, false)
		if exit_btn:
			exit_btn.pressed.emit()
	for _w in range(20): await process_frame

func _initialize():
	printerr("[RR] start")
	var gs = preload("res://game/GameState.gd").new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var src := "res://story/chapters/PrologueChapter.gd"
	var snapshot := _read(src)

	# 1回目: scene_university を開く → 保存 → 終了
	var layout1: Control = await _drive_open(main_inst, {"id": "prologue", "label": "scene_university", "name": "Prologue 大学"})
	_check(layout1 != null, "1st open layout exists")
	var card1: PanelContainer = _find_visible_card(layout1)
	_check(card1 != null, "1st open card exists")
	var initial_scale: float = 0.0
	if card1:
		var sl1: Dictionary = main_inst._get_edit_sliders(card1)
		initial_scale = sl1.scale.value
		printerr("[RR] 1st open initial scale = %.2f" % initial_scale)
		sl1.scale.value = 0.83
		sl1.x.value = 22
		sl1.y.value = -33
		await process_frame
		var save_btn: Button = card1.find_child("SaveBtn", true, false)
		if save_btn: save_btn.pressed.emit()
		for _w in range(3): await process_frame
		printerr("[RR] 1st save: %s" % (card1.find_child("InfoLabel", true, false) as Label).text)
	await _exit(layout1)

	# 2回目: 同じシーケンスを開く → スライダーが保存値か？
	var layout2: Control = await _drive_open(main_inst, {"id": "prologue", "label": "scene_university", "name": "Prologue 大学"})
	_check(layout2 != null, "2nd open layout exists")
	var card2: PanelContainer = _find_visible_card(layout2)
	_check(card2 != null, "2nd open card exists")
	if card2:
		var sl2: Dictionary = main_inst._get_edit_sliders(card2)
		var reopen_scale: float = sl2.scale.value
		printerr("[RR] 2nd open scale = %.2f (saved 0.83)" % reopen_scale)
		_check(abs(reopen_scale - 0.83) < 0.001, "reopen reflects saved scale 0.83")
	await _exit(layout2)

	_write(src, snapshot)
	printerr("[RR] (file restored)")
	quit(0)
