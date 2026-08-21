extends RefCounted
class_name SlideshowSource

# バトル章の「紙芝居」(敗北ごとの一枚絵スライド) を章ソースから読み書きする。
#
# 紙芝居は outfit_N(bt) の勝利分岐の中に、こう並んでいる:
#   bt.background("res://.../undressing_001.png")
#   bt.bubble("...", {"side": "right"})
#   bt.background("res://.../undressing_002.png")
#   bt.bubble("...", {"side": "right"})
#   bt.background("res://assets/backgrounds/.../bg_room.png")   ← 背景を戻すだけの行
#
# ページ = background 1行 + それに続く bubble 群。
# 末尾の「bubble を伴わない background」は背景復帰なのでページに数えない。
#
# ランタイムを触らずソースを直接読むのは、Background コマンドが edit_source_id を
# 持たず、bubble() が force_result_mode (=編集モード) で丸ごとスキップされるため。
# 実行時には紙芝居が観測できない。行番号もソースから取る方が確実で、ページの
# 挿入・削除も行操作で完結する。

const BG_RE := '^(\\s*)bt\\.background\\s*\\(\\s*"([^"]*)"\\s*(.*)$'
const BUBBLE_RE := '^(\\s*)bt\\.bubble\\s*\\(\\s*"((?:[^"\\\\]|\\\\.)*)"\\s*(.*)$'
const FUNC_RE := '^func\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\('
# 章によっては belka_outfit_3 のように接頭辞が付く
const OUTFIT_RE := 'outfit_(\\d+)$'

# ---------- 解析 ----------

static func _match(pattern: String, line: String) -> RegExMatch:
	var re := RegEx.new()
	re.compile(pattern)
	return re.search(line)

# GDScript の文字列リテラル -> 生テキスト。
# バックスラッシュを最後に処理すると、ソース上の \\n
# (エスケープされた円記号 + n) が 円記号 + 改行 になってしまうため、
# 1 文字ずつ走査して先頭から解決する。
static func unescape(s: String) -> String:
	var out := ""
	var i := 0
	while i < s.length():
		if s[i] == "\\" and i + 1 < s.length():
			var c := s[i + 1]
			match c:
				"n": out += "\n"
				"t": out += "\t"
				"\"": out += "\""
				"\\": out += "\\"
				_: out += "\\" + c
			i += 2
		else:
			out += s[i]
			i += 1
	return out

# 生テキスト -> GDScript の文字列リテラル (囲みクォートは含まない)
static func escape(s: String) -> String:
	return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")

# lines から紙芝居ブロックを全て取り出す。
# 返り値: [{ "func_name", "loss_index", "start_line", "end_line", "indent",
#            "pages": [{ "bg_line", "bg_path", "bubbles": [{"line","text","tail"}] }],
#            "terminator_line", "terminator_path" }]
# 行番号はすべて 1 始まり。
static func parse_blocks(lines: PackedStringArray) -> Array:
	# 行 -> 属する outfit 関数名
	var func_of := {}
	var current := ""
	for i in range(lines.size()):
		var fm := _match(FUNC_RE, lines[i])
		if fm:
			# outfit_N を含む関数だけ紙芝居の入れ物とみなす
			current = fm.get_string(1) if _match(OUTFIT_RE, fm.get_string(1)) else ""
		func_of[i] = current
	var blocks: Array = []
	var i2: int = 0
	while i2 < lines.size():
		if _match(BG_RE, lines[i2]) == null:
			i2 += 1
			continue
		# 連続する background / bubble 行を1連として取り込む
		var run_start: int = i2
		var run: Array = []
		while i2 < lines.size():
			var bm := _match(BG_RE, lines[i2])
			var ubm := _match(BUBBLE_RE, lines[i2])
			if bm:
				run.append({"kind": "bg", "line": i2 + 1, "path": bm.get_string(2), "indent": bm.get_string(1), "tail": bm.get_string(3)})
			elif ubm:
				var tail: String = ubm.get_string(3)
				run.append({"kind": "bubble", "line": i2 + 1, "text": unescape(ubm.get_string(2)), "indent": ubm.get_string(1), "tail": tail, "side": side_of(tail), "font_size": font_size_of(tail)})
			else:
				break
			i2 += 1
		# bubble を1つも含まない連は紙芝居ではない (単発の背景切り替え)
		var has_bubble := false
		for e in run:
			if e["kind"] == "bubble":
				has_bubble = true
				break
		if not has_bubble:
			continue
		var pages: Array = []
		var term_line: int = -1
		var term_path: String = ""
		for e in run:
			if e["kind"] == "bg":
				pages.append({"bg_line": e["line"], "bg_path": e["path"], "bg_tail": e["tail"], "bubbles": []})
			else:
				if pages.is_empty():
					continue
				pages[pages.size() - 1]["bubbles"].append({"line": e["line"], "text": e["text"], "tail": e["tail"], "side": e["side"], "font_size": e["font_size"]})
		# 末尾がセリフなしなら背景復帰行として切り離す
		if not pages.is_empty() and (pages[pages.size() - 1]["bubbles"] as Array).is_empty():
			var last: Dictionary = pages.pop_back()
			term_line = last["bg_line"]
			term_path = last["bg_path"]
		if pages.is_empty():
			continue
		blocks.append({
			"func_name": func_of.get(run_start, ""),
			"loss_index": 0,  # 後段で埋める
			"start_line": run[0]["line"],
			"end_line": run[run.size() - 1]["line"],
			"indent": run[0]["indent"],
			"pages": pages,
			"terminator_line": term_line,
			"terminator_path": term_path,
		})
	# outfit 番号の大きい順 = 1敗目, 2敗目, ... (outfit_3 が最初の敗北)
	var nums := {}
	for b in blocks:
		var om := _match(OUTFIT_RE, b["func_name"])
		b["outfit_num"] = int(om.get_string(1)) if om else -1
		nums[b["outfit_num"]] = true
	var ordered: Array = nums.keys()
	ordered.sort()
	ordered.reverse()
	for b in blocks:
		var idx: int = ordered.find(b["outfit_num"])
		b["loss_index"] = idx + 1 if idx >= 0 else 0
	return blocks

