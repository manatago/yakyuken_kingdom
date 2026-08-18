extends TestSuite
class_name SlideshowSourceTests

# 紙芝居 (敗北ごとの一枚絵スライド) のソース解析と行編集のテスト。
#
# ここが崩れると章ソースの別の行を書き換えてしまう。実在のバトル章に対して
# 「3ブロック取れること」「ページ数が実際の枚数と合うこと」を固定したうえで、
# 挿入・削除・並べ替えは合成ソースで境界を確認する。

const Slideshow := preload("res://battle/SlideshowSource.gd")
const FIONA := "res://battle/chapters/FionaBattleChapter.gd"

func get_name() -> String:
	return "SlideshowSource"

func get_tests() -> Array:
	return [
		{"name": "parses_three_blocks_per_battle_chapter", "callable": Callable(self, "_test_all_chapters")},
		{"name": "fiona_page_counts_match_the_artwork", "callable": Callable(self, "_test_fiona")},
		{"name": "trailing_background_is_not_a_page", "callable": Callable(self, "_test_terminator")},
		{"name": "multi_bubble_page_is_one_page", "callable": Callable(self, "_test_multi_bubble")},
		{"name": "set_page_image_rewrites_only_that_line", "callable": Callable(self, "_test_set_image")},
		{"name": "set_bubble_text_escapes_quotes_and_newlines", "callable": Callable(self, "_test_set_text")},
		{"name": "insert_page_adds_two_lines_after_target", "callable": Callable(self, "_test_insert")},
		{"name": "delete_page_removes_background_and_its_bubbles", "callable": Callable(self, "_test_delete")},
		{"name": "delete_page_keeps_the_last_remaining_page", "callable": Callable(self, "_test_delete_last")},
		{"name": "move_page_swaps_with_neighbour", "callable": Callable(self, "_test_move")},
		{"name": "bubble_side_is_parsed", "callable": Callable(self, "_test_side_parse")},
		{"name": "set_bubble_side_rewrites_existing_side", "callable": Callable(self, "_test_side_write")},
		{"name": "set_bubble_side_adds_dict_when_missing", "callable": Callable(self, "_test_side_add")},
		{"name": "every_used_side_exists_in_the_runtime_table", "callable": Callable(self, "_test_side_known")},
		{"name": "font_size_round_trips", "callable": Callable(self, "_test_font_roundtrip")},
		{"name": "font_size_zero_removes_the_override", "callable": Callable(self, "_test_font_clear")},
	]

# ---------- helpers ----------

func _sample() -> PackedStringArray:
	var t := "extends BattleChapterBase\n"                                    # 1
	t += "\n"                                                                 # 2
	t += "func outfit_3(bt):\n"                                               # 3
	t += "\tif true:\n"                                                       # 4
	t += "\t\tbt.set_battle_ui_visible(false)\n"                              # 5
	t += "\t\tbt.background(\"res://a_001.png\")\n"                           # 6
	t += "\t\tbt.bubble(\"one\", {\"side\": \"right\"})\n"                    # 7
	t += "\t\tbt.background(\"res://a_002.png\")\n"                           # 8
	t += "\t\tbt.bubble(\"two\", {\"side\": \"right\"})\n"                    # 9
	t += "\t\tbt.bubble(\"two-b\", {\"side\": \"right\"})\n"                  # 10
	t += "\t\tbt.background(\"res://room.png\")\n"                            # 11
	t += "\t\tbt.set_battle_ui_visible(true)\n"                               # 12
	return t.split("\n")

func _block0(lines: PackedStringArray) -> Dictionary:
	var b := Slideshow.parse_blocks(lines)
	return b[0] if not b.is_empty() else {}

func _join(lines: PackedStringArray) -> String:
	return "\n".join(lines)

# ---------- 実ソースに対する固定 ----------

func _test_all_chapters() -> bool:
	var d := DirAccess.open("res://battle/chapters")
	if not d:
		return fail("battle/chapters を開けない")
	var checked := 0
	for name in d.get_files():
		if not name.ends_with(".gd"):
			continue
		var lines := Slideshow.read_lines("res://battle/chapters/" + name)
		if lines.is_empty():
			continue
		var blocks := Slideshow.parse_blocks(lines)
		if blocks.is_empty():
			continue  # ミニゲーム章など紙芝居を持たないもの
		if not expect_equals(blocks.size(), 3, "%s の紙芝居ブロック数" % name):
			return false
		# 1敗目/2敗目/3敗目が割り当たること
		var seen := {}
		for b in blocks:
			seen[b["loss_index"]] = true
			# 章によっては belka_outfit_3 のように接頭辞が付く
			if not expect_true(b["func_name"].contains("outfit_"), "%s: outfit 関数の外で検出している (%s)" % [name, b["func_name"]]):
				return false
			if not expect_true((b["pages"] as Array).size() > 0, "%s: ページ0件のブロック" % name):
				return false
		if not expect_true(seen.has(1) and seen.has(2) and seen.has(3), "%s: 1〜3敗目が揃わない" % name):
			return false
		checked += 1
	return expect_true(checked >= 5, "検査したバトル章が少なすぎる (got %d)" % checked)

