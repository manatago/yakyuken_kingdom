class_name SatoshiLoseNarrations
extends RefCounted

# サトシ敗北時の共通ナレーション・プール
# 設計詳細: docs/scenarios/_common_lose_narrations.md
#
# 各パターンは frames（[speaker_id, text] のリスト）と outcome を持つ。
# speaker_id:
#   "narrator" → 地の文 (ナレーター)
#   "satoshi"  → サトシ
#   "pisuke"   → ピー助
# text は {opponent} プレースホルダーを含む場合があり、render() で置換する。
# outcome:
#   "recover_clothes" → 服回収。追加副作用なし（既存じゃんけん仕様の
#                        カード喪失のみ）
#   "lose_clothes"    → 服喪失。GameState.money から REPLACEMENT_COST 減算

const REPLACEMENT_COST: int = 50  # 服の買い直し費用（G）

const PATTERNS: Dictionary = {
	"A-1": {
		"category": "A",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップが発動し、サトシの両手が勝手に動き出す。\n意思に反して、襟元を緩め、ボタンを外し、シャツを脱ぎ捨てる。\n続いてベルトが緩み、ズボンが床に滑り落ちた。"],
			["narrator", "制御が外れた瞬間、サトシは床に散らばった衣服に飛びつき、\n{opponent}の手が伸びるより先にひったくった。"],
			["satoshi", "ご、ごめんなさいごめんなさい！"],
			["narrator", "半裸で衣服を抱え、サトシは脱兎のごとく駆け出した。"],
		],
	},
	"A-2": {
		"category": "A",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップに体を乗っ取られ、サトシは無表情のままシャツを脱ぎ、\nズボンを下ろし、床にきれいに揃えて置いた。"],
			["narrator", "制御が解けると同時にサトシは床に転がり、\n散らばった服を必死にかき集めた。"],
			["satoshi", "俺の、俺のだから……！"],
			["narrator", "両手で衣服を抱え込み、半裸のまま、\nサトシは情けない悲鳴を上げて駆け出した。"],
		],
	},
	"A-3": {
		"category": "A",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップが発動。意思を奪われたサトシは、\nシャツのボタンを一つずつ外し、ズボンのベルトを緩め、\n衣服を一枚ずつ床に脱ぎ落としていく。"],
			["narrator", "制御が外れた瞬間、サトシは目を血走らせて床の服に飛びついた。"],
			["satoshi", "う、うわぁぁ、返せ、返せぇぇ！"],
			["narrator", "涙と鼻水でぐしゃぐしゃになりながら、\nサトシは服を抱え、転げるように退散した。"],
		],
	},
	"B-1": {
		"category": "B",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップが発動。サトシの体が勝手に動き、シャツが、ズボンが、\nひとつずつ床に脱ぎ落とされていく。"],
			["narrator", "意思を取り戻したサトシは、両手で前を押さえてその場で土下座した。"],
			["satoshi", "ご、ごめんなさいごめんなさいごめんなさいぃぃ！\nふ、服だけは、服だけは返してくださいぃぃ！"],
			["narrator", "涙と鼻水で床を濡らし、何度も何度も額を擦りつけて詫びた。\n{opponent}は呆れた様子で、足元の衣服をぽいと放り投げた。"],
			["pisuke", "（小声）...プライドってもんが無いのか、お前は。"],
			["narrator", "サトシは服を抱きしめ、半泣きで退散した。"],
		],
	},
	"B-2": {
		"category": "B",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップに乗っ取られたサトシは、自らの手でシャツを脱ぎ、\nベルトを緩め、ズボンを床に落とした。"],
			["narrator", "制御が解けると同時に、がくがくと膝をつき、\n頭を床に擦りつけた。"],
			["satoshi", "な、なんでもします、なんでもしますからぁぁ！\nふ、服だけは、お情けを、お情けをぉぉ！"],
			["narrator", "涙でぐしゃぐしゃになった顔で詫び続けるサトシに、\n{opponent}はため息混じりに服を投げて寄越した。"],
			["satoshi", "あ、ありがとうございますぅぅ！"],
			["narrator", "情けなく感謝を述べ、サトシは衣服を抱えて駆け出した。"],
		],
	},
	"B-3": {
		"category": "B",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップが発動。サトシは無表情のまま、ほぼ全ての衣服を\nひとつずつ床に脱ぎ落としていった。"],
			["narrator", "制御が解けたサトシは、両手で前を押さえ、その場で土下座した。"],
			["satoshi", "許してくださいぃ、ふ、服を、服をどうかぁぁ！"],
			["narrator", "小刻みに震える肩、涙で曇る視界、額を必死に床に擦り続ける。\n{opponent}は呆れ果てて、衣服を「持ってけ」と放り投げた。"],
			["narrator", "サトシは抱きしめるように服を取り、よろよろと退散した。"],
		],
	},
	"C-1": {
		"category": "C",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップが発動。サトシは意思に反してシャツのボタンを外し、\nベルトを緩め、ズボンを床に落とした。"],
			["narrator", "為す術もなく両手で前を押さえるサトシの代わりに、\nピー助が囁き始めた。"],
			["pisuke", "（サトシの声で）...いやぁ、見事な技でした。\nあなたほどの方なら、敗者の服など興味ないでしょう？\nあれは家族の形見でして、私の手元にあって初めて意味があるもの。"],
			["narrator", "{opponent}は満更でもない顔で、足元の衣服をぽいと投げて寄越した。"],
			["pisuke", "（小声）...サトシ、いいか、いつ何時もプライドはくすぐっておけ。"],
			["narrator", "サトシは情けない顔のまま、衣服を抱えて退散した。"],
		],
	},
	"C-2": {
		"category": "C",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップに体を奪われ、サトシはシャツとズボンを次々に脱ぎ捨てた。\n口をパクパクさせて言葉が出ないサトシの代わりに、\nピー助が囁いた。"],
			["pisuke", "（サトシの声で）...これ、王都中央広場で晒されたら、あなたの方も\n品位を疑われますよ。\n「冒険者を全裸にして喜ぶ」と。\n...返していただけますね？"],
			["narrator", "{opponent}は鼻白んで、衣服を投げ寄越した。"],
			["pisuke", "（小声）...口は災いの元、ってのを利用するんだよ。"],
			["narrator", "サトシは涙目でうなずきながら、服を掻き集めて駆け出した。"],
		],
	},
	"C-3": {
		"category": "C",
		"outcome": "recover_clothes",
		"frames": [
			["narrator", "チップ発動でシャツが脱げ、ズボンが床に落ちる。\nサトシは半泣きで何も言えない。"],
			["pisuke", "（サトシの声で・しおらしく）...すみません。こいつ、本当にこれしか着るものがないんです。\n実家から仕送りも止まってまして...。\nどうか、ご慈悲を...。"],
			["narrator", "{opponent}は呆れた様子で、「持ってけ、馬鹿が」と\n衣服を投げて寄越した。"],
			["pisuke", "（小声）...嘘も方便ってな。お前、感謝しろよ。"],
			["narrator", "サトシは服を抱え、ぐすぐすと泣きながら退散した。"],
		],
	},
	"D-1": {
		"category": "D",
		"outcome": "lose_clothes",
		"frames": [
			["narrator", "チップが発動。サトシは自分の手で、シャツも、ズボンも、\n一枚ずつ床に脱ぎ落とした。"],
			["narrator", "{opponent}は床の衣服を見下ろし、つまむように拾い上げた。\n汚れた男の使い古しなど、誰も家宝にはしない。\nだが裏路地の古着屋に流せば、銅貨数枚にはなる。"],
			["narrator", "両手で前を押さえ、サトシはがたがた震える。"],
			["pisuke", "（焦った声で）サトシ、もう諦めろ！ 走れ、走るんだ！"],
			["satoshi", "う、うわぁぁぁ、嫌だ嫌だ嫌だぁぁぁ！"],
			["narrator", "人目を避ける場所を必死に探しながら、\nサトシは半裸でギルドへ駆け戻った。"],
		],
	},
	"D-2": {
		"category": "D",
		"outcome": "lose_clothes",
		"frames": [
			["narrator", "チップに体を奪われ、サトシは無感情にシャツとズボンを脱ぎ、\n床に揃えて置いた。"],
			["narrator", "{opponent}はその衣服を一瞥もせず、足で蹴り散らかしてから\n部屋を出ていった。"],
			["narrator", "サトシは床に散った服に手を伸ばすが、ピー助が叫んだ。"],
			["pisuke", "サトシ、それ、もう拾うな！ 罠かもしれん！\n...今は、逃げろ！"],
			["satoshi", "で、でも俺の服がぁぁ...！"],
			["narrator", "ピー助に強引に引かれ、サトシは半裸で人目を忍びつつ、\nギルドへ逃げ帰った。"],
		],
	},
	"D-3": {
		"category": "D",
		"outcome": "lose_clothes",
		"frames": [
			["narrator", "チップが発動。サトシは意思とは無関係に、シャツとズボンを\nひとつずつ脱ぎ捨てた。"],
			["narrator", "{opponent}は床の衣服を、ぞんざいに拾い上げた。\n古着屋に持ち込めば、捨てるよりはマシな値が付く。\nそれすら惜しい代物だが、「一応」貰っておく、という顔で。"],
			["satoshi", "そ、そんなぁぁ！"],
			["narrator", "両手で前を押さえ、その場でへたり込むサトシ。"],
			["pisuke", "（深いため息）...諦めろ、サトシ。買い直すぞ。"],
			["narrator", "ピー助はサトシの腕を引き、半裸で号泣するサトシを、\n裏路地伝いにギルドまで連れ帰った。"],
		],
	},
}

