extends SceneTree
# ランダムバトル編集モードの実クリック相当テスト。
# EditMode → ランダムバトル編集 → キャラ選択 → (エリア選択) → 装備画面 →
# エンカウント受諾 → バトル と進み、◀/▶ の立ち絵履歴ナビを検証する。
# 実行: Godot --path godot --script res://tests/RunRandomBattleEditClick.gd

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

# node 以下を再帰探索し、text を含む可視 Button を返す
func _find_button(node: Node, text_substr: String) -> Button:
	if node is Button and node.visible and (text_substr.is_empty() or text_substr in node.text):
		return node
	for c in node.get_children():
		var found := _find_button(c, text_substr)
		if found:
			return found
	return null

# node 以下に text を含む Label があるか
func _has_label(node: Node, text_substr: String) -> bool:
	if node is Label and text_substr in node.text:
		return true
	for c in node.get_children():
		if _has_label(c, text_substr):
			return true
	return false

func _initialize():
	printerr("[RND] start")
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

	# 1) EditMode
	printerr("[RND] click EditModeButton")
	await _click(_center_of(main_inst.edit_mode_button))
	await process_frame

	# 2) ランダムバトル編集
	var rnd_btn: Button = null
	for c in main_inst.jump_list.get_children():
		if c is Button and "ランダムバトル" in c.text:
			rnd_btn = c
			break
	if rnd_btn == null:
		printerr("[RND] FAIL: ランダムバトル編集 not found")
		quit(1); return
	await _click(_center_of(rnd_btn))
	for i in 10:
		await process_frame

	# 3) キャラ選択（「← 戻る」以外の最初の Button）
	var char_btn: Button = null
	for c in main_inst.jump_list.get_children():
		if c is Button and not ("戻る" in c.text):
			char_btn = c
			break
	if char_btn == null:
		printerr("[RND] FAIL: character button not found")
		quit(1); return
	printerr("[RND] pick character '%s'" % char_btn.text)
	await _click(_center_of(char_btn))

	# 4) エリア選択（出る場合のみ）→ 装備画面 → エンカウント受諾
	var reached_battle := false
	for step in range(120):
		await process_frame
		# エンカウントの受諾ボタン
		var accept := _find_button(main_inst, "受けて立つ")
		if accept:
			printerr("[RND] click 受けて立つ")
			await _click(_center_of(accept))
			reached_battle = true
			break
		# 装備画面
		var go_battle := _find_button(main_inst, "バトルへ進む")
		if go_battle:
			printerr("[RND] click バトルへ進む")
			await _click(_center_of(go_battle))
			continue
		# エリア選択パネル
		for c in main_inst.get_children():
			if c is PanelContainer and _has_label(c, "エリア選択"):
				var area_btn := _find_button(c, "")
				if area_btn:
					printerr("[RND] click area '%s'" % area_btn.text)
					await _click(_center_of(area_btn))
				break
	if not reached_battle:
		printerr("[RND] FAIL: never reached encounter accept")
		quit(1); return

	# 5) バトル立ち上げ待ち
	for i in 40:
		await process_frame

	# 6) 編集パネル発見
	var panel: PanelContainer = null
	for c in main_inst.get_children():
		if c is PanelContainer and c.find_child("PrevBtn", true, false):
			panel = c
			break
	if panel == null:
		printerr("[RND] FAIL: no edit panel with PrevBtn")
		quit(1); return
	var prev_btn: Button = panel.find_child("PrevBtn", true, false)
	var next_btn: Button = panel.find_child("NextBtn", true, false)
	if not (prev_btn and next_btn):
		printerr("[RND] FAIL: panel structure")
		quit(1); return

	for i in 20:
		await process_frame

	# 7) ▶ を2回 → 履歴が増えるか
	var hist0: int = main_inst._battle_edit_get_log().size()
	printerr("[RND] portrait_log size (initial) = %d" % hist0)
	await _click(_center_of(next_btn))
	await _wait_idle(main_inst)
	await _click(_center_of(next_btn))
	await _wait_idle(main_inst)
	var hist1: int = main_inst._battle_edit_get_log().size()
	var idx1: int = main_inst._battle_edit_history_idx
	printerr("[RND] after ▶x2: portrait_log size=%d idx=%d" % [hist1, idx1])
	if hist1 < 2:
		printerr("[RND] FAIL — ▶ で画像履歴が増えていない (%d)" % hist1)
		quit(1); return

	# 8) ◀ で1つ戻る + 位置が巻き戻らないか
	var idx_before: int = main_inst._battle_edit_history_idx
	await _click(_center_of(prev_btn))
	await _wait_idle(main_inst)
	var idx_after: int = main_inst._battle_edit_history_idx
	printerr("[RND] after ◀: idx %d -> %d" % [idx_before, idx_after])
	if idx_after != idx_before - 1:
		printerr("[RND] FAIL — ◀ で history_idx が1つ戻っていない (%d -> %d)" % [idx_before, idx_after])
		quit(1); return
	var rect_after: TextureRect = main_inst._battle_edit_target_rect
	if rect_after and is_instance_valid(rect_after):
		var pos_just := rect_after.position
		for _w in range(20):
			await process_frame
		var pos_settled := rect_after.position
		printerr("[RND] pos after ◀: just=%s settled=%s" % [pos_just, pos_settled])
		if not pos_just.is_equal_approx(pos_settled):
			printerr("[RND] FAIL — ◀ 後に立ち絵位置が巻き戻った %s -> %s" % [pos_just, pos_settled])
			quit(1); return

	# 9) ▶ で1つ進む
	await _click(_center_of(next_btn))
	await _wait_idle(main_inst)
	var idx_fwd: int = main_inst._battle_edit_history_idx
	printerr("[RND] after ▶: idx %d -> %d" % [idx_after, idx_fwd])
	if idx_fwd != idx_after + 1:
		printerr("[RND] FAIL — ▶ で history_idx が1つ進んでいない (%d -> %d)" % [idx_after, idx_fwd])
		quit(1); return

	# 10) 勝負フロー検証: ▶ で勝負待ちまで進め、結果強制ボタン＋カードで決着
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
		printerr("[RND] FAIL — ▶ で勝負待ち（結果強制ボタン）に到達できない")
		quit(1); return
	printerr("[RND] 勝負待ちに到達。結果強制ボタンで決着させる")

	# 結果強制「勝ち」
	var win_btn: Button = null
	for c in battle._force_result_container.find_children("*", "Button", true, false):
		if c is Button and "勝ち" in c.text:
			win_btn = c
			break
	if win_btn == null:
		printerr("[RND] FAIL — 結果強制『勝ち』ボタンが見つからない")
		quit(1); return
	await _click(_center_of(win_btn))

	# カード選択 → 勝負
	var card_btn: BaseButton = null
	for entry in battle._deck_buttons:
		if not entry.get("used", false) and entry.get("button"):
			card_btn = entry.button
			break
	if card_btn == null:
		printerr("[RND] FAIL — デッキのカードボタンが見つからない")
		quit(1); return
	await _click(_center_of(card_btn))
	await _click(_center_of(battle.confirm_button))

	for _w in range(240):
		await process_frame

	# 旧バグ検証: select_hand が解決されず停止していないこと
	var stalled := false
	if is_instance_valid(battle):
		if "_force_result_container" in battle \
				and battle._force_result_container != null \
				and is_instance_valid(battle._force_result_container):
			stalled = true
	printerr("[RND] 勝負後: battle_ended=%s force_panel_残存=%s" % [not is_instance_valid(battle), stalled])
	if stalled:
		printerr("[RND] FAIL — 勝負後も結果強制パネルが残存（途中停止バグ）")
		quit(1); return

	printerr("[RND] OK — ランダムバトル編集で ▶履歴・◀/▶・位置維持・勝負フロー すべて成功")
	quit(0)