# フィオナは服4枚 / ブラ5枚 / パンツ13枚。
func _test_fiona() -> bool:
	var blocks := Slideshow.parse_blocks(Slideshow.read_lines(FIONA))
	if not expect_equals(blocks.size(), 3, "フィオナのブロック数"):
		return false
	var by_loss := {}
	for b in blocks:
		by_loss[b["loss_index"]] = (b["pages"] as Array).size()
	if not expect_equals(by_loss.get(1, -1), 4, "1敗目 (outfit_3) のページ数"):
		return false
	if not expect_equals(by_loss.get(2, -1), 5, "2敗目 (outfit_2) のページ数"):
		return false
	return expect_equals(by_loss.get(3, -1), 13, "3敗目 (outfit_1) のページ数")

# ---------- 合成ソースに対する境界 ----------

func _test_terminator() -> bool:
	var b := _block0(_sample())
	if not expect_equals((b["pages"] as Array).size(), 2, "ページ数 (背景復帰行を除く)"):
		return false
	return expect_equals(b["terminator_line"], 11, "背景復帰行の行番号")

func _test_multi_bubble() -> bool:
	var b := _block0(_sample())
	var pages: Array = b["pages"]
	if not expect_equals((pages[0]["bubbles"] as Array).size(), 1, "1ページ目のセリフ数"):
		return false
	return expect_equals((pages[1]["bubbles"] as Array).size(), 2, "2ページ目のセリフ数 (1枚に2セリフ)")

func _test_set_image() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	var before := _join(lines)
	if not expect_true(Slideshow.set_page_image(lines, b["pages"][1], "res://new.png"), "set_page_image が false"):
		return false
	if not expect_equals(lines[7], "\t\tbt.background(\"res://new.png\")", "対象行が書き換わる"):
		return false
	if not expect_equals(lines[5], "\t\tbt.background(\"res://a_001.png\")", "別ページの背景は無傷"):
		return false
	return expect_equals(lines.size(), before.split("\n").size(), "行数が変わらない")

func _test_set_text() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	if not expect_true(Slideshow.set_bubble_text(lines, b["pages"][0]["bubbles"][0], "あ\"い\"\nう"), "set_bubble_text が false"):
		return false
	if not expect_equals(lines[6], "\t\tbt.bubble(\"あ\\\"い\\\"\\nう\", {\"side\": \"right\"})", "クォートと改行がエスケープされる"):
		return false
	# 書き戻したものを読み直して元に戻ること
	var b2 := _block0(lines)
	return expect_equals(b2["pages"][0]["bubbles"][0]["text"], "あ\"い\"\nう", "読み直しで元のテキストに戻る")

func _test_insert() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	if not expect_true(Slideshow.insert_page(lines, b, 0, "res://ins.png", "ins"), "insert_page が false"):
		return false
	if not expect_equals(lines.size(), _sample().size() + 2, "2行増える"):
		return false
	# 1ページ目のセリフ(7行目)の直後に入る
	if not expect_equals(lines[7], "\t\tbt.background(\"res://ins.png\")", "挿入位置が対象ページの直後"):
		return false
	if not expect_equals(lines[8], "\t\tbt.bubble(\"ins\", {\"side\": \"right\"})", "セリフ行の書式を既存から引き継ぐ"):
		return false
	var b2 := _block0(lines)
	return expect_equals((b2["pages"] as Array).size(), 3, "ページが1枚増える")

func _test_delete() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	# 2ページ目 = background + bubble 2本 = 3行
	if not expect_true(Slideshow.delete_page(lines, b, 1), "delete_page が false"):
		return false
	if not expect_equals(lines.size(), _sample().size() - 3, "3行減る (背景1 + セリフ2)"):
		return false
	var b2 := _block0(lines)
	if not expect_equals((b2["pages"] as Array).size(), 1, "ページが1枚減る"):
		return false
	return expect_equals(b2["terminator_line"], 8, "背景復帰行が残る")

