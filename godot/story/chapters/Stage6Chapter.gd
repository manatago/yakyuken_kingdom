extends RefCounted
class_name Stage6Chapter

# Stage6: 王女アレクシア編（晩餐会 → 四天王嘲笑 → 第一勝負必敗 → 最悪マナー → 通常バトル勝利）
# 詳細シナリオ: docs/scenarios/stage6_scenario.txt

const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const BG_HALL := "res://assets/backgrounds/stage6/bg_royal_hall.png"
const BG_SIDE := "res://assets/backgrounds/stage6/bg_side_room.png"

const HERO_NORMAL := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_001.png"
const HERO_SHOCK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"
const HERO_PANIC := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_016.png"
const HERO_AWKWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_067.png"
const HERO_NERVOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_091.png"
const HERO_DESPAIR := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_018.png"
const HERO_RESOLVE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_088.png"
const HERO_SERIOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_011.png"
const HERO_COLD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_012.png"
const HERO_DISTANT := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_083.png"
const HERO_DAZED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_028.png"
const HERO_HOPE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_015.png"
const HERO_TIRED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_087.png"

const RECEP_COLD := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_007.png"
const RECEP_BUSINESS := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_006.png"
const RECEP_JIT := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png"
const PRINCESS := "res://assets/characters/main/princess/clothed/princess_clothed_001.png"
const FERIA := "res://assets/characters/main/feria/clothed/feria_clothed_001.png"
const MAGDALENA := "res://assets/characters/main/magdalena/clothed/magdalena_clothed_001.png"
const SELES := "res://assets/characters/main/seles/clothed/seles_clothed_001.png"
const LAYLA := "res://assets/characters/main/layla/clothed/layla_clothed_001.png"
const NOBLE := "res://assets/characters/mob/noble/default/noble_default_001.png"
const CHAMBERLAIN := "res://assets/characters/mob/chamberlain/default/chamberlain_default_001.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "stage6_pre", "builder": "_build_stage6_pre"},
		{"id": "stage6_banquet", "builder": "_build_stage6_banquet"},
		{"id": "stage6_recover", "builder": "_build_stage6_recover"},
		{"id": "stage6_post", "builder": "_build_stage6_post"},
	]

