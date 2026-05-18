extends SceneTree
# 回帰テスト: バトル編集モードがカードバトル（デッキ構築UI・カード選択待ち・
# じゃんけん演出・動画）を介さず、編集開始時点で各 outfit の全分岐立ち絵を
# 「勝負前 → 勝ち → 負け → 引き分け」の順で portrait_log に揃えることを検証する。
#   - ▶ を一切押さなくても全立ち絵が記録済み
#   - outfit ごとに 勝負前 → 勝ち → 負け → 引き分け の順序
#   - 重複する「勝負前」立ち絵は 1 つにまとめられる（重複排除）
#
# 実行: Godot --path godot --headless --script res://tests/RunBattleEditNoCardBattle.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[NOCARD] PASS: %s" % msg)
	else:
		printerr("[NOCARD] FAIL: %s" % msg)
		_fails += 1

func _names(main_inst) -> Array:
	var out: Array = []
	for e in main_inst._battle_edit_get_log():
		var tex: Texture2D = e.get("texture")
		out.append(tex.resource_path.get_file() if tex else "null")
	return out

func _initialize():
	printerr("[NOCARD] start")
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame

	var ch_info := {}
	for info in main_inst.EVENT_BATTLE_CHAPTERS:
		if info.get("id", "") == "prologue" and info.get("mode", "") == "battle":
			ch_info = info
			break
	main_inst._run_event_battle_edit(ch_info)
	# ▶ を一切押さずに、立ち絵キャプチャの完了を待つ
	for _w in range(120):
		await process_frame

	var names: Array = _names(main_inst)
	printerr("[NOCARD] portrait_log (no nav input) = %s" % str(names))

	# 編集開始時は履歴の先頭（最初の立ち絵 = 勝負前 guard_024）を表示しているはず
	_check(main_inst._battle_edit_history_idx == 0,
		"edit opens at first portrait (history_idx=%d)" % main_inst._battle_edit_history_idx)
	var sc0 = main_inst._battle_edit_ref._story_scene if is_instance_valid(main_inst._battle_edit_ref) else null
	if sc0:
		var r0: TextureRect = main_inst._find_visible_char_rect(sc0)
		var shown0: String = (r0.texture.resource_path.get_file() if r0 and r0.texture else "null")
		_check(shown0 == "guard_default_024.png",
			"first shown portrait is setup image guard_024 (got %s)" % shown0)

	# outfit_3 の全分岐立ち絵が揃っている（勝負前 guard_024 / 勝ち 014 / 負け 015 / 引き分け 012）
	for f in ["guard_default_024.png", "guard_default_014.png", "guard_default_015.png", "guard_default_012.png"]:
		_check(names.has(f), "log contains %s (outfit_3)" % f)
	# outfit_2 / outfit_1 の立ち絵も揃っている
	for f in ["guard_default_016.png", "guard_default_017.png", "guard_default_020.png", "guard_default_021.png"]:
		_check(names.has(f), "log contains %s" % f)

	# 順序: outfit_3 は 勝負前(024) → 勝ち(014) → 負け(015) → 引き分け(012)
	if names.has("guard_default_024.png") and names.has("guard_default_012.png"):
		var i024: int = names.find("guard_default_024.png")
		var i014: int = names.find("guard_default_014.png")
		var i015: int = names.find("guard_default_015.png")
		var i012: int = names.find("guard_default_012.png")
		_check(i024 < i014 and i014 < i015 and i015 < i012,
			"outfit_3 order is 勝負前→勝ち→負け→引き分け (%d<%d<%d<%d)" % [i024, i014, i015, i012])

	# 呼び出し位置ごとに1エントリ。prologue は setup + outfit_3/2/1 各4箇所
	# （勝負前/勝ち/負け/引き分け）で計13箇所。outfit を3回流しても各箇所1回ずつ。
	_check(names.size() == 13,
		"portrait_log has one entry per set_portrait call-site (expect 13, got %d)" % names.size())
	# guard_024 は setup_scene と outfit_3 冒頭の2箇所で使用 → 2エントリ
	# （3回流しで3倍に増えていない＝呼び出し位置での重複排除が効いている）
	var c024 := 0
	for n in names:
		if n == "guard_default_024.png":
			c024 += 1
	_check(c024 == 2, "guard_024 = one entry per call-site, not tripled by 3x runs (count=%d)" % c024)

	# テキストと画像の対応: outfit_3 の各分岐立ち絵に、その分岐のセリフが紐づいている
	var expect := {
		"guard_default_014.png": "変態",    # outfit_3 勝ち: 「くっ、変態の癖に。」
		"guard_default_015.png": "弱い",     # outfit_3 負け: 「やっぱり、真剣勝負も弱いわね。」
		"guard_default_012.png": "あいこ",   # outfit_3 引き分け: 「あいこか。首がつながったな。」
	}
	for e in main_inst._battle_edit_get_log():
		var tex: Texture2D = e.get("texture")
		if tex == null:
			continue
		var fn: String = tex.resource_path.get_file()
		if expect.has(fn):
			var d: Dictionary = e.get("dialogue", {})
			var txt: String = "%s %s %s" % [d.get("n_body", ""), d.get("l_body", ""), d.get("r_body", "")]
			_check(String(expect[fn]) in txt,
				"%s dialogue matches portrait (expect '%s', got '%s')" % [fn, expect[fn], txt.strip_edges()])

	printerr("[NOCARD] done, fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
