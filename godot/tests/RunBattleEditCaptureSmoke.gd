extends SceneTree
# スモーク: 全イベントバトルチャプターで編集モードの立ち絵キャプチャが
# SCRIPT ERROR・ハングなく走り、portrait_log が populate されることを確認する。
# 各チャプターごとに Main を作り直して独立に検証する。
#
# 実行: Godot --path godot --headless --script res://tests/RunBattleEditCaptureSmoke.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[CAPSMOKE] PASS: %s" % msg)
	else:
		printerr("[CAPSMOKE] FAIL: %s" % msg)
		_fails += 1

func _run_one(ch_info: Dictionary):
	var target_id: String = ch_info.get("id", "?")
	var mode: String = ch_info.get("mode", "?")
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	printerr("[CAPSMOKE] --- opening %s (mode=%s) ---" % [target_id, mode])
	main_inst._run_event_battle_edit(ch_info)
	for _w in range(180):
		await process_frame
	var log_size: int = main_inst._battle_edit_get_log().size()
	var ref_ok: bool = is_instance_valid(main_inst._battle_edit_ref)
	var done: bool = ref_ok and ("portrait_capture_done" in main_inst._battle_edit_ref) \
		and main_inst._battle_edit_ref.portrait_capture_done
	printerr("[CAPSMOKE] %s: portrait_log size=%d battle_ref_valid=%s capture_done=%s" % [
		target_id, log_size, ref_ok, done])
	# クラッシュ・ハングせず、立ち絵キャプチャが最後まで完了したことを確認
	_check(ref_ok, "%s edit opened without crash" % target_id)
	_check(done, "%s portrait capture completed (no hang)" % target_id)
	if mode != "minigame":
		_check(log_size > 0, "%s captured at least one portrait" % target_id)

	main_inst.queue_free()
	gs.queue_free()
	await process_frame
	await process_frame

func _initialize():
	printerr("[CAPSMOKE] start")
	var main_packed = load("res://Main.tscn").instantiate()
	root.add_child(main_packed)
	await process_frame
	var chapters: Array = main_packed.EVENT_BATTLE_CHAPTERS.duplicate()
	main_packed.free()
	await process_frame
	for ch_info in chapters:
		await _run_one(ch_info)
	printerr("[CAPSMOKE] done, fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