# =========================================================
# 場面1: 招待状
# =========================================================
func _build_stage6_pre(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage6_pre")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NORMAL, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	receptionist.band("サトシ様。...王宮より、直々の召喚状が届いております。\n発行者は、王女アレクシア殿下ご自身の署名入りでございます。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("はあ！？ 王女、本人から！？\n...俺、殿下に何か、ご無礼でも...！？")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...名目は「王都四傑連破の功労を労う、宮中晩餐会ご招待」。\n...非公式の行事として記載がございますが、ご出席は実質義務化されて\nおります。")

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("晩餐会！？ 俺、そんな高貴な場、行ったこと、ないですよ！\nマナーとか、全然分からないですし...！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...ご健闘を、とは、申し上げません。\n...ただ、不敬罪だけは、避けていただきますよう。")

	hero.band("そんなのに、行くの俺、絶対嫌なんですけど...！")

	receptionist.band("...拒否は、不敬罪でございます。")

	pisuke.band("ゲコッ。...まあ、ただの「労い」で、王宮が異邦の冒険者を呼ぶか？\n何か裏が、あるかもしれねえな。気を付けろ。", {"side": "left"})

# =========================================================
# 場面2+3+3.5+4: 晩餐会→マナー詰め→挑戦→第一勝負必敗
# =========================================================
func _build_stage6_banquet(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var princess = b.character("princess")
	var feria = b.character("feria")
	var magdalena = b.character("magdalena")
	var seles = b.character("seles")
	var layla = b.character("layla")
	var noble = b.character("noble")
	var chamberlain = b.character("chamberlain")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage6_banquet")
	b.background(BG_HALL, 0.5)
	b.show_band()

	princess.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": PRINCESS, "portrait_scale": 0.5, "position": [0, 0],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_PANIC, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("（...え、え、え、え！？）")

	b.narrator_band("室内の顔ぶれ：王女アレクシアの上座。脇に騎士団長フェリア、侍従長。\n貴族たちの席。宮中魔術師席にはセレス、祈祷係としてマグダレナ、給仕にはレイラ。\n——倒してきた4人、全員。")

	pisuke.band("ゲコッ。...サトシ、察した通りだ。\nあの4人、全員、王女の腹心だ。\n俺様、ずっと感づいてたが、言わなかった。今、全員、お前を迎えるために、\n揃ってる。", {"side": "left"})

	hero.set_portrait(HERO_NERVOUS, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（ピー助、それ、もっと早く言えよ！）")

	pisuke.band("言っても、何か変わったか？\n...それに、王女本人が動いてくるのは、今日が、初めてだ。\nこれまでは、四人がそれぞれの事情で動いてた。\n...今日は、王女が、まとめて、後処理に来てる。", {"side": "left"})

	princess.band("...サトシ様、ようこそお越しくださいました。\nどうぞ、末席に、お進みください。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、は、はい、失礼、いたします...。")

	# 場面2.5: マナー詰め
	princess.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})

	layla.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": LAYLA, "portrait_scale": 0.5, "position": [0, 100],
	})
	layla.band("...サトシ様。冷製のスープでございます。\n...また、お会いいたしましたね。\n...前回の屈辱、忘れては、おりません。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（レイラさん、地獄の挨拶...！）")
	layla.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})


	noble.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": NOBLE, "portrait_scale": 0.5, "position": [0, 100],
	})
	noble.band("おや、サトシ殿。そのスプーンの動かし方は、異邦の流儀ですかな？\n王宮では、もう少し、音を立てないのが作法でございますが。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、す、すみません、気をつけます...。")

	layla.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})
	noble.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})



	seles.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": SELES, "portrait_scale": 0.5, "position": [0, -100],
	})
	seles.band("...お口の動き、実に、研究対象として興味深い所作でございますね。\n咀嚼の回数、通常比で1.4倍。音の発生頻度、通常比で2.8倍。\n...論文に、残させていただきます。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（論文に！？ 今、俺の食事、研究対象にされてる！？）")

	noble.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})
	seles.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})



	magdalena.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": MAGDALENA, "portrait_scale": 0.5, "position": [0, -100],
	})
	magdalena.band("神は、全ての所作を、ご覧でございます。\n...異邦の方の、素朴なお食事も、きっと、お慈悲深く、御覧に\nなっておられるでしょう。")

	hero.set_portrait(HERO_DISTANT, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（神経由の悪口！ 神経由の悪口！）")

	noble.band("...ところで、サトシ殿。王都の四傑を、連破されたそうですな。\n...さぞ、卑怯な戦法を、ご使用に、なられたので？")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（これ、完全に、総攻撃だ。\n王女が動くまでもなく、周りが全部、俺を潰しにかかってる。）")

	pisuke.band("ゲコッ。サトシ、耐えろ。王女の「本命」は、まだ来てねえ。\n...食事を乗り切って、デザートまで生きろ。", {"side": "left"})

	# 場面3: デザート後・追い込み→挑戦
	noble.band("...殿下。お集まりの皆様。\n...本日の晩餐、私、深く、感じ入る所がございました。\n...異邦の冒険者サトシ殿の所作、口の動き、フォークの持ち方、視線、\n...いずれも、王宮の品格に、まったくそぐわぬ水準でございました。")

	seles.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})
	magdalena.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})



	feria.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": FERIA, "portrait_scale": 0.5, "position": [0, 0],
	})
	feria.band("...殿下。本件、騎士団としても、何らかの正式な処分を、必要と\n認めます。")

	princess.band("（穏やかな微笑のまま、何も言わない）")

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ま、待ってください！\n...俺、あの、何もかも、そんな処分されるようなこと、してません！")

	noble.band("...では、サトシ殿。何をもって、ご自身の正当性を、証明されますか？")

	hero.band("や、野球拳！ 野球拳で、勝負させてください！\n俺が勝ったら、処分はなし！\n負けたら、王都地下牢、何でも受けます！")

	princess.band("（扇を、ゆっくり、広げる）\n...サトシ様。ご自身から、お申し出になられた、と。\n...良いでしょう。この、私が、お相手いたします。")

	princess.band("...潔白か、王都地下牢か。条件、了承いたしました。")

	# 古法引用（ピー助操作）
	hero.set_portrait(HERO_COLD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...お待ちください、殿下。")

	hero.band("...王国古法、第二百四十七条、『王女と異邦人との野球拳による決着\nにおいては、王位継承権もまた、賭けの対象に含みうる』という、\n条項がございます。\n\n...加えまして、同条第二項。\n「王位継承権を賭けた戦いは、四回勝負とし、挑戦者が一度でも\n勝利した場合、これを挑戦者の勝者とみなす」。\n...古の、王族の慈悲を示す規定でございます。")

	feria.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})


	chamberlain.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": CHAMBERLAIN, "portrait_scale": 0.5, "position": [0, 100],
	})
	chamberlain.band("（慌てて古文書を確認）\n...確かに、ございます。第一項・第二項、ともに。\n...ただし、数百年前の、事実上、死文化した条項でございますが。")

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（ピー助、何、引っ張り出してんの！？ そんなの、俺、知らない！）")

	pisuke.band("ゲコッ。いいか、サトシ、本気で耳を貸せ。\nこいつら、お前を潔白で解放する気は最初からない。\n地下牢送りを、確実に、狙ってる。...ならば、こっちも賭け金を\n釣り上げて、王女の言質を縛るしかねえ。", {"side": "left"})

	hero.set_portrait(HERO_COLD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...敗者側の処分も、王位に見合う形に引き上げて、構いません。\n...殿下の格式を考えれば、王位と王都地下牢では、釣り合いが\n取れませぬ。")

	princess.band("（扇の奥で、一瞬、目を細める）\n...興味深いご提案でございますね。\n...王位を賭けるのであれば、敗者の行き先も、相応に。")

	noble.band("...殿下、であれば、北の最果ての、極寒の牢獄は、いかがでしょう。\n...入った者は、二度と、生きては出られぬ、と言われる、あの地。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ちょ、ちょっと、待って！ 二度と出られない！？")

	pisuke.band("黙ってろ。ここから、引けねえ。", {"side": "left"})

	princess.band("...では、よろしいでしょうか。\n私が勝てば、サトシ様を北の最果ての極寒の牢獄へ。\nサトシ様が勝たれた場合は、王位を、譲らせていただきます。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（え、ええええええ、賭けが、どんどん、でかくなってる...！）")

	# 場面3.5+4: ルール宣言→第一勝負（勅令で必敗）
	princess.band("...ルールは、先ほど貴殿が引用なさった王国古法・第二百四十七条・\n第二項に、則ります。\n\n四回の「勝負」。各勝負は通常の三本先取。\nそして、四回の勝負のうち、挑戦者が一度でも勝負に勝てば、挑戦者の勝者\nとみなします。")

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、4つの勝負のうち、1つ、取るだけで、いいんですか！？")

	princess.band("...古の王族が、異邦の挑戦者に示した「慈悲」でございます。")

	princess.band("...ただし、私は、王族の秘技を、自由に発動いたします。\n\n第一勝負は、王族の慣習として、「勅令」を、事前に、予告させて\nいただきます。\n...私が「勝ち」と宣せば、その勝負の三本すべて、あなたに敗北して\nいただく判定が下ります。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（勅令、出た...！ 第一勝負の3本、全部、必敗...！）")

	princess.band("...残り三つの勝負は、通常勝負。ただし、必要に応じて、王家奥義\n「絶対王政」を、発動する場合があります。\n...この奥義が発動している間、勝敗は、王家側に固定されます。")

	hero.set_portrait(HERO_SERIOUS, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（...要するに、第一勝負の3本は確定敗北、残り3つの勝負の内、\n1つでも3本先取で勝てば、勝ち、と...！）")

	pisuke.band("ゲコッ。サトシ、第一勝負は、諦めろ。データ収集だ。\n...勝負は、二戦目の勝負から、本番だ。", {"side": "left"})

	# 場面4: 第一勝負（勅令で3本全敗）
	princess.band("第一勝負。...勅令、発動。")

	b.hide_band()
	b.label("stage6_battle1_start")
	# 第一勝負（固定敗北）
	b.battle("res://battle/chapters/Stage6BattleChapter.gd")
	b.label("stage6_battle1_done")

# =========================================================
# 場面4.5+5+6: 控えの間→覚悟→最悪マナー発動→秘技封じ
# =========================================================
func _build_stage6_recover(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var princess = b.character("princess")
	var feria = b.character("feria")
	var chamberlain = b.character("chamberlain")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage6_recover")
	b.background(BG_SIDE, 0.5)
	b.show_band()

	chamberlain.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": CHAMBERLAIN, "portrait_scale": 0.5, "position": [0, 0],
	})
	chamberlain.band("...古法の定めにより、次戦まで、短き休憩を取らせていただきます。")
	chamberlain.leave({"exit_effect": "fade", "exit_duration": 0.3})

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("ピー助、勅令、予告通り、第一勝負で3本必敗。...あと3つの勝負、\n1つでも3本先取で勝てば、勝ち、だよね。\nベイズ・アイ、生きてる。普通に挑めば、なんとか...。")

	pisuke.band("...サトシ、正直に言う。\n王女は、素の腕前でも、お前の手に余る。\nしかも、残りのどこかで、確実に絶対王政を出してくる。\n...このまま普通に挑んでも、ほぼ、詰みだ。", {"side": "left"})

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("じゃ、じゃあ、どうすれば...！？")

	pisuke.band("...次元の違う手を、ここで、仕込む。\n戦闘中、王女のデータを、少しだけ、読めた。\n...性に関する情報の免疫が、ゼロ。\n箱入りで育って、そっち系の刺激は、完全に未知だ。", {"side": "left"})

	hero.set_portrait(HERO_NERVOUS, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...で？")

	pisuke.band("お前の急所を、強制的に王女に触らせれば、認知限界突破で、\n勅令も絶対王政も、以後、封じられる。\n...他の章と、同じパターンだ。相手の弱点を突いて、秘技を封じて、\n通常のジャンケン勝負に持ち込む。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ええええええ！？ 晩餐会の場で、全員見てるんだぞ！？")

	pisuke.band("だから、覚悟が要る。この世界に来てからの性的記憶、全部\n総動員。最悪のマナーで、王女の結界も、王家の秘技も、全部\n剥がせ。そうすれば、あと3つの勝負のうち、1つで3本先取、取れる\n公算が出る。", {"side": "left"})

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（召喚直後の全裸転移、マチルダ戦の勝利の余韻、ベルカのコレクション、\n聖女マグダレナの法衣が揺れた瞬間、アサシンの純情、\nセレスの新性癖、フェリアの秘密、そして今しがたの晩餐会の屈辱――）\n（全て、今日のための、助走だった。）")

	pisuke.band("ゲコッ、サトシ。最悪のマナーを撃つには、最悪の屈辱の記憶を、\n全部、引きずり出せ。\n...一つでも揺らげば、終わりだ。", {"side": "left"})

	hero.band("（...行く。俺は、今日、宮中マナーの歴史を、粉砕する。）")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面6: 大広間中央・最悪マナー発動
	b.background(BG_HALL, 0.5)
	princess.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": PRINCESS, "portrait_scale": 0.5, "position": [0, 0],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_RESOLVE, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("...殿下。第二勝負の前に、一つ、お許しください。")

	princess.band("？")

	hero.band("先ほど、皆様より、私のマナーに、多くのご指摘を頂戴いたしました。\n「異邦の所作は、宮中の格式に合わない」と。\n\n...つきましては、本日、異邦の最高位の礼法をもって、\nお応えいたします。")

	b.narrator_band("大広間、ざわめき。\n貴族「異邦の、最高位の、礼法...？」")

	hero.band("殿下、失礼、いたします。")

	b.narrator_band("サトシ、自らの礼装の裾に手をかけ、ゆっくりと持ち上げる。")

	princess.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})


	feria.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.3,
		"portrait": FERIA, "portrait_scale": 0.5, "position": [200, 100],
	})
	feria.band("！ な、何をする、サトシぃ！")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（ミニゲームで性的記憶を総動員したせいで、ここに来て、俺、不覚に\nも、準備万端状態に、なっちゃってる！ いや、違う、これ、違う、\n違うって、今、違う、違う違う違う！）")

	pisuke.band("...サトシ、お前、その状態で王女に触らせる気か...。", {"side": "left"})

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（俺の意志と関係なく！ 体が！ 性癖記憶を総動員した副作用で！）")

	b.narrator_band("サトシは王女の手を取った。手が震える。")

	hero.band("殿下、ご容赦を。これは、王国と、殿下のご威光を、傷つけないための、\nやむを得ない、異邦の「儀礼」でございます！")

	b.narrator_band("王女の手がサトシの急所に一瞬触れる。")

	princess.band("（硬直）\n...。\n......。\n............え？\n...この、柔らかくも、かたく、あり得ないほど、熱を持った、\n...え？")

	pisuke.band("...認知リソース、100%占有どころか、200%オーバー。\n最悪のマナー＋意図しない勃起、のダブル衝撃で、王女の秘技系統、\n全部、永久封印レベルで、剥がれた。", {"side": "left"})

	princess.band("...こ、これは、いったい...。\n...何、なのですか、...おかしな、感情が、頭に、...。")

	b.narrator_band("王女、ふらりと倒れ込む。意識が朦朧。フェリアが咄嗟に支えた。")

	feria.band("殿下ぁぁぁぁぁ！")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（...俺、やった、やっちまった！ 勃起まで、された...！\n一生、消えない、やつ、これ！）")

	pisuke.band("サトシ、勅令・絶対王政・王族結界、以後すべて使用不能。\n...残り3戦、普通のジャンケン勝負だ。ベイズ・アイ、全開で、行け。", {"side": "left"})

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（ありがとう、ピー助、助かった、でも、代償、でか過ぎる...！）")

