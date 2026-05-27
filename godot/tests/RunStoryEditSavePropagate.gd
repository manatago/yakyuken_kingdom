extends SceneTree
# ストーリー編集の保存で「同じ画像の他の箇所も同じ設定に揃う」波及機能の検証。
# ST1 の satoshi_isekai_012 は 2 箇所（appear と set_portrait）。片方を編集保存したら
# 両方が同じ scale/position になることを実ファイル書き込みで確認する。
# 対象ファイルはバックアップ→復元。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSavePropagate.gd

const GameStateScript := preload("res://game/GameState.gd")
const SRC := "res://story/chapters/Stage1Chapter.gd"
const IMG := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_012.png"

func _check(c, m):
	printerr("[PROP] %s: %s" % [("PASS" if c else "FAIL"), m])
	return c

func _read(p) -> String:
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p, c):
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _initialize():
	printerr("[PROP] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var snapshot := _read(SRC)
	var lines := snapshot.split("\n")
	# satoshi_012 の set_portrait 行（1始まり）を探す
	var sp_line := -1
	for i in range(lines.size()):
		if "set_portrait(" in lines[i] and IMG in lines[i] and not lines[i].strip_edges().begins_with("#"):
			sp_line = i + 1
			break
	if sp_line < 0:
		_check(false, "satoshi_012 の set_portrait 行が見つからない"); quit(1); return
	printerr("[PROP] satoshi_012 set_portrait = 行%d" % sp_line)

	# story_scene を立て、その行を指す portrait_log エントリを注入
	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()
	var fake_rect: TextureRect = sc.right_char
	fake_rect.visible = true
	fake_rect.texture = ImageTexture.create_from_image(Image.create(100, 100, false, Image.FORMAT_RGBA8))
	sc.portrait_log.append({
		"rect": fake_rect, "side": "right", "texture": fake_rect.texture,
		"texture_path": IMG, "character_id": "main",
		"scale": 0.5, "position": Vector2.ZERO, "flip_h": false,
		"background": null, "dialogue": {}, "edit_source_id": "%s:%d" % [SRC, sp_line],
	})

	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var card: PanelContainer = layout.find_child("StoryEditCard_Right", true, false)
	main_inst._bind_story_edit_card(card, sc, "right", fake_rect)
	var sl: Dictionary = main_inst._get_edit_sliders(card)
	sl.scale.value = 0.6
	sl.x.value = 5
	sl.y.value = 5
	await process_frame

	main_inst._save_story_edit_card(card, [], 0)
	for _w in range(4): await process_frame
	var info: Label = card.find_child("InfoLabel", true, false)
	printerr("[PROP] InfoLabel = %s" % info.text)

	var after := _read(SRC)
	# 復元（以降の判定は after を使う）
	_write(SRC, snapshot)
	printerr("[PROP] (file restored)")

	var ok := true
	ok = _check(info.text.begins_with("[保存]"), "保存成功 (got '%s')" % info.text) and ok
	# satoshi_012 は2箇所 → 片方編集で 1 箇所へ波及
	ok = _check("+1箇所" in info.text, "他1箇所へ波及した表示 (got '%s')" % info.text) and ok
	# 2箇所とも position [5, 5] になっている（他の行に [5,5] は無い想定）
	var cnt_pos := after.count('"position": [5, 5]')
	ok = _check(cnt_pos == 2, "position [5, 5] がちょうど2箇所 (got %d)" % cnt_pos) and ok
	# set_portrait 側は "scale": 0.60、appear 側は "portrait_scale": 0.60
	ok = _check('"scale": 0.60' in after, "set_portrait 側が scale 0.60") and ok
	ok = _check('"portrait_scale": 0.60' in after, "appear 側が portrait_scale 0.60") and ok
	# 別画像(satoshi_018)が巻き込まれていない（元の portrait_scale 0.5 のまま）
	var other_ok := ("satoshi_isekai_018.png" in after) and ('"position": [5, 5]' not in _line_with(after, "satoshi_isekai_018.png"))
	ok = _check(other_ok, "別画像 satoshi_018 は波及していない") and ok

	if ok:
		printerr("[PROP] OK — 保存で同一画像の全箇所が揃った（波及）")
		quit(0)
	else:
		printerr("[PROP] FAIL")
		quit(1)

func _line_with(text: String, needle: String) -> String:
	for ln in text.split("\n"):
		if needle in ln:
			return ln
	return ""
