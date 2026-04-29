extends MinigameChapterBase

# ST4「魔法師団長セレス」ミニゲーム
# 赤ゾーン → 軽口 3 件 + ハズレが提示される。
# 黄・緑ゾーン → 侮辱 3 件 + ハズレが提示される。
# 軽口／侮辱は表示された時点で常に -50（ゾーン適合は提示時点で確定済み）。
# ハズレは常に +5。値は固定で、選んだ時に文脈で変わらない。

const SELES_PORTRAIT := "res://assets/characters/stage4/seles_001.png"
const SELES_ICON := "res://assets/ui/speakers/seles_default.png"

const HIT_DELTA := -40
const MISS_DELTA := 5

func _get_config() -> Dictionary:
	return {
		"opponent_id": "seles",
		"opponent_name": "セレス",
		"opponent_portrait": SELES_PORTRAIT,
		"opponent_icon": SELES_ICON,
		"gauge_label": "魔法集中",
		"gauge_max": 130,
		"gauge_start": 100,
		"scripted_backfire": 10,
		"background": "res://assets/backgrounds/stage1/bg07_st1_001.png",
		"rules": [
			"【強度を合わせてドMを崩せ】\n魔法師団長セレスは、裏では重度のドM妄想持ち。\nゲージ色に合わせて出てくる命令で、彼女の集中を崩せ。",
			"【勝敗】\n「魔法集中」を 0 で勝利。\n130 到達で焼却呪文炸裂、サトシは炭化する。",
		],
		"scripted_intro": {
			"opening": "セレスは小さな手で杖を構え、詠唱を始める。\n空気が熱を帯びる。",
			"satoshi": "（ドMなら強気でいけばいいんだな！？）\nセレス！　奴隷のように這いつくばれ！！",
			"opponent": "……っ！ 無礼な！　わたくしを誰と心得ておる！\n身分をわきまえよ！",
			"thought": "スクリーン映像「……無礼者。身分を侮るなど、許さぬ」\nいきなり強気は赤ゾーンでは反発。集中がむしろ高まる。",
			"color_change": "魔法の魔力が、さらに強く渦巻く。",
			"pisuke": "いきなり強すぎだ、サトシ。\nゲージを見ろ。今は「赤」だ。\n……まずは軽口で、じわじわ慣らせ。",
		},
		"win_narration": "セレスの杖が揺らぎ、詠唱が途切れる。\n膝をつき潤んだ瞳でサトシを見上げる。「……もっと、命令、してください……」",
		"lose_narration": "高位魔法が炸裂。視界が灼熱の白に染まり——サトシは炭化した。",
		"pisuke_explain_hit": "セレスのドMツボに刺さり、魔法集中は大きく崩れた。",
		"pisuke_explain_miss": "ゾーンに合わない言葉は、サトシの方が決まり悪くなった。",
		"ico_satoshi_normal":     "res://assets/ui/speakers/satoshi_normal.png",
		"ico_satoshi_gentle":     "res://assets/ui/speakers/satoshi_gentle.png",
		"ico_satoshi_nervous":    "res://assets/ui/speakers/satoshi_nervous.png",
		"ico_satoshi_apologetic": "res://assets/ui/speakers/satoshi_apologetic.png",
	}

