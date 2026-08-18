extends RefCounted
class_name PortraitImportCache

# 実行中のゲームが立ち絵 PNG を新規に書き出したときの、インポート済みキャッシュの後始末。
#
# Godot は res:// の画像を load() するとき、まず <file>.import の [remap] path を見て
# .godot/imported/*.ctex を読む。ここで問題になるのが「同名ファイルの .import が
# 残っている」ケース:
#   1. 過去に foo_v4.png があり、インポートされて .ctex が出来ている
#   2. foo_v4.png を git などで削除する（.import は gitignore 対象なのでツリーに残る）
#   3. 編集モードのドラッグ&ドロップが再び foo_v4.png という名前で新しい画像を書く
#   4. load("res://foo_v4.png") が古い .ctex を返す
# resource_path は新ファイルを指したままなので、編集カードのタイトルもログも新しい
# ファイル名を表示する。画面の絵だけが古い、という形でしか表に出ない。
#
# 実行中のプロセスは再インポートできないので、書き出し直後に .import と生成物を消す。
# こうすると load() は remap を経ずに ResourceCache / 生 PNG フォールバック
# （StoryScene._load_texture）へ落ち、書いたばかりの画像が正しく出る。
# エディタが次にスキャンした時点で、新しい内容から .import が作り直される。

# res_path (res://... の画像パス) に対応する .import と生成物を削除する。
# 削除した実ファイル数を返す（0 なら .import が無かった＝何もしていない）。
static func purge(res_path: String) -> int:
	var import_res: String = res_path + ".import"
	if not FileAccess.file_exists(import_res):
		return 0
	var removed: int = 0
	var cfg := ConfigFile.new()
	if cfg.load(import_res) == OK:
		var dests: Array = []
		var remap_path = cfg.get_value("remap", "path", "")
		if remap_path is String and not (remap_path as String).is_empty():
			dests.append(remap_path)
		var dep_files = cfg.get_value("deps", "dest_files", [])
		if dep_files is Array:
			for d in dep_files:
				if d is String and not dests.has(d):
					dests.append(d)
		for d in dests:
			# .ctex 本体と、再インポート判定に使われる .md5 の両方を消す
			for target in [d, str(d).get_basename() + ".md5"]:
				var abs_target: String = ProjectSettings.globalize_path(target)
				if FileAccess.file_exists(abs_target):
					if DirAccess.remove_absolute(abs_target) == OK:
						removed += 1
	var abs_import: String = ProjectSettings.globalize_path(import_res)
	if DirAccess.remove_absolute(abs_import) == OK:
		removed += 1
	return removed
