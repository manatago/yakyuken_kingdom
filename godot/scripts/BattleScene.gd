extends Control
class_name BattleScene

## BattleScene - 単独実行可能なカードバトルシーン
## 背景、対戦相手、テーブルを設定して表示

signal battle_finished(result: Dictionary)

# === 設定（ソースコードで指定） ===
# 位置は画面サイズに対する比率（0.0〜1.0）で指定

# 背景
var background_path: String = "res://assets/backgrounds/bg06_prison_arena.png"

# 対戦相手
var opponent_path: String = "res://assets/characters/char04-003.png"
var opponent_position_ratio: Vector2 = Vector2(0.4, 0.05)  # 画面比率

# テーブル
var table_path: String = "res://assets/battle/decks/table01-001.png"
var table_position_ratio: Vector2 = Vector2(0.04, 0.18)  # 画面比率
var table_scale: Vector2 = Vector2(3.0, 3.0)

# 基準解像度（この解像度でのスケールを基準にする）
const BASE_RESOLUTION: Vector2 = Vector2(1280, 720)

# === パネルテーマ ===
enum PanelTheme { GOLD, SILVER }
var panel_theme: PanelTheme = PanelTheme.GOLD

const PANEL_THEMES = {
	PanelTheme.GOLD: {
		"outer_bg": Color(0.55, 0.4, 0.1, 1.0),
		"outer_border": Color(1.0, 0.85, 0.4, 1.0),
		"inner_bg": Color(0.1, 0.08, 0.15, 0.9),
		"inner_border": Color(0.85, 0.65, 0.13, 0.7),
	},
	PanelTheme.SILVER: {
		"outer_bg": Color(0.45, 0.48, 0.52, 1.0),
		"outer_border": Color(0.85, 0.88, 0.92, 1.0),
		"inner_bg": Color(0.1, 0.11, 0.16, 0.9),
		"inner_border": Color(0.7, 0.73, 0.78, 0.7),
	},
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}

# === カード設定 ===
var card_back_path: String = "res://assets/battle/cards/card_back.png"

# カード配置設定（画面比率）
# 各カードは以下のパラメータを持つ:
#   position: Vector2 - 画面上の位置（0.0〜1.0の比率）
#   scale: float - 全体のスケール
#   rotation: float - 回転角度（度）
#   bottom_width: float - 底辺の長さ（ピクセル、絶対値）
#   top_ratio: float - 上辺 / 底辺
#   x_offset_ratio: float - X差分 / 底辺
#   height_ratio: float - 高さ / 底辺
#
# 台形の形状図解:
#         x_offset
#         ←──→
#         ┌────────┐  ← top_width (= bottom_width × top_ratio)
#        ╱          ╲
#       ╱            ╲  height (= bottom_width × height_ratio)
#      ╱              ╲
#     └────────────────┘  ← bottom_width (絶対値)
#
var hand_cards: Array = [
	{  # 1 - 左端（追加）
		"position": Vector2(0.41, 0.61),
		"scale": 0.75,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 0.6,
		"x_offset_ratio": 0.8,
		"height_ratio": 0.5,
	},
	{  # 2 - 元の左
		"position": Vector2(0.48, 0.61),
		"scale": 0.75,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 0.6,
		"x_offset_ratio": 0.55,
		"height_ratio": 0.5,
	},
	{  # 3 - 元の中央
		"position": Vector2(0.55, 0.61),
		"scale": 0.75,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 0.6,
		"x_offset_ratio": 0.25,
		"height_ratio": 0.5,
	},
	{  # 4 - 元の右
		"position": Vector2(0.62, 0.61),
		"scale": 0.75,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 0.6,
		"x_offset_ratio": -0.1,
		"height_ratio": 0.5,
	},
	{  # 5 - 右端（追加）
		"position": Vector2(0.69, 0.61),
		"scale": 0.75,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 0.6,
		"x_offset_ratio": -0.35,
		"height_ratio": 0.5,
	},
]

# プレイヤーの手札（画面下部、元の画像比率で表示）

# プレイヤーカードの画像パス
var card_rock_path: String = "res://assets/battle/cards/rock.png"
var card_scissors_path: String = "res://assets/battle/cards/scissors.png"
var card_paper_path: String = "res://assets/battle/cards/paper.png"