# =========================================================
# 場面7: 第二〜第四勝負（通常バトル・勝利）
# =========================================================
func _build_stage6_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var princess = b.character("princess")
	var chamberlain = b.character("chamberlain")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage6_post")
	b.background(BG_HALL, 0.5)
	b.show_band()

	princess.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": PRINCESS, "portrait_scale": 0.5, "position": [0, 0],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_SERIOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	princess.band("（意識を半分取り戻しつつ、扇で顔を覆う）\n...では、第二勝負、開始、いたします。")

	pisuke.band("サトシ、王女は完全に動揺状態だ。勅令も絶対王政も、もう出ない。\nベイズ・アイ、全開で読める。\n...どれか一つの勝負で、3本先取すれば、勝ちだ。", {"side": "left"})

	b.set_flag("stage6_first_battle_done")
	b.hide_band()
	b.label("stage6_battle2_start")
	# 通常バトル（再戦勝利）
	b.battle("res://battle/chapters/Stage6BattleChapter.gd")
	b.label("stage6_battle2_done")

	# 勝利演出
	b.show_band()
	princess.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})

	chamberlain.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": CHAMBERLAIN, "portrait_scale": 0.5, "position": [200, 100],
	})
	chamberlain.band("（震える声で）\n...勝者、冒険者サトシ殿。\n古法に則り、本試合の勝利者でございます。")

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...勝った...。本当に、勝ったのか...。")

	pisuke.band("ゲコッ。サトシ、お前、王位継承権、ゲットしたぞ。", {"side": "left"})

	b.set_flag("stage6_complete")
