extends SceneTree
# ランダムバトル: encounter / battle / farewell_win / farewell_lose の4区間それぞれの
# 保存が、EncounterDatabase.gd の該当エンカウント・該当ブロックだけを更新できるかを検証。
# 検証後にファイルを元へ戻す。
# 実行: Godot --path godot --headless --script res://tests/RunRandom4PortraitSave.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[FOUR] PASS: %s" % msg)
	else:
		printerr("[FOUR] FAIL: %s" % msg)
		_fails += 1

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

# 保存後の EncounterDatabase 内、thug_a/<portrait_key> ブロックの scale が
# 期待値になっているかを確認する。
func _verify_saved_scale(file_text: String, enc_id: String, portrait_key: String, expected_scale: float) -> bool:
	var lines: PackedStringArray = file_text.split("\n")
	var enc_line: int = -1
	for i in range(lines.size()):
		if ('"%s":' % enc_id) in lines[i] and "{" in lines[i]:
			enc_line = i; break
	if enc_line < 0: return false
	var key_line: int = -1
	for i in range(enc_line, min(enc_line + 100, lines.size())):
		if ('"%s":' % portrait_key) in lines[i] and "{" in lines[i]:
			key_line = i; break
	if key_line < 0: return false
	for j in range(key_line, min(key_line + 5, lines.size())):
		if '"scale"' in lines[j]:
			var expected: String = '"scale": %.2f' % expected_scale
			return expected in lines[j]
	return false

func _drive_save(portrait_key: String, scale: float, x: int, y: int):
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame
	var panel = PanelContainer.new()
	panel.set_meta("chapter_path", "res://encounter/EncounterDatabase.gd")
	panel.set_meta("encounter_id", "thug_a")
	panel.set_meta("portrait_key", portrait_key)
	root.add_child(panel)
	var info := Label.new()
	panel.add_child(info)
	main_inst._save_encounter_portrait(panel, info, scale, x, y)
	for _w in range(3): await process_frame
	printerr("[FOUR] %s -> %s" % [portrait_key, info.text])
	main_inst.queue_free()
	gs.queue_free()
	panel.queue_free()
	await process_frame; await process_frame

func _initialize():
	printerr("[FOUR] start")
	var file_path := "res://encounter/EncounterDatabase.gd"
	var snapshot := _read(file_path)
	# 期待値（ユニークなスケール値で照合）
	var keys := ["encounter", "battle", "farewell_win", "farewell_lose"]
	var scales := [0.51, 0.52, 0.53, 0.54]
	for idx in range(keys.size()):
		await _drive_save(keys[idx], scales[idx], 10 + idx, -100 - idx)
	# 保存結果を1ファイルで照合（最後の保存だけでなく、4つすべてが残っていること）
	var after := _read(file_path)
	for idx in range(keys.size()):
		var ok: bool = _verify_saved_scale(after, "thug_a", keys[idx], scales[idx])
		_check(ok, "thug_a/%s scale=%.2f written" % [keys[idx], scales[idx]])
	_write(file_path, snapshot)
	printerr("[FOUR] (file restored), fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
