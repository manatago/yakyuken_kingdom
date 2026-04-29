extends BattleChapterBase

# ST3「聖女マグダレナ」ミニゲーム（2 軸組み合わせ式）
#
# 設計：
# - 本のジャンル列（5 択）× 物証列（5 択）＝ 25 通りの組み合わせ
# - そのうち **10 通りが正解**（各ジャンルに 2 通りの正解物証が紐づく）
# - 毎ターン プレイヤーが本＋物証を 1 つずつ選び、決定で攻撃
# - HIT (-50)：未使用の正解組み合わせを引いた場合 → 妄想直撃 ＋ 畳みかけ追撃
# - MISS (+5)：不正解の組み合わせ ＋ 既使用の正解（どちらも生半可な反応）
# - 3 HIT で勝利（信仰の威厳 140 → 0）／180 到達で敗北
# - ピー助任せ：未使用の正解組み合わせから 1 つランダム選出（HIT 確定）

const MAGDALENA_PORTRAIT := "res://assets/characters/stage3/magdalena_001.png"
const MAGDALENA_ICON := "res://assets/ui/speakers/magdalena_default.png"
const MAGDALENA_ID := "magdalena"

const GAUGE_MAX := 180
const GAUGE_START := 140

const HIT_DELTA := -50
const MISS_DELTA := 5

# --- 章列（5 択） ---
# サトシが懺悔室に持ち込む 1 冊（マグダレナの自選集）の章を選ぶ。
const CHAPTERS := {
	"bath":     {"label": "「湯浴み」章",         "satoshi_line": "「湯浴み」章"},
	"guardian": {"label": "「相互加護」章",       "satoshi_line": "「相互加護」章"},
	"oath":     {"label": "「朝露の誓い」章",     "satoshi_line": "「朝露の誓い」章"},
	"chest":    {"label": "「胸筋と誓約」章",     "satoshi_line": "「胸筋と誓約」章"},
	"draft":    {"label": "「書きかけ草稿」章",   "satoshi_line": "「書きかけ草稿」章"},
}
const CHAPTER_KEYS := ["bath", "guardian", "oath", "chest", "draft"]

# --- 物証列（5 択） ---
const EVIDENCES := {
	"page_stain":    {"label": "ページ三十七行目の白い滲み", "satoshi_line": "ページ三十七行目に、白い滲みが"},
	"finger_trace":  {"label": "ページ裏の指で撫でた跡",     "satoshi_line": "ページの裏側に、指の跡が"},
	"pillow_stain":  {"label": "枕カバーの白濁した飛沫",     "satoshi_line": "枕カバーに、白濁した飛沫が、点々と"},
	"cover_finger":  {"label": "表紙の指の形の白い染み",     "satoshi_line": "表紙に、指の形の白い染みが"},
	"margin_stain":  {"label": "余白の白濁した染み",         "satoshi_line": "余白に、白濁した染みが、点々と"},
}
const EVIDENCE_KEYS := ["page_stain", "finger_trace", "pillow_stain", "cover_finger", "margin_stain"]

