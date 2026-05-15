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

	# 6) ▶ 1回 → step が 0 -> 1 になることを確認（force_select_hand は合計 1.8s）
	var next_btn: Button = panel.find_child("NextBtn", true, false)
	for i in 10:
		await process_frame
	var step_before: int = main_inst._battle_edit_step
	printerr("[REAL] before ▶: step=%d label='%s'" % [step_before, target_label.text])
	await _click(_center_of(next_btn))
	# mutex 解放を 300 frame まで待つ
	var waited := 0
	for _w in range(300):
		await process_frame
		waited += 1
		if not main_inst._battle_edit_advancing:
			break
	var step_after: int = main_inst._battle_edit_step
	printerr("[REAL] after ▶: step=%d (waited=%d frames) label='%s' advancing=%s" % [step_after, waited, target_label.text, main_inst._battle_edit_advancing])

	if step_after <= step_before:
		printerr("[REAL] FAIL — ▶ で step が増えなかった (mutex がまだ %s)" % main_inst._battle_edit_advancing)
		quit(1); return
	printerr("[REAL] OK — step %d -> %d" % [step_before, step_after])

	# 7) ◀ 1回 → step 減 + battle 再生成
	var prev_step: int = step_after
	var battle_before = main_inst._battle_edit_ref
	await _click(_center_of(prev_btn))
	waited = 0
	for _w in range(300):
		await process_frame
		waited += 1
		if not main_inst._battle_edit_advancing:
			break
	var step_back: int = main_inst._battle_edit_step
	var battle_after = main_inst._battle_edit_ref
	printerr("[REAL] after ◀: step=%d (waited=%d) battle_changed=%s" % [step_back, waited, battle_before != battle_after])

	if step_back >= prev_step:
		printerr("[REAL] FAIL — ◀ で step が減らなかった (%d -> %d)" % [prev_step, step_back])
		quit(1); return
	if battle_before == battle_after:
		printerr("[REAL] FAIL — ◀ で BattleScene が再生成されていない")
		quit(1); return
	printerr("[REAL] OK — ▶ step++, ◀ step-- + battle 再生成")
	quit(0)
