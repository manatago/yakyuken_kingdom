extends Control
class_name SlideshowEditor

# 紙芝居（敗北ごとの一枚絵スライド）の編集画面。
#
# 章ソースを SlideshowSource で直接読み書きする。実行時のバトルを走らせないのは、
# bubble() が編集モードで丸ごとスキップされ、Background コマンドが呼び出し位置を
# 持たないため（実行しても紙芝居は観測できない）。ソースを唯一の真実源にすることで、
# ページの挿入・削除も行操作で完結する。
#
# 変更は毎回ファイルへ書き戻して再パースする。行番号を持ち回すと挿入・削除で必ず
# ずれるので、書いたら読み直す。

signal closed

const SlideshowSourceScript := preload("res://battle/SlideshowSource.gd")
const SourceFileWriterScript := preload("res://game/SourceFileWriter.gd")
const PortraitImportCacheScript := preload("res://game/PortraitImportCache.gd")
const BgRemovalEditorScript := preload("res://game/BgRemovalEditor.gd")
# 吹き出しの位置プリセットは実機と同じ表を使う（二重定義するとプレビューがズレる）
const BattleSceneScript := preload("res://game/BattleScene.gd")
const BubbleFitScript := preload("res://ui/BubbleFit.gd")

var chapter_res: String = ""
var _blocks: Array = []
var _block_idx: int = 0
var _page_idx: int = 0
var _bubble_idx: int = 0

var _bg_rect: TextureRect
var _bubble_label: Label
var _loss_sel: OptionButton
var _page_label: Label
var _path_label: Label
var _bubble_sel: OptionButton
var _side_sel: OptionButton
var _font_spin: SpinBox
var _bubble_panel: Panel
var _text_edit: TextEdit
var _info: Label

func setup(chapter_path: String) -> void:
	chapter_res = chapter_path

func _ready() -> void:
	# set_anchors_preset は「今の矩形を保つ」ようオフセットを再計算するため、
	# 親に add_child した後で呼ぶと size 0 のまま offset_right=-親幅 が入り、
	# 全画面アンカーなのに 0x0 になる。オフセットごと preset にする方を使う。
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_reload()
	var win := get_window()
	if win and not win.files_dropped.is_connected(_on_files_dropped):
		win.files_dropped.connect(_on_files_dropped)

func _exit_tree() -> void:
	var win := get_window()
	if win and win.files_dropped.is_connected(_on_files_dropped):
		win.files_dropped.disconnect(_on_files_dropped)

# ---------- UI ----------

