extends RefCounted
class_name PortraitPicker

# 編集モードの画像差し替えピッカーを支える純粋ロジック。
#   - 「同じ系統の立ち絵」を集めるための命名規則（prefix_of / matches_prefix）
#   - グリッドに並べるサムネの生成（make_thumb）
#
# Main.gd 側に置かず独立させてあるのは、Main.gd が GameState オートロードに依存して
# いてテストからインスタンス化できないため（SourceFileWriter.gd と同じ理由）。
# Main.gd からは preload 定数経由で呼ぶこと。グローバルクラス名で直接参照すると、
# エディタを通していないチェックアウトでパースエラーになる。

# ---------- 命名規則 ----------

# ファイル名から「連番より前の系統名（prefix）」を返す。
# 例: "satoshi_isekai_007.png"              → "satoshi_isekai_"
#     "fiona_clothed_017_v1.png"            → "fiona_clothed_"
#     "fiona_clothed_019_smile__waving.png" → "fiona_clothed_"
#     "fiona_clothed_janken_001.png"        → "fiona_clothed_janken_"
#
# "_" 区切りで最初に数字から始まるトークンを連番とみなし、その手前までを系統名とする。
# フォルダ単位でまとめないのは、同じフォルダに別系統が同居しているため
# （例: main/sister_head/clothed には sister_head_clothed_* と
# sister_head_undressing_panty_* が両方入っている）。
# 数字始まりのトークンが無ければ basename をそのまま返す（マッチは厳密一致になる）。
static func prefix_of(filename: String) -> String:
	var base: String = filename.get_basename()
	var parts: PackedStringArray = base.split("_")
	for i in parts.size():
		var p: String = parts[i]
		if p.is_empty() or not (p[0] >= "0" and p[0] <= "9"):
			continue
		# 先頭トークンがいきなり数字なら系統名が無いので厳密一致に倒す
		if i == 0:
			return base
		return "_".join(parts.slice(0, i)) + "_"
	return base

# 同フォルダの画像名が prefix_of() で得た prefix にマッチするか。
# prefix + 「数字で始まる残り」を sibling として認める。
# 残りが全桁数字である必要はない。"019_smile__waving" のように連番のあとへ
# 表情/ポーズを書いたファイル名も、"017_v1" のような差し替え版も sibling になる。
# 数字始まりに限っているのは、同フォルダの別系統（fiona_clothed_janken_* など）を
# 巻き込まないため。
static func matches_prefix(filename: String, prefix: String) -> bool:
	var base: String = filename.get_basename()
	if not base.begins_with(prefix):
		return false
	var rest: String = base.substr(prefix.length())
	if rest.is_empty():
		return false
	return rest[0] >= "0" and rest[0] <= "9"

# ---------- サムネ ----------

# 生成済みサムネの置き場。元画像の mtime とサムネ寸法をキーに含めるので、
# 画像を差し替えれば自動で作り直される（古いエントリは残るが 1 枚数十 KB）。
const THUMB_CACHE_DIR := "user://portrait_thumb_cache"

static func thumb_cache_path(full_path: String, thumb_w: int, thumb_h: int) -> String:
	var key: String = "%s|%d|%dx%d" % [full_path, FileAccess.get_modified_time(full_path), thumb_w, thumb_h]
	return THUMB_CACHE_DIR.path_join(key.md5_text() + ".png")

# ピッカーのグリッドに並べるサムネを作る。
#
# 立ち絵は縦長。横方向は中央の 1/2 幅をクロップ（2倍ズーム）、縦方向はその2倍の
# 高さ（=元の上半身分量）を取り、顔/上半身が見切れないようにする。
# 顔位置（画像上部 14% あたり）が thumb の上 1/3 〜 中央に来るよう垂直オフセットを寄せる。
#
# 元テクスチャを AtlasTexture でそのまま表示すると、候補の枚数ぶんフル解像度画像が
# 同時に GPU へ載る（640x1536 RGBA で約 3.9MB/枚。fiona/clothed のように 240 枚を
# 超えるフォルダでは 1GB 近くになる）。クロップ後に thumb 寸法まで縮小した
# ImageTexture を返し、元画像への参照はこの関数を抜けた時点で手放す。
# 2 回目以降の表示のために user:// へ焼いておく（全部作り直すと数秒かかるため）。
static func make_thumb(full_path: String, thumb_w: int, thumb_h: int) -> Texture2D:
	var cache_path: String = thumb_cache_path(full_path, thumb_w, thumb_h)
	if FileAccess.file_exists(cache_path):
		var cached := Image.load_from_file(cache_path)
		if cached:
			return ImageTexture.create_from_image(cached)
	var tex: Texture2D = load(full_path)
	if not tex:
		return null
	var img: Image = tex.get_image()
	if not img:
		return null
	var tw: int = img.get_width()
	var th: int = img.get_height()
	var crop_w: int = max(1, min(int(tw / 2), int(th * 0.25)))
	var crop_h: int = max(1, min(th, crop_w * 2))
	var face_y_est: int = int(th * 0.14)
	var crop_y: int = clampi(face_y_est - int(crop_h / 3), 0, max(0, th - crop_h))
	var crop_x: int = max(0, int((tw - crop_w) / 2))
	var cropped: Image = img.get_region(Rect2i(crop_x, crop_y, crop_w, crop_h))
	cropped.resize(thumb_w, thumb_h, Image.INTERPOLATE_BILINEAR)
	DirAccess.make_dir_recursive_absolute(THUMB_CACHE_DIR)
	cropped.save_png(cache_path)
	return ImageTexture.create_from_image(cropped)