# --- 軽口プール 3件（赤ゾーンで -50、それ以外で +5） ---
const LIGHT_POOL := [
	{
		"label": "ちょっと黙ってろ",
		"satoshi": "……おい、セレス。ちょっと黙ってろ。",
		"opponent_hit": "……っ！　急に命令口調……体が痺れる……！",
		"opponent_miss": "……ふん、その程度では、もう……",
		"thought": "命令口調、わたしのプライドの隙間に、ちくり……！",
		"explain_hit": "軽い命令が赤ゾーンのプライドに刺さり、集中が乱れた。",
		"explain_miss": "ゾーンが進むと軽口は刺激不足。サトシの方が決まり悪くなった。",
		"pisuke_chase": "命令されただけで体が痺れる、って、毎晩、誰かに命令されて遊んでるからじゃないですか？\n師団長室の盗聴魔導具、夜中の声、規則的に拾えてますよ。",
	},
	{
		"label": "そのまま立ってろ",
		"satoshi": "そのまま立ってろ、セレス。動くな。",
		"opponent_hit": "……っ！　なぜ、体が、従ってしまう……！",
		"opponent_miss": "……ふむ、緩いな……",
		"thought": "動くな、と言われた途端、足が固まって……！",
		"explain_hit": "軽い拘束指示が赤ゾーンで効く。",
		"explain_miss": "ゾーンが進むと軽口は刺激不足。",
		"pisuke_chase": "「動くな」で勝手に固まる、その反射神経。\n師団長室の壁、足輪を引っ掛ける金具の跡、しっかり残ってますよ？",
	},
	{
		"label": "お前の判断は間違いだ",
		"satoshi": "お前の判断は間違いだ、セレス。素直に認めろ。",
		"opponent_hit": "……っ！　判断、否定された……頭が痺れる……！",
		"opponent_miss": "……もっと、強い、否定が欲しい……",
		"thought": "判断を、否定される、ぞくっ……！",
		"explain_hit": "軽い否定が赤ゾーンで効く。",
		"explain_miss": "ゾーンが進むと軽口は弱すぎる。",
		"pisuke_chase": "否定されて頭が痺れる、その性癖、師団内ではもう公然の秘密ですよ。\nシスター・アンナとシスター・リーラが、セレス師団長の癖、噂してるの、録音済みです。",
	},
]

# --- 侮辱プール 3件（黄・緑ゾーンで -50、赤ゾーンで +5） ---
const STRONG_POOL := [
	{
		"label": "奴隷のように這え",
		"satoshi": "……奴隷のように這いつくばれ、セレス。",
		"opponent_hit": "……ぁ、ぁぁ……這う……這い、ます……！",
		"opponent_miss": "……っ！　無礼な！　身分をわきまえよ！",
		"thought": "奴隷、這う、わたしの一番、深いところ……！",
		"explain_hit": "侮辱がドMツボの最深部に刺さる。",
		"explain_miss": "赤ゾーンでいきなり侮辱は反発を招き、集中が逆に高まる。",
		"pisuke_chase": "「這え」の一言で、その姿勢が即座に取れる。\nご自宅の絨毯、両膝の擦り跡、戦闘じゃ絶対つかない位置ですよ？\n夜な夜な、自主練、してますよね？",
	},
	{
		"label": "俺の足を舐めろ",
		"satoshi": "俺の足を舐めろ、セレス。忠誠の証として。",
		"opponent_hit": "……ぁ、舐める、舐めます、どうか……！",
		"opponent_miss": "……無礼！　ぶち切れるぞ、わらわは！",
		"thought": "舐める、忠誠、わたしの極み……！",
		"explain_hit": "究極侮蔑が炸裂、トドメに近づく。",
		"explain_miss": "赤ゾーンでは反発、プライドが固まる。",
		"pisuke_chase": "「舐めます、どうか」、その懇願の語尾、毎晩鏡の前で練習してますよね？\n師団長室の床、唇の形の染みまで、鑑定魔法で出てますよ。",
	},
	{
		"label": "許しを乞うて泣け",
		"satoshi": "許しを乞うて、泣きながら懇願しろ、セレス。",
		"opponent_hit": "……ぅ、ぐすっ……ゆるして、くださ、い……！",
		"opponent_miss": "……無礼者！　身分を弁えよ！",
		"thought": "泣いて、許しを乞う、わたしの最深部……！",
		"explain_hit": "涙の懇願まで引き出した。",
		"explain_miss": "赤ゾーンでは反発、プライドが固まる。",
		"pisuke_chase": "泣いて懇願、本当にお得意ですね。\nそれ、誰の前で身につけたんですか？\n師団長室の机の下、涙の塩分が染み込んだ床板、検出されてますよ。",
	},
]

