extends BattleChapterBase

# ST3「聖女マグダレナ」ミニゲーム（2 軸独立選択の組み合わせ式）
#
# 設計：
# - 本の章（CHAPTERS）と物証（EVIDENCES）はそれぞれ HIT 用キーと MISS 用キーに分かれる:
#     * HIT_CHAPTER_KEYS (7)  : マグダレナの自選集の章。VALID_COMBOS に 1 回ずつ登場
#     * MISS_CHAPTER_KEYS (8) : ありきたりな本（聖戦の譜・建国記など）。デコイ
#     * HIT_EVIDENCE_KEYS (7) : 白濁／指跡など示唆的物証。VALID_COMBOS に 1 回ずつ登場
#     * MISS_EVIDENCE_KEYS (8): 栞・埃・折り目など普通の痕跡。デコイ
# - VALID_COMBOS = 7 通り（章 7 × 物証 7 の 1 対 1 マッピング、各キーは 1 回ずつ登場）
# - 毎ターンの提示:
#     * 章ボタン 4 個 = HIT 章 1（その回の正解 combo の章）+ MISS 章 3 (MISS_CHAPTER_KEYS から)
#     * 物証ボタン 4 個 = HIT 物証 1 + MISS 物証 3 (MISS_EVIDENCE_KEYS から)
#     * MISS は **必ず MISS 専用プールから** 引く。決して HIT 側から引かない
#       → 4×4 グリッド 16 セル中、正解は HIT 章 × HIT 物証 の 1 セルだけ
#     * + 決定ボタン + ピー助任せ
# - プレイヤーは 1 章 + 1 物証を選んで決定。(章, 物証) ペアが VALID_COMBOS に
#   含まれていれば HIT、含まれていなければ MISS
# - HIT (-40)：未使用の正解組み合わせ → 妄想直撃 ＋ ピー助の畳みかけ追撃
# - MISS (+5)：的外れな組み合わせ → シラけ反応
# - 既使用正解 (+5)：同じ正解の二度目はネタ尽き反応
# - 3 HIT で勝利（信仰の威厳 100 → 0）／130 到達で敗北
# - ピー助任せ：未使用の正解組み合わせから 1 つランダム選出（HIT 確定）
# - 設計書 `docs/minigame_designs/st3_magdalena.md` の Decision Log を参照
#   （2026-04-29: ST2 から組み合わせ機構を移動、HIT/MISS プール分離方式に再設計）

const MAGDALENA_PORTRAIT := "res://assets/characters/stage3/magdalena_001.png"
const MAGDALENA_ICON := "res://assets/ui/speakers/magdalena_default.png"
const MAGDALENA_ID := "magdalena"

const GAUGE_MAX := 130     # 共通リミット（_common_rules.md）
const GAUGE_START := 100   # 共通基本 start（バックファイアなし）

const HIT_DELTA := -40
const MISS_DELTA := 5

