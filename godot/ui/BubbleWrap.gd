class_name BubbleWrap

# 吹き出し1行に入る最大文字数（全角換算）。フォント24pt × 横幅 33% × アイコン控除を実測した値。
# 注：MAX を緩めるとアイコン側で実際にはみ出す。20→16 まで詰めて視認確認済み。
const MAX_CHARS_PER_LINE: int = 16
# 吹き出し1ふきだしに入る最大行数（話者プレフィックス含む）。
# バブル高さ 27% × フォント 24pt → 物理的には 5 行まで収まる。
const MAX_LINES: int = 5
# スマート改行で優先的に切る句読点／区切り。
const BREAK_CHARS: PackedStringArray = ["、", "。", "！", "？", "　", ","]

static func wrap(text: String) -> String:
	if text.is_empty():
		return text
	var out: PackedStringArray = []
	for line in text.split("\n"):
		for sub in break_line(line):
			out.append(sub)
	return "\n".join(out)

# 1 行を MAX_CHARS_PER_LINE 以下に収まるよう句読点位置で再帰分割。
static func break_line(line: String) -> PackedStringArray:
	if line.length() <= MAX_CHARS_PER_LINE:
		return PackedStringArray([line])
	# 切断後の先頭チャンクが MAX_CHARS_PER_LINE 文字以下になるよう、
	# 区切り文字は index ≤ MAX_CHARS_PER_LINE - 1 の範囲で探す。
	var split_at: int = -1
	var search_end: int = mini(MAX_CHARS_PER_LINE - 1, line.length() - 1)
	for i in range(search_end, 0, -1):
		if BREAK_CHARS.has(line[i]):
			split_at = i + 1
			break
	if split_at <= 0:
		split_at = MAX_CHARS_PER_LINE
	var first := line.substr(0, split_at)
	var rest := line.substr(split_at)
	var result: PackedStringArray = [first]
	for sub in break_line(rest):
		result.append(sub)
	return result
