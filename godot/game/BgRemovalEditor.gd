extends Window
class_name BgRemovalEditor

# 背景除去モーダルエディタ (別 OS ウィンドウ)。
# - AI 自動除去: rembg (Python CLI) をサブプロセスで実行。~/mangas と同じ方式。
# - ワンド: クリック地点から連結する類似色領域を透明化 (scanline flood-fill)。
# - ブラシ: ドラッグで消しゴム / 復元。
# - ホイールでカーソル中心ズーム、右クリックドラッグでパン。
# - Undo (Ctrl+Z)。適用でコールバックへ編集済 Image を渡す。

signal applied(final_image: Image)
signal cancelled

const REMBG_MODEL := "isnet-anime"
const MAX_UNDO := 30
const MIN_ZOOM := 0.1
const MAX_ZOOM := 12.0

# 画像バッファ (RGBA8 に統一)
var _original: Image = null       # 読み込み直後の不変コピー (復元ブラシ用)
var _current: Image = null        # 編集中の作業画像
var _img_size: Vector2i = Vector2i.ZERO

# ツール状態
var _tool: String = "wand"        # "wand" | "brush"
var _brush_mode: String = "erase" # "erase" | "restore"
var _tolerance: int = 60
var _brush_size: int = 24
var _zoom: float = 1.0
var _undo_stack: Array[PackedByteArray] = []
var _painting: bool = false
var _last_paint_ipos: Vector2i = Vector2i(-1, -1)
var _panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_scroll: Vector2i = Vector2i.ZERO

# 保存ハンドラ
var _save_target_hint: String = ""

# rembg 実行状態 (OS.create_process ベース、Timer でポーリング)
var _rembg_pid: int = -1
var _rembg_poll_timer: Timer = null
var _rembg_input_tmp: String = ""
var _rembg_output_tmp: String = ""

# 遅延セットアップ用 (setup が _ready より先に呼ばれた場合の保留)
var _pending_source_path: String = ""

# UI ノード
var _scroll: ScrollContainer
var _canvas_holder: Control
var _checker_bg: TextureRect
var _image_rect: TextureRect
var _tolerance_slider: HSlider
var _brush_slider: HSlider
var _tool_label: Label
var _mode_label: Label
var _zoom_label: Label
var _status_label: Label
var _ai_btn: Button
var _apply_btn: Button
var _tool_wand_btn: Button
var _tool_brush_btn: Button
var _brush_erase_btn: Button
var _brush_restore_btn: Button

# --- ライフサイクル -----------------------------------------------

func setup(input_path: String, target_hint: String = "") -> bool:
	_save_target_hint = target_hint if not target_hint.is_empty() else input_path.get_file()
	# _ready 前に呼ばれた場合は保留し、_ready で読み込む
	if not is_node_ready():
		_pending_source_path = input_path
		return true
	return _load_image_from(input_path)

func _load_image_from(input_path: String) -> bool:
	var abs: String = input_path
	if abs.begins_with("res://"):
		abs = ProjectSettings.globalize_path(abs)
	var img := Image.new()
	var err: int = img.load(abs)
	if err != OK:
		push_error("[BgRemovalEditor] load 失敗: %s (err=%d)" % [abs, err])
		if _status_label:
			_status_label.text = "[NG] 画像読み込み失敗: %s (err=%d)" % [abs, err]
		return false
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	_original = img
	_current = img.duplicate()
	_img_size = Vector2i(img.get_width(), img.get_height())
	_rebuild_texture()
	_apply_zoom()
	if _status_label:
		_status_label.text = "読み込み: %s  (%d×%d)" % [_save_target_hint, _img_size.x, _img_size.y]
	# 少し遅らせて fit（ScrollContainer のレイアウト確定後）
	call_deferred("_fit_zoom")
	return true

