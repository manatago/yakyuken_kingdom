extends SceneTree
# スモーク: ステージ1（冒険者A戦）の編集モードが tutorial として起動し、
# Stage1BattleChapter.tutorial() のスクリプト戦が SCRIPT ERROR なく走り出すか確認。
# 実行: Godot --path godot --headless --script res://tests/RunStage1EditSmoke.gd

const GameStateScript := preload("res://game/GameState.gd")

func _initialize():
	printerr("[ST1SMOKE] start")
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
		if info.get("id", "") == "stage1":
			ch_info = info
			break
	if ch_info.is_empty():
		printerr("[ST1SMOKE] FAIL: stage1 entry not found")
		quit(1); return
	printerr("[ST1SMOKE] entry mode=%s name=%s" % [ch_info.get("mode", "?"), ch_info.get("name", "?")])
	if ch_info.get("mode", "") != "tutorial":
		printerr("[ST1SMOKE] FAIL: stage1 entry mode is not 'tutorial'")
		quit(1); return

	main_inst._run_event_battle_edit(ch_info)
	for _w in range(150):
		await process_frame

	var ok := is_instance_valid(main_inst._battle_edit_ref)
	printerr("[ST1SMOKE] battle ref valid=%s" % ok)
	if ok:
		var b = main_inst._battle_edit_ref
		var is_tut: bool = ("_is_tutorial" in b and b._is_tutorial)
		printerr("[ST1SMOKE] battle is_tutorial=%s" % is_tut)
	printerr("[ST1SMOKE] done")
	quit(0)