func _build_ui() -> void:
	_bg_rect = TextureRect.new()
	_bg_rect.name = "SlidePreview"
	_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	# 吹き出しプレビュー。位置は実機と同じ BUBBLE_SIDE_ANCHORS で決める。
	# 幅・高さの比率まで合わせているので、ここで見た位置がそのまま本番になる。
	# 実機の ui/SpeechBubble.tscn と同じ構造にする。
	# PanelContainer にすると Container が子の最小サイズまで枠を広げてしまい、
	# 高さの上限 (BUBBLE_MAX_HEIGHT_RATIO) を無視して画面をはみ出す。
	# 素の Panel + アンカー配置の Label にして、枠の寸法をこちらで決める。
	_bubble_panel = Panel.new()
	_bubble_panel.name = "BubblePreview"
	_bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_panel.clip_contents = true
	var band_style := StyleBoxFlat.new()
	band_style.bg_color = Color(1.0, 0.98, 0.92, 0.92)
	band_style.set_corner_radius_all(18)
	_bubble_panel.add_theme_stylebox_override("panel", band_style)
	add_child(_bubble_panel)
	_bubble_label = Label.new()
	_bubble_label.name = "BubbleText"
	# 内側マージンは BubbleFit の比率から引く（.tscn と重複定義しない）
	var lw: float = BubbleFitScript.LABEL_W_RATIO
	var lh: float = BubbleFitScript.LABEL_H_RATIO
	_bubble_label.anchor_left = (1.0 - lw) / 2.0
	_bubble_label.anchor_right = 1.0 - (1.0 - lw) / 2.0
	_bubble_label.anchor_top = (1.0 - lh) / 2.0
	_bubble_label.anchor_bottom = 1.0 - (1.0 - lh) / 2.0
	_bubble_label.clip_contents = true
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.add_theme_font_size_override("font_size", BattleSceneScript.BUBBLE_FONT_SIZE)
	_bubble_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	_bubble_panel.add_child(_bubble_label)

	# 上部ナビ
	var nav := PanelContainer.new()
	nav.name = "SlideNavBar"
	nav.anchor_left = 0.18
	nav.anchor_right = 0.82
	nav.anchor_top = 0.01
	nav.anchor_bottom = 0.01
	nav.offset_bottom = 46
	var nav_style := StyleBoxFlat.new()
	nav_style.bg_color = Color(0, 0, 0, 0.8)
	nav_style.content_margin_left = 10
	nav_style.content_margin_right = 10
	nav_style.content_margin_top = 6
	nav_style.content_margin_bottom = 6
	nav.add_theme_stylebox_override("panel", nav_style)
	add_child(nav)
	var nav_box := HBoxContainer.new()
	nav_box.add_theme_constant_override("separation", 8)
	nav.add_child(nav_box)

	_loss_sel = OptionButton.new()
	_loss_sel.name = "LossSelector"
	_loss_sel.tooltip_text = "何敗目の紙芝居か（outfit_3 が1敗目）"
	_loss_sel.item_selected.connect(func(i: int):
		_block_idx = i
		_page_idx = 0
		_bubble_idx = 0
		_refresh())
	nav_box.add_child(_loss_sel)

	var prev_btn := Button.new()
	prev_btn.name = "PrevPageBtn"
	prev_btn.text = "◀ 前"
	prev_btn.pressed.connect(func(): _goto_page(_page_idx - 1))
	nav_box.add_child(prev_btn)

	_page_label = Label.new()
	_page_label.name = "PageLabel"
	_page_label.custom_minimum_size = Vector2(80, 0)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav_box.add_child(_page_label)

	var next_btn := Button.new()
	next_btn.name = "NextPageBtn"
	next_btn.text = "次 ▶"
	next_btn.pressed.connect(func(): _goto_page(_page_idx + 1))
	nav_box.add_child(next_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_box.add_child(spacer)

	var back_btn := Button.new()
	back_btn.name = "SlideBackBtn"
	back_btn.text = "← 戻る"
	back_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	back_btn.pressed.connect(func():
		closed.emit()
		queue_free())
	nav_box.add_child(back_btn)

	# 右パネル
	var panel := PanelContainer.new()
	panel.name = "SlideEditPanel"
	panel.anchor_left = 0.62
	panel.anchor_right = 0.99
	panel.anchor_top = 0.12
	panel.anchor_bottom = 0.12
	panel.offset_bottom = 360
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.06, 0.08, 0.06, 0.92)
	pstyle.content_margin_left = 10
	pstyle.content_margin_right = 10
	pstyle.content_margin_top = 8
	pstyle.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", pstyle)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	_path_label = Label.new()
	_path_label.name = "PathLabel"
	_path_label.add_theme_font_size_override("font_size", 12)
	_path_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	_path_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	vb.add_child(_path_label)

	var img_row := HBoxContainer.new()
	img_row.add_theme_constant_override("separation", 4)
	vb.add_child(img_row)
	var replace_btn := Button.new()
	replace_btn.name = "ReplaceImageBtn"
	replace_btn.text = "🔄 画像を選ぶ"
	replace_btn.tooltip_text = "外部の画像を選び、背景除去エディタを通して別名保存し、このページに割り当てる"
	replace_btn.pressed.connect(_on_replace_image)
	img_row.add_child(replace_btn)
	var hint := Label.new()
	hint.text = "  (ドロップでも可)"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	img_row.add_child(hint)

	_bubble_sel = OptionButton.new()
	_bubble_sel.name = "BubbleSelector"
	_bubble_sel.tooltip_text = "このページのセリフ（1枚に複数付くことがある）"
	_bubble_sel.item_selected.connect(func(i: int):
		_bubble_idx = i
		_refresh_text_only())
	vb.add_child(_bubble_sel)

	var side_row := HBoxContainer.new()
	side_row.add_theme_constant_override("separation", 4)
	vb.add_child(side_row)
	var side_lbl := Label.new()
	side_lbl.text = "位置:"
	side_lbl.add_theme_font_size_override("font_size", 12)
	side_row.add_child(side_lbl)
	_side_sel = OptionButton.new()
	_side_sel.name = "BubbleSideSelector"
	_side_sel.tooltip_text = "吹き出しの表示位置。選ぶと即座にソースへ書き戻す"
	for key in BattleSceneScript.BUBBLE_SIDE_ANCHORS.keys():
		_side_sel.add_item(str(key))
		_side_sel.set_item_metadata(_side_sel.item_count - 1, str(key))
	_side_sel.item_selected.connect(func(i: int): _on_change_side(str(_side_sel.get_item_metadata(i))))
	side_row.add_child(_side_sel)
	var font_lbl := Label.new()
	font_lbl.text = "  文字:"
	font_lbl.add_theme_font_size_override("font_size", 12)
	side_row.add_child(font_lbl)
	_font_spin = SpinBox.new()
	_font_spin.name = "BubbleFontSpin"
	_font_spin.min_value = 0
	_font_spin.max_value = 96
	_font_spin.step = 1
	_font_spin.tooltip_text = "このセリフの文字サイズ。0 で既定 (%d) に戻す。枠は文字量に合わせて自動で伸びる" % BattleSceneScript.BUBBLE_FONT_SIZE
	_font_spin.custom_minimum_size = Vector2(70, 0)
	_font_spin.value_changed.connect(func(v: float): _on_change_font_size(int(v)))
	side_row.add_child(_font_spin)

	_text_edit = TextEdit.new()
	_text_edit.name = "BubbleEdit"
	_text_edit.custom_minimum_size = Vector2(0, 90)
	_text_edit.add_theme_font_size_override("font_size", 14)
	vb.add_child(_text_edit)

	var apply_btn := Button.new()
	apply_btn.name = "ApplyTextBtn"
	apply_btn.text = "セリフを更新"
	apply_btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	apply_btn.pressed.connect(_on_apply_text)
	vb.add_child(apply_btn)

	var page_row := HBoxContainer.new()
	page_row.add_theme_constant_override("separation", 4)
	vb.add_child(page_row)
	for spec in [["AddPageBtn", "＋ページ追加", Color(0.6, 1.0, 0.6)], ["DelPageBtn", "🗑 削除", Color(1.0, 0.5, 0.5)],
			["MoveLeftBtn", "◀ 前へ移動", Color(0.8, 0.8, 1.0)], ["MoveRightBtn", "後ろへ移動 ▶", Color(0.8, 0.8, 1.0)]]:
		var b := Button.new()
		b.name = spec[0]
		b.text = spec[1]
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", spec[2])
		page_row.add_child(b)
	page_row.get_node("AddPageBtn").pressed.connect(_on_add_page)
	page_row.get_node("DelPageBtn").pressed.connect(_on_delete_page)
	page_row.get_node("MoveLeftBtn").pressed.connect(func(): _on_move_page(-1))
	page_row.get_node("MoveRightBtn").pressed.connect(func(): _on_move_page(1))

	_info = Label.new()
	_info.name = "SlideInfoLabel"
	_info.add_theme_font_size_override("font_size", 11)
	_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_info)

