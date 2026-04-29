extends BattleChapterBase

# ST3「シスター・マグダレナ」ミニゲーム
#
# 設計：docs/minigame_designs/st3_magdalena.md 準拠
# - 信仰の威厳ゲージを 0 にすれば成功、130 で失敗
# - 毎ターン CHOICE_POOL からランダム 4 択 ＋ ピー助任せ ＝ 5 ボタン
# - delta 値で効果分け：
#     的外れ (0)：刺さらない、ゲージ変動なし
#     逆効果 (+10)：神への帰依・殉教・祈り → 敬虔さ強化
#     軽刺激 (-5)：筋肉/汗/入浴/共闘 → 萌えスイッチ軽タッチ
#     ピー助任せ (-50 / -20 / -5)：直球 BL 妄想、減衰あり
# - サトシは章タイトルだけ見て選ぶ → 的外れ／逆効果を選びがち
# - プレイヤーは引用文を読んで「湯気」「汗」「二人きり」「傷」キーワードを拾う

const MAGDALENA_PORTRAIT := "res://assets/characters/stage3/magdalena_001.png"
const MAGDALENA_ID := "magdalena"

const GAUGE_MAX := 130
const GAUGE_START := 110       # スクリプト導入前
const SCRIPTED_BACKFIRE := 10  # 開幕で +10（サトシのとちり）

# --- アイコン ---
const ICO_SATOSHI_NORMAL     := "res://assets/ui/speakers/satoshi_normal.png"
const ICO_SATOSHI_NERVOUS    := "res://assets/ui/speakers/satoshi_nervous.png"
const ICO_SATOSHI_GENTLE     := "res://assets/ui/speakers/satoshi_gentle.png"
const ICO_SATOSHI_APOLOGETIC := "res://assets/ui/speakers/satoshi_apologetic.png"
const ICO_MAGDALENA_DEFAULT  := "res://assets/ui/speakers/magdalena_default.png"

