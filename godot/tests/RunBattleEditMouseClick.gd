extends SceneTree
# 実マウスクリックパスを通す診断:
#   Input.parse_input_event() で InputEventMouseButton を viewport へ流して、
#   ホイットボックス上でクリックが ◀ ボタンに届いて pressed が発火するかを検証する。

const GameStateScript := preload("res://game/GameState.gd")

func _initialize():
	printerr("[CLICK] start")
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	var main_packed = load("res://Main.tscn")
	var main_inst = main_packed.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	main_inst.edit_mode_button.pressed.emit()
	await process_frame
	var event_btn: Button = null
	for child in main_inst.jump_list.get_children():
		if child is Button and "イベントバトル" in child.text:
			event_btn = child
			break
	event_btn.pressed.emit()
	await process_frame
	var stage1_btn: Button = null
	for child in main_inst.jump_list.get_children():
		if child is Button and "ステージ1" in child.text:
			stage1_btn = child
			break
	stage1_btn.pressed.emit()

	# 立ち上げ待ち
	for i in 50:
		await process_frame

	var panel: PanelContainer = null
	for child in main_inst.get_children():
		if child is PanelContainer:
			panel = child
			break
	if panel == null:
		printerr("[CLICK] FAIL: no panel")
		quit(1); return

	var prev_btn: Button = panel.find_child("PrevBtn", true, false)
	var target_label: Label = panel.find_child("TargetLabel", true, false)

	# ボタンの絶対位置を取得
	var btn_rect: Rect2 = prev_btn.get_global_rect()
	var click_pos: Vector2 = btn_rect.position + btn_rect.size * 0.5
	printerr("[CLICK] prev_btn global_rect=%s click_pos=%s" % [btn_rect, click_pos])
	printerr("[CLICK] panel visible=%s prev_btn visible=%s prev_btn.disabled=%s" % [panel.visible, prev_btn.visible, prev_btn.disabled])
	printerr("[CLICK] initial label='%s'" % target_label.text)

	# hover check
	root.gui_disable_input = false
	var pressed_observed := [false]
	prev_btn.pressed.connect(func(): pressed_observed[0] = true)

	# マウスを移動させる
	var move_ev := InputEventMouseMotion.new()
	move_ev.position = click_pos
	move_ev.global_position = click_pos
	Input.parse_input_event(move_ev)
	await process_frame
	var hovered = root.gui_get_hovered_control()
	printerr("[CLICK] hovered control after move=%s" % hovered)

	# 左ボタン押下
	var press_ev := InputEventMouseButton.new()
	press_ev.button_index = MOUSE_BUTTON_LEFT
	press_ev.pressed = true
	press_ev.position = click_pos
	press_ev.global_position = click_pos
	Input.parse_input_event(press_ev)
	await process_frame
	# 左ボタン離す
	var rel_ev := InputEventMouseButton.new()
	rel_ev.button_index = MOUSE_BUTTON_LEFT
	rel_ev.pressed = false
	rel_ev.position = click_pos
	rel_ev.global_position = click_pos
	Input.parse_input_event(rel_ev)
	await process_frame
	await process_frame

	printerr("[CLICK] pressed_observed=%s" % pressed_observed[0])
	printerr("[CLICK] after click: target=%s label='%s'" % [main_inst._battle_edit_target_rect, target_label.text])

	printerr("[CLICK] DONE")
	quit(0)
