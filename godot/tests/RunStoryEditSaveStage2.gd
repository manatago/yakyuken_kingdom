extends SceneTree
# ユーザー報告のケース: Stage2Chapter.gd 行72-76 (staff_b.appear)、行86-89 (receptionist.appear)
# に保存をかけて、実際にファイルが書き換わるかを確認する。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveStage2.gd

func _check(cond: bool, msg: String):
	if cond:
		printerr("[S2] PASS: %s" % msg)
	else:
		printerr("[S2] FAIL: %s" % msg)

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _initialize():
	printerr("[S2] start")
	var gs = preload("res://game/GameState.gd").new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var src_file := "res://story/chapters/Stage2Chapter.gd"
	var snapshot := _read(src_file)

	# story_scene を立てる
	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()

	# 偽 rect: right_char を使う（receptionist.appear の bind 想定）
	var fake_rect: TextureRect = sc.right_char
	fake_rect.visible = true
	fake_rect.texture = ImageTexture.create_from_image(Image.create(100, 100, false, Image.FORMAT_RGBA8))

	# Case 1: 行72 staff_b.appear (portrait_scale + position 両方あり)
	sc.portrait_log.clear()
	sc.portrait_log.append({
		"rect": fake_rect,
		"side": "right",
		"texture": fake_rect.texture,
		"texture_path": "res://assets/characters/mob/staff_b/default/staff_b_default_001.png",
		"character_id": "staff_b",
		"scale": 0.5,
		"position": Vector2.ZERO,
		"flip_h": false,
		"background": null,
		"dialogue": {},
		"edit_source_id": "%s:72" % src_file,
	})
	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var right_card: PanelContainer = layout.find_child("StoryEditCard_Right", true, false)
	main_inst._bind_story_edit_card(right_card, sc, "right", fake_rect)
	var sl1: Dictionary = main_inst._get_edit_sliders(right_card)
	sl1.scale.value = 0.65
	sl1.x.value = 0
	sl1.y.value = 270
	await process_frame
	main_inst._save_story_edit_card(right_card, [], 0)
	for _w in range(3): await process_frame
	var info1: Label = right_card.find_child("InfoLabel", true, false)
	printerr("[S2] case1 (staff_b 72) info: %s" % info1.text)

	var after1 := _read(src_file)
	var has_scale1: bool = '"portrait_scale": 0.65' in after1
	var has_pos1: bool = '"position": [0, 270]' in after1
	printerr("[S2] case1 file scale 0.65 = %s, pos [0,270] = %s" % [has_scale1, has_pos1])
	# 元の値（0.5, [0, 50]）が残っていないか
	var had_old_scale1: bool = '"portrait_scale": 0.50' in after1 or '"portrait_scale": 0.5,' in after1
	var had_old_pos1: bool = '"position": [0, 50]' in after1
	printerr("[S2] case1 file STILL has old scale 0.5 = %s, old pos [0,50] = %s" % [had_old_scale1, had_old_pos1])
	_check(has_scale1, "case1 scale updated to 0.65")
	_check(has_pos1, "case1 position updated to [0, 270]")
	_check(not had_old_scale1, "case1 old scale removed")
	_check(not had_old_pos1, "case1 old position removed")

	# 元へ戻す
	_write(src_file, snapshot)

	# Case 2: 行86 receptionist.appear (portrait_scale あり、position なし)
	sc.portrait_log.clear()
	sc.portrait_log.append({
		"rect": fake_rect,
		"side": "right",
		"texture": fake_rect.texture,
		"texture_path": "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png",
		"character_id": "receptionist",
		"scale": 0.5,
		"position": Vector2.ZERO,
		"flip_h": false,
		"background": null,
		"dialogue": {},
		"edit_source_id": "%s:86" % src_file,
	})
	main_inst._bind_story_edit_card(right_card, sc, "right", fake_rect)
	var sl2: Dictionary = main_inst._get_edit_sliders(right_card)
	sl2.scale.value = 0.67
	sl2.x.value = 0
	sl2.y.value = 275
	await process_frame
	main_inst._save_story_edit_card(right_card, [], 0)
	for _w in range(3): await process_frame
	var info2: Label = right_card.find_child("InfoLabel", true, false)
	printerr("[S2] case2 (receptionist 86) info: %s" % info2.text)

	var after2 := _read(src_file)
	var has_scale2: bool = '"portrait_scale": 0.67' in after2
	var has_pos2: bool = '"position": [0, 275]' in after2
	printerr("[S2] case2 file scale 0.67 = %s, pos [0,275] = %s" % [has_scale2, has_pos2])
	_check(has_scale2, "case2 scale updated to 0.67")
	_check(has_pos2, "case2 position added [0, 275]")

	# 復元
	_write(src_file, snapshot)
	printerr("[S2] (file restored)")
	quit(0)
