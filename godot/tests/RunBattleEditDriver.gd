extends SceneTree

const GameStateScript := preload("res://game/GameState.gd")

func _initialize():
	printerr("[DRIVER] start")
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)

	var main_packed = load("res://Main.tscn")
	var main_inst = main_packed.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	# panel
	var panel = main_inst._create_edit_overlay({"name": "test_chapter"})
	main_inst.add_child(panel)
	await process_frame

	var prev_btn = panel.find_child("PrevBtn", true, false)
	var next_btn = panel.find_child("NextBtn", true, false)
	var target_label = panel.find_child("TargetLabel", true, false)
	if not (prev_btn and next_btn and target_label):
		printerr("[DRIVER] FAIL: panel missing buttons")
		quit(1); return
	printerr("[DRIVER] initial label='%s'" % target_label.text)

	# real BattleScene
	var bs_packed = load("res://BattleScene.tscn")
	var battle = bs_packed.instantiate()
	main_inst.add_child(battle)
	await process_frame
	printerr("[DRIVER] battle._story_scene=%s" % battle._story_scene)
	if battle._story_scene == null:
		# BattleScene._ready does NOT instantiate _story_scene; that's done in start_battle.
		# For test, create manually
		var sc_packed = load("res://StoryScene.tscn")
		var sc = sc_packed.instantiate()
		battle.add_child(sc)
		battle._story_scene = sc
		await process_frame
	printerr("[DRIVER] battle._story_scene now=%s" % battle._story_scene)

	# Make center_char visible
	var dummy_tex = load("res://assets/battle/cards/rock.png")
	battle._story_scene.center_char.texture = dummy_tex
	battle._story_scene.center_char.visible = true
	printerr("[DRIVER] center visible=%s has_tex=%s" % [battle._story_scene.center_char.visible, battle._story_scene.center_char.texture != null])

	# connect
	main_inst._connect_edit_to_battle(panel, battle, {})
	printerr("[DRIVER] ref=%s panel_meta=%s target=%s" % [main_inst._battle_edit_ref, main_inst._battle_edit_panel, main_inst._battle_edit_target_rect])
	printerr("[DRIVER] label after connect='%s'" % target_label.text)

	# tick _process
	for i in 5:
		await process_frame
	printerr("[DRIVER] after 5 frames: target=%s label='%s'" % [main_inst._battle_edit_target_rect, target_label.text])

	# fire prev
	prev_btn.pressed.emit()
	await process_frame
	printerr("[DRIVER] after PrevBtn: target=%s label='%s'" % [main_inst._battle_edit_target_rect, target_label.text])

	# fire next
	next_btn.pressed.emit()
	await process_frame
	printerr("[DRIVER] after NextBtn: target=%s label='%s'" % [main_inst._battle_edit_target_rect, target_label.text])

	# add second char on right
	battle._story_scene.right_char.texture = dummy_tex
	battle._story_scene.right_char.visible = true
	await process_frame
	prev_btn.pressed.emit()
	await process_frame
	printerr("[DRIVER] 2-char: after PrevBtn target=%s label='%s'" % [main_inst._battle_edit_target_rect, target_label.text])
	next_btn.pressed.emit()
	await process_frame
	printerr("[DRIVER] 2-char: after NextBtn target=%s label='%s'" % [main_inst._battle_edit_target_rect, target_label.text])

	printerr("[DRIVER] DONE")
	quit(0)