func _ready() -> void:
	name = "BgRemovalEditor"
	title = "🎨 背景除去エディタ"
	size = Vector2i(1280, 820)
	min_size = Vector2i(700, 500)
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	close_requested.connect(_on_cancel_pressed)

	# Window の中身: 全域を占める Control
	var root := Control.new()
	root.name = "EditorRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.10, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "RootVBox"
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	root.add_child(root_vbox)

	_build_header(root_vbox)
	_build_canvas_area(root_vbox)
	_build_footer(root_vbox)

	_refresh_tool_buttons()
	_refresh_mode_label()

	# 保留された画像を読み込む
	if not _pending_source_path.is_empty():
		var p: String = _pending_source_path
		_pending_source_path = ""
		_load_image_from(p)

	# rembg 実行パスヒント
	var probe: Array = _resolve_rembg_command()
	if probe.is_empty() or probe[0] == "rembg":
		_ai_btn.tooltip_text = "rembg 実行 (絶対パス未検出。PATH の rembg にフォールバック。未インストールなら pip install rembg または YAKYUKEN_REMBG=/abs/path)"
	else:
		_ai_btn.tooltip_text = "rembg (isnet-anime) でワンショット背景除去: %s" % probe[0]

# --- ヘッダー (ツールバー) ---------------------------------------

func _build_header(parent: VBoxContainer) -> void:
	var header := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.15, 0.18, 1.0)
	st.content_margin_left = 10; st.content_margin_right = 10
	st.content_margin_top = 6; st.content_margin_bottom = 6
	header.add_theme_stylebox_override("panel", st)
	parent.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)

	_ai_btn = Button.new()
	_ai_btn.text = "🤖 AI 自動除去"
	_ai_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.7))
	_ai_btn.pressed.connect(_on_ai_pressed)
	row.add_child(_ai_btn)

	row.add_child(VSeparator.new())

	_tool_wand_btn = Button.new()
	_tool_wand_btn.text = "🖱 ワンド"
	_tool_wand_btn.tooltip_text = "クリックで連結領域を透明化"
	_tool_wand_btn.pressed.connect(func(): _set_tool("wand"))
	row.add_child(_tool_wand_btn)

	_tool_brush_btn = Button.new()
	_tool_brush_btn.text = "🖌 ブラシ"
	_tool_brush_btn.tooltip_text = "ドラッグで消しゴム / 復元"
	_tool_brush_btn.pressed.connect(func(): _set_tool("brush"))
	row.add_child(_tool_brush_btn)

	_brush_erase_btn = Button.new()
	_brush_erase_btn.text = "消す"
	_brush_erase_btn.pressed.connect(func(): _set_brush_mode("erase"))
	row.add_child(_brush_erase_btn)
	_brush_restore_btn = Button.new()
	_brush_restore_btn.text = "戻す"
	_brush_restore_btn.tooltip_text = "元画像の色/アルファを復元"
	_brush_restore_btn.pressed.connect(func(): _set_brush_mode("restore"))
	row.add_child(_brush_restore_btn)

	row.add_child(VSeparator.new())

	var tol_lbl := Label.new()
	tol_lbl.text = "許容色差"
	row.add_child(tol_lbl)
	_tolerance_slider = HSlider.new()
	_tolerance_slider.min_value = 0
	_tolerance_slider.max_value = 200
	_tolerance_slider.step = 1
	_tolerance_slider.value = _tolerance
	_tolerance_slider.custom_minimum_size = Vector2(130, 0)
	_tolerance_slider.value_changed.connect(func(v: float): _tolerance = int(v); _refresh_mode_label())
	row.add_child(_tolerance_slider)

	var br_lbl := Label.new()
	br_lbl.text = "ブラシ径"
	row.add_child(br_lbl)
	_brush_slider = HSlider.new()
	_brush_slider.min_value = 2
	_brush_slider.max_value = 200
	_brush_slider.step = 1
	_brush_slider.value = _brush_size
	_brush_slider.custom_minimum_size = Vector2(110, 0)
	_brush_slider.value_changed.connect(func(v: float): _brush_size = int(v); _refresh_mode_label())
	row.add_child(_brush_slider)

	row.add_child(VSeparator.new())

	var undo_btn := Button.new()
	undo_btn.text = "↩ Undo"
	undo_btn.pressed.connect(_do_undo)
	row.add_child(undo_btn)

	var fit_btn := Button.new()
	fit_btn.text = "🔍 フィット"
	fit_btn.pressed.connect(_fit_zoom)
	row.add_child(fit_btn)
	var oneone_btn := Button.new()
	oneone_btn.text = "1:1"
	oneone_btn.pressed.connect(func(): _set_zoom(1.0))
	row.add_child(oneone_btn)

	_zoom_label = Label.new()
	_zoom_label.text = "100%"
	_zoom_label.custom_minimum_size = Vector2(60, 0)
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_zoom_label)

	_tool_label = Label.new()
	_tool_label.text = ""
	row.add_child(_tool_label)
	_mode_label = Label.new()
	_mode_label.text = ""
	_mode_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	row.add_child(_mode_label)

