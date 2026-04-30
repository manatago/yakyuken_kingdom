extends BattleChapterBase
class_name MinigameChapterBase

# サブイベント3「羞恥の儀」型ミニゲームの共通基盤。
# サブクラスは _get_config() / CHOICE_POOL / PISUKE_LINES を返すだけで良い。
#
# 仕組み:
#   - 上部ゲージ: GAUGE_START から始まり、0 で勝利 / GAUGE_MAX で失敗
#   - 毎ターン、CHOICE_POOL からランダム 4 つ + 「ピー助に任せる」の 5 択提示
#   - サトシ→相手→心の声＋説明（ナレーション）→ゲージ変化エフェクト の流れ

const BUBBLE_SIDE_SATOSHI := "bottom-left"
const BUBBLE_SIDE_OPPONENT := "right"
const BUBBLE_SIDE_PISUKE := "bottom-left"

# --- 内部状態 ---
var _gauge: int = 100
var _pisuke_used: Array = []
var _pisuke_cycle: int = 0
var _current_choices: Array = []
var _last_pool_indices: Array = []
var _last_zone: String = ""         # "red" / "yellow" / "green"
var _turns_in_current_zone: int = 0  # ゾーン内実行ターン数（ピー助ロック判定用）
var _tako_initial_done: bool = false
var _evidences_fired: Array = []     # 発動済み物証インデックス

var _ui_root: Control = null
var _gauge_bar: ColorRect = null
var _gauge_bg: ColorRect = null
var _gauge_label: Label = null
var _gauge_stack: Control = null
var _advance_prompt: Label = null
var _advance_prompt_tween: Tween = null
var _choice_buttons: Array[Button] = []
var _choice_selected: int = -1
var _prompt_poll_active: bool = false

signal _choice_emitted(idx: int)

# ========== サブクラスがオーバーライドすべきメソッド ==========

# 中心となる Dictionary 設定。必ずオーバーライド。
#   必須キー:
#     opponent_id (String), opponent_name (String)
#     opponent_portrait (String), opponent_icon (String)
#     gauge_label (String), gauge_max (int), gauge_start (int)
#     scripted_backfire (int): スクリプト導入で上昇する値
#     rules (Array[String]): ルール説明の段数（3段推奨）
#     scripted_intro (Dictionary): opening / satoshi / opponent / thought / color_change / pisuke
#     win_narration (String), lose_narration (String)
#     pisuke_explain (Array[String]): 1周目/2周目/3周目+ の効果説明
#     ico_satoshi_normal / gentle / nervous / apologetic (String): 顔アイコン
func _get_config() -> Dictionary:
	return {}

# 選択肢プール（サトシ選択肢 - 14個程度推奨）
# 各要素: {label, delta, satoshi, opponent, thought, explain}
func _get_choice_pool() -> Array:
	return []

# ピー助発話プール（5個推奨）
# 各要素: {opening, followup, opponent, opponent2, thought}
func _get_pisuke_lines() -> Array:
	return []

# ========== BattleChapterBase オーバーライド ==========

func get_opponent_id() -> String:
	return _get_config().get("opponent_id", "opponent")

func get_opponent_name() -> String:
	return _get_config().get("opponent_name", "相手")

func get_battle_background() -> String:
	return _get_config().get("background", "res://assets/backgrounds/stage1/bg07_st1_001.png")

func setup_scene(bt):
	var cfg := _get_config()
	var opp_id: String = cfg.get("opponent_id", "opponent")
	var portrait: String = cfg.get("opponent_portrait", "")
	if portrait.is_empty():
		return
	var opp = bt.character(opp_id)
	opp.set_portrait(portrait, {"scale": 0.55, "side": "center", "position": [0, -200]})

func get_lose_behavior() -> String:
	return "continue"

# ========== メインフロー ==========

