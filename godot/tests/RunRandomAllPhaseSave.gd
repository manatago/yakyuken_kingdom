extends SceneTree
# 全4フェーズの実フロー保存検証。各フェーズで:
# 1. _random_phase_*() を fire-and-forget 起動
# 2. 直近の編集パネルを取り出す
# 3. スライダー設定 → 保存ボタン emit
# 4. ファイル反映を確認
# 5. NextBtn でフェーズ終了
# 実行: Godot --path godot --headless --script res://tests/RunRandomAllPhaseSave.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[ALL] PASS: %s" % msg)
	else:
		printerr("[ALL] FAIL: %s" % msg)
		_fails += 1

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

# 直近に追加された PanelContainer（指定 portrait_key を持つもの）を探す
func _find_panel(main_inst, portrait_key: String) -> PanelContainer:
	for child in main_inst.get_children():
		if child is PanelContainer and child.has_meta("portrait_key"):
			if child.get_meta("portrait_key") == portrait_key:
				return child
	return null

func _drive_portrait_phase(main_inst, home, enc_data: Dictionary, portrait_key: String, scale: float, x: int, y: int):
	var phase_result: Array = [""]
	var coro = func():
		phase_result[0] = await main_inst._random_phase_portrait(home, enc_data, portrait_key)
	coro.call()
	for _w in range(8): await process_frame
	var panel: PanelContainer = _find_panel(main_inst, portrait_key)
	if not panel:
		_check(false, "%s: edit panel not found" % portrait_key)
		return
	var sl: Dictionary = main_inst._get_edit_sliders(panel)
	sl.scale.value = scale
	sl.x.value = x
	sl.y.value = y
	for _w in range(3): await process_frame
	var save_btn: Button = panel.find_child("EditSaveButton", true, false)
	if save_btn:
		save_btn.pressed.emit()
		for _w in range(3): await process_frame
		var info: Label = panel.find_child("InfoLabel", true, false)
		var t: String = info.text if info else ""
		printerr("[ALL] %s save: %s" % [portrait_key, t])
		_check(t.begins_with("[保存]"), "%s save returned [保存]" % portrait_key)
	# NextBtn でフェーズ終了
	var next_btn: Button = panel.find_child("NextBtn", true, false)
	if next_btn:
		next_btn.pressed.emit()
		for _w in range(10): await process_frame
	_check(phase_result[0] == "next", "%s returned 'next'" % portrait_key)

func _drive_battle_phase(main_inst, home, enc_data: Dictionary, scale: float, x: int, y: int):
	var phase_result: Array = [""]
	var coro = func():
		phase_result[0] = await main_inst._random_phase_battle(home, enc_data, null, "")
	coro.call()
	# Battle phase の portrait_capture が走るので長めに待つ
	for _w in range(120): await process_frame
	var panel: PanelContainer = _find_panel(main_inst, "battle")
	if not panel:
		_check(false, "battle: edit panel not found")
		return
	var sl: Dictionary = main_inst._get_edit_sliders(panel)
	sl.scale.value = scale
	sl.x.value = x
	sl.y.value = y
	for _w in range(3): await process_frame
	var save_btn: Button = panel.find_child("EditSaveButton", true, false)
	if save_btn:
		save_btn.pressed.emit()
		for _w in range(3): await process_frame
		var info: Label = panel.find_child("InfoLabel", true, false)
		var t: String = info.text if info else ""
		printerr("[ALL] battle save: %s" % t)
		_check(t.begins_with("[保存]"), "battle save returned [保存]")
	var next_btn: Button = panel.find_child("NextBtn", true, false)
	if next_btn:
		next_btn.pressed.emit()
		for _w in range(15): await process_frame
	_check(phase_result[0] == "next", "battle returned 'next' (got '%s')" % phase_result[0])

func _initialize():
	printerr("[ALL] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	gs.reset()
	gs.init_default_inventory()
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var file_path := "res://encounter/EncounterDatabase.gd"
	var snapshot := _read(file_path)

	var db_script: GDScript = main_inst._load_script_fresh(file_path)
	var db = db_script.new()
	var enc_data: Dictionary = db.get_char("thug_a")

	var home = main_inst.guild_home_scene.instantiate()
	main_inst.add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home.setup(null, main_inst._current_town_map if main_inst._current_town_map else null)
	await process_frame; await process_frame

	# 各フェーズで保存検証
	await _drive_portrait_phase(main_inst, home, enc_data, "encounter", 0.61, 11, -11)
	await _drive_battle_phase(main_inst, home, enc_data, 0.62, 12, -12)
	await _drive_portrait_phase(main_inst, home, enc_data, "farewell_win", 0.63, 13, -13)
	await _drive_portrait_phase(main_inst, home, enc_data, "farewell_lose", 0.64, 14, -14)

	# 全部書かれているか
	var after := _read(file_path)
	_check('"scale": 0.61' in after, "encounter scale=0.61 written")
	_check('"scale": 0.62' in after, "battle scale=0.62 written")
	_check('"scale": 0.63' in after, "farewell_win scale=0.63 written")
	_check('"scale": 0.64' in after, "farewell_lose scale=0.64 written")

	_write(file_path, snapshot)
	printerr("[ALL] (file restored), fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
