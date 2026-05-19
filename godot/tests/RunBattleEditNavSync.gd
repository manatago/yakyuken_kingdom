extends SceneTree
# 回帰テスト: バトル編集モードで、ライブのバトルが自走して portrait_log を
# 増やしたとき（勝利動画後に次 outfit の set_portrait が走る等）、
#   1) _battle_edit_history_idx が最新エントリへ追従すること
#   2) スライダー編集が「表示中の画像」のエントリへ書き込まれ、
#      古いエントリ（別画像）のスケール/位置を破壊しないこと
# を検証する。修正前は idx が古いまま固定され、スライダー編集が
# guard_024(scale 0.80) のエントリへ guard_014(scale 0.40) の値を書き込み、
# ◀ で戻ると guard_024 が左に寄って小さく表示されるバグがあった。
#
# 実行: Godot --path godot --headless --script res://tests/RunBattleEditNavSync.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[NAVSYNC] PASS: %s" % msg)
	else:
		printerr("[NAVSYNC] FAIL: %s" % msg)
		_fails += 1

func _initialize():
	printerr("[NAVSYNC] start")
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
		if info.get("id", "") == "prologue" and info.get("mode", "") == "battle":
			ch_info = info
			break
	if ch_info.is_empty():
		printerr("[NAVSYNC] FAIL: prologue battle ch_info not found")
		quit(1); return

	main_inst._run_event_battle_edit(ch_info)
	for _w in range(120):
		await process_frame

	var sc = main_inst._battle_edit_ref._story_scene
	var log: Array = main_inst._battle_edit_get_log()
	_check(log.size() >= 1, "portrait_log has setup entry (size=%d)" % log.size())
	if log.size() < 1:
		quit(1); return

	# entry #0 = setup_scene の guard_024 (scale 0.80)。これを「過去エントリ」とみなす。
	var stale_idx := 0
	var stale_scale_before: float = log[stale_idx].get("scale", -1.0)
	var stale_pos_before: Vector2 = log[stale_idx].get("position", Vector2.ZERO)
	var stale_tex = log[stale_idx].get("texture")

	# ユーザが ◀ で過去エントリへ戻った状態を作る
	main_inst._battle_edit_history_idx = stale_idx
	printerr("[NAVSYNC] simulated user at history_idx=%d (size=%d)" % [stale_idx, log.size()])

	# --- ライブのバトルが自走して新しい立ち絵を出した状況を再現 ---
	# guard_014（2048x2048, scale 0.40 相当）の別テクスチャを直接 log へ追加し、
	# center_char にも反映する（実ゲームでは勝利動画後に set_portrait が行う）。
	var live_tex: Texture2D = load("res://assets/characters/mob/guard/default/guard_default_014.png")
	_check(live_tex != null, "loaded guard_014 texture for autonomous entry")
	var center = sc.center_char
	center.texture = live_tex
	center.scale = Vector2(0.40, 0.40)
	center.size = live_tex.get_size()
	center.position = Vector2(550.4, 207.8)
	center.visible = true
	sc.portrait_log.append({
		"rect": center,
		"side": "center",
		"texture": live_tex,
		"texture_path": "res://assets/characters/mob/guard/default/guard_default_014.png",
		"character_id": "matilda",
		"scale": 0.40,
		"position": Vector2(550.4, 207.8),
		"flip_h": false,
		"background": null,
		"dialogue": {},
	})
	var live_idx: int = sc.portrait_log.size() - 1
	printerr("[NAVSYNC] autonomous append -> log size=%d (live entry #%d)" % [sc.portrait_log.size(), live_idx])

	# Main._process が走る数フレームを待つ
	for _w in range(4):
		await process_frame

	# 検証 1: history_idx が最新エントリへ追従したか
	_check(main_inst._battle_edit_history_idx == live_idx,
		"history_idx followed autonomous advance (expected=%d actual=%d)" % [
			live_idx, main_inst._battle_edit_history_idx])

	# 検証 2: スライダー編集が表示中(=live)エントリへ書き込まれ、過去エントリは無傷
	var sl: Dictionary = main_inst._battle_edit_sl
	if sl.is_empty() or sl.get("scale") == null:
		printerr("[NAVSYNC] FAIL: edit sliders not available")
		_fails += 1
	else:
		sl.scale.value = 0.55
		sl.x.value = 30
		sl.y.value = -120
		main_inst._on_battle_slider(0.55, sl, main_inst._battle_edit_ref)
		for _w in range(2):
			await process_frame
		var elog: Array = main_inst._battle_edit_get_log()
		# 過去エントリ #0 (guard_024) は変更されていないこと
		_check(is_equal_approx(elog[stale_idx].get("scale", -1.0), stale_scale_before),
			"stale entry #%d scale unchanged (%.3f)" % [stale_idx, stale_scale_before])
		_check(elog[stale_idx].get("position", Vector2.ZERO).is_equal_approx(stale_pos_before),
			"stale entry #%d position unchanged" % stale_idx)
		_check(elog[stale_idx].get("texture") == stale_tex,
			"stale entry #%d texture unchanged" % stale_idx)
		# live エントリにスライダー値が反映されていること
		_check(is_equal_approx(elog[live_idx].get("scale", -1.0), 0.55),
			"live entry #%d scale updated to 0.55 (actual=%.3f)" % [
				live_idx, elog[live_idx].get("scale", -1.0)])

	printerr("[NAVSYNC] done, fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
