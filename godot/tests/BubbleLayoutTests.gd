extends TestSuite
class_name BubbleLayoutTests

# 敗北イベント（紙芝居）の吹き出しの寸法・文字サイズに関するテスト。
#
# 位置表と文字サイズは BattleScene の定数が唯一の真実源で、紙芝居編集の
# プレビューも同じ定数を読む。ui/SpeechBubble.tscn 側に文字サイズの実値が
# あるため、そこがズレると「エディタと実機で見え方が違う」状態になる。
# 併せて、既存のセリフが枠に収まるかを見積もって回帰を検出する。

const BattleSceneScript := preload("res://game/BattleScene.gd")
const BubbleFit := preload("res://ui/BubbleFit.gd")
const Slideshow := preload("res://battle/SlideshowSource.gd")
const BUBBLE_TSCN := "res://ui/SpeechBubble.tscn"
const CHAPTER_DIR := "res://battle/chapters"

# ラベルの内側マージンは BubbleFit を唯一の真実源とする（再宣言しない）
const VP := Vector2(1920, 1080)

func get_name() -> String:
	return "BubbleLayout"

func get_tests() -> Array:
	return [
		{"name": "scene_font_size_matches_the_constant", "callable": Callable(self, "_test_font_sync")},
		{"name": "every_side_slot_stays_on_screen", "callable": Callable(self, "_test_on_screen")},
		{"name": "slots_keep_their_screen_edge", "callable": Callable(self, "_test_edges")},
		{"name": "auto_fit_makes_every_line_fit", "callable": Callable(self, "_test_fit")},
		{"name": "auto_fit_never_exceeds_the_screen", "callable": Callable(self, "_test_fit_cap")},
		{"name": "box_height_grows_with_text_and_clamps", "callable": Callable(self, "_test_box_height")},
	]

func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return ""
	var t := f.get_as_text()
	f.close()
	return t

# .tscn の実値と定数がズレていないこと。
func _test_font_sync() -> bool:
	var src := _read(BUBBLE_TSCN)
	if src.is_empty():
		return fail("SpeechBubble.tscn を読めない")
	var want: int = BattleSceneScript.BUBBLE_FONT_SIZE
	if not expect_true(src.contains("theme_override_font_sizes/font_size = %d" % want),
			"SpeechBubble.tscn の font_size が BUBBLE_FONT_SIZE(%d) と一致しない" % want):
		return false
	# ラベルの内側マージンも BubbleFit と一致していること。
	# ここがズレると実機と紙芝居プレビューで折り返し位置が食い違う。
	var mw: float = (1.0 - BubbleFit.LABEL_W_RATIO) / 2.0
	var mh: float = (1.0 - BubbleFit.LABEL_H_RATIO) / 2.0
	for pair in [["anchor_left", mw], ["anchor_right", 1.0 - mw], ["anchor_top", mh], ["anchor_bottom", 1.0 - mh]]:
		var key: String = pair[0]
		var val: float = pair[1]
		var line: String = "%s = %s" % [key, String.num(val, 2).trim_suffix("0").trim_suffix(".")]
		if not expect_true(src.contains(line),
				"SpeechBubble.tscn の %s が BubbleFit の比率と一致しない (期待 %s)" % [key, line]):
			return false
	return expect_true(true)

# 各スロットが画面内に収まり、幅・高さが正であること。
func _test_on_screen() -> bool:
	for key in BattleSceneScript.BUBBLE_SIDE_ANCHORS.keys():
		var a: Dictionary = BattleSceneScript.BUBBLE_SIDE_ANCHORS[key]
		if not expect_true(float(a["l"]) >= 0.0 and float(a["r"]) <= 1.0, "%s が左右にはみ出す" % key):
			return false
		if not expect_true(float(a["t"]) >= 0.0 and float(a["b"]) <= 1.0, "%s が上下にはみ出す" % key):
			return false
		if not expect_true(float(a["r"]) > float(a["l"]) and float(a["b"]) > float(a["t"]), "%s の幅/高さが 0 以下" % key):
			return false
	return expect_true(true)

# left は左端、right は右端、bottom-* は下端に寄っていること。
# 縮小するときに寄せる辺を間違えると、吹き出しが画面中央へ寄って話者から離れる。
func _test_edges() -> bool:
	var t: Dictionary = BattleSceneScript.BUBBLE_SIDE_ANCHORS
	if not expect_true(float(t["left"]["l"]) < 0.1 and float(t["bottom-left"]["l"]) < 0.1, "left 系が左端に寄っていない"):
		return false
	if not expect_true(float(t["right"]["r"]) > 0.9 and float(t["bottom-right"]["r"]) > 0.9, "right 系が右端に寄っていない"):
		return false
	if not expect_true(float(t["bottom-left"]["b"]) > 0.7 and float(t["bottom-right"]["b"]) > 0.7, "bottom 系が下端に寄っていない"):
		return false
	var c: Dictionary = t["center"]
	var mid: float = (float(c["l"]) + float(c["r"])) / 2.0
	return expect_true(absf(mid - 0.5) < 0.02, "center が画面中央にない (mid=%.3f)" % mid)