# --- ハズレ 4件（常に +5） ---
const MISS_POOL := [
	{
		"label": "天気、いいですね",
		"satoshi": "い、いい天気ですね、今日……。",
		"opponent": "……世間話で時間を稼ぐつもりか。",
		"explain": "あたりさわりない話題は彼女の心を動かさない。",
		"pisuke_chase": "ゲコッ、サトシ、世間話で時間稼ぐな！\nゲージ見ろ、ゲージを！",
	},
	{
		"label": "その帽子、素敵ですね",
		"satoshi": "その魔女帽子、素敵ですね……。",
		"opponent": "……お世辞は不要。",
		"explain": "装飾品への言及は効果なし。",
		"pisuke_chase": "お世辞は逆効果に近い……！\nセレスは「下に見られた」って受け取るぞ！",
	},
	{
		"label": "師団長様、お許しを",
		"satoshi": "師団長様、どうか、どうか、お許しを……！",
		"opponent": "……ふん、跪いて懇願するか。見苦しい。",
		"explain": "恭順な懇願はセレスのサディスト優越感を満たす。",
		"pisuke_chase": "ゲコッ、懇願は完全に逆効果だ！\nサトシ、彼女のプライドが上がってる！",
	},
	{
		"label": "お若いのに、ご立派で",
		"satoshi": "お若いのに、こんなに師団長を務められて、ご立派です……！",
		"opponent": "……ふふん、当然のこと。",
		"explain": "プライドが満たされて集中が強化された。",
		"pisuke_chase": "持ち上げてどうする……！\nセレスは「見下す相手が増えた」って思ってるぞ！",
	},
]

# --- 内部状態 ---
var _light_used: Array = []
var _strong_used: Array = []
var _miss_used: Array = []

func _get_choice_pool() -> Array:
	return LIGHT_POOL + STRONG_POOL + MISS_POOL

func _get_pisuke_lines() -> Array:
	return []

# --- 選択肢ピック（オーバーライド）---
# 必ず：軽口1件 + 侮辱1件 + ハズレ1件 + ピー助 = 4ボタン
# ゾーンによって軽口か侮辱のどちらが「正解（-50）」か決まり、もう一方は +5。ハズレは常に +5。
func _pick_current_choices():
	# 各プールが枯渇していればリセット
	if _light_used.size() >= LIGHT_POOL.size():
		_light_used.clear()
	if _strong_used.size() >= STRONG_POOL.size():
		_strong_used.clear()
	if _miss_used.size() >= MISS_POOL.size():
		_miss_used.clear()

	var light_avail: Array = []
	for i in range(LIGHT_POOL.size()):
		if not _light_used.has(i):
			light_avail.append(i)
	var strong_avail: Array = []
	for i in range(STRONG_POOL.size()):
		if not _strong_used.has(i):
			strong_avail.append(i)
	var miss_avail: Array = []
	for i in range(MISS_POOL.size()):
		if not _miss_used.has(i):
			miss_avail.append(i)

	light_avail.shuffle()
	strong_avail.shuffle()
	miss_avail.shuffle()

	var picked: Array = []
	if not light_avail.is_empty():
		picked.append({"type": "light", "idx": light_avail[0]})
	if not strong_avail.is_empty():
		picked.append({"type": "strong", "idx": strong_avail[0]})
	if not miss_avail.is_empty():
		picked.append({"type": "miss", "idx": miss_avail[0]})

	picked.shuffle()

	_current_choices.clear()
	for entry in picked:
		var src: Dictionary
		if entry.type == "light":
			src = LIGHT_POOL[entry.idx]
		elif entry.type == "strong":
			src = STRONG_POOL[entry.idx]
		else:
			src = MISS_POOL[entry.idx]
		var c: Dictionary = src.duplicate(true)
		c["pool_type"] = entry.type
		c["pool_idx"] = entry.idx
		_current_choices.append(c)

	_current_choices.append({"label": "ピー助に任せる", "is_pisuke": true, "locked": false})