# --- 章 ---
# CHAPTERS は HIT 用 (VALID_COMBOS で使用される 5 章) と MISS 用 (デコイ・決して
# VALID_COMBOS に登場しない 8 章) の合体辞書。サンプリング時は HIT_CHAPTER_KEYS と
# MISS_CHAPTER_KEYS を使い分け、MISS は決して HIT 側から引かない。
const CHAPTERS := {
	# === HIT 側（マグダレナの自選集の章、いずれかが VALID_COMBOS に出る）===
	"bath":         {"label": "「湯浴み」章",         "excerpt": "湯気立つ浴場で、二人の男が裸身を擦り合わせ──"},
	"guardian":     {"label": "「相互加護」章",       "excerpt": "戦友の傷を労ると見せかけ、指は脇腹を這い回り──"},
	"oath":         {"label": "「朝露の誓い」章",     "excerpt": "二人きりの夜明け、汗ばむ指を絡め、唇を寄せ──"},
	"chest":        {"label": "「胸筋と誓約」章",     "excerpt": "鍛え抜かれた胸と胸を擦り合わせ、汗ばむ肌で誓約を──"},
	"draft":        {"label": "「書きかけ草稿」章",   "excerpt": "汗だくで腰を打ち付け合い、もつれ合う二人の裸体──"},
	"night_drill":  {"label": "「夜更けの鍛錬」章",   "excerpt": "篝火の影で、二人の若き戦士が腰を打ち付け合い──"},
	"blood_oath":   {"label": "「血盟の儀」章",       "excerpt": "互いの腕に刃を当て、流れる血を舐め合いながら──"},
	# === MISS 側（ありきたりの本、デコイ）===
	"war":      {"label": "『聖戦の譜』第1章",     "excerpt": "勇敢な騎士は盾を構えた──"},
	"history":  {"label": "『建国記』第5章",       "excerpt": "王は国を統べると誓った──"},
	"morals":   {"label": "『道徳論』第2章",       "excerpt": "節制こそ徳の礎──"},
	"mary":     {"label": "『聖母マリア讃歌』",   "excerpt": "汚れなきマリアよ、我らを──"},
	"martyr":   {"label": "『殉教者録』最終章",   "excerpt": "主のために血を流し、天国へ昇った──"},
	"prayer":   {"label": "『祈祷集』朝の祈り",   "excerpt": "主よ、わが魂を御許に──"},
	"mercy":    {"label": "『神の慈愛』序章",     "excerpt": "神は万物を愛で包みたまう──"},
	"repent":   {"label": "『懺悔の書』序章",     "excerpt": "罪深き者よ、膝をつきなさい──"},
}
const HIT_CHAPTER_KEYS := ["bath", "guardian", "oath", "chest", "draft", "night_drill", "blood_oath"]
const MISS_CHAPTER_KEYS := ["war", "history", "morals", "mary", "martyr", "prayer", "mercy", "repent"]

# --- 物証 ---
# 同じ構造。HIT 側は白濁／指跡など示唆的な物証、MISS 側は栞・埃・折り目など
# ありきたりで決して VALID_COMBOS に登場しないデコイ。
const EVIDENCES := {
	# === HIT 側（VALID_COMBOS で使用される示唆的物証）===
	"page_stain":    {"label": "ページ三十七行目の不審な滲み", "description": "開いた一節、何かが弾けたような跡"},
	"finger_trace":  {"label": "ページ裏の指で撫でた跡",       "description": "何度も読み返した指の脂"},
	"pillow_stain":  {"label": "枕カバーの広範囲な染み",       "description": "ベッドで何かが弾けた痕跡"},
	"cover_finger":  {"label": "表紙の指の形の湿った跡",       "description": "二本指の形に残った染み"},
	"margin_stain":  {"label": "余白の点々染み",               "description": "執筆中に飛び散った何かの跡"},
	"crust":         {"label": "ページ間に固まった謎の物質",   "description": "ページ同士を貼り付ける乾いた何か"},
	"kiss_mark":     {"label": "表紙裏の口づけの跡",           "description": "表紙の裏側に残った唇形の染み"},
	# === MISS 側（ありきたりの痕跡、デコイ）===
	"bookmark":      {"label": "折り込まれた栞",             "description": "読みかけのページに挟まれた栞"},
	"wear":          {"label": "角の擦り切れ",               "description": "本の角に出来た自然な擦り切れ"},
	"dust":          {"label": "表紙の埃",                   "description": "薄く積もった埃"},
	"fold":          {"label": "ページの折り目",             "description": "印を付けるための小さな折り目"},
	"flower":        {"label": "ページに挟まった押し花",     "description": "間に挟まれて乾いた押し花"},
	"binding":       {"label": "装丁の解れ",                 "description": "装丁の縁が解れている"},
	"gilt":          {"label": "金箔の剥がれ",               "description": "表紙装飾の金箔が剥がれた跡"},
	"cord":          {"label": "栞紐の擦り跡",               "description": "栞紐の通り道に出来た擦り跡"},
}
const HIT_EVIDENCE_KEYS := ["page_stain", "finger_trace", "pillow_stain", "cover_finger", "margin_stain", "crust", "kiss_mark"]
const MISS_EVIDENCE_KEYS := ["bookmark", "wear", "dust", "fold", "flower", "binding", "gilt", "cord"]