func minigame(bt):
	var cfg := _get_config()
	_gauge = cfg.get("gauge_start", 100)
	_pisuke_used.clear()
	_pisuke_cycle = 0
	_last_zone = _get_zone(_gauge)
	_turns_in_current_zone = 0
	_tako_initial_done = false
	_evidences_fired.clear()

	_build_ui(bt)
	_set_buttons_visible(false)
	_update_gauge_display()
	await bt.wait(0.3)

	await _play_rules_intro(bt)
	await _play_scripted_intro(bt)

	await _narrate_wait(bt, "……さあ、次の一言をどう選ぶか。")
	_set_buttons_visible(true)

	var gauge_max: int = cfg.get("gauge_max", 130)
	while _gauge > 0 and _gauge < gauge_max:
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
		await _narrate_wait(bt, cfg.get("win_narration", "儀式は成功した。"))
		return "win"
	else:
		await _narrate_wait(bt, cfg.get("lose_narration", "儀式は失敗した。"))
		return "lose"

# --- ゾーン判定 ---
func _get_zone(value: int) -> String:
	var cfg := _get_config()
	var gauge_max: int = cfg.get("gauge_max", 130)
	var red_threshold: int = int(gauge_max * 0.77)  # ~100/130
	var yellow_threshold: int = int(gauge_max * 0.38)  # ~50/130
	if value >= red_threshold:
		return "red"
	elif value >= yellow_threshold:
		return "yellow"
	else:
		return "green"

# --- ルール説明 ---
func _play_rules_intro(bt):
	var cfg := _get_config()
	var rules: Array = cfg.get("rules", [])
	for line in rules:
		await _narrate_wait(bt, line)

# --- 場面4: スクリプト導入 ---
func _play_scripted_intro(bt):
	var cfg := _get_config()
	var intro: Dictionary = cfg.get("scripted_intro", {})
	var ico_apologetic: String = cfg.get("ico_satoshi_apologetic", "res://assets/ui/speakers/satoshi_apologetic.png")
	var ico_default_opp: String = cfg.get("opponent_icon", "")

	await _narrate_wait(bt, intro.get("opening", ""))

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\n%s" % intro.get("satoshi", ""), "satoshi", ico_apologetic)
	await bt.wait(0.0)

	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n%s" % [get_opponent_name(), intro.get("opponent", "")], cfg.get("opponent_id", "opponent"), ico_default_opp)
	await bt.wait(0.0)

	await _narrate_wait(bt, intro.get("thought", ""))
	await _apply_gauge_change(bt, cfg.get("scripted_backfire", 10))
	await _narrate_wait(bt, intro.get("color_change", ""))

	bt.set_bubble_side(BUBBLE_SIDE_PISUKE)
	bt.narrator_band("ピー助（小声）:\n%s" % intro.get("pisuke", ""), "pisuke")
	await bt.wait(0.0)

# --- 選択肢適用 ---
func _apply_choice(bt, idx: int):
	var choice: Dictionary = _current_choices[idx]
	if choice.get("is_pisuke", false):
		await _apply_pisuke(bt)
	else:
		var cfg := _get_config()
		# ゾーン依存 damage: damage_by_zone: {red: X, yellow: Y, green: Z}
		var delta: int = 0
		if choice.has("damage_by_zone"):
			var zone: String = _get_zone(_gauge)
			delta = int(choice.damage_by_zone.get(zone, 0))
		else:
			delta = int(choice.get("delta", 0))

		var satoshi_ico: String = cfg.get("ico_satoshi_normal", "res://assets/ui/speakers/satoshi_normal.png")
		if delta != 0:
			satoshi_ico = cfg.get("ico_satoshi_gentle", "res://assets/ui/speakers/satoshi_gentle.png")
		var opp_ico: String = cfg.get("opponent_icon", "")
		bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
		bt.narrator_band("サトシ:\n%s" % choice.satoshi, "satoshi", satoshi_ico)
		await bt.wait(0.0)
		bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
		# ゾーン依存リアクション: opponent_by_zone があれば優先、なければ opponent
		var opp_text: String = ""
		if choice.has("opponent_by_zone"):
			var z: String = _get_zone(_gauge)
			opp_text = choice.opponent_by_zone.get(z, "")
		if opp_text.is_empty():
			opp_text = choice.get("opponent", "……")
		bt.narrator_band("%s:\n%s" % [get_opponent_name(), opp_text], cfg.get("opponent_id", "opponent"), opp_ico)
		await bt.wait(0.0)

		var thought: String = choice.get("thought", "")
		var explain: String = choice.get("explain", "")
		# ゾーン依存 explain
		if choice.has("explain_by_zone"):
			var z2: String = _get_zone(_gauge)
			explain = choice.explain_by_zone.get(z2, explain)
		var narration: String = ""
		if not thought.is_empty():
			narration += "スクリーン映像「%s」\n" % thought
		narration += explain
		await _narrate_wait(bt, narration)

		await _apply_gauge_change(bt, delta)
		_turns_in_current_zone += 1