const ALL_IDS: Array = [
	"A-1", "A-2", "A-3",
	"B-1", "B-2", "B-3",
	"C-1", "C-2", "C-3",
	"D-1", "D-2", "D-3",
]

# allowed_ids から重複回避でランダム選出。
# exclude_id が指定されていて、それ以外の選択肢が残るならば必ず除外する。
# 戻り値: pattern dict + "id" フィールド
static func pick_random(allowed_ids: Array, exclude_id: String = "") -> Dictionary:
	var pool: Array = []
	for id in allowed_ids:
		if id != exclude_id and PATTERNS.has(id):
			pool.append(id)
	if pool.is_empty():
		# 全部除外された / allowed が空 → fallback で全 ID から
		for id in allowed_ids:
			if PATTERNS.has(id):
				pool.append(id)
		if pool.is_empty():
			pool = ALL_IDS.duplicate()
	pool.shuffle()
	var picked_id: String = pool[0]
	var entry: Dictionary = PATTERNS[picked_id].duplicate(true)
	entry["id"] = picked_id
	return entry

# pattern の各 frame のテキスト中の {opponent} を opponent_name で置換した
# frames を返す。元の pattern は変更しない。
static func render_frames(pattern: Dictionary, opponent_name: String) -> Array:
	var out: Array = []
	var frames: Array = pattern.get("frames", [])
	for f in frames:
		var speaker: String = String(f[0])
		var text: String = String(f[1]).format({"opponent": opponent_name})
		out.append([speaker, text])
	return out
