extends SceneTree
# 立ち絵の直接操作（クリック選択 / ドラッグ移動 / ホイール拡縮）の検証。
#
# 更新は必ずカードのスライダーを経由すること。スライダーは _save_story_edit_card の
# 真実源なので、rect だけ動かすと「画面では動いたのに保存されない」状態になる。
#
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditPortraitDrag.gd

var _fails := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		printerr("[DRAG] PASS: %s" % msg)
	else:
		_fails += 1
		printerr("[DRAG] FAIL: %s" % msg)

func _mb(button: int, pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	e.position = pos
	return e

func _mm(pos: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = pos
	return e

func _initialize() -> void:
	printerr("[DRAG] start")
	var gs = preload("res://game/GameState.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame

	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame
	main_inst._story_edit_current_seq_idx = -1

	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()

	# 右の立ち絵を「全面不透明」なテクスチャで用意する（アルファ判定を通すため）
	var img := Image.create(200, 400, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	var rect: TextureRect = sc.right_char
	rect.visible = true
	rect.texture = tex
	sc.left_char.visible = false
	sc.center_char.visible = false

	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var card: PanelContainer = layout.find_child("StoryEditCard_Right", true, false)
	main_inst._bind_story_edit_card(card, sc, "right", rect)
	await process_frame

	var drag_layer: Control = layout.find_child("PortraitDragLayer", true, false)
	_check(drag_layer != null, "PortraitDragLayer が存在する")
	if drag_layer == null:
		quit(1)
		return
	# カードより先に入力を取らないよう、パネルより手前に居ないこと
	var panels: Control = layout.find_child("EditPanelsContainer", true, false)
	_check(panels != null and drag_layer.get_index() < panels.get_index(),
		"ドラッグ層が編集パネルより下にある (layer=%d panels=%s)" % [drag_layer.get_index(), str(panels.get_index()) if panels else "?"])
	# 実マウス入力は gui_input 経由なので、層が画面全面を占めていないとイベントが来ない。
	# テストはハンドラを直接叩くため、サイズを見ておかないと 0x0 でも素通りする。
	var vp0: Vector2 = main_inst.get_viewport_rect().size
	_check(drag_layer.size.is_equal_approx(vp0), "ドラッグ層が全面を占める (got %s / vp %s)" % [drag_layer.size, vp0])

	var sl = main_inst._get_edit_sliders(card)
	main_inst._story_edit_apply_transform(card, 1.0, 0.0, 0.0)
	await process_frame

	# --- クリックで選択 ---
	var center: Vector2 = rect.get_global_rect().get_center()
	main_inst._on_story_edit_portrait_input(_mb(MOUSE_BUTTON_LEFT, true, center))
	_check(main_inst._story_edit_selected_rect == rect, "立ち絵の上をクリックすると選択される")
	_check(main_inst._story_edit_drag_card == card, "選択した立ち絵のカードが紐づく")

	# --- ドラッグで X / Y ---
	var x0: float = sl.x.value
	var y0: float = sl.y.value
	main_inst._on_story_edit_portrait_input(_mm(center + Vector2(40, -25)))
	await process_frame
	_check(is_equal_approx(sl.x.value, x0 + 40.0), "ドラッグで X スライダーが +40 (got %.1f)" % (sl.x.value - x0))
	_check(is_equal_approx(sl.y.value, y0 - 25.0), "ドラッグで Y スライダーが -25 (got %.1f)" % (sl.y.value - y0))
	# rect が実際に動いていること（スライダーだけ動いて絵が置いていかれないこと）
	var base_pos: Vector2 = main_inst._story_edit_get_base_pos(rect, sl.scale.value)
	_check(rect.position.is_equal_approx(base_pos + Vector2(sl.x.value, sl.y.value)), "rect の位置がスライダー値と一致する")

	# --- ボタンを離すとドラッグ終了 ---
	main_inst._on_story_edit_portrait_input(_mb(MOUSE_BUTTON_LEFT, false, center))
	var x1: float = sl.x.value
	main_inst._on_story_edit_portrait_input(_mm(center + Vector2(300, 0)))
	await process_frame
	_check(is_equal_approx(sl.x.value, x1), "ボタンを離した後のマウス移動では動かない")

	# --- 透明部分/外側のクリックで選択解除 ---
	main_inst._on_story_edit_portrait_input(_mb(MOUSE_BUTTON_LEFT, true, Vector2(-50, -50)))
	_check(main_inst._story_edit_selected_rect == null, "立ち絵の外をクリックすると選択が外れる")
	main_inst._on_story_edit_portrait_input(_mb(MOUSE_BUTTON_LEFT, false, Vector2(-50, -50)))

	# --- ホイールで拡縮 ---
	var s0: float = sl.scale.value
	var cursor: Vector2 = rect.get_global_rect().get_center()
	# 拡大前にカーソル下にあるテクスチャ座標を覚えておく
	var u: Vector2 = (cursor - rect.position) / s0
	main_inst._on_story_edit_portrait_input(_mb(MOUSE_BUTTON_WHEEL_UP, true, cursor))
	await process_frame
	_check(sl.scale.value > s0, "ホイール上でスケールが増える (%.2f -> %.2f)" % [s0, sl.scale.value])
	# カーソル位置が固定されていること（拡大しても掴んだ点がずれない）
	var anchored: Vector2 = rect.position + u * sl.scale.value
	_check(anchored.distance_to(cursor) < 1.5, "拡大してもカーソル下の点が動かない (ズレ %.2fpx)" % anchored.distance_to(cursor))

	var s1: float = sl.scale.value
	main_inst._on_story_edit_portrait_input(_mb(MOUSE_BUTTON_WHEEL_DOWN, true, cursor))
	await process_frame
	_check(sl.scale.value < s1, "ホイール下でスケールが減る (%.2f -> %.2f)" % [s1, sl.scale.value])

	# --- スライダー範囲を超えない ---
	for i in range(200):
		main_inst._on_story_edit_portrait_input(_mb(MOUSE_BUTTON_WHEEL_UP, true, cursor))
	await process_frame
	_check(sl.scale.value <= sl.scale.max_value + 0.001, "スケールが上限を超えない (max=%.2f got %.2f)" % [sl.scale.max_value, sl.scale.value])

	printerr("[DRAG] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
