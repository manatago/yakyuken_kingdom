class_name EncounterDatabase
extends RefCounted

# ランダムバトル共通設定
const RANDOM_BATTLE_HP := 1
const RANDOM_BATTLE_DECK_SIZE := 3
const RANDOM_BATTLE_PLAYER_DECK_SIZE := 3

# 全キャラ定義
var characters: Dictionary = {}

func _init():
	characters = {
		"thug_a": {
			"id": "thug_a",
			"name": "チンピラA",
			"portraits": {
				"encounter": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.5, "position": [0, 0],
				},
				"battle": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
				"farewell_win": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
				"farewell_lose": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
			},
			"lines": {
				"greetings": [
					"おい新入り！ カード賭けて勝負しろよ！",
					"よぉ、いいカード持ってそうじゃねぇか！",
					"暇だからよ、ちょっと遊んでけよ！",
				],
				"battle_start": [
					"さっさとカード出しな！",
					"ビビってんのか？ 早くしろよ！",
					"グズグズすんな！",
				],
				"farewells_win": [
					"くっ……覚えてろよ！",
					"チクショウ……次は負けねぇ！",
					"うわぁぁ、俺のカードが！",
				],
				"farewells_lose": [
					"ガハハ！ 弱ぇ弱ぇ！",
					"カードもらいだ！ ざまぁみろ！",
					"新入りの分際で歯向かうからだ！",
				],
			},
			"hand": [{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "paper", "grade": 1}],
			"tendency": {"rock": 2.33},
			"gold_reward": {"min": 5, "max": 15},
		},
		"thug_b": {
			"id": "thug_b",
			"name": "ゴロツキ",
			"portraits": {
				"encounter": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.5, "position": [0, 0],
				},
				"battle": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
				"farewell_win": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
				"farewell_lose": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
			},
			"lines": {
				"greetings": [
					"ヘッ、弱そうなやつ発見。カードよこしな！",
					"おっと、そこの新顔。通行料代わりに勝負だ！",
					"チッ、金はねぇのか。ならカードで払え！",
				],
				"battle_start": [
					"さっさと出しな！",
					"もたもたすんなよ！",
					"ほら、早くしろ！",
				],
				"farewells_win": [
					"嘘だろ……こんなガキに……",
					"テメェ、覚えとけよ……！",
					"くそっ……今日は運が悪い！",
				],
				"farewells_lose": [
					"ケッ、こんなもんか。",
					"弱いくせにウロウロすんな！",
					"……今日は見逃してやる。",
				],
			},
			"hand": [{"hand": "rock", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "paper", "grade": 1}],
			"tendency": {},
			"gold_reward": {"min": 5, "max": 15},
		},
		"drunk": {
			"id": "drunk",
			"name": "酔っ払い冒険者",
			"portraits": {
				"encounter": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.5, "position": [0, 0],
				},
				"battle": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
				"farewell_win": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
				"farewell_lose": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
			},
			"lines": {
				"greetings": [
					"うぃ～……おまえ、じゃんけん……できるかぁ？",
					"ひっく……俺と勝負しろぉ……負けたことねぇんだよ……",
					"なぁ……一杯おごれよ……いや、カードでいいや……",
				],
				"battle_start": [
					"うぃ～……いくぞぉ……",
					"ひっく……まだ酔ってねぇからな……",
					"よっしゃ……勝負だぁ……",
				],
				"farewells_win": [
					"うぇ……酔いが覚めちまった……",
					"ひっく……ま、まぐれだからな……",
					"うぅ……カード返せよぉ……",
				],
				"farewells_lose": [
					"ひっひっひ……やっぱ酔拳は最強だな……",
					"酒代ゲットぉ～！",
					"ひっく……もう一杯飲めるぜぇ……",
				],
			},
			"hand": [{"hand": "rock", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1}],
			"tendency": {"scissors": 1.5},
			"gold_reward": {"min": 3, "max": 10},
		},
		"merchant": {
			"id": "merchant",
			"name": "恰幅のいい商人",
			"portraits": {
				"encounter": {
					"path": "res://assets/characters/random_battle/char001_random_01.png",
					"scale": 0.73, "side": "center", "position": [0, -50],
				},
				"battle": {
					"path": "res://assets/characters/random_battle/char001_random_02.png",
					"scale": 0.35, "side": "center", "position": [0, -182],
				},
				"farewell_win": {
					"path": "res://assets/characters/random_battle/char001_random_03.png",
					"scale": 0.8, "side": "center", "position": [0, -30],
				},
				"farewell_lose": {
					"path": "res://assets/characters/random_battle/char001_random_04.png",
					"scale": 0.53, "side": "center", "position": [0, 200],
				},
			},
			"lines": {
				"greetings": [
					"いらっしゃいませ。カードで勝負しましょう？",
					"ふふふ、お兄さん、お店寄っていくかい？ まずは腕試し。",
					"ここいらの決まりは、カードで勝つことさ",
				],
				"battle_start": [
					"さぁ、商売開始だよ。",
					"ふふふ、いい取引にしようじゃないか。",
					"お手柔らかにね。",
				],
				"farewells_win": [
					"ふっ、服は返してください...",
					"ひぃ、おゆるしを...",
					"どっ、どうか服だけは返してください...",
				],
				"farewells_lose": [
					"商売は勝ってこそ、だよ。ふふふ。お金とカードはもらっていくよ",
					"いい取引だったねぇ。またよろしく。お金とカードはもらっていくよ",
					"ふふ、これも商売の一環さ。お金とカードはもらっていくよ",
				],
			},
			"hand": [{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "scissors", "grade": 1}],
			"tendency": {"paper": 1.5},
			"gold_reward": {"min": 10, "max": 25},
		},
		"merchant2": {
			"id": "merchant2",
			"name": "怪しい商人",
			"portraits": {
				"encounter": {
					"path": "res://assets/characters/random_battle/char002_random_01.png",
					"scale": 0.5, "side": "center", "position": [0, -50],
				},
				"battle": {
					"path": "res://assets/characters/random_battle/char002_random_02.png",
					"scale": 0.42, "side": "center", "position": [0, -248],
				},
				"farewell_win": {
					"path": "res://assets/characters/random_battle/char002_random_03.png",
					"scale": 0.45, "side": "center", "position": [0, 160],
				},
				"farewell_lose": {
					"path": "res://assets/characters/random_battle/char002_random_04.png",
					"scale": 0.53, "side": "center", "position": [0, 50],
				},
			},
			"lines": {
				"greetings": [
					"いらっしゃいませ。カードで勝負しましょう？",
					"これはこれは、いらっしゃませ？ まずは腕試しから。",
					"ここの所倍の決まりは、カードで勝つことですよ",
				],
				"battle_start": [
					"さぁ、商売開始だよ。",
					"ふふふ、いい取引にしようじゃないか。",
					"お手柔らかにね。",
				],
				"farewells_win": [
					"ふっ、服は返してください...",
					"ひぃ、おゆるしを...",
					"どっ、どうか服だけは返してください...",
				],
				"farewells_lose": [
					"商売は勝ってこそ、だよ。ふふふ。お金とカードはもらっていくよ",
					"いい取引だったねぇ。またよろしく。お金とカードはもらっていくよ",
					"ふふ、これも商売の一環さ。お金とカードはもらっていくよ",
				],
			},
			"hand": [{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "scissors", "grade": 1}],
			"tendency": {"paper": 1.5},
			"gold_reward": {"min": 10, "max": 25},
		},
		"sailor": {
			"id": "sailor",
			"name": "荒くれ船乗り",
			"portraits": {
				"encounter": {
					"path": "res://assets/characters/random_battle/char003_random_01.png",
					"side": "center", "scale": 0.5, "position": [0, 0],
				},
				"battle": {
					"path": "res://assets/characters/random_battle/char003_random_02.png",
					"scale": 0.50, "side": "center", "position": [0, -225],
				},
				"farewell_win": {
					"path": "res://assets/characters/random_battle/char003_random_03.png",
					"scale": 0.60, "side": "center", "position": [0, 100],
				},
				"farewell_lose": {
					"path": "res://assets/characters/random_battle/char003_random_04.png",
					"scale": 0.50, "side": "center", "position": [0, 0],
				},
			},
			"lines": {
				"greetings": [
					"港町のルールだ！ 通りたきゃカードで勝負しな！",
					"おう、陸の人間か。海の男の強さ見せてやるよ！",
					"退屈でよぉ。お前、相手しろ！",
				],
				"battle_start": [
					"海の男を舐めんなよ！",
					"波に揉まれた俺の拳を見せてやる！",
					"さぁ、錨を上げろ！",
				],
				"farewells_win": [
					"ぐぬぬ……次は負けねぇ",
					"くそっ、覚えていろよ",
					"マジかよ……くそが！",
				],
				"farewells_lose": [
					"ガハハ！ 海の男にゃ敵わねぇだろ！",
					"陸の人間はこんなもんか！",
					"大海原を渡ってきた俺に勝てるわけねぇ！",
				],
			},
			"hand": [{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "scissors", "grade": 1}],
			"tendency": {"rock": 1.5},
			"gold_reward": {"min": 8, "max": 20},
		},
		"bandit": {
			"id": "bandit",
			"name": "野盗",
			"portraits": {
				"encounter": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.5, "position": [0, 0],
				},
				"battle": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
				"farewell_win": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
				"farewell_lose": {
					"path": "res://assets/characters/stage1_battle/char09_st1_battle_001.png",
					"side": "center", "scale": 0.4, "position": [0, -199],
				},
			},
			"lines": {
				"greetings": [
					"城壁の外は俺たちの縄張りだ。カードを置いていけ！",
					"ここを通りたきゃ、カードで勝負だ！",
					"ケケケ……いいカード持ってそうだな！",
				],
				"battle_start": [
					"覚悟しろ！",
					"カードを全部いただくぜ！",
					"ケケケ、楽しませてもらうぜ！",
				],
				"farewells_win": [
					"ちっ……仲間呼ぶぞ！ 覚えてろ！",
					"くそ……今日は運が悪かった……",
					"テメェ……次はねぇぞ！",
				],
				"farewells_lose": [
					"ケケケ、カードは没収だ！",
					"二度とここに来るんじゃねぇぞ！",
					"ヒャッハー！ いただきだ！",
				],
			},
			"hand": [{"hand": "rock", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "paper", "grade": 1}],
			"tendency": {},
			"gold_reward": {"min": 10, "max": 30},
		},
	}

# キャラデータ取得
func get_char(id: String) -> Dictionary:
	return characters.get(id, {})

# 全キャラ取得（エディタ用）
func get_all_chars() -> Dictionary:
	return characters

# セリフをランダム選択
static func pick_line(char_data: Dictionary, line_key: String) -> String:
	var lines_dict: Dictionary = char_data.get("lines", {})
	var lines: Array = lines_dict.get(line_key, [])
	if lines.is_empty():
		return ""
	return lines[randi() % lines.size()]

# ポートレート取得（フォールバック付き）
# scene: "encounter", "battle", "farewell_win", "farewell_lose"
static func get_portrait(char_data: Dictionary, scene: String) -> Dictionary:
	var portraits: Dictionary = char_data.get("portraits", {})
	if portraits.has(scene):
		return portraits[scene]
	# farewell_win / farewell_lose → battle → encounter の順でフォールバック
	if scene.begins_with("farewell") and portraits.has("battle"):
		return portraits["battle"]
	if portraits.has("battle"):
		return portraits["battle"]
	if portraits.has("encounter"):
		return portraits["encounter"]
	return {}
