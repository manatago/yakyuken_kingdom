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
	# 章はビルダー関数ごとにキャストを宣言する。ここでは 2 関数構成にして、
	# 別の関数で宣言されたキャラ (goren) が選べないことまで検証する。
	#   3-7 : build_a  -> sebas, fiona   (編集対象はここ)
	#   9-12: build_b  -> goren
	var src := "extends RefCounted\n"
	src += "\n"
	src += "func build_a(b):\n"
	src += "\tvar sebas = b.character(\"sebas\")\n"
	src += "\tvar fiona = b.character(\"fiona\")\n"
	src += "\tsebas.set_portrait(\"res://assets/characters/mob/sebas/default/sebas_default_001.png\", {\"scale\": 0.5, \"side\": \"right\", \"flip\": 0, \"position\": [0, 0]})\n"
	src += "\tsebas.band(\"よろしくお願いいたします。\")\n"
	src += "\n"
	src += "func build_b(b):\n"
	src += "\tvar goren = b.character(\"goren\")\n"
	src += "\tgoren.set_portrait(\"res://assets/characters/mob/goren/default/goren_default_001.png\", {\"scale\": 0.5, \"side\": \"right\", \"flip\": 0, \"position\": [0, 0]})\n"
	src += "\tgoren.band(\"うむ。\")\n"
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
	# 編集対象は build_a の中なので、build_b の goren は出てはいけない。
	# 出ると、選んだ瞬間に未宣言の識別子が書き込まれて章がパースエラーになる。
	_check(sel.item_count == 2, "同じ関数内の 2件だけが並ぶ (got %d)" % sel.item_count)
	var ids := []
	for i in range(sel.item_count):
		var md = sel.get_item_metadata(i)
		if md:
			ids.append(String(md.get("id", "")))
	_check(not ids.has("goren"), "別関数の goren は一覧に出ない (got %s)" % str(ids))
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

	# --- スコープ外のキャラを直接指定しても書き込まないこと ---
	# UI を経由しない呼び出し（将来の別経路や誤用）でも章を壊さない保険。
	main_inst._bind_story_edit_card(card, sc, "right", rect)
	var before_guard: String = "\n".join(_lines(SRC))
	var fake := OptionButton.new()
	fake.name = "PortraitCharSelector"
	fake.add_item("goren  (goren)")
	fake.set_item_metadata(0, {"var": "goren", "id": "goren"})
	var old_sel: OptionButton = card.find_child("PortraitCharSelector", true, false)
	if old_sel:
		old_sel.name = "PortraitCharSelector_disabled"
	card.get_node("VBox/PortraitCharRow").add_child(fake)
	main_inst._on_story_edit_card_change_char(card, layout)
	await process_frame
	_check("\n".join(_lines(SRC)) == before_guard, "スコープ外のキャラ指定ではソースを書き換えない")
	var info2: Label = card.find_child("InfoLabel", true, false)
	_check(info2 != null and info2.text.contains("宣言されていない"), "スコープ外を拒否した旨が表示される (got '%s')" % (info2.text if info2 else ""))

	# --- セリフ側のキャラ一覧も関数スコープに限定されていること ---
	# 立ち絵と同じ穴が「話者変更」「下に追加」に残っていた回帰を防ぐ。
	var dlg_sel := OptionButton.new()
	main_inst._story_edit_entries = [show_cmd, band_cmd]
	main_inst._story_edit_current_idx = 1
	main_inst._populate_dialogue_char_selector(dlg_sel, band_cmd, main_inst._story_edit_entries)
	var dlg_ids := []
	for i in range(dlg_sel.item_count):
		var md2 = dlg_sel.get_item_metadata(i)
		if md2 and String(md2.get("kind", "")) == "char":
			dlg_ids.append(String(md2.get("id", "")))
	_check(not dlg_ids.has("goren"), "セリフ側にも別関数の goren が出ない (got %s)" % str(dlg_ids))
	_check(dlg_ids.size() == 2, "セリフ側もスコープ内の2件だけ (got %d)" % dlg_ids.size())
	dlg_sel.free()

	# --- ビルダー引数名が bt の章（バトル章）でもキャストを拾えること ---
	# story 章は b.character、battle 章は bt.character。b 決め打ちだと
	# バトル章でスコープ判定が常に空になり、ガードが正当な変更まで拒否する。
	var bt_src := PackedStringArray([
		"extends RefCounted",
		"",
		"func belka_outfit_3(bt):",
		"\tvar belka = bt.character(\"belka\")",
		"\tbelka.band(\"くそっ\")",
	])
	var bt_path := "res://tests/_tmp_bt_scope.gd"
	_write(bt_path, "\n".join(bt_src))
	var bt_lines := _lines(bt_path)
	var bt_scope: Array = main_inst._chapter_characters_in_scope(bt_lines, 5)
	var bt_ids := []
	for e in bt_scope:
		bt_ids.append(String(e.get("id", "")))
	_check(bt_ids.has("belka"), "bt.character 記法のキャストを拾える (got %s)" % str(bt_ids))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bt_path))

	# --- 実在の全章で、キャストを宣言している関数のスコープが空にならないこと ---
	# 1ファイルだけ見て「> 0」を確認する形だと、たまたま動く章を選んでしまい
	# 他章の取りこぼし（定数でIDを渡している等）を見逃す。全章を回して、
	# 宣言行を含む関数が必ず1件以上返すことを固定する。
	var dirs := ["res://story/chapters", "res://battle/chapters"]
	var checked := 0
	var misses := []
	for d in dirs:
		var da := DirAccess.open(d)
		if not da:
			continue
		for fname in da.get_files():
			if not fname.ends_with(".gd"):
				continue
			var fl := _lines(d + "/" + fname)
			for i in range(fl.size()):
				if not fl[i].contains(".character("):
					continue
				if fl[i].strip_edges().begins_with("#"):
					continue
				if not fl[i].strip_edges().begins_with("var "):
					continue
				checked += 1
				# 宣言行の「次の行」で問い合わせる（宣言位置より前だけが有効なため）
				var scope_here: Array = main_inst._chapter_characters_in_scope(fl, i + 2)
				# その行で宣言した var 自身が返ること（先頭1件だけ返す実装を弾く）
				var declared := fl[i].strip_edges().split(" ")[1]
				var found := false
				for e in scope_here:
					if String(e.get("var", "")) == declared:
						found = true
						break
				if not found:
					misses.append("%s:%d %s" % [fname, i + 1, fl[i].strip_edges()])
	_check(checked > 100, "全章のキャスト宣言を検査した (%d件)" % checked)
	_check(misses.is_empty(), "全ての宣言でスコープが取れる (取れない %d件) 例: %s" % [misses.size(), misses[0] if misses.size() > 0 else ""])

	# --- 定数で渡されたキャラ ID が実際に解決されること ---
	# 「スコープが空でない」だけ見ると、id が空のまま返る実装でも通ってしまう。
	# 実在の const 宣言を使って、値まで解決できることを固定する。
	var mg := _lines("res://battle/chapters/Subevent3MinigameChapter.gd")
	var const_line := -1
	for i in range(mg.size()):
		if mg[i].contains(".character(FIONA_ID)"):
			const_line = i + 1
			break
	_check(const_line > 0, "定数渡しのキャスト宣言が見つかる (行%d)" % const_line)
	if const_line > 0:
		var resolved := ""
		for e in main_inst._chapter_characters_in_scope(mg, const_line + 1):
			if String(e.get("var", "")).contains("fiona"):
				resolved = String(e.get("id", ""))
				break
		_check(resolved == "fiona_armor", "const FIONA_ID が \"fiona_armor\" に解決される (got '%s')" % resolved)

	# --- 編集地点より後ろの宣言はスコープに入れないこと ---
	# GDScript は宣言前の使用を拒否するので、後ろの宣言を数えるとガードを
	# 通過したのにパースエラーになる書き込みが作れてしまう。
	var late := PackedStringArray([
		"extends RefCounted",                       # 1
		"",                                         # 2
		"func build_c(b):",                         # 3
		"\tvar early = b.character(\"early\")",     # 4
		"\tearly.band(\"ここが編集地点\")",          # 5
		"\tvar late_cast = b.character(\"late\")",  # 6
		"\tlate_cast.band(\"あと\")",               # 7
	])
	var at5: Array = main_inst._chapter_characters_in_scope(late, 5)
	var at5_ids := []
	for e in at5:
		at5_ids.append(String(e.get("id", "")))
	_check(at5_ids.has("early"), "編集地点より前の宣言は使える (got %s)" % str(at5_ids))
	_check(not at5_ids.has("late"), "編集地点より後ろの宣言は使わない (got %s)" % str(at5_ids))
	_check(main_inst._story_edit_var_in_scope(late, 5, "late_cast") == false, "後方宣言の var をスコープ内と誤判定しない")

	# --- ビルダー引数名を関数シグネチャから取れること ---
	# ナレーター行は「キャストではなくビルダー自体」を書くので、b 決め打ちだと
	# bt 章へ b.narrator_band(...) を書いて未宣言識別子になる。
	_check(main_inst._chapter_builder_name(late, 5) == "b", "b 章のビルダー名が b")
	var btf := PackedStringArray(["extends RefCounted", "", "func belka_outfit_3(bt):", "\tvar belka = bt.character(\"belka\")", "\tbelka.band(\"x\")"])
	_check(main_inst._chapter_builder_name(btf, 5) == "bt", "bt 章のビルダー名が bt (got '%s')" % main_inst._chapter_builder_name(btf, 5))
	var real_bt := _lines("res://battle/chapters/BelkaBattleChapter.gd")
	var bt_line := -1
	for i in range(real_bt.size()):
		if real_bt[i].contains("bt.character("):
			bt_line = i + 2
			break
	_check(bt_line > 0 and main_inst._chapter_builder_name(real_bt, bt_line) == "bt", "実在のバトル章でも bt を取れる")

	# --- 別ブロックで宣言された var はスコープ外 ---
	# GDScript の var は関数ではなくインデントブロックのスコープ。
	#   if 節で宣言 → else 節では未宣言（パースエラー）
	# 関数単位で見ていると、この宣言を「自分より前にある」として通してしまう。
	var blk := PackedStringArray([
		"extends RefCounted",                        # 1
		"",                                          # 2
		"func _apply_choice(bt, idx):",              # 3
		"\tvar outer = bt.character(\"outer\")",     # 4
		"\tif idx > 0:",                             # 5
		"\t\tvar inner = bt.character(\"inner\")",   # 6
		"\t\tinner.band(\"A\")",                     # 7
		"\telse:",                                   # 8
		"\t\touter.band(\"B\")",                     # 9
	])
	var at9: Array = main_inst._chapter_characters_in_scope(blk, 9)
	var at9_ids := []
	for e in at9:
		at9_ids.append(String(e.get("id", "")))
	_check(at9_ids.has("outer"), "外側ブロックの宣言は使える (got %s)" % str(at9_ids))
	_check(not at9_ids.has("inner"), "別ブロック(if節)の宣言は使わない (got %s)" % str(at9_ids))
	_check(main_inst._story_edit_var_in_scope(blk, 9, "inner") == false, "別ブロックの var をスコープ内と誤判定しない")
	# 同じブロック内なら見える
	_check(main_inst._story_edit_var_in_scope(blk, 7, "inner"), "同じブロック内の宣言は見える")

	# --- ビルダー名が判別できない場合は "b" を勝手に使わないこと ---
	# 既定を "b" にすると、ナレーター前置も "b" で作るためガードが自己承認する。
	var nofunc := PackedStringArray(["extends RefCounted", "\tsome.band(\"x\")"])
	_check(main_inst._chapter_builder_name(nofunc, 2) == "", "シグネチャ不明時は空を返す (got '%s')" % main_inst._chapter_builder_name(nofunc, 2))

	# --- 呼び出し側の検証: bt 章でナレーターに変えると bt.narrator_band が書かれる ---
	# ヘルパ (_chapter_builder_name) が正しくても、呼び出し側が "b" のままなら
	# bt 章へ b.narrator_band(...) を書いて未宣言識別子になる。call site を直接叩く。
	var BT_SRC := "res://tests/_tmp_bt_narrator.gd"
	_write(BT_SRC, "\n".join(PackedStringArray([
		"extends RefCounted",
		"",
		"func belka_outfit_3(bt):",
		"\tvar belka = bt.character(\"belka\")",
		"\tbelka.band(\"ここを変える\")",
	])))
	var bt_band := StoryCommands.Band.new()
	bt_band.speaker_id = "belka"
	bt_band.text = "ここを変える"
	bt_band.edit_source_id = "%s:%d" % [BT_SRC, 5]
	main_inst._story_edit_entries = [bt_band]
	main_inst._story_edit_current_idx = 0
	var nsel: OptionButton = layout.find_child("DialogueCharSelector", true, false)
	if nsel:
		nsel.clear()
		nsel.add_item("ナレーター")
		nsel.set_item_metadata(0, {"kind": "narrator"})
		nsel.select(0)
		main_inst._story_edit_change_current_speaker(layout)
		await process_frame
		var after_bt := _lines(BT_SRC)
		var l5: String = after_bt[4] if after_bt.size() >= 5 else ""
		_check(l5.contains("bt.narrator_band("), "bt 章には bt.narrator_band が書かれる (got %s)" % l5.strip_edges())
		_check(not l5.contains("b.narrator_band(") or l5.contains("bt.narrator_band("), "b. を書いていない")
	else:
		_check(false, "DialogueCharSelector が見つからない")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BT_SRC))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BT_SRC + ".bak"))

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SRC))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SRC + ".bak"))
	printerr("[CHAR] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
