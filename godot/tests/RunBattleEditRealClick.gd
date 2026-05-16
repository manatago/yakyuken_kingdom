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

	# --- 勝負フロー検証: ▶ で勝負待ちになるまで進め、結果強制ボタン＋カードで決着 ---
	# ▶ を押して select_hand（勝負待ち）まで進める
	var battle = main_inst._battle_edit_ref
	var reached_match := false
	for _m in range(8):
		await _click(_center_of(next_btn))
		await _wait_idle(main_inst)
		if is_instance_valid(battle) and "_force_result_container" in battle \
				and battle._force_result_container != null \
				and is_instance_valid(battle._force_result_container):
			reached_match = true
			break
	if not reached_match:
		printerr("[REAL] FAIL — ▶ で勝負待ち（結果強制ボタン）に到達できない")
		quit(1); return
	printerr("[REAL] 勝負待ちに到達。結果強制ボタンで決着させる")

	var log_before_match: int = main_inst._battle_edit_get_log().size()

	# 結果強制「勝ち」ボタンをクリック
	var win_btn: Button = null
	for c in battle._force_result_container.find_children("*", "Button", true, false):
		if c is Button and "勝ち" in c.text:
			win_btn = c
			break
	if win_btn == null:
		printerr("[REAL] FAIL — 結果強制『勝ち』ボタンが見つからない")
		quit(1); return
	await _click(_center_of(win_btn))

	# デッキのカードを1枚選択
	var card_btn: BaseButton = null
	for entry in battle._deck_buttons:
		if not entry.get("used", false) and entry.get("button"):
			card_btn = entry.button
			break
	if card_btn == null:
		printerr("[REAL] FAIL — デッキのカードボタンが見つからない")
		quit(1); return
	await _click(_center_of(card_btn))
	# 勝負（確定）ボタン
	await _click(_center_of(battle.confirm_button))

	# janken オーバーレイの解決を待つ
	for _w in range(240):
		await process_frame

	# 旧バグ検証: select_hand が解決されずバトルが select_hand で停止していないこと。
	# 解決していれば _clear_force_result_buttons により結果強制パネルが消える。
	# （相手 outfit が1つだけのバトルは勝利で終了する＝それも「停止していない」）
	var stalled := false
	if is_instance_valid(battle):
		if "_force_result_container" in battle \
				and battle._force_result_container != null \
				and is_instance_valid(battle._force_result_container):
			stalled = true
	var battle_ended := not is_instance_valid(battle)
	printerr("[REAL] 勝負後: battle_ended=%s force_panel_残存=%s" % [battle_ended, stalled])
	if stalled:
		printerr("[REAL] FAIL — 勝負後も結果強制パネルが残存（select_hand が停止＝途中停止バグ）")
		quit(1); return

	printerr("[REAL] OK — ▶ 履歴・◀/▶・勝負フロー（結果強制で決着→停止せず進行）すべて成功")
	quit(0)
