extends BattleChapterBase

# ST2「アサシン・レイラ」ミニゲーム（表情選択式）
#
# 設計：
# - 毎ターン、ピー助が不意打ち質問 → レイラの表情が変化（立ち絵差分 + テキスト描写）
# - プレイヤーは表情を見て、適切な指摘を 4 ボタンから選ぶ + ピー助任せ = 5 ボタン
# - 表情と一致 → -50 + ピー助の畳みかけ追撃
# - 表情と不一致 → +5 + ピー助の叱責
# - 反応テキスト（既存）は補助信号として残す。表情画像が主信号。

const LAYLA_PORTRAIT := "res://assets/characters/main/layla/clothed/layla_clothed_001.png"
const LAYLA_ICON := "res://assets/ui/speakers/layla_default.png"
const LAYLA_ID := "layla"

const GAUGE_MAX := 130
const GAUGE_START := 100  # 共通基本 start（_common_rules.md 参照、ST2 はバックファイアなし）

const HIT_DELTA := -40
const MISS_DELTA := 5

# --- 表情カテゴリ定義 ---
# 当面は色付きラベルで表情をプレースホルダー表示。将来は立ち絵差分に差し替え。
# choice：プレイヤーボタン用（自然な疑問文）／badge：右上バッジ表示用（簡潔ラベル）
const EXPRESSIONS := {
	"shake":  {"badge": "震え", "choice": "手、震えてません？",     "color": Color(0.55, 0.85, 1.00)},
	"blush":  {"badge": "紅潮", "choice": "顔、赤くなってません？", "color": Color(1.00, 0.55, 0.65)},
	"sweat":  {"badge": "汗",   "choice": "汗、かいてません？",     "color": Color(0.95, 0.95, 0.55)},
	"panic":  {"badge": "狼狽", "choice": "動揺してません？",       "color": Color(1.00, 0.70, 0.45)},  # 罠
}

# --- 選択肢ラベル（4 表情 + ピー助任せ） ---
# 順番固定。配置順がそのままボタン番号 1〜5 に対応。
const CHOICE_KEYS := ["shake", "blush", "sweat", "panic"]

# --- ピー助の MISS 叱責（プレイヤーが選んだ表情ごと） ---
const MISS_SCOLDS := {
	"shake": "彼女、ぴくりとも震えてないだろ！\nもっと別の場所、よく見ろ！",
	"blush": "顔、赤くなってないぞ！\n他の場所が反応してる、見落とすな！",
	"sweat": "汗、どこにも！\n表情の別の変化、見えてるはずだ！",
	"panic": "狼狽？　彼女、案外冷静だぞ！\n反応は別のところに出てる！",
}