# --- 正解組み合わせ 7 件 ---
# 章×物証で 5×5 = 25 セル中、7 セルが正解。テーマ重複を排除した構成。
#   bath     : page_stain  + finger_trace
#   guardian : finger_trace + pillow_stain
#   oath     : page_stain
#   chest    : cover_finger
#   draft    : margin_stain
const VALID_COMBOS := [
	# 1. bath × page_stain（湯浴み章のページ三十七行目の白濁滲み）
	{
		"chapter": "bath",
		"evidence": "page_stain",
		"mag_react": "……っ！ そ、その章は、どこで……どこで手に！",
		"mag_thought": "床板の下、なぜ、なぜそこに……！",
		"pisuke_chase": [
			"──ページ三十七行目、白濁した滲み。",
			"──騎士二人、湯気の中で、硬いアレを擦り合う、淫靡な描写。",
			"──読みながら片手でご自身を慰め、ページに白いのを散らしています。",
			"──毎晩、湯浴みの章で自分を慰めて、愛液を撒き散らしてしまったんですよね？",
		],
		"mag_pile": "……っ！ ……や、やめて、もう、許して……！",
	},
	# 2. bath × finger_trace（湯浴み章のページ裏の指跡）
	{
		"chapter": "bath",
		"evidence": "finger_trace",
		"mag_react": "……っ！ そ、その章のページ裏まで、なぜ──！",
		"mag_thought": "湯浴み章、何度も読み返したから、指の跡が、ページ裏にまで……！",
		"pisuke_chase": [
			"──湯浴み章の裏側、指の腹で何度も撫でた跡。",
			"──騎士二人が湯気で抱き合う場面、何十回読み返したのか。",
			"──興奮で湿った指の脂、紙の繊維に染み込んでます。",
			"──ページを撫でながら、もう片手で自分の敏感なところを触って慰めていたんですよね？",
		],
		"mag_pile": "……っ！ ……あの章は、わたくしの、聖域なのに……！",
	},
	# 3. guardian × finger_trace（相互加護章のページ裏指跡）
	{
		"chapter": "guardian",
		"evidence": "finger_trace",
		"mag_react": "……っ！ ぃ、いえ、それは、戦友愛の、神聖な描写で──！",
		"mag_thought": "肩を抱く、絡む指先、わたくしの……一番の章……！",
		"pisuke_chase": [
			"──相互加護のページ裏、汗で湿った指の跡。",
			"──戦友二人が汗だくで、互いの肌を抱き合う、その瞬間。",
			"──指の腹で、何度も、何度も、撫でた跡ですよね？",
			"──戦友の絡みを読みながら、自分のアソコを掻き回してたんですよね？",
		],
		"mag_pile": "……っ！ ……お願い、もう、見ないで……！",
	},
	# 4. guardian × pillow_stain（相互加護章を読みながら枕に飛んだ白濁）
	{
		"chapter": "guardian",
		"evidence": "pillow_stain",
		"mag_react": "……っ！ そ、それは、寝具の、汚れで──！",
		"mag_thought": "相互加護の章を読みながら、わたくし、枕に……！",
		"pisuke_chase": [
			"──枕カバーに、白濁した飛沫が、点々と。",
			"──相互加護を読み終えた瞬間、ご自身が果てた跡。",
			"──戦友二人が抱き合う場面、ベッドの上で読みながら。",
			"──毎晩、相互加護の章で果てて、枕を愛液で濡らしてしまったんですよね？",
		],
		"mag_pile": "……っ！ ……枕の、染みまで……！",
	},
	# 5. oath × page_stain（朝露の誓い章のページ滲み）
	{
		"chapter": "oath",
		"evidence": "page_stain",
		"mag_react": "……っ！ そ、その章のページにまで、滲みなど──！",
		"mag_thought": "双子の絡み、夜明けの場面、わたくし、読みながら……！",
		"pisuke_chase": [
			"──双子剣士の絡みの場面、ページに、白濁の滲み。",
			"──夜明けに兄弟が指を絡める描写、夢中になられて。",
			"──ページを濡らしたのは、朝露ではない、ですよね？",
			"──双子が絡む場面で、自分のアソコに指を入れて、果ててたんですよね？",
		],
		"mag_pile": "……っ！ ……双子の絡みまで、見られて……！",
	},
	# 6. chest × cover_finger（胸筋と誓約章を含む本の表紙の指染み）
	{
		"chapter": "chest",
		"evidence": "cover_finger",
		"mag_react": "……っ！ あ、汗、です、汗の染み、長年の使用で──！",
		"mag_thought": "あの本、誰にも触らせていないのに、なぜ……！",
		"pisuke_chase": [
			"──鑑定魔法によると、これ、汗ではございません。",
			"──白濁した体液、人差し指と中指の、二本の形で。",
			"──片手で本を持ちながら、もう一方の手で何を？",
			"──毎晩、この本を腿の間に挟んで、擦りつけて果ててたんですよね？",
		],
		"mag_pile": "……っ！ ……あの本だけは、あの本だけは……！",
	},
	# 7. draft × margin_stain（書きかけ草稿章の余白に白濁染み）
	{
		"chapter": "draft",
		"evidence": "margin_stain",
		"mag_react": "……っ！ そ、それは、墨の、撥ねた跡で──！",
		"mag_thought": "書きながら、つい、片手で……まさか、それまで……！",
		"pisuke_chase": [
			"──余白の点々染み、墨ではございません。",
			"──検出されたのは、ご本人の、白濁した体液でして。",
			"──執筆に夢中になりながら、もう一方の手で何を？",
			"──書きながら、片手は筆、もう片手で自分のアソコをいじっていたんですよね？",
		],
		"mag_pile": "……っ！ ……書斎を、見られた、書斎を……！",
	},
]

