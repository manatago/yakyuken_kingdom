extends SceneTree
# 分割後の subevent1_hideout（前半2・盗賊団アジト）でストーリー編集の保存ができるか検証。
# 章分割で新規追加したシーケンスが get_sequence / source_file マッピング / edit_source_id
# 保存まで一気通貫で動くことを確認する。対象ファイルはバックアップ→復元。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveSubevent1Hideout.gd

const GameStateScript := preload("res://game/GameState.gd")
const SRC := "res://story/chapters/Subevent1Chapter.gd"

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[SE1H] PASS: %s" % msg)
	else:
		printerr("[SE1H] FAIL: %s" % msg)
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

func _initialize():
	printerr("[SE1H] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var snapshot := _read(SRC)
	# 分割後の新シーケンスを直接編集
	var entry := {"id": "subevent1_hideout", "name": "サブイベント1 前半2（盗賊団アジト）", "chapter": "Subevent1ChapterScript"}
	var coro = func():
		await main_inst._run_story_edit(entry)
	coro.call()
	for _w in range(150): await process_frame

	var layout: Control = null
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			layout = child
			break
	_check(layout != null, "StoryEditRoot exists (subevent1_hideout シーケンスが開けた)")
	if not layout:
		_write(SRC, snapshot)
		quit(1); return

	# sourceファイルが Subevent1Chapter.gd に紐づいているか
	_check(main_inst._story_edit_source_file == SRC, "source_file = %s (got '%s')" % [SRC, main_inst._story_edit_source_file])

	var card: PanelContainer = _find_visible_card(layout)
	_check(card != null, "可視カード（bound_rect 付き）がある")

	if card:
		var sl: Dictionary = main_inst._get_edit_sliders(card)
		sl.scale.value = 0.66
		sl.x.value = 21
		sl.y.value = -33
		for _w in range(4): await process_frame

		var save_btn: Button = card.find_child("SaveBtn", true, false)
		_check(save_btn != null, "カードに SaveBtn がある")
		if save_btn:
			save_btn.pressed.emit()
			for _w in range(6): await process_frame
			var info: Label = card.find_child("InfoLabel", true, false)
			var info_text: String = info.text if info else ""
			printerr("[SE1H] save InfoLabel: %s" % info_text)
			_check(info_text.begins_with("[保存]"), "保存成功 (got '%s')" % info_text)

			var after := _read(SRC)
			var has_scale: bool = ('"scale": 0.66' in after) or ('"portrait_scale": 0.66' in after)
			printerr("[SE1H] file has scale 0.66 = %s" % has_scale)
			_check(has_scale, "ファイルに scale/portrait_scale 0.66 が書き込まれた")

	# 終了
	var nav_bar: PanelContainer = layout.find_child("StoryEditNavBar", true, false)
	if nav_bar:
		var exit_btn: Button = nav_bar.find_child("ExitBtn", true, false)
		if exit_btn:
			exit_btn.pressed.emit()
			for _w in range(30): await process_frame

	_write(SRC, snapshot)
	printerr("[SE1H] (file restored), fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