# 章に実在するセリフが、自動フィット後の枠に収まること。
#
# 判定は必ず実装 (BubbleFit.box_height -> Font.get_multiline_string_size) を通す。
# テスト側で行数を近似して比べると「近似式が自分自身と一致するか」を見るだけの
# 恒真式になり、実際のレイアウトを何も検証しない。
func _test_fit() -> bool:
	var font: Font = ThemeDB.fallback_font
	if not expect_true(font != null, "フォールバックフォントが取れない"):
		return false
	var default_font: int = BattleSceneScript.BUBBLE_FONT_SIZE
	var d := DirAccess.open(CHAPTER_DIR)
	if not d:
		return fail("%s を開けない" % CHAPTER_DIR)
	var total := 0
	var over := 0
	var worst := ""
	for name in d.get_files():
		if not name.ends_with(".gd"):
			continue
		var lines := Slideshow.read_lines(CHAPTER_DIR + "/" + name)
		for block in Slideshow.parse_blocks(lines):
			for page in block["pages"]:
				for bub in page["bubbles"]:
					total += 1
					var side: String = str(bub.get("side", "center"))
					if not BattleSceneScript.BUBBLE_SIDE_ANCHORS.has(side):
						side = "center"
					var a: Dictionary = BattleSceneScript.BUBBLE_SIDE_ANCHORS[side]
					var fs: int = int(bub.get("font_size", 0))
					if fs <= 0:
						fs = default_font
					var box_w: float = VP.x * (float(a["r"]) - float(a["l"]))
					var min_h: float = VP.y * (float(a["b"]) - float(a["t"]))
					var max_h: float = VP.y * float(BubbleFit.MAX_HEIGHT_RATIO)
					var text: String = str(bub["text"])
					# 実装が決める箱の高さ
					var box_h: float = BubbleFit.box_height(text, font, fs, box_w, min_h, max_h)
					# その箱でラベルに使える高さと、実際に必要な高さを突き合わせる
					var label_h: float = box_h * BubbleFit.LABEL_H_RATIO
					var need: float = font.get_multiline_string_size(
						text, HORIZONTAL_ALIGNMENT_LEFT, box_w * BubbleFit.LABEL_W_RATIO, fs).y
					if need > label_h + 1.0:
						over += 1
						if worst.is_empty():
							worst = "%s: 「%s」(必要 %.0fpx / 枠 %.0fpx)" % [name, text.substr(0, 24).replace("\n", "/"), need, label_h]
	if not expect_true(total > 100, "セリフ件数が少なすぎる (got %d)" % total):
		return false
	# 自動フィットが効いていれば 0 件。増えたら枠の伸縮が壊れている。
	return expect_true(over == 0, "自動フィットしても収まらないセリフがある (%d/%d 件) %s" % [over, total, worst])

# 自動フィットは画面に収まる範囲までしか伸びないこと。
func _test_fit_cap() -> bool:
	var cap: float = float(BubbleFit.MAX_HEIGHT_RATIO)
	if not expect_true(cap > 0.0 and cap <= 0.9, "BUBBLE_MAX_HEIGHT_RATIO が異常 (%.2f)" % cap):
		return false
	# bottom-* は下辺固定で上へ伸びるので、上端が画面外へ出ないこと
	var t: Dictionary = BattleSceneScript.BUBBLE_SIDE_ANCHORS
	for key in ["bottom-left", "bottom-right"]:
		var bottom: float = float(t[key]["b"])
		if not expect_true(bottom - cap >= 0.0, "%s が上へ伸びると画面外へ出る (b=%.2f cap=%.2f)" % [key, bottom, cap]):
			return false
	# 上部スロットは上辺固定で下へ伸びる
	for key in ["left", "right", "center"]:
		var top: float = float(t[key]["t"])
		if not expect_true(top + cap <= 1.0, "%s が下へ伸びると画面外へ出る (t=%.2f cap=%.2f)" % [key, top, cap]):
			return false
	return expect_true(true)


# 高さ計算そのものの検証。実機の _fit_bubble_to_text と紙芝居プレビューが
# 共に呼ぶ関数なので、ここが壊れると両方で枠が伸びなくなる。
func _test_box_height() -> bool:
	var font: Font = ThemeDB.fallback_font
	if not expect_true(font != null, "フォールバックフォントが取れない"):
		return false
	var min_h := 194.0
	var max_h := 670.0
	var w := 422.0
	var short_h: float = BubbleFit.box_height("あ", font, 34, w, min_h, max_h)
	if not expect_true(is_equal_approx(short_h, min_h), "短文は最低高さ (got %.1f / min %.1f)" % [short_h, min_h]):
		return false
	var mid: String = ""
	for i in range(60):
		mid += "あ"
	var mid_h: float = BubbleFit.box_height(mid, font, 34, w, min_h, max_h)
	if not expect_true(mid_h > short_h, "文字が増えたら高さが伸びる (%.1f -> %.1f)" % [short_h, mid_h]):
		return false
	var big_h: float = BubbleFit.box_height(mid, font, 64, w, min_h, max_h)
	if not expect_true(big_h > mid_h, "文字を大きくしたら高さが伸びる (%.1f -> %.1f)" % [mid_h, big_h]):
		return false
	var huge: String = ""
	for i in range(600):
		huge += "あ"
	var huge_h: float = BubbleFit.box_height(huge, font, 64, w, min_h, max_h)
	return expect_true(is_equal_approx(huge_h, max_h), "上限で頭打ちになる (got %.1f / max %.1f)" % [huge_h, max_h])
