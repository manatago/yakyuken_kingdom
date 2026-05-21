extends SceneTree
# サブイベント1編集モードでスライダーが立ち絵に反映されるかを検証する。
# 実行: Godot --path godot --headless --script res://tests/RunSubevent1EditSlider.gd

func _check(cond: bool, msg: String):
	printerr("[SE1] %s: %s" % [("PASS" if cond else "FAIL"), msg])

func _initialize():
	printerr("[SE1] start")
	var gs = preload("res://game/GameState.gd").new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var entry := {"id": "subevent1_pre", "name": "サブイベント1 前半", "chapter": "Subevent1ChapterScript"}
	var coro = func():
		await main_inst._run_story_edit(entry)
	coro.call()
	for _w in range(100): await process_frame

	# レイアウト確認
	var layout: Control = null
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			layout = child; break
	_check(layout != null, "StoryEditRoot exists")
	if not layout:
		quit(1); return

	var left_card: PanelContainer = layout.find_child("StoryEditCard_Left", true, false)
	var right_card: PanelContainer = layout.find_child("StoryEditCard_Right", true, false)
	_check(left_card != null, "left card found")
	_check(right_card != null, "right card found")

	# シーン上の立ち絵状態
	var sc = main_inst.story_scene_instance
	printerr("[SE1] left_char visible=%s tex=%s" % [sc.left_char.visible, sc.left_char.texture])
	printerr("[SE1] right_char visible=%s tex=%s" % [sc.right_char.visible, sc.right_char.texture])
	printerr("[SE1] center_char visible=%s tex=%s" % [sc.center_char.visible, sc.center_char.texture])

	# カード bind 状態
	printerr("[SE1] left card visible=%s bound_side=%s bound_rect=%s" % [
		left_card.visible,
		left_card.get_meta("bound_side", "(none)"),
		left_card.get_meta("bound_rect", null)
	])
	printerr("[SE1] right card visible=%s bound_side=%s bound_rect=%s" % [
		right_card.visible,
		right_card.get_meta("bound_side", "(none)"),
		right_card.get_meta("bound_rect", null)
	])

	# 表示中のカードでスライダーを動かして、bound_rect の位置が変わるか確認
	var test_card: PanelContainer = null
	for c in [left_card, right_card]:
		if c.visible and c.has_meta("bound_rect"):
			var br = c.get_meta("bound_rect")
			if is_instance_valid(br):
				test_card = c
				break
	_check(test_card != null, "at least one bound card visible")
	if test_card:
		var sl: Dictionary = main_inst._get_edit_sliders(test_card)
		var bound_rect = test_card.get_meta("bound_rect")
		var before_pos = bound_rect.position
		var before_scale = bound_rect.scale
		printerr("[SE1] before: position=%s scale=%s" % [before_pos, before_scale])

		# スライダーを既知値へ
		sl.scale.value = 0.75
		sl.x.value = 100
		sl.y.value = -50
		for _w in range(4): await process_frame
		var after_pos = bound_rect.position
		var after_scale = bound_rect.scale
		printerr("[SE1] after slider: position=%s scale=%s" % [after_pos, after_scale])
		_check(after_pos.distance_to(before_pos) > 1.0, "rect position changed after slider")
		_check(abs(after_scale.x - 0.75) < 0.01, "rect scale changed to 0.75")

	# 終了
	var nav: PanelContainer = layout.find_child("StoryEditNavBar", true, false)
	if nav:
		var exit_btn: Button = nav.find_child("ExitBtn", true, false)
		if exit_btn:
			exit_btn.pressed.emit()
	for _w in range(20): await process_frame
	printerr("[SE1] done")
	quit(0)
