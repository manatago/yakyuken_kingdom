extends TestSuite
class_name PortraitPickerTests

# 編集モードの画像差し替えピッカーのテスト。
#
# 命名規則が崩れると、ピッカーに出るべき立ち絵が出なくなる（系統名を細かく取りすぎ）か、
# 出てはいけない別系統が混ざる（例: clothed のカードに undressing が並ぶ）。
# サムネ生成が壊れると、ピッカーを開いた瞬間にエラーで何も並ばない。
# どちらも実行時にしか踏まないので、実在のファイル名/画像で固定しておく。

const Picker := preload("res://game/PortraitPicker.gd")
const MAIN_PATH := "res://game/Main.gd"
const FIONA_CLOTHED_DIR := "res://assets/characters/main/fiona/clothed"
const SEBAS_DEFAULT_DIR := "res://assets/characters/mob/sebas/default"
const SAMPLE_PORTRAIT := "res://assets/characters/main/fiona/clothed/fiona_clothed_001.png"

func get_name() -> String:
	return "PortraitPicker"

func get_tests() -> Array:
	return [
		{"name": "prefix_of_strips_serial_and_variant_suffix", "callable": Callable(self, "_test_prefix_of")},
		{"name": "prefix_of_keeps_named_series_separate", "callable": Callable(self, "_test_prefix_keeps_series")},
		{"name": "matches_prefix_accepts_described_serials", "callable": Callable(self, "_test_matches_described")},
		{"name": "matches_prefix_rejects_other_series", "callable": Callable(self, "_test_matches_rejects")},
		{"name": "described_portraits_group_with_plain_serials", "callable": Callable(self, "_test_round_trip_between_styles")},
		{"name": "fiona_clothed_folder_lists_all_story_portraits", "callable": Callable(self, "_test_fiona_folder")},
		{"name": "sebas_default_folder_lists_all_portraits", "callable": Callable(self, "_test_sebas_folder")},
		{"name": "make_thumb_returns_downscaled_texture", "callable": Callable(self, "_test_make_thumb")},
		{"name": "make_thumb_second_call_hits_cache", "callable": Callable(self, "_test_make_thumb_cache")},
		{"name": "make_thumb_returns_null_for_missing_image", "callable": Callable(self, "_test_make_thumb_missing")},
		{"name": "main_references_picker_via_preload", "callable": Callable(self, "_test_main_preloads_picker")},
	]

# ---------- helpers ----------

func _list_images(dir_path: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir_path)
	if not d:
		return out
	for n in d.get_files():
		var lower: String = n.to_lower()
		if lower.ends_with(".png") or lower.ends_with(".jpg") or lower.ends_with(".jpeg") or lower.ends_with(".webp"):
			out.append(n)
	return out