func _test_delete_last() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	Slideshow.delete_page(lines, b, 1)
	var b2 := _block0(lines)
	return expect_false(Slideshow.delete_page(lines, b2, 0), "最後の1枚は削除できてしまっている")

func _test_move() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	if not expect_true(Slideshow.move_page(lines, b, 0, 1), "move_page が false"):
		return false
	var b2 := _block0(lines)
	var pages: Array = b2["pages"]
	if not expect_equals(pages[0]["bg_path"], "res://a_002.png", "2枚目が先頭に来る"):
		return false
	if not expect_equals((pages[0]["bubbles"] as Array).size(), 2, "セリフ2本も一緒に移動する"):
		return false
	return expect_equals(pages[1]["bg_path"], "res://a_001.png", "1枚目が後ろへ下がる")

func _test_side_parse() -> bool:
	var b := _block0(_sample())
	return expect_equals(b["pages"][0]["bubbles"][0]["side"], "right", "side を読み取る")

func _test_side_write() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	if not expect_true(Slideshow.set_bubble_side(lines, b["pages"][0]["bubbles"][0], "bottom-left"), "set_bubble_side が false"):
		return false
	if not expect_equals(lines[6], "\t\tbt.bubble(\"one\", {\"side\": \"bottom-left\"})", "side だけ書き換わる"):
		return false
	return expect_equals(_block0(lines)["pages"][0]["bubbles"][0]["side"], "bottom-left", "読み直しで反映される")

func _test_side_add() -> bool:
	var lines := PackedStringArray([
		"func outfit_3(bt):",
		"\t\tbt.background(\"res://a.png\")",
		"\t\tbt.bubble(\"no dict\")",
		"\t\tbt.background(\"res://room.png\")",
	])
	var b := _block0(lines)
	if not expect_true(Slideshow.set_bubble_side(lines, b["pages"][0]["bubbles"][0], "center"), "dict 無しでも書ける"):
		return false
	return expect_equals(lines[2], "\t\tbt.bubble(\"no dict\", {\"side\": \"center\"})", "dict を追加する")

# 実際に章で使われている side が、実機の位置表に全部載っていること。
# 載っていない side は _apply_bubble_side で無視され、吹き出しが前の位置に residual する。
func _test_side_known() -> bool:
	var table: Dictionary = preload("res://game/BattleScene.gd").BUBBLE_SIDE_ANCHORS
	var d := DirAccess.open("res://battle/chapters")
	if not d:
		return fail("battle/chapters を開けない")
	for name in d.get_files():
		if not name.ends_with(".gd"):
			continue
		var lines := Slideshow.read_lines("res://battle/chapters/" + name)
		for block in Slideshow.parse_blocks(lines):
			for page in block["pages"]:
				for bub in page["bubbles"]:
					var sd: String = str(bub.get("side", ""))
					if sd.is_empty():
						continue
					if not expect_true(table.has(sd), "%s: 未知の side '%s' (行%d)" % [name, sd, bub["line"]]):
						return false
	return expect_true(true)

# セリフ単位の文字サイズが読み書きできること。
func _test_font_roundtrip() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	if not expect_equals(b["pages"][0]["bubbles"][0]["font_size"], 0, "未指定は 0"):
		return false
	if not expect_true(Slideshow.set_bubble_font_size(lines, b["pages"][0]["bubbles"][0], 42), "set_bubble_font_size が false"):
		return false
	if not expect_true(lines[6].contains('"font_size": 42'), "font_size が書かれる: %s" % lines[6]):
		return false
	if not expect_true(lines[6].contains('"side": "right"'), "既存の side を壊さない: %s" % lines[6]):
		return false
	return expect_equals(_block0(lines)["pages"][0]["bubbles"][0]["font_size"], 42, "読み直しで 42")

# 0 を渡すと指定ごと消えて既定へ戻ること（"font_size": 0 が残ると実機が 0px にする）。
func _test_font_clear() -> bool:
	var lines := _sample()
	var b := _block0(lines)
	Slideshow.set_bubble_font_size(lines, b["pages"][0]["bubbles"][0], 42)
	var b2 := _block0(lines)
	if not expect_true(Slideshow.set_bubble_font_size(lines, b2["pages"][0]["bubbles"][0], 0), "0 指定が false"):
		return false
	if not expect_false(lines[6].contains("font_size"), "font_size 指定が残っている: %s" % lines[6]):
		return false
	if not expect_true(lines[6].contains('"side": "right"'), "side まで消している: %s" % lines[6]):
		return false
	return expect_equals(_block0(lines)["pages"][0]["bubbles"][0]["font_size"], 0, "既定へ戻る")
