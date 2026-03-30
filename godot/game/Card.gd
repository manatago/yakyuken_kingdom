class_name Card
extends RefCounted

var hand: String = ""       # "rock" / "scissors" / "paper"
var grade: int = 1          # 1=ノーマル, 2=ブロンズ, 3=シルバー, 4=ゴールド, 5=プラチナ
var effects: Array = []     # 付与効果（将来用）

func _init(h: String = "", g: int = 1):
	hand = h
	grade = g

func duplicate_card() -> Card:
	var c := Card.new(hand, grade)
	c.effects = effects.duplicate(true)
	return c

func to_dict() -> Dictionary:
	return {"hand": hand, "grade": grade, "effects": effects.duplicate(true)}

static func from_dict(data: Dictionary) -> Card:
	var c := Card.new(data.get("hand", ""), int(data.get("grade", 1)))
	c.effects = data.get("effects", [])
	return c

# グレード別確率補正（比率維持方式）
# { grade: {"lose_up": 相手が負ける手↑, "win_down": 相手が勝つ手↓} }
const GRADE_EFFECTS := {
	1: {"lose_up": 0.0,  "win_down": 0.0},   # ノーマル
	2: {"lose_up": 0.05, "win_down": 0.0},    # ブロンズ
	3: {"lose_up": 0.10, "win_down": 0.0},    # シルバー
	4: {"lose_up": 0.0,  "win_down": 0.15},   # ゴールド
	5: {"lose_up": 0.15, "win_down": 0.15},   # プラチナ
}

# じゃんけんの関係
const LOSES_TO := {"rock": "scissors", "scissors": "paper", "paper": "rock"}
const WINS_AGAINST := {"rock": "paper", "scissors": "rock", "paper": "scissors"}

func get_grade_effect() -> Dictionary:
	return GRADE_EFFECTS.get(grade, GRADE_EFFECTS[1])

# 相手の確率を補正する（比率維持方式）
# base_probs: {"rock": 0.33, "scissors": 0.33, "paper": 0.33}
# 戻り値: 補正後の確率 Dictionary
static func apply_grade_effect(player_hand: String, player_grade: int, base_probs: Dictionary) -> Dictionary:
	var effect: Dictionary = GRADE_EFFECTS.get(player_grade, GRADE_EFFECTS[1])
	var lose_up: float = effect.lose_up
	var win_down: float = effect.win_down
	if lose_up == 0.0 and win_down == 0.0:
		return base_probs.duplicate()

	var result := base_probs.duplicate()
	var lose_hand: String = LOSES_TO[player_hand]   # 相手が負ける手
	var win_hand: String = WINS_AGAINST[player_hand] # 相手が勝つ手
	var draw_hand: String = player_hand               # あいこの手

	# 1. 相手が負ける手を上げる
	if lose_up > 0.0:
		var old_lose: float = result[lose_hand]
		var new_lose: float = old_lose + lose_up
		result[lose_hand] = new_lose
		# 残り2つを比率維持で縮小
		var remaining_old: float = result[win_hand] + result[draw_hand]
		if remaining_old > 0.0:
			var remaining_new: float = 1.0 - new_lose
			var ratio: float = remaining_new / remaining_old
			result[win_hand] *= ratio
			result[draw_hand] *= ratio

	# 2. 相手が勝つ手を下げる
	if win_down > 0.0:
		var old_win: float = result[win_hand]
		var new_win: float = maxf(old_win - win_down, 0.0)
		result[win_hand] = new_win
		# 残り2つを比率維持で拡大
		var remaining_old: float = result[lose_hand] + result[draw_hand]
		if remaining_old > 0.0:
			var remaining_new: float = 1.0 - new_win
			var ratio: float = remaining_new / remaining_old
			result[lose_hand] *= ratio
			result[draw_hand] *= ratio

	return result

func _to_string() -> String:
	return "Card(%s, grade=%d)" % [hand, grade]