static func read_lines(res_path: String) -> PackedStringArray:
	var f := FileAccess.open(res_path, FileAccess.READ)
	if not f:
		return PackedStringArray()
	var t := f.get_as_text()
	f.close()
	return t.split("\n")

# bt.bubble(...) の第2引数から "side" を取り出す。無ければ空文字。
static func side_of(tail: String) -> String:
	var m := _match('"side"\\s*:\\s*"([^"]*)"', tail)
	return m.get_string(1) if m else ""

# bt.bubble(...) の第2引数から "font_size" を取り出す。無指定なら 0。
static func font_size_of(tail: String) -> int:
	var m := _match('"font_size"\\s*:\\s*(\\d+)', tail)
	return int(m.get_string(1)) if m else 0

# ---------- 編集 ----------
# どれも lines を書き換えて true/false を返す。行番号がずれる操作 (挿入/削除) の後は
# parse_blocks をやり直すこと。ブロック内で行番号を持ち回すと必ず壊れる。

# ページの背景画像を差し替える。
static func set_page_image(lines: PackedStringArray, page: Dictionary, new_path: String) -> bool:
	var li: int = int(page.get("bg_line", 0)) - 1
	if li < 0 or li >= lines.size():
		return false
	var m := _match(BG_RE, lines[li])
	if m == null:
		return false
	lines[li] = '%sbt.background("%s"%s' % [m.get_string(1), new_path, m.get_string(3)]
	return true

# セリフ1行を書き換える。
static func set_bubble_text(lines: PackedStringArray, bubble: Dictionary, new_text: String) -> bool:
	var li: int = int(bubble.get("line", 0)) - 1
	if li < 0 or li >= lines.size():
		return false
	var m := _match(BUBBLE_RE, lines[li])
	if m == null:
		return false
	lines[li] = '%sbt.bubble("%s"%s' % [m.get_string(1), escape(new_text), m.get_string(3)]
	return true

# セリフの表示位置 (bt.bubble の "side") を書き換える。
# dict ごと無い呼び出し (bt.bubble("...")) には dict を足す。
static func set_bubble_side(lines: PackedStringArray, bubble: Dictionary, new_side: String) -> bool:
	var li: int = int(bubble.get("line", 0)) - 1
	if li < 0 or li >= lines.size():
		return false
	var m := _match(BUBBLE_RE, lines[li])
	if m == null:
		return false
	var head: String = '%sbt.bubble("%s"' % [m.get_string(1), escape(unescape(m.get_string(2)))]
	var tail: String = m.get_string(3)
	if side_of(tail).is_empty():
		# 末尾の ")" の手前へ dict を挿入
		var close: int = tail.rfind(")")
		if close < 0:
			return false
		tail = tail.substr(0, close) + ', {"side": "%s"}' % new_side + tail.substr(close)
	else:
		var re := RegEx.new()
		re.compile('"side"\\s*:\\s*"[^"]*"')
		tail = re.sub(tail, '"side": "%s"' % new_side)
	lines[li] = head + tail
	return true

