extends SceneTree
# 同一セッション中のフェーズ間ナビで「保存→別フェーズ→◀で戻る」したとき、
# 保存値が再表示されるか（編集パネルのスライダー初期値に反映されるか）を検証。
# 実行: Godot --path godot --headless --script res://tests/RunRandomPhaseRevisit.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[RV] PASS: %s" % msg)
	else:
		printerr("[RV] FAIL: %s" % msg)
		_fails += 1

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _find_panel(main_inst, portrait_key: String) -> PanelContainer:
	for child in main_inst.get_children():
		if child is PanelContainer and child.has_meta("portrait_key"):
			if child.get_meta("portrait_key") == portrait_key:
				return child
	return null

func _initialize():
	printerr("[RV] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	gs.reset()
	gs.init_default_inventory()
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var file_path := "res://encounter/EncounterDatabase.gd"
	var snapshot := _read(file_path)

	# _run_char_edit_test の本体ループ部分だけを模倣して再現
	var db_script: GDScript = main_inst._load_script_fresh(file_path)
	var db = db_script.new()
	var encounter_data: Dictionary = db.get_char("thug_a")
	encounter_data["battle_bg"] = ""  # battle phase が空 bg で動くようにする

	var home = main_inst.guild_home_scene.instantiate()
	main_inst.add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home.setup(null, main_inst._current_town_map if main_inst._current_town_map else null)
	await process_frame; await process_frame

	# Phase 0 (encounter) を起動 → 保存（scale=0.71, pos=[55, -66]）→ ▶ で次へ
	printerr("[RV] phase 0 (encounter) start")
	var phase0_result: Array = [""]
	var coro0 = func():
		phase0_result[0] = await main_inst._random_phase_portrait(home, encounter_data, "encounter")
	coro0.call()
	for _w in range(8): await process_frame
	var p0 = _find_panel(main_inst, "encounter")
	_check(p0 != null, "phase 0 panel found")
	if p0:
		var sl0: Dictionary = main_inst._get_edit_sliders(p0)
		sl0.scale.value = 0.71
		sl0.x.value = 55
		sl0.y.value = -66
		for _w in range(3): await process_frame
		(p0.find_child("EditSaveButton", true, false) as Button).pressed.emit()
		for _w in range(3): await process_frame
		printerr("[RV] phase 0 save info: %s" % (p0.find_child("InfoLabel", true, false) as Label).text)
		(p0.find_child("NextBtn", true, false) as Button).pressed.emit()
		for _w in range(10): await process_frame
	_check(phase0_result[0] == "next", "phase 0 returned 'next'")

	# 「次フェーズへ移動」を模倣したいが、battle phase は重いのでスキップして
	# 「encounter を閉じて再度 encounter を開き直す」直接シナリオで確認する。
	# ループの本体（_run_char_edit_test）では各イテレーション冒頭で encounter_data
	# を fresh_db.get_char(enc_id) で再フェッチする処理を追加した。これを直接呼ぶ。
	var db_script2: GDScript = main_inst._load_script_fresh(file_path)
	var db2 = db_script2.new()
	var encounter_data_refreshed: Dictionary = db2.get_char("thug_a")
	var refreshed_scale: float = encounter_data_refreshed.get("portraits", {}).get("encounter", {}).get("scale", -1.0)
	var refreshed_pos = encounter_data_refreshed.get("portraits", {}).get("encounter", {}).get("position", [])
	printerr("[RV] after save, refreshed encounter scale=%.2f pos=%s" % [refreshed_scale, refreshed_pos])
	_check(abs(refreshed_scale - 0.71) < 0.001, "refresh shows saved scale 0.71")
	_check(refreshed_pos is Array and refreshed_pos.size() >= 2 and int(refreshed_pos[0]) == 55 and int(refreshed_pos[1]) == -66, "refresh shows saved position [55,-66]")

	# Phase 0 を再度開いて、スライダー初期値が 0.71 になっているか確認
	# （これがメモリ上の encounter_data 更新が効いていることの確認）
	printerr("[RV] phase 0 (encounter) revisit")
	var phase0_revisit: Array = [""]
	var coro_revisit = func():
		phase0_revisit[0] = await main_inst._random_phase_portrait(home, encounter_data_refreshed, "encounter")
	coro_revisit.call()
	for _w in range(8): await process_frame
	var pR = _find_panel(main_inst, "encounter")
	_check(pR != null, "phase 0 revisit panel found")
	if pR:
		var slR: Dictionary = main_inst._get_edit_sliders(pR)
		var init_scale: float = slR.scale.value
		var init_x: int = int(slR.x.value)
		var init_y: int = int(slR.y.value)
		printerr("[RV] revisit slider init: scale=%.2f x=%d y=%d" % [init_scale, init_x, init_y])
		_check(abs(init_scale - 0.71) < 0.001, "revisit slider scale=0.71 (saved)")
		_check(init_x == 55 and init_y == -66, "revisit slider pos=[55,-66] (saved)")
		(pR.find_child("EditBackButton", true, false) as Button).pressed.emit()
		for _w in range(10): await process_frame

	_write(file_path, snapshot)
	printerr("[RV] (file restored), fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
