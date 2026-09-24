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
	# エリアごとの出現キャラリスト。サブクラスで _area_encounters を定義し
	# _build_encounter() を使って組み立てる。
	return []

# エンカウントエントリを組み立てる共通ヘルパー。
# グーチョキパーとグレードをどちらもランダムに生成する。
# grade_min / grade_max でグレードの上限・下限を指定する。
func _build_encounter(char_data: Dictionary, entry: Dictionary) -> Dictionary:
	var combined := char_data.duplicate(true)
	combined["weight"] = entry.get("weight", 1)
	var g_min: int = entry.get("grade_min", 1)
	var g_max: int = entry.get("grade_max", g_min)
	const HAND_TYPES := ["rock", "scissors", "paper"]
	var random_hand: Array = []
	for _i in range(EncounterDatabase.RANDOM_BATTLE_DECK_SIZE):
		random_hand.append({
			"hand": HAND_TYPES[randi() % HAND_TYPES.size()],
			"grade": randi_range(g_min, g_max),
		})
	combined["hand"] = random_hand
	return combined