# --- シーンプール（10 件） ---
# 各シーン：
#   pisuke_line: ピー助の不意打ち質問
#   expression : 正解の表情カテゴリ（key）
#   reaction   : テキスト描写（補助信号として残す）
#   satoshi_hit: HIT 時のサトシの指摘台詞
#   pile_on    : HIT 時のピー助の畳みかけ追撃
#   layla_pile : 追撃時のレイラ崩れ反応
# シーンは順番に消化される（ランダムではなく、エスカレーション順）。
# 段階：
#   [1〜3] 男たちの「視線」を意識させる（外見へのからかい）
#   [4〜6] 「身体」そのものを話題にする（体臭・お尻・下の毛）
#   [7〜10] 性知識の直球（勃起・アソコ・子作り・アナル）
const SCENES := [
	# --- ステージ1：視線 ---
	{
		"pisuke_line": "男たちは、揺れている胸に釘付けですよ。",
		"expression": "blush",
		"reaction": "気になってた視線の話を突きつけられ、レイラの唇が結ばれ、頬が紅潮した。",
		"satoshi_hit": "頬、真っ赤に紅潮してますよ、レイラさん。\n胸の揺れ、見られてること、自覚してましたよね？",
		"pile_on": "──戦うたびに、ぼいん、ぼいん、って大きく揺れて。\n──ブラの中で、乳首が擦れて、カリカリに尖ってますよね？\n──激しく動くたび、男たちは寸前まで興奮してます。\n──今、何人射精させたか、数えてあげましょうか？",
		"layla_pile": "...っ！ ...う、動けない、動いたら、もっと、揺れちゃう...！",
	},
	{
		"pisuke_line": "下着の色、周りの男に透けて見えてるかも。",
		"expression": "blush",
		"reaction": "気になってた不安を的中させられ、レイラの胸元が紅潮し、両手で胸を隠そうとする。",
		"satoshi_hit": "胸元から首まで、ぱあっと紅潮してますね。\n下着、見られてる前提で、生きてたんでしょ？",
		"pile_on": "──暗殺服、汗で張り付いたら、もう全部スケスケ。\n──しゃがんだ瞬間、お尻の谷間に、下着の食い込み、線まで、くっきり。\n──今日も、白ですか？　それとも、戦勝祈願で勝負下着？\n──ちなみに、シミの形も、男たちは観察してますよ。",
		"layla_pile": "...っ！ ...み、見ないで、お尻、お尻ぃ...！",
	},
	{
		"pisuke_line": "男たちは、あなたの太ももの間を妄想してます。",
		"expression": "shake",
		"reaction": "薄々想像してた視線を明言されて、レイラの手が太ももを押さえ、指先が震えた。",
		"satoshi_hit": "太ももを押さえる手、ぷるぷる震えてますよ。\n妄想されてること、薄々わかってたんでしょ？",
		"pile_on": "──スリットの奥、ぐっしょり濡れた下着、見えてるんでしょ？\n──毎晩、何十人もの男が、太ももの間を舐め回す想像、してますよ。\n──スカート短いの、わざと、ですよね？　見せたいんでしょ？\n──今夜の標的の男、あなたを犯す妄想で、興奮しながら寝てますよ。",
		"layla_pile": "...っ！ ...み、見せたくない、見せたくないぃ、わざとじゃないぃ...！",
	},
	# --- ステージ2：身体 ---
	{
		"pisuke_line": "戦闘中の汗の匂い、男には媚薬らしいですよ。",
		"expression": "sweat",
		"reaction": "薄々想像してたかもしれない効果を突かれ、レイラの胸元が一気に汗ばむ。",
		"satoshi_hit": "言われた途端、胸元、ぱっと汗ばみましたね。\n媚薬扱いされてること、想像してましたよね？",
		"pile_on": "──男たちは、あなたの汗をビン詰めにして、家で嗅ぎたいんですよ。\n──下着の匂い、こっそり盗まれてる可能性、ありますね。\n──戦闘中の体臭で、男を勃たせるのが、本当の暗殺術じゃないですか？\n──今夜、誰の枕元で、あなたの匂い嗅がれてるんでしょうね？",
		"layla_pile": "...っ！ ...や、やめて、私の匂い、私の匂いぃ...！",
	},
	{
		"pisuke_line": "男たちは、お尻の皺を数えたがっていますよ。",
		"expression": "shake",
		"reaction": "薄々想像してた背後の視線を指摘され、レイラの手がお尻を隠し、指先が震えた。",
		"satoshi_hit": "お尻を隠す手、震えてますよ、レイラさん。\n後ろから数えられてること、想像してましたよね？",
		"pile_on": "──スリット越しのお尻、皺の本数、男たちが集計してます。\n──Sランク暗殺者の皺は、十六本だ、って噂です。\n──今この瞬間も、後ろから、男が、本数を数えてますよ。\n──今夜、彼らのオカズに、あなたの皺が、ばっちり登場します。",
		"layla_pile": "...っ！ ...み、見ないで、数えないで、お尻ぃ...！",
	},
	{
		"pisuke_line": "下の毛、生えてますか？",
		"expression": "sweat",
		"reaction": "踏み込まれた話題に動悸が走り、レイラの胸元が熱を帯び、じっとりと汗ばんだ。",
		"satoshi_hit": "胸元、じっとり汗ばんでますよ。\nそんなとこまで突かれるとは、思ってなかったんでしょ？",
		"pile_on": "──アソコの周り、もじゃもじゃ、生え揃ってますよね？\n──手入れしないと、変態の趣味って思われちゃいますよ。\n──今、男全員が想像してます。あなたのアソコの毛が、何センチで、どんな形か。\n──正方形に剃るのが、最近の流行りらしいですよ？",
		"layla_pile": "...っ！ ...み、見ないで、想像しないでぇ、お願いぃ...！",
	},
	# --- ステージ3：性知識（直球） ---
	{
		"pisuke_line": "男性は、勃起するって知ってます？",
		"expression": "shake",
		"reaction": "初耳の言葉を反芻するように、レイラの手元が大きく揺れ、指先が震えた。",
		"satoshi_hit": "指、震えてますね、レイラさん。\n勃起、って単語、初めて聞いたんでしょ？",
		"pile_on": "──興奮すると、ズボンの中で、ぐぐぐっと硬くなるんです。\n──今、あなたを見てる男、全員が勃起してますよ。\n──戦ってるあなたを見ながら、夜、自分でしごくんです、毎晩。\n──あなたの姿で、何リットル、男の汁が排出されたか、ご存知ですか？",
		"layla_pile": "...っ！ ...や、やめてぇ、想像、しないでぇ...！",
	},
	{
		"pisuke_line": "男性のアソコ、見たことあります？",
		"expression": "shake",
		"reaction": "初耳の単語に動揺し、レイラの手が口元を覆い、小刻みに震え始めた。",
		"satoshi_hit": "手、震えてますよ、レイラさん。\nアソコの話で、こんなに動揺するなんて。",
		"pile_on": "──じゃあ今、想像してください、レイラさん。\n──血管が浮き出て、ぴくぴく動く、太くて硬い棒。\n──ぱんぱんに張り詰めて、先っちょから、透明な汁が、滲み出てる。\n──今、目の前に、ぶらーんって、ぶら下がってる絵、見えますよね？",
		"layla_pile": "...っ！ ...や、やだ、消えて、頭から消えてぇ...！",
	},
	{
		"pisuke_line": "子供の作り方、知ってますか？",
		"expression": "blush",
		"reaction": "初耳の言葉に衝撃が走り、レイラの唇が固く結ばれ、頬が真っ赤に紅潮した。",
		"satoshi_hit": "顔、真っ赤ですよ、レイラさん。\n初めての話で、頭の中で想像しちゃったんでしょ？",
		"pile_on": "──じゃあ、教えてあげますね、レイラさん。\n──男の硬く太いアレを、女のアソコに、ずぶずぶ深く突っ込んで。\n──白いのを、奥に、たっぷり、注ぎ込むんですよ。\n──今、頭の中で、その光景、見えてますよね？",
		"layla_pile": "...っ！ ...い、嫌、嫌っ、頭から、消えない、消えてぇ...！",
	},
	{
		"pisuke_line": "アナルセックスって、知ってますか？",
		"expression": "sweat",
		"reaction": "初耳の単語に動悸が走り、レイラの胸元が紅潮し、じわりと汗ばむ。",
		"satoshi_hit": "胸元、汗ばんでますよ、レイラさん。\nアナル、って単語で、心臓の鼓動、上がってますよね？",
		"pile_on": "──お尻の穴を、無理やり広げて、男の硬いのを、ぶち込むんですよ。\n──最初は痛い、痛い、痛いって叫んで、涙が出るらしいです。\n──でも慣れると、アソコより気持ちいいって、皆さん。\n──あなたのお尻、誰が最初に開発するんでしょうね？",
		"layla_pile": "...っ！ ...ぃ、いやだ、お尻の穴、お尻の穴ぁ...！",
	},
]

