extends SceneTree
# バトル編集の立ち絵直接操作（クリック選択 / ドラッグ移動 / ホイール拡縮）と、
# ドロップ差し替えのパス書き換えを検証する。
#
# 更新は必ずスライダー経由であること。スライダーは _save_battle_edit の真実源なので、
# rect だけ動かすと「画面では動いたのに保存されない」状態になる。
# また操作レイヤは編集パネルより下に居ること（上に来るとスライダーやボタンが押せない）。
#
# 実行: Godot --path godot --headless --script res://tests/RunBattleEditPortraitDrag.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		printerr("[BDRAG] PASS: %s" % msg)
	else:
		_fails += 1
		printerr("[BDRAG] FAIL: %s" % msg)

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

func _read(res_path: String) -> String:
	var f := FileAccess.open(res_path, FileAccess.READ)
	if not f:
		return ""
	var t := f.get_as_text()
	f.close()
	return t

func _write(res_path: String, content: String) -> void:
	var f := FileAccess.open(res_path, FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()

func _initialize() -> void:
	printerr("[BDRAG] start")
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	# プロローグのイベントバトルを編集モードで開く
	var ch_info := {}
	for info in main_inst.EVENT_BATTLE_CHAPTERS:
		if info.get("mode", "") == "battle":
			ch_info = info
			break
	if ch_info.is_empty():
		printerr("[BDRAG] FAIL: イベントバトル章が見つからない")
		quit(1)
		return
	var chapter_file: String = ch_info.get("path", "")
	var snapshot := _read(chapter_file)

	main_inst._run_event_battle_edit(ch_info)
	for _w in range(150):
		await process_frame

	_check(main_inst._battle_edit_active, "バトル編集が起動している")
	var panel = main_inst._battle_edit_panel
	_check(panel != null, "編集パネルが存在する")

	# --- 操作レイヤの位置関係 ---
	var layer: Control = main_inst._battle_edit_drag_layer()
	_check(layer != null, "BattleEditDragLayer が作られる")
	if layer == null or panel == null:
		_write(chapter_file, snapshot)
		quit(1)
		return
	_check(layer.get_index() < panel.get_index(),
		"操作レイヤが編集パネルより下にある (layer=%d panel=%d)" % [layer.get_index(), panel.get_index()])
	# 実マウス入力は gui_input 経由なので、層が画面全面を占めていないとイベントが来ない。
	var vp0: Vector2 = main_inst.get_viewport_rect().size
	_check(layer.size.is_equal_approx(vp0), "操作レイヤが全面を占める (got %s / vp %s)" % [layer.size, vp0])

	var rect: TextureRect = main_inst._battle_edit_current_rect()
	_check(rect != null and rect.texture != null, "編集対象の立ち絵が取れる")
	if rect == null or rect.texture == null:
		_write(chapter_file, snapshot)
		quit(1)
		return

	var sl: Dictionary = main_inst._battle_edit_sl
	_check(not sl.is_empty(), "スライダーが bind されている")

	# --- 基準座標が _on_battle_slider の式と一致すること ---
	# ここがズレるとホイール拡縮でカーソルを固定できない
	main_inst._battle_edit_apply_transform(sl.scale.value, 0.0, 0.0)
	await process_frame
	var base0: Vector2 = main_inst._battle_edit_base_pos(rect, sl.scale.value)
	_check(rect.position.is_equal_approx(base0), "X=Y=0 のとき rect が基準座標に一致する")

	# --- クリックで選択 ---
	var center: Vector2 = rect.get_global_rect().get_center()
	main_inst._on_battle_edit_portrait_input(_mb(MOUSE_BUTTON_LEFT, true, center))
	_check(main_inst._battle_edit_selected_rect == rect, "立ち絵をクリックすると選択される")

	# --- ドラッグで X / Y ---
	var x0: float = sl.x.value
	var y0: float = sl.y.value
	main_inst._on_battle_edit_portrait_input(_mm(center + Vector2(35, -20)))
	await process_frame
	_check(is_equal_approx(sl.x.value, x0 + 35.0), "ドラッグで X スライダーが +35 (got %.1f)" % (sl.x.value - x0))
	_check(is_equal_approx(sl.y.value, y0 - 20.0), "ドラッグで Y スライダーが -20 (got %.1f)" % (sl.y.value - y0))
	var base1: Vector2 = main_inst._battle_edit_base_pos(rect, sl.scale.value)
	_check(rect.position.is_equal_approx(base1 + Vector2(sl.x.value, sl.y.value)), "rect の位置がスライダー値と一致する")

	main_inst._on_battle_edit_portrait_input(_mb(MOUSE_BUTTON_LEFT, false, center))
	var x1: float = sl.x.value
	main_inst._on_battle_edit_portrait_input(_mm(center + Vector2(200, 0)))
	await process_frame
	_check(is_equal_approx(sl.x.value, x1), "ボタンを離した後のマウス移動では動かない")

	# --- ホイールで拡縮（カーソル固定）---
	var s0: float = sl.scale.value
	var cursor: Vector2 = rect.get_global_rect().get_center()
	var u: Vector2 = (cursor - rect.position) / s0
	main_inst._on_battle_edit_portrait_input(_mb(MOUSE_BUTTON_WHEEL_UP, true, cursor))
	await process_frame
	_check(sl.scale.value > s0, "ホイール上でスケールが増える (%.2f -> %.2f)" % [s0, sl.scale.value])
	var anchored: Vector2 = rect.position + u * sl.scale.value
	_check(anchored.distance_to(cursor) < 1.5, "拡大してもカーソル下の点が動かない (ズレ %.2fpx)" % anchored.distance_to(cursor))

	var s1: float = sl.scale.value
	main_inst._on_battle_edit_portrait_input(_mb(MOUSE_BUTTON_WHEEL_DOWN, true, cursor))
	await process_frame
	_check(sl.scale.value < s1, "ホイール下でスケールが減る")
	for i in range(300):
		main_inst._on_battle_edit_portrait_input(_mb(MOUSE_BUTTON_WHEEL_UP, true, cursor))
	await process_frame
	_check(sl.scale.value <= sl.scale.max_value + 0.001, "スケールが上限を超えない (max=%.2f got %.2f)" % [sl.scale.max_value, sl.scale.value])

	# --- ドロップ差し替え: 章ソースのパス書き換え ---
	var old_res: String = rect.texture.resource_path
	var elog: Array = main_inst._battle_edit_get_log()
	var idx: int = main_inst._battle_edit_history_idx
	if idx < 0:
		idx = elog.size() - 1
	var src_id: String = elog[idx].get("edit_source_id", "") if idx >= 0 and idx < elog.size() else ""
	_check(not src_id.is_empty(), "差し替え対象の呼び出し位置が記録されている (%s)" % src_id)
	if not src_id.is_empty() and not old_res.is_empty():
		var img := Image.create(24, 48, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 1, 0, 1))
		main_inst._battle_edit_apply_edited_image(rect, old_res, img)
		await process_frame
		var new_res: String = rect.texture.resource_path
		_check(new_res != old_res, "rect が新しい別名ファイルを指す (%s)" % new_res.get_file())
		_check(FileAccess.file_exists(new_res), "新しい PNG が保存されている")
		var body := _read(chapter_file)
		_check(body.contains(new_res), "章ソースが新パスを参照する")
		_check(elog[idx].get("texture_path", "") == new_res, "portrait_log も新パスへ追従する")
		# 後片付け: 生成した PNG と .import を消す
		DirAccess.remove_absolute(ProjectSettings.globalize_path(new_res))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(new_res + ".import"))

	# 章ソースを元に戻す（run_regression.sh も退避するが、単体実行でも汚さない）
	_write(chapter_file, snapshot)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(chapter_file + ".bak"))
	printerr("[BDRAG] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
