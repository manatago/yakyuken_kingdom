extends TestSuite
class_name SourceFileWriterTests

# 編集モードによる章ソース (.gd) 書き戻しの安全性テスト。
#
# Main.gd の 12 箇所の保存処理は、いずれも
#   f.get_as_text().split("\n") -> 行を加工 -> "\n".join(lines) を書き戻す
# という形をしている。ここが壊れると Git 管理下の章ソースが黙って失われるため、
#   (a) split/join のラウンドトリップが元の内容を保つこと
#   (b) 書き戻しがバックアップを残し、失敗時に元ファイルを壊さないこと
#   (c) Main.gd が生の FileAccess.WRITE ではなく共通ライタを通していること
# を検証する。

const SourceFileWriterScript := preload("res://game/SourceFileWriter.gd")
const MAIN_PATH := "res://game/Main.gd"

var _tmp_dir: String = ""

func get_name() -> String:
	return "SourceFileWriter"

func get_tests() -> Array:
	return [
		{"name": "split_join_roundtrip_preserves_chapter_sources", "callable": Callable(self, "_test_roundtrip")},
		{"name": "write_replaces_content", "callable": Callable(self, "_test_write_replaces_content")},
		{"name": "write_leaves_backup_of_previous_content", "callable": Callable(self, "_test_write_backup")},
		{"name": "write_leaves_no_temp_file", "callable": Callable(self, "_test_no_temp_left")},
		{"name": "write_to_unwritable_path_keeps_original", "callable": Callable(self, "_test_failure_keeps_original")},
		{"name": "main_uses_common_writer_for_sources", "callable": Callable(self, "_test_main_uses_writer")},
		{"name": "main_references_writer_via_preload", "callable": Callable(self, "_test_main_preloads_writer")},
	]

func before_each() -> void:
	_tmp_dir = OS.get_user_data_dir().path_join("source_file_writer_tests")
	DirAccess.make_dir_recursive_absolute(_tmp_dir)

func after_each() -> void:
	if _tmp_dir.is_empty():
		return
	var d := DirAccess.open(_tmp_dir)
	if d:
		for f in d.get_files():
			DirAccess.remove_absolute(_tmp_dir.path_join(f))

# ---------- helpers ----------

func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _read_raw(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return ""
	var txt := f.get_as_text()
	f.close()
	return txt

# ---------- tests ----------

# 実際の章ソースで split("\n") -> join("\n") が原文と一致すること。
# 末尾改行が落ちる/増えるといった差分が出ないことの担保。
func _test_roundtrip() -> bool:
	var chapter_dir := "res://story/chapters"
	var d := DirAccess.open(chapter_dir)
	if not d:
		return fail("章ディレクトリを開けない: %s" % chapter_dir)
	var checked := 0
	for name in d.get_files():
		if not name.ends_with(".gd"):
			continue
		var path := chapter_dir.path_join(name)
		var original := _read_raw(path)
		if original.is_empty():
			continue
		var rejoined: String = "\n".join(original.split("\n"))
		if rejoined != original:
			return fail("split/join が原文を保てない: %s" % path)
		checked += 1
	if checked == 0:
		return fail("検査対象の章ソースが1件も見つからない")
	return expect_true(true)

func _test_write_replaces_content() -> bool:
	var target := _tmp_dir.path_join("sample.gd")
	_write_raw(target, "old line 1\nold line 2\n")
	var ok: bool = SourceFileWriterScript.write(target, "new line 1\nnew line 2\n")
	if not expect_true(ok, "write が false を返した"):
		return false
	return expect_equals(_read_raw(target), "new line 1\nnew line 2\n")

func _test_write_backup() -> bool:
	var target := _tmp_dir.path_join("sample.gd")
	var original := "keep me\n"
	_write_raw(target, original)
	var ok: bool = SourceFileWriterScript.write(target, "overwritten\n")
	if not expect_true(ok, "write が false を返した"):
		return false
	var bak := target + SourceFileWriterScript.BACKUP_SUFFIX
	if not expect_true(FileAccess.file_exists(bak), "バックアップが作られていない: %s" % bak):
		return false
	return expect_equals(_read_raw(bak), original, "バックアップが書き込み前の内容と一致しない")

func _test_no_temp_left() -> bool:
	var target := _tmp_dir.path_join("sample.gd")
	_write_raw(target, "before\n")
	var ok: bool = SourceFileWriterScript.write(target, "after\n")
	if not expect_true(ok, "write が false を返した"):
		return false
	var tmp := target + SourceFileWriterScript.TEMP_SUFFIX
	return expect_false(FileAccess.file_exists(tmp), "一時ファイルが残っている: %s" % tmp)

# 一時ファイルを作れない場所を指定した場合、false を返すだけで
# 既存ファイルには手を付けないこと。
func _test_failure_keeps_original() -> bool:
	var missing_dir := _tmp_dir.path_join("no_such_dir")
	var target := missing_dir.path_join("sample.gd")
	var ok: bool = SourceFileWriterScript.write(target, "should not be written\n")
	if not expect_false(ok, "存在しないディレクトリへの write が true を返した"):
		return false
	return expect_false(FileAccess.file_exists(target), "書けないはずのパスにファイルが出来ている")

# 章ソースの書き戻しが共通ライタ経由であること。
# 生の FileAccess.WRITE + "\n".join(...) が復活したら落とす。
func _test_main_uses_writer() -> bool:
	var src := _read_raw(MAIN_PATH)
	if src.is_empty():
		return fail("Main.gd を読めない")
	if not expect_true(src.contains("SourceFileWriterScript.write("), "Main.gd が共通ライタを使っていない"):
		return false
	for line in src.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("#"):
			continue
		if stripped.contains("store_string(\"\\n\".join("):
			return fail("章ソースを共通ライタを通さず直接書いている行がある: %s" % stripped)
	return expect_true(true)

# Main.gd は他スクリプトを preload 定数で参照すること。
#
# class_name によるグローバルクラス名は、エディタがプロジェクトを走査したときに
# .godot/global_script_class_cache.cfg へ登録される。.godot/ は gitignore 対象なので、
# エディタを通さずに class_name 付きスクリプトを追加してグローバル名で参照すると、
# 「Identifier not declared in the current scope」で Main.gd 全体がパースエラーになり、
# タイトル画面のボタンが軒並み無反応になる。
#
# なお、このテストは Main.gd の全パースエラーを検出できるわけではない。
# 起動時の確定チェックは:
#   /Applications/Godot.app/Contents/MacOS/Godot --path godot --headless --quit-after 120
func _test_main_preloads_writer() -> bool:
	var src := _read_raw(MAIN_PATH)
	if src.is_empty():
		return fail("Main.gd を読めない")
	if not expect_true(src.contains('preload("res://game/SourceFileWriter.gd")'), "Main.gd が SourceFileWriter.gd を preload していない"):
		return false
	for line in src.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("#") or stripped.begins_with("const "):
			continue
		if stripped.contains("SourceFileWriter."):
			return fail("グローバルクラス名で直接参照している行がある（preload 定数を使うこと）: %s" % stripped)
	return expect_true(true)
