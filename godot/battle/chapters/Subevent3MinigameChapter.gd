extends BattleChapterBase

# サブイベント3「羞恥の儀」ミニゲーム
# 呪いの加護度ゲージを0にすれば成功、130で失敗。
# docs/scenarios/subevent3_scenario.txt 準拠。

const ARMOR_PORTRAIT := "res://assets/characters/subevent3/armor_001.png"
const FIONA_ID := "fiona_armor"

const GAUGE_MAX := 130
const GAUGE_START := 100      # 儀式開始時点の素の加護度
const SCRIPTED_BACKFIRE := 10 # スクリプト導入でサトシのとちりにより上昇

# --- 感情別アイコン画像（セリフのトーンに合わせて切替） ---
# 画像は scripts/crop_speaker_icons.py で顔切り抜き生成
const ICO_SATOSHI_NORMAL      := "res://assets/ui/speakers/satoshi_normal.png"
const ICO_SATOSHI_NERVOUS     := "res://assets/ui/speakers/satoshi_nervous.png"
const ICO_SATOSHI_WORRIED     := "res://assets/ui/speakers/satoshi_worried.png"
const ICO_SATOSHI_GENTLE      := "res://assets/ui/speakers/satoshi_gentle.png"
const ICO_SATOSHI_APOLOGETIC  := "res://assets/ui/speakers/satoshi_apologetic.png"
const ICO_FIONA_DEFAULT       := "res://assets/ui/speakers/fiona_default.png"
# セバス（仮: 盗賊ガルド画像を流用）
const ICO_SEBAS_NORMAL        := "res://assets/ui/speakers/sebas_normal.png"
const ICO_SEBAS_FROWN         := "res://assets/ui/speakers/sebas_frown.png"
const ICO_SEBAS_STRICT        := "res://assets/ui/speakers/sebas_strict.png"
# ピー助（画像なし→ 頭文字アイコンで代用）
const ICO_PISUKE_DEFAULT      := ""

