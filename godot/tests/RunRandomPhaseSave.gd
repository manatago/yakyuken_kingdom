extends SceneTree
# 統合検証: _random_phase_portrait の実フローで「スライダー → 保存」が
# ファイルへ反映されるかをエンドツーエンドで確認する。
# 実行: Godot --path godot --headless --script res://tests/RunRandomPhaseSave.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[PS] PASS: %s" % msg)
	else:
		printerr("[PS] FAIL: %s" % msg)
		_fails += 1

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _initialize():
	printerr("[PS] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var file_path := "res://encounter/EncounterDatabase.gd"
	var snapshot := _read(file_path)

	# encounter_data を取得
	var db_script: GDScript = main_inst._load_script_fresh(file_path)
	var db = db_script.new()
	var enc_data: Dictionary = db.get_char("thug_a")

	# GuildHome を立てる
	var home = main_inst.guild_home_scene.instantiate()
	main_inst.add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home.setup(null, main_inst._current_town_map if main_inst._current_town_map else null)
	await process_frame; await process_frame

	# encounter フェーズを fire-and-forget で開始
	var phase_result: Array = [""]
	var coro = func():
		phase_result[0] = await main_inst._random_phase_portrait(home, enc_data, "encounter")
	coro.call()
	for _w in range(8): await process_frame

	# 直近に追加された PanelContainer（編集パネル）を探す
	var panel: PanelContainer = null
	for child in main_inst.get_children():
		if child is PanelContainer and child.has_meta("portrait_key"):
			if child.get_meta("portrait_key") == "encounter":
				panel = child
				break
	if not panel:
		_check(false, "encounter edit panel not found")
		quit(1)
		return

	# スライダーを既知値へ
	var sl: Dictionary = main_inst._get_edit_sliders(panel)
	sl.scale.value = 0.66
	sl.x.value = 77
	sl.y.value = -88
	for _w in range(4): await process_frame

	# 保存ボタンを emit
	var save_btn: Button = panel.find_child("EditSaveButton", true, false)
	if not save_btn:
		_check(false, "EditSaveButton not found on encounter panel")
	else:
		save_btn.pressed.emit()
		for _w in range(4): await process_frame
		var info: Label = panel.find_child("InfoLabel", true, false)
		var info_text: String = info.text if info else ""
		printerr("[PS] InfoLabel after save: %s" % info_text)
		_check(info_text.begins_with("[保存]"), "save reported success (%s)" % info_text)

	# ファイルが書き換わっているか
	var after := _read(file_path)
	var ok_scale: bool = '"scale": 0.66' in after
	var ok_pos: bool = '"position": [77, -88]' in after
	_check(ok_scale, "file contains scale 0.66")
	_check(ok_pos, "file contains position [77, -88]")

	# NextBtn を押してフェーズ終了
	var next_btn: Button = panel.find_child("NextBtn", true, false)
	if next_btn:
		next_btn.pressed.emit()
		for _w in range(10): await process_frame
	_check(phase_result[0] == "next", "phase returned 'next' (got '%s')" % phase_result[0])

	_write(file_path, snapshot)
	printerr("[PS] (file restored), fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