# --- キャンバス --------------------------------------------------

func _build_canvas_area(parent: VBoxContainer) -> void:
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	parent.add_child(_scroll)

	_canvas_holder = Control.new()
	_canvas_holder.name = "CanvasHolder"
	_canvas_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas_holder.gui_input.connect(_on_canvas_input)
	_scroll.add_child(_canvas_holder)

	_checker_bg = TextureRect.new()
	_checker_bg.name = "CheckerBG"
	_checker_bg.texture = _build_checker_texture(16)
	_checker_bg.stretch_mode = TextureRect.STRETCH_TILE
	_checker_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_holder.add_child(_checker_bg)

	_image_rect = TextureRect.new()
	_image_rect.name = "EditImage"
	_image_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas_holder.add_child(_image_rect)

# --- フッター (状態 + ボタン) ------------------------------------

func _build_footer(parent: VBoxContainer) -> void:
	var footer := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.15, 0.18, 1.0)
	st.content_margin_left = 10; st.content_margin_right = 10
	st.content_margin_top = 6; st.content_margin_bottom = 6
	footer.add_theme_stylebox_override("panel", st)
	parent.add_child(footer)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	footer.add_child(row)

	_status_label = Label.new()
	_status_label.text = "読み込み中..."
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_status_label)

	var cancel_btn := Button.new()
	cancel_btn.text = "✕ キャンセル"
	cancel_btn.pressed.connect(_on_cancel_pressed)
	row.add_child(cancel_btn)

	_apply_btn = Button.new()
	_apply_btn.text = "✔ 適用"
	_apply_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_apply_btn.pressed.connect(_on_apply_pressed)
	row.add_child(_apply_btn)

func _build_checker_texture(sq: int) -> Texture2D:
	var w := sq * 2
	var img := Image.create(w, w, false, Image.FORMAT_RGBA8)
	var c1 := Color(0.75, 0.75, 0.75)
	var c2 := Color(0.94, 0.94, 0.94)
	for y in range(w):
		for x in range(w):
			var use1: bool = ((x / sq) + (y / sq)) % 2 == 0
			img.set_pixel(x, y, c1 if use1 else c2)
	return ImageTexture.create_from_image(img)

# --- ツール切替 -------------------------------------------------

func _set_tool(t: String) -> void:
	_tool = t
	_refresh_tool_buttons()
	_refresh_mode_label()

func _set_brush_mode(m: String) -> void:
	_brush_mode = m
	_refresh_tool_buttons()
	_refresh_mode_label()

func _refresh_tool_buttons() -> void:
	var active_c := Color(0.4, 1.0, 0.6)
	var inactive_c := Color(0.7, 0.7, 0.7)
	if _tool_wand_btn:
		_tool_wand_btn.add_theme_color_override("font_color", active_c if _tool == "wand" else inactive_c)
	if _tool_brush_btn:
		_tool_brush_btn.add_theme_color_override("font_color", active_c if _tool == "brush" else inactive_c)
	if _brush_erase_btn:
		_brush_erase_btn.disabled = _tool != "brush"
		_brush_erase_btn.add_theme_color_override("font_color", active_c if _brush_mode == "erase" else inactive_c)
	if _brush_restore_btn:
		_brush_restore_btn.disabled = _tool != "brush"
		_brush_restore_btn.add_theme_color_override("font_color", active_c if _brush_mode == "restore" else inactive_c)