# サトシ選択肢プール（ピー助は別枠・常に5枠目）
# 毎ターン、このプールから 4 つランダムに選ばれる
const CHOICE_POOL := [
	# --- 的外れ (delta 0) ---
	{
		"label": "鎧、重くないですか？",
		"delta": 0,
		"satoshi": "……フ、フィオナさん。鎧、重くないですか……？",
		"fiona": "……お、重いです……でも、だいじょうぶ……。",
		"thought": "",
		"explain": "気遣いが的外れで、フィオナの心に波紋は起きない。",
		"sebas": "……。",
	},
	{
		"label": "手入れは誰がなさってるんですか？",
		"delta": 0,
		"satoshi": "その鎧……手入れは、どなたがなさってるんですか？",
		"fiona": "……手入れ、など……もう、ずっと……。",
		"thought": "",
		"explain": "雑事めいた質問で、フィオナの心は動かない。",
		"sebas": "……（困惑）",
	},
	{
		"label": "剣とか、お使いになるんですか？",
		"delta": 0,
		"satoshi": "……そういえば、剣とかも、お使いになるんですか？",
		"fiona": "……い、いえ……戦いは、無縁で……。",
		"thought": "",
		"explain": "見当違いの話題で、フィオナは拍子抜けする。",
		"sebas": "……。",
	},
	{
		"label": "いい、天気ですよね",
		"delta": 0,
		"satoshi": "い、いい天気、ですよね……今日……。",
		"fiona": "……は、はい……窓から、見えて、います……。",
		"thought": "",
		"explain": "あたりさわりない世間話で、フィオナの心は動かない。",
		"sebas": "……（無言）",
	},
	{
		"label": "ご趣味は、何ですか？",
		"delta": 0,
		"satoshi": "あの……ご趣味って、何か、おありですか？",
		"fiona": "……本を……読むのが、好き、で……。",
		"thought": "",
		"explain": "初対面の話題で、フィオナは僅かに戸惑うだけ。",
		"sebas": "……。",
	},
	{
		"label": "え、えっと……お、お元気、ですか？",
		"delta": 0,
		"satoshi": "え、えっと……お、お元気、ですか……？\nいや、元気なわけないか……す、すみません……。",
		"fiona": "……え……あ、は、はい、なんとか……。",
		"thought": "",
		"explain": "サトシが緊張しすぎて、むしろフィオナが気を遣う側になる。",
		"sebas": "……（小さく溜息）",
	},
	{
		"label": "あ、あの、お、お飲み物とか……？",
		"delta": 0,
		"satoshi": "あ、あの、お、お飲み物とか……い、いや、飲めないですよね、その、鎧で……。\nす、すみません、忘れてくださ……。",
		"fiona": "……あ、いえ……お気遣い、ありがとうございます……。",
		"thought": "",
		"explain": "サトシの挙動不審で、フィオナは動揺するどころか気の毒に思う。",
		"sebas": "……（もう一度、溜息）",
	},
	# --- 逆効果 (delta +10) ---
	{
		"label": "一か月、本当にお辛かったですね",
		"delta": 10,
		"satoshi": "一か月も鎧の中、本当にお辛かったですよね。\nよく耐えてこられたと思います。",
		"fiona": "……あ、ありがとうございます……お優しい、です……。",
		"thought": "……この人、本当に優しい……気遣ってくれる……",
		"explain": "優しさに心が温まり、羞恥どころか呪いが強まってしまった。",
		"sebas": "……サトシ様。色が濃くなっております。",
	},
	{
		"label": "ご家族も、ご心配でしょうね",
		"delta": 10,
		"satoshi": "ご家族の皆さんも、フィオナさんをずっとご心配されてたでしょうね。",
		"fiona": "……お父様も、セバスも……わたしのために……。",
		"thought": "……みんな、わたしを愛してくれている……",
		"explain": "家族の愛を実感し、心が満たされて羞恥が生まれない。",
		"sebas": "……いけませんな、サトシ様。",
	},
	{
		"label": "ご立派にお耐えですね",
		"delta": 10,
		"satoshi": "ご立派にお耐えですね、フィオナさん。\n尊敬します。",
		"fiona": "……わ、わたし、そんな……そんなふうに……。",
		"thought": "……わたし、頑張ってこれたんだ……認めてくれる人がいる……",
		"explain": "尊敬の言葉でフィオナの誇りが復活し、呪いが強まる。",
		"sebas": "……（頭を抱える）",
	},
	{
		"label": "きっと、呪いは解けますよ",
		"delta": 10,
		"satoshi": "きっと、大丈夫です。\nフィオナさんの呪い、必ず解いてみせます。",
		"fiona": "……あ、ありがとうございます……わたし、信じます……。",
		"thought": "……この人が、助けてくれる……もう少し、耐えよう……",
		"explain": "希望の言葉で心が満たされ、羞恥が遠のいて呪いが強まる。",
		"sebas": "……頼もしいお言葉ですが、色が……。",
	},
	{
		"label": "セバスさんは、本当に献身的ですね",
		"delta": 10,
		"satoshi": "セバスさん、本当にフィオナさんに尽くしておられますね。\n素敵なご関係ですよね。",
		"fiona": "……セバス、いつも、そばに……いて、くれて……。",
		"thought": "……わたし、一人じゃない……セバスが、いてくれる……",
		"explain": "家人の愛を実感し、心が温まって羞恥が生まれない。",
		"sebas": "……（やや誇らしげ）……しかし、色が……。",
	},
	{
		"label": "ヴァニティ・チェイン、貴重な鎧ですよね",
		"delta": 10,
		"satoshi": "しかし、ヴァニティ・チェインって、貴重な魔道具ですよね。\n歴史ある品物でしょう？",
		"fiona": "……は、はい……先祖代々、伝わるものだと……。",
		"thought": "……そう、これは誇り高い、家の宝……わたしが継いだ……",
		"explain": "家宝への敬意でフィオナの誇りが疼き、呪いが強まる。",
		"sebas": "……サトシ様、今はそれを褒める場面では……。",
	},
	# --- 軽羞恥 (delta -5) ---
	{
		"label": "お風呂、入りたいですよね？",
		"delta": -5,
		"satoshi": "……お風呂、入りたいですよね……。一か月は、さすがに……。",
		"fiona": "……は、はい……入りたい、です……。",
		"thought": "お風呂……お湯に浸かりたい……髪、洗いたい……",
		"explain": "不浄な自分を直視させられ、小さな羞恥が呪いを削る。",
		"sebas": "……微々たるものですな。",
	},
	{
		"label": "早く脱ぎたいですよね？",
		"delta": -5,
		"satoshi": "……早く、脱ぎたいですよね……鎧。",
		"fiona": "……は、はい……脱ぎたい……です……。",
		"thought": "脱ぎたい……こんな鎧、もう、やだ……",
		"explain": "無力な自分を認めさせられ、小さな羞恥が呪いを削る。",
		"sebas": "……微々たるものですな。",
	},
	{
		"label": "髪、ぺたんこになってませんか？",
		"delta": -5,
		"satoshi": "……髪、ぺたんこになって、ませんか？　ずっと兜の中で……。",
		"fiona": "……っ……た、たぶん、なってます……。",
		"thought": "ぺったり……ぐしゃぐしゃ……貴族令嬢の髪型じゃ、ない……",
		"explain": "令嬢らしさの崩壊を突きつけられ、羞恥が呪いを削る。",
		"sebas": "……微々たるものですが、効いております。",
	},
	{
		"label": "お化粧も、できてないですよね？",
		"delta": -5,
		"satoshi": "あ……お化粧も、できて、ないですよね……一か月……。",
		"fiona": "……っ……い、いえ、普段から、薄化粧、で……。",
		"thought": "素顔……誰にも見せたことないのに、たぶん今、見られてる……",
		"explain": "素顔を晒していることを意識させられ、小さな羞恥が呪いを削る。",
		"sebas": "……進んでおります。",
	},
	{
		"label": "鎧の跡、肌に残りますよね？",
		"delta": -5,
		"satoshi": "その……鎧の跡、肌に残っちゃいますよね？\n金属、ずっと当たってるから……。",
		"fiona": "……あ……跡、ついて、ます……たぶん、ずっと……。",
		"thought": "痣みたいな跡……絶対、残ってる……醜い……",
		"explain": "身体の物理的変容を意識させられ、羞恥が呪いを削る。",
		"sebas": "……微々たるものですが、確実に。",
	},
]

