extends TestSuite

# 吹き出しに表示されるテキストが MAX_CHARS_PER_LINE / MAX_LINES に収まるかを検証する。
# BubbleWrap.wrap() を通した結果について、
#   - 1 行が MAX_CHARS_PER_LINE 文字以下
#   - 総行数が MAX_LINES 行以下（話者プレフィックス含む）
# でなければ失敗扱い。Claude Code が走らせて自律修正できるようにするため。

const BubbleWrap := preload("res://ui/BubbleWrap.gd")

func get_name() -> String:
	return "BubbleOverflow"

func get_tests() -> Array:
	return [
		{"name": "stage2_briefing_fits", "callable": Callable(self, "_test_stage2_briefing_fits")},
		{"name": "stage2_scenes_fit", "callable": Callable(self, "_test_stage2_scenes_fit")},
		{"name": "stage2_miss_scolds_fit", "callable": Callable(self, "_test_stage2_miss_scolds_fit")},
		{"name": "stage2_miss_choice_labels_fit", "callable": Callable(self, "_test_stage2_miss_choice_labels_fit")},
		{"name": "stage3_scenes_fit", "callable": Callable(self, "_test_stage3_scenes_fit")},
		{"name": "stage3_miss_lines_fit", "callable": Callable(self, "_test_stage3_miss_lines_fit")},
		{"name": "stage5_pisuke_finishes_fit", "callable": Callable(self, "_test_stage5_pisuke_finishes_fit")},
	]

# --- ヘルパー ---

func _check_text(label: String, text: String, failures: Array) -> void:
	var wrapped: String = BubbleWrap.wrap(text)
	var lines: PackedStringArray = wrapped.split("\n")
	if lines.size() > BubbleWrap.MAX_LINES:
		failures.append("[%s] 行数超過 (%d > %d): %s" % [label, lines.size(), BubbleWrap.MAX_LINES, _preview(text)])
	for i in range(lines.size()):
		var line: String = lines[i]
		if line.length() > BubbleWrap.MAX_CHARS_PER_LINE:
			failures.append("[%s] 文字数超過 (%d > %d): line %d = \"%s\"" % [label, line.length(), BubbleWrap.MAX_CHARS_PER_LINE, i + 1, line])

func _preview(text: String) -> String:
	var p: String = text.replace("\n", " / ")
	if p.length() > 60:
		p = p.substr(0, 60) + "…"
	return p

func _report(failures: Array) -> bool:
	if failures.size() == 0:
		return true
	for f in failures:
		push_error(f)
	push_error("--- 計 %d 件のはみ出しを検出 ---" % failures.size())
	return false

# --- Stage2 テスト ---

func _test_stage2_briefing_fits() -> bool:
	# Stage2MinigameChapter._play_briefing で出力される 7 メッセージを再現
	var failures: Array = []
	_check_text("briefing-1", "レイラ:\n……再検証、開始いたします。\n条件は、前回と同様で。", failures)
	_check_text("briefing-2", "サトシ（ピー助の声色で）:\n……レイラさん、一つだけ、\n伺ってもよろしいですか。", failures)
	_check_text("briefing-3", "レイラ:\n……ええ、どうぞ。", failures)
	_check_text("briefing-4", "サトシ（ピー助の声色で）:\nあなたの所作、見事でした。\nですが、一点だけ、引っかかって。", failures)
	_check_text("briefing-5", "サトシ（ピー助の声色で）:\n本当は、男に触れたこと、\n一度もないんでしょう？", failures)
	_check_text("briefing-6", "レイラ:\n……っ、ふざけたことを。\n男の体なんて、何度でも、見てきたわ。", failures)
	_check_text("briefing-7", "サトシ（ピー助の声色で）:\nじゃあ、確かめさせてもらいますね。\n表情を動かさなければ、信じます。", failures)
	return _report(failures)

func _test_stage2_scenes_fit() -> bool:
	var chapter = preload("res://battle/chapters/Stage2MinigameChapter.gd").new()
	var failures: Array = []
	for i in range(chapter.SCENES.size()):
		var scene: Dictionary = chapter.SCENES[i]
		_check_text("scene[%d].pisuke_line" % i, "ピー助:\n%s" % scene.get("pisuke_line", ""), failures)
		_check_text("scene[%d].satoshi_hit" % i, "サトシ:\n%s" % scene.get("satoshi_hit", ""), failures)
		# pile_on は 1 行 1 バブルで配信される
		var pile_on: String = scene.get("pile_on", "")
		var pile_lines: PackedStringArray = pile_on.split("\n")
		for j in range(pile_lines.size()):
			var prefix: String = "ピー助（畳みかけて）:" if j == 0 else "ピー助:"
			_check_text("scene[%d].pile_on[%d]" % [i, j], "%s\n%s" % [prefix, pile_lines[j]], failures)
		_check_text("scene[%d].layla_pile" % i, "レイラ:\n%s" % scene.get("layla_pile", ""), failures)
	return _report(failures)