# ---------- 状態 ----------

func _reload() -> void:
	var lines := SlideshowSourceScript.read_lines(chapter_res)
	_blocks = SlideshowSourceScript.parse_blocks(lines)
	_block_idx = clampi(_block_idx, 0, max(0, _blocks.size() - 1))
	_loss_sel.clear()
	for b in _blocks:
		_loss_sel.add_item("%d敗目  (%s / %dページ)" % [b["loss_index"], b["func_name"], (b["pages"] as Array).size()])
	if _blocks.size() > 0:
		_loss_sel.select(_block_idx)
	_refresh()

func current_block() -> Dictionary:
	if _block_idx < 0 or _block_idx >= _blocks.size():
		return {}
	return _blocks[_block_idx]

func current_page() -> Dictionary:
	var b := current_block()
	if b.is_empty():
		return {}
	var pages: Array = b["pages"]
	if _page_idx < 0 or _page_idx >= pages.size():
		return {}
	return pages[_page_idx]

func _goto_page(idx: int) -> void:
	var b := current_block()
	if b.is_empty():
		return
	var n: int = (b["pages"] as Array).size()
	_page_idx = clampi(idx, 0, max(0, n - 1))
	_bubble_idx = 0
	_refresh()

func _refresh() -> void:
	var b := current_block()
	var pages: Array = b.get("pages", [])
	_page_idx = clampi(_page_idx, 0, max(0, pages.size() - 1))
	_page_label.text = "%d / %d" % [_page_idx + 1, pages.size()]
	var p := current_page()
	if p.is_empty():
		_bg_rect.texture = null
		_path_label.text = "(ページなし)"
		_bubble_sel.clear()
		_text_edit.text = ""
		_bubble_label.text = ""
		return
	var path: String = p["bg_path"]
	_bg_rect.texture = load(path)
	_path_label.text = "%s\n%s 行%d" % [path.get_file(), chapter_res.get_file(), p["bg_line"]]
	_bubble_sel.clear()
	var bl: Array = p["bubbles"]
	for i in range(bl.size()):
		_bubble_sel.add_item("セリフ %d / %d" % [i + 1, bl.size()])
	_bubble_idx = clampi(_bubble_idx, 0, max(0, bl.size() - 1))
	if bl.size() > 0:
		_bubble_sel.select(_bubble_idx)
	_bubble_sel.visible = bl.size() > 1
	_refresh_text_only()

