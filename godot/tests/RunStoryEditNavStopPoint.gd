extends SceneTree
# ストーリー編集の ▶/◀ ナビが、実機と同じ「停止ポイント（テキスト付き Band/Line または Battle）」
# 単位で動くことを検証する。間にある set_portrait/background/hide_character/SeqLabel 等は
# 1クリックで一気に適用され、絵だけ/テキストだけのチラ見せが起きない。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditNavStopPoint.gd

const GameStateScript := preload("res://game/GameState.gd")
const StoryCommandsScript := preload("res://story/StoryCommands.gd")

var _fails: int = 0
func _check(c, m):
	if c:
		printerr("[STOP] PASS: %s" % m)
	else:
		printerr("[STOP] FAIL: %s" % m)
		_fails += 1

func _nav(main_inst, action: String) -> bool:
	var before: int = main_inst._story_edit_current_idx
	for _f in range(80):
		main_inst._story_edit_nav_action = action
		await process_frame
		if main_inst._story_edit_current_idx != before:
			return true
	return false

func _is_stop(e) -> bool:
	if e == null: return false
	if e is StoryCommandsScript.Band and not e.text.is_empty(): return true
	if e is StoryCommandsScript.Line and not e.text.is_empty(): return true
	if e is StoryCommandsScript.Battle: return true
	return false

func _initialize():
	printerr("[STOP] start")
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

	# 編集モード起動確認
	var found_root := false
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			found_root = true; break
	_check(found_root, "編集モードに入れた")
	if not found_root:
		quit(1); return

	# entries 取得
	var entries: Array = []
	if main_inst.story_script:
		var seq = main_inst.story_script.get_sequence("subevent1_hideout")
		if seq: entries = seq.entries
	_check(entries.size() > 10, "シーケンスのエントリが取れている（%d 件）" % entries.size())

	# 初期位置: setup_end は最初の停止ポイントの筈
	var idx0: int = main_inst._story_edit_current_idx
	_check(_is_stop(entries[idx0]), "初期 idx=%d は停止ポイント（Band/Line/Battle）" % idx0)

	# ▶ を 5 回押し、毎回「次の停止ポイント」にジャンプしているかを確認
	var jump_idxs: Array = [idx0]
	var jump_sizes: Array = []
	for step in range(5):
		var ok: bool = await _nav(main_inst, "next")
		if not ok: break
		var cur: int = main_inst._story_edit_current_idx
		jump_sizes.append(cur - jump_idxs[-1])
		jump_idxs.append(cur)
		# 着地点は停止ポイント
		_check(_is_stop(entries[cur]), "▶後 idx=%d も停止ポイント" % cur)
		# 中間に他の停止ポイントが無い（あったらそこで止まっている筈）
		var intermediate_stops := 0
		for j in range(jump_idxs[-2] + 1, cur):
			if _is_stop(entries[j]):
				intermediate_stops += 1
		_check(intermediate_stops == 0, "中間に停止ポイントが残っていない (idx=%d→%d, 中間stops=%d)" % [jump_idxs[-2], cur, intermediate_stops])

	printerr("[STOP] ▶ ジャンプ幅: %s" % [jump_sizes])
	# 単純な +1 単位ではない＝1クリックで複数コマンド進んでいる
	var has_multi_jump := false
	for jz in jump_sizes:
		if jz > 1:
			has_multi_jump = true; break
	_check(has_multi_jump, "▶ で複数コマンド一気に進んだクリックが少なくとも1回ある（チラ見せ防止）")

	# ◀ で戻り、前の停止ポイントに戻ること
	var idx_last: int = jump_idxs[-1]
	var idx_prev_recorded: int = jump_idxs[-2]
	var ok_back: bool = await _nav(main_inst, "prev")
	_check(ok_back, "◀ で idx が動いた")
	var idx_after_back: int = main_inst._story_edit_current_idx
	_check(idx_after_back == idx_prev_recorded, "◀ が前の停止ポイントに戻った（記録 %d, 実測 %d）" % [idx_prev_recorded, idx_after_back])

	printerr("[STOP] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