func _test_stage2_miss_scolds_fit() -> bool:
	var chapter = preload("res://battle/chapters/Stage2MinigameChapter.gd").new()
	var failures: Array = []
	for key in chapter.MISS_SCOLDS.keys():
		var text: String = "ピー助（小声で叱責）:\n%s" % chapter.MISS_SCOLDS[key]
		_check_text("miss_scold[%s]" % key, text, failures)
	return _report(failures)

func _test_stage2_miss_choice_labels_fit() -> bool:
	# _play_miss でサトシが叫ぶ「choice」がそのままナレーターに流れるので確認
	var chapter = preload("res://battle/chapters/Stage2MinigameChapter.gd").new()
	var failures: Array = []
	for key in chapter.EXPRESSIONS.keys():
		var info: Dictionary = chapter.EXPRESSIONS[key]
		var text: String = "サトシ:\n%s" % info.get("choice", "")
		_check_text("expression[%s]" % key, text, failures)
	return _report(failures)

# --- Stage3 テスト ---

func _test_stage3_scenes_fit() -> bool:
	# 10 通りの正解組み合わせ（VALID_COMBOS）について：
	#   - サトシ朗読バブル（本＋物証で 2 バブル）
	#   - マグダレナ動揺バブル
	#   - ピー助の畳みかけ追撃（1 行 1 バブル）
	#   - マグダレナ崩れ反応バブル
	# が、すべてバブル幅・行数に収まることを検証
	var chapter = preload("res://battle/chapters/Stage3MinigameChapter.gd").new()
	var failures: Array = []
	# 本＋物証朗読（毎ターン共通フォーマット）
	for c_key in chapter.CHAPTER_KEYS:
		var c_info: Dictionary = chapter.CHAPTERS.get(c_key, {})
		_check_text("st3.satoshi.chapter[%s]" % c_key, "サトシ:\n聖女マグダレナ様。\n%s より。" % c_info.get("satoshi_line", ""), failures)
	for e_key in chapter.EVIDENCE_KEYS:
		var e_info: Dictionary = chapter.EVIDENCES.get(e_key, {})
		_check_text("st3.satoshi.evidence[%s]" % e_key, "サトシ:\n%s、ございます。" % e_info.get("satoshi_line", ""), failures)
	# 各正解組み合わせの HIT 反応
	for i in range(chapter.VALID_COMBOS.size()):
		var combo: Dictionary = chapter.VALID_COMBOS[i]
		_check_text("st3.combo[%d].mag_react" % i, "マグダレナ:\n%s" % combo.get("mag_react", ""), failures)
		var chase: Array = combo.get("pisuke_chase", [])
		for j in range(chase.size()):
			var prefix: String = "ピー助（畳みかけて）:" if j == 0 else "ピー助:"
			_check_text("st3.combo[%d].chase[%d]" % [i, j], "%s\n%s" % [prefix, chase[j]], failures)
		var pile: String = combo.get("mag_pile", "")
		if not pile.is_empty():
			_check_text("st3.combo[%d].mag_pile" % i, "マグダレナ:\n%s" % pile, failures)
	return _report(failures)

func _test_stage5_pisuke_finishes_fit() -> bool:
	# ST5 の各 question.hit.pisuke_finish（配列）について、1 行 1 バブル想定で検証
	var chapter = preload("res://battle/chapters/Stage5MinigameChapter.gd").new()
	var failures: Array = []
	var pools: Array = [chapter.QUESTIONS_RED, chapter.QUESTIONS_STRONG]
	var pool_names: Array = ["R", "S"]
	for p in range(pools.size()):
		var pool: Array = pools[p]
		for i in range(pool.size()):
			var q: Dictionary = pool[i]
			var hit: Dictionary = q.get("hit", {})
			var finish: Variant = hit.get("pisuke_finish", "")
			var lines: Array = []
			if finish is Array or finish is PackedStringArray:
				lines = Array(finish)
			else:
				lines = String(finish).split("\n")
			for j in range(lines.size()):
				var prefix: String = "ピー助（畳みかけて）:" if j == 0 else "ピー助:"
				_check_text("st5.%s%d.finish[%d]" % [pool_names[p], i + 1, j], "%s\n%s" % [prefix, lines[j]], failures)
	return _report(failures)

func _test_stage3_miss_lines_fit() -> bool:
	# 不正解組み合わせ／既使用組み合わせの汎用 MISS 反応を検証
	var chapter = preload("res://battle/chapters/Stage3MinigameChapter.gd").new()
	var failures: Array = []
	_check_text("st3.MISS_MAG", "マグダレナ:\n%s" % chapter.MISS_MAG, failures)
	_check_text("st3.MISS_SCOLD", "ピー助（小声で叱責）:\n%s" % chapter.MISS_SCOLD, failures)
	_check_text("st3.ALREADY_USED_MAG", "マグダレナ:\n%s" % chapter.ALREADY_USED_MAG, failures)
	_check_text("st3.ALREADY_USED_SCOLD", "ピー助（小声で叱責）:\n%s" % chapter.ALREADY_USED_SCOLD, failures)
	return _report(failures)
