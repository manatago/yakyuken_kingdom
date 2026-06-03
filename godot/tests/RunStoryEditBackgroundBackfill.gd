extends SceneTree
# ストーリー編集をラベル途中から開いた時の「背景の取りこぼし」回帰テスト。
#
# 背景は background() を呼んだ時だけ切り替わり、呼ばなければ直前の背景を引き継ぐ。
# 編集モードをラベル開始で開くと、そのラベルより前の background() を再生しないため、
# 何も対策しないと前画面の残骸（例: 大学キャンパス bg01_university）が背景に居座る。
# Main._story_edit_apply_preceding_background がラベル直前の直近 background() を補完する。
#
# プロローグの "tutorial_start" ラベルは直後に background() が無く、前の bg05_prison_cell を
# 引き継ぐ。編集をこのラベルで開いた直後、background_rect が bg05_prison_cell になっていることを
# 確認する（残骸 = 別シーンの背景ではないこと）。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditBackgroundBackfill.gd

const GameStateScript := preload("res://game/GameState.gd")
const EXPECT_BG := "bg05_prison_cell"
# 「残骸」として誤って残りがちな別シーン背景。これになっていたら回帰。
const STALE_BG := "bg01_university"

var _fails: int = 0
func _check(c, m):
	if c:
		printerr("[BGBF] PASS: %s" % m)
	else:
		printerr("[BGBF] FAIL: %s" % m)
		_fails += 1

func _initialize():
	printerr("[BGBF] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# プロローグの "tutorial_start" ラベルから編集を開く（背景指定が直後に無いシーン）
	var entry := {"id": "prologue", "label": "tutorial_start", "name": "チュートリアル"}
	var coro = func():
		await main_inst._run_story_edit(entry)
	coro.call()

	# 初期セットアップ完了まで待つ
	for _w in range(120): await process_frame

	var sc = main_inst.story_scene_instance
	_check(sc != null, "story_scene_instance exists")
	if not sc:
		quit(1); return

	var bg_rect = sc.background_rect
	var bg_path: String = ""
	if bg_rect and bg_rect.texture and bg_rect.texture.resource_path:
		bg_path = bg_rect.texture.resource_path
	printerr("[BGBF] background_rect.texture = '%s'" % bg_path)

	_check(not bg_path.is_empty(), "背景が空でない（補完が効いている）")
	_check(EXPECT_BG in bg_path, "引き継ぎ背景 '%s' が表示されている (got '%s')" % [EXPECT_BG, bg_path.get_file()])
	_check(not (STALE_BG in bg_path), "別シーンの残骸 '%s' が出ていない" % STALE_BG)

	# 終了
	var layout: Control = null
	for child in main_inst.get_children():
		if child is Control and child.name == "StoryEditRoot":
			layout = child
			break
	if layout:
		var nav_bar: PanelContainer = layout.find_child("StoryEditNavBar", true, false)
		if nav_bar:
			var exit_btn: Button = nav_bar.find_child("ExitBtn", true, false)
			if exit_btn:
				exit_btn.pressed.emit()
				for _w in range(20): await process_frame

	printerr("[BGBF] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
