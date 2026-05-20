extends SceneTree
# ランダムバトル（RandomBattleChapter）の編集モード立ち絵キャプチャを検証する。
# 実行: Godot --path godot --headless --script res://tests/RunRandomBattleVerify.gd

const GameStateScript := preload("res://game/GameState.gd")

func _initialize():
	printerr("[RNDVERIFY] start")
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame
	gs.reset()
	gs.init_default_inventory()

	var db = EncounterDatabase.new()
	var enc: Dictionary = db.characters.get("thug_a", {}).duplicate(true)
	if enc.is_empty():
		printerr("[RNDVERIFY] FAIL: thug_a not found")
		quit(1); return
	enc["battle_bg"] = ""

	var chapter = RandomBattleChapter.new()
	chapter.setup_from_encounter(enc)

	var battle = load("res://BattleScene.tscn").instantiate()
	root.add_child(battle)
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle.setup({}, null, gs.inventory)
	battle.force_result_mode = true
	battle.start_battle(chapter)
	for _w in range(200):
		await process_frame

	var sc = battle._story_scene
	var log: Array = sc.portrait_log if sc and ("portrait_log" in sc) else []
	var done: bool = ("portrait_capture_done" in battle) and battle.portrait_capture_done
	printerr("[RNDVERIFY] portrait_log size=%d capture_done=%s" % [log.size(), done])
	for i in range(log.size()):
		var e: Dictionary = log[i]
		var t = e.get("texture")
		printerr("[RNDVERIFY]  #%d tex=%s scale=%.3f pos=%s" % [
			i, (t.resource_path.get_file() if t else "null"), e.get("scale", -1.0), e.get("position", Vector2.ZERO)])

	var fails := 0
	# 立ち絵キャプチャが最後まで完了（ハングしていない）
	if done:
		printerr("[RNDVERIFY] PASS: capture completed (no hang)")
	else:
		printerr("[RNDVERIFY] FAIL: capture did not complete")
		fails += 1
	# ランダムバトルは HP1・1 outfit。setup_scene は台座のみ・outfit_1 の立ち絵1箇所 → 1シーン
	if log.size() == 1:
		printerr("[RNDVERIFY] PASS: 1 portrait scene (setup_scene の重複が解消されている)")
	else:
		printerr("[RNDVERIFY] FAIL: expected 1 portrait scene, got %d" % log.size())
		fails += 1
	printerr("[RNDVERIFY] done, fails=%d" % fails)
	quit(1 if fails > 0 else 0)
