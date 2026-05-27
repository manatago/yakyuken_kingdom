extends SceneTree
# ストーリー編集の ◀/▶ ナビで portrait_log が「次の画像」エントリを残す不具合の回帰テスト。
# 症状: ▶ で先へ進むと portrait_log が溜まり、◀ で前へ戻っても reset_scene が log を
# 消さないため、保存が「rect の最後のエントリ=次の画像の行」を書き換えてしまう。
# 検証: ▶ を多数 → ◀ を数回 戻したとき、portrait_log が [0..idx] 相当に縮むこと
# （バグ時は縮まず N_near == N_far のまま）。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditNavLogStale.gd

const GameStateScript := preload("res://game/GameState.gd")

func _nav(main_inst, action: String) -> bool:
	var before: int = main_inst._story_edit_current_idx
	for _f in range(80):
		main_inst._story_edit_nav_action = action
		await process_frame
		if main_inst._story_edit_current_idx != before:
			return true
	return false

func _plog_size(main_inst) -> int:
	var sc = main_inst.story_scene_instance
	if sc and "portrait_log" in sc:
		return sc.portrait_log.size()
	return -1

func _initialize():
	printerr("[NAVLOG] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var entry := {"id": "subevent1_hideout", "name": "前半2", "chapter": "Subevent1ChapterScript"}
	var coro = func():
		await main_inst._run_story_edit(entry)
	coro.call()
	for _w in range(150): await process_frame

	# StoryEditRoot が立ち上がっているか
	var has_root := false
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			has_root = true
			break
	if not has_root:
		printerr("[NAVLOG] FAIL — StoryEditRoot が無い（編集モードに入れていない）")
		quit(1); return

	# ▶ を多数押して先へ進める（portrait_log を溜める）
	var advanced := 0
	for i in range(30):
		var ok: bool = await _nav(main_inst, "next")
		if not ok:
			break
		advanced += 1
	var idx_far: int = main_inst._story_edit_current_idx
	var n_far: int = _plog_size(main_inst)
	printerr("[NAVLOG] ▶x%d 後: idx=%d portrait_log=%d" % [advanced, idx_far, n_far])
	if advanced < 3 or n_far < 2:
		printerr("[NAVLOG] FAIL — 前提不成立（前進%d / log%d）。シーケンスが短すぎる" % [advanced, n_far])
		quit(1); return

	# ◀ を数回戻す
	var backed := 0
	for i in range(min(advanced - 1, 12)):
		var ok2: bool = await _nav(main_inst, "prev")
		if not ok2:
			break
		backed += 1
	var idx_near: int = main_inst._story_edit_current_idx
	var n_near: int = _plog_size(main_inst)
	printerr("[NAVLOG] ◀x%d 後: idx=%d portrait_log=%d" % [backed, idx_near, n_near])

	if idx_near >= idx_far:
		printerr("[NAVLOG] FAIL — ◀ で idx が戻っていない (%d -> %d)" % [idx_far, idx_near])
		quit(1); return

	# 期待: 前へ戻ったら portrait_log は [0..idx_near] 相当に縮む。
	# バグ時は reset_scene が log を消さないので n_near == n_far のまま。
	if n_near >= n_far:
		printerr("[NAVLOG] FAIL — ◀ で戻っても portrait_log が縮まない（次の画像エントリが残存）n_far=%d n_near=%d" % [n_far, n_near])
		printerr("[NAVLOG]   → 保存が rect の最後のエントリ＝次の画像の行を書き換える不具合")
		quit(1); return

	printerr("[NAVLOG] OK — ◀ で portrait_log が縮んだ (n_far=%d → n_near=%d)。保存対象が次の画像へズレない" % [n_far, n_near])
	quit(0)
