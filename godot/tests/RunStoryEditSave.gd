extends SceneTree
# ストーリー編集の保存をエンドツーエンドで検証する。
# 1. プロローグの story edit を起動
# 2. 数フレーム待って初期セットアップ完了
# 3. 表示中の card に bound_rect があるか確認
# 4. スライダーを既知値へ
# 5. 保存ボタンを emit → InfoLabel に [保存] が出るか・ファイルが書き換わるか
# 6. 元へ戻す
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSave.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[SS] PASS: %s" % msg)
	else:
		printerr("[SS] FAIL: %s" % msg)
		_fails += 1

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _find_visible_card(layout: Control) -> PanelContainer:
	for name in ["StoryEditCard_Left", "StoryEditCard_Right"]:
		var c: PanelContainer = layout.find_child(name, true, false)
		if c and c.visible and c.has_meta("bound_rect"):
			var r = c.get_meta("bound_rect")
			if is_instance_valid(r):
				return c
	return null

func _initialize():
	printerr("[SS] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# プロローグの story_edit を fire-and-forget で開始
	var entry := {"id": "prologue", "name": "プロローグ"}
	var src_file := "res://story/chapters/PrologueChapter.gd"
	var snapshot := _read(src_file)
	# registry 移行後、プロローグの登録画像は scale/position を PortraitLayout.gd へ保存する。
	# 章ソースではなく registry が書き換わるため、registry もスナップショット＆復元する。
	var reg_file := "res://story/PortraitLayout.gd"
	var reg_snapshot := _read(reg_file)

	var done: Array = [false]
	var coro = func():
		await main_inst._run_story_edit(entry)
		done[0] = true
	coro.call()

	# 初期セットアップが終わるまで十分待つ
	for _w in range(120): await process_frame

	# StoryEditRoot を探す
	var layout: Control = null
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			layout = child
			break
	_check(layout != null, "StoryEditRoot exists")
	if not layout:
		quit(1)
		return

	# 表示中のカードを探す
	var card: PanelContainer = _find_visible_card(layout)
	_check(card != null, "at least one visible card with bound rect")

	if card:
		var bound_side: String = card.get_meta("bound_side", "")
		var bound_rect = card.get_meta("bound_rect", null)
		printerr("[SS] card bound_side=%s rect=%s" % [bound_side, bound_rect])

		# portrait_log を確認
		var plog: Array = main_inst.story_scene_instance.portrait_log if main_inst.story_scene_instance else []
		printerr("[SS] portrait_log size=%d" % plog.size())
		for i in range(plog.size()):
			var e = plog[i]
			printerr("[SS]   entry %d: side=%s rect=%s src=%s" % [i, e.get("side", "?"), e.get("rect", null), e.get("edit_source_id", "")])

		var sl: Dictionary = main_inst._get_edit_sliders(card)
		sl.scale.value = 0.91
		sl.x.value = 33
		sl.y.value = -44
		for _w in range(4): await process_frame

		var save_btn: Button = card.find_child("SaveBtn", true, false)
		_check(save_btn != null, "card has SaveBtn")
		if save_btn:
			save_btn.pressed.emit()
			for _w in range(5): await process_frame
			var info: Label = card.find_child("InfoLabel", true, false)
			var info_text: String = info.text if info else ""
			printerr("[SS] save InfoLabel: %s" % info_text)
			_check(info_text.begins_with("[保存]"), "save reported success (got '%s')" % info_text)

			# 保存先は「章ソース」か「registry(PortraitLayout.gd)」のどちらか。
			# registry 登録画像（プロローグの大半）は registry 側に書かれるので両方を見る。
			var after := _read(src_file)
			var after_reg := _read(reg_file)
			var has_scale: bool = ('"scale": 0.91' in after) or ('"portrait_scale": 0.91' in after) \
				or ('"scale": 0.91' in after_reg)
			var has_pos: bool = ('"position": [33, -44]' in after) or ('"position": [33, -44]' in after_reg)
			printerr("[SS] scale 0.91 = %s, position [33,-44] = %s (src or registry)" % [has_scale, has_pos])
			_check(has_scale, "scale 0.91 が章ソースか registry に書かれた")
			_check(has_pos, "position [33, -44] が章ソースか registry に書かれた")

	# 編集モードを終了
	var nav_bar: PanelContainer = layout.find_child("StoryEditNavBar", true, false)
	if nav_bar:
		var exit_btn: Button = nav_bar.find_child("ExitBtn", true, false)
		if exit_btn:
			exit_btn.pressed.emit()
			for _w in range(30): await process_frame

	_write(src_file, snapshot)
	_write(reg_file, reg_snapshot)
	printerr("[SS] (files restored), fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