# セリフ単位の文字サイズを書き換える。0 を渡すと指定ごと取り除いて既定へ戻す。
static func set_bubble_font_size(lines: PackedStringArray, bubble: Dictionary, size: int) -> bool:
	var li: int = int(bubble.get("line", 0)) - 1
	if li < 0 or li >= lines.size():
		return false
	var m := _match(BUBBLE_RE, lines[li])
	if m == null:
		return false
	var head: String = '%sbt.bubble("%s"' % [m.get_string(1), escape(unescape(m.get_string(2)))]
	var tail: String = m.get_string(3)
	var has := _match('"font_size"\\s*:\\s*\\d+', tail) != null
	if size <= 0:
		if not has:
			return true
		# ", \"font_size\": N" ごと、もしくは "\"font_size\": N, " ごと消す
		var re_del := RegEx.new()
		re_del.compile(',\\s*"font_size"\\s*:\\s*\\d+|"font_size"\\s*:\\s*\\d+\\s*,\\s*')
		tail = re_del.sub(tail, "")
	elif has:
		var re := RegEx.new()
		re.compile('"font_size"\\s*:\\s*\\d+')
		tail = re.sub(tail, '"font_size": %d' % size)
	else:
		var close: int = tail.rfind("}")
		if close >= 0:
			tail = tail.substr(0, close) + ', "font_size": %d' % size + tail.substr(close)
		else:
			var paren: int = tail.rfind(")")
			if paren < 0:
				return false
			tail = tail.substr(0, paren) + ', {"font_size": %d}' % size + tail.substr(paren)
	lines[li] = head + tail
	return true

# page_index の「次」に新しいページ (background + bubble の2行) を挿入する。
# page_index が -1 なら先頭へ。
static func insert_page(lines: PackedStringArray, block: Dictionary, page_index: int, bg_path: String, text: String) -> bool:
	var pages: Array = block.get("pages", [])
	var indent: String = block.get("indent", "\t\t")
	var bubble_tail: String = ', {"side": "right"})'
	# 既存ページの書式 (side など) を引き継ぐ
	if not pages.is_empty():
		var ref: Dictionary = pages[clampi(max(page_index, 0), 0, pages.size() - 1)]
		var refb: Array = ref.get("bubbles", [])
		if not refb.is_empty():
			bubble_tail = str(refb[0].get("tail", bubble_tail))
	# insert_before は 0 始まりの「この行の手前に入れる」位置
	var insert_before: int
	if page_index < 0:
		if pages.is_empty():
			return false
		insert_before = int(pages[0]["bg_line"]) - 1
	else:
		if page_index >= pages.size():
			return false
		var p: Dictionary = pages[page_index]
		var bl: Array = p.get("bubbles", [])
		insert_before = int(bl[bl.size() - 1]["line"]) if not bl.is_empty() else int(p["bg_line"])
	if insert_before < 0 or insert_before > lines.size():
		return false
	var ins := PackedStringArray()
	ins.append('%sbt.background("%s")' % [indent, bg_path])
	ins.append('%sbt.bubble("%s"%s' % [indent, escape(text), bubble_tail])
	var out := PackedStringArray()
	for i in range(lines.size()):
		if i == insert_before:
			out.append_array(ins)
		out.append(lines[i])
	if insert_before >= lines.size():
		out.append_array(ins)
	lines.clear()
	lines.append_array(out)
	return true

# ページ (background 行 + 続く bubble 行) をまとめて削除する。
static func delete_page(lines: PackedStringArray, block: Dictionary, page_index: int) -> bool:
	var pages: Array = block.get("pages", [])
	if page_index < 0 or page_index >= pages.size():
		return false
	if pages.size() <= 1:
		return false  # 最後の1枚は消させない (紙芝居が消滅する)
	var p: Dictionary = pages[page_index]
	var first: int = int(p["bg_line"])
	var bl: Array = p.get("bubbles", [])
	var last: int = int(bl[bl.size() - 1]["line"]) if not bl.is_empty() else first
	var out := PackedStringArray()
	for i in range(lines.size()):
		var ln: int = i + 1
		if ln >= first and ln <= last:
			continue
		out.append(lines[i])
	lines.clear()
	lines.append_array(out)
	return true

# ページを1つ前 / 後ろへ動かす (dir = -1 / +1)。
static func move_page(lines: PackedStringArray, block: Dictionary, page_index: int, dir: int) -> bool:
	var pages: Array = block.get("pages", [])
	var other: int = page_index + dir
	if page_index < 0 or page_index >= pages.size():
		return false
	if other < 0 or other >= pages.size():
		return false
	var a: Dictionary = pages[min(page_index, other)]
	var b: Dictionary = pages[max(page_index, other)]
	var a_first: int = int(a["bg_line"])
	var ab: Array = a.get("bubbles", [])
	var a_last: int = int(ab[ab.size() - 1]["line"]) if not ab.is_empty() else a_first
	var b_first: int = int(b["bg_line"])
	var bb: Array = b.get("bubbles", [])
	var b_last: int = int(bb[bb.size() - 1]["line"]) if not bb.is_empty() else b_first
	if a_last + 1 != b_first:
		return false  # 間に想定外の行がある
	var out := PackedStringArray()
	for i in range(a_first - 1):
		out.append(lines[i])
	for i in range(b_first - 1, b_last):
		out.append(lines[i])
	for i in range(a_first - 1, a_last):
		out.append(lines[i])
	for i in range(b_last, lines.size()):
		out.append(lines[i])
	lines.clear()
	lines.append_array(out)
	return true
