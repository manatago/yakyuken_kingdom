extends SceneTree
# イベントバトル編集モードで「保存」ボタンを実クリックし、章ソースファイルへ
# 正しく書き込まれるか（保存できるか）を end-to-end で検証する。
# 対象ファイルはバックアップ→復元するので副作用なし。
# 実行: Godot --path godot --script res://tests/RunBattleEditSaveClick.gd

const GameStateScript := preload("res://game/GameState.gd")
const TARGET_FILE := "res://battle/chapters/Stage1BattleChapter.gd"

func _click(pos: Vector2):
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	root.push_input(press)
	await process_frame
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = pos
	rel.global_position = pos
	root.push_input(rel)
	await process_frame
	await process_frame

func _center_of(ctrl: Control) -> Vector2:
	var r := ctrl.get_global_rect()
	return r.position + r.size * 0.5

func _wait_idle(main_inst):
	for _w in range(300):
		await process_frame
		if not main_inst._battle_edit_advancing:
			return

func _read_file(path: String) -> String:
	var f := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.READ)
	if not f:
		return ""
	var t := f.get_as_text()
	f.close()
	return t

func _write_file(path: String, content: String):
	var f := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	f.store_string(content)
	f.close()

func _fail(msg: String, backup: String):
	if not backup.is_empty():
		_write_file(TARGET_FILE, backup)
		printerr("[SAVE] (対象ファイル復元済み)")
	printerr("[SAVE] FAIL — %s" % msg)
	quit(1)

func _initialize():
	printerr("[SAVE] start")
	root.gui_disable_input = false
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	# 1) EditMode → イベントバトル編集 → ステージ1
	await _click(_center_of(main_inst.edit_mode_button))
	await process_frame
	var event_btn: Button = null
	for c in main_inst.jump_list.get_children():
		if c is Button and "イベントバトル" in c.text:
			event_btn = c
			break
	if event_btn == null:
		_fail("イベントバトル編集ボタンがない", ""); return
	await _click(_center_of(event_btn))
	await process_frame
	await process_frame
	var stage_btn: Button = null
	for c in main_inst.jump_list.get_children():
		if c is Button and "ステージ1" in c.text:
			stage_btn = c
			break
	if stage_btn == null:
		_fail("ステージ1 が一覧にない", ""); return
	await _click(_center_of(stage_btn))

	# 2) バトル + 編集パネル待ち
	for i in 40:
		await process_frame
	var panel: PanelContainer = null
	for c in main_inst.get_children():
		if c is PanelContainer and c.find_child("EditSaveButton", true, false):
			panel = c
			break
	if panel == null:
		_fail("保存ボタン付き編集パネルがない", ""); return
	var save_btn: Button = panel.find_child("EditSaveButton", true, false)
	var info: Label = panel.find_child("InfoLabel", true, false)
	var scale_slider: HSlider = panel.find_child("ScaleSlider", true, false)
	if not (save_btn and info and scale_slider):
		_fail("パネル構造が不正 (save=%s info=%s scale=%s)" % [save_btn, info, scale_slider], ""); return
	for i in 20:
		await process_frame

	# 3) 先頭画像(0)へ ◀ で移動（保存対象を確定）
	var prev_btn: Button = panel.find_child("PrevBtn", true, false)
	await _click(_center_of(prev_btn))
	await _wait_idle(main_inst)
	var idx: int = main_inst._battle_edit_history_idx
	var elog: Array = main_inst._battle_edit_get_log()
	if idx < 0 or idx >= elog.size():
		_fail("history_idx が不正 (%d / %d)" % [idx, elog.size()], ""); return
	var src_id: String = elog[idx].get("edit_source_id", "")
	printerr("[SAVE] 保存対象 idx=%d edit_source_id='%s'" % [idx, src_id])
	if src_id.is_empty() or not (":" in src_id):
		_fail("edit_source_id が未記録（editor_capture が立っていない可能性）: '%s'" % src_id, ""); return

	# 対象ファイル名と行を分解
	var colon: int = src_id.rfind(":")
	var src_file: String = src_id.substr(0, colon)
	var line_no: int = int(src_id.substr(colon + 1))
	if src_file != TARGET_FILE:
		printerr("[SAVE] 注意: 対象ファイルが %s（テスト前提は %s）" % [src_file, TARGET_FILE])

	# 4) バックアップ
	var backup := _read_file(src_file)
	if backup.is_empty():
		_fail("対象ファイルを読めない: %s" % src_file, ""); return
	var orig_line := backup.split("\n")[line_no - 1]
	printerr("[SAVE] 変更前 行%d: %s" % [line_no, orig_line.strip_edges()])

	# 5) スケールを変更（_on_battle_slider 発火 → 現在値が保存に使われる）
	var new_scale: float = snappedf(scale_slider.value + 0.05, 0.01)
	if new_scale > scale_slider.max_value:
		new_scale = snappedf(scale_slider.value - 0.05, 0.01)
	scale_slider.value = new_scale
	await process_frame
	await process_frame

	# 6) 保存をクリック
	await _click(_center_of(save_btn))
	await process_frame
	await process_frame
	printerr("[SAVE] InfoLabel = '%s'" % info.text)

	# 7) 結果判定: ラベルが [保存] 成功で始まること
	if not info.text.begins_with("[保存]"):
		_fail("保存に失敗（InfoLabel='%s'）" % info.text, backup); return

	# 8) ファイルが実際に変わり、対象行に新スケールが入っていること
	var after := _read_file(src_file)
	var after_line := after.split("\n")[line_no - 1] if after.split("\n").size() > line_no - 1 else ""
	printerr("[SAVE] 変更後 行%d: %s" % [line_no, after_line.strip_edges()])
	var expected := '"scale": %.2f' % new_scale
	var ok_file := after != backup and (expected in after_line)

	# 9) 復元
	_write_file(src_file, backup)
	printerr("[SAVE] 対象ファイル復元済み")

	if not ok_file:
		printerr("[SAVE] FAIL — ファイルが期待通り更新されていない（expected '%s' を行%dに）" % [expected, line_no])
		quit(1); return

	printerr("[SAVE] OK — 保存クリックで対象行(%d)に %s が書き込まれた" % [line_no, expected])
	quit(0)