# --- 選択肢プール（毎ターン 4 つランダム抽出）---
const CHOICE_POOL := [
	# === 的外れ (delta 0) — 刺さらない ===
	{
		"label": "『聖戦の譜』第1章",
		"excerpt": "勇敢な騎士は盾を構えた──",
		"delta": 0,
		"satoshi": "聖女マグダレナ様。\n「勇敢な騎士は盾を構えた──」",
		"mag": "……勇ましきお話ですわ。",
		"explain": "戦闘描写は彼女の心に届かない。",
	},
	{
		"label": "『懺悔の書』序章",
		"excerpt": "罪深き者よ、膝をつきなさい──",
		"delta": 0,
		"satoshi": "聖女マグダレナ様。\n「罪深き者よ、膝をつきなさい──」",
		"mag": "……ええ、ご立派な心がけでございます。",
		"explain": "形式的な訓話、サトシ自身がうろたえる。",
	},
	{
		"label": "『建国記』第5章",
		"excerpt": "王は国を統べると誓った──",
		"delta": 0,
		"satoshi": "聖女マグダレナ様。\n「王は国を統べると誓った──」",
		"mag": "……歴史のお話ですか。",
		"explain": "政治史で彼女の心は動かない。",
	},
	{
		"label": "『神の慈愛』序章",
		"excerpt": "神は万物を愛で包みたまう──",
		"delta": 0,
		"satoshi": "聖女マグダレナ様。\n「神は万物を愛で包みたまう──」",
		"mag": "……心地よきお言葉ですわ。",
		"explain": "ありきたりの慈愛訓話、彼女には日常。",
	},
	{
		"label": "『道徳論』第2章",
		"excerpt": "節制こそ徳の礎──",
		"delta": 0,
		"satoshi": "聖女マグダレナ様。\n「節制こそ徳の礎──」",
		"mag": "……至極ごもっとも。",
		"explain": "道徳論で彼女は微動だにしない。",
	},
	# === 逆効果 (delta +10) — 敬虔心が再燃 ===
	{
		"label": "『聖典』創世篇",
		"excerpt": "光あれ──神は仰せられた──",
		"delta": 10,
		"satoshi": "聖女マグダレナ様。\n「光あれ──神は仰せられた──」",
		"mag": "……素晴らしき朗読ですわ。\n心が洗われる気持ちでございます。",
		"explain": "聖典そのまま読み、敬虔さが強化された。",
	},
	{
		"label": "『殉教者録』最終章",
		"excerpt": "主のために血を流し、天国へ昇った──",
		"delta": 10,
		"satoshi": "聖女マグダレナ様。\n「主のために血を流し、天国へ昇った──」",
		"mag": "……美しきお話。\n殉教の誉れ、わたくしも続きとうございます。",
		"explain": "殉教譚で使命感に火がついた。",
	},
	{
		"label": "『祈祷集』朝の祈り",
		"excerpt": "主よ、わが魂を御許に──",
		"delta": 10,
		"satoshi": "聖女マグダレナ様。\n「主よ、わが魂を御許に──」",
		"mag": "……ありがたきお祈り。\n心が澄み渡りますわ。",
		"explain": "祈祷で彼女の信仰が深まった。",
	},
	{
		"label": "『聖母マリア讃歌』",
		"excerpt": "汚れなきマリアよ、我らを──",
		"delta": 10,
		"satoshi": "聖女マグダレナ様。\n「汚れなきマリアよ、我らを──」",
		"mag": "……汚れなき御方への讃歌、\nわたくしの心の支えでございます。",
		"explain": "聖母讃歌で彼女の敬虔さが固まった。",
	},
	# === 軽刺激 (delta -5) — 萌えスイッチ軽タッチ ===
	{
		"label": "『朝日に汗する若き騎士』第3章 湯浴み",
		"excerpt": "湯気立ち昇る浴場で、鍛えられた背筋が──",
		"delta": -5,
		"satoshi": "聖女マグダレナ様。\n「湯気立ち昇る浴場で、鍛えられた背筋が──」",
		"mag": "……っ、そ、その章は……\n（頬がわずかに紅潮）",
		"explain": "湯気と汗の描写で、わずかに頬が染まった。",
	},
	{
		"label": "『聖なる鍛錬 第二部』第7章 相互加護",
		"excerpt": "傷を労る手つきの優しさ──",
		"delta": -5,
		"satoshi": "聖女マグダレナ様。\n「傷を労る手つきの優しさ──」",
		"mag": "……っ、そ、その描写は……\n（指先がわずかに震える）",
		"explain": "戦友の傷手当描写で、指先が震えた。",
	},
	{
		"label": "『双子剣士の朝露』最終章 二人の誓い",
		"excerpt": "二人きりの夜明けに、指を重ねて──",
		"delta": -5,
		"satoshi": "聖女マグダレナ様。\n「二人きりの夜明けに、指を重ねて──」",
		"mag": "……っ、夜明けの場面は……\n（声が微かに上ずる）",
		"explain": "二人きりの誓いの描写で、声が上ずった。",
	},
	{
		"label": "『武者修行日記』",
		"excerpt": "汗だくで鍛錬し、もつれ合う二人の体──",
		"delta": -5,
		"satoshi": "聖女マグダレナ様。\n「汗だくで鍛錬し、もつれ合う二人の体──」",
		"mag": "……っ、もつれ合う……\n（息を呑む）",
		"explain": "もつれ合う描写で、彼女が息を呑んだ。",
	},
	{
		"label": "『剣友録』第12章",
		"excerpt": "同胞の傷を、素手で押さえた──",
		"delta": -5,
		"satoshi": "聖女マグダレナ様。\n「同胞の傷を、素手で押さえた──」",
		"mag": "……っ、素手で……\n（瞳が潤む）",
		"explain": "同胞の傷を素手で押さえる描写、瞳が潤んだ。",
	},
]

# --- ピー助任せ（直球 BL 妄想、減衰あり）---
# 1 回目 -50、2 回目 -20、3 回目以降 -5
const PISUKE_DELTAS := [-50, -20, -5]

