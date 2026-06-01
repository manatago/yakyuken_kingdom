extends SceneTree
# ストーリー編集で、同じコマンド位置(idx)へ ▶ で到達した時と ◀ で戻った時に、
# 表示中の立ち絵設定（カードの scale/x/y とテクスチャ）が一致するかを検証する。
# ユーザー報告:「戻るで確認した時と、次へをクリックした時で画像の設定が合わない」。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditNavConsistency.gd

const GameStateScript := preload("res://game/GameState.gd")

func _nav(main_inst, action: String) -> bool:
	var before: int = main_inst._story_edit_current_idx
	for _f in range(80):
		main_inst._story_edit_nav_action = action
		await process_frame
		if main_inst._story_edit_current_idx != before:
			return true
	return false

func _root_of(main_inst) -> Control:
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			return child
	return null

# 右カード（center/right 優先）の現在値スナップショットを取る
func _snap(main_inst) -> Dictionary:
	var root := _root_of(main_inst)
	if not root:
		return {}
	var card: PanelContainer = root.find_child("StoryEditCard_Right", true, false)
	if not card or not card.visible:
		return {"visible": false}
	var sl: Dictionary = main_inst._get_edit_sliders(card)
	if sl.is_empty():
		return {"visible": false}
	var rect = card.get_meta("bound_rect", null)
	var tex := ""
	if is_instance_valid(rect) and rect.texture and rect.texture.resource_path:
		tex = rect.texture.resource_path
	return {
		"visible": true,
		"scale": snappedf(sl.scale.value, 0.001),
		"x": int(sl.x.value),
		"y": int(sl.y.value),
		"tex": tex,
		"side": card.get_meta("bound_side", ""),
	}

func _eq(a: Dictionary, b: Dictionary) -> bool:
	if a.get("visible") != b.get("visible"):
		return false
	if not a.get("visible"):
		return true
	return a.get("tex") == b.get("tex") \
		and is_equal_approx(a.get("scale"), b.get("scale")) \
		and a.get("x") == b.get("x") and a.get("y") == b.get("y")

func _initialize():
	printerr("[NAVCONS] start")
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

	if not _root_of(main_inst):
		printerr("[NAVCONS] FAIL — 編集モードに入れていない")
		quit(1); return

	# ▶ で前進しながら各 idx のスナップショットを記録
	var fwd := {}    # idx -> snap
	fwd[main_inst._story_edit_current_idx] = _snap(main_inst)
	var steps := 0
	for i in range(28):
		var ok: bool = await _nav(main_inst, "next")
		if not ok:
			break
		steps += 1
		fwd[main_inst._story_edit_current_idx] = _snap(main_inst)
	printerr("[NAVCONS] ▶x%d 記録 idx=%d" % [steps, main_inst._story_edit_current_idx])
	if steps < 4:
		printerr("[NAVCONS] FAIL — 前進不足(%d)" % steps)
		quit(1); return

	# ◀ で戻りながら、同 idx の値が forward と一致するか比較
	var mismatches := 0
	var compared := 0
	for i in range(steps):
		var ok2: bool = await _nav(main_inst, "prev")
		if not ok2:
			break
		var idx_now: int = main_inst._story_edit_current_idx
		if not fwd.has(idx_now):
			continue
		var back_snap := _snap(main_inst)
		var fwd_snap: Dictionary = fwd[idx_now]
		compared += 1
		if not _eq(fwd_snap, back_snap):
			mismatches += 1
			printerr("[NAVCONS] MISMATCH idx=%d  ▶=%s  ◀=%s" % [idx_now, fwd_snap, back_snap])

	printerr("[NAVCONS] 比較 %d 件中 不一致 %d 件" % [compared, mismatches])
	if compared < 3:
		printerr("[NAVCONS] FAIL — 比較対象が少なすぎる(%d)" % compared)
		quit(1); return
	if mismatches > 0:
		printerr("[NAVCONS] FAIL — ▶到達時と◀到達時で立ち絵設定が一致しない(%d件)" % mismatches)
		quit(1); return

	printerr("[NAVCONS] OK — ▶到達と◀到達で立ち絵設定が一致(%d件比較)" % compared)
	quit(0)