const PISUKE_CHOICE := {"label": "ピー助に任せる", "is_pisuke": true}

# ピー助のランダム発話プール（5個）
const PISUKE_LINES := [
	{
		"opening": "──下着、一か月、ずっと同じままですよね。",
		"followup": "──黄ばんでますよね。もう色、元に戻らないですよね。\n──肌に張り付いて、剥がすとき、ぺりって音しません？",
		"fiona": "……っ！ ……い、言わないで……それは、さすがに……！",
		"fiona2": "……ぁ……やめ……もう、やめて……っ！",
		"thought": "バレてる……気持ち悪い……洗い替えなんて、ない……ずっと同じ……！",
	},
	{
		"opening": "──脇毛、一か月、伸び放題ですよね？",
		"followup": "──貴族のお嬢様がボーボーって、侍女に見られたらどうします？\n──あ、脇だけじゃないですよね。足も、あと……他の場所も。",
		"fiona": "……っ！ ……言わないで、それだけは、絶対に──！",
		"fiona2": "……っ！！ ……ひ、ひどい……なんでそこまで……っ！",
		"thought": "もじゃもじゃ……全身……侍女にだけは、絶対、見られたくない……！",
	},
	{
		"opening": "──お手洗い、どうしてるんですか？　一か月、ずっと中で？",
		"followup": "──あ、まさか、その……鎧の中で、そのまま……？\n──じゃあ、足元のあたり、もう……？",
		"fiona": "……っ！ ……き、訊かないで……お願い……っ！",
		"fiona2": "……ち、違います……ちゃんと、ちゃんと……っ！",
		"thought": "聞かないで……考えたくない……もう、自分でもわからない……",
	},
	{
		"opening": "──今、どんな匂いがしていますか？　鎧の中。",
		"followup": "──近くで嗅いだら、わかっちゃいますかね？\n──セバスさんとか、本当はもう気づいてるんじゃないですか？",
		"fiona": "……っ！ ……い、嫌……それだけは、嗅がないで……っ！",
		"fiona2": "……ぐすっ……ひっく……ごめん、なさい……っ！",
		"thought": "……きっと、臭い……セバスも気づいてる……優しいから、言わないだけ……",
	},
	{
		"opening": "──鎧の中、汗でヌルヌルですよね？",
		"followup": "──腋とか、胸の下とか、もう汗だまりじゃないですか？\n──歩くたびに、ぴちゃぴちゃ、音、しません？",
		"fiona": "……っ！ ……ぃ、言わないで、聞かないで……っ！",
		"fiona2": "……ぃ、言ったら……死んじゃう……っ！",
		"thought": "ぴちゃ……ぴちゃ……音、してる……絶対、みんなに聞こえてる……！",
	},
]

var _gauge: int = GAUGE_START
var _pisuke_used: Array = []
var _pisuke_cycle: int = 0
var _current_choices: Array = []  # 毎ターン5個（ランダム4＋ピー助）
var _last_pool_indices: Array = []  # 直前ターンのプールインデックス（連続排除用）

func get_opponent_id() -> String:
	return FIONA_ID

func get_opponent_name() -> String:
	return "フィオナ"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage1/bg07_st1_001.png"

# --- UI 参照 ---
var _ui_root: Control = null
var _gauge_bar: ColorRect = null
var _gauge_bg: ColorRect = null
var _gauge_label: Label = null
var _gauge_stack: Control = null
var _advance_prompt: Label = null
var _advance_prompt_tween: Tween = null
var _choice_buttons: Array[Button] = []
var _choice_selected: int = -1

signal _choice_emitted(idx: int)

func setup_scene(bt):
	var fiona = bt.character(FIONA_ID)
	fiona.set_portrait(ARMOR_PORTRAIT, {"scale": 0.55, "side": "center", "position": [0, -200]})