const PISUKE_LINES := [
	{
		"opening": "──続きのページに、落書きがございました。",
		"followup": "──筋骨隆々の騎士が、修道士の法衣をめくり、\n──汗だくで腰を擦り合わせている、ご自筆の絵が。",
		"finish": "──毎晩、書斎で、こういう絵を描きながら、\n──ご自身を慰めてらっしゃる、ですよね？",
		"mag": "……っ！ ……み、見ないで、見ないでぇ……！",
	},
	{
		"opening": "──巻末付録、『傷手当の実技』第3節。",
		"followup": "──「胸筋に塗る軟膏の扱い方」と題して、\n──男の胸を素手で撫で回す指の動きが、図解で。",
		"finish": "──毎晩、この図を眺めながら、\n──ご自身の指を、男の胸の代わりに動かしてらっしゃる、ですよね？",
		"mag": "……っ！ ……あ、あの図解は、医学的な、ただの──！",
	},
	{
		"opening": "──著者注記を見ると、興味深い記述が。",
		"followup": "──「最も熱量を込めた章は、夜更けの汗だくの場面」と。\n──書きながら、何度も読み返されたそうで。",
		"finish": "──書き直すたびに、ご自身を慰めてらっしゃる、\n──そういう熱量、ですよね？",
		"mag": "……っ！ ……熱量、それは、創作の、ただの──！",
	},
]

# --- 内部状態 ---
var _gauge: int = GAUGE_START
var _pisuke_used_count: int = 0
var _pisuke_used_lines: Array = []
var _current_choices: Array = []
var _last_pool_indices: Array = []
var _turns_done: int = 0

# --- UI 参照 ---
var _ui_root: Control = null
var _gauge_bar: ColorRect = null
var _gauge_label: Label = null
var _gauge_stack: Control = null
var _choice_buttons: Array[Button] = []

signal _choice_emitted(idx: int)

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

# === メイン ===

func minigame(bt):
	_gauge = GAUGE_START
	_pisuke_used_count = 0
	_pisuke_used_lines.clear()
	_turns_done = 0

	_build_ui(bt)
	_set_buttons_visible(false)
	_update_gauge_display()
	await bt.wait(0.3)

	await _play_rules_intro(bt)
	await _play_scripted_intro(bt)

	_set_buttons_visible(true)
	while _gauge > 0 and _gauge < GAUGE_MAX:
		_pick_current_choices()
		_refresh_choice_buttons()
		_update_gauge_display()
		_set_buttons_enabled(true)
		var idx: int = await _choice_emitted
		_set_buttons_enabled(false)
		await _apply_choice(bt, idx)
		_update_gauge_display()
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

# === 導入 ===

