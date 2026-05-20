extends SceneTree
# 「extra dict なしの set_portrait("path")」呼び出しに対して、保存時に scale/position
# が追加されるかを実保存経路で確認する。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveBareCall.gd

func _check(cond: bool, msg: String):
	if cond:
		printerr("[BC] PASS: %s" % msg)
	else:
		printerr("[BC] FAIL: %s" % msg)

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _initialize():
	printerr("[BC] start")
	var gs = preload("res://game/GameState.gd").new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# 1. テスト用ファイルを作る（dummy chapter）
	var test_res_path := "res://tests/_tmp_bare_call.gd"
	var initial: String = "func dummy():\n"
	initial += "\thero.set_portrait(\"res://path.png\")\n"  # line 2
	initial += "\tend\n"
	_write(test_res_path, initial)

	# 2. 偽の portrait_log エントリを用意（rect/edit_source_id 付き）
	# story_scene_instance を立てる
	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()

	# 偽 rect を用意（sc の left_char を再利用）
	var fake_rect: TextureRect = sc.left_char
	fake_rect.visible = true
	fake_rect.texture = ImageTexture.create_from_image(Image.create(100, 100, false, Image.FORMAT_RGBA8))

	sc.portrait_log.append({
		"rect": fake_rect,
		"side": "left",
		"texture": fake_rect.texture,
		"texture_path": "res://path.png",
		"character_id": "hero",
		"scale": 1.0,
		"position": Vector2.ZERO,
		"flip_h": false,
		"background": null,
		"dialogue": {},
		"edit_source_id": "%s:2" % test_res_path,
	})

	# 3. カードを作って bind
	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var left_card: PanelContainer = layout.find_child("StoryEditCard_Left", true, false)
	main_inst._bind_story_edit_card(left_card, sc, "left", fake_rect)
	_check(left_card.visible, "card visible after bind")

	# 4. スライダーを設定して保存
	var sl: Dictionary = main_inst._get_edit_sliders(left_card)
	sl.scale.value = 0.77
	sl.x.value = 88
	sl.y.value = -99
	await process_frame
	main_inst._save_story_edit_card(left_card, [], 0)
	for _w in range(3): await process_frame
	var info: Label = left_card.find_child("InfoLabel", true, false)
	printerr("[BC] InfoLabel: %s" % info.text)
	_check(info.text.begins_with("[保存]"), "save reported success")

	# 5. ファイルが追記/書換されたか
	var after := _read(test_res_path)
	printerr("[BC] file after save:\n%s" % after)
	_check('"scale": 0.77' in after, "file has scale 0.77")
	_check('"position": [88, -99]' in after, "file has position [88, -99]")

	# cleanup
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_res_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_res_path) + ".uid")
	printerr("[BC] done")
	quit(0)