func _refresh_mode_label() -> void:
	if not _mode_label: return
	if _tool == "wand":
		_mode_label.text = "  クリック→連結 (許容 %d)" % _tolerance
	else:
		_mode_label.text = "  ドラッグ→%s (径 %d)" % [("消去" if _brush_mode == "erase" else "復元"), _brush_size]

# --- ズーム & パン -----------------------------------------------

func _set_zoom(z: float) -> void:
	z = clampf(z, MIN_ZOOM, MAX_ZOOM)
	if z == _zoom:
		return
	_zoom = z
	_apply_zoom()

func _apply_zoom() -> void:
	if _img_size == Vector2i.ZERO or not _canvas_holder:
		return
	var dw: int = int(round(_img_size.x * _zoom))
	var dh: int = int(round(_img_size.y * _zoom))
	_canvas_holder.custom_minimum_size = Vector2(dw, dh)
	_canvas_holder.size = Vector2(dw, dh)
	if _checker_bg:
		_checker_bg.position = Vector2.ZERO
		_checker_bg.size = Vector2(dw, dh)
	if _image_rect:
		_image_rect.position = Vector2.ZERO
		_image_rect.size = Vector2(dw, dh)
	if _zoom_label:
		_zoom_label.text = "%d%%" % int(round(_zoom * 100))

