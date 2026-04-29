extends MinigameChapterBase

# ST5「騎士団長フェリア・尋問を投げ返せ」ミニゲーム
#
# 設計：
# - 心鏡の珠は範囲内で最も心が動揺する者を自動追尾する装置
# - フェリアは「絶対に動じぬ心」を鍛え上げ、珠を扱える数少ない人物
# - だが、彼女には抑圧した癖があり、質問の語彙にそれが滲み出る
# - その語彙をピー助が解析し、サトシが投げ返すと、彼女のプライドが反論で動揺
# - 装置は正直なので、動揺の主役がフェリアに移れば針が彼女に振れる
#
# メカニクス：
# - 毎ターン、フェリアが質問する（漏らし語が含まれる）
# - プレイヤーは 4 ボタンから返答を選ぶ：HIT 1 + MISS 2 + ピー助任せ
# - HIT（漏らし語をオウム返し → ピー助が「なぜその語？」と解剖）→ 針がフェリア側へ → -50
# - MISS（普通の語彙をオウム返し）→ 針はサトシ側のまま → +5
# - 質問プールはゾーン別（赤 3 件 / 黄・緑 3 件）

const FERIA_PORTRAIT := "res://assets/characters/stage5/feria_001.png"
const FERIA_ICON := "res://assets/ui/speakers/feria_default.png"

const HIT_DELTA := -40
const MISS_DELTA := 5

func _get_config() -> Dictionary:
	return {
		"opponent_id": "feria",
		"opponent_name": "フェリア",
		"opponent_portrait": FERIA_PORTRAIT,
		"opponent_icon": FERIA_ICON,
		"gauge_label": "自白耐性",
		"gauge_max": 130,
		"gauge_start": 100,
		"scripted_backfire": 0,
		"background": "res://assets/backgrounds/stage1/bg07_st1_001.png",
		"rules": [
			"【尋問を投げ返せ】\n心鏡の珠は、範囲内で最も心が動揺する者を追尾する装置。\nフェリアは「私の心は動かぬ」と確信しているが、抑圧した癖が質問の語彙に滲む。\nその漏らした言葉を拾って、彼女に投げ返せ。",
			"【勝敗】\n「自白耐性」を 0 で勝利。\n130 到達でサトシは処刑される。",
		],
		"scripted_intro": {
			"opening": "フェリアは騎士剣を抜き、心鏡の珠を取り出した。\n珠は範囲内で最も動揺する者を追尾する。",
			"satoshi": "は、はい……。",
			"opponent": "",
			"opponent_chunks": [
				"貴殿、王都四傑連破の咎、これより尋問させていただく。",
				"破られた三傑——レイラ、マグダレナ、セレスから聞き取った。\n三人とも、卑怯な手段で屈したと。",
				"正攻法では、異邦人が続けざまに破れる相手ではない。\n対戦前夜の周到な準備があったはず。",
				"ゆえに、貴殿の対戦前夜の行動を直接問う。\n心鏡の珠の前、虚偽は許されぬ。",
				"珠は私を見ぬ——私の心は、動かぬ故。",
			],
			# 特定チャンクの後にサトシの中間反応を挟む（after_chunk は 0-index）
			"satoshi_mid_reaction": {
				"after_chunk": 1,
				"text": "そ、そんな……！\n卑怯だなんて、決してそんなつもりは……！",
			},
			"thought": "スクリーン映像「……怯えた罪人。良い兆候」\n珠の針は、完全にサトシ側に固定されている。",
			"color_change": "",
			"pisuke": "フェリアの質問には、彼女の癖が漏れた語が一つ混じる。\n諜報疑惑なら使わない、妙に具体的な語が目印だ。\n──それを含む選択肢を選べば、心鏡の珠の針が彼女に振れる。",
		},
		"win_narration": "心鏡の珠の針が、完全にフェリア側に固定された。\nフェリアは膝をつき、剣を取り落とす。\n「……ま、まさか、私が……」\n「……も、もう、お許しを……」\n何年も鍛え上げた「絶対に動じぬ心」が、今、崩れ落ちた。",
		"lose_narration": "珠の針はサトシ側に固定されたまま、揺るがなかった。\nフェリアの剣が閃く——\nサトシの首筋に冷たい鋼、視界が暗転。",
		"pisuke_explain_hit": "フェリアの「絶対」が揺らぎ、珠の針が彼女側に振れた。",
		"pisuke_explain_miss": "珠の針は依然サトシ側。動揺の主役は、まだお前だ。",
		"ico_satoshi_normal":     "res://assets/ui/speakers/satoshi_normal.png",
		"ico_satoshi_gentle":     "res://assets/ui/speakers/satoshi_gentle.png",
		"ico_satoshi_nervous":    "res://assets/ui/speakers/satoshi_nervous.png",
		"ico_satoshi_apologetic": "res://assets/ui/speakers/satoshi_apologetic.png",
	}

# --- 質問エントリ構造 ---
# 各エントリ：フェリアの質問 + 漏らし語 + 3 つの選択肢（1 HIT + 2 MISS）
#
# 選択肢のテキスト形式：
#   サトシの台詞は全て「〇〇、ですか…」のオウム返し型
#   HIT のサトシ台詞だけは漏らし語を含む
#   ピー助が続けて「なぜその語？」と解剖攻撃する

