extends RefCounted
class_name TownMapBase

# --- エリア定義 (override in subclasses) ---

func get_areas() -> Dictionary:
	# エリアID → エリア情報
	# {
	#   "name": 表示名,
	#   "bg": 背景画像パス,
	#   "description": エリア説明文,
	#   "connections": [接続先エリアID],
	#   "battle_rate": ランダムバトル発生率 (0.0〜1.0),
	#   "enemy_strength": 敵の強さ (1=弱, 2=中, 3=強),
	#   "battle_chapter": バトルチャプターのパス (省略時はデフォルト),
	# }
	return {}

func get_home_area() -> String:
	# ホーム画面のエリアID
	return "guild_home"

func get_home_connections() -> Array:
	# ホーム画面から直接行けるエリア
	return []

func get_home_background() -> String:
	# ホーム画面の背景
	return ""

func get_all_encounter_chars() -> Dictionary:
	# 全エンカウントキャラを返す（エディタ用）
	return {}

func get_encounters(_area_id: String) -> Array:
	# エリアごとの出現キャラリスト
	# [{ "id": キャラID, "name": 表示名, "weight": 出現重み,
	#    "portrait": ポートレート画像パス, "greeting": 遭遇時セリフ,
	#    "battle_chapter": バトルチャプターパス }, ...]
	return []