# --- 正解組み合わせ 7 件（章 7×物証 7、1 対 1 マッピング）---
# 各章・各物証は VALID_COMBOS に 1 回ずつだけ登場する。
#   bath        : page_stain
#   night_drill : crust
#   guardian    : finger_trace
#   blood_oath  : pillow_stain
#   oath        : kiss_mark
#   chest       : cover_finger
#   draft       : margin_stain
const VALID_COMBOS := [
	# 1. bath × page_stain（湯浴み章のページ三十七行目の不審な滲み）
	{
		"chapter": "bath",
		"evidence": "page_stain",
		"mag_react": "...っ！ そ、その章は、どこで...どこで手に！",
		"mag_thought": "床板の下、なぜ、なぜそこに...！",
		"pisuke_chase": [
			"──ページ三十七行目、不審な滲み。",
			"──騎士二人、湯気の中で、硬いアレを擦り合う、淫靡な描写。",
			"──読みながら片手でご自身を慰め、ページに何かを散らしています。",
			"──毎晩、湯浴みの章で自分を慰めて、愛液を撒き散らしてしまったんですよね？",
		],
		"mag_pile": "...っ！ ...や、やめて、もう、許して...！",
	},
	# 2. night_drill × crust（夜更けの鍛錬章のページに固まった謎の物質）
	{
		"chapter": "night_drill",
		"evidence": "crust",
		"mag_react": "...っ！ そ、その章の存在を、なぜ、お前が──！",
		"mag_thought": "夜更けの鍛錬章、若き戦士たちが腰を打ち付け合う場面、わたくし...！",
		"pisuke_chase": [
			"──ページの間、固まった謎の塊。",
			"──夜更けに二人の戦士が腰を打ち付け合う場面、興奮で噴き出した、ご自身の何か。",
			"──開いたまま閉じ忘れて、乾いてページに張り付いている。",
			"──毎晩、夜更けの鍛錬章で果てて、ご自身の分泌物を本に流し込んでらっしゃる、ですよね？",
		],
		"mag_pile": "...っ！ ...あの章を、見られた、見られた...！",
	},
	# 3. guardian × finger_trace（相互加護章のページ裏指跡）
	{
		"chapter": "guardian",
		"evidence": "finger_trace",
		"mag_react": "...っ！ ぃ、いえ、それは、戦友愛の、神聖な描写で──！",
		"mag_thought": "肩を抱く、絡む指先、わたくしの...一番の章...！",
		"pisuke_chase": [
			"──相互加護のページ裏、汗で湿った指の跡。",
			"──戦友二人が汗だくで、互いの肌を抱き合う、その瞬間。",
			"──指の腹で、何度も、何度も、撫でた跡ですよね？",
			"──戦友の絡みを読みながら、自分のアソコを掻き回してたんですよね？",
		],
		"mag_pile": "...っ！ ...お願い、もう、見ないで...！",
	},
	# 4. blood_oath × pillow_stain（血盟の儀章を読みながら枕に飛んだ何か）
	{
		"chapter": "blood_oath",
		"evidence": "pillow_stain",
		"mag_react": "...っ！ そ、それは、寝具の、汚れで──！",
		"mag_thought": "血盟の儀の章を読みながら、わたくし、枕に...！",
		"pisuke_chase": [
			"──枕カバーに、何かが弾けた飛沫が、点々と。",
			"──血盟の儀を読み終えた瞬間、ご自身が果てた跡。",
			"──戦士たちが互いの血を舐め合う場面、ベッドの上で読みながら、",
			"──毎晩、血盟の儀の章で果てて、枕を愛液で濡らしてしまったんですよね？",
		],
		"mag_pile": "...っ！ ...枕の、染みまで...！",
	},
	# 5. oath × kiss_mark（朝露の誓い章を読みながら表紙裏に残した口づけ跡）
	{
		"chapter": "oath",
		"evidence": "kiss_mark",
		"mag_react": "...っ！ そ、その表紙の裏まで、なぜ──！",
		"mag_thought": "双子の絡み、夜明けの場面、わたくし、表紙の裏に...！",
		"pisuke_chase": [
			"──表紙の裏側、ご自身の唇の形が、はっきりと残っている。",
			"──夜明けに兄弟が口づけを交わす描写、夢中になられて。",
			"──ページを閉じ、表紙の裏に唇を押し付け、舐め回したんですよね？",
			"──双子が絡む場面で、ご自身も唇を本に押し付けて、片手でクリを触っていたんですよね？",
		],
		"mag_pile": "...っ！ ...表紙の裏まで、見られて...！",
	},
	# 6. chest × cover_finger（胸筋と誓約章を含む本の表紙の指染み）
	{
		"chapter": "chest",
		"evidence": "cover_finger",
		"mag_react": "...っ！ あ、汗、です、汗の染み、長年の使用で──！",
		"mag_thought": "あの本、誰にも触らせていないのに、なぜ...！",
		"pisuke_chase": [
			"──鑑定魔法によると、これ、汗ではございません。",
			"──不審な体液、人差し指と中指の、二本の形で。",
			"──片手で本を持ちながら、もう一方の手で何を？",
			"──毎晩、この本を腿の間に挟んで、お豆に擦りつけて果ててたんですよね？",
		],
		"mag_pile": "...っ！ ...あの本だけは、あの本だけは...！",
	},
	# 7. draft × margin_stain（書きかけ草稿章の余白の謎の染み）
	{
		"chapter": "draft",
		"evidence": "margin_stain",
		"mag_react": "...っ！ そ、それは、墨の、撥ねた跡で──！",
		"mag_thought": "書きながら、つい、片手で...まさか、それまで...！",
		"pisuke_chase": [
			"──余白の点々染み、墨ではございません。",
			"──検出されたのは、ご本人の、不審な体液でして。",
			"──執筆に夢中になりながら、もう一方の手で何を？",
			"──書きながら、片手は筆、もう片手で自分のアソコをいじっていたんですよね？",
		],
		"mag_pile": "...っ！ ...書斎を、見られた、書斎を...！",
	},
]

