extends SceneTree
# 複数のストーリーシーケンスで保存が機能するか網羅検証する。
# どのシーケンスで失敗するかを特定するため、各章をテストし NG メッセージを記録。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveMulti.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[MS] PASS: %s" % msg)
	else:
		printerr("[MS] FAIL: %s" % msg)
		_fails += 1

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

func _drive_sequence(main_inst, entry: Dictionary) -> String:
	# 1回 story edit を起動 → 1回保存 → 終了
	# 失敗した場合は InfoLabel テキストを返す
	# 成功した場合は "OK" を返す
	# ファイルを書き換えるので呼び元はスナップショット→復元のループでラップ
	var done: Array = [false]
	var coro = func():
		await main_inst._run_story_edit(entry)
		done[0] = true
	coro.call()
	for _w in range(80): await process_frame

	var layout: Control = null
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			layout = child; break
	if not layout:
		return "no layout"

	var card: PanelContainer = _find_visible_card(layout)
	if not card:
		# 終了して return
		var nav: PanelContainer = layout.find_child("StoryEditNavBar", true, false)
		if nav:
			var exit_btn0: Button = nav.find_child("ExitBtn", true, false)
			if exit_btn0: exit_btn0.pressed.emit()
		for _w in range(20): await process_frame
		return "no visible card"

	var sl: Dictionary = main_inst._get_edit_sliders(card)
	sl.scale.value = 0.85
	sl.x.value = 99
	sl.y.value = -11
	for _w in range(3): await process_frame
	var save_btn: Button = card.find_child("SaveBtn", true, false)
	var info_text: String = ""
	if save_btn:
		save_btn.pressed.emit()
		for _w in range(5): await process_frame
		var info: Label = card.find_child("InfoLabel", true, false)
		info_text = info.text if info else ""

	# 終了
	var nav_bar: PanelContainer = layout.find_child("StoryEditNavBar", true, false)
	if nav_bar:
		var exit_btn: Button = nav_bar.find_child("ExitBtn", true, false)
		if exit_btn: exit_btn.pressed.emit()
	for _w in range(20): await process_frame
	return info_text

func _initialize():
	printerr("[MS] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# 各シーケンスを試す
	var cases := [
		{"entry": {"id": "prologue", "label": "scene_university", "name": "Prologue 大学"}, "src": "res://story/chapters/PrologueChapter.gd"},
		{"entry": {"id": "prologue", "label": "scene_room", "name": "Prologue 自室"}, "src": "res://story/chapters/PrologueChapter.gd"},
		{"entry": {"id": "stage1", "label": "scene_guild_street", "name": "Stage1 ギルド通り"}, "src": "res://story/chapters/Stage1Chapter.gd"},
		{"entry": {"id": "stage2_pre", "name": "Stage2 場面1"}, "src": "res://story/chapters/Stage2Chapter.gd"},
		{"entry": {"id": "stage3_harass", "name": "Stage3 場面1-2"}, "src": "res://story/chapters/Stage3Chapter.gd"},
		{"entry": {"id": "subevent1_pre", "name": "Subevent1 前半", "chapter": "Subevent1ChapterScript"}, "src": "res://story/chapters/Subevent1Chapter.gd"},
	]
	for c in cases:
		var snap: String = _read(c.src)
		var info_text: String = await _drive_sequence(main_inst, c.entry)
		var ok: bool = info_text.begins_with("[保存]")
		printerr("[MS] %-30s -> %s" % [c.entry.get("name", "?"), info_text])
		_check(ok, "%s save succeeded" % c.entry.get("name", "?"))
		_write(c.src, snap)
		await process_frame; await process_frame

	printerr("[MS] done, fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