func _apply_pisuke(bt):
	var cfg := _get_config()
	var pisuke_pool: Array = _get_pisuke_lines()
	var available: Array = []
	for i in range(pisuke_pool.size()):
		if not _pisuke_used.has(i):
			available.append(i)
	if available.is_empty():
		_pisuke_used.clear()
		_pisuke_cycle += 1
		for i in range(pisuke_pool.size()):
			available.append(i)
	var pick: int = available[randi() % available.size()]
	_pisuke_used.append(pick)

	var line: Dictionary = pisuke_pool[pick]
	var ico_nervous: String = cfg.get("ico_satoshi_nervous", "res://assets/ui/speakers/satoshi_nervous.png")
	var opp_ico: String = cfg.get("opponent_icon", "")
	var opp_id: String = cfg.get("opponent_id", "opponent")

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\n……えっと──", "satoshi", ico_nervous)
	await bt.wait(0.0)
	bt.narrator_band("ピー助（サトシの声に被せて）:\n%s" % line.opening, "pisuke")
	await bt.wait(0.0)
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n%s" % [get_opponent_name(), line.opponent], opp_id, opp_ico)
	await bt.wait(0.0)
	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("ピー助（畳みかけて）:\n%s" % line.followup, "pisuke")
	await bt.wait(0.0)
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n%s" % [get_opponent_name(), line.opponent2], opp_id, opp_ico)
	await bt.wait(0.0)

	var explains: Array = cfg.get("pisuke_explain", ["心を暴かれ、集中が乱れた。", "慣れが出てきた。", "もう効きづらい。"])
	var explain: String = explains[0]
	if _pisuke_cycle == 1 and explains.size() > 1:
		explain = explains[1]
	elif _pisuke_cycle >= 2 and explains.size() > 2:
		explain = explains[2]
	await _narrate_wait(bt, "スクリーン映像「%s」\n%s" % [line.thought, explain])

	# 基本 damage（ベースを底上げ）
	var delta: int = -65
	if _pisuke_cycle == 1:
		delta = -30
	elif _pisuke_cycle >= 2:
		delta = -10
	await _apply_gauge_change(bt, delta)

	# 1周目のみ: 決めの追撃ボーナス -15
	if _pisuke_cycle == 0:
		bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
		bt.narrator_band("ピー助（止めの一撃）:\n……どうですか、心、丸裸にされた感想は？", "pisuke")
		await bt.wait(0.0)
		bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
		bt.narrator_band("%s:\n……っ！ ……や、やめて、もう、許して……！" % get_opponent_name(), opp_id, opp_ico)
		await bt.wait(0.0)
		await _apply_gauge_change(bt, -15)

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\nち、違う！ 今のは俺じゃない！", "satoshi", ico_nervous)
	await bt.wait(0.0)