func minigame(bt):
	_gauge = GAUGE_START
	_pisuke_used.clear()
	_pisuke_cycle = 0

	_build_ui(bt)
	_set_buttons_visible(false)
	_update_gauge_display()
	await bt.wait(0.3)

	# --- ルール説明 ---
	await _play_rules_intro(bt)

	# --- 場面4: スクリプト導入（プレイヤー操作なし）---
	await _play_scripted_intro(bt)

	# --- 場面5: 本番（プレイヤー操作開始）---
	await _narrate_wait(bt, "……さあ、次の一言をどう選ぶか。")
	_set_buttons_visible(true)

	while _gauge > 0 and _gauge < GAUGE_MAX:
		_pick_current_choices()
		_refresh_choice_buttons()
		_update_gauge_display()
		_set_buttons_enabled(true)
		_choice_selected = -1
		var idx: int = await _choice_emitted
		_set_buttons_enabled(false)
		await _apply_choice(bt, idx)
		_update_gauge_display()

	_teardown_ui()

	if _gauge <= 0:
		await _narrate_wait(bt, "水晶球が鮮やかな緑に輝いた！　呪いの加護は崩れ去った。")
		return "win"
	else:
		await _narrate_wait(bt, "水晶球が真っ赤に染まった……　呪いが完全発動し、儀式は失敗した。")
		return "lose"

# --- 選択肢適用 ---

func _apply_choice(bt, idx: int):
	var choice: Dictionary = _current_choices[idx]
	if choice.get("is_pisuke", false):
		await _apply_pisuke(bt)
	else:
		# delta に応じたサトシ・セバスの表情決定
		var delta: int = int(choice.delta)
		var satoshi_ico: String = ICO_SATOSHI_NORMAL
		var sebas_ico: String = ICO_SEBAS_NORMAL
		if delta > 0:
			satoshi_ico = ICO_SATOSHI_GENTLE    # 優しい気遣い（が裏目）
			sebas_ico = ICO_SEBAS_STRICT        # 渋い警告顔
		elif delta < 0:
			satoshi_ico = ICO_SATOSHI_GENTLE    # 踏み込んだ気遣い
			sebas_ico = ICO_SEBAS_FROWN         # 微かに頷く
		bt.set_bubble_side("bottom-left")
		bt.narrator_band("サトシ:\n%s" % choice.satoshi, "satoshi", satoshi_ico)
		await bt.wait(0.0)
		bt.set_bubble_side("right")
		bt.narrator_band("フィオナ:\n%s" % choice.fiona, "fiona", ICO_FIONA_DEFAULT)
		await bt.wait(0.0)

		# 心の声＋効果の理由をナレーションで提示（3行以内）
		var thought: String = choice.get("thought", "")
		var explain: String = choice.get("explain", "")
		var narration: String = ""
		if not thought.is_empty():
			narration += "スクリーン映像「%s」\n" % thought
		narration += explain
		await _narrate_wait(bt, narration)

		await _apply_gauge_change(bt, delta)
		var sebas_line: String = choice.get("sebas", "")
		var delta_text: String = _format_delta(delta)
		bt.set_bubble_side("bottom-right")
		if sebas_line.is_empty():
			bt.narrator_band("（加護度 %s）" % delta_text)
		else:
			bt.narrator_band("セバス:\n%s\n\n（加護度 %s）" % [sebas_line, delta_text], "sebas", sebas_ico)
		await bt.wait(0.0)

func _apply_pisuke(bt):
	# まだ出ていないセリフを選ぶ。全部出し切ったら2周目（減衰あり）
	var available: Array = []
	for i in range(PISUKE_LINES.size()):
		if not _pisuke_used.has(i):
			available.append(i)
	if available.is_empty():
		_pisuke_used.clear()
		_pisuke_cycle += 1
		for i in range(PISUKE_LINES.size()):
			available.append(i)
	var pick: int = available[randi() % available.size()]
	_pisuke_used.append(pick)

	var line: Dictionary = PISUKE_LINES[pick]

	# サトシが言いかけて乗っ取られる演出
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n……えっと──", "satoshi", ICO_SATOSHI_NERVOUS)
	await bt.wait(0.0)
	bt.narrator_band("ピー助（サトシの声に被せて）:\n%s" % line.opening, "pisuke")
	await bt.wait(0.0)
	bt.set_bubble_side("right")
	bt.narrator_band("フィオナ:\n%s" % line.fiona, "fiona", ICO_FIONA_DEFAULT)
	await bt.wait(0.0)
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("ピー助（畳みかけて）:\n%s" % line.followup, "pisuke")
	await bt.wait(0.0)
	bt.set_bubble_side("right")
	bt.narrator_band("フィオナ:\n%s" % line.fiona2, "fiona", ICO_FIONA_DEFAULT)
	await bt.wait(0.0)

	# 心の声＋効果の理由をナレーションで提示（3行以内）
	var explain: String = "心を丸裸に暴かれ、強烈な羞恥が呪いを大きく削る。"
	if _pisuke_cycle == 1:
		explain = "同じ指摘は二度目。衝撃は弱まったが、羞恥は残る。"
	elif _pisuke_cycle >= 2:
		explain = "三度目ともなると、フィオナの心も少し慣れてきた。"
	await _narrate_wait(bt, "スクリーン映像「%s」\n%s" % [line.thought, explain])

	var delta: int = -50
	if _pisuke_cycle == 1:
		delta = -20  # 2周目減衰
	elif _pisuke_cycle >= 2:
		delta = -5   # 3周目以降さらに減衰
	await _apply_gauge_change(bt, delta)

	bt.set_bubble_side("bottom-right")
	bt.narrator_band("セバス:\n（サトシを睨むが、水晶球を見て、ぐっと耐える）\n……進んでおります。\n\n（加護度 %s）" % _format_delta(delta), "sebas", ICO_SEBAS_STRICT)
	await bt.wait(0.0)
	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\nち、違う！ 今のは俺じゃない！", "satoshi", ICO_SATOSHI_NERVOUS)
	await bt.wait(0.0)

