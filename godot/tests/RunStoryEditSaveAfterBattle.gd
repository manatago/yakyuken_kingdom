extends SceneTree
# 通常バトル後（editor_capture=false）にストーリー編集を開いても保存できることを検証。
# 修正前: editor_capture が false のまま章再ロード → edit_source_id 無し → 保存NG。
# 修正後: _run_story_edit が editor_capture を true に戻す → 保存OK。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveAfterBattle.gd

const GameStateScript := preload("res://game/GameState.gd")

func _check(c, m): printerr("[AB] %s: %s" % [("PASS" if c else "FAIL"), m])

func _read(p):
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t
func _write(p, c):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _find_card(layout):
	for nm in ["StoryEditCard_Left","StoryEditCard_Right"]:
		var c = layout.find_child(nm, true, false)
		if c and c.visible and c.has_meta("bound_rect") and is_instance_valid(c.get_meta("bound_rect")):
			return c
	return null

func _initialize():
	printerr("[AB] start")
	var gs = GameStateScript.new(); gs.name="GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# ★通常バトルを模擬: editor_capture を false にする（BattleScene.start_battle 相当）
	StoryCommands.editor_capture = false
	printerr("[AB] editor_capture forced to false (通常バトル後を模擬)")

	var src := "res://story/chapters/Subevent3Chapter.gd"  # source_file フォールバック無しの章
	var snap: String = _read(src)
	var entry := {"id": "subevent3_pre", "name": "Subevent3"}
	var coro = func(): await main_inst._run_story_edit(entry)
	coro.call()
	for _w in range(100): await process_frame

	var layout = null
	for ch in main_inst.get_children():
		if ch is Control and ch.name == "StoryEditRoot": layout = ch; break
	_check(layout != null, "StoryEditRoot exists")
	if not layout: quit(1); return

	_check(StoryCommands.editor_capture == true, "editor_capture restored to true by _run_story_edit")

	var card = _find_card(layout)
	_check(card != null, "visible card with bound rect")
	if card:
		var sl = main_inst._get_edit_sliders(card)
		sl.scale.value = 0.59
		sl.x.value = 22
		sl.y.value = -33
		for _w in range(3): await process_frame
		var save_btn = card.find_child("SaveBtn", true, false)
		save_btn.pressed.emit()
		for _w in range(4): await process_frame
		var info = card.find_child("InfoLabel", true, false)
		printerr("[AB] save info: %s" % info.text)
		_check(info.text.begins_with("[保存]"), "save succeeded after battle (got '%s')" % info.text)

	var nav = layout.find_child("StoryEditNavBar", true, false)
	if nav:
		var ex = nav.find_child("ExitBtn", true, false)
		if ex: ex.pressed.emit()
	for _w in range(20): await process_frame
	_write(src, snap)
	printerr("[AB] (file restored)")
	quit(0)
