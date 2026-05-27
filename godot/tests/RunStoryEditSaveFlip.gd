extends SceneTree
# ストーリー編集の反転（flip_h）機能の検証:
# - 反転ボタン相当のトグルで bound_rect.flip_h が即変わる（プレビュー）。
# - 保存で対象行の "flip" 値が書き換わる。
# - InfoLabel に「反転ON/OFF」が出る。
# - last_entry.flip_h が更新される（◀/▶ 再生整合）。
# 対象ファイルはバックアップ→復元。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveFlip.gd

const GameStateScript := preload("res://game/GameState.gd")
const SRC := "res://story/chapters/Subevent1Chapter.gd"
const IMG := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png"

var _fails: int = 0
func _check(c, m):
	if c:
		printerr("[FLIP] PASS: %s" % m)
	else:
		printerr("[FLIP] FAIL: %s" % m)
		_fails += 1

func _read(p) -> String:
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p, c):
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _initialize():
	printerr("[FLIP] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var snapshot := _read(SRC)
	var lines := snapshot.split("\n")
	var sp_line := -1
	for i in range(lines.size()):
		if "set_portrait(" in lines[i] and IMG in lines[i] and not lines[i].strip_edges().begins_with("#"):
			sp_line = i + 1
			break
	_check(sp_line > 0, "対象行を発見 (行%d)" % sp_line)
	if sp_line <= 0:
		quit(1); return
	# 元の flip 値を確認（"flip": N が含まれているはず）
	var orig_line := lines[sp_line - 1]
	var orig_flip_one: bool = '"flip": 1' in orig_line
	printerr("[FLIP] 元の行: %s" % orig_line.strip_edges())
	printerr("[FLIP] 元の flip = %s" % ("1" if orig_flip_one else "0 or なし"))

	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()
	var rect: TextureRect = sc.left_char
	rect.visible = true
	var tex := ImageTexture.create_from_image(Image.create(50, 50, false, Image.FORMAT_RGBA8))
	tex.resource_path = IMG
	rect.texture = tex
	rect.flip_h = orig_flip_one  # 履歴の元 flip と一致させる
	sc.portrait_log.append({
		"rect": rect, "side": "left", "texture": tex,
		"texture_path": IMG, "character_id": "main",
		"scale": 0.71, "position": Vector2(0, 70), "flip_h": orig_flip_one,
		"background": null, "dialogue": {},
		"edit_source_id": "%s:%d" % [SRC, sp_line],
	})

	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var card: PanelContainer = layout.find_child("StoryEditCard_Left", true, false)
	main_inst._bind_story_edit_card(card, sc, "left", rect)

	# 反転トグル
	main_inst._on_story_edit_card_flip(card)
	var new_flip: bool = rect.flip_h
	_check(new_flip == (not orig_flip_one), "トグルで rect.flip_h が反転した (%s → %s)" % [orig_flip_one, new_flip])

	# 保存
	main_inst._save_story_edit_card(card, [], 0)
	for _w in range(4): await process_frame
	var info: Label = card.find_child("InfoLabel", true, false)
	var msg: String = info.text if info else ""
	printerr("[FLIP] InfoLabel = '%s'" % msg)

	_check(msg.begins_with("[保存]"), "保存成功 (got '%s')" % msg)
	var expected_note: String = "反転%s" % ("ON" if new_flip else "OFF")
	_check(expected_note in msg, "InfoLabel に「%s」表示" % expected_note)

	# ファイル検証
	var after := _read(SRC)
	var after_lines := after.split("\n")
	var after_target: String = after_lines[sp_line - 1]
	_write(SRC, snapshot)
	printerr("[FLIP] (file restored)")
	printerr("[FLIP] 保存後の行: %s" % after_target.strip_edges())

	var expected_flip_str: String = '"flip": %d' % (1 if new_flip else 0)
	_check(expected_flip_str in after_target, "行%d に '%s' が書き込まれた" % [sp_line, expected_flip_str])
	# 反対値が消えていること（重複が無いこと）
	var opposite_flip_str: String = '"flip": %d' % (0 if new_flip else 1)
	_check(not (opposite_flip_str in after_target), "行%d に反対値 '%s' が残っていない" % [sp_line, opposite_flip_str])

	# in-memory: last_entry.flip_h が更新されているか
	_check(sc.portrait_log[0].get("flip_h") == new_flip, "last_entry.flip_h が新値に更新")

	printerr("[FLIP] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