func get_opponent_id() -> String:
	return LAYLA_ID

func get_opponent_name() -> String:
	return "レイラ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage1/bg07_st1_001.png"

func get_lose_behavior() -> String:
	return "continue"

func setup_scene(bt):
	var layla = bt.character(LAYLA_ID)
	layla.set_portrait(LAYLA_PORTRAIT, {"scale": 0.55, "side": "center", "position": [0, -200]})

# --- 状態 ---
var _gauge: int = GAUGE_START
var _current_scene: Dictionary = {}
var _used_scenes: Array = []
var _turns_done: int = 0  # ピー助ロック用

# --- UI 参照 ---
var _ui_root: Control = null
var _gauge_bar: ColorRect = null
var _gauge_label: Label = null
var _gauge_stack: Control = null
var _reaction_label: Label = null
var _reaction_panel: PanelContainer = null
var _expression_badge: Label = null
var _expression_badge_panel: PanelContainer = null
var _choice_buttons: Array[Button] = []
var _pisuke_button: Button = null

signal _choice_picked(picked_key: String)

func minigame(bt):
	_gauge = GAUGE_START
	_used_scenes.clear()
	_turns_done = 0

	_build_ui(bt)
	_update_gauge_display()
	_set_buttons_active(false)
	_set_buttons_visible(false)
	_set_reaction_visible(false)
	_set_expression_visible(false)
	await bt.wait(0.3)

	await _play_intro(bt)
	await _play_briefing(bt)

	while _gauge > 0 and _gauge < GAUGE_MAX:
		_pick_scene()

		# 1. ピー助の不意打ち質問（ボタンも表情も非表示）
		_set_buttons_visible(false)
		_set_expression_visible(false)
		_set_reaction_visible(false)
		bt.set_bubble_side("bottom-left")
		bt.narrator_band("ピー助:\n%s" % _current_scene.get("pisuke_line", ""), "pisuke")
		await bt.wait(0.0)

		# 2. レイラの表情変化を表示
		_show_expression()
		_show_reaction_text(bt)
		# 反応テキスト読み終わったら、表情と選択肢を提示
		_set_buttons_visible(true)
		_set_buttons_active(true)
		var picked: String = await _choice_picked
		_set_buttons_active(false)
		_set_buttons_visible(false)
		# レイラの吹き出しを邪魔しないよう、反応テキスト・表情バッジも非表示にする
		_set_reaction_visible(false)
		_set_expression_visible(false)

		if picked == "_pisuke":
			await _apply_pisuke(bt)
		else:
			await _apply_choice(bt, picked)
		_turns_done += 1

	_teardown_ui()

	if _gauge <= 0:
		bt.dialogue_band("narrator", "レイラの殺気が、ふっと霧散した。\n真っ赤な顔で後ずさる。「...あ、もう...知らない！」", true)
		await bt.wait(0.0)
		bt.hide_dialogue_band()
		await bt.wait(0.0)
		return "win"
	else:
		bt.dialogue_band("narrator", "レイラが一歩踏み込んだ。\n視界が真っ赤に染まる——冷たい刃の感触。", true)
		await bt.wait(0.0)
		bt.hide_dialogue_band()
		await bt.wait(0.0)
		return "lose"