# --- MISS 時の汎用反応 ---
# 不正解の組み合わせは、彼女の側からは「ありきたりの懺悔朗読が続いているだけ」に見える。
# 物証も身に覚えのないものなので、敬虔に受け止め、心が穏やかになる ＝ 信仰の威厳が回復。
const MISS_MAG := "...ええ、敬虔なお言葉。\nわたくしの心も、穏やかになりますわ。"
const MISS_SCOLD := "ゲコッ、刺さらん！\nマグダレナの妄想スイッチを突け！"

# 既使用 HIT に再挑戦したとき
const ALREADY_USED_MAG := "...ええ、それは先ほど伺いました。\n別のお話を、お願いします。"
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
var _used_combo_keys: Array = []  # "bath|page_stain" 形式
var _turns_done: int = 0  # ピー助ロック用（1 ターン自力プレイ後解放）
# 2 軸組み合わせ：毎ターン 4 章 + 4 物証 を提示（共通ルール準拠：HIT 1 + MISS 3）
var _current_chapter_keys: Array = []   # 表示順の 4 章キー
var _current_evidence_keys: Array = []  # 表示順の 4 物証キー
var _selected_chapter: String = ""
var _selected_evidence: String = ""

# --- UI 参照 ---
var _ui_root: Control = null
var _gauge_bar: ColorRect = null
var _gauge_label: Label = null
var _gauge_stack: Control = null
var _chapter_buttons: Array[Button] = []
var _evidence_buttons: Array[Button] = []
var _decide_button: Button = null
var _pisuke_button: Button = null
var _column_headers: Array[Label] = []  # 「本のジャンル」「物証」見出し

signal _action_triggered(action: String)