# --- 選択肢ピック ---
func _pick_current_choices():
	var pool: Array = _get_choice_pool()
	var indices: Array = []
	for i in range(pool.size()):
		indices.append(i)
	indices.shuffle()
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
		_current_choices.append(pool[i])
	# ピー助ロック: ゾーン変化後1ターン以上経つと解放
	var pisuke_locked: bool = _turns_in_current_zone < 1
	var pisuke_label: String = "ピー助に任せる" if not pisuke_locked else "ピー助に任せる（残り1ターン）"
	_current_choices.append({"label": pisuke_label, "is_pisuke": true, "locked": pisuke_locked})

# --- UI ---
func _build_ui(bt: Node):
	var cfg := _get_config()
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
	frame.add_theme_stylebox_override("panel", frame_style)
	_gauge_stack.add_child(frame)

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
	_gauge_stack.add_child(track)

	_gauge_bg = ColorRect.new()
	_gauge_bg.color = Color(0.12, 0.12, 0.15, 1.0)
	_gauge_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.add_child(_gauge_bg)

	_gauge_bar = ColorRect.new()
	_gauge_bar.color = Color(0.85, 0.20, 0.20)
	_gauge_bar.position = Vector2(0, 0)
	_gauge_bar.size = Vector2(0, 0)
	_gauge_bar.anchor_top = 0.0
	_gauge_bar.anchor_bottom = 1.0
	track.add_child(_gauge_bar)

	var gloss := ColorRect.new()
	gloss.color = Color(1, 1, 1, 0.25)
	gloss.anchor_left = 0.0
	gloss.anchor_top = 0.0
	gloss.anchor_right = 1.0
	gloss.anchor_bottom = 0.35
	gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge_bar.add_child(gloss)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.25)
	shade.anchor_left = 0.0
	shade.anchor_top = 0.75
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge_bar.add_child(shade)

	_gauge_label = Label.new()
	_gauge_label.text = cfg.get("gauge_label", "ゲージ")
	_gauge_label.add_theme_font_size_override("font_size", 22)
	_gauge_label.add_theme_color_override("font_color", Color.WHITE)
	_gauge_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_gauge_label.add_theme_constant_override("shadow_offset_x", 2)
	_gauge_label.add_theme_constant_override("shadow_offset_y", 2)
	_gauge_label.add_theme_constant_override("shadow_outline_size", 3)
	_gauge_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gauge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gauge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gauge_stack.add_child(_gauge_label)

	# 選択肢ボタン（左上・ゲージ直下）
	var button_root := VBoxContainer.new()
	button_root.position = Vector2(40, 120)
	button_root.size = Vector2(420, 460)
	button_root.add_theme_constant_override("separation", 10)
	_ui_root.add_child(button_root)

	_choice_buttons.clear()
	for i in range(5):
		var btn := Button.new()
		btn.text = "[%d] -" % (i + 1)
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(420, 84)
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
				sb.bg_color = Color(0.12, 0.12, 0.14, 0.95)
				border_col = Color(0.75, 0.58, 0.18, 1.0)
			elif state == "disabled":
				sb.bg_color = Color(0.18, 0.18, 0.22, 0.55)
				border_col = Color(0.60, 0.50, 0.25, 0.50)
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

func _update_gauge_display():
	if not _gauge_bar:
		return
	var cfg := _get_config()
	var gauge_max: int = cfg.get("gauge_max", 130)
	var ratio: float = float(_gauge) / float(gauge_max)
	var parent_w: float = 600.0
	if _gauge_bar.get_parent() is Control:
		parent_w = (_gauge_bar.get_parent() as Control).size.x
	_gauge_bar.size.x = parent_w * ratio
	_gauge_bar.color = _gauge_color(_gauge, gauge_max)
	if _gauge_label:
		_gauge_label.text = "%s  %d / %d" % [cfg.get("gauge_label", "ゲージ"), _gauge, gauge_max]