func _refresh_text_only() -> void:
	var p := current_page()
	var bl: Array = p.get("bubbles", [])
	if _bubble_idx < 0 or _bubble_idx >= bl.size():
		_text_edit.text = ""
		_bubble_label.text = ""
		_bubble_panel.visible = false
		return
	_bubble_panel.visible = true
	var bub: Dictionary = bl[_bubble_idx]
	_text_edit.text = bub["text"]
	_bubble_label.text = bub["text"]
	var fs: int = int(bub.get("font_size", 0))
	if _font_spin:
		_font_spin.set_block_signals(true)
		_font_spin.value = fs
		_font_spin.set_block_signals(false)
	_bubble_label.add_theme_font_size_override("font_size",
		fs if fs > 0 else BattleSceneScript.BUBBLE_FONT_SIZE)
	_apply_preview_side(str(bub.get("side", "")))

# 吹き出しプレビューを実機と同じアンカーへ置く。
func _apply_preview_side(side: String) -> void:
	var table: Dictionary = BattleSceneScript.BUBBLE_SIDE_ANCHORS
	var key: String = side if table.has(side) else "center"
	var a: Dictionary = table[key]
	_bubble_panel.anchor_left = a["l"]
	_bubble_panel.anchor_right = a["r"]
	_bubble_panel.anchor_top = a["t"]
	_bubble_panel.anchor_bottom = a["b"]
	_bubble_panel.offset_left = 0
	_bubble_panel.offset_right = 0
	_bubble_panel.offset_top = 0
	_bubble_panel.offset_bottom = 0
	_fit_preview_bubble(a)
	if _side_sel:
		for i in range(_side_sel.item_count):
			if str(_side_sel.get_item_metadata(i)) == key:
				_side_sel.set_block_signals(true)
				_side_sel.select(i)
				_side_sel.set_block_signals(false)
				break