func minigame(bt):
	_gauge = GAUGE_START
	_used_combo_keys.clear()
	_turns_done = 0
	_current_chapter_keys.clear()
	_current_evidence_keys.clear()
	_selected_chapter = ""
	_selected_evidence = ""

	_build_ui(bt)
	_update_gauge_display()
	_set_buttons_visible(false)
	await bt.wait(0.3)

	await _play_intro(bt)
	await _play_scripted_opening(bt)

	while _gauge > 0 and _gauge < GAUGE_MAX:
		_pick_current_choices()
		_selected_chapter = ""
		_selected_evidence = ""
		_refresh_button_labels()
		_set_buttons_visible(true)
		_set_buttons_enabled(true)

		var action: String = await _action_triggered

		_set_buttons_enabled(false)
		_set_buttons_visible(false)  # 吹き出しに被らないよう、決定後すぐ隠す

		if action == "_pisuke":
			await _apply_pisuke(bt)
		else:
			await _apply_choice(bt, _selected_chapter, _selected_evidence)
		_turns_done += 1

	_teardown_ui()

	if _gauge <= 0:
		bt.dialogue_band("narrator", "マグダレナの手から聖典が滑り落ちる。\n小窓の向こうで両手に顔を埋め、項垂れたまま動かない。\n「...もう、お許しください...！」", true)
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
	bt.dialogue_band("narrator", "【勝敗】\n「信仰の威厳」を 0 で勝利。\n130 到達で焚刑に処される。", true)
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
	bt.narrator_band("マグダレナ:\n...ええ。罪人の魂、\nわたくしが受け止めましょう。", MAGDALENA_ID, MAGDALENA_ICON)
	await bt.wait(0.0)

# --- 結果適用 ---

