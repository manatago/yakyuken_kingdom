extends SceneTree
# 実ユーザフロー相当のテスト:
#   1. EditMode ボタン押下
#   2. イベントバトル編集 押下
#   3. 章 (Stage1) 押下
#   4. battle.start_battle が走る間、何 frame か待つ
#   5. PrevBtn / NextBtn を押す
#   6. パネル/ボタンの可視性、ハンドラ実行、TargetLabel 更新を検証

const GameStateScript := preload("res://game/GameState.gd")

func _initialize():
	printerr("[FLOW] start")
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	var main_packed = load("res://Main.tscn")
	var main_inst = main_packed.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	printerr("[FLOW] main ready; child_count=%d" % main_inst.get_child_count())

	# Step 1: EditMode ボタン押下
	main_inst.edit_mode_button.pressed.emit()
	await process_frame
	# JumpMenu に編集メニューのボタンが並ぶ
	printerr("[FLOW] jump_menu visible=%s" % main_inst.jump_menu.visible)

	# Step 2: イベントバトル編集 ボタンを探して押下
	var event_btn: Button = null
	for child in main_inst.jump_list.get_children():
		if child is Button and "イベントバトル" in child.text:
			event_btn = child
			break
	if event_btn == null:
		printerr("[FLOW] FAIL: イベントバトル編集 button not found")
		quit(1); return
	event_btn.pressed.emit()
	await process_frame
	await process_frame

	# Step 3: 章選択画面で Stage1 を押す（PrologueBattleChapter は tutorial モードなので避ける）
	var stage1_btn: Button = null
	for child in main_inst.jump_list.get_children():
		if child is Button and "ステージ1" in child.text:
			stage1_btn = child
			break
	if stage1_btn == null:
		printerr("[FLOW] FAIL: ステージ1 button not found")
		# 何があるか列挙
		for c in main_inst.jump_list.get_children():
			if c is Button:
				printerr("[FLOW]  > available: '%s'" % c.text)
		quit(1); return
	printerr("[FLOW] clicking '%s'" % stage1_btn.text)
	stage1_btn.pressed.emit()
	await process_frame
	# _run_event_battle_edit が走る — start_battle は async
	# パネルが生成されて _connect_edit_to_battle が呼ばれるはず

	# Step 4: battle が立ち上がるまで何 frame か待つ
	for i in 30:
		await process_frame

	# Step 5: パネル発見
	var panel: PanelContainer = null
	for child in main_inst.get_children():
		if child is PanelContainer and child.has_meta("chapter_path"):
			panel = child
			break
	if panel == null:
		# meta なしでも見つけてみる
		for child in main_inst.get_children():
			if child is PanelContainer:
				panel = child
				break
	if panel == null:
		printerr("[FLOW] FAIL: edit_panel not found among Main children")
		for c in main_inst.get_children():
			printerr("[FLOW]  > main child: %s (%s)" % [c.name, c.get_class()])
		quit(1); return

	var prev_btn = panel.find_child("PrevBtn", true, false)
	var next_btn = panel.find_child("NextBtn", true, false)
	var target_label = panel.find_child("TargetLabel", true, false)
	printerr("[FLOW] panel found; PrevBtn=%s NextBtn=%s TargetLabel=%s" % [prev_btn != null, next_btn != null, target_label != null])
	if not (prev_btn and next_btn and target_label):
		quit(1); return
	printerr("[FLOW] panel visible=%s, prev_btn visible=%s" % [panel.visible, prev_btn.visible])
	printerr("[FLOW] _battle_edit_active=%s _battle_edit_ref=%s _battle_edit_target=%s" % [main_inst._battle_edit_active, main_inst._battle_edit_ref, main_inst._battle_edit_target_rect])
	printerr("[FLOW] initial label='%s'" % target_label.text)

	# 念のためもう少し待つ
	for i in 20:
		await process_frame
	printerr("[FLOW] after wait, target=%s label='%s'" % [main_inst._battle_edit_target_rect, target_label.text])

	# Step 6: PrevBtn を emit
	prev_btn.pressed.emit()
	await process_frame
	printerr("[FLOW] after PrevBtn: target=%s label='%s'" % [main_inst._battle_edit_target_rect, target_label.text])

	# Step 7: 戻るボタンで abort
	var back_btn = panel.find_child("EditBackButton", true, false)
	if back_btn:
		back_btn.pressed.emit()
		await process_frame

	printerr("[FLOW] DONE")
	quit(0)
