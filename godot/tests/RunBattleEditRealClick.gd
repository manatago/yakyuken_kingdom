extends SceneTree
# 実ディスプレイ + Viewport.push_input による実クリック相当の自動テスト。
# 実行: Godot --path godot --script res://tests/RunBattleEditRealClick.gd
# (--headless は付けない。macOS/Windows/Linux のいずれもディスプレイ必須)

const GameStateScript := preload("res://game/GameState.gd")

func _click(pos: Vector2):
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	root.push_input(press)
	await process_frame
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = pos
	rel.global_position = pos
	root.push_input(rel)
	await process_frame
	await process_frame

func _center_of(ctrl: Control) -> Vector2:
	var r := ctrl.get_global_rect()
	return r.position + r.size * 0.5

func _wait_idle(main_inst):
	for _w in range(300):
		await process_frame
		if not main_inst._battle_edit_advancing:
			return

func _initialize():
	printerr("[REAL] start")
	root.gui_disable_input = false
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	var main_packed = load("res://Main.tscn")
	var main_inst = main_packed.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	# 1) EditMode ボタンを実クリック
	printerr("[REAL] click EditModeButton")
	await _click(_center_of(main_inst.edit_mode_button))
	await process_frame
	printerr("[REAL] jump_menu visible=%s, jump_list children=%d" % [main_inst.jump_menu.visible, main_inst.jump_list.get_child_count()])

	# 2) イベントバトル編集 ボタンを実クリック
	var event_btn: Button = null
	for c in main_inst.jump_list.get_children():
		if c is Button and "イベントバトル" in c.text:
			event_btn = c
			break
	if event_btn == null:
		printerr("[REAL] FAIL: イベントバトル編集 not found")
		quit(1); return
	printerr("[REAL] click '%s'" % event_btn.text)
	await _click(_center_of(event_btn))
	await process_frame
	await process_frame

	# 3) 環境変数 CHAPTER で章を選択（デフォルトはステージ1）
	var target_name: String = "ステージ1"
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("chapter="):
			target_name = a.substr(8)
	printerr("[REAL] target_name=%s" % target_name)
	var stage_btn: Button = null
	for c in main_inst.jump_list.get_children():
		if c is Button and target_name in c.text:
			stage_btn = c
			break
	if stage_btn == null:
		printerr("[REAL] FAIL: '%s' not found in list" % target_name)
		for c in main_inst.jump_list.get_children():
			if c is Button:
				printerr("[REAL]   available: '%s'" % c.text)
		quit(1); return
	printerr("[REAL] click '%s'" % stage_btn.text)
	await _click(_center_of(stage_btn))

	# 4) バトル立ち上げ待ち
	for i in 30:
		await process_frame

	# 5) パネル発見
	var panel: PanelContainer = null
	for c in main_inst.get_children():
		if c is PanelContainer:
			panel = c
			break
	if panel == null:
		printerr("[REAL] FAIL: no edit panel")
		quit(1); return
	var prev_btn = panel.find_child("PrevBtn", true, false)
	var target_label: Label = panel.find_child("TargetLabel", true, false)
	if not (prev_btn and target_label):
		printerr("[REAL] FAIL: panel structure")
		quit(1); return
	printerr("[REAL] initial label='%s'" % target_label.text)

	# 6) 履歴方式の検証 — StoryScene.portrait_log を参照
	var next_btn: Button = panel.find_child("NextBtn", true, false)
	for i in 20:
		await process_frame

	var log: Array = main_inst._battle_edit_get_log()
	# ▶ を2回押して履歴を増やす（末尾なのでバトル進行 → 新画像生成）
	var hist0: int = log.size()
	printerr("[REAL] portrait_log size (initial) = %d, idx=%d" % [hist0, main_inst._battle_edit_history_idx])
	await _click(_center_of(next_btn))
	await _wait_idle(main_inst)
	await _click(_center_of(next_btn))
	await _wait_idle(main_inst)
	var hist1: int = main_inst._battle_edit_get_log().size()
	var idx1: int = main_inst._battle_edit_history_idx
	printerr("[REAL] after ▶x2: portrait_log size=%d idx=%d" % [hist1, idx1])

	if hist1 < 2:
		printerr("[REAL] FAIL — ▶ で画像履歴が増えていない (%d)" % hist1)
		quit(1); return

	# 現在表示中のテクスチャを記録
	var tex_at_latest = null
	if main_inst._battle_edit_target_rect and is_instance_valid(main_inst._battle_edit_target_rect):
		tex_at_latest = main_inst._battle_edit_target_rect.texture
	printerr("[REAL] tex at latest = %s" % tex_at_latest)

	# ◀ で1つ前の画像へ
	var idx_before_back: int = main_inst._battle_edit_history_idx
	await _click(_center_of(prev_btn))
	await _wait_idle(main_inst)
	var idx_after_back: int = main_inst._battle_edit_history_idx
	var tex_after_back = null
	if main_inst._battle_edit_target_rect and is_instance_valid(main_inst._battle_edit_target_rect):
		tex_after_back = main_inst._battle_edit_target_rect.texture
	printerr("[REAL] after ◀: idx %d -> %d, tex=%s" % [idx_before_back, idx_after_back, tex_after_back])

	if idx_after_back != idx_before_back - 1:
		printerr("[REAL] FAIL — ◀ で history_idx が1つ戻っていない (%d -> %d)" % [idx_before_back, idx_after_back])
		quit(1); return

	# ◀ で前の画像のテクスチャに変わったか（履歴に複数あれば別テクスチャのはず）
	printerr("[REAL] tex changed by ◀: %s" % (tex_after_back != tex_at_latest))

	# 復元位置が StoryScene._process で巻き戻らないか（横ずれ回帰検出）
	var rect_after_back: TextureRect = main_inst._battle_edit_target_rect
	if rect_after_back and is_instance_valid(rect_after_back):
		var pos_just_after := rect_after_back.position
		for _w in range(20):
			await process_frame
		var pos_settled := rect_after_back.position
		printerr("[REAL] pos after ◀: just=%s settled=%s" % [pos_just_after, pos_settled])
		if not pos_just_after.is_equal_approx(pos_settled):
			printerr("[REAL] FAIL — ◀ 後に立ち絵位置が巻き戻った（横ずれ） %s -> %s" % [pos_just_after, pos_settled])
			quit(1); return

	# ▶ で1つ次へ戻る
	await _click(_center_of(next_btn))
	await _wait_idle(main_inst)
	var idx_after_fwd: int = main_inst._battle_edit_history_idx
	printerr("[REAL] after ▶: idx %d -> %d" % [idx_after_back, idx_after_fwd])

	if idx_after_fwd != idx_after_back + 1:
		printerr("[REAL] FAIL — ▶ で history_idx が1つ進んでいない (%d -> %d)" % [idx_after_back, idx_after_fwd])
		quit(1); return

	# --- 回帰検証(A): ◀ で古い画像に停車中、ライブのバトルが portrait_log を
	# 伸ばしても _process が history_idx を末尾へ飛ばさないこと。
	# 飛ばすと保存対象（history_idx → edit_source_id → file:line）が「次の画像」の
	# set_portrait 行へズレる＝ユーザー報告「保存すると次の画像の設定が変わる」不具合。
	await _click(_center_of(prev_btn))            # ◀ で先頭(0)へ
	await _wait_idle(main_inst)
	var parked_idx: int = main_inst._battle_edit_history_idx
	printerr("[REAL] 停車 idx=%d" % parked_idx)
	if parked_idx != 0:
		printerr("[REAL] FAIL — ◀ で先頭(0)へ戻れていない (idx=%d)" % parked_idx)
		quit(1); return

	var elog: Array = main_inst._battle_edit_get_log()
	var saved_src_before: String = elog[parked_idx].get("edit_source_id", "")
	var size_before: int = elog.size()
	# ライブのバトルが新しい立ち絵を表示した状況を擬似（portrait_log を1つ伸ばす）
	elog.append({
		"rect": main_inst._battle_edit_target_rect,
		"texture": null,
		"scale": 0.99,
		"position": Vector2(123, 456),
		"edit_source_id": "res://battle/chapters/FAKE_LIVE.gd:999",
	})
	for _w in range(10):
		await process_frame
	var parked_idx2: int = main_inst._battle_edit_history_idx
	printerr("[REAL] log %d->%d 後の idx=%d (期待: %d 維持)" % [size_before, elog.size(), parked_idx2, parked_idx])
	if parked_idx2 != parked_idx:
		printerr("[REAL] FAIL — ライブ log 増加で history_idx が末尾へ飛んだ（保存先がズレる回帰）%d -> %d" % [parked_idx, parked_idx2])
		quit(1); return

	# 保存対象（history_idx → edit_source_id）が「停車中の画像」のままで、
	# 後から増えた FAKE_LIVE 行を指していないこと
	var saved_src_after: String = elog[main_inst._battle_edit_history_idx].get("edit_source_id", "")
	if saved_src_after != saved_src_before or "FAKE_LIVE" in saved_src_after:
		printerr("[REAL] FAIL — 保存対象が別行へズレた '%s' -> '%s'" % [saved_src_before, saved_src_after])
		quit(1); return
	printerr("[REAL] 保存対象は据え置き: %s" % saved_src_after)

	printerr("[REAL] OK — ▶履歴・◀/▶・位置維持・保存先据え置き(回帰A) すべて成功")
	quit(0)