func _gauge_color(value: int, max_value: int) -> Color:
	# 信号色: 高=赤 / 中=黄 / 低=緑
	var red_threshold: int = int(max_value * 0.77)  # ~100/130
	var yellow_threshold: int = int(max_value * 0.38)  # ~50/130
	if value >= red_threshold:
		return Color(0.85, 0.20, 0.20)
	elif value >= yellow_threshold:
		return Color(0.90, 0.78, 0.20)
	else:
		return Color(0.30, 0.78, 0.30)

func _set_buttons_enabled(enabled: bool):
	for i in range(_choice_buttons.size()):
		var btn = _choice_buttons[i]
		if not enabled:
			btn.disabled = true
		else:
			# ロック中のピー助は例外
			if i < _current_choices.size() and _current_choices[i].get("locked", false):
				btn.disabled = true
			else:
				btn.disabled = false

func _set_buttons_visible(visible: bool):
	for btn in _choice_buttons:
		btn.visible = visible

func _refresh_choice_buttons():
	for i in range(_choice_buttons.size()):
		if i < _current_choices.size():
			_choice_buttons[i].text = "[%d] %s" % [i + 1, _current_choices[i].label]
			# ピー助ロック: locked=trueなら無効化
			if _current_choices[i].get("locked", false):
				_choice_buttons[i].disabled = true
			else:
				_choice_buttons[i].disabled = false
		else:
			_choice_buttons[i].text = ""

func _on_choice_pressed(idx: int):
	if _choice_selected >= 0:
		return
	_choice_selected = idx
	_choice_emitted.emit(idx)

# --- ゲージ変化＋エフェクト ---
func _apply_gauge_change(bt, delta: int, apply_zone_cap: bool = true):
	var cfg := _get_config()
	var gauge_max: int = cfg.get("gauge_max", 130)
	var old_gauge: int = _gauge
	var tentative: int = clamp(old_gauge + delta, 0, gauge_max)

	# ゾーン越え防止 cap: 1ターンで複数ゾーン飛ばせない
	if apply_zone_cap and delta < 0:
		var cap_value: int = _zone_boundary_cap(old_gauge)
		if tentative < cap_value:
			tentative = cap_value

	var new_gauge: int = tentative
	var real_delta: int = new_gauge - old_gauge
	_gauge = new_gauge

	_spawn_floating_number(real_delta)
	_tween_gauge_bar(new_gauge)
	_shake_gauge(abs(real_delta) >= 10)

	if abs(real_delta) >= 10:
		_spawn_screen_flash(real_delta)
		_spawn_telop(real_delta)

	await bt.wait(1.6)

	# 物証閾値イベント発動チェック
	await _check_threshold_events(bt, old_gauge, new_gauge)

	# ゾーン変化時の処理
	var new_zone: String = _get_zone(new_gauge)
	if new_zone != _last_zone:
		_last_zone = new_zone
		_turns_in_current_zone = 0  # ピー助ロック再発動
		await _on_zone_changed(bt, new_zone)

# ゾーン境界 cap: 現ゾーン内の最低値を返す（それ以上削れない）
func _zone_boundary_cap(current: int) -> int:
	var cfg := _get_config()
	var gauge_max: int = cfg.get("gauge_max", 130)
	var red_threshold: int = int(gauge_max * 0.77)
	var yellow_threshold: int = int(gauge_max * 0.38)
	if current >= red_threshold:
		return red_threshold
	elif current >= yellow_threshold:
		return yellow_threshold
	else:
		return 0

# 物証閾値チェック（サブクラスで evidences を config に入れれば自動発動）
func _check_threshold_events(bt, old_gauge: int, new_gauge: int):
	var cfg := _get_config()
	var evidences: Array = cfg.get("evidences", [])
	for i in range(evidences.size()):
		if _evidences_fired.has(i):
			continue
		var ev: Dictionary = evidences[i]
		var threshold: int = ev.get("threshold", -1)
		if threshold < 0:
			continue
		# 閾値を下回った（またいだ）ら発動
		if old_gauge > threshold and new_gauge <= threshold:
			_evidences_fired.append(i)
			await _play_evidence_cutscene(bt, ev)

