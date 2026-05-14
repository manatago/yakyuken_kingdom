extends SceneTree
# 実マウスクリック相当を Viewport.push_input で送り込み、
# Button が確かに pressed を発火するかを検証する単体スモーク。

func _initialize():
	printerr("[UICLICK] start; gui_disable_input=%s" % root.gui_disable_input)
	root.gui_disable_input = false
	# 最小限のシーン: root → Control → Button
	var control := Control.new()
	control.size = Vector2(400, 200)
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.add_child(control)
	var btn := Button.new()
	btn.text = "TEST"
	btn.position = Vector2(50, 50)
	btn.custom_minimum_size = Vector2(120, 40)
	control.add_child(btn)

	var fired := [false]
	btn.pressed.connect(func(): fired[0] = true)

	await process_frame
	await process_frame
	var btn_rect := btn.get_global_rect()
	var click_pos := btn_rect.position + btn_rect.size * 0.5
	printerr("[UICLICK] btn_rect=%s click_pos=%s" % [btn_rect, click_pos])

	# --- approach 1: Viewport.push_input ---
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = click_pos
	press.global_position = click_pos
	root.push_input(press)
	await process_frame
	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = click_pos
	rel.global_position = click_pos
	root.push_input(rel)
	await process_frame
	await process_frame
	printerr("[UICLICK] approach1 (push_input): fired=%s" % fired[0])

	if not fired[0]:
		# --- approach 2: viewport._gui_input ---
		var press2 := InputEventMouseButton.new()
		press2.button_index = MOUSE_BUTTON_LEFT
		press2.pressed = true
		press2.position = click_pos
		press2.global_position = click_pos
		if root.has_method("_gui_input"):
			root._gui_input(press2)
		var rel2 := InputEventMouseButton.new()
		rel2.button_index = MOUSE_BUTTON_LEFT
		rel2.pressed = false
		rel2.position = click_pos
		rel2.global_position = click_pos
		if root.has_method("_gui_input"):
			root._gui_input(rel2)
		await process_frame
		printerr("[UICLICK] approach2 (viewport._gui_input): fired=%s" % fired[0])

	if not fired[0]:
		# --- approach 3: btn._gui_input directly ---
		var press3 := InputEventMouseButton.new()
		press3.button_index = MOUSE_BUTTON_LEFT
		press3.pressed = true
		press3.position = Vector2(60, 20)
		press3.global_position = click_pos
		btn._gui_input(press3)
		var rel3 := InputEventMouseButton.new()
		rel3.button_index = MOUSE_BUTTON_LEFT
		rel3.pressed = false
		rel3.position = Vector2(60, 20)
		rel3.global_position = click_pos
		btn._gui_input(rel3)
		await process_frame
		printerr("[UICLICK] approach3 (btn._gui_input): fired=%s" % fired[0])

	if fired[0]:
		quit(0)
	else:
		printerr("[UICLICK] all approaches failed in headless. Falling back to signal.emit() for tests")
		quit(1)
