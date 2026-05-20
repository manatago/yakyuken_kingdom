extends SceneTree
# ランダムバトル編集: 同一セッションでの「保存 → 再オープン」が反映されるかを検証。
# EncounterDatabase.gd の強制再パースが効いているかを確認する。

const GameStateScript := preload("res://game/GameState.gd")

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

# _run_char_edit_test と同じ「保存→再オープンで反映」経路を直接叩く簡易版。
# 実装側は _run_char_edit_test の冒頭で encounter_data を最新値に差し替えている。
# ここでは差し替え後の dict が更新値を含むかどうかで判定する。
func _initialize():
	printerr("[RR] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	var file_path := "res://encounter/EncounterDatabase.gd"
	var snapshot := _read(file_path)

	# 初期値を取得
	var initial_script: GDScript = main_inst._load_script_fresh(file_path)
	var initial_db = initial_script.new()
	var enc_id := "thug_a"
	var initial_data: Dictionary = initial_db.get_char(enc_id)
	var initial_scale: float = initial_data.get("portraits", {}).get("battle", {}).get("scale", -1.0)
	printerr("[RR] before save: thug_a/battle scale=%.2f" % initial_scale)

	# ファイルを直接書き換えてシミュレート（実機では _save_battle_edit が同じことをする）
	# thug_a/battle の scale を 0.83 へ
	var text: String = snapshot
	var lines: PackedStringArray = text.split("\n")
	var enc_line: int = -1
	for i in range(lines.size()):
		if '"%s":' % enc_id in lines[i] and "{" in lines[i]:
			enc_line = i; break
	for j in range(enc_line, min(enc_line + 100, lines.size())):
		if '"battle":' in lines[j] and "{" in lines[j]:
			# その下数行内の scale を書き換え
			for k in range(j, min(j + 5, lines.size())):
				if '"scale"' in lines[k]:
					var r := RegEx.new(); r.compile('"scale":\\s*[\\d.]+')
					lines[k] = r.sub(lines[k], '"scale": 0.83')
					break
			break
	_write(file_path, "\n".join(lines))
	printerr("[RR] file written with scale=0.83")

	# 同一セッション中に再フェッチ → 反映確認
	var reopen_script: GDScript = main_inst._load_script_fresh(file_path)
	var reopen_db = reopen_script.new()
	var reopen_data: Dictionary = reopen_db.get_char(enc_id)
	var reopen_scale: float = reopen_data.get("portraits", {}).get("battle", {}).get("scale", -1.0)
	printerr("[RR] after reopen: thug_a/battle scale=%.2f" % reopen_scale)

	if abs(reopen_scale - 0.83) < 0.001:
		printerr("[RR] PASS: random reopen reflects saved value")
	else:
		printerr("[RR] FAIL: reopen still shows %.2f (expected 0.83)" % reopen_scale)

	_write(file_path, snapshot)
	printerr("[RR] (file restored)")
	quit(0)