# 実機の _fit_bubble_to_text と同じ式で高さを決める（共通の静的関数を呼ぶ）。
func _fit_preview_bubble(a: Dictionary) -> void:
	var vp: Vector2 = get_viewport_rect().size
	var box_w: float = vp.x * (float(a["r"]) - float(a["l"]))
	var min_h: float = vp.y * (float(a["b"]) - float(a["t"]))
	var max_h: float = vp.y * BubbleFitScript.MAX_HEIGHT_RATIO
	var font: Font = _bubble_label.get_theme_font("font")
	var fs: int = _bubble_label.get_theme_font_size("font_size")
	var box_h: float = BubbleFitScript.box_height(_bubble_label.text, font, fs, box_w, min_h, max_h)
	if float(a["t"]) >= 0.5:
		_bubble_panel.anchor_top = a["b"]
		_bubble_panel.anchor_bottom = a["b"]
		_bubble_panel.offset_top = -box_h
		_bubble_panel.offset_bottom = 0
	else:
		_bubble_panel.anchor_top = a["t"]
		_bubble_panel.anchor_bottom = a["t"]
		_bubble_panel.offset_top = 0
		_bubble_panel.offset_bottom = box_h

func _on_change_font_size(size: int) -> void:
	var bi: int = _bubble_idx
	var pi: int = _page_idx
	_mutate(func(lines, block):
		var pages: Array = block["pages"]
		if pi < 0 or pi >= pages.size():
			return false
		var bl: Array = pages[pi]["bubbles"]
		if bi < 0 or bi >= bl.size():
			return false
		return SlideshowSourceScript.set_bubble_font_size(lines, bl[bi], size),
		"文字サイズを %s へ" % ("既定" if size <= 0 else str(size)))

func _on_change_side(new_side: String) -> void:
	var bi: int = _bubble_idx
	var pi: int = _page_idx
	_mutate(func(lines, block):
		var pages: Array = block["pages"]
		if pi < 0 or pi >= pages.size():
			return false
		var bl: Array = pages[pi]["bubbles"]
		if bi < 0 or bi >= bl.size():
			return false
		return SlideshowSourceScript.set_bubble_side(lines, bl[bi], new_side), "セリフの位置を %s へ" % new_side)

# 書き換えは必ず「読む → 直す → 書く → 読み直す」。行番号を持ち回さない。
func _mutate(op: Callable, note: String) -> bool:
	var lines := SlideshowSourceScript.read_lines(chapter_res)
	var blocks: Array = SlideshowSourceScript.parse_blocks(lines)
	if _block_idx < 0 or _block_idx >= blocks.size():
		_info.text = "[NG] ブロックが見つからない"
		return false
	if not op.call(lines, blocks[_block_idx]):
		_info.text = "[NG] %s" % note
		return false
	if not SourceFileWriterScript.write(ProjectSettings.globalize_path(chapter_res), "\n".join(lines)):
		_info.text = "[NG] 書き込み失敗"
		return false
	_reload()
	_info.text = "[OK] %s" % note
	print("[SLIDESHOW] %s (%s ブロック%d ページ%d)" % [note, chapter_res.get_file(), _block_idx, _page_idx])
	return true

# ---------- 操作 ----------

func _on_apply_text() -> void:
	var new_text: String = _text_edit.text
	var bi: int = _bubble_idx
	var pi: int = _page_idx
	_mutate(func(lines, block):
		var pages: Array = block["pages"]
		if pi < 0 or pi >= pages.size():
			return false
		var bl: Array = pages[pi]["bubbles"]
		if bi < 0 or bi >= bl.size():
			return false
		return SlideshowSourceScript.set_bubble_text(lines, bl[bi], new_text), "セリフを更新")

func _on_add_page() -> void:
	var p := current_page()
	var bg: String = p.get("bg_path", "")
	var pi: int = _page_idx
	if _mutate(func(lines, block):
			return SlideshowSourceScript.insert_page(lines, block, pi, bg, "..."), "ページを追加"):
		_goto_page(pi + 1)