func _format_delta(delta: int) -> String:
	if delta > 0:
		return "+%d" % delta
	elif delta < 0:
		return "%d" % delta  # マイナスは自動で付く
	return "±0"

# --- UI 構築 ---

func _build_ui(bt: Node):
	_ui_root = Control.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bt.add_child(_ui_root)

	# ゲージ（画面上部・立体感のあるデザイン）
	var gauge_w: float = 600.0
	var gauge_h: float = 60.0
	_gauge_stack = Control.new()
	_gauge_stack.position = Vector2(40, 40)
	_gauge_stack.size = Vector2(gauge_w, gauge_h)
	_ui_root.add_child(_gauge_stack)
	var gauge_stack: Control = _gauge_stack

	# 外枠パネル（影付き・縁あり）
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.06, 0.06, 0.09, 0.95)
	frame_style.border_width_left = 2
	frame_style.border_width_right = 2
	frame_style.border_width_top = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = Color(0.55, 0.55, 0.62, 1.0)
	frame_style.corner_radius_top_left = 10
	frame_style.corner_radius_top_right = 10
	frame_style.corner_radius_bottom_left = 10
	frame_style.corner_radius_bottom_right = 10
	frame_style.shadow_color = Color(0, 0, 0, 0.55)
	frame_style.shadow_size = 6
	frame_style.shadow_offset = Vector2(0, 3)
	frame_style.content_margin_left = 4
	frame_style.content_margin_right = 4
	frame_style.content_margin_top = 4
	frame_style.content_margin_bottom = 4
	frame.add_theme_stylebox_override("panel", frame_style)
	gauge_stack.add_child(frame)

	# 内側の溝（バーが走るトラック）
	var track_margin: float = 5.0
	var track := Control.new()
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.anchor_left = 0.0
	track.anchor_top = 0.0
	track.anchor_right = 1.0
	track.anchor_bottom = 1.0
	track.offset_left = track_margin
	track.offset_top = track_margin
	track.offset_right = -track_margin
	track.offset_bottom = -track_margin
	track.clip_contents = true
	gauge_stack.add_child(track)

	# 背景（溝の奥・暗いグラデ模擬のため濃色）
	_gauge_bg = ColorRect.new()
	_gauge_bg.color = Color(0.12, 0.12, 0.15, 1.0)
	_gauge_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.add_child(_gauge_bg)

	# バー本体（幅は_update_gauge_displayで変化）
	_gauge_bar = ColorRect.new()
	_gauge_bar.color = Color(0.85, 0.20, 0.20)
	_gauge_bar.position = Vector2(0, 0)
	_gauge_bar.size = Vector2(0, 0)
	_gauge_bar.anchor_top = 0.0
	_gauge_bar.anchor_bottom = 1.0
	track.add_child(_gauge_bar)

	# バー上部のハイライト（白帯でツヤ表現）
	var gloss := ColorRect.new()
	gloss.color = Color(1, 1, 1, 0.25)
	gloss.name = "GaugeGloss"
	gloss.anchor_left = 0.0
	gloss.anchor_top = 0.0
	gloss.anchor_right = 1.0
	gloss.anchor_bottom = 0.35
	gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge_bar.add_child(gloss)

	# バー下部のシャドウ（下1/4暗く）
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.25)
	shade.name = "GaugeShade"
	shade.anchor_left = 0.0
	shade.anchor_top = 0.75
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge_bar.add_child(shade)

	_gauge_label = Label.new()
	_gauge_label.text = "呪いの加護度"
	_gauge_label.add_theme_font_size_override("font_size", 22)
	_gauge_label.add_theme_color_override("font_color", Color.WHITE)
	_gauge_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_gauge_label.add_theme_constant_override("shadow_offset_x", 2)
	_gauge_label.add_theme_constant_override("shadow_offset_y", 2)
	_gauge_label.add_theme_constant_override("shadow_outline_size", 3)
	_gauge_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gauge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gauge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gauge_stack.add_child(_gauge_label)

	# 選択肢ボタン（左上 — ゲージ直下。こちら側＝左の慣習に従う）
	# ビューポート 1920x1080。ゲージ下端 y=96 / 左下バブル開始 y=594
	# 配置: x=40-460, y=120-580（左下バブルと干渉しない）
	var button_root := VBoxContainer.new()
	button_root.position = Vector2(40, 120)
	button_root.size = Vector2(420, 460)
	button_root.add_theme_constant_override("separation", 10)
	_ui_root.add_child(button_root)

	_choice_buttons.clear()
	for i in range(5):  # 常に5個（4ランダム + ピー助）
		var btn := Button.new()
		btn.text = "[%d] -" % (i + 1)
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(420, 84)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		# テキスト左余白 + 金色枠線のスタイルボックス（細線）
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.18, 0.18, 0.22, 0.95)
			var border_col := Color(0.95, 0.78, 0.30, 0.95)  # 金色
			if state == "hover":
				sb.bg_color = Color(0.30, 0.26, 0.18, 0.95)
				border_col = Color(1.0, 0.90, 0.45, 1.0)  # 明るい金
			elif state == "pressed":
				sb.bg_color = Color(0.12, 0.12, 0.14, 0.95)
				border_col = Color(0.75, 0.58, 0.18, 1.0)  # 濃い金
			elif state == "disabled":
				sb.bg_color = Color(0.18, 0.18, 0.22, 0.55)
				border_col = Color(0.60, 0.50, 0.25, 0.50)  # 薄い金
			elif state == "focus":
				border_col = Color(1.0, 0.95, 0.55, 1.0)
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
			# 金色の淡い光沢シャドウ
			sb.shadow_color = Color(0.95, 0.78, 0.30, 0.28)
			sb.shadow_size = 3
			btn.add_theme_stylebox_override(state, sb)
		var idx_capture: int = i
		btn.pressed.connect(func(): _on_choice_pressed(idx_capture))
		button_root.add_child(btn)
		_choice_buttons.append(btn)

