extends SceneTree
# 共通レイアウト定数を使うバトル立ち絵の保存回帰テスト。
# 実行: Godot --path godot --headless --script res://tests/RunBattleEditLayoutConstantSave.gd

func _initialize():
	var main = load("res://game/Main.gd").new()
	var lines: PackedStringArray = [
		'const _FIONA_LAYOUT := {"scale": 0.55, "side": "center", "position": [0, 37]}',
		'fiona.set_portrait(ARMOR_PORTRAIT, _FIONA_LAYOUT)',
	]
	var layout_name: String = main._battle_edit_layout_constant_name(lines[1])
	var result: Dictionary = main._battle_edit_update_layout_constant(lines, layout_name, 0.73, 21, -34)
	var updated: PackedStringArray = result["lines"]
	var ok: bool = layout_name == "_FIONA_LAYOUT" and result["found"] and result["changed"] \
		and '"scale": 0.73' in updated[0] and '"position": [21, -34]' in updated[0]
	printerr("[LAYOUT_SAVE] %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