func _zoom_at(pointer_local: Vector2, factor: float) -> void:
	var next: float = clampf(_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	if next == _zoom:
		return
	var img_x: float = pointer_local.x / _zoom
	var img_y: float = pointer_local.y / _zoom
	_zoom = next
	_apply_zoom()
	var vp_x: float = pointer_local.x - _scroll.scroll_horizontal
	var vp_y: float = pointer_local.y - _scroll.scroll_vertical
	var new_scroll_x: int = int(round(img_x * _zoom - vp_x))
	var new_scroll_y: int = int(round(img_y * _zoom - vp_y))
	_scroll.scroll_horizontal = max(0, new_scroll_x)
	_scroll.scroll_vertical = max(0, new_scroll_y)

func _fit_zoom() -> void:
	if _img_size == Vector2i.ZERO or not _scroll:
		return
	var vp: Vector2 = _scroll.size
	if vp.x <= 0 or vp.y <= 0:
		return
	var fx: float = vp.x / float(_img_size.x)
	var fy: float = vp.y / float(_img_size.y)
	_set_zoom(minf(fx, fy) * 0.98)

# --- 入力ハンドラ -----------------------------------------------

func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(mb.position, 1.15)
			set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(mb.position, 1.0 / 1.15)
			set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_panning = true
				_pan_start_mouse = mb.position
				_pan_start_scroll = Vector2i(_scroll.scroll_horizontal, _scroll.scroll_vertical)
			else:
				_panning = false
			set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var ipos: Vector2i = _canvas_to_image(mb.position)
			if ipos.x < 0:
				return
			if mb.pressed:
				if _tool == "wand":
					_snapshot_for_undo()
					_apply_wand(ipos)
				else:
					_snapshot_for_undo()
					_painting = true
					_last_paint_ipos = ipos
					_stamp_brush(ipos)
					_rebuild_texture()
			else:
				_painting = false
				_last_paint_ipos = Vector2i(-1, -1)
			set_input_as_handled()
			return
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _panning:
			var dx: float = mm.position.x - _pan_start_mouse.x
			var dy: float = mm.position.y - _pan_start_mouse.y
			_scroll.scroll_horizontal = max(0, _pan_start_scroll.x - int(dx))
			_scroll.scroll_vertical = max(0, _pan_start_scroll.y - int(dy))
			return
		if _painting and _tool == "brush":
			var ipos: Vector2i = _canvas_to_image(mm.position)
			if ipos.x < 0:
				return
			_paint_line(_last_paint_ipos, ipos)
			_last_paint_ipos = ipos
			_rebuild_texture()

# Window 内でのキー入力: input イベントで受ける
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var ek: InputEventKey = event
		if ek.keycode == KEY_Z and (ek.ctrl_pressed or ek.meta_pressed):
			_do_undo()
			get_viewport().set_input_as_handled()
		elif ek.keycode == KEY_ESCAPE:
			_on_cancel_pressed()
			get_viewport().set_input_as_handled()

func _canvas_to_image(local_pos: Vector2) -> Vector2i:
	if _img_size == Vector2i.ZERO or _zoom <= 0:
		return Vector2i(-1, -1)
	var ix: int = int(floor(local_pos.x / _zoom))
	var iy: int = int(floor(local_pos.y / _zoom))
	if ix < 0 or iy < 0 or ix >= _img_size.x or iy >= _img_size.y:
		return Vector2i(-1, -1)
	return Vector2i(ix, iy)

# --- Undo ------------------------------------------------------

func _snapshot_for_undo() -> void:
	if not _current: return
	var snap: PackedByteArray = _current.get_data()
	_undo_stack.append(snap)
	if _undo_stack.size() > MAX_UNDO:
		_undo_stack = _undo_stack.slice(_undo_stack.size() - MAX_UNDO)

func _do_undo() -> void:
	if _undo_stack.is_empty():
		if _status_label: _status_label.text = "Undo できる操作がない"
		return
	var prev: PackedByteArray = _undo_stack.pop_back()
	_current = Image.create_from_data(_img_size.x, _img_size.y, false, Image.FORMAT_RGBA8, prev)
	_rebuild_texture()
	if _status_label: _status_label.text = "↩ Undo (残 %d)" % _undo_stack.size()

# --- ワンド (flood-fill) --------------------------------------

# scanline 4-連結 flood-fill (mangas の wandMask.ts contiguousMask 相当)
func _apply_wand(start: Vector2i) -> void:
	var w: int = _img_size.x
	var h: int = _img_size.y
	if start.x < 0 or start.y < 0 or start.x >= w or start.y >= h:
		return
	var data: PackedByteArray = _current.get_data()
	var i0: int = (start.y * w + start.x) * 4
	if data[i0 + 3] == 0:
		if _status_label: _status_label.text = "既に透明な画素です"
		return
	var tr: int = data[i0]
	var tg: int = data[i0 + 1]
	var tb: int = data[i0 + 2]
	var tol2: int = _tolerance * _tolerance
	var visited := PackedByteArray()
	visited.resize(w * h)
	var stack: PackedInt32Array = PackedInt32Array()
	stack.append(start.y * w + start.x)
	var erased: int = 0
	while stack.size() > 0:
		var seed: int = stack[stack.size() - 1]
		stack.remove_at(stack.size() - 1)
		var py: int = seed / w
		var sx: int = seed - py * w
		var x: int = sx
		while x >= 0 and visited[py * w + x] == 0 and _pixel_within(data, py * w + x, tr, tg, tb, tol2):
			x -= 1
		x += 1
		var span_above := false
		var span_below := false
		while x < w and visited[py * w + x] == 0 and _pixel_within(data, py * w + x, tr, tg, tb, tol2):
			var p: int = py * w + x
			visited[p] = 1
			data[p * 4 + 3] = 0
			erased += 1
			if py > 0:
				var above_p: int = (py - 1) * w + x
				var above_ok: bool = visited[above_p] == 0 and _pixel_within(data, above_p, tr, tg, tb, tol2)
				if not span_above and above_ok:
					stack.append(above_p); span_above = true
				elif span_above and not above_ok:
					span_above = false
			if py < h - 1:
				var below_p: int = (py + 1) * w + x
				var below_ok: bool = visited[below_p] == 0 and _pixel_within(data, below_p, tr, tg, tb, tol2)
				if not span_below and below_ok:
					stack.append(below_p); span_below = true
				elif span_below and not below_ok:
					span_below = false
			x += 1
	_current = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
	_rebuild_texture()
	if _status_label:
		_status_label.text = "🖱 ワンド: %d px 透明化 (許容 %d, 起点 %d,%d)" % [erased, _tolerance, start.x, start.y]

func _pixel_within(data: PackedByteArray, p: int, tr: int, tg: int, tb: int, tol2: int) -> bool:
	var i: int = p * 4
	if data[i + 3] == 0:
		return false
	var dr: int = data[i] - tr
	var dg: int = data[i + 1] - tg
	var db: int = data[i + 2] - tb
	return dr * dr + dg * dg + db * db <= tol2

# --- ブラシ ---------------------------------------------------

func _stamp_brush(center: Vector2i) -> void:
	var w: int = _img_size.x
	var h: int = _img_size.y
	var r: int = _brush_size
	var r2: int = r * r
	var data: PackedByteArray = _current.get_data()
	var orig_data: PackedByteArray = _original.get_data() if _brush_mode == "restore" else PackedByteArray()
	var y0: int = max(0, center.y - r)
	var y1: int = min(h - 1, center.y + r)
	var x0: int = max(0, center.x - r)
	var x1: int = min(w - 1, center.x + r)
	for y in range(y0, y1 + 1):
		var dy: int = y - center.y
		var dy2: int = dy * dy
		for x in range(x0, x1 + 1):
			var dx: int = x - center.x
			if dx * dx + dy2 > r2:
				continue
			var p: int = (y * w + x) * 4
			if _brush_mode == "erase":
				data[p + 3] = 0
			else:
				data[p] = orig_data[p]
				data[p + 1] = orig_data[p + 1]
				data[p + 2] = orig_data[p + 2]
				data[p + 3] = orig_data[p + 3]
	_current = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)