# --- MISS 時の汎用反応 ---
const MISS_MAG := "……？ その物証、わたくしには、心当たりが……。"
const MISS_SCOLD := "ゲコッ、組み合わせが違う！\n本と物証、別の対応を試せ！"

# 既使用 HIT に再挑戦したとき
const ALREADY_USED_MAG := "……そのお話、先ほど伺いました。"
const ALREADY_USED_SCOLD := "ゲコッ、もう使った組み合わせだ！\n別の本×物証を試せ！"

func get_opponent_id() -> String:
	return MAGDALENA_ID

func get_opponent_name() -> String:
	return "マグダレナ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/subevent2/bg05_church_peep_room.png"

func get_lose_behavior() -> String:
	return "continue"

func setup_scene(bt):
	var mag = bt.character(MAGDALENA_ID)
	mag.set_portrait(MAGDALENA_PORTRAIT, {"scale": 0.55, "side": "center", "position": [0, -200]})

# --- 状態 ---
var _gauge: int = GAUGE_START
var _selected_chapter: String = ""
var _selected_evidence: String = ""
var _used_combo_keys: Array = []  # "knight|page_stain" 形式
var _turns_done: int = 0  # ピー助ロック用（1 ターン自力プレイ後解放）

# --- UI 参照 ---
var _ui_root: Control = null
var _gauge_bar: ColorRect = null
var _gauge_label: Label = null
var _gauge_stack: Control = null
var _chapter_buttons: Array[Button] = []
var _evidence_buttons: Array[Button] = []
var _decide_button: Button = null
var _pisuke_button: Button = null

signal _action_triggered(action: String)

func minigame(bt):
	_gauge = GAUGE_START
	_used_combo_keys.clear()
	_turns_done = 0
	_selected_chapter = ""
	_selected_evidence = ""

	_build_ui(bt)
	_update_gauge_display()
	_set_buttons_active(false)
	_set_buttons_visible(false)
	await bt.wait(0.3)

	await _play_intro(bt)
	await _play_scripted_opening(bt)

	while _gauge > 0 and _gauge < GAUGE_MAX:
		_selected_chapter = ""
		_selected_evidence = ""
		_refresh_button_highlights()
		_set_buttons_visible(true)
		_set_buttons_active(true)

		var action: String = await _action_triggered

		_set_buttons_active(false)
		_set_buttons_visible(false)

		if action == "_pisuke":
			await _apply_pisuke(bt)
		else:
			await _apply_choice(bt, _selected_chapter, _selected_evidence)
		_turns_done += 1

	_teardown_ui()

	if _gauge <= 0:
		bt.dialogue_band("narrator", "マグダレナの手から聖典が滑り落ちる。\n小窓の向こうで両手に顔を埋め、項垂れたまま動かない。\n「……もう、お許しください……！」", true)
		await bt.wait(0.0)
		bt.hide_dialogue_band()
		await bt.wait(0.0)
		return "win"
	else:
		bt.dialogue_band("narrator", "マグダレナが懺悔室の扉を蹴り開け、高らかに宣告した。\n「魂の浄化を装った冒涜、もはや異端。焚刑に処す」\n——サトシは信徒たちに取り押さえられ、火刑台へ連行された。", true)
		await bt.wait(0.0)
		bt.hide_dialogue_band()
		await bt.wait(0.0)
		return "lose"