func _apply_choice(bt, chapter: String, evidence: String):
	var c_info: Dictionary = CHAPTERS.get(chapter, {})
	var e_info: Dictionary = EVIDENCES.get(evidence, {})

	# サトシの朗読：章タイトル → 引用 → 物証提示（3 バブル）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n聖女マグダレナ様。\n%s より。" % c_info.get("label", ""), "satoshi", "res://assets/ui/speakers/satoshi_gentle.png")
	await bt.wait(0.0)
	bt.narrator_band("サトシ:\n「%s」" % c_info.get("excerpt", ""), "satoshi", "res://assets/ui/speakers/satoshi_gentle.png")
	await bt.wait(0.0)
	bt.narrator_band("サトシ:\n%s、ございます。" % e_info.get("description", ""), "satoshi", "res://assets/ui/speakers/satoshi_gentle.png")
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
	bt.narrator_band("ピー助(小声で叱責):\n%s" % MISS_SCOLD, "pisuke")
	await bt.wait(0.0)

	bt.dialogue_band("narrator", "敬虔な朗読として受け止められた。\n(信仰の威厳 +%d)" % MISS_DELTA, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

func _play_already_used(bt):
	bt.set_bubble_side("right")
	bt.narrator_band("マグダレナ:\n%s" % ALREADY_USED_MAG, MAGDALENA_ID, MAGDALENA_ICON)
	await bt.wait(0.0)

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("ピー助(小声で叱責):\n%s" % ALREADY_USED_SCOLD, "pisuke")
	await bt.wait(0.0)

	bt.dialogue_band("narrator", "同じ朗読、二度目は刺さらない。\n(信仰の威厳 +%d)" % MISS_DELTA, true)
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
	bt.narrator_band("サトシ:\n...えっと、どれを選べば──", "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)
	bt.narrator_band("ピー助(小声):\n%s と、%s。\nこれを組み合わせろ。" % [c_info.get("label", ""), e_info.get("label", "")], "pisuke")
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

	# 章ボタン（左列・4 個） — 中身は毎ターン _refresh_button_labels で差し替え
	# 2 行表示（タイトル + 引用）に合わせて高さを増やす
	var book_root := VBoxContainer.new()
	book_root.position = Vector2(40, 170)
	book_root.size = Vector2(440, 380)
	book_root.add_theme_constant_override("separation", 6)
	_ui_root.add_child(book_root)

	_chapter_buttons.clear()
	for i in range(4):
		var btn := _make_choice_button("")
		btn.custom_minimum_size = Vector2(440, 88)
		var idx_capture: int = i
		btn.pressed.connect(func(): _on_chapter_button_pressed(idx_capture))
		book_root.add_child(btn)
		_chapter_buttons.append(btn)

	# 物証ボタン（右列・4 個）
	var evidence_root := VBoxContainer.new()
	evidence_root.position = Vector2(490, 170)
	evidence_root.size = Vector2(440, 380)
	evidence_root.add_theme_constant_override("separation", 6)
	_ui_root.add_child(evidence_root)

	_evidence_buttons.clear()
	for i in range(4):
		var btn := _make_choice_button("")
		btn.custom_minimum_size = Vector2(440, 88)
		var idx_capture: int = i
		btn.pressed.connect(func(): _on_evidence_button_pressed(idx_capture))
		evidence_root.add_child(btn)
		_evidence_buttons.append(btn)

	# 決定 + ピー助任せ（下、横並び）
	var bottom_root := HBoxContainer.new()
	bottom_root.position = Vector2(40, 570)
	bottom_root.size = Vector2(900, 56)
	bottom_root.add_theme_constant_override("separation", 16)
	_ui_root.add_child(bottom_root)

	_decide_button = _make_choice_button("[決定] この組み合わせで攻撃")
	_decide_button.custom_minimum_size = Vector2(440, 56)
	_decide_button.pressed.connect(func(): _on_decide_pressed())
	bottom_root.add_child(_decide_button)

	_pisuke_button = _make_choice_button("[ピー助に任せる]")
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
	_column_headers.append(label)

# === 選択肢ピック（毎ターン HIT 1 + MISS 3、両軸とも 4 択）===

func _pick_current_choices():
	# 1. HIT: 未使用の VALID_COMBOS から 1 件 → そのターンの「正解の組み合わせ」
	var hit_avail: Array = []
	for combo in VALID_COMBOS:
		var key: String = "%s|%s" % [combo.get("chapter", ""), combo.get("evidence", "")]
		if not _used_combo_keys.has(key):
			hit_avail.append(combo)
	if hit_avail.is_empty():
		for combo in VALID_COMBOS:
			hit_avail.append(combo)
	hit_avail.shuffle()
	var hit_combo: Dictionary = hit_avail[0]
	var hit_ch: String = String(hit_combo.get("chapter", ""))
	var hit_ev: String = String(hit_combo.get("evidence", ""))

	# 2. MISS の章/物証は **必ず MISS 専用プールから** 引く（HIT 側からは決して引かない）。
	#    MISS_CHAPTER_KEYS / MISS_EVIDENCE_KEYS のキーは VALID_COMBOS に一切登場しないので、
	#    4×4 グリッドの中で正解になりうるのは HIT 章 × HIT 物証 の 1 セルだけになる。
	var miss_chs: Array = MISS_CHAPTER_KEYS.duplicate()
	miss_chs.shuffle()
	miss_chs = miss_chs.slice(0, 3)

	var miss_evs: Array = MISS_EVIDENCE_KEYS.duplicate()
	miss_evs.shuffle()
	miss_evs = miss_evs.slice(0, 3)

	# 3. 章 4 件・物証 4 件を構築してシャッフル
	var chapter_keys: Array = [hit_ch]
	for k in miss_chs:
		chapter_keys.append(String(k))
	chapter_keys.shuffle()

	var evidence_keys: Array = [hit_ev]
	for k in miss_evs:
		evidence_keys.append(String(k))
	evidence_keys.shuffle()

	_current_chapter_keys = chapter_keys
	_current_evidence_keys = evidence_keys

func _is_valid_combo(chapter: String, evidence: String) -> bool:
	for combo in VALID_COMBOS:
		if combo.get("chapter", "") == chapter and combo.get("evidence", "") == evidence:
			return true
	return false

# === ボタン表示更新 ===

func _refresh_button_labels():
	for i in range(_chapter_buttons.size()):
		var btn: Button = _chapter_buttons[i]
		if i >= _current_chapter_keys.size():
			btn.visible = false
			continue
		btn.visible = true
		var key: String = _current_chapter_keys[i]
		var info: Dictionary = CHAPTERS.get(key, {})
		var title: String = info.get("label", key)
		var excerpt: String = info.get("excerpt", "")
		var selected: bool = (key == _selected_chapter)
		var prefix: String = "▶ 選択中  " if selected else "[%d] " % (i + 1)
		btn.text = "%s%s\n   「%s」" % [prefix, title, excerpt]
		_apply_selected_style(btn, selected)
	for i in range(_evidence_buttons.size()):
		var btn: Button = _evidence_buttons[i]
		if i >= _current_evidence_keys.size():
			btn.visible = false
			continue
		btn.visible = true
		var key: String = _current_evidence_keys[i]
		var info: Dictionary = EVIDENCES.get(key, {})
		var title: String = info.get("label", key)
		var desc: String = info.get("description", "")
		var selected: bool = (key == _selected_evidence)
		var prefix: String = "▶ 選択中  " if selected else "[%d] " % (i + 5)
		btn.text = "%s%s\n   %s" % [prefix, title, desc]
		_apply_selected_style(btn, selected)
	if _decide_button:
		_decide_button.disabled = _selected_chapter.is_empty() or _selected_evidence.is_empty()

func _apply_selected_style(btn: Button, selected: bool):
	# 選択中のボタンには明るい黄色の枠＋濃いアンバー背景を適用、
	# 文字色も白から鮮黄へ切り替えて視認性を強化する。
	var bg: Color
	var border: Color
	var text_col: Color
	if selected:
		bg = Color(0.55, 0.40, 0.10, 0.98)
		border = Color(1.0, 0.95, 0.40, 1.0)
		text_col = Color(1.0, 0.95, 0.55)
	else:
		bg = Color(0.18, 0.18, 0.22, 0.95)
		border = Color(0.95, 0.78, 0.30, 0.95)
		text_col = Color.WHITE
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		if state == "hover" and not selected:
			sb.bg_color = Color(0.30, 0.26, 0.18, 0.95)
		elif state == "hover" and selected:
			sb.bg_color = Color(0.65, 0.50, 0.18, 0.98)
		elif state == "pressed":
			sb.bg_color = Color(0.50, 0.40, 0.10, 0.95)
		sb.border_width_left = 2 if selected else 1
		sb.border_width_right = 2 if selected else 1
		sb.border_width_top = 2 if selected else 1
		sb.border_width_bottom = 2 if selected else 1
		sb.border_color = border
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.content_margin_left = 16
		sb.content_margin_right = 8
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)

func _set_buttons_enabled(active: bool):
	for btn in _chapter_buttons:
		btn.disabled = not active
	for btn in _evidence_buttons:
		btn.disabled = not active
	if _decide_button:
		_decide_button.disabled = not active or _selected_chapter.is_empty() or _selected_evidence.is_empty()
	if _pisuke_button:
		if not active:
			_pisuke_button.disabled = true
		else:
			var locked: bool = (_turns_done < 1)
			_pisuke_button.disabled = locked
			_pisuke_button.text = "[ピー助に任せる]" if not locked else "[ピー助に任せる]（残り 1 ターン）"

func _set_buttons_visible(visible: bool):
	# 章/物証/決定/ピー助のボタン群と「本のジャンル」「物証」見出しを一括表示制御。
	# 吹き出し（dialogue/narrator band）と重ならないよう、台詞表示中は false で隠す。
	for btn in _chapter_buttons:
		btn.visible = visible
	for btn in _evidence_buttons:
		btn.visible = visible
	if _decide_button:
		_decide_button.visible = visible
	if _pisuke_button:
		_pisuke_button.visible = visible
	for header in _column_headers:
		header.visible = visible

# === ボタンハンドラ ===

func _on_chapter_button_pressed(idx: int):
	if idx < 0 or idx >= _current_chapter_keys.size():
		return
	_selected_chapter = _current_chapter_keys[idx]
	_refresh_button_labels()

func _on_evidence_button_pressed(idx: int):
	if idx < 0 or idx >= _current_evidence_keys.size():
		return
	_selected_evidence = _current_evidence_keys[idx]
	_refresh_button_labels()

func _on_decide_pressed():
	if _selected_chapter.is_empty() or _selected_evidence.is_empty():
		return
	_action_triggered.emit("_combo")

func _on_pisuke_pressed():
	if _turns_done < 1:
		return
	_action_triggered.emit("_pisuke")

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
	_column_headers.clear()

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
	# 共通ルール準拠（max=130）でしきい値を再設定
	if value >= 100:
		return Color(0.85, 0.20, 0.20)
	elif value >= 40:
		return Color(0.90, 0.78, 0.20)
	else:
		return Color(0.30, 0.78, 0.30)
