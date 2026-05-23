extends SceneTree
# ST3/ST4/ST5 ミニゲーム編集モードで、保存が各章固有のファイルへ書き込まれるかを検証する。
# 修正前: ST4/ST5 は setup_scene を override しておらず基底 MinigameChapterBase.gd が
#        更新されてしまうため、独立に保存できなかった。
# 修正後: 各章が自前の setup_scene + set_portrait を持つので、edit_source_id が
#        各章ファイル行を指して個別保存できる。
# 実行: Godot --path godot --headless --script res://tests/RunMinigameEditSave.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[MG] PASS: %s" % msg)
	else:
		printerr("[MG] FAIL: %s" % msg)
		_fails += 1

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _drive(main_inst, target_id: String, expected_file_basename: String, marker_scale: float, marker_x: int, marker_y: int):
	# 該当ミニゲームを開く
	var ch_info := {}
	for info in main_inst.EVENT_BATTLE_CHAPTERS:
		if info.get("id", "") == target_id and info.get("mode", "") == "minigame":
			ch_info = info
			break
	if ch_info.is_empty():
		_check(false, "%s: entry not found" % target_id)
		return
	main_inst._run_event_battle_edit(ch_info)
	for _w in range(180): await process_frame  # ミニゲームは少し時間がかかる

	var panel = main_inst._battle_edit_panel
	var info_lbl: Label = panel.find_child("InfoLabel", true, false) if panel else null
	if not panel or not info_lbl:
		_check(false, "%s: no edit panel" % target_id)
		return

	# スライダーを既知値へ
	var sl: Dictionary = main_inst._battle_edit_sl
	sl.scale.value = marker_scale
	sl.x.value = marker_x
	sl.y.value = marker_y
	for _w in range(4): await process_frame

	main_inst._save_battle_edit(panel, info_lbl)
	for _w in range(4): await process_frame
	var msg: String = info_lbl.text
	printerr("[MG] %s save message: %s" % [target_id, msg])
	_check(msg.begins_with("[保存]"), "%s: save reported success" % target_id)
	_check(expected_file_basename in msg, "%s: save targets %s (got '%s')" % [target_id, expected_file_basename, msg])

	# 戻るボタンで終了
	var back_btn: Button = panel.find_child("EditBackButton", true, false)
	if back_btn and is_instance_valid(main_inst._battle_edit_ref):
		main_inst._battle_edit_ref.battle_finished.emit("abort")
	for _w in range(20): await process_frame

func _initialize():
	printerr("[MG] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# ST3, ST4, ST5 のミニゲーム保存先ファイルをスナップショット
	var paths := [
		"res://battle/chapters/Stage3MinigameChapter.gd",
		"res://battle/chapters/Stage4MinigameChapter.gd",
		"res://battle/chapters/Stage5MinigameChapter.gd",
		"res://battle/MinigameChapterBase.gd",
	]
	var snapshots := {}
	for p in paths:
		snapshots[p] = _read(p)

	# 1) Stage3: setup_scene を override 済 → 個別保存できる
	await _drive(main_inst, "minigame_stage3", "Stage3MinigameChapter.gd", 0.77, 11, -22)
	# 2) Stage4: 今回 setup_scene を追加 → 個別保存できる
	await _drive(main_inst, "minigame_stage4", "Stage4MinigameChapter.gd", 0.66, 33, -44)
	# 3) Stage5: 今回 setup_scene を追加 → 個別保存できる
	await _drive(main_inst, "minigame_stage5", "Stage5MinigameChapter.gd", 0.55, 55, -66)

	# 基底クラス MinigameChapterBase.gd が誤って書き換わっていないか
	var base_after := _read("res://battle/MinigameChapterBase.gd")
	_check(base_after == snapshots["res://battle/MinigameChapterBase.gd"], "base class file untouched (no contamination)")

	# 各章ファイルに期待値が書かれているか
	var s3 := _read("res://battle/chapters/Stage3MinigameChapter.gd")
	_check('"scale": 0.77' in s3 and '"position": [11, -22]' in s3, "Stage3 file has saved values")
	var s4 := _read("res://battle/chapters/Stage4MinigameChapter.gd")
	_check('"scale": 0.66' in s4 and '"position": [33, -44]' in s4, "Stage4 file has saved values")
	var s5 := _read("res://battle/chapters/Stage5MinigameChapter.gd")
	_check('"scale": 0.55' in s5 and '"position": [55, -66]' in s5, "Stage5 file has saved values")

	# ファイル復元
	for p in paths:
		_write(p, snapshots[p])
	printerr("[MG] (files restored)")
	printerr("[MG] done, fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