# カード画像は 288x462 なので height_ratio = 462/288 ≈ 1.60
var player_cards: Array = [
	{
		"position": Vector2(0.35, 0.875),
		"scale": 0.8,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 1.0,
		"x_offset_ratio": 0.0,
		"height_ratio": 1.60,
		"type": "rock",  # グー
	},
	{
		"position": Vector2(0.425, 0.875),
		"scale": 0.8,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 1.0,
		"x_offset_ratio": 0.0,
		"height_ratio": 1.60,
		"type": "rock",  # グー
	},
	{
		"position": Vector2(0.50, 0.875),
		"scale": 0.8,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 1.0,
		"x_offset_ratio": 0.0,
		"height_ratio": 1.60,
		"type": "scissors",  # チョキ
	},
	{
		"position": Vector2(0.575, 0.875),
		"scale": 0.8,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 1.0,
		"x_offset_ratio": 0.0,
		"height_ratio": 1.60,
		"type": "paper",  # パー
	},
	{
		"position": Vector2(0.65, 0.875),
		"scale": 0.8,
		"rotation": 0.0,
		"bottom_width": 100.0,
		"top_ratio": 1.0,
		"x_offset_ratio": 0.0,
		"height_ratio": 1.60,
		"type": "paper",  # パー
	},
]

# === ノード参照 ===
@onready var background_rect: TextureRect = $Background
@onready var opponent_rect: TextureRect = $OpponentLayer/Opponent
@onready var table_rect: TextureRect = $TableLayer/Table
@onready var bottom_panel: Panel = $BottomPanel
@onready var inner_panel: Panel = $BottomPanel/InnerPanel

var _is_animating: bool = false
var _opponent_card_order: Array = [0, 1, 2, 3, 4]  # 左端から順に
var _opponent_card_index: int = 0  # 次に出すカードの番号

func _ready():
	print("=== Script loaded at: ", Time.get_datetime_string_from_system(), " ===")
	print("=== Card values: ", hand_cards[0]["x_offset_ratio"], ", ", hand_cards[1]["x_offset_ratio"], ", ", hand_cards[2]["x_offset_ratio"], " ===")
	_load_and_apply_settings()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if not _is_animating:
			_animate_opponent_card()

func _load_and_apply_settings():
	print("=== BattleScene _load_and_apply_settings ===")

	# 画面サイズを取得
	var screen_size = get_viewport_rect().size
	var scale_factor = screen_size.x / BASE_RESOLUTION.x
	print("Screen size: ", screen_size, " Scale factor: ", scale_factor)

	# 背景
	print("Background path: ", background_path)
	if background_rect and not background_path.is_empty():
		var tex = load(background_path)
		print("Background texture loaded: ", tex)
		if tex:
			background_rect.texture = tex

	# 対戦相手
	print("Opponent path: ", opponent_path)
	if opponent_rect:
		if not opponent_path.is_empty():
			var tex = load(opponent_path)
			print("Opponent texture loaded: ", tex)
			if tex:
				opponent_rect.texture = tex
				opponent_rect.visible = true
				opponent_rect.z_index = 50  # テーブルより上、カードより下
				# 比率から実際の位置を計算
				opponent_rect.position = Vector2(
					screen_size.x * opponent_position_ratio.x,
					screen_size.y * opponent_position_ratio.y
				)
		else:
			opponent_rect.visible = false

	# テーブル
	print("Table path: ", table_path)
	if table_rect:
		if not table_path.is_empty():
			var tex = load(table_path)
			print("Table texture loaded: ", tex)
			if tex:
				table_rect.texture = tex
				table_rect.visible = true
				# 比率から実際の位置を計算
				table_rect.position = Vector2(
					screen_size.x * table_position_ratio.x,
					screen_size.y * table_position_ratio.y
				)
				# スケールも画面サイズに応じて調整
				table_rect.scale = table_scale * scale_factor
		else:
			table_rect.visible = false

	print("=== Settings applied ===")

	# パネルテーマを適用
	_apply_panel_theme()

	# カードを配置
	_create_card_layout(screen_size, scale_factor)

func _apply_panel_theme():
	var theme_colors = PANEL_THEMES[panel_theme]

	var outer_style = bottom_panel.get_theme_stylebox("panel").duplicate()
	outer_style.bg_color = theme_colors["outer_bg"]
	outer_style.border_color = theme_colors["outer_border"]
	bottom_panel.add_theme_stylebox_override("panel", outer_style)

	var inner_style = inner_panel.get_theme_stylebox("panel").duplicate()
	inner_style.bg_color = theme_colors["inner_bg"]
	inner_style.border_color = theme_colors["inner_border"]
	inner_panel.add_theme_stylebox_override("panel", inner_style)