# --- 導入 ---

func _play_intro(bt):
	bt.dialogue_band("narrator", "【相手の表情を読め】\nアサシン・レイラは超純情な処女。\nピー助の不意打ちで動揺した表情を見抜いて指摘し、殺気を削げ。", true)
	await bt.wait(0.0)
	bt.dialogue_band("narrator", "【勝敗】\n「冷静度」を 0 で勝利。\n130 到達でサトシは斬殺される。", true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

# --- ミニゲーム直前の繋ぎ（カマかけ→強がり→セクハラ宣言） ---
# ピー助がサトシの声色を真似て、レイラの純情を見抜いていると挑発。
# レイラが強がって否定 → ピー助が「じゃあ確かめてやる」とセクハラ宣言。
func _play_briefing(bt):
	# 1. レイラの再戦開幕
	bt.set_bubble_side("right")
	bt.narrator_band("レイラ:\n...再検証、開始いたします。\n条件は、前回と同様で。", LAYLA_ID, LAYLA_ICON)
	await bt.wait(0.0)

	# 2. サトシ（ピー助の声色）が切り出し
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ（ピー助の声色で）:\n...レイラさん、一つだけ、\n伺ってもよろしいですか。", "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)

	# 3. レイラ応答（油断）
	bt.set_bubble_side("right")
	bt.narrator_band("レイラ:\n...ええ、どうぞ。", LAYLA_ID, LAYLA_ICON)
	await bt.wait(0.0)

	# 4. 仕込み（褒め→引っかかり）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ（ピー助の声色で）:\nあなたの所作、見事でした。\nですが、一点だけ、引っかかって。", "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)

	# 5. 核心の挑発
	bt.narrator_band("サトシ（ピー助の声色で）:\n本当は、男に触れたこと、\n一度もないんでしょう？", "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)

	# 6. レイラ強がり
	bt.set_bubble_side("right")
	bt.narrator_band("レイラ:\n...っ、ふざけたことを。\n男の体なんて、何度でも、見てきたわ。", LAYLA_ID, LAYLA_ICON)
	await bt.wait(0.0)

	# 7. 確かめ宣言（不意打ち質問の連発へ）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ（ピー助の声色で）:\nじゃあ、確かめさせてもらいますね。\n表情を動かさなければ、信じます。", "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)

# --- シーンピック（重複なし、枯渇でリセット） ---

func _pick_scene():
	if _used_scenes.size() >= SCENES.size():
		_used_scenes.clear()
	var avail: Array = []
	for i in range(SCENES.size()):
		if not _used_scenes.has(i):
			avail.append(i)
	avail.shuffle()
	var idx: int = avail[0]
	_used_scenes.append(idx)
	_current_scene = SCENES[idx]

# --- 表情と反応テキストの表示 ---

func _show_expression():
	var key: String = _current_scene.get("expression", "blush")
	var info: Dictionary = EXPRESSIONS.get(key, {})
	if _expression_badge:
		_expression_badge.text = "【%s】" % info.get("badge", "")
		_expression_badge.add_theme_color_override("font_color", info.get("color", Color.WHITE))
	if _expression_badge_panel:
		_expression_badge_panel.visible = true

func _show_reaction_text(bt):
	if _reaction_label:
		_reaction_label.text = _current_scene.get("reaction", "")
	if _reaction_panel:
		_reaction_panel.visible = true

# --- 選択肢適用 ---

func _apply_choice(bt, picked: String):
	var correct: String = _current_scene.get("expression", "")
	var is_hit: bool = (picked == correct)
	if is_hit:
		await _play_hit(bt)
		_gauge = clamp(_gauge + HIT_DELTA, 0, GAUGE_MAX)
	else:
		await _play_miss(bt, picked)
		_gauge = clamp(_gauge + MISS_DELTA, 0, GAUGE_MAX)
	_update_gauge_display()

func _play_hit(bt):
	# サトシの指摘
	var sat_line: String = _current_scene.get("satoshi_hit", "")
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n%s" % sat_line, "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)

	# ピー助の畳みかけ追撃（1 行ずつ別バブルで「畳みかけ」感を出す）
	var pile_on: String = _current_scene.get("pile_on", "")
	if not pile_on.is_empty():
		var pile_lines: PackedStringArray = pile_on.split("\n")
		for i in range(pile_lines.size()):
			var prefix: String = "ピー助（畳みかけて）:" if i == 0 else "ピー助:"
			bt.set_bubble_side("bottom-left")
			bt.narrator_band("%s\n%s" % [prefix, pile_lines[i]], "pisuke")
			await bt.wait(0.0)

	# レイラの崩れ反応
	var layla_pile: String = _current_scene.get("layla_pile", "")
	if not layla_pile.is_empty():
		bt.set_bubble_side("right")
		bt.narrator_band("レイラ:\n%s" % layla_pile, LAYLA_ID, LAYLA_ICON)
		await bt.wait(0.0)

	# 結果ナレーション
	bt.dialogue_band("narrator", "クリティカル！\n（冷静度 %d）" % HIT_DELTA, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

func _play_miss(bt, picked: String):
	var info: Dictionary = EXPRESSIONS.get(picked, {})
	# サトシの誤指摘（ボタン文と同じ自然な疑問文）
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n%s" % info.get("choice", ""), "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)
	# レイラの平然反応
	bt.set_bubble_side("right")
	bt.narrator_band("レイラ:\n...はぁ？　見当違いね。" , LAYLA_ID, LAYLA_ICON)
	await bt.wait(0.0)
	# ピー助の叱責
	var scold: String = MISS_SCOLDS.get(picked, "違うぞ、よく見ろ！")
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("ピー助（小声で叱責）:\n%s" % scold, "pisuke")
	await bt.wait(0.0)
	# 結果ナレーション
	bt.dialogue_band("narrator", "見当違い、シラけられた。\n（冷静度 +%d）" % MISS_DELTA, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

func _apply_pisuke(bt):
	var correct: String = _current_scene.get("expression", "")
	var info: Dictionary = EXPRESSIONS.get(correct, {})

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n...えっと、何て言えば──", "satoshi", "res://assets/ui/speakers/satoshi_nervous.png")
	await bt.wait(0.0)
	bt.narrator_band("ピー助（小声）:\n...これだ。「%s」、と聞け。" % info.get("choice", ""), "pisuke")
	await bt.wait(0.0)

	# HIT と同じフローで再生
	await _play_hit(bt)
	_gauge = clamp(_gauge + HIT_DELTA, 0, GAUGE_MAX)
	_update_gauge_display()

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
	_gauge_label.text = "レイラの冷静度"
	_gauge_label.add_theme_font_size_override("font_size", 22)
	_gauge_label.add_theme_color_override("font_color", Color.WHITE)
	_gauge_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_gauge_label.add_theme_constant_override("shadow_outline_size", 3)
	_gauge_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gauge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gauge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gauge_stack.add_child(_gauge_label)

	# 表情バッジ（右上、レイラ立ち絵の上に重ねる）
	_expression_badge_panel = _make_panel(Vector2(1500, 110), Vector2(280, 60), Color(0.3, 0.3, 0.4, 0.95))
	_ui_root.add_child(_expression_badge_panel)
	_expression_badge = Label.new()
	_expression_badge.text = ""
	_expression_badge.add_theme_font_size_override("font_size", 32)
	_expression_badge.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_expression_badge.add_theme_constant_override("shadow_outline_size", 4)
	_expression_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_expression_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_expression_badge_panel.add_child(_expression_badge)

	# 反応テキストパネル（右上、表情バッジの下）
	_reaction_panel = _make_panel(Vector2(980, 190), Vector2(900, 200), Color(0.8, 0.3, 0.5, 0.75))
	_ui_root.add_child(_reaction_panel)
	_reaction_label = Label.new()
	_reaction_label.text = ""
	_reaction_label.add_theme_font_size_override("font_size", 22)
	_reaction_label.add_theme_color_override("font_color", Color.WHITE)
	_reaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_reaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reaction_panel.add_child(_reaction_label)

	# 選択肢ボタン（左、5 ボタン縦並び）
	var btn_root := VBoxContainer.new()
	btn_root.position = Vector2(40, 120)
	btn_root.size = Vector2(420, 280)
	btn_root.add_theme_constant_override("separation", 8)
	_ui_root.add_child(btn_root)

	_choice_buttons.clear()
	for i in range(CHOICE_KEYS.size()):
		var key: String = CHOICE_KEYS[i]
		var info: Dictionary = EXPRESSIONS.get(key, {})
		var label: String = "[%d] %s" % [i + 1, info.get("choice", key)]
		var btn := _make_choice_button(label)
		var key_capture: String = key
		btn.pressed.connect(func(): _on_choice_pressed(key_capture))
		btn_root.add_child(btn)
		_choice_buttons.append(btn)

	# ピー助任せボタン
	_pisuke_button = _make_choice_button("[5] ピー助に任せる")
	_pisuke_button.pressed.connect(func(): _on_pisuke_pressed())
	btn_root.add_child(_pisuke_button)

func _make_panel(pos: Vector2, sz: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = sz
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.10, 0.08, 0.12, 0.9)
	ss.border_width_left = 1
	ss.border_width_right = 1
	ss.border_width_top = 1
	ss.border_width_bottom = 1
	ss.border_color = border
	ss.corner_radius_top_left = 6
	ss.corner_radius_top_right = 6
	ss.corner_radius_bottom_left = 6
	ss.corner_radius_bottom_right = 6
	ss.content_margin_left = 16
	ss.content_margin_right = 16
	ss.content_margin_top = 8
	ss.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", ss)
	return panel

func _make_choice_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 22)
	btn.custom_minimum_size = Vector2(420, 48)
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
	_reaction_label = null
	_reaction_panel = null
	_expression_badge = null
	_expression_badge_panel = null
	_choice_buttons.clear()
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
		_gauge_label.text = "レイラの冷静度  %d / %d" % [_gauge, GAUGE_MAX]

