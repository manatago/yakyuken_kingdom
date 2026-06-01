extends SceneTree
# ストーリー編集の保存「キー追加」でカンマ抜け／二重カンマが起きないことを検証する。
# Main.gd の _story_edit_dict_last_char と挿入式を複製し、各種 dict 形状で
# 生成結果が valid GDScript dict としてパース可能か確認する。
# （Main.gd は autoload GameState 依存で --script 単独 preload 不可のためロジックを複製）
# 実行: Godot --path godot --headless --script res://tests/RunDictInsertCommaFix.gd

var _pass := 0
var _fail := 0
func _ck(c, m):
	if c: _pass += 1
	else: _fail += 1
	printerr("[DI] %s: %s" % [("PASS" if c else "FAIL"), m])

# Main._story_edit_dict_last_char と同一実装
func _dict_last_char(file_lines: PackedStringArray, end_li: int, end_col: int) -> String:
	var li: int = end_li
	var col: int = end_col - 1
	while li >= 0:
		var s: String = file_lines[li]
		if li != end_li:
			col = s.length() - 1
		while col >= 0:
			var ch: String = s[col]
			if ch != " " and ch != "\t":
				return ch
			col -= 1
		li -= 1
	return ""

# Main の挿入ロジックと同一の式でキーを差し込む
func _simulate_insert(line: String, insert_scale: bool, insert_pos: bool) -> String:
	var lines := PackedStringArray([line])
	var dict_end_li := 0
	var dict_end_col := line.rfind("}")
	var ln: String = lines[dict_end_li]
	var before: String = ln.substr(0, dict_end_col)
	var last_ch: String = _dict_last_char(lines, dict_end_li, dict_end_col)
	var need_comma: bool = not (last_ch == "{" or last_ch == "," or last_ch == "")
	var parts := ""
	if insert_scale: parts += '"scale": %.2f' % 0.65
	if insert_pos:
		if not parts.is_empty(): parts += ", "
		parts += '"position": [%d, %d]' % [-45, 360]
	if need_comma: parts = ", " + parts
	return before + parts + ln.substr(dict_end_col)

func _parses(dict_literal: String) -> bool:
	var src := "extends RefCounted\nfunc _t():\n\tvar d = %s\n\treturn d\n" % dict_literal
	var gd := GDScript.new()
	gd.source_code = src
	return gd.reload() == OK

func _initialize():
	# last_char 単体
	_ck(_dict_last_char(PackedStringArray(['{"a": 1}']), 0, 7) == "1", "last_char: 値の直後=1")
	_ck(_dict_last_char(PackedStringArray(['{}']), 0, 1) == "{", "last_char: 空dict={")
	_ck(_dict_last_char(PackedStringArray(['{"a": 1,', '\t"b": 2,', '}']), 2, 0) == ",", "last_char: 複数行末尾カンマ=,")
	_ck(_dict_last_char(PackedStringArray(['{', '\t"b": 2', '}']), 2, 0) == "2", "last_char: 複数行カンマ無し=2")

	# 挿入結果がパース可能か（旧バグの再現ケース）
	var cases := [
		['{"scale": 0.46, "side": "right", "flip": 0}', false, true],  # 367型: posのみ追加
		['{"side": "left"}', true, true],                              # 383型: scale+pos
		['{}', true, true],                                            # 空dict
		['{"scale": 0.5,}', false, true],                             # 末尾カンマ済→二重防止
		['{\n\t"side": "right"\n}', false, true],                    # 複数行カンマ無し
	]
	for c in cases:
		var out := _simulate_insert(c[0], c[1], c[2])
		_ck(_parses(out), "挿入結果パース可: %s" % out.replace("\n", "\\n"))

	printerr("[DI] === %d passed, %d failed ===" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