func _teardown_ui():
	if _advance_prompt_tween:
		_advance_prompt_tween.kill()
	_advance_prompt_tween = null
	if _ui_root and is_instance_valid(_ui_root):
		_ui_root.queue_free()
	_ui_root = null
	_gauge_bar = null
	_gauge_bg = null
	_gauge_label = null
	_gauge_stack = null
	_advance_prompt = null
	_choice_buttons.clear()

var _prompt_poll_active: bool = false

# --- ナレーション：ダイアログバンドに表示してクリック待ち ---
func _narrate_wait(bt, text: String):
	_ensure_advance_prompt()
	if _advance_prompt:
		_advance_prompt.visible = false
	_prompt_poll_active = true
	bt.dialogue_band("narrator", text, true)
	_poll_prompt_ready(bt)  # タイプライター完了後に ▼ を点滅
	await bt.wait(0.0)
	_prompt_poll_active = false
	_hide_advance_prompt()
	bt.hide_dialogue_band()
	await bt.wait(0.0)

# タイプライター完了＋入力待機状態になったら ▼ を表示
func _poll_prompt_ready(bt):
	var ss = bt._story_scene
	while _prompt_poll_active:
		if ss:
			var typing: bool = ss.get("_typing_in_progress")
			var waiting: bool = ss.get("_waiting_for_input")
			if waiting and not typing:
				_show_advance_prompt()
				return
		await get_tree().create_timer(0.08).timeout

func _ensure_advance_prompt():
	if not _ui_root:
		return
	if _advance_prompt != null:
		return
	_advance_prompt = Label.new()
	_advance_prompt.text = "▼  クリック / Enter"
	_advance_prompt.add_theme_font_size_override("font_size", 24)
	_advance_prompt.add_theme_color_override("font_color", Color(1, 1, 0.55))
	_advance_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_advance_prompt.add_theme_constant_override("shadow_offset_x", 2)
	_advance_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_advance_prompt.add_theme_constant_override("shadow_outline_size", 5)
	_advance_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_advance_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# ダイアログバンド右下（y=816〜1080 の範囲内、右寄せ）
	_advance_prompt.position = Vector2(1540, 1020)
	_advance_prompt.size = Vector2(340, 40)
	_advance_prompt.visible = false
	_ui_root.add_child(_advance_prompt)

func _show_advance_prompt():
	_ensure_advance_prompt()
	if not _advance_prompt:
		return
	_advance_prompt.visible = true
	_advance_prompt.modulate.a = 1.0
	if _advance_prompt_tween:
		_advance_prompt_tween.kill()
	_advance_prompt_tween = get_tree().create_tween().set_loops()
	_advance_prompt_tween.tween_property(_advance_prompt, "modulate:a", 0.35, 0.55)
	_advance_prompt_tween.tween_property(_advance_prompt, "modulate:a", 1.0, 0.55)

func _hide_advance_prompt():
	if _advance_prompt_tween:
		_advance_prompt_tween.kill()
	_advance_prompt_tween = null
	if _advance_prompt:
		_advance_prompt.visible = false

