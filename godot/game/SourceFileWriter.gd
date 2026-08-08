extends RefCounted
class_name SourceFileWriter

# 編集モードが章ソース (.gd) を書き戻すための共通ライタ。
#
# 直接 FileAccess.WRITE で開いて store_string すると、行特定ロジックのバグや
# 書き込み中の異常終了で Git 管理下のソースがそのまま失われる。ここを通すことで:
#   1. 直前の内容を <path>.bak に1世代退避する
#   2. <path>.tmp へ書いてから rename する（途中で失敗しても元ファイルは無傷）
#
# Main.gd は GameState オートロード依存でテストランナーからインスタンス化できないため、
# ロジックはこの依存のない RefCounted 側に置いてテスト可能にしてある。

const BACKUP_SUFFIX := ".bak"
const TEMP_SUFFIX := ".tmp"

# abs_path へ text を書き戻す。成功したら true。
# 失敗した場合、元ファイルには一切変更を加えない。
static func write(abs_path: String, text: String) -> bool:
	_make_backup(abs_path)
	var tmp_path: String = abs_path + TEMP_SUFFIX
	var wf := FileAccess.open(tmp_path, FileAccess.WRITE)
	if not wf:
		push_error("[SOURCE_WRITE] 一時ファイルを開けない: %s" % tmp_path)
		return false
	wf.store_string(text)
	var write_err: int = wf.get_error()
	wf.close()
	if write_err != OK:
		push_error("[SOURCE_WRITE] 書き込み失敗: %s (err=%d)" % [tmp_path, write_err])
		DirAccess.remove_absolute(tmp_path)
		return false
	var rename_err: int = DirAccess.rename_absolute(tmp_path, abs_path)
	if rename_err != OK:
		push_error("[SOURCE_WRITE] rename 失敗: %s -> %s (err=%d)" % [tmp_path, abs_path, rename_err])
		DirAccess.remove_absolute(tmp_path)
		return false
	return true

# 既存ファイルがある場合だけ .bak を作る。バックアップ失敗自体は書き込みを止めない
# （警告に留める）が、その旨は必ず記録する。
static func _make_backup(abs_path: String) -> void:
	var prev := FileAccess.open(abs_path, FileAccess.READ)
	if not prev:
		return
	var original: String = prev.get_as_text()
	prev.close()
	var bak := FileAccess.open(abs_path + BACKUP_SUFFIX, FileAccess.WRITE)
	if not bak:
		push_warning("[SOURCE_WRITE] バックアップ作成不可: %s%s" % [abs_path, BACKUP_SUFFIX])
		return
	bak.store_string(original)
	bak.close()
