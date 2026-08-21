extends SceneTree
# 紙芝居編集の end-to-end 検証。
# 実際の章ソースを退避したうえで SlideshowEditor を開き、セリフ更新・ページ追加・
# 移動・削除がソースへ正しく書き戻ることを確認して、最後に必ず元へ戻す。
#
# 実行: Godot --path godot --headless --script res://tests/RunSlideshowEdit.gd

const GameStateScript := preload("res://game/GameState.gd")
const TARGET := "res://battle/chapters/FionaBattleChapter.gd"

var _fails := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		printerr("[SLIDE] PASS: %s" % msg)
	else:
		_fails += 1
		printerr("[SLIDE] FAIL: %s" % msg)

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f:
		return ""
	var t := f.get_as_text()
	f.close()
	return t

func _write(p: String, c: String) -> void:
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f:
		f.store_string(c)
		f.close()

func _initialize() -> void:
	printerr("[SLIDE] start")
	var snapshot := _read(TARGET)
	if snapshot.is_empty():
		printerr("[SLIDE] FAIL: 章ソースを読めない")
		quit(1)
		return

	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame

	# 章一覧に紙芝居持ちだけが出ること
	var options: Array = main_inst._slideshow_chapter_options()
	_check(options.size() >= 5, "紙芝居を持つ章が一覧に出る (got %d)" % options.size())
	var has_fiona := false
	for o in options:
		if String(o.get("path", "")) == TARGET:
			has_fiona = true
			_check(o.get("slideshow_blocks", 0) == 3, "フィオナは3敗ぶん (got %s)" % str(o.get("slideshow_blocks")))
			_check(o.get("slideshow_pages", 0) == 22, "フィオナは全22ページ 4+5+13 (got %s)" % str(o.get("slideshow_pages")))
	_check(has_fiona, "フィオナ章が一覧にある")

	var editor = preload("res://game/SlideshowEditor.gd").new()
	editor.setup(TARGET)
	main_inst.add_child(editor)
	await process_frame
	await process_frame

	_check(editor._blocks.size() == 3, "エディタが3ブロック読み込む (got %d)" % editor._blocks.size())
	# 1敗目 = outfit_3 = 4ページ
	editor._block_idx = 0
	editor._page_idx = 0
	editor._refresh()
	await process_frame
	var b0: Dictionary = editor.current_block()
	_check(b0.get("loss_index", 0) == 1, "先頭ブロックが1敗目")
	_check((b0["pages"] as Array).size() == 4, "1敗目は4ページ (got %d)" % (b0["pages"] as Array).size())
	_check(editor._bg_rect.texture != null, "背景プレビューに画像が乗る")

	# --- レイアウト: 実際に画面を占めていること ---
	# texture が乗っていても size 0 なら何も見えない。add_child 後に
	# set_anchors_preset を呼ぶと offset が再計算されて 0x0 になる罠がある。
	var vp: Vector2 = main_inst.get_viewport_rect().size
	_check(editor.size.is_equal_approx(vp), "エディタがビューポート全面を占める (got %s / vp %s)" % [editor.size, vp])
	_check(editor._bg_rect.get_global_rect().size.is_equal_approx(vp), "背景プレビューが全面を占める (got %s)" % editor._bg_rect.get_global_rect().size)
	for spec in [["SlideNavBar", 0.05], ["BubblePreview", 0.5], ["SlideEditPanel", 0.5]]:
		var node: Control = editor.get_node_or_null(String(spec[0]))
		_check(node != null, "%s が存在する" % spec[0])
		if node:
			var r: Rect2 = node.get_global_rect()
			_check(r.size.x > vp.x * 0.15 and r.size.y > 20.0, "%s が潰れていない (%s)" % [spec[0], r.size])
			_check(r.position.y >= vp.y * float(spec[1]) - vp.y or r.position != Vector2.ZERO, "%s が原点に貼り付いていない (%s)" % [spec[0], r.position])
			_check(r.end.x <= vp.x + 1.0 and r.end.y <= vp.y + 1.0, "%s が画面外へはみ出さない (end=%s)" % [spec[0], r.end])

	# --- 吹き出しプレビューが実機と同じ位置に出ること ---
	# 表を二重に持つと「編集画面では合っているのに本番でズレる」ので、
	# 実機の BUBBLE_SIDE_ANCHORS からの計算値と一致することを見る。
	var table: Dictionary = preload("res://game/BattleScene.gd").BUBBLE_SIDE_ANCHORS
	var cur_side: String = str(editor.current_page()["bubbles"][0].get("side", ""))
	_check(table.has(cur_side), "章で使われている side が実機の表にある (%s)" % cur_side)
	var bp: Control = editor.get_node_or_null("BubblePreview")
	_check(bp != null, "BubblePreview が存在する")
	if bp and table.has(cur_side):
		var a: Dictionary = table[cur_side]
		var want := Rect2(vp.x * float(a["l"]), vp.y * float(a["t"]),
			vp.x * (float(a["r"]) - float(a["l"])), vp.y * (float(a["b"]) - float(a["t"])))
		var got: Rect2 = bp.get_global_rect()
		_check(got.position.distance_to(want.position) < 2.0 and got.size.distance_to(want.size) < 2.0,
			"吹き出しが実機と同じ位置・大きさ (got %s / want %s)" % [got, want])
		# 上下どちらのスロットかは章の内容次第なので、表の値と突き合わせて判定する
		# （「1枚目は必ず上部」と決め打ちすると、位置を変えた章で誤検出する）。
		var is_upper: bool = float(a["t"]) < 0.5
		_check((got.position.y < vp.y * 0.5) == is_upper,
			"%s のスロット位置が表と一致する (%s / y=%.0f)" % [cur_side, "上部" if is_upper else "下部", got.position.y])

	# --- 位置の変更がソースへ書き戻ること ---
	# 現在値と必ず異なる side を選ぶ（同一だと _on_change_side が書き込まない）。
	var other_side: String = "bottom-left" if cur_side != "bottom-left" else "center"
	var other_upper: bool = float(table[other_side]["t"]) < 0.5
	editor._on_change_side(other_side)
	await process_frame
	_check(_read(TARGET).contains('{"side": "%s"}' % other_side), "位置の変更がソースへ書き戻る (%s)" % other_side)
	_check(str(editor.current_page()["bubbles"][0].get("side", "")) == other_side, "読み直しで反映される")
	if bp:
		_check((bp.get_global_rect().position.y < vp.y * 0.5) == other_upper, "プレビューが %s の位置へ移動する" % other_side)
	editor._on_change_side(cur_side)
	await process_frame
	_check(str(editor.current_page()["bubbles"][0].get("side", "")) == cur_side, "元の side へ戻せる")

	# --- 文字サイズ変更と枠の自動フィット ---
	if bp:
		# 既定の "..." は最小高さに収まってしまい伸縮を確認できないので、
		# 先に長いセリフを入れてから文字サイズを上げる。
		editor._text_edit.text = "あのですね、ちょっとこれは長めのセリフでして、枠が文字量に合わせて伸びるかどうかを確かめるためのものです。"
		editor._on_apply_text()
		await process_frame
		await process_frame
		var h_before: float = bp.get_global_rect().size.y
		editor._on_change_font_size(64)
		await process_frame
		await process_frame
		_check(_read(TARGET).contains('"font_size": 64'), "文字サイズがソースへ書き戻る")
		_check(int(editor.current_page()["bubbles"][0].get("font_size", 0)) == 64, "読み直しで反映される")
		_check(editor._bubble_label.get_theme_font_size("font_size") == 64, "プレビューの文字も大きくなる")
		var h_after: float = bp.get_global_rect().size.y
		_check(h_after >= h_before, "枠が文字量に追従して縮まない (%.0f -> %.0f)" % [h_before, h_after])
		_check(h_after <= vp.y * float(preload("res://game/BattleScene.gd").BUBBLE_MAX_HEIGHT_RATIO) + 1.0,
			"枠が上限を超えない (%.0f)" % h_after)
		# 0 で既定へ戻す
		editor._on_change_font_size(0)
		await process_frame
		_check(not _read(TARGET).contains("font_size"), "0 指定で font_size ごと消える")
		_check(int(editor.current_page()["bubbles"][0].get("font_size", 0)) == 0, "既定へ戻る")

	# --- セリフ更新 ---
	var marker := "テスト用セリフ\"引用\"入り"
	editor._text_edit.text = marker
	editor._on_apply_text()
	await process_frame
	var body := _read(TARGET)
	_check(body.contains('bt.bubble("テスト用セリフ\\"引用\\"入り"'), "セリフがエスケープされて書き戻る")
	_check(editor.current_page()["bubbles"][0]["text"] == marker, "読み直しで元のテキストに戻る")

	# --- ページ追加 ---
	var before_pages: int = (editor.current_block()["pages"] as Array).size()
	editor._on_add_page()
	await process_frame
	_check((editor.current_block()["pages"] as Array).size() == before_pages + 1, "ページが1枚増える")
	_check(editor._page_idx == 1, "追加した次のページへ移動する (got %d)" % editor._page_idx)
	# 他ブロックが巻き添えを食っていないこと
	_check((editor._blocks[1]["pages"] as Array).size() == 5, "2敗目のページ数が変わらない")
	_check((editor._blocks[2]["pages"] as Array).size() == 13, "3敗目のページ数が変わらない")

	# --- 移動 ---
	var p1_path: String = editor.current_page()["bg_path"]
	editor._on_move_page(-1)
	await process_frame
	_check((editor.current_block()["pages"] as Array)[0]["bg_path"] == p1_path, "前へ移動でページが入れ替わる")
	_check(editor._page_idx == 0, "移動先へ追従する")

	# --- 削除 ---
	var before_del: int = (editor.current_block()["pages"] as Array).size()
	editor._on_delete_page()
	await process_frame
	_check((editor.current_block()["pages"] as Array).size() == before_del - 1, "ページが1枚減る")

	# --- 章全体が壊れていないこと ---
	var final_body := _read(TARGET)
	_check(final_body.contains("func outfit_3(bt):") and final_body.contains("func outfit_1(bt):"), "関数定義が残っている")
	_check(final_body.split("\n").size() > 150, "行が大量に消えていない (got %d)" % final_body.split("\n").size())

	# 復元
	_write(TARGET, snapshot)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TARGET + ".bak"))
	_check(_read(TARGET) == snapshot, "章ソースを元に戻した")
	printerr("[SLIDE] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