func _on_delete_page() -> void:
	var pi: int = _page_idx
	if _mutate(func(lines, block):
			return SlideshowSourceScript.delete_page(lines, block, pi), "ページを削除（最後の1枚は消せません）"):
		_goto_page(min(pi, 9999))

func _on_move_page(dir: int) -> void:
	var pi: int = _page_idx
	if _mutate(func(lines, block):
			return SlideshowSourceScript.move_page(lines, block, pi, dir), "ページを移動"):
		_goto_page(pi + dir)

# ---------- 画像差し替え ----------

func _on_replace_image() -> void:
	var dlg := FileDialog.new()
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.access = FileDialog.ACCESS_FILESYSTEM
	dlg.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; 画像ファイル"])
	dlg.title = "このページに使う画像を選択"
	dlg.size = Vector2i(900, 600)
	add_child(dlg)
	dlg.file_selected.connect(func(path: String):
		dlg.queue_free()
		_open_bg_editor(path))
	dlg.canceled.connect(func(): dlg.queue_free())
	dlg.popup_centered()

func _on_files_dropped(files: PackedStringArray) -> void:
	if not is_inside_tree() or files.is_empty():
		return
	for f in files:
		var lower: String = String(f).to_lower()
		if lower.ends_with(".png") or lower.ends_with(".jpg") or lower.ends_with(".jpeg") or lower.ends_with(".webp"):
			_open_bg_editor(f)
			return
	_info.text = "[NG] 画像形式ではない"

func _open_bg_editor(source_path: String) -> void:
	var p := current_page()
	if p.is_empty():
		_info.text = "[NG] 対象ページなし"
		return
	var editor = BgRemovalEditorScript.new()
	editor.setup(source_path, String(p["bg_path"]).get_file())
	editor.applied.connect(func(final_image: Image):
		_apply_new_image(final_image)
		editor.queue_free())
	editor.cancelled.connect(func(): editor.queue_free())
	add_child(editor)
	editor.show()

# 別名保存してページの参照を差し替える。既存ファイルは上書きしない。
func _apply_new_image(final_image: Image) -> void:
	var p := current_page()
	if p.is_empty():
		return
	var old_res: String = p["bg_path"]
	var new_res: String = _next_variant(old_res)
	if new_res.is_empty():
		_info.text = "[NG] 別名パスを決められない"
		return
	var new_abs: String = ProjectSettings.globalize_path(new_res)
	DirAccess.make_dir_recursive_absolute(new_abs.get_base_dir())
	if final_image.save_png(new_abs) != OK:
		_info.text = "[NG] PNG 保存失敗"
		return
	# 同名ファイルの古いインポートキャッシュが残っていると load() がそちらを返す
	var purged: int = PortraitImportCacheScript.purge(new_res)
	if purged > 0:
		print("[SLIDESHOW] 旧インポートキャッシュを破棄: %s (%d ファイル)" % [new_res.get_file(), purged])
	var pi: int = _page_idx
	_mutate(func(lines, block):
		var pages: Array = block["pages"]
		if pi < 0 or pi >= pages.size():
			return false
		return SlideshowSourceScript.set_page_image(lines, pages[pi], new_res), "画像を差し替え: %s" % new_res.get_file())

func _next_variant(current_res: String) -> String:
	var dir: String = current_res.get_base_dir()
	var stem: String = current_res.get_file().get_basename()
	var re := RegEx.new()
	re.compile("_v(\\d+)$")
	var m: RegExMatch = re.search(stem)
	if m:
		stem = stem.substr(0, m.get_start())
	var i: int = 1
	while i < 10000:
		var candidate: String = "%s/%s_v%d.png" % [dir, stem, i]
		if not FileAccess.file_exists(ProjectSettings.globalize_path(candidate)):
			return candidate
		i += 1
	return ""