func _play_rules_intro(bt):
	bt.dialogue_band("narrator", "【懺悔室で妄想を誘発せよ】\n持ち込んだ本の章を選んで読み上げ、\nマグダレナの「信仰の威厳」を 0 にせよ。", true)
	await bt.wait(0.0)
	bt.dialogue_band("narrator", "【勝敗】\n0 で勝利。130 到達で焚刑に処される。\n章タイトルだけでなく、引用文をよく読め。", true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

func _play_scripted_intro(bt):
	bt.dialogue_band("narrator", "懺悔室。薄暗い小窓を挟んで、二人きり。\nマグダレナは聖典を手に、悔悛の朗読を待っている。", true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n聖女マグダレナ様。\n朗読を、始めさせていただきます。", "satoshi", ICO_SATOSHI_APOLOGETIC)
	await bt.wait(0.0)

	bt.set_bubble_side("right")
	bt.narrator_band("マグダレナ:\n……ええ。罪人の魂、\nわたくしが受け止めましょう。", MAGDALENA_ID, ICO_MAGDALENA_DEFAULT)
	await bt.wait(0.0)

	_gauge = clamp(_gauge + SCRIPTED_BACKFIRE, 0, GAUGE_MAX)
	bt.dialogue_band("narrator", "緊張のあまり、サトシは最初の聖句を噛んでしまった。\n（信仰の威厳 +%d）" % SCRIPTED_BACKFIRE, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

# === 選択肢ピック ===

func _pick_current_choices():
	var avail: Array = []
	for i in range(CHOICE_POOL.size()):
		if not _last_pool_indices.has(i):
			avail.append(i)
	if avail.size() < 4:
		avail.clear()
		for i in range(CHOICE_POOL.size()):
			avail.append(i)
	avail.shuffle()
	var picked: Array = avail.slice(0, 4)
	_last_pool_indices = picked.duplicate()

	_current_choices.clear()
	for idx in picked:
		var c: Dictionary = CHOICE_POOL[idx].duplicate(true)
		c["pool_idx"] = idx
		_current_choices.append(c)

	var pisuke_locked: bool = _turns_done < 1
	var pisuke_label: String = "[5] ピー助に任せる"
	if pisuke_locked:
		pisuke_label += "（残り 1 ターン）"
	_current_choices.append({
		"label": pisuke_label,
		"is_pisuke": true,
		"locked": pisuke_locked,
	})

# === 選択肢適用 ===

func _apply_choice(bt, idx: int):
	var choice: Dictionary = _current_choices[idx]
	if choice.get("is_pisuke", false):
		await _apply_pisuke(bt)
		return

	var delta: int = int(choice.get("delta", 0))
	var sat_ico: String = ICO_SATOSHI_APOLOGETIC
	if delta < 0:
		sat_ico = ICO_SATOSHI_GENTLE
	elif delta > 0:
		sat_ico = ICO_SATOSHI_NERVOUS

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n%s" % choice.get("satoshi", ""), "satoshi", sat_ico)
	await bt.wait(0.0)

	bt.set_bubble_side("right")
	bt.narrator_band("マグダレナ:\n%s" % choice.get("mag", ""), MAGDALENA_ID, ICO_MAGDALENA_DEFAULT)
	await bt.wait(0.0)

	var explain: String = choice.get("explain", "")
	var delta_text: String = _format_delta(delta)
	if not explain.is_empty():
		bt.dialogue_band("narrator", "%s\n（信仰の威厳 %s）" % [explain, delta_text], true)
		await bt.wait(0.0)
		bt.hide_dialogue_band()
		await bt.wait(0.0)

	_gauge = clamp(_gauge + delta, 0, GAUGE_MAX)

# === ピー助任せ ===

func _apply_pisuke(bt):
	var avail: Array = []
	for i in range(PISUKE_LINES.size()):
		if not _pisuke_used_lines.has(i):
			avail.append(i)
	if avail.is_empty():
		_pisuke_used_lines.clear()
		for i in range(PISUKE_LINES.size()):
			avail.append(i)
	avail.shuffle()
	var pick: int = avail[0]
	_pisuke_used_lines.append(pick)

	var line: Dictionary = PISUKE_LINES[pick]
	var delta: int = PISUKE_DELTAS[mini(_pisuke_used_count, PISUKE_DELTAS.size() - 1)]
	_pisuke_used_count += 1

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ:\n……えっと、何を読めば──", "satoshi", ICO_SATOSHI_NERVOUS)
	await bt.wait(0.0)
	bt.narrator_band("ピー助（小声）:\n……これだ。読み上げろ。", "pisuke")
	await bt.wait(0.0)

	bt.set_bubble_side("bottom-left")
	bt.narrator_band("サトシ（ピー助の声色）:\n%s" % line.get("opening", ""), "satoshi", ICO_SATOSHI_GENTLE)
	await bt.wait(0.0)

	bt.narrator_band("サトシ（ピー助の声色）:\n%s" % line.get("followup", ""), "satoshi", ICO_SATOSHI_GENTLE)
	await bt.wait(0.0)

	bt.narrator_band("サトシ（ピー助の声色）:\n%s" % line.get("finish", ""), "satoshi", ICO_SATOSHI_GENTLE)
	await bt.wait(0.0)

	bt.set_bubble_side("right")
	bt.narrator_band("マグダレナ:\n%s" % line.get("mag", ""), MAGDALENA_ID, ICO_MAGDALENA_DEFAULT)
	await bt.wait(0.0)

	var delta_text: String = _format_delta(delta)
	bt.dialogue_band("narrator", "妄想直撃！\n（信仰の威厳 %s）" % delta_text, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)

	_gauge = clamp(_gauge + delta, 0, GAUGE_MAX)

# === ヘルパー ===

func _format_delta(delta: int) -> String:
	if delta > 0:
		return "+%d" % delta
	return "%d" % delta

# === UI 構築 ===

func _build_ui(bt: Node):
	_ui_root = Control.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bt.add_child(_ui_root)

	_gauge_stack = Control.new()
	_gauge_stack.position = Vector2(40, 40)
	_gauge_stack.size = Vector2(600, 60)
	_ui_root.add_child(_gauge_stack)
	_build_gauge()

	var btn_root := VBoxContainer.new()
	btn_root.position = Vector2(40, 380)
	btn_root.size = Vector2(800, 320)
	btn_root.add_theme_constant_override("separation", 8)
	_ui_root.add_child(btn_root)

	_choice_buttons.clear()
	for i in range(5):
		var btn := _make_choice_button("[%d]" % (i + 1))
		var idx_capture: int = i
		btn.pressed.connect(func(): _on_choice_pressed(idx_capture))
		btn_root.add_child(btn)
		_choice_buttons.append(btn)

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
	frame.add_theme_stylebox_override("panel", fs)
	_gauge_stack.add_child(frame)

	var track := Control.new()
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.offset_left = 5; track.offset_top = 5; track.offset_right = -5; track.offset_bottom = -5
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
	btn.add_theme_font_size_override("font_size", 18)
	btn.custom_minimum_size = Vector2(800, 56)
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
		elif state == "disabled":
			sb.bg_color = Color(0.18, 0.18, 0.22, 0.55)
			border_col = Color(0.60, 0.50, 0.25, 0.50)
		sb.border_width_left = 1; sb.border_width_right = 1
		sb.border_width_top = 1; sb.border_width_bottom = 1
		sb.border_color = border_col
		sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6; sb.corner_radius_bottom_right = 6
		sb.content_margin_left = 16; sb.content_margin_right = 8
		sb.content_margin_top = 6; sb.content_margin_bottom = 6
		btn.add_theme_stylebox_override(state, sb)
	return btn

func _refresh_choice_buttons():
	for i in range(_choice_buttons.size()):
		if i >= _current_choices.size():
			_choice_buttons[i].visible = false
			continue
		_choice_buttons[i].visible = true
		var c: Dictionary = _current_choices[i]
		if c.get("is_pisuke", false):
			_choice_buttons[i].text = c.get("label", "")
			_choice_buttons[i].disabled = c.get("locked", false)
		else:
			var label: String = "[%d] %s" % [i + 1, c.get("label", "")]
			var excerpt: String = c.get("excerpt", "")
			if not excerpt.is_empty():
				label += "\n    「%s」" % excerpt
			_choice_buttons[i].text = label
			_choice_buttons[i].disabled = false

func _set_buttons_visible(visible: bool):
	for btn in _choice_buttons:
		btn.visible = visible

func _set_buttons_enabled(enabled: bool):
	for i in range(_choice_buttons.size()):
		if i >= _current_choices.size():
			_choice_buttons[i].disabled = true
			continue
		var c: Dictionary = _current_choices[i]
		if not enabled:
			_choice_buttons[i].disabled = true
		elif c.get("is_pisuke", false):
			_choice_buttons[i].disabled = c.get("locked", false)
		else:
			_choice_buttons[i].disabled = false

func _teardown_ui():
	if _ui_root and is_instance_valid(_ui_root):
		_ui_root.queue_free()
	_ui_root = null
	_gauge_bar = null
	_gauge_label = null
	_gauge_stack = null
	_choice_buttons.clear()

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
	if value >= 100:
		return Color(0.85, 0.20, 0.20)
	elif value >= 50:
		return Color(0.90, 0.78, 0.20)
	else:
		return Color(0.30, 0.78, 0.30)

func _on_choice_pressed(idx: int):
	if idx >= _current_choices.size():
		return
	var c: Dictionary = _current_choices[idx]
	if c.get("is_pisuke", false) and c.get("locked", false):
		return
	_choice_emitted.emit(idx)

func _narrate_wait(bt, text: String):
	if text.is_empty():
		return
	bt.dialogue_band("narrator", text, true)
	await bt.wait(0.0)
	bt.hide_dialogue_band()
	await bt.wait(0.0)
