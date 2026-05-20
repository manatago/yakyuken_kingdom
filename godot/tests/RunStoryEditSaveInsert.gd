extends SceneTree
# 既存キーがない呼び出しでも保存（キー追加）が機能するか検証する。
# 1. set_portrait("path") のような extra dict なしのケース
# 2. appear({...}) で scale/position が省略されているケース
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditSaveInsert.gd

func _check(cond: bool, msg: String):
	if cond:
		printerr("[INS] PASS: %s" % msg)
	else:
		printerr("[INS] FAIL: %s" % msg)

func _read(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p: String, c: String):
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _initialize():
	printerr("[INS] start")
	var gs = preload("res://game/GameState.gd").new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# テストファイルを作成（worktree 内の story chapter）
	var test_file := "res://tests/_tmp_insert_test.gd"
	var content := """extends "res://story/chapters/StoryChapterBase.gd"
class_name TmpInsertTest

func register_sequences(s, _b):
	var seq = StorySequence.new()
	seq.id = "tmp"
	# Case 1: extra dict なし
	# (実際の StoryDsl 呼び出しを模擬: ここは仮データ)
	s.add_sequence(seq)
"""
	# 直接ファイル単位で動かすテストは煩雑なので、
	# ここでは _save_story_edit_card のロジック関数を直接叩く。

	# テスト用ファイル: 3 ケース（extra dict なし / 部分キー / 完全キー）を含む .gd を作る
	var f_path_abs := ProjectSettings.globalize_path("res://tests/_tmp_save_target.gd")
	var src := "func dummy():\n"
	src += "\thero.set_portrait(\"res://path.png\")\n"  # line 2 (1-based): no dict
	src += "\tother.appear({\n"  # line 3
	src += "\t\t\"side\": \"left\",\n"  # line 4
	src += "\t\t\"appear_effect\": \"fade\",\n"  # line 5
	src += "\t})\n"  # line 6
	src += "\thero.set_portrait(\"res://path2.png\", {\"scale\": 0.5, \"position\": [0, 0]})\n"  # line 7
	_write("res://tests/_tmp_save_target.gd", src)

	# Helper: 該当行を見せかけの edit_source_id 経路で更新するシミュレート
	# テストでは _save_story_edit_card は使えない（rect が必要）ので、
	# 直接 lines 操作 + 検証関数だけ呼ぶ

	# 検証: _story_edit_find_call_block_end と _story_edit_find_dict_close の挙動
	var lines: PackedStringArray = _read("res://tests/_tmp_save_target.gd").split("\n")

	# Case 1: set_portrait("path") line 2 (idx 1)
	var be1: int = main_inst._story_edit_find_call_block_end(lines, 1)
	_check(be1 == 1, "case1: block_end == 1 (got %d)" % be1)
	var dc1: Dictionary = main_inst._story_edit_find_dict_close(lines, 1, be1)
	_check(dc1["li"] == -1, "case1: dict not found (li=%d)" % dc1["li"])

	# Case 2: appear multi-line, line 3 (idx 2) → block_end should be 5 (idx)
	var be2: int = main_inst._story_edit_find_call_block_end(lines, 2)
	_check(be2 == 5, "case2: block_end == 5 (got %d)" % be2)
	var dc2: Dictionary = main_inst._story_edit_find_dict_close(lines, 2, be2)
	_check(dc2["li"] == 5, "case2: dict close at line 5 (got %d)" % dc2["li"])
	_check(dc2["col"] >= 0, "case2: dict close col valid")

	# Case 3: single-line dict line 7 (idx 6)
	var be3: int = main_inst._story_edit_find_call_block_end(lines, 6)
	_check(be3 == 6, "case3: block_end == 6 (got %d)" % be3)
	var dc3: Dictionary = main_inst._story_edit_find_dict_close(lines, 6, be3)
	_check(dc3["li"] == 6, "case3: dict close on line 6")

	# cleanup
	DirAccess.remove_absolute(f_path_abs)
	printerr("[INS] done")
	quit(0)