func _paint_line(a: Vector2i, b: Vector2i) -> void:
	if a.x < 0 or b.x < 0:
		_stamp_brush(b)
		return
	var dist: float = Vector2(b - a).length()
	var step: float = max(1.0, float(_brush_size) / 2.0)
	var n: int = max(1, int(ceil(dist / step)))
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var pos := Vector2i(
			int(round(a.x + (b.x - a.x) * t)),
			int(round(a.y + (b.y - a.y) * t))
		)
		_stamp_brush(pos)

# --- テクスチャ更新 --------------------------------------------

# 毎回 ImageTexture を作り直して TextureRect に再アサイン。
# ImageTexture.update() は Godot 4 で内部キャッシュの都合で描画に反映されないケースがある
# ため、確実性を優先して再生成する。~1024×1024 なら数 ms 程度で問題なし。
func _rebuild_texture() -> void:
	if not _current or not _image_rect:
		return
	var tex := ImageTexture.create_from_image(_current)
	_image_rect.texture = tex
	_image_rect.queue_redraw()

# --- AI 除去 (rembg) ------------------------------------------

func _resolve_rembg_command() -> Array:
	var env_override: String = OS.get_environment("YAKYUKEN_REMBG").strip_edges()
	if not env_override.is_empty() and FileAccess.file_exists(env_override):
		return [env_override, []]
	var candidates: Array = [
		"/Library/Frameworks/Python.framework/Versions/3.11/bin/rembg",
		"/opt/homebrew/bin/rembg",
		"/usr/local/bin/rembg",
		"/usr/bin/rembg",
		OS.get_environment("HOME").path_join(".local/bin/rembg"),
	]
	for c in candidates:
		if FileAccess.file_exists(c):
			return [c, []]
	return ["rembg", []]

