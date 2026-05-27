extends SceneTree
# ユーザー操作の再現: ストーリー編集で ▶ で先へ進んでから ◀ で前の画像へ戻り、保存。
# 保存が「現在表示中の画像の set_portrait 行」を更新し、「次の画像の行」に漏れない
# ことを end-to-end（実ファイル書き込み）で検証する。対象ファイルはバックアップ→復元。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveAfterNav.gd

const GameStateScript := preload("res://game/GameState.gd")
const SRC := "res://story/chapters/Subevent1Chapter.gd"

func _nav(main_inst, action: String) -> bool:
	var before: int = main_inst._story_edit_current_idx
	for _f in range(80):
		main_inst._story_edit_nav_action = action
		await process_frame
		if main_inst._story_edit_current_idx != before:
			return true
	return false

func _read(p: String) -> String:
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _root_of(main_inst) -> Control:
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			return child
	return null

# 右カードと、その保存対象行（rect の最後の portrait_log エントリの edit_source_id 行）
func _right_card(main_inst) -> PanelContainer:
	var r := _root_of(main_inst)
	return r.find_child("StoryEditCard_Right", true, false) if r else null

func _target_line(main_inst, card: PanelContainer) -> int:
	if not card or not card.visible:
		return -1
	var rect = card.get_meta("bound_rect", null)
	if not is_instance_valid(rect):
		return -1
	var sc = main_inst.story_scene_instance
	var plog: Array = sc.portrait_log if (sc and "portrait_log" in sc) else []
	for i in range(plog.size() - 1, -1, -1):
		if plog[i].get("rect") == rect:
			var sid: String = plog[i].get("edit_source_id", "")
			if ":" in sid:
				return int(sid.substr(sid.rfind(":") + 1))
			return -1
	return -1

func _initialize():
	printerr("[SAVNAV] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var snapshot := _read(SRC)
	var entry := {"id": "subevent1_hideout", "name": "前半2", "chapter": "Subevent1ChapterScript"}
	var coro = func():
		await main_inst._run_story_edit(entry)
	coro.call()
	for _w in range(150): await process_frame
	if not _root_of(main_inst):
		printerr("[SAVNAV] FAIL — 編集モードに入れていない"); quit(1); return

	# ▶ で前進し、右カードの保存対象行が「変わった」時点(=後の画像)を far として記録
	var far_line := -1
	var fwd_steps := 0
	var start_line := _target_line(main_inst, _right_card(main_inst))
	for i in range(28):
		if not await _nav(main_inst, "next"):
			break
		fwd_steps += 1
		var tl := _target_line(main_inst, _right_card(main_inst))
		if tl > 0 and tl != start_line:
			far_line = tl
	printerr("[SAVNAV] ▶x%d  start_line=%d far_line=%d" % [fwd_steps, start_line, far_line])
	if far_line < 0:
		printerr("[SAVNAV] FAIL — 後の画像（別行）に到達できず前提不成立"); quit(1); return

	# ◀ で戻り、右カードの保存対象行が far_line と「異なる前の行」になる位置を探す
	var near_line := -1
	for i in range(fwd_steps):
		if not await _nav(main_inst, "prev"):
			break
		var card := _right_card(main_inst)
		var tl := _target_line(main_inst, card)
		if tl > 0 and tl != far_line:
			near_line = tl
			break
	printerr("[SAVNAV] ◀ 後 near_line=%d (far_line=%d)" % [near_line, far_line])
	if near_line < 0 or near_line == far_line:
		printerr("[SAVNAV] FAIL — ◀ で前の画像(別行)へ戻れず前提不成立"); quit(1); return

	# near の画像でスライダーを変えて保存
	var card := _right_card(main_inst)
	var sl: Dictionary = main_inst._get_edit_sliders(card)
	var new_scale: float = 0.37
	sl.scale.value = new_scale
	sl.x.value = 11
	sl.y.value = 22
	for _w in range(3): await process_frame
	var save_btn: Button = card.find_child("SaveBtn", true, false)
	save_btn.pressed.emit()
	for _w in range(6): await process_frame
	var info: Label = card.find_child("InfoLabel", true, false)
	printerr("[SAVNAV] InfoLabel = %s" % info.text)

	var after := _read(SRC)
	var after_lines := after.split("\n")
	var near_txt: String = after_lines[near_line - 1] if after_lines.size() >= near_line else ""
	var far_txt: String = after_lines[far_line - 1] if after_lines.size() >= far_line else ""
	printerr("[SAVNAV] near行%d: %s" % [near_line, near_txt.strip_edges()])
	printerr("[SAVNAV] far 行%d: %s" % [far_line, far_txt.strip_edges()])

	# 復元
	_write(SRC, snapshot)
	printerr("[SAVNAV] (file restored)")

	var want := '"scale": 0.37'
	var near_ok := want in near_txt           # 現在の画像の行が更新された
	var far_clean := not (want in far_txt)     # 次の画像の行に漏れていない
	if not info.text.begins_with("[保存]"):
		printerr("[SAVNAV] FAIL — 保存自体が失敗 (%s)" % info.text); quit(1); return
	if not near_ok:
		printerr("[SAVNAV] FAIL — 現在の画像(行%d)が更新されていない" % near_line); quit(1); return
	if not far_clean:
		printerr("[SAVNAV] FAIL — 次の画像(行%d)に保存が漏れた" % far_line); quit(1); return

	printerr("[SAVNAV] OK — ◀ 後の保存が現在画像(行%d)のみ更新、次画像(行%d)へ漏れなし" % [near_line, far_line])
	quit(0)
