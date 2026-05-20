extends SceneTree
# 同一セッションでの「保存 → 再オープン」が反映されるかを検証する。
# 1) プロローグ編集を開いて save_target_id 行を既知値へ
# 2) 保存
# 3) 編集を閉じて再オープン
# 4) 再オープン後の portrait_log[0] が保存値になっているか確認
# 検証後にファイルを元へ戻す。
# 実行: Godot --path godot --headless --script res://tests/RunReopenVerify.gd

const GameStateScript := preload("res://game/GameState.gd")

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _open_prologue_edit(main_inst) -> void:
	var ch_info := {}
	for info in main_inst.EVENT_BATTLE_CHAPTERS:
		if info.get("id", "") == "prologue" and info.get("mode", "") == "battle":
			ch_info = info; break
	main_inst._run_event_battle_edit(ch_info)
	for _w in range(150): await process_frame

func _close_battle_edit(main_inst) -> void:
	# 編集パネルとバトルインスタンスを掃除
	if is_instance_valid(main_inst._battle_edit_panel):
		main_inst._battle_edit_panel.queue_free()
		main_inst._battle_edit_panel = null
	if is_instance_valid(main_inst._battle_edit_ref):
		main_inst._battle_edit_ref.queue_free()
		main_inst._battle_edit_ref = null
	main_inst._battle_edit_history_idx = -1
	main_inst._battle_edit_last_log_size = 0
	for _w in range(5): await process_frame

func _initialize():
	printerr("[RO] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var file_path := "res://battle/chapters/PrologueBattleChapter.gd"
	var snapshot := _read(file_path)

	# --- 1回目: 開いて、値を変えて、保存 ---
	await _open_prologue_edit(main_inst)
	var elog: Array = main_inst._battle_edit_get_log()
	var first_scale: float = elog[0].get("scale", -1.0)
	var first_pos: Vector2 = elog[0].get("position", Vector2.ZERO)
	printerr("[RO] 1st open: portrait_log[0] scale=%.2f position=%s" % [first_scale, first_pos])

	var sl: Dictionary = main_inst._battle_edit_sl
	sl.scale.value = 0.77
	sl.x.value = 222
	sl.y.value = -333
	for _w in range(3): await process_frame

	var panel = main_inst._battle_edit_panel
	var info_lbl: Label = panel.find_child("InfoLabel", true, false)
	main_inst._save_battle_edit(panel, info_lbl)
	for _w in range(4): await process_frame
	printerr("[RO] save: %s" % info_lbl.text)

	# 編集パネルを閉じる
	await _close_battle_edit(main_inst)
	printerr("[RO] edit closed")

	# --- 2回目: 開き直し ---
	await _open_prologue_edit(main_inst)
	var elog2: Array = main_inst._battle_edit_get_log()
	var second_scale: float = elog2[0].get("scale", -1.0)
	var second_pos: Vector2 = elog2[0].get("position", Vector2.ZERO)
	printerr("[RO] 2nd open: portrait_log[0] scale=%.2f position=%s" % [second_scale, second_pos])

	# portrait_log の "position" は描画座標（offset + viewport 計算後）なので、
	# 章ファイルの offset リテラル [222,-333] とは直接一致しない。scale は
	# 章リテラルと一致するためそれで判定し、position は変化したかだけ確認する。
	var scale_ok: bool = abs(second_scale - 0.77) < 0.001
	var pos_changed: bool = second_pos.distance_to(first_pos) > 1.0
	if scale_ok and pos_changed:
		printerr("[RO] PASS: reopen reflects saved values (scale 0.80→%.2f, position moved)" % second_scale)
	else:
		printerr("[RO] FAIL: scale_ok=%s pos_changed=%s — script cache not reloaded" % [scale_ok, pos_changed])

	_write(file_path, snapshot)
	printerr("[RO] (file restored)")
	printerr("[RO] done")
	quit(0)