func _read_raw(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return ""
	var txt := f.get_as_text()
	f.close()
	return txt

# ---------- 命名規則 ----------

# 連番・差し替え版・説明付き連番のいずれからでも同じ系統名が出ること。
func _test_prefix_of() -> bool:
	var cases := {
		"satoshi_isekai_007.png": "satoshi_isekai_",
		"fiona_clothed_001.png": "fiona_clothed_",
		"fiona_clothed_017_v1.png": "fiona_clothed_",
		"fiona_clothed_019_smile__waving.png": "fiona_clothed_",
		"sebas_default_001_v13.png": "sebas_default_",
		"char01_st1_017_orig.png": "char01_st1_",
	}
	for fn in cases:
		if not expect_equals(Picker.prefix_of(fn), cases[fn], "prefix_of(%s)" % fn):
			return false
	return expect_true(true)

# 名前付きの別系統（janken, undressing）は別グループのままであること。
func _test_prefix_keeps_series() -> bool:
	var cases := {
		"fiona_clothed_janken_001.png": "fiona_clothed_janken_",
		"fiona_undressing_panty_003.png": "fiona_undressing_panty_",
		"sister_head_undressing_bra_002.png": "sister_head_undressing_bra_",
	}
	for fn in cases:
		if not expect_equals(Picker.prefix_of(fn), cases[fn], "prefix_of(%s)" % fn):
			return false
	# 数字を含まない名前は厳密一致に倒れる（自分だけがマッチする）
	return expect_equals(Picker.prefix_of("machilda_undressing.png"), "machilda_undressing")

# 連番の後ろに表情/ポーズを書いたファイルも sibling として拾えること。
func _test_matches_described() -> bool:
	var prefix := "fiona_clothed_"
	for fn in ["fiona_clothed_001.png", "fiona_clothed_017_v1.png", "fiona_clothed_019_3__arms-at-sides.png", "fiona_clothed_242_worried__profile.png"]:
		if not expect_true(Picker.matches_prefix(fn, prefix), "sibling として拾えていない: %s" % fn):
			return false
	return expect_true(true)

# 同フォルダに同居する別系統を巻き込まないこと。
func _test_matches_rejects() -> bool:
	if not expect_false(Picker.matches_prefix("fiona_clothed_janken_001.png", "fiona_clothed_"), "janken 系が clothed に混ざっている"):
		return false
	if not expect_false(Picker.matches_prefix("sister_head_undressing_panty_004.png", "sister_head_clothed_"), "undressing 系が clothed に混ざっている"):
		return false
	# prefix 一致でも残りが無ければ sibling ではない
	return expect_false(Picker.matches_prefix("fiona_clothed_.png", "fiona_clothed_"))

# どちらの書き方の立ち絵を開いても、相手側が候補に出ること（対称性）。
# 説明付きの立ち絵を選んだ瞬間にピッカーが自分1枚しか出さなくなる、という
# 退行を防ぐ。
func _test_round_trip_between_styles() -> bool:
	var plain := "fiona_clothed_001.png"
	var described := "fiona_clothed_019_3__arms-at-sides.png"
	if not expect_true(Picker.matches_prefix(described, Picker.prefix_of(plain)), "連番から説明付きが見えない"):
		return false
	return expect_true(Picker.matches_prefix(plain, Picker.prefix_of(described)), "説明付きから連番が見えない")

# 実フォルダに対して、ストーリー用の立ち絵が全部ピッカーに出ること。
# fiona/clothed は janken 系（バトル専用）だけが除外されている状態を期待する。
func _test_fiona_folder() -> bool:
	return _check_folder(FIONA_CLOTHED_DIR, "fiona_clothed_001.png", "fiona_clothed_janken_")

# sebas/default は連番 001 とその差し替え版 001_vNN、および説明付きの 002_* が
# すべて同じグループに入ること（除外されるものは無い）。
func _test_sebas_folder() -> bool:
	return _check_folder(SEBAS_DEFAULT_DIR, "sebas_default_001.png", "")

# dir_path 内の画像を sample_file から導いた系統名で絞り、
#   - 拾えなかったものが allowed_excluded_prefix 系だけであること
#   - 説明付き（表情__ポーズ）の立ち絵が拾えていること
# を確認する。allowed_excluded_prefix が空なら「1枚も落ちないこと」を要求する。
func _check_folder(dir_path: String, sample_file: String, allowed_excluded_prefix: String) -> bool:
	var files := _list_images(dir_path)
	if files.is_empty():
		return fail("立ち絵が1枚も無い: %s" % dir_path)
	var prefix: String = Picker.prefix_of(sample_file)
	var matched: Array = []
	for fn in files:
		if Picker.matches_prefix(fn, prefix):
			matched.append(fn)
			continue
		if allowed_excluded_prefix.is_empty():
			return fail("%s で除外された（全部拾えるはず）: %s" % [dir_path, fn])
		if not expect_true(fn.begins_with(allowed_excluded_prefix), "想定外に除外されている: %s" % fn):
			return false
	# 旧来の連番だけでなく、説明付きの立ち絵も拾えていること
	for fn in matched:
		if fn.contains("__"):
			return expect_true(true)
	return fail("説明付きの立ち絵が1枚も拾えていない: %s" % dir_path)

# ---------- サムネ ----------

# 指定寸法まで縮小されたテクスチャが返ること。
# 元のフル解像度をそのまま返してしまうと、候補数ぶん GPU に載って破綻する。
func _test_make_thumb() -> bool:
	var cache_path: String = Picker.thumb_cache_path(SAMPLE_PORTRAIT, 200, 400)
	DirAccess.remove_absolute(cache_path)
	var thumb: Texture2D = Picker.make_thumb(SAMPLE_PORTRAIT, 200, 400)
	if not expect_true(thumb != null, "サムネが作れない: %s" % SAMPLE_PORTRAIT):
		return false
	if not expect_equals(thumb.get_width(), 200, "サムネ幅"):
		return false
	return expect_equals(thumb.get_height(), 400, "サムネ高さ")

# 2 回目は user:// のキャッシュから読むこと（240枚超のフォルダで毎回作り直さない）。
func _test_make_thumb_cache() -> bool:
	var cache_path: String = Picker.thumb_cache_path(SAMPLE_PORTRAIT, 200, 400)
	DirAccess.remove_absolute(cache_path)
	if not expect_false(FileAccess.file_exists(cache_path), "事前クリアに失敗"):
		return false
	Picker.make_thumb(SAMPLE_PORTRAIT, 200, 400)
	if not expect_true(FileAccess.file_exists(cache_path), "サムネがキャッシュされていない: %s" % cache_path):
		return false
	var again: Texture2D = Picker.make_thumb(SAMPLE_PORTRAIT, 200, 400)
	if not expect_true(again != null, "キャッシュからサムネを復元できない"):
		return false
	return expect_equals(again.get_width(), 200, "キャッシュ経由のサムネ幅")

# 読めない画像は null を返すだけで、ピッカー全体を巻き込まないこと。
func _test_make_thumb_missing() -> bool:
	var missing := "%s://%s/never_%d.png" % ["res", "zzzimaginary_dir", randi()]
	return expect_true(Picker.make_thumb(missing, 200, 400) == null, "存在しない画像で null を返していない")

# ---------- 参照方法 ----------

# Main.gd は PortraitPicker を preload 定数で参照すること。
# グローバルクラス名で書くと、エディタを通していないチェックアウトで
# 「Identifier not declared in the current scope」となり Main.gd 全体が
# パースエラーになる（.godot/global_script_class_cache.cfg は gitignore 対象）。
func _test_main_preloads_picker() -> bool:
	var src := _read_raw(MAIN_PATH)
	if src.is_empty():
		return fail("Main.gd を読めない")
	if not expect_true(src.contains('preload("res://game/PortraitPicker.gd")'), "Main.gd が PortraitPicker.gd を preload していない"):
		return false
	for line in src.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("#") or stripped.contains("preload("):
			continue
		if stripped.contains("PortraitPicker."):
			return fail("グローバルクラス名で直接参照している行がある（preload 定数を使うこと）: %s" % stripped)
	return expect_true(true)