func _gauge_color(value: int) -> Color:
	if value >= 100:
		return Color(0.85, 0.20, 0.20)
	elif value >= 50:
		return Color(0.90, 0.78, 0.20)
	else:
		return Color(0.30, 0.78, 0.30)

func _set_buttons_active(active: bool):
	for btn in _choice_buttons:
		btn.disabled = not active
	if _pisuke_button:
		# ピー助は 1 ターン自力プレイ後に解放（2 ターン目から使用可）
		if not active:
			_pisuke_button.disabled = true
		else:
			_pisuke_button.disabled = (_turns_done < 1)
			if _turns_done >= 1:
				_pisuke_button.text = "[5] ピー助に任せる"
			else:
				_pisuke_button.text = "[5] ピー助に任せる（残り 1 ターン）"

func _set_buttons_visible(visible: bool):
	for btn in _choice_buttons:
		btn.visible = visible
	if _pisuke_button:
		_pisuke_button.visible = visible

func _set_reaction_visible(visible: bool):
	if _reaction_panel:
		_reaction_panel.visible = visible

func _set_expression_visible(visible: bool):
	if _expression_badge_panel:
		_expression_badge_panel.visible = visible

func _on_choice_pressed(key: String):
	_choice_picked.emit(key)

func _on_pisuke_pressed():
	if _turns_done < 1:
		return
	_choice_picked.emit("_pisuke")