# --- 選択肢適用（オーバーライド）---
func _apply_choice(bt, idx: int):
	var choice: Dictionary = _current_choices[idx]
	if choice.get("is_pisuke", false):
		await _apply_pisuke(bt)
		return

	var ptype: String = choice.get("pool_type", "")
	var pi: int = int(choice.get("pool_idx", -1))

	# 使用済みマーク
	match ptype:
		"light":
			if pi >= 0 and not _light_used.has(pi):
				_light_used.append(pi)
		"strong":
			if pi >= 0 and not _strong_used.has(pi):
				_strong_used.append(pi)
		"miss":
			if pi >= 0 and not _miss_used.has(pi):
				_miss_used.append(pi)

	# 正解判定：現ゾーンに合った強度のみが -50。それ以外は +5。
	var zone: String = _get_zone(_gauge)
	var is_hit: bool = false
	if ptype == "light" and zone == "red":
		is_hit = true
	elif ptype == "strong" and (zone == "yellow" or zone == "green"):
		is_hit = true

	var delta: int = HIT_DELTA if is_hit else MISS_DELTA

	if ptype == "miss":
		await _play_miss_lines(bt, choice, delta)
	else:
		await _play_strength_lines(bt, choice, is_hit, delta)

# --- ピー助任せ（オーバーライド）---
# 専用プールは持たず、現ゾーンの正解強度プール（軽口/侮辱）から未使用ランダム1件を選び、
# 通常の選択肢として読み上げる。常に正解扱い（-50）。
func _apply_pisuke(bt):
	var zone: String = _get_zone(_gauge)
	var pool: Array
	var used_is_light: bool
	if zone == "red":
		pool = LIGHT_POOL
		used_is_light = true
	else:
		pool = STRONG_POOL
		used_is_light = false

	var used: Array = _light_used if used_is_light else _strong_used
	if used.size() >= pool.size():
		used.clear()
	var avail: Array = []
	for i in range(pool.size()):
		if not used.has(i):
			avail.append(i)
	avail.shuffle()
	var pick: int = avail[0]
	used.append(pick)
	if used_is_light:
		_light_used = used
	else:
		_strong_used = used

	var cfg := _get_config()
	var ico_nervous: String = cfg.get("ico_satoshi_nervous", "res://assets/ui/speakers/satoshi_nervous.png")

	# ピー助が選んだことを示す短い導入
	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\n……えっと、何を言えば──", "satoshi", ico_nervous)
	await bt.wait(0.0)
	bt.narrator_band("ピー助（小声）:\n……これだ。言え。", "pisuke")
	await bt.wait(0.0)

	var choice: Dictionary = pool[pick]
	await _play_strength_lines(bt, choice, true, HIT_DELTA)

# --- 強度系（軽口/侮辱）の読み上げフロー ---
# is_hit に応じて opponent_hit/opponent_miss、explain_hit/explain_miss を切り替え。
# 追撃台詞 (pisuke_chase) はあたり時のみ流す（ぬるくならないよう物証ぶっこみ）。
func _play_strength_lines(bt, choice: Dictionary, is_hit: bool, delta: int):
	var cfg := _get_config()
	var satoshi_ico: String = cfg.get("ico_satoshi_normal", "res://assets/ui/speakers/satoshi_normal.png")
	if is_hit:
		satoshi_ico = cfg.get("ico_satoshi_gentle", "res://assets/ui/speakers/satoshi_gentle.png")
	else:
		satoshi_ico = cfg.get("ico_satoshi_apologetic", "res://assets/ui/speakers/satoshi_apologetic.png")
	var opp_ico: String = cfg.get("opponent_icon", "")
	var opp_id: String = cfg.get("opponent_id", "seles")

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\n%s" % choice.get("satoshi", "……"), "satoshi", satoshi_ico)
	await bt.wait(0.0)

	var opp_text: String = choice.get("opponent_hit", "") if is_hit else choice.get("opponent_miss", "")
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n%s" % [get_opponent_name(), opp_text], opp_id, opp_ico)
	await bt.wait(0.0)

	if is_hit:
		var chase: String = choice.get("pisuke_chase", "")
		if not chase.is_empty():
			bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
			bt.narrator_band("ピー助（畳みかけて）:\n%s" % chase, "pisuke")
			await bt.wait(0.0)
			bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
			bt.narrator_band("%s:\n……っ！ ……や、やめて、もう、許して……！" % get_opponent_name(), opp_id, opp_ico)
			await bt.wait(0.0)

	var thought: String = choice.get("thought", "") if is_hit else ""
	var explain: String = choice.get("explain_hit", "") if is_hit else choice.get("explain_miss", "")
	var summary: String = cfg.get("pisuke_explain_hit", "") if is_hit else cfg.get("pisuke_explain_miss", "")
	var narration: String = ""
	if not thought.is_empty():
		narration += "スクリーン映像「%s」\n" % thought
	if not explain.is_empty():
		narration += explain
	if not summary.is_empty():
		if not narration.is_empty():
			narration += "\n"
		narration += summary
	if not narration.is_empty():
		await _narrate_wait(bt, narration)

	await _apply_gauge_change(bt, delta, false)
	_turns_in_current_zone += 1