# --- 導入 ---

func _play_intro(bt):
	bt.dialogue_band("narrator", "【懺悔室で妄想を誘発せよ】\n本と物証の組み合わせを変えて、\n彼女の妄想スイッチを的確に突け。", true)
	await bt.wait(0.0)
	bt.dialogue_band("narrator", "【勝敗】\n「信仰の威厳」を 0 で勝利。\n180 到達で焚刑に処される。", true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

func _play_scripted_opening(bt):
	bt.dialogue_band("narrator", "懺悔室。薄暗い小窓を挟んで、二人きり。\nマグダレナは聖典を手に、悔悛の朗読を待っている。", true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n聖女マグダレナ様。\n朗読を、始めさせていただきます。", "satoshi", "res://assets/ui/speakers/satoshi_apologetic.png")
	await bt.wait(0.0)

	bt.set_bubble_side("right")
	bt.narrator_band("マグダレナ:\n……ええ。罪人の魂、\nわたくしが受け止めましょう。", MAGDALENA_ID, MAGDALENA_ICON)
	await bt.wait(0.0)

# --- 結果適用 ---

func _apply_choice(bt, chapter: String, evidence: String):
	var c_info: Dictionary = CHAPTERS.get(chapter, {})
	var e_info: Dictionary = EVIDENCES.get(evidence, {})

	# サトシの朗読＋物証提示（2 バブル）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n聖女マグダレナ様。\n%s より。" % c_info.get("satoshi_line", ""), "satoshi", "res://assets/ui/speakers/satoshi_gentle.png")
	await bt.wait(0.0)
	bt.narrator_band("サトシ:\n%s、ございます。" % e_info.get("satoshi_line", ""), "satoshi", "res://assets/ui/speakers/satoshi_gentle.png")
	await bt.wait(0.0)

	var combo: Dictionary = _find_valid_combo(chapter, evidence)
	var combo_key: String = "%s|%s" % [chapter, evidence]

	if not combo.is_empty():
		if _used_combo_keys.has(combo_key):
			# 既使用：弱反応
			await _play_already_used(bt)
			_gauge = clamp(_gauge + MISS_DELTA, 0, GAUGE_MAX)
		else:
			await _play_hit(bt, combo)
			_used_combo_keys.append(combo_key)
			_gauge = clamp(_gauge + HIT_DELTA, 0, GAUGE_MAX)
	else:
		# 不正解組み合わせ：MISS
		await _play_miss(bt)
		_gauge = clamp(_gauge + MISS_DELTA, 0, GAUGE_MAX)
	_update_gauge_display()

func _find_valid_combo(chapter: String, evidence: String) -> Dictionary:
	for combo in VALID_COMBOS:
		if combo.get("chapter", "") == chapter and combo.get("evidence", "") == evidence:
			return combo
	return {}

func _play_hit(bt, combo: Dictionary):
	bt.set_bubble_side("right")
	bt.narrator_band("マグダレナ:\n%s" % combo.get("mag_react", ""), MAGDALENA_ID, MAGDALENA_ICON)
	await bt.wait(0.0)

	# ピー助の畳みかけ追撃（1 行 1 バブル）
	var chase: Array = combo.get("pisuke_chase", [])
	for i in range(chase.size()):
		var prefix: String = "ピー助（畳みかけて）:" if i == 0 else "ピー助:"
		bt.set_bubble_side("bottom-left")
		bt.narrator_band("%s\n%s" % [prefix, chase[i]], "pisuke")
		await bt.wait(0.0)

	var pile: String = combo.get("mag_pile", "")
	if not pile.is_empty():
		bt.set_bubble_side("right")
		bt.narrator_band("マグダレナ:\n%s" % pile, MAGDALENA_ID, MAGDALENA_ICON)
		await bt.wait(0.0)

	bt.dialogue_band("narrator", "妄想直撃！\n（信仰の威厳 %d）" % HIT_DELTA, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

func _play_miss(bt):
	bt.set_bubble_side("right")
	bt.narrator_band("マグダレナ:\n%s" % MISS_MAG, MAGDALENA_ID, MAGDALENA_ICON)
	await bt.wait(0.0)

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("ピー助（小声で叱責）:\n%s" % MISS_SCOLD, "pisuke")
	await bt.wait(0.0)

	bt.dialogue_band("narrator", "見当違い、シラけられた。\n（信仰の威厳 +%d）" % MISS_DELTA, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

func _play_already_used(bt):
	bt.set_bubble_side("right")
	bt.narrator_band("マグダレナ:\n%s" % ALREADY_USED_MAG, MAGDALENA_ID, MAGDALENA_ICON)
	await bt.wait(0.0)

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("ピー助（小声で叱責）:\n%s" % ALREADY_USED_SCOLD, "pisuke")
	await bt.wait(0.0)

	bt.dialogue_band("narrator", "同じネタ、二度目は刺さらない。\n（信仰の威厳 +%d）" % MISS_DELTA, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

func _apply_pisuke(bt):
	# 未使用の正解組み合わせから 1 つランダム選出
	var unused: Array = []
	for combo in VALID_COMBOS:
		var key: String = "%s|%s" % [combo.get("chapter", ""), combo.get("evidence", "")]
		if not _used_combo_keys.has(key):
			unused.append(combo)
	if unused.is_empty():
		return  # 全消費（理論上 win 直前で起きない）
	unused.shuffle()
	var combo: Dictionary = unused[0]
	var c_info: Dictionary = CHAPTERS.get(combo.get("chapter", ""), {})
	var e_info: Dictionary = EVIDENCES.get(combo.get("evidence", ""), {})

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n……えっと、どれを選べば──", "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)
	bt.narrator_band("ピー助（小声）:\n%s と、%s。\nこれを組み合わせろ。" % [c_info.get("label", ""), e_info.get("label", "")], "pisuke")
	await bt.wait(0.0)

	await _apply_choice(bt, combo.get("chapter", ""), combo.get("evidence", ""))

# --- UI 構築 ---

func _build_ui(bt: Node):
	_ui_root = Control.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bt.add_child(_ui_root)

	# ゲージ（左上）
	_gauge_stack = Control.new()
	_gauge_stack.position = Vector2(40, 40)
	_gauge_stack.size = Vector2(600, 60)
	_ui_root.add_child(_gauge_stack)
	_build_gauge()

	# 列ヘッダー
	_make_column_header("本のジャンル", Vector2(40, 120))
	_make_column_header("物証",         Vector2(490, 120))

	# 本ボタン（左列・5 個）
	var book_root := VBoxContainer.new()
	book_root.position = Vector2(40, 170)
	book_root.size = Vector2(440, 320)
	book_root.add_theme_constant_override("separation", 6)
	_ui_root.add_child(book_root)

	_chapter_buttons.clear()
	for i in range(CHAPTER_KEYS.size()):
		var key: String = CHAPTER_KEYS[i]
		var info: Dictionary = CHAPTERS.get(key, {})
		var btn := _make_choice_button("[%d] %s" % [i + 1, info.get("label", key)])
		var key_capture: String = key
		btn.pressed.connect(func(): _on_chapter_pressed(key_capture))
		book_root.add_child(btn)
		_chapter_buttons.append(btn)

	# 物証ボタン（右列・5 個）
	var evidence_root := VBoxContainer.new()
	evidence_root.position = Vector2(490, 170)
	evidence_root.size = Vector2(440, 320)
	evidence_root.add_theme_constant_override("separation", 6)
	_ui_root.add_child(evidence_root)

	_evidence_buttons.clear()
	for i in range(EVIDENCE_KEYS.size()):
		var key: String = EVIDENCE_KEYS[i]
		var info: Dictionary = EVIDENCES.get(key, {})
		var btn := _make_choice_button("[%d] %s" % [i + 6, info.get("label", key)])
		var key_capture: String = key
		btn.pressed.connect(func(): _on_evidence_pressed(key_capture))
		evidence_root.add_child(btn)
		_evidence_buttons.append(btn)

	# 決定 + ピー助任せ（下、横並び）
	var bottom_root := HBoxContainer.new()
	bottom_root.position = Vector2(40, 510)
	bottom_root.size = Vector2(900, 56)
	bottom_root.add_theme_constant_override("separation", 16)
	_ui_root.add_child(bottom_root)

	_decide_button = _make_choice_button("[決定] この組み合わせで攻撃")
	_decide_button.custom_minimum_size = Vector2(440, 56)
	_decide_button.pressed.connect(func(): _on_decide_pressed())
	bottom_root.add_child(_decide_button)

	_pisuke_button = _make_choice_button("[ピー助任せ]")
	_pisuke_button.custom_minimum_size = Vector2(440, 56)
	_pisuke_button.pressed.connect(func(): _on_pisuke_pressed())
	bottom_root.add_child(_pisuke_button)

func _make_column_header(text: String, pos: Vector2):
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(440, 36)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ui_root.add_child(label)

func _build_gauge():
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.06, 0.06, 0.09, 0.95)
	fs.border_width_left = 2
	fs.border_width_right = 2
	fs.border_width_top = 2
	fs.border_width_bottom = 2
	fs.border_color = Color(0.55, 0.55, 0.62, 1.0)
	fs.corner_radius_top_left = 10
	fs.corner_radius_top_right = 10
	fs.corner_radius_bottom_left = 10
	fs.corner_radius_bottom_right = 10
	fs.shadow_color = Color(0, 0, 0, 0.55)
	fs.shadow_size = 6
	fs.shadow_offset = Vector2(0, 3)
	frame.add_theme_stylebox_override("panel", fs)
	_gauge_stack.add_child(frame)

	var track := Control.new()
	track.anchor_left = 0.0
	track.anchor_top = 0.0
	track.anchor_right = 1.0
	track.anchor_bottom = 1.0
	track.offset_left = 5
	track.offset_top = 5
	track.offset_right = -5
	track.offset_bottom = -5
	track.clip_contents = true
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge_stack.add_child(track)

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.15, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.add_child(bg)

	_gauge_bar = ColorRect.new()
	_gauge_bar.color = Color(0.85, 0.20, 0.20)
	_gauge_bar.position = Vector2(0, 0)
	_gauge_bar.anchor_top = 0.0
	_gauge_bar.anchor_bottom = 1.0
	track.add_child(_gauge_bar)

	_gauge_label = Label.new()
	_gauge_label.text = "信仰の威厳"
	_gauge_label.add_theme_font_size_override("font_size", 22)
	_gauge_label.add_theme_color_override("font_color", Color.WHITE)
	_gauge_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_gauge_label.add_theme_constant_override("shadow_outline_size", 3)
	_gauge_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gauge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gauge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gauge_stack.add_child(_gauge_label)

func _make_choice_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 20)
	btn.custom_minimum_size = Vector2(440, 48)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.18, 0.18, 0.22, 0.95)
		var border_col := Color(0.95, 0.78, 0.30, 0.95)
		if state == "hover":
			sb.bg_color = Color(0.30, 0.26, 0.18, 0.95)
			border_col = Color(1.0, 0.90, 0.45, 1.0)
		elif state == "pressed":
			sb.bg_color = Color(0.50, 0.40, 0.10, 0.95)
			border_col = Color(0.95, 0.78, 0.30, 1.0)
		elif state == "disabled":
			sb.bg_color = Color(0.18, 0.18, 0.22, 0.55)
			border_col = Color(0.60, 0.50, 0.25, 0.50)
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = border_col
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.content_margin_left = 16
		sb.content_margin_right = 8
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		btn.add_theme_stylebox_override(state, sb)
	return btn

func _teardown_ui():
	if _ui_root and is_instance_valid(_ui_root):
		_ui_root.queue_free()
	_ui_root = null
	_gauge_bar = null
	_gauge_label = null
	_gauge_stack = null
	_chapter_buttons.clear()
	_evidence_buttons.clear()
	_decide_button = null
	_pisuke_button = null

func _update_gauge_display():
	if not _gauge_bar:
		return
	var ratio: float = float(_gauge) / float(GAUGE_MAX)
	var parent_w: float = 590.0
	if _gauge_bar.get_parent() is Control:
		parent_w = (_gauge_bar.get_parent() as Control).size.x
	_gauge_bar.size.x = parent_w * ratio
	_gauge_bar.color = _gauge_color(_gauge)
	if _gauge_label:
		_gauge_label.text = "信仰の威厳  %d / %d" % [_gauge, GAUGE_MAX]

func _gauge_color(value: int) -> Color:
	if value >= 130:
		return Color(0.85, 0.20, 0.20)
	elif value >= 60:
		return Color(0.90, 0.78, 0.20)
	else:
		return Color(0.30, 0.78, 0.30)

func _set_buttons_active(active: bool):
	for btn in _chapter_buttons:
		btn.disabled = not active
	for btn in _evidence_buttons:
		btn.disabled = not active
	if _decide_button:
		_decide_button.disabled = not active or _selected_chapter.is_empty() or _selected_evidence.is_empty()
	if _pisuke_button:
		# ピー助は 1 ターン自力プレイ後に解放（2 ターン目から使用可）
		if not active:
			_pisuke_button.disabled = true
		else:
			_pisuke_button.disabled = (_turns_done < 1)
			if _turns_done >= 1:
				_pisuke_button.text = "[ピー助任せ]"
			else:
				_pisuke_button.text = "[ピー助任せ]（残り 1 ターン）"

func _set_buttons_visible(visible: bool):
	for btn in _chapter_buttons:
		btn.visible = visible
	for btn in _evidence_buttons:
		btn.visible = visible
	if _decide_button:
		_decide_button.visible = visible
	if _pisuke_button:
		_pisuke_button.visible = visible

func _refresh_button_highlights():
	for i in range(_chapter_buttons.size()):
		var key: String = CHAPTER_KEYS[i]
		_chapter_buttons[i].text = "[%d] %s%s" % [i + 1, "▶ " if key == _selected_chapter else "", CHAPTERS.get(key, {}).get("label", key)]
	for i in range(_evidence_buttons.size()):
		var key: String = EVIDENCE_KEYS[i]
		_evidence_buttons[i].text = "[%d] %s%s" % [i + 6, "▶ " if key == _selected_evidence else "", EVIDENCES.get(key, {}).get("label", key)]
	if _decide_button:
		_decide_button.disabled = _selected_chapter.is_empty() or _selected_evidence.is_empty()

func _on_chapter_pressed(key: String):
	_selected_chapter = key
	_refresh_button_highlights()

func _on_evidence_pressed(key: String):
	_selected_evidence = key
	_refresh_button_highlights()

func _on_decide_pressed():
	if _selected_chapter.is_empty() or _selected_evidence.is_empty():
		return
	_action_triggered.emit("_combo")

func _on_pisuke_pressed():
	if _turns_done < 1:
		return
	_action_triggered.emit("_pisuke")