# --- 赤ゾーン質問プール（3 件） ---
# 表向き：四傑証言から「対戦前夜の周到な準備」を疑う直接的尋問。
# 漏らし：フェリアの夜の癖の語彙が、質問の中に滲み出る。
const QUESTIONS_RED := [
	{
		"id": "R1",
		"feria": "貴殿、対戦前夜は、寝る前に必ず行う仕度があるのか？",
		"leak": "必ず行う仕度",
		"hit": {
			"label": "必ず行う仕度、ですか…",
			"satoshi": "……必ず行う仕度、ですか……",
			"pisuke_attack": "なぜ「必ず行う仕度」なんですか？\n通常なら「就寝の準備」と聞くはず。\nご自身に毎晩の必須儀がお有りで？",
			"feria_react": "……っ！　な、私の寝る前の仕度など──！",
			"feria_inner": "……「必ず」、なぜ口から……？",
			"pisuke_finish": [
				"──「必ず」と漏れた、その執着、しかと聞きました。",
				"──夜更け、扉を閉めた瞬間、片手は太もも、もう片手で乳房を握り。",
				"──毎晩、シーツに白いのを撒かないと、お眠りになれない、ですよね？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そうだ、対戦前夜の話だ。質問に答えよ。",
				"pisuke_scold": "「対戦前夜」は時期の話だ、針が動かない！\n漏らしは「必ず行う仕度」、なぜ毎晩の必須性を前提にしたかが本丸だ！",
			},
			{
				"label": "寝る前に、ですか…",
				"satoshi": "……寝る前に、ですか……",
				"feria_react": "……そうだ、就寝前の話だ。",
				"pisuke_scold": "「寝る前に」だけなら普通の時間帯だ、針が動かない！\n核心は「必ず行う仕度」、その「必ず」が彼女の漏らしだ！",
			},
			{
				"label": "仕度、ですか…",
				"satoshi": "……仕度、ですか……",
				"feria_react": "……何らかの準備の有無を問うておる。",
				"pisuke_scold": "「仕度」だけじゃ広すぎる！\n「必ず行う」という強迫的な前提こそ、彼女の漏らしだ！",
			},
			{
				"label": "必ず、ですか…",
				"satoshi": "……必ず、ですか……",
				"feria_react": "……そう、必ず行うか否か、を問うておる。",
				"pisuke_scold": "惜しい、サトシ！「必ず」だけじゃ弱い！\n「必ず行う仕度」と全部を投げ返さないと、針は動かない！",
			},
		],
	},
	{
		"id": "R2",
		"feria": "貴殿、対戦前は、身体のどこかを念入りに揉みほぐすのか？",
		"leak": "念入りに揉みほぐす",
		"hit": {
			"label": "念入りに揉みほぐす、ですか…",
			"satoshi": "……念入りに揉みほぐす、ですか……",
			"pisuke_attack": "なぜ「念入りに揉みほぐす」なんですか？\n通常なら「ストレッチ」と聞くはず。\nご自身の動作だから、思いついたんじゃ？",
			"feria_react": "……っ！　わ、私が念入りに揉みほぐすなど──！",
			"feria_inner": "……「念入りに」、なぜ、口から──！",
			"pisuke_finish": [
				"──「念入りに」、何分かけて揉んでらっしゃる？",
				"──太ももの内側、指で割って、奥へ、奥へ、入念に。",
				"──毎晩、自分の手で、自分の体を、念入りに濡らしてる、ですよね？",
			],
		},
		"misses": [
			{
				"label": "対戦前、ですか…",
				"satoshi": "……対戦前、ですか……",
				"feria_react": "……そうだ、対戦前の話だ。",
				"pisuke_scold": "「対戦前」は時期だ、針が動かない！\n漏らしは「念入りに揉みほぐす」、なぜ「念入りに」と強調したかが本丸！",
			},
			{
				"label": "身体のどこか、ですか…",
				"satoshi": "……身体のどこか、ですか……",
				"feria_react": "……身体の部位を問うておる。",
				"pisuke_scold": "「身体のどこか」は曖昧な逃げ道だ！\n核心は「念入りに揉みほぐす」、彼女の動作の癖だ！",
			},
			{
				"label": "揉みほぐす、ですか…",
				"satoshi": "……揉みほぐす、ですか……",
				"feria_react": "……整える動作の有無を問うておる。",
				"pisuke_scold": "「揉みほぐす」だけなら普通のストレッチ語だ！\n「念入りに」という強調こそ、彼女の漏らしだ！",
			},
			{
				"label": "念入りに、ですか…",
				"satoshi": "……念入りに、ですか……",
				"feria_react": "……念を入れるか否か、を問うておる。",
				"pisuke_scold": "惜しい！「念入りに」だけじゃ弱い！\n「念入りに揉みほぐす」と動作まで含めて投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "R3",
		"feria": "貴殿、対戦前夜は、いつもの時刻にいつもの動作を欠かさぬのか？",
		"leak": "いつもの時刻にいつもの動作",
		"hit": {
			"label": "いつもの時刻にいつもの動作、ですか…",
			"satoshi": "……いつもの時刻にいつもの動作、ですか……",
			"pisuke_attack": "なぜ「いつもの時刻」「いつもの動作」と二重限定？\n通常なら「就寝前の習慣」と聞くはず。\nご自身が毎晩欠かさぬから、思いついたんじゃ？",
			"feria_react": "……っ！　わ、私の毎晩の動作など──！",
			"feria_inner": "……「いつもの」、規則性まで……！",
			"pisuke_finish": [
				"──「いつもの時刻」、二十二時の鐘ですよね？",
				"──鐘が鳴ると、体が勝手に。手が太ももへ、迷わず奥へ。",
				"──済ませないと眠れない、そのご自身の指の動き、毎晩、ですよね？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そうだ、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n漏らしは「いつもの時刻にいつもの動作」、規則性の前提が本丸！",
			},
			{
				"label": "欠かさぬ、ですか…",
				"satoshi": "……欠かさぬ、ですか……",
				"feria_react": "……欠かすか否か、を問うておる。",
				"pisuke_scold": "動詞の言い回しに逃げるな！\n核心は「いつもの時刻にいつもの動作」、彼女の規則性の漏らしだ！",
			},
			{
				"label": "時刻、ですか…",
				"satoshi": "……時刻、ですか……",
				"feria_react": "……時間帯を問うておる。",
				"pisuke_scold": "「時刻」だけじゃ弱い！\n「いつもの時刻に」「いつもの動作」の二重特定こそ漏らしだ！",
			},
			{
				"label": "いつもの、ですか…",
				"satoshi": "……いつもの、ですか……",
				"feria_react": "……いつも欠かさぬか否か、を問うておる。",
				"pisuke_scold": "惜しい！「いつもの」だけじゃ片手落ちだ！\n「いつもの時刻に」「いつもの動作」、両方含めて投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "R4",
		"feria": "貴殿、対戦前夜は、寝る前に丁寧に身を清めるのか？",
		"leak": "身を清める",
		"hit": {
			"label": "身を清める、ですか…",
			"satoshi": "……身を清める、ですか……",
			"pisuke_attack": "なぜ「身を清める」なんですか？\n通常なら「入浴」と聞くはず。\n清める儀式をお持ちだから、思いついたんじゃ？",
			"feria_react": "……っ！　わ、私が身を清めるのは、ただの──！",
			"feria_inner": "……「清める」、なぜ、口から……？",
			"pisuke_finish": [
				"──「清める」って、汚した後の話ですよね？",
				"──毎晩、自分で乱れて、シーツに白いのを撒いて、その始末を。",
				"──翌朝の湯桶の底、毎日、何が沈んでらっしゃる？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そうだ、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n核心は「身を清める」、なぜ宗教めいた語を選んだかが本丸だ！",
			},
			{
				"label": "寝る前に、ですか…",
				"satoshi": "……寝る前に、ですか……",
				"feria_react": "……そう、就寝前の話だ。",
				"pisuke_scold": "「寝る前に」は普通の時間帯だ、針が動かない！\n漏らしは「身を清める」、儀式語が彼女の漏らしだ！",
			},
			{
				"label": "丁寧に、ですか…",
				"satoshi": "……丁寧に、ですか……",
				"feria_react": "……念入りか否か、を問うておる。",
				"pisuke_scold": "「丁寧に」だけなら強調語だ、針が動かない！\n核心は「身を清める」、その語の選び方が漏らしだ！",
			},
			{
				"label": "清める、ですか…",
				"satoshi": "……清める、ですか……",
				"feria_react": "……清めるか否か、を問うておる。",
				"pisuke_scold": "惜しい！「清める」だけじゃ弱い！\n「身を清める」と全部投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "R5",
		"feria": "貴殿、対戦前夜は、独り部屋に篭もる時間を持つか？",
		"leak": "独り部屋に篭もる",
		"hit": {
			"label": "独り部屋に篭もる、ですか…",
			"satoshi": "……独り部屋に篭もる、ですか……",
			"pisuke_attack": "なぜ「独り」「篭もる」なんですか？\n通常なら「精神統一の時間など」と聞くはず。\n独り篭もって何かなさってるから、思いついたんじゃ？",
			"feria_react": "……っ！　わ、私が篭もるなど──！",
			"feria_inner": "……「篭もる」、なぜ口から──！",
			"pisuke_finish": [
				"──「篭もって」、扉に鍵までかけて、誰にも見せられない動作。",
				"──ベッドの上、片手は乳房、もう片手は太ももの間、声を殺して。",
				"──部下が呼んでも開けない、その時間、何をしてらっしゃる？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そうだ、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n漏らしは「独り部屋に篭もる」、外界遮断の前提が本丸！",
			},
			{
				"label": "部屋、ですか…",
				"satoshi": "……部屋、ですか……",
				"feria_react": "……場所を問うておる。",
				"pisuke_scold": "「部屋」は普通の語だ、針が動かない！\n核心は「独り」「篭もる」の組み合わせ、彼女の漏らしだ！",
			},
			{
				"label": "時間、ですか…",
				"satoshi": "……時間、ですか……",
				"feria_react": "……時間の有無を問うておる。",
				"pisuke_scold": "「時間」は中立な語だ、針が動かない！\n核心は「独り部屋に篭もる」、外界遮断の語彙が漏らしだ！",
			},
			{
				"label": "独り、ですか…",
				"satoshi": "……独り、ですか……",
				"feria_react": "……単独の有無を問うておる。",
				"pisuke_scold": "惜しい！「独り」だけじゃ弱い！\n「独り部屋に篭もる」と外界遮断まで投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "R6",
		"feria": "貴殿、対戦前夜は、寝具を入念に敷き直してから床に就くのか？",
		"leak": "入念に敷き直す",
		"hit": {
			"label": "入念に敷き直す、ですか…",
			"satoshi": "……入念に敷き直す、ですか……",
			"pisuke_attack": "なぜ「入念に敷き直す」なんですか？\n通常なら「枕の高さなど」と聞くはず。\n入念に敷き直してから何かなさるから、思いついたんじゃ？",
			"feria_react": "……っ！　わ、私が寝具を敷き直すなど──！",
			"feria_inner": "……「入念に」、なぜ口から──！",
			"pisuke_finish": [
				"──「敷き直す」、これから乱す前提ですよね？",
				"──シーツを整え、枕を並べ、自分の指で、自分を乱す準備。",
				"──毎晩、シーツの同じ場所に、白い染みが、ですよね？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そう、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n核心は「入念に敷き直す」、寝具に念を入れる前提が本丸！",
			},
			{
				"label": "寝具、ですか…",
				"satoshi": "……寝具、ですか……",
				"feria_react": "……寝具の話だ。",
				"pisuke_scold": "「寝具」は普通の語だ、針が動かない！\n核心は「入念に敷き直す」、寝具への念入り作業が漏らしだ！",
			},
			{
				"label": "床に就く、ですか…",
				"satoshi": "……床に就く、ですか……",
				"feria_react": "……就寝の有無を問うておる。",
				"pisuke_scold": "「床に就く」は普通の就寝動作だ、針が動かない！\n核心は「入念に敷き直す」、整える動作の前提が漏らしだ！",
			},
			{
				"label": "敷き直す、ですか…",
				"satoshi": "……敷き直す、ですか……",
				"feria_react": "……敷き直すか否か、を問うておる。",
				"pisuke_scold": "惜しい！「敷き直す」だけじゃ弱い！\n「入念に」を含めて投げ返さないと、針が動かない！",
			},
		],
	},
]

# --- 黄・緑ゾーン質問プール（3 件） ---
# 自然な尋問口調を保ちつつ、過剰特定された語が混じる構造。
# ゾーンが進むほどフェリアの質問が、自分の癖を投影した語彙になる。
const QUESTIONS_STRONG := [
	{
		"id": "S1",
		"feria": "……っ、では、別の問いだ。貴殿、対戦前夜、肌に密着させて持ち込む物はあるか？",
		"leak": "肌に密着させて持ち込む",
		"hit": {
			"label": "肌に密着させて持ち込む、ですか…",
			"satoshi": "……肌に密着させて持ち込む、ですか……",
			"pisuke_attack": "なぜ「肌に密着させて」なんですか？\n通常なら「お守りなど」と聞くはず。\n密着の感触をご存知だから、思いついたんじゃ？",
			"feria_react": "……っ！　わ、私が肌に密着させるなど──！",
			"feria_inner": "……「密着」、なぜ口から──！",
			"pisuke_finish": [
				"──「肌に密着」、お守りなら服の上で十分です。",
				"──冷たい金属を、直接、乳首に、太ももの内側に、何度も擦って。",
				"──金属の感触で、自分を昂ぶらせる、毎晩の儀式、ですよね？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そう、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n核心は「肌に密着させて持ち込む」、密着前提の語が本丸だ！",
			},
			{
				"label": "持ち込む、ですか…",
				"satoshi": "……持ち込む、ですか……",
				"feria_react": "……所持の有無を問うておる。",
				"pisuke_scold": "「持ち込む」だけじゃ動作の話だ！\n「肌に密着させて」こそ、彼女の漏らしだ！",
			},
			{
				"label": "物、ですか…",
				"satoshi": "……物、ですか……",
				"feria_react": "……所持物を問うておる。",
				"pisuke_scold": "「物」だけじゃ広すぎる！\n核心は「肌に密着させて」、密着の前提が漏らしだ！",
			},
			{
				"label": "密着、ですか…",
				"satoshi": "……密着、ですか……",
				"feria_react": "……密着させるか否か、を問うておる。",
				"pisuke_scold": "惜しい！「密着」だけじゃ弱い！\n「肌に密着させて持ち込む」と全部投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "S2",
		"feria": "貴殿、対戦前夜、息を整える特別な術を持つのか？",
		"leak": "息を整える特別な術",
		"hit": {
			"label": "息を整える特別な術、ですか…",
			"satoshi": "……息を整える特別な術、ですか……",
			"pisuke_attack": "なぜ「息を整える特別な術」なんですか？\n通常なら「呼吸法など」と聞くはず。\nなぜ「特別」と限定？　ご自身がお持ちだから？",
			"feria_react": "……っ！　わ、私が息を整える術など──！",
			"feria_inner": "……「特別な術」、なぜ口から──！",
			"pisuke_finish": [
				"──「特別な術」って、普通の呼吸じゃないんですよね？",
				"──昂ぶった時の、押し殺した、断続的な、あの呼吸。",
				"──夜分、独り、そういう呼吸を整える状況、説明、要りますか？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そう、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n核心は「息を整える特別な術」、なぜ「特別」と限定したかが本丸！",
			},
			{
				"label": "術、ですか…",
				"satoshi": "……術、ですか……",
				"feria_react": "……何らかの技術の有無を問うておる。",
				"pisuke_scold": "「術」だけじゃ広すぎる！\n「息を整える」「特別な」の二重限定こそ、彼女の漏らしだ！",
			},
			{
				"label": "整える、ですか…",
				"satoshi": "……整える、ですか……",
				"feria_react": "……息を整えるか否か、を問うておる。",
				"pisuke_scold": "動詞だけじゃ意味ない！\n「特別な術」、その「特別」が彼女の漏らしだ！",
			},
			{
				"label": "特別な、ですか…",
				"satoshi": "……特別な、ですか……",
				"feria_react": "……特別な何かがあるか、を問うておる。",
				"pisuke_scold": "惜しい！「特別な」だけじゃ片手落ちだ！\n「息を整える特別な術」と全部投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "S3",
		"feria": "貴殿、対戦前夜、独り深く昂ぶることはないか？",
		"leak": "独り深く昂ぶる",
		"hit": {
			"label": "独り深く昂ぶる、ですか…",
			"satoshi": "……独り深く昂ぶる、ですか……",
			"pisuke_attack": "なぜ「独り」「深く」「昂ぶる」と三重限定？\n通常なら「気合いの入れ方など」と聞くはず。\nご自身が独り昂ぶってらっしゃるから？",
			"feria_react": "……っ！！　わ、私が独り昂ぶるなど──！",
			"feria_inner": "……「独り」「深く」、なぜ口から──！",
			"pisuke_finish": [
				"──「昂ぶる」、対象がないと使わない動詞ですよね？",
				"──独りで、深く、何かを想像して、自分の指で、自分を高めていく。",
				"──毎晩、誰の幻影で、昂ぶってらっしゃる？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そう、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n核心は「独り深く昂ぶる」、その三重特定が本丸だ！",
			},
			{
				"label": "独り、ですか…",
				"satoshi": "……独り、ですか……",
				"feria_react": "……単独の有無を問うておる。",
				"pisuke_scold": "「独り」だけじゃ弱い！\n「独り」「深く」「昂ぶる」の三重特定こそ、彼女の漏らしだ！",
			},
			{
				"label": "昂ぶる、ですか…",
				"satoshi": "……昂ぶる、ですか……",
				"feria_react": "……感情の高ぶりを問うておる。",
				"pisuke_scold": "動詞だけじゃ意味ない！\n「独り」「深く」と組み合わさった「昂ぶる」こそ漏らしだ！",
			},
			{
				"label": "深く、ですか…",
				"satoshi": "……深く、ですか……",
				"feria_react": "……深い高ぶりがあるか、を問うておる。",
				"pisuke_scold": "惜しい！「深く」だけじゃ弱い！\n「独り深く昂ぶる」と全部投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "S4",
		"feria": "貴殿、対戦前夜、寝具の中で身悶えるようなことはないか？",
		"leak": "身悶える",
		"hit": {
			"label": "身悶える、ですか…",
			"satoshi": "……身悶える、ですか……",
			"pisuke_attack": "なぜ「身悶える」なんですか？\n通常なら「寝相など」と聞くはず。\nご自身の動作だから、官能的な響きの語が？",
			"feria_react": "……っ！　わ、私が身悶えるなど──！",
			"feria_inner": "……「身悶える」、なぜ口から──！",
			"pisuke_finish": [
				"──「身悶える」、文字通り、身が悶えるほどの何か。",
				"──シーツを掴み、足を絡め、声を噛み殺し、腰を浮かす。",
				"──寝苦しさじゃ出ない動作ですよね、それ。",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そうだ、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n核心は「身悶える」、なぜ官能的な語を選んだかが本丸！",
			},
			{
				"label": "寝具、ですか…",
				"satoshi": "……寝具、ですか……",
				"feria_react": "……寝具の中での話だ。",
				"pisuke_scold": "「寝具」は普通の語だ、針が動かない！\n核心は「身悶える」、その語の選び方が漏らしだ！",
			},
			{
				"label": "ようなこと、ですか…",
				"satoshi": "……ようなこと、ですか……",
				"feria_react": "……そう、その類のことだ。",
				"pisuke_scold": "「ようなこと」は曖昧で逃げ道だ！\n核心は「身悶える」、彼女の漏らしはそこだ！",
			},
			{
				"label": "悶える、ですか…",
				"satoshi": "……悶える、ですか……",
				"feria_react": "……悶える動作の有無を問うておる。",
				"pisuke_scold": "惜しい！「悶える」だけじゃ弱い！\n「身悶える」と全部投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "S5",
		"feria": "貴殿、対戦前夜、肌を撫でて心を鎮める術はあるか？",
		"leak": "肌を撫でて",
		"hit": {
			"label": "肌を撫でて、ですか…",
			"satoshi": "……肌を撫でて、ですか……",
			"pisuke_attack": "なぜ「肌を撫でて」なんですか？\n通常なら「深呼吸など」と聞くはず。\nご自身の動作だから、思いついたんじゃ？",
			"feria_react": "……っ！　わ、私が肌を撫でるなど──！",
			"feria_inner": "……「撫でる」、なぜ口から──！",
			"pisuke_finish": [
				"──「肌を撫でて」、自分の指で自分の肌を撫でる夜の動作。",
				"──首筋、鎖骨、乳房、お腹、太ももの内側、奥の方まで、ゆっくり。",
				"──撫でて鎮まるはずがない、むしろ昂ぶる、ですよね？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そう、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n核心は「肌を撫でて」、自分の肌に触れる前提が本丸！",
			},
			{
				"label": "心を鎮める、ですか…",
				"satoshi": "……心を鎮める、ですか……",
				"feria_react": "……精神を整えるか否か、を問うておる。",
				"pisuke_scold": "「心を鎮める」は普通の精神修養語だ、針が動かない！\n核心は「肌を撫でて」、その前段の動作が漏らしだ！",
			},
			{
				"label": "術、ですか…",
				"satoshi": "……術、ですか……",
				"feria_react": "……手段の有無を問うておる。",
				"pisuke_scold": "「術」だけじゃ広すぎる！\n核心は「肌を撫でて」、肌への接触が漏らしだ！",
			},
			{
				"label": "撫でる、ですか…",
				"satoshi": "……撫でる、ですか……",
				"feria_react": "……撫でる動作の有無を問うておる。",
				"pisuke_scold": "惜しい！「撫でる」だけじゃ弱い！\n「肌を撫でて」と肌の対象まで投げ返さないと、針が動かない！",
			},
		],
	},
	{
		"id": "S6",
		"feria": "貴殿、対戦前夜、声を漏らさぬよう細心の注意を払うことはないか？",
		"leak": "声を漏らさぬよう",
		"hit": {
			"label": "声を漏らさぬよう、ですか…",
			"satoshi": "……声を漏らさぬよう、ですか……",
			"pisuke_attack": "なぜ「声を漏らさぬよう」なんですか？\n通常なら「不審な囁きなど」と聞くはず。\n漏らしうる声の存在を、ご自身が知ってらっしゃるから？",
			"feria_react": "……っ！　わ、私が漏らしうる声など──！",
			"feria_inner": "……「漏らす」、なぜ口から──！",
			"pisuke_finish": [
				"──「漏らさぬ」、漏れる前提の声があるんですよね？",
				"──押し殺した嬌声、噛んだ唇から漏れる吐息、シーツを掴む指。",
				"──毎晩、誰にも聞かれぬよう、必死に堪えてらっしゃる、ですよね？",
			],
		},
		"misses": [
			{
				"label": "対戦前夜、ですか…",
				"satoshi": "……対戦前夜、ですか……",
				"feria_react": "……そう、対戦前夜の話だ。",
				"pisuke_scold": "「対戦前夜」は時期だ、針が動かない！\n核心は「声を漏らさぬよう」、漏らしうる声の前提が本丸！",
			},
			{
				"label": "細心の注意、ですか…",
				"satoshi": "……細心の注意、ですか……",
				"feria_react": "……注意を払うか否か、を問うておる。",
				"pisuke_scold": "「細心の注意」は形式語だ、針が動かない！\n核心は「声を漏らさぬよう」、その前段が漏らしだ！",
			},
			{
				"label": "払う、ですか…",
				"satoshi": "……払う、ですか……",
				"feria_react": "……注意を払うか否か、を問うておる。",
				"pisuke_scold": "動詞だけじゃ意味ない！\n核心は「声を漏らさぬよう」、彼女の漏らしはそこだ！",
			},
			{
				"label": "漏らさぬ、ですか…",
				"satoshi": "……漏らさぬ、ですか……",
				"feria_react": "……漏らすか否か、を問うておる。",
				"pisuke_scold": "惜しい！「漏らさぬ」だけじゃ弱い！\n「声を漏らさぬよう」と「声」の対象まで投げ返さないと、針が動かない！",
			},
		],
	},
]

# --- 内部状態 ---
var _red_used: Array = []
var _strong_used: Array = []
# 現ターンのアクティブ質問（_pick_current_choices で決定、_apply_choice で参照）
var _active_question: Dictionary = {}

func _get_choice_pool() -> Array:
	# 基底フォールバック用
	return []

func _get_pisuke_lines() -> Array:
	return []

# --- 質問プール参照ヘルパー ---
func _question_pool() -> Array:
	if _get_zone(_gauge) == "red":
		return QUESTIONS_RED
	return QUESTIONS_STRONG

func _question_used() -> Array:
	if _get_zone(_gauge) == "red":
		return _red_used
	return _strong_used

func _set_question_used(arr: Array):
	if _get_zone(_gauge) == "red":
		_red_used = arr
	else:
		_strong_used = arr

# --- 選択肢ピック（オーバーライド）---
# 1 ターン = 1 質問。質問ごとに HIT 1 + MISS 2 + ピー助任せ = 4 ボタン。
func _pick_current_choices():
	var pool: Array = _question_pool()
	var used: Array = _question_used()
	if used.size() >= pool.size():
		used.clear()
		_set_question_used(used)

	var avail: Array = []
	for i in range(pool.size()):
		if not used.has(i):
			avail.append(i)
	avail.shuffle()
	var qidx: int = avail[0]
	used.append(qidx)
	_set_question_used(used)

	_active_question = pool[qidx]

	# 選択肢構成：HIT 1 + MISS 3（ランダム抽出）+ ピー助任せ 1 = 5 ボタン
	_current_choices.clear()

	var hit_choice: Dictionary = {
		"label": _active_question.hit.get("label", "（HIT）"),
		"pool_type": "hit",
	}
	_current_choices.append(hit_choice)

	# MISS は定義 4 件から 3 件をランダム抽出（リプレイ性確保）
	var miss_indices: Array = []
	for i in range(_active_question.misses.size()):
		miss_indices.append(i)
	miss_indices.shuffle()
	var miss_pick_count: int = min(3, miss_indices.size())
	for i in range(miss_pick_count):
		var miss: Dictionary = _active_question.misses[miss_indices[i]]
		var miss_choice: Dictionary = {
			"label": miss.get("label", "（MISS）"),
			"pool_type": "miss",
			"miss_data": miss,
		}
		_current_choices.append(miss_choice)

	_current_choices.shuffle()

	_current_choices.append({"label": "ピー助に任せる", "is_pisuke": true, "locked": false})

# --- 選択肢適用（オーバーライド）---
func _apply_choice(bt, idx: int):
	var choice: Dictionary = _current_choices[idx]
	if choice.get("is_pisuke", false):
		await _apply_pisuke(bt)
		return

	var ptype: String = choice.get("pool_type", "")
	if ptype == "hit":
		await _play_hit_lines(bt, _active_question)
	else:
		var miss_data: Dictionary = choice.get("miss_data", {})
		await _play_miss_lines(bt, miss_data)

# --- ピー助任せ（オーバーライド）---
# 現ターンの質問の HIT 選択肢を自動発動。
func _apply_pisuke(bt):
	var cfg := _get_config()
	var ico_nervous: String = cfg.get("ico_satoshi_nervous", "res://assets/ui/speakers/satoshi_nervous.png")

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\n（……どう返せば──）", "satoshi", ico_nervous)
	await bt.wait(0.0)
	bt.narrator_band("ピー助（小声）:\n……これだ。「%s」、これを彼女に向け直せ。" % _active_question.get("leak", ""), "pisuke")
	await bt.wait(0.0)

	await _play_hit_lines(bt, _active_question)

# --- HIT フロー：質問オウム返し → ピー助の解剖攻撃 → フェリア反論 → 内心の動揺 → ピー助の物証畳みかけ ---
func _play_hit_lines(bt, q: Dictionary):
	var cfg := _get_config()
	var satoshi_ico: String = cfg.get("ico_satoshi_gentle", "res://assets/ui/speakers/satoshi_gentle.png")
	var opp_ico: String = cfg.get("opponent_icon", "")
	var opp_id: String = cfg.get("opponent_id", "feria")
	var hit: Dictionary = q.get("hit", {})

	# サトシの台詞はオウム返しの一言だけ
	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\n%s" % hit.get("satoshi", "……"), "satoshi", satoshi_ico)
	await bt.wait(0.0)

	# ピー助の解剖攻撃（サトシに被せて）
	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("ピー助（被せて、フェリアへ）:\n%s" % hit.get("pisuke_attack", ""), "pisuke")
	await bt.wait(0.0)

	# フェリアの反論
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n%s" % [get_opponent_name(), hit.get("feria_react", "")], opp_id, opp_ico)
	await bt.wait(0.0)

	# 心鏡の珠の針が振れる演出
	await _narrate_wait(bt, "【心鏡の珠】針が、ぐらりとフェリア側へ振れる。")

	# フェリア内心の動揺
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s（小声で、自分自身に）:\n%s" % [get_opponent_name(), hit.get("feria_inner", "")], opp_id, opp_ico)
	await bt.wait(0.0)

	# ピー助の言葉の追撃（1 行 1 バブルで「畳みかけ」感を出す）
	var finish: Variant = hit.get("pisuke_finish", "")
	var finish_lines: PackedStringArray = []
	if finish is Array or finish is PackedStringArray:
		for line in finish:
			finish_lines.append(line)
	else:
		# 旧フォーマット互換：\n 区切りの文字列
		finish_lines = String(finish).split("\n")
	for i in range(finish_lines.size()):
		var prefix: String = "ピー助（畳みかけて）:" if i == 0 else "ピー助:"
		bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
		bt.narrator_band("%s\n%s" % [prefix, finish_lines[i]], "pisuke")
		await bt.wait(0.0)

	# フェリアの屈服反応
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n……っ！ ……そ、それは──！" % get_opponent_name(), opp_id, opp_ico)
	await bt.wait(0.0)

	# ナレーション
	var summary: String = cfg.get("pisuke_explain_hit", "")
	await _narrate_wait(bt, "尋問装置が、尋問者を裏切った瞬間。\n%s" % summary)

	await _apply_gauge_change(bt, HIT_DELTA, false)
	_turns_in_current_zone += 1

# --- MISS フロー：普通語をオウム返し → フェリア平然 → ピー助の叱責 ---
func _play_miss_lines(bt, miss: Dictionary):
	var cfg := _get_config()
	var satoshi_ico: String = cfg.get("ico_satoshi_apologetic", "res://assets/ui/speakers/satoshi_apologetic.png")
	var opp_ico: String = cfg.get("opponent_icon", "")
	var opp_id: String = cfg.get("opponent_id", "feria")

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("サトシ:\n%s" % miss.get("satoshi", "……"), "satoshi", satoshi_ico)
	await bt.wait(0.0)

	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n%s" % [get_opponent_name(), miss.get("feria_react", "")], opp_id, opp_ico)
	await bt.wait(0.0)

	await _narrate_wait(bt, "【心鏡の珠】針は、ぴくりとも動かない。サトシ側にロックされたまま。")

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("ピー助（小声で叱責）:\n%s" % miss.get("pisuke_scold", ""), "pisuke")
	await bt.wait(0.0)

	var summary: String = cfg.get("pisuke_explain_miss", "")
	await _narrate_wait(bt, "珠の照準は、依然サトシ側。\n%s" % summary)

	await _apply_gauge_change(bt, MISS_DELTA, false)
	_turns_in_current_zone += 1

# --- ゾーン遷移演出（前進・後退の両方） ---
func _on_zone_changed(bt, new_zone: String):
	if new_zone == "yellow":
		await _narrate_wait(bt, "フェリアの剣の握りが、わずかに緩む。\n珠の針が、ふらつき始めた。")
		bt.set_bubble_side("bottom-left")
		bt.narrator_band("ピー助:\nゲージの色、変わったぞ。\nここからフェリアの質問は、もっと際どい語彙になってくる。\nその分、漏らしも露骨だ。容赦なく、投げ返せ。", "pisuke")
		await bt.wait(0.0)
	elif new_zone == "red":
		await _narrate_wait(bt, "フェリアが剣の柄を握り直し、自己統制を取り戻す。\n珠の針が、再びサトシ側にロックされる。")
		bt.set_bubble_side("bottom-left")
		bt.narrator_band("ピー助:\n針が戻った。フェリアが平静を取り戻したぞ。\n質問の語彙も、無難な方向に戻る。慎重に漏らしを聞き取れ。", "pisuke")
		await bt.wait(0.0)

# --- minigame() 上書き：質問表示を選択肢前に挿入 + 勝利時の物証カットイン挿入 ---
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

	# scripted_intro 直後はボタン非表示。各ターン、質問が出た後にボタンが現れる流れ。
	_set_buttons_visible(false)
	_set_buttons_enabled(false)

	var gauge_max: int = cfg.get("gauge_max", 130)
	while _gauge > 0 and _gauge < gauge_max:
		_pick_current_choices()
		_refresh_choice_buttons()
		_update_gauge_display()

		# まず質問を表示（ボタン非表示のまま）
		_set_buttons_visible(false)
		_set_buttons_enabled(false)
		await _display_question(bt)

		# 質問クリック後に選択肢ボタンを表示・有効化
		_set_buttons_visible(true)
		_set_buttons_enabled(true)
		_choice_selected = -1
		var idx: int = await _choice_emitted
		_set_buttons_enabled(false)
		_set_buttons_visible(false)
		await _apply_choice(bt, idx)
		_update_gauge_display()

	_teardown_ui()

	if _gauge <= 0:
		await _play_pre_collected_evidence(bt)
		await _narrate_wait(bt, cfg.get("win_narration", "儀式は成功した。"))
		return "win"
	else:
		await _narrate_wait(bt, cfg.get("lose_narration", "儀式は失敗した。"))
		return "lose"

# --- scripted_intro 上書き：固定逆効果なし + opponent をチャンク表示 ---
# 順序：opening → 相手の発言 → サトシの応答 → 心の声 → ピー助の指示
func _play_scripted_intro(bt):
	var cfg := _get_config()
	var intro: Dictionary = cfg.get("scripted_intro", {})
	var ico_apologetic: String = cfg.get("ico_satoshi_apologetic", "res://assets/ui/speakers/satoshi_apologetic.png")
	var opp_ico: String = cfg.get("opponent_icon", "")
	var opp_id: String = cfg.get("opponent_id", "feria")

	await _narrate_wait(bt, intro.get("opening", ""))

	# フェリアの宣言を opponent_chunks（あればチャンク表示）または opponent（単一）で表示
	# 特定チャンク後にサトシの中間反応を挿入（satoshi_mid_reaction で指定）
	var chunks: Array = intro.get("opponent_chunks", [])
	if chunks.is_empty():
		var fallback: String = intro.get("opponent", "")
		if not fallback.is_empty():
			chunks = [fallback]
	var mid_reaction: Dictionary = intro.get("satoshi_mid_reaction", {})
	var mid_after: int = int(mid_reaction.get("after_chunk", -1))
	var mid_text: String = mid_reaction.get("text", "")
	for i in range(chunks.size()):
		bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
		bt.narrator_band("%s:\n%s" % [get_opponent_name(), chunks[i]], opp_id, opp_ico)
		await bt.wait(0.0)
		# 指定チャンク直後にサトシの中間反応を挟む
		if i == mid_after and not mid_text.is_empty():
			bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
			bt.narrator_band("サトシ:\n%s" % mid_text, "satoshi", ico_apologetic)
			await bt.wait(0.0)

	# サトシの最終応答（フェリアの尋問を受けて緊張気味に）
	var sat_text: String = intro.get("satoshi", "")
	if not sat_text.is_empty():
		bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
		bt.narrator_band("サトシ:\n%s" % sat_text, "satoshi", ico_apologetic)
		await bt.wait(0.0)

	var thought: String = intro.get("thought", "")
	if not thought.is_empty():
		await _narrate_wait(bt, thought)

	# 固定逆効果（_apply_gauge_change(scripted_backfire)）はスキップ。color_change も空なら出さない。
	var color_change: String = intro.get("color_change", "")
	if not color_change.is_empty():
		await _narrate_wait(bt, color_change)

	bt.set_bubble_side(BUBBLE_SIDE_PISUKE)
	bt.narrator_band("ピー助（小声）:\n%s" % intro.get("pisuke", ""), "pisuke")
	await bt.wait(0.0)

# --- 各ターンの質問表示 ---
func _display_question(bt):
	var cfg := _get_config()
	var opp_id: String = cfg.get("opponent_id", "feria")
	var opp_ico: String = cfg.get("opponent_icon", "")
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n%s" % [get_opponent_name(), _active_question.get("feria", "……")], opp_id, opp_ico)
	await bt.wait(0.0)

# --- 事前収集物証 3 枚の畳みかけ（勝利時の最終演出） ---
# ピー助が事前に手に入れていた手帳・影絵・音声を順に提示し、フェリアを完全に屈服させる。
func _play_pre_collected_evidence(bt):
	var cfg := _get_config()
	var opp_id: String = cfg.get("opponent_id", "feria")
	var opp_ico: String = cfg.get("opponent_icon", "")

	await _narrate_wait(bt, "心鏡の珠の針が、完全にフェリア側に固定された。針は揺るがない。\n……だが、ピー助の追い打ちは、まだ終わらぬ。")

	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("ピー助:\n騎士団長様、最後にお見せしたい物がございます。\n実は事前に、三つ、手に入れておりまして。", "pisuke")
	await bt.wait(0.0)

	# 物証 1：手帳
	await _narrate_wait(bt, "【UI 演出】サトシの携帯端末から、手帳の写しが投影される。")
	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("ピー助:\n一つ目——騎士団長様の手帳の一頁。\n「明日の鍛錬予定」の下に、小さく「いつもの時刻、忘れず」と。\n──「いつもの時刻」とは、何時の、何の予定で？", "pisuke")
	await bt.wait(0.0)
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n……っ！　そ、それは、どこで、それを……！" % get_opponent_name(), opp_id, opp_ico)
	await bt.wait(0.0)

	# 物証 2：影絵
	await _narrate_wait(bt, "【UI 演出】影絵魔導具の動画が再生される。寝具の上、影が規則的に上下する。")
	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("ピー助:\n二つ目——影絵魔導具で記録した、騎士団長室の寝室の動作。\n寝具の上の影、規則的に上下する片手の動き、二十分継続。\n──手の動き、なんとなく規則的で。何を握ってらっしゃるんで？", "pisuke")
	await bt.wait(0.0)
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n……ぅ、そ、それは、武具の手入れを──！\n夜間の、鍛錬の、ひとつで……！" % get_opponent_name(), opp_id, opp_ico)
	await bt.wait(0.0)

	# 物証 3：音声
	await _narrate_wait(bt, "【UI 演出】録声魔導具が起動。乱れた呼吸音と、抑制された高音がループ再生される。")
	bt.set_bubble_side(BUBBLE_SIDE_SATOSHI)
	bt.narrator_band("ピー助:\n三つ目——録声魔導具による音声記録。\n「……ぁ……っ……」「……騎士、さま……」\n──ご自分の声、お聞き分けになれますね？\n武具の手入れで、こんな呼吸になりますかね？", "pisuke")
	await bt.wait(0.0)
	bt.set_bubble_side(BUBBLE_SIDE_OPPONENT)
	bt.narrator_band("%s:\n……っ！！ ……ぁ、ぁぁ……！\nもう、お許しを、お許しください……！" % get_opponent_name(), opp_id, opp_ico)
	await bt.wait(0.0)

	await _narrate_wait(bt, "心鏡の珠の判定、フェリア側に完全に固定されている。\n事前収集の三物証が、彼女の「絶対」を、跡形もなく粉砕した。")

# --- UI 上書き：5ボタン構成（HIT 1 + MISS 3 + ピー助任せ 1） ---
# 基底の 5 ボタン枠をそのまま使う。
const VISIBLE_BUTTON_COUNT := 5

# ボタンを縮小して、画面下部の DialogueBand（拡張後 320px）と重ならないようにする。
# 5ボタン × 48高さ + 4セパレータ × 8 = 272px → コンテナ280px → y=120 から y=400 で終わる
func _build_ui(bt: Node):
	super._build_ui(bt)
	for btn in _choice_buttons:
		btn.custom_minimum_size = Vector2(420, 48)
	if _ui_root != null:
		for child in _ui_root.get_children():
			if child is VBoxContainer:
				var vbox: VBoxContainer = child
				vbox.size = Vector2(420, 280)
				vbox.add_theme_constant_override("separation", 8)
				break
