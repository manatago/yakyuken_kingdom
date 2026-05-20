extends TestSuite
class_name EditPanelTests

# 編集パネル構造の静的解析テスト
# Main.gd は GameState オートロード依存で test runner からインスタンス化できないので、
# ソースを文字列として読み、期待するボタン名・接続が存在するかを確認する。

func get_name() -> String:
	return "EditPanel"

func get_tests() -> Array:
	return [
		{"name": "story_edit_panel_has_buttons", "callable": Callable(self, "_test_story_panel_buttons")},
		{"name": "story_edit_panel_no_auto_btn", "callable": Callable(self, "_test_story_panel_no_auto")},
		{"name": "story_edit_buttons_connected", "callable": Callable(self, "_test_story_buttons_connected")},
		{"name": "battle_overlay_has_action_buttons", "callable": Callable(self, "_test_battle_overlay_action_buttons")},
		{"name": "battle_overlay_nav_connected", "callable": Callable(self, "_test_battle_overlay_nav_connected")},
		{"name": "battle_overlay_no_removed_nav", "callable": Callable(self, "_test_battle_overlay_no_removed_nav")},
		{"name": "no_orphan_auto_references", "callable": Callable(self, "_test_no_orphan_auto_refs")},
	]

# ---------- helpers ----------

const MAIN_PATH := "res://game/Main.gd"

func _read_main_source() -> String:
	var f := FileAccess.open(MAIN_PATH, FileAccess.READ)
	if f == null:
		return ""
	var txt := f.get_as_text()
	f.close()
	return txt

func _slice_function(src: String, func_name: String) -> String:
	var marker := "func %s(" % func_name
	var start := src.find(marker)
	if start < 0:
		return ""
	# 次の `func ` まで（行頭マッチ）
	var rest := src.substr(start)
	var line_idx := 0
	var lines := rest.split("\n", true)
	var collected := PackedStringArray()
	for line in lines:
		if line_idx > 0 and line.begins_with("func "):
			break
		collected.append(line)
		line_idx += 1
	return "\n".join(collected)

# ---------- tests ----------

func _test_story_panel_buttons() -> bool:
	# 新レイアウト: ナビ帯（PrevBtn/NextBtn/ExitBtn）＋ 左右カード（SaveBtn/CopyBtn を持つ）
	var src := _read_main_source()
	if src.is_empty():
		return fail("could not read Main.gd")
	var nav_body := _slice_function(src, "_create_story_edit_nav_bar")
	if nav_body.is_empty():
		return fail("_create_story_edit_nav_bar not found")
	var card_body := _slice_function(src, "_create_story_edit_char_card")
	if card_body.is_empty():
		return fail("_create_story_edit_char_card not found")
	var all_ok := true
	for needle in ['"PrevBtn"', '"NextBtn"', '"ExitBtn"']:
		if not nav_body.contains(needle):
			all_ok = fail("nav bar missing button name: %s" % needle) and false
	for needle in ['"SaveBtn"', '"CopyBtn"']:
		if not card_body.contains(needle):
			all_ok = fail("char card missing button name: %s" % needle) and false
	return all_ok

func _test_story_panel_no_auto() -> bool:
	# 旧 L/R トグルや自動進行ボタンが新レイアウトで残っていないこと
	var src := _read_main_source()
	var nav_body := _slice_function(src, "_create_story_edit_nav_bar")
	var card_body := _slice_function(src, "_create_story_edit_char_card")
	if nav_body.is_empty() or card_body.is_empty():
		return fail("story edit layout helpers not found")
	var all_ok := true
	for needle in ['"AutoBtn"', '"SideBtn"']:
		if nav_body.contains(needle):
			all_ok = fail("nav bar should NOT contain: %s" % needle) and false
		if card_body.contains(needle):
			all_ok = fail("char card should NOT contain: %s" % needle) and false
	return all_ok

func _test_story_buttons_connected() -> bool:
	var src := _read_main_source()
	var func_body := _slice_function(src, "_run_story_edit")
	if func_body.is_empty():
		return fail("_run_story_edit not found")
	var all_ok := true
	# ナビ帯のボタン connect
	for btn in ["prev_btn", "next_btn", "exit_btn"]:
		if not func_body.contains("%s.pressed.connect" % btn):
			all_ok = fail("_run_story_edit: %s.pressed.connect missing" % btn) and false
	# カード側の保存/コピーが connect されている（変数名は card 側）
	if not func_body.contains("save_btn_c.pressed.connect"):
		all_ok = fail("_run_story_edit: per-card save not connected") and false
	if not func_body.contains("copy_btn_c.pressed.connect"):
		all_ok = fail("_run_story_edit: per-card copy not connected") and false
	return all_ok

func _test_battle_overlay_action_buttons() -> bool:
	var src := _read_main_source()
	var func_body := _slice_function(src, "_create_edit_overlay")
	if func_body.is_empty():
		return fail("_create_edit_overlay not found")
	var all_ok := true
	# 表示テキストで確認
	for needle in ['"EditSaveButton"', '"EditBackButton"', 'text = "コピー"', '"PrevBtn"', '"NextBtn"', '"TargetLabel"']:
		if not func_body.contains(needle):
			all_ok = fail("_create_edit_overlay missing: %s" % needle) and false
	return all_ok

func _test_battle_overlay_nav_connected() -> bool:
	# _connect_edit_to_battle で ◀ / ▶ が pressed.connect されているか
	var src := _read_main_source()
	var func_body := _slice_function(src, "_connect_edit_to_battle")
	if func_body.is_empty():
		return fail("_connect_edit_to_battle not found")
	var all_ok := true
	for needle in ['prev_btn.pressed.connect', 'next_btn.pressed.connect', '_battle_edit_cycle_target']:
		if not func_body.contains(needle):
			all_ok = fail("_connect_edit_to_battle missing wire: %s" % needle) and false
	return all_ok

func _test_battle_overlay_no_removed_nav() -> bool:
	# 自動 / L/R は battle 側では使わないので無いことを確認
	var src := _read_main_source()
	var func_body := _slice_function(src, "_create_edit_overlay")
	if func_body.is_empty():
		return fail("_create_edit_overlay not found")
	var all_ok := true
	for needle in ['"AutoBtn"', '"SideBtn"']:
		if func_body.contains(needle):
			all_ok = fail("_create_edit_overlay should NOT contain: %s" % needle) and false
	return all_ok

func _test_no_orphan_auto_refs() -> bool:
	# 自動ボタン削除に伴うリファレンス漏れを検出
	var src := _read_main_source()
	var all_ok := true
	for needle in ["_story_edit_auto_mode", "_story_edit_toggle_auto", "_battle_edit_auto_mode", "_battle_edit_toggle_auto"]:
		if src.contains(needle):
			all_ok = fail("orphan auto-mode reference: %s" % needle) and false
	return all_ok