func _on_ai_pressed() -> void:
	if not _current:
		return
	if _rembg_pid > 0 and OS.is_process_running(_rembg_pid):
		_status_label.text = "既に実行中..."
		return
	var cmd: Array = _resolve_rembg_command()
	if cmd.is_empty():
		_status_label.text = "[NG] rembg が見つからない"
		return
	var tmp_dir: String = OS.get_user_data_dir().path_join("bg_removal_tmp")
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var stamp: int = Time.get_ticks_msec()
	_rembg_input_tmp = tmp_dir.path_join("in_%d.png" % stamp)
	_rembg_output_tmp = tmp_dir.path_join("out_%d.png" % stamp)
	var save_err: int = _current.save_png(_rembg_input_tmp)
	if save_err != OK:
		_status_label.text = "[NG] 一時ファイル書き込み失敗 (err=%d)" % save_err
		return
	var exec_path: String = cmd[0]
	var prefix: Array = cmd[1]
	var args: PackedStringArray = PackedStringArray()
	for a in prefix:
		args.append(String(a))
	args.append("i")
	args.append("-m"); args.append(REMBG_MODEL)
	args.append(_rembg_input_tmp)
	args.append(_rembg_output_tmp)
	var pid: int = OS.create_process(exec_path, args)
	if pid <= 0:
		_status_label.text = "[NG] プロセス起動失敗: %s" % exec_path
		return
	_rembg_pid = pid
	_ai_btn.disabled = true
	_apply_btn.disabled = true
	_status_label.text = "🤖 rembg 実行中... (%s) — キャンセル可" % REMBG_MODEL
	# ポーリング Timer 起動 (main thread 上で is_process_running を叩く)
	if not _rembg_poll_timer:
		_rembg_poll_timer = Timer.new()
		_rembg_poll_timer.name = "RembgPollTimer"
		_rembg_poll_timer.wait_time = 0.25
		_rembg_poll_timer.one_shot = false
		_rembg_poll_timer.timeout.connect(_poll_rembg)
		add_child(_rembg_poll_timer)
	_rembg_poll_timer.start()

func _poll_rembg() -> void:
	if _rembg_pid <= 0:
		if _rembg_poll_timer: _rembg_poll_timer.stop()
		return
	if OS.is_process_running(_rembg_pid):
		return
	var pid: int = _rembg_pid
	_rembg_pid = -1
	if _rembg_poll_timer: _rembg_poll_timer.stop()
	var exit_code: int = OS.get_process_exit_code(pid)
	_rembg_completed(exit_code, _rembg_output_tmp)

func _rembg_completed(exit_code: int, out_path: String) -> void:
	_ai_btn.disabled = false
	_apply_btn.disabled = false
	if exit_code != 0 or not FileAccess.file_exists(out_path):
		_status_label.text = "[AI NG] rembg exit=%d (stderr は Godot コンソール参照)" % exit_code
		print("[BgRemovalEditor] rembg failed exit=%d, out=%s exists=%s" % [exit_code, out_path, FileAccess.file_exists(out_path)])
		return
	var img := Image.new()
	var err: int = img.load(out_path)
	if err != OK:
		_status_label.text = "[AI NG] 出力読込失敗 (err=%d)" % err
		return
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	if img.get_width() != _img_size.x or img.get_height() != _img_size.y:
		img.resize(_img_size.x, _img_size.y, Image.INTERPOLATE_LANCZOS)
	_snapshot_for_undo()
	_current = img
	_rebuild_texture()
	_status_label.text = "🤖 AI 除去 完了"

# --- 保存 / キャンセル -----------------------------------------

func _on_apply_pressed() -> void:
	if not _current:
		return
	applied.emit(_current)

func _on_cancel_pressed() -> void:
	# 実行中の rembg があれば kill してから閉じる (待機しない)
	if _rembg_pid > 0:
		if OS.is_process_running(_rembg_pid):
			OS.kill(_rembg_pid)
		_rembg_pid = -1
	if _rembg_poll_timer:
		_rembg_poll_timer.stop()
	cancelled.emit()

func _exit_tree() -> void:
	if _rembg_pid > 0:
		if OS.is_process_running(_rembg_pid):
			OS.kill(_rembg_pid)
		_rembg_pid = -1
	if _rembg_poll_timer:
		_rembg_poll_timer.stop()
	for p in [_rembg_input_tmp, _rembg_output_tmp]:
		if not p.is_empty() and FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
