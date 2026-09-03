extends TestSuite
class_name PortraitImportCacheTests

# 実行中のゲームが立ち絵を新規保存したとき、同名ファイルの古いインポート
# キャッシュ (.import / .ctex / .md5) が残っていると load() がそちらを返す。
# ファイル名・resource_path・ログはすべて新しいままなので、画面の絵だけが古い、
# という形でしか気付けない。書き出し時に必ず潰すことを固定する。

const ImportCache := preload("res://game/PortraitImportCache.gd")
const MAIN_PATH := "res://game/Main.gd"

var _tmp_dir: String = ""
var _img_res: String = ""

func get_name() -> String:
	return "PortraitImportCache"

func get_tests() -> Array:
	return [
		{"name": "purge_removes_import_and_generated_files", "callable": Callable(self, "_test_purge")},
		{"name": "purge_is_noop_without_import", "callable": Callable(self, "_test_purge_noop")},
		{"name": "purge_keeps_the_image_itself", "callable": Callable(self, "_test_keeps_image")},
		{"name": "main_purges_after_saving_new_variant", "callable": Callable(self, "_test_main_purges")},
	]

func before_each() -> void:
	_tmp_dir = "user://portrait_import_cache_tests"
	DirAccess.make_dir_recursive_absolute(_tmp_dir)
	DirAccess.make_dir_recursive_absolute(_tmp_dir.path_join("imported"))
	_img_res = _tmp_dir.path_join("sample.png")

func after_each() -> void:
	var d := DirAccess.open(_tmp_dir)
	if not d:
		return
	for sub in d.get_directories():
		var sd := DirAccess.open(_tmp_dir.path_join(sub))
		if sd:
			for f in sd.get_files():
				DirAccess.remove_absolute(_tmp_dir.path_join(sub).path_join(f))
	for f in d.get_files():
		DirAccess.remove_absolute(_tmp_dir.path_join(f))

# ---------- helpers ----------

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _make_image() -> void:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	img.save_png(_img_res)

# 実際の .import と同じ体裁（[remap] path と [deps] dest_files）で偽の
# インポート済みキャッシュを作る。
func _make_stale_import() -> Array:
	var ctex: String = _tmp_dir.path_join("imported/sample.png-deadbeef.ctex")
	var md5: String = _tmp_dir.path_join("imported/sample.png-deadbeef.md5")
	_write(ctex, "stale texture bytes")
	_write(md5, 'source_md5="00000000000000000000000000000000"')
	_write(_img_res + ".import", "[remap]\n\npath=\"%s\"\n\n[deps]\n\ndest_files=[\"%s\"]\n" % [ctex, ctex])
	return [ctex, md5]

func _read_raw(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return ""
	var t := f.get_as_text()
	f.close()
	return t

# ---------- tests ----------

func _test_purge() -> bool:
	_make_image()
	var made: Array = _make_stale_import()
	if not expect_true(FileAccess.file_exists(_img_res + ".import"), "前提: .import を用意できていない"):
		return false
	var removed: int = ImportCache.purge(_img_res)
	if not expect_true(removed >= 3, "削除数が足りない (.import + .ctex + .md5 で3以上, got %d)" % removed):
		return false
	if not expect_false(FileAccess.file_exists(_img_res + ".import"), ".import が残っている"):
		return false
	for p in made:
		if not expect_false(FileAccess.file_exists(p), "生成物が残っている: %s" % p):
			return false
	return expect_true(true)

func _test_purge_noop() -> bool:
	_make_image()
	return expect_equals(ImportCache.purge(_img_res), 0, ".import が無いのに何か消している")

# 画像そのものは消さないこと（消すと差し替えたばかりの絵が失われる）。
func _test_keeps_image() -> bool:
	_make_image()
	_make_stale_import()
	ImportCache.purge(_img_res)
	return expect_true(FileAccess.file_exists(_img_res), "画像本体まで消している")

# 新しい立ち絵を書き出す経路が purge を通ること。
# save_png しただけで放置すると、同名の古い .ctex を load() が返し続ける。
func _test_main_purges() -> bool:
	var src := _read_raw(MAIN_PATH)
	if src.is_empty():
		return fail("Main.gd を読めない")
	if not expect_true(src.contains('preload("res://game/PortraitImportCache.gd")'), "Main.gd が PortraitImportCache.gd を preload していない"):
		return false
	var lines := src.split("\n")
	var save_idx := -1
	for i in range(lines.size()):
		if lines[i].contains("final_image.save_png("):
			save_idx = i
			break
	if not expect_true(save_idx >= 0, "final_image.save_png( の呼び出しが見つからない"):
		return false
	# 保存直後（同じ関数内の近傍）で purge していること
	var window: String = "\n".join(lines.slice(save_idx, min(save_idx + 15, lines.size())))
	return expect_true(window.contains("PortraitImportCacheScript.purge("),
		"新規立ち絵の保存直後に古いインポートキャッシュを潰していない")