# --- ゲージ変化＋エフェクト（ドーパミン全部盛り） ---
func _apply_gauge_change(bt, delta: int):
	var old_gauge: int = _gauge
	var new_gauge: int = clamp(old_gauge + delta, 0, GAUGE_MAX)
	var real_delta: int = new_gauge - old_gauge  # クランプ後の実差分
	_gauge = new_gauge

	_spawn_floating_number(real_delta)
	_tween_gauge_bar(new_gauge)
	_shake_gauge(abs(real_delta) >= 10)

	if abs(real_delta) >= 10:
		_spawn_screen_flash(real_delta)
		_spawn_telop(real_delta)

	# エフェクトを見せるため十分に待つ
	await bt.wait(1.6)

# フローティング数値
func _spawn_floating_number(delta: int):
	if not _ui_root:
		return
	var label := Label.new()
	var text: String
	var col: Color
	if delta > 0:
		text = "+%d" % delta
		col = Color(1.0, 0.35, 0.35)
	elif delta < 0:
		text = "%d" % delta
		col = Color(0.35, 1.0, 0.55)
	else:
		text = "±0"
		col = Color(0.85, 0.85, 0.85)
	label.text = text
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_constant_override("shadow_outline_size", 6)
	# ゲージ右端のすぐ右に出現
	label.position = Vector2(660, 20)
	label.scale = Vector2(0.3, 0.3)
	label.pivot_offset = Vector2(40, 40)
	_ui_root.add_child(label)

	# Phase 1: ポップイン（0〜0.22s）その場で拡大
	var pop := get_tree().create_tween()
	pop.tween_property(label, "scale", Vector2(1.15, 1.15), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(label, "scale", Vector2(1.0, 1.0), 0.10)

	# Phase 2: 1.8秒その場でホールド → 上昇＋フェード
	get_tree().create_timer(1.8).timeout.connect(func():
		if not is_instance_valid(label):
			return
		var rise := get_tree().create_tween()
		rise.set_parallel(true)
		rise.tween_property(label, "position:y", label.position.y - 140, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		rise.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.2)
		rise.chain().tween_callback(Callable(label, "queue_free"))
	)

# ゲージバーを tween + 色アニメ
func _tween_gauge_bar(new_value: int):
	if not _gauge_bar:
		return
	var parent_w: float = 600.0
	if _gauge_bar.get_parent() is Control:
		parent_w = (_gauge_bar.get_parent() as Control).size.x
	var target_w: float = parent_w * (float(new_value) / float(GAUGE_MAX))
	var target_color: Color = _gauge_color(new_value)

	var tw := get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(_gauge_bar, "size:x", target_w, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_gauge_bar, "color", target_color, 0.35)
	# ラベルは即時更新
	if _gauge_label:
		_gauge_label.text = "呪いの加護度  %d / %d" % [new_value, GAUGE_MAX]

# ゲージ横揺れ
func _shake_gauge(big: bool):
	if not _gauge_stack:
		return
	var base := _gauge_stack.position
	var amp: float = 12.0 if big else 4.0
	var tw := get_tree().create_tween()
	tw.tween_property(_gauge_stack, "position:x", base.x + amp, 0.04)
	tw.tween_property(_gauge_stack, "position:x", base.x - amp, 0.06)
	tw.tween_property(_gauge_stack, "position:x", base.x + amp * 0.5, 0.05)
	tw.tween_property(_gauge_stack, "position:x", base.x, 0.05)

# 画面フラッシュ
func _spawn_screen_flash(delta: int):
	if not _ui_root:
		return
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(0.95, 0.15, 0.15, 0.55) if delta > 0 else Color(0.15, 0.95, 0.35, 0.55)
	_ui_root.add_child(flash)
	var tw := get_tree().create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(Callable(flash, "queue_free"))

# 大文字テロップ
func _spawn_telop(delta: int):
	if not _ui_root:
		return
	var label := Label.new()
	var text: String
	var col: Color
	if delta >= 10:
		text = "逆効果！"
		col = Color(1.0, 0.45, 0.45)
	elif delta <= -50:
		text = "効果絶大！"
		col = Color(0.35, 1.0, 0.55)
	else:
		text = "効果あり！"
		col = Color(0.55, 1.0, 0.70)

	label.text = text
	label.add_theme_font_size_override("font_size", 96)
	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("shadow_offset_x", 6)
	label.add_theme_constant_override("shadow_offset_y", 6)
	label.add_theme_constant_override("shadow_outline_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.pivot_offset = Vector2(960, 540)
	label.scale = Vector2(0.4, 0.4)
	label.modulate.a = 0.0
	_ui_root.add_child(label)

	# Phase 1: ポップイン
	var pop := get_tree().create_tween()
	pop.set_parallel(true)
	pop.tween_property(label, "scale", Vector2(1.25, 1.25), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(label, "modulate:a", 1.0, 0.20)
	# Phase 2: 長めホールド後フェード
	get_tree().create_timer(1.5).timeout.connect(func():
		if not is_instance_valid(label):
			return
		var fade := get_tree().create_tween()
		fade.tween_property(label, "modulate:a", 0.0, 0.55)
		fade.tween_callback(Callable(label, "queue_free"))
	)

func _update_gauge_display():
	if not _gauge_bar:
		return
	var ratio: float = float(_gauge) / float(GAUGE_MAX)
	# ゲージ幅は親 Control のサイズに合わせる
	var parent_w: float = 600.0
	if _gauge_bar.get_parent() is Control:
		parent_w = (_gauge_bar.get_parent() as Control).size.x
	_gauge_bar.size.x = parent_w * ratio
	_gauge_bar.color = _gauge_color(_gauge)
	if _gauge_label:
		_gauge_label.text = "呪いの加護度  %d / %d" % [_gauge, GAUGE_MAX]

func _gauge_color(value: int) -> Color:
	# 信号色: 100以上=赤(危険), 50-100=黄(注意), 50未満=緑(進展)
	if value >= 100:
		return Color(0.85, 0.20, 0.20)
	elif value >= 50:
		return Color(0.90, 0.78, 0.20)
	else:
		return Color(0.30, 0.78, 0.30)

func _set_buttons_enabled(enabled: bool):
	for btn in _choice_buttons:
		btn.disabled = not enabled

func _set_buttons_visible(visible: bool):
	for btn in _choice_buttons:
		btn.visible = visible

# --- 毎ターンのランダム選択肢ピック ---
# プールから 4 つをランダムに選ぶ。直前ターンと同じ組み合わせは避ける。
func _pick_current_choices():
	var indices: Array = []
	for i in range(CHOICE_POOL.size()):
		indices.append(i)
	indices.shuffle()
	# 直前ターンと全一致を避ける（4個被りなら入れ替え）
	var picked: Array = indices.slice(0, 4)
	if _last_pool_indices.size() == 4:
		var all_same: bool = true
		for p in picked:
			if p not in _last_pool_indices:
				all_same = false
				break
		if all_same:
			indices.shuffle()
			picked = indices.slice(0, 4)
	_last_pool_indices = picked.duplicate()

	_current_choices.clear()
	for i in picked:
		_current_choices.append(CHOICE_POOL[i])
	_current_choices.append(PISUKE_CHOICE)

func _refresh_choice_buttons():
	for i in range(_choice_buttons.size()):
		if i < _current_choices.size():
			_choice_buttons[i].text = "[%d] %s" % [i + 1, _current_choices[i].label]
		else:
			_choice_buttons[i].text = ""

# --- 場面4: スクリプト導入 ---
# 呪いの加護度 100 の状態でサトシが無難なねぎらいを言い、+10 して 110 まで上昇。
# プレイヤー操作はなし。
# --- ルール説明（ミニゲーム冒頭） ---
func _play_rules_intro(bt):
	await _narrate_wait(bt, "【羞恥の儀】\nフィオナを封じる呪いの鎧「ヴァニティ・チェイン」。\n装着者自身に強烈な羞恥を与え、呪いの加護を削り取れ。")
	await _narrate_wait(bt, "左上のゲージは「呪いの加護度」。\n0 まで削れば呪いは弱まり、鎧は崩れる。\n逆に 130 に達すれば、儀式は失敗だ。")
	await _narrate_wait(bt, "選択肢を選び、フィオナに問いかけろ。\n彼女が恥じらえば加護度は下がる。\n……が、的外れな気遣いは逆効果となる。")

func _play_scripted_intro(bt):
	await _narrate_wait(bt, "水晶球は深い赤に染まったまま。\n壁の一角に映像投影窓が浮かび上がる。")

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n……え、えっと、フィオナさん。\n……一か月、辛かったですよね……本当にお疲れ様でした。", "satoshi", ICO_SATOSHI_APOLOGETIC)
	await bt.wait(0.0)

	bt.set_bubble_side("right")
	bt.narrator_band("フィオナ:\n……あ、ありがとう……お優しい方ですね……。", "fiona", ICO_FIONA_DEFAULT)
	await bt.wait(0.0)

	await _narrate_wait(bt, "スクリーン映像「……この人、本当に優しい……気遣ってくれる……」\n優しさに心が温まり、羞恥どころか呪いが強まってしまった。")

	await _apply_gauge_change(bt, SCRIPTED_BACKFIRE)
	await _narrate_wait(bt, "水晶球の赤が、さらに濃くなる。")

	bt.set_bubble_side("bottom-right")
	bt.narrator_band("セバス:\n（眉をひそめて水晶球を見る）\n……色が濃くなっておりますな、サトシ様。", "sebas", ICO_SEBAS_FROWN)
	await bt.wait(0.0)

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("ピー助（小声・頭を抱える）:\n……サトシ、お前、ただのねぎらいじゃねえか。", "pisuke")
	await bt.wait(0.0)

func _on_choice_pressed(idx: int):
	if _choice_selected >= 0:
		return
	_choice_selected = idx
	_choice_emitted.emit(idx)

func get_lose_behavior() -> String:
	return "continue"
