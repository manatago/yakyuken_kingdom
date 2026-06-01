extends SceneTree
# ストーリー編集の保存で「bound_rect の現在テクスチャ」と「portrait_log の最後の
# 同 rect エントリの texture_path」が食い違う場合、保存を拒否することを検証する。
# Subevent1 等で band(side=...) が rect の見た目だけ変える/portrait_log に書かない
# パターンで、別画像の行を誤って書き換える事故を防ぐためのガード。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveTextureMismatch.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0
func _check(c, m):
	if c:
		printerr("[MISM] PASS: %s" % m)
	else:
		printerr("[MISM] FAIL: %s" % m)
		_fails += 1

func _read(p) -> String:
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _initialize():
	printerr("[MISM] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# 任意の章ソースを用意（実ファイルへの書き込みは起きない想定）
	var src := "res://story/chapters/Subevent1Chapter.gd"
	var snapshot := _read(src)
	var snap_len := snapshot.length()

	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()

	# 「履歴上は サトシ on left_char」状態を作る（band で pisuke が後から上書きされた想定）
	var left_rect: TextureRect = sc.left_char
	left_rect.visible = true
	# 視覚（bound_rect.texture）= pisuke 風（別テクスチャ）
	var visual_tex := ImageTexture.create_from_image(Image.create(50, 50, false, Image.FORMAT_RGBA8))
	visual_tex.resource_path = "res://assets/characters/main/pisuke/default/pisuke_default_001.png"
	left_rect.texture = visual_tex
	# portrait_log の最後の left_char エントリ = サトシ画像（テクスチャは別物）
	var logged_tex := ImageTexture.create_from_image(Image.create(60, 60, false, Image.FORMAT_RGBA8))
	logged_tex.resource_path = "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png"
	sc.portrait_log.append({
		"rect": left_rect, "side": "left", "texture": logged_tex,
		"texture_path": "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png",
		"character_id": "main", "scale": 0.5, "position": Vector2(0, 70),
		"flip_h": false, "background": null, "dialogue": {},
		"edit_source_id": "%s:33" % src,  # 適当な行（実際に書き換わってはいけない）
	})

	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var card: PanelContainer = layout.find_child("StoryEditCard_Left", true, false)
	main_inst._bind_story_edit_card(card, sc, "left", left_rect)
	var sl: Dictionary = main_inst._get_edit_sliders(card)
	sl.scale.value = 0.99   # 危険な値（こんな値が満たされたら異常）
	sl.x.value = 999
	sl.y.value = 999
	await process_frame

	main_inst._save_story_edit_card(card, [], 0)
	for _w in range(4): await process_frame
	var info: Label = card.find_child("InfoLabel", true, false)
	var msg: String = info.text if info else ""
	printerr("[MISM] InfoLabel = '%s'" % msg)

	# 期待: 保存NG（表示中の画像と履歴が食い違う）
	_check(msg.begins_with("[保存NG]"), "視覚/履歴ミスマッチで保存が拒否された")
	_check("食い違う" in msg or "履歴" in msg, "NG 理由が画像ミスマッチを示している")

	# 期待: 元ファイルが変わっていない（NG なので書き込みされていない筈）
	var after := _read(src)
	_check(after.length() == snap_len, "対象ファイルが書き換わっていない")
	# サトシ 行に危険な値が入っていないこと（具体的に 0.99 / 999 が無いこと）
	_check(not ('"scale": 0.99' in after), "ファイルに 0.99 が混入していない")
	_check(not ('"position": [999, 999]' in after), "ファイルに [999, 999] が混入していない")

	printerr("[MISM] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