# 物証 cutscene（サブクラスでオーバーライド可）
func _play_evidence_cutscene(bt, evidence: Dictionary):
	var lines: Array = evidence.get("lines", [])
	for line in lines:
		var speaker: String = line.get("speaker", "")
		var text: String = line.get("text", "")
		var side: String = line.get("side", "bottom-left")
		var icon: String = line.get("icon", "")
		if speaker == "narrator":
			await _narrate_wait(bt, text)
		else:
			bt.set_bubble_side(side)
			bt.narrator_band("%s:\n%s" % [line.get("speaker_name", speaker), text], speaker, icon)
			await bt.wait(0.0)
	# 追加 damage（物証効果）
	var bonus_damage: int = evidence.get("damage", -30)
	if bonus_damage != 0:
		await _apply_gauge_change(bt, bonus_damage, false)  # cap 無視して物証は突破

# ゾーン変化時のフック（サブクラスで強制タコ初手など）
func _on_zone_changed(bt, new_zone: String):
	pass

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
	label.position = Vector2(660, 20)
	label.scale = Vector2(0.3, 0.3)
	label.pivot_offset = Vector2(40, 40)
	_ui_root.add_child(label)

	var pop := get_tree().create_tween()
	pop.tween_property(label, "scale", Vector2(1.15, 1.15), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(label, "scale", Vector2(1.0, 1.0), 0.10)

	get_tree().create_timer(1.8).timeout.connect(func():
		if not is_instance_valid(label):
			return
		var rise := get_tree().create_tween()
		rise.set_parallel(true)
		rise.tween_property(label, "position:y", label.position.y - 140, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		rise.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.2)
		rise.chain().tween_callback(Callable(label, "queue_free"))
	)

func _tween_gauge_bar(new_value: int):
	if not _gauge_bar:
		return
	var cfg := _get_config()
	var gauge_max: int = cfg.get("gauge_max", 130)
	var parent_w: float = 600.0
	if _gauge_bar.get_parent() is Control:
		parent_w = (_gauge_bar.get_parent() as Control).size.x
	var target_w: float = parent_w * (float(new_value) / float(gauge_max))
	var target_color: Color = _gauge_color(new_value, gauge_max)
	var tw := get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(_gauge_bar, "size:x", target_w, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_gauge_bar, "color", target_color, 0.35)
	if _gauge_label:
		_gauge_label.text = "%s  %d / %d" % [cfg.get("gauge_label", "ゲージ"), new_value, gauge_max]

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

	var pop := get_tree().create_tween()
	pop.set_parallel(true)
	pop.tween_property(label, "scale", Vector2(1.25, 1.25), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(label, "modulate:a", 1.0, 0.20)
	get_tree().create_timer(1.5).timeout.connect(func():
		if not is_instance_valid(label):
			return
		var fade := get_tree().create_tween()
		fade.tween_property(label, "modulate:a", 0.0, 0.55)
		fade.tween_callback(Callable(label, "queue_free"))
	)

# --- ナレーション＋クリック待機ヘルパー ---
func _narrate_wait(bt, text: String):
	if text.is_empty():
		return
	_ensure_advance_prompt()
	if _advance_prompt:
		_advance_prompt.visible = false
	_prompt_poll_active = true
	bt.dialogue_band("narrator", text, true)
	_poll_prompt_ready(bt)
	await bt.wait(0.0)
	_prompt_poll_active = false
	_hide_advance_prompt()
	bt.hide_dialogue_band()
	await bt.wait(0.0)

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
	if not _ui_root or _advance_prompt != null:
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