func _create_card_layout(screen_size: Vector2, scale_factor: float):
	# 既存のカードを削除
	for child in get_children():
		if child.name.begins_with("Card_"):
			child.queue_free()

	var card_back_tex = load(card_back_path)

	# 手札3枚（裏向き）
	for i in range(hand_cards.size()):
		var card_info = hand_cards[i]
		print("Card ", i, ": x_offset_ratio = ", card_info["x_offset_ratio"])
		var pos = Vector2(
			card_info["position"].x * screen_size.x,
			card_info["position"].y * screen_size.y
		)
		_create_card(
			"Card_" + str(i),
			card_back_tex,
			pos,
			card_info["scale"] * scale_factor,
			card_info["rotation"],
			card_info["bottom_width"],
			card_info["top_ratio"],
			card_info["x_offset_ratio"],
			card_info["height_ratio"]
		)

	# プレイヤーの手札（画面下部）
	var card_textures = {
		"rock": load(card_rock_path),
		"scissors": load(card_scissors_path),
		"paper": load(card_paper_path),
	}
	for i in range(player_cards.size()):
		var card_info = player_cards[i]
		var card_tex = card_textures[card_info["type"]]
		var pos = Vector2(
			card_info["position"].x * screen_size.x,
			card_info["position"].y * screen_size.y
		)
		_create_card(
			"Card_Player_" + str(i),
			card_tex,
			pos,
			card_info["scale"] * scale_factor,
			card_info["rotation"],
			card_info["bottom_width"],
			card_info["top_ratio"],
			card_info["x_offset_ratio"],
			card_info["height_ratio"]
		)

## 台形の頂点座標を生成する
##
## 底辺を基準として、全てのパラメータを比率で指定することで形状を決定する。
## これにより、底辺の長さを変えるだけで相似形の台形を生成できる。
##
## @param bottom_width: 底辺の長さ（ピクセル、絶対値）- 全ての計算の基準
## @param top_ratio: 上辺の長さ / 底辺の長さ（例: 0.5 = 上辺は底辺の半分）
## @param x_offset_ratio: X差分 / 底辺（上辺左端の、底辺左端からの水平オフセット）
## @param height_ratio: 高さ / 底辺の長さ（例: 0.7 = 高さは底辺の70%）
## @return: 台形の4頂点（左上、右上、右下、左下の順）
func _create_trapezoid(bottom_width: float, top_ratio: float,
		x_offset_ratio: float, height_ratio: float) -> PackedVector2Array:
	var top_width = bottom_width * top_ratio
	var x_offset = bottom_width * x_offset_ratio
	var height = bottom_width * height_ratio

	print("Trapezoid: bottom=", bottom_width, " top=", top_width, " x_offset=", x_offset, " height=", height)

	return PackedVector2Array([
		Vector2(x_offset, 0),                # 左上
		Vector2(x_offset + top_width, 0),    # 右上
		Vector2(bottom_width, height),       # 右下
		Vector2(0, height),                  # 左下
	])

func _create_card(card_name: String, texture: Texture2D, pos: Vector2,
		card_scale: float, rotation_deg: float,
		bottom_width: float, top_ratio: float,
		x_offset_ratio: float, height_ratio: float) -> Polygon2D:
	# スケール適用後の底辺の長さ
	var scaled_bottom_width = bottom_width * card_scale

	# 台形の頂点を生成
	var vertices = _create_trapezoid(
		scaled_bottom_width,
		top_ratio,
		x_offset_ratio,
		height_ratio
	)

	# 高さを計算（位置調整用）
	var height = scaled_bottom_width * height_ratio

	# テクスチャUV座標
	var tex_size = texture.get_size()
	var uvs = PackedVector2Array([
		Vector2(0, 0),
		Vector2(tex_size.x, 0),
		Vector2(tex_size.x, tex_size.y),
		Vector2(0, tex_size.y),
	])

	var card = Polygon2D.new()
	card.name = card_name
	card.texture = texture
	card.polygon = vertices
	card.uv = uvs
	card.z_index = 100  # 最前面に表示
	print("Card ", card_name, " vertices: ", card.polygon)
	# 底辺の中心を基準に配置
	card.position = pos - Vector2(scaled_bottom_width / 2, height / 2)
	card.rotation_degrees = rotation_deg
	add_child(card)
	return card

func _animate_opponent_card():
	# 順番にカードを出す
	if _opponent_card_index >= _opponent_card_order.size():
		return

	var card_idx = _opponent_card_order[_opponent_card_index]
	var target_card = get_node_or_null("Card_" + str(card_idx))
	if not target_card:
		return

	_is_animating = true
	_opponent_card_index += 1
	var move_distance = 80.0
	var scale_to = 1.2

	# 前面に表示
	target_card.z_index = 101 + _opponent_card_index

	var tween = create_tween()
	# 1) その場から手前に出てくる + 拡大（同時に0.4秒）
	tween.set_parallel(true)
	tween.tween_property(target_card, "position:y", target_card.position.y + move_distance, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(target_card, "scale", Vector2(scale_to, scale_to), 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain()
	# 少し間を置く
	tween.tween_interval(0.3)
	# 2) フェードアウトして消える（0.3秒）
	tween.tween_property(target_card, "modulate:a", 0.0, 0.3) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	# 完了後にノードを削除
	tween.tween_callback(func():
		target_card.queue_free()
		_is_animating = false
	)
