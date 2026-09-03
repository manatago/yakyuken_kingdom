extends SceneTree
# ドラッグ&ドロップで set_portrait を挿入したとき、挿入したコマンド自身の
# edit_source_id が実際の挿入行を指し続けることを検証する。
#
# 回帰対象のバグ:
#   _story_edit_insert_new_portrait_before が entries.insert を
#   _story_edit_shift_source_ids より先に呼んでいたため、挿入行 (line_no) を
#   占める new_show 自身までシフト対象 (ln >= from_line) に入り、+1 された。
#   結果、以後そのコマンドは 1 行下（＝元のセリフ行）を指し続ける:
#     - 反転/保存が set_portrait ではない行を掴んで [NG] block になる
#     - 挿入を重ねるとズレが累積し、複数コマンドの edit_source_id が衝突して
#       portrait_log の重複排除に飲まれ、ページ送りで差し替えが消える
#
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditInsertSourceId.gd

const SRC := "res://tests/_tmp_insert_srcid.gd"

var _fails := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		printerr("[ISID] PASS: %s" % msg)
	else:
		_fails += 1
		printerr("[ISID] FAIL: %s" % msg)

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _lines(path: String) -> PackedStringArray:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return PackedStringArray()
	var t := f.get_as_text()
	f.close()
	return t.split("\n")

func _line_at(sid: String) -> String:
	var c: int = sid.rfind(":")
	var ln: int = int(sid.substr(c + 1))
	var ls := _lines(sid.substr(0, c))
	if ln <= 0 or ln > ls.size():
		return "<範囲外:%d>" % ln
	return ls[ln - 1]

func _sid_line(cmd) -> int:
	var sid: String = cmd.edit_source_id
	return int(sid.substr(sid.rfind(":") + 1))

func _show(char_id: String, path: String, line_no: int):
	var c := StoryCommands.ShowCharacter.new()
	c.character_id = char_id
	c.portrait_id = path
	c.side_override = "right"
	c.portrait_scale = 0.5
	c.edit_source_id = "%s:%d" % [SRC, line_no]
	return c

func _band(text: String, line_no: int):
	var c := StoryCommands.Band.new()
	c.speaker_id = "sebas"
	c.text = text
	c.edit_source_id = "%s:%d" % [SRC, line_no]
	return c

func _initialize() -> void:
	printerr("[ISID] start")
	var gs = preload("res://game/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	# 行番号が読みやすいよう、章ソースを固定内容で作る。
	#   5: set_portrait A / 6: band one / 7: set_portrait B / 8: band two
	var src := "extends RefCounted\n"                                       # 1
	src += "\n"                                                             # 2
	src += "func build(b):\n"                                               # 3
	src += "\tvar sebas = b.character(\"sebas\")\n"                         # 4
	src += "\tsebas.set_portrait(\"res://tests/_isid_a.png\", {\"scale\": 0.5, \"side\": \"right\", \"flip\": 0, \"position\": [0, 0]})\n"   # 5
	src += "\tsebas.band(\"one\")\n"                                        # 6
	src += "\tsebas.set_portrait(\"res://tests/_isid_b.png\", {\"scale\": 0.6, \"side\": \"right\", \"flip\": 0, \"position\": [1, 1]})\n"   # 7
	src += "\tsebas.band(\"two\")\n"                                        # 8
	_write(SRC, src)

	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	# last_story_edit.cfg を触らせない（実プレイの再開位置を壊さないため）
	main_inst._story_edit_current_seq_idx = -1

	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()
	var rect: TextureRect = sc.right_char
	rect.visible = true
	var tex := ImageTexture.create_from_image(Image.create(50, 50, false, Image.FORMAT_RGBA8))
	rect.texture = tex
	sc.portrait_log.append({
		"rect": rect, "side": "right", "texture": tex,
		"texture_path": "res://tests/_isid_a.png", "character_id": "sebas",
		"scale": 0.5, "position": Vector2(0, 0), "flip_h": false,
		"background": null, "dialogue": {},
		"edit_source_id": "%s:%d" % [SRC, 5],
	})

	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var card: PanelContainer = layout.find_child("StoryEditCard_Right", true, false)
	main_inst._bind_story_edit_card(card, sc, "right", rect)
	var info := Label.new()

	main_inst._story_edit_entries = [
		_show("sebas", "res://tests/_isid_a.png", 5),
		_band("one", 6),
		_show("sebas", "res://tests/_isid_b.png", 7),
		_band("two", 8),
	]
	main_inst._story_edit_current_idx = 1  # band "one"

	# --- 1回目の挿入: band "one"(6行) の直前 ---
	var ok1: bool = main_inst._story_edit_insert_new_portrait_before(
		card, main_inst._story_edit_entries[1], "res://tests/_isid_c.png", info)
	_check(ok1, "1回目の挿入が成功する")
	var e: Array = main_inst._story_edit_entries
	_check(e.size() == 5, "entries が 1 件増える (got %d)" % e.size())
	_check(_sid_line(e[0]) == 5, "既存 set_portrait A は 5 行のまま (got %d)" % _sid_line(e[0]))
	_check(_sid_line(e[1]) == 6, "★挿入した set_portrait が挿入行 6 を指す (got %d)" % _sid_line(e[1]))
	_check(_sid_line(e[2]) == 7, "band one が 7 行へずれる (got %d)" % _sid_line(e[2]))
	_check(_sid_line(e[3]) == 8, "set_portrait B が 8 行へずれる (got %d)" % _sid_line(e[3]))
	_check(_sid_line(e[4]) == 9, "band two が 9 行へずれる (got %d)" % _sid_line(e[4]))
	_check(main_inst._story_edit_current_idx == 2, "current_idx が band one を指し続ける (got %d)" % main_inst._story_edit_current_idx)

	# --- 2回目の挿入: ズレが累積しないこと（セバスで実際に起きたケース）---
	var ok2: bool = main_inst._story_edit_insert_new_portrait_before(
		card, main_inst._story_edit_entries[2], "res://tests/_isid_d.png", info)
	_check(ok2, "2回目の挿入が成功する")
	e = main_inst._story_edit_entries
	_check(e.size() == 6, "entries がさらに 1 件増える (got %d)" % e.size())

	# 各 ShowCharacter の edit_source_id が、自分の画像パスを含む行を指していること。
	# これが崩れると保存/反転が別の行を書き換える。
	for cmd in e:
		if not (cmd is StoryCommands.ShowCharacter):
			continue
		var line: String = _line_at(cmd.edit_source_id)
		_check(line.contains(cmd.portrait_id),
			"%s の edit_source_id(%d行) が自分の set_portrait を指す / 実際の行: %s"
				% [cmd.portrait_id.get_file(), _sid_line(cmd), line.strip_edges()])

	# edit_source_id の重複が無いこと。
	# 重複すると portrait_log の重複排除に飲まれ、ページ送りで差し替えが消える。
	var seen := {}
	var dup := ""
	for cmd in e:
		var sid: String = cmd.edit_source_id
		if seen.has(sid):
			dup = sid
			break
		seen[sid] = true
	_check(dup.is_empty(), "edit_source_id が衝突しない (dup=%s)" % dup)

	# 後片付け
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SRC))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SRC + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SRC + ".tmp"))

	printerr("[ISID] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