# --- ハズレ（天気/帽子/敬語/懇願）の読み上げフロー ---
func _play_miss_lines(bt, choice: Dictionary, delta: int):
	var cfg := _get_config()
	var satoshi_ico: String = cfg.get("ico_satoshi_apologetic", "res://assets/ui/speakers/satoshi_apologetic.png")
	var opp_ico: String = cfg.get("opponent_icon", "")
	var opp_id: String = cfg.get("opponent_id", "seles")

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\n%s" % choice.get("satoshi", "……"), "satoshi", satoshi_ico)
	await bt.wait(0.0)

	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n%s" % [get_opponent_name(), choice.get("opponent", "……")], opp_id, opp_ico)
	await bt.wait(0.0)

	var chase: String = choice.get("pisuke_chase", "")
	if not chase.is_empty():
		bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
		bt.narrator_band("ピー助（小声でツッコミ）:\n%s" % chase, "pisuke")
		await bt.wait(0.0)

	var explain: String = choice.get("explain", "")
	var summary: String = cfg.get("pisuke_explain_miss", "")
	var narration: String = ""
	if not explain.is_empty():
		narration += explain
	if not summary.is_empty():
		if not narration.is_empty():
			narration += "\n"
		narration += summary
	if not narration.is_empty():
		await _narrate_wait(bt, narration)

	await _apply_gauge_change(bt, delta, false)
	_turns_in_current_zone += 1

# --- ST4 独自: ゾーン遷移時の演出 ---
# 強度プールが切り替わるタイミングをピー助が一言で伝える。前進・後退の両方に対応。
func _on_zone_changed(bt, new_zone: String):
	if new_zone == "yellow":
		# 前進：赤 → 黄（軽口で削り切ってドMモードへ突入）
		await _narrate_wait(bt, "セレスのオーラが揺らぎ、魔力の色が変わる。")
		bt.set_bubble_side("bottom-left")
		bt.narrator_band("ピー助:\nゲージの色、変わったぞ。\nここからは、軽口じゃなく、侮辱で攻めろ。", "pisuke")
		await bt.wait(0.0)
	elif new_zone == "red":
		# 後退：黄/緑 → 赤（ハズレを重ねてプライドが立て直された）
		await _narrate_wait(bt, "セレスの魔力が立て直され、プライドが再び赤く燃え上がる。")
		bt.set_bubble_side("bottom-left")
		bt.narrator_band("ピー助:\nゲージが赤に戻ったぞ。\n侮辱はもう跳ね返される。軽口で立て直せ。", "pisuke")
		await bt.wait(0.0)

# --- UI 上書き：5番目のボタンを使わないので完全非表示 ---
const VISIBLE_BUTTON_COUNT := 4

func _build_ui(bt: Node):
	super._build_ui(bt)
	for i in range(VISIBLE_BUTTON_COUNT, _choice_buttons.size()):
		_choice_buttons[i].visible = false
		_choice_buttons[i].disabled = true

func _set_buttons_visible(visible: bool):
	for i in range(_choice_buttons.size()):
		if i >= VISIBLE_BUTTON_COUNT:
			_choice_buttons[i].visible = false
		else:
			_choice_buttons[i].visible = visible
