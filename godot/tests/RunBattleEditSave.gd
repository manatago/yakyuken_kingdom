extends SceneTree
# 回帰テスト: 編集モードの「保存」が、対象ファイルへ正しく書き戻せることを検証する。
#   - イベントバトル（プロローグ＝リテラルパス）
#   - イベントバトル（ステージ2＝定数 LAYLA_PORTRAIT 参照）
#   - ランダムバトル（EncounterDatabase の battle 立ち絵）
# 各対象ファイルはテスト前にスナップショットし、検証後に元へ戻す。
#
# 実行: Godot --path godot --headless --script res://tests/RunBattleEditSave.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[SAVETEST] PASS: %s" % msg)
	else:
		printerr("[SAVETEST] FAIL: %s" % msg)
		_fails += 1

func _read_file(res_path: String) -> String:
	var f := FileAccess.open(res_path, FileAccess.READ)
	if not f:
		return ""
	var t := f.get_as_text()
	f.close()
	return t

func _write_file(res_path: String, content: String):
	var f := FileAccess.open(res_path, FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()

func _test_event(target_id: String, file_path: String):
	var snapshot := _read_file(file_path)
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame
	var ch_info := {}
	for info in main_inst.EVENT_BATTLE_CHAPTERS:
		if info.get("id", "") == target_id and info.get("mode", "") == "battle":
			ch_info = info
			break
	main_inst._run_event_battle_edit(ch_info)
	for _w in range(150):
		await process_frame
	var panel = main_inst._battle_edit_panel
	var info_lbl: Label = panel.find_child("InfoLabel", true, false) if panel else null
	if panel and info_lbl:
		main_inst._save_battle_edit(panel, info_lbl)
		for _w in range(4):
			await process_frame
		_check(info_lbl.text.begins_with("[保存]"),
			"event %s save succeeded (%s)" % [target_id, info_lbl.text])
	else:
		_check(false, "event %s: no edit panel" % target_id)
	main_inst.queue_free()
	gs.queue_free()
	await process_frame
	await process_frame
	_write_file(file_path, snapshot)

func _test_random():
	var file_path := "res://encounter/EncounterDatabase.gd"
	var snapshot := _read_file(file_path)
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame
	gs.reset()
	gs.init_default_inventory()
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame
	var enc: Dictionary = EncounterDatabase.new().characters.get("thug_a", {}).duplicate(true)
	enc["battle_bg"] = ""
	var chapter = RandomBattleChapter.new()
	chapter.setup_from_encounter(enc)
	var panel = main_inst._create_edit_overlay(enc)
	panel.set_meta("chapter_path", file_path)
	panel.set_meta("encounter_id", enc.get("id", ""))
	main_inst.add_child(panel)
	var battle = main_inst.battle_scene_scene.instantiate()
	main_inst.add_child(battle)
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cast = main_inst.story_script.get_cast() if main_inst.story_script else {}
	battle.setup(cast, null, gs.inventory)
	battle.force_result_mode = true
	battle.start_battle(chapter)
	main_inst._connect_edit_to_battle(panel, battle, enc)
	for _w in range(150):
		await process_frame
	var info_lbl: Label = panel.find_child("InfoLabel", true, false)
	if info_lbl:
		main_inst._save_battle_edit(panel, info_lbl)
		for _w in range(4):
			await process_frame
		_check(info_lbl.text.begins_with("[保存]"),
			"random thug_a save succeeded (%s)" % info_lbl.text)
	else:
		_check(false, "random: no edit panel")
	_write_file(file_path, snapshot)

func _initialize():
	printerr("[SAVETEST] start")
	await _test_event("prologue", "res://battle/chapters/PrologueBattleChapter.gd")
	await _test_event("stage2", "res://battle/chapters/Stage2BattleChapter.gd")
	await _test_random()
	printerr("[SAVETEST] done, fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
