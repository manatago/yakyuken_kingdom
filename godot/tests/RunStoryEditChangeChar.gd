extends SceneTree
# 立ち絵のキャラ差し替え（セバス → フィオナ）の検証。
#
# set_portrait の呼び出し元変数と画像パスを同時に書き換える必要がある。
# 変数だけ変えると別キャラの画像を指したままになり、パスだけ変えると
# character_id が古いままで side 解決や portrait_log が食い違う。
#
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditChangeChar.gd

const SRC := "res://tests/_tmp_change_char.gd"

var _fails := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		printerr("[CHAR] PASS: %s" % msg)
	else:
		_fails += 1
		printerr("[CHAR] FAIL: %s" % msg)

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

func _initialize() -> void:
	printerr("[CHAR] start")
	var gs = preload("res://game/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	# 4: var sebas / 5: var fiona / 6: sebas.set_portrait / 7: sebas.band
	var src := "extends RefCounted\n"
	src += "\n"
	src += "func build(b):\n"
	src += "\tvar sebas = b.character(\"sebas\")\n"
	src += "\tvar fiona = b.character(\"fiona\")\n"
	src += "\tsebas.set_portrait(\"res://assets/characters/mob/sebas/default/sebas_default_001.png\", {\"scale\": 0.5, \"side\": \"right\", \"flip\": 0, \"position\": [0, 0]})\n"
	src += "\tsebas.band(\"よろしくお願いいたします。\")\n"
	_write(SRC, src)

	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame
	main_inst._story_edit_current_seq_idx = -1

	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()
	var rect: TextureRect = sc.right_char
	rect.visible = true
	var tex := ImageTexture.create_from_image(Image.create(40, 80, false, Image.FORMAT_RGBA8))
	rect.texture = tex
	sc.portrait_log.append({
		"rect": rect, "side": "right", "texture": tex,
		"texture_path": "res://assets/characters/mob/sebas/default/sebas_default_001.png",
		"character_id": "sebas", "scale": 0.5, "position": Vector2.ZERO, "flip_h": false,
		"background": null, "dialogue": {}, "edit_source_id": "%s:%d" % [SRC, 6],
	})

	var show_cmd := StoryCommands.ShowCharacter.new()
	show_cmd.character_id = "sebas"
	show_cmd.portrait_id = "res://assets/characters/mob/sebas/default/sebas_default_001.png"
	show_cmd.side_override = "right"
	show_cmd.edit_source_id = "%s:%d" % [SRC, 6]
	var band_cmd := StoryCommands.Band.new()
	band_cmd.speaker_id = "sebas"
	band_cmd.text = "よろしくお願いいたします。"
	band_cmd.edit_source_id = "%s:%d" % [SRC, 7]
	main_inst._story_edit_entries = [show_cmd, band_cmd]
	main_inst._story_edit_current_idx = 1

	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var card: PanelContainer = layout.find_child("StoryEditCard_Right", true, false)
	main_inst._bind_story_edit_card(card, sc, "right", rect)
	await process_frame

	# --- キャラ選択が章の宣言から作られ、現在のキャラが選ばれていること ---
	var sel: OptionButton = card.find_child("PortraitCharSelector", true, false)
	_check(sel != null, "PortraitCharSelector が存在する")
	if sel == null:
		quit(1)
		return
	_check(sel.item_count == 2, "章の b.character 宣言 2件が並ぶ (got %d)" % sel.item_count)
	var cur_meta = sel.get_selected_metadata()
	_check(cur_meta != null and cur_meta.get("id", "") == "sebas", "現在のキャラ sebas が初期選択される")

	# --- フィオナへ変更 ---
	var fiona_idx := -1
	for i in range(sel.item_count):
		var md = sel.get_item_metadata(i)
		if md and md.get("id", "") == "fiona":
			fiona_idx = i
	_check(fiona_idx >= 0, "一覧に fiona がある")
	sel.select(fiona_idx)
	main_inst._on_story_edit_card_change_char(card, layout)
	await process_frame

	var after := _lines(SRC)
	var line6: String = after[5] if after.size() >= 6 else ""
	printerr("[CHAR] 書き換え後: %s" % line6.strip_edges())
	_check(line6.contains("fiona.set_portrait("), "呼び出し元変数が fiona になる")
	_check(not line6.contains("sebas."), "sebas. が残っていない")
	_check(line6.contains("res://assets/characters/main/fiona/"), "画像がフィオナのフォルダを指す")
	_check(not line6.contains("sebas_default_001.png"), "旧画像パスが残っていない")
	# dict は保持されること（scale/side/flip/position を落とすと配置が壊れる）
	_check(line6.contains('"side": "right"') and line6.contains('"scale": 0.5'), "第2引数の dict がそのまま残る")
	_check(line6.contains('"position": [0, 0]'), "position も残る")

	# --- in-memory も追従 ---
	_check(show_cmd.character_id == "fiona", "in-memory の character_id が fiona (got %s)" % show_cmd.character_id)
	_check(show_cmd.portrait_id.contains("/fiona/"), "in-memory の portrait_id がフィオナの画像")

	# --- 同じキャラを選び直しても壊さない ---
	main_inst._bind_story_edit_card(card, sc, "right", rect)
	var before_repeat := _lines(SRC)
	main_inst._on_story_edit_card_change_char(card, layout)
	await process_frame
	var after_repeat := _lines(SRC)
	_check("\n".join(before_repeat) == "\n".join(after_repeat), "同一キャラへの変更はファイルを書き換えない")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SRC))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SRC + ".bak"))
	printerr("[CHAR] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
