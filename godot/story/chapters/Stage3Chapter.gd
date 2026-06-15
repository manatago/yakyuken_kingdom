extends RefCounted
class_name Stage3Chapter

# Stage3: マグダレナ編（教会嫌がらせ → 教会乗り込み → 初戦敗北 → ミニゲーム → 再戦勝利）
# 詳細シナリオ: docs/scenarios/stage3_scenario.txt

const BG_INN := "res://assets/backgrounds/stage3/bg_inn_exterior.png"
const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const BG_CHURCH := "res://assets/backgrounds/subevent2/bg02_church_interior.png"
const BG_RESTING := "res://assets/backgrounds/stage2/bg_guild_resting.png"
const BG_CATHEDRAL := "res://assets/backgrounds/stage3/bg_cathedral_night.png"

const HERO_WEAK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_004.png"
const HERO_PUZZLE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_006.png"
const HERO_IRRITATE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png"
const HERO_SHOCK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"
const HERO_AWKWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_067.png"
const HERO_TIRED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_014.png"
const HERO_GLOOM := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_033.png"
const HERO_PROTEST := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_016.png"
const HERO_DESPAIR := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_070.png"
const HERO_RESOLVE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_088.png"
const HERO_GLARE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png"
const HERO_NERVOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_091.png"
const HERO_DAZED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_028.png"
const HERO_DISTANT := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_083.png"
const HERO_GUILTY := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_013.png"
const HERO_RELIEF := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_015.png"
const HERO_COLD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_012.png"

const RECEP_NORMAL := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_005.png"
const RECEP_JIT := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png"
const RECEP_COLD := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_007.png"
const RECEP_BUSINESS := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_006.png"
const MAGDALENA := "res://assets/characters/main/magdalena/clothed/magdalena_clothed_001.png"
const ORPHAN := "res://assets/characters/mob/orphan/default/orphan_default_001.png"
const CHURCH_FOLLOWER := "res://assets/characters/mob/church_follower/default/church_follower_default_001.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "stage3_harass", "builder": "_build_stage3_harass"},
		{"id": "stage3_challenge", "builder": "_build_stage3_challenge"},
		{"id": "stage3_recover", "builder": "_build_stage3_recover"},
		{"id": "stage3_post", "builder": "_build_stage3_post"},
	]

# =========================================================
# 場面1-2: 嫌がらせフェーズ・ギルドでの冷徹
# =========================================================
func _build_stage3_harass(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var orphan = b.character("orphan")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage3_harass")
	b.background(BG_INN, 0.5)
	b.show_band()

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_WEAK, "portrait_scale": 0.53, "flip": 1, "position": [0, 70],
	})

	b.narrator_band("「神はあなたを見ておられます。悔い改めの時は近づいております。」\n「聖アレクシア教会 北方管区大司祭 マグダレナ」")

	hero.set_portrait(HERO_TIRED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("毎日、毎日、同じ文面で...。")

	b.narrator_band("宿主が申し訳なさそうに視線を逸らす。\n「サトシさん、近所から『教会から睨まれてる男を泊めてる宿』って噂が立ち始めて、他のお客が逃げてるんです。今月末までに、出ていってもらえないかと...。」")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("えっ、うちを...！ 宿、追い出されるんですか...。")

	pisuke.band("ゲコッ。嫌がらせ、じわじわ効いてきてるな。", {"side": "left"})

	hero.set_portrait(HERO_DISTANT, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...他にも、最近、市場の店主に買い物を断られたり、ギルドの\n他の冒険者が距離を取ったり、子どもにすれ違いざまに囁かれたり...。")

	orphan.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": ORPHAN, "portrait_scale": 0.5, "position": [0, 150],
	})
	orphan.band("あの人だよ、教会の聖女様を辱めた人...。\n近づかないほうがいいって、神父さんが。", {"side": "right"})

	orphan.leave({"exit_effect": "fade", "exit_duration": 0.3})

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（...子どもまで、言い含められてる。）")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面2: ギルド
	b.background(BG_GUILD, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})

	receptionist.band("サトシ様。...本日もご来訪、ありがとうございます。")

	hero.set_portrait(HERO_WEAK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、受付嬢さん、お戻りになってたんですね...。\nあの、折り入って、ご相談、いいですか...。")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("...教会からの件、ですね。")

	hero.band("は、はい...最近、毎日、手紙は届くし、市街では白い目で見られるし、\n宿は追い出されるし...。")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("...サトシ様。\n...ギルドに届いている苦情文書、本日時点で、五十七通でございます。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("五十七...！？")

	receptionist.band("...全て、聖アレクシア教会関連の信徒、あるいは教会の影響下にある\n商会、あるいは孤児院からの、正式な苦情でございます。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("そ、それって、ちょっと、組織ぐるみじゃないですか！？\n俺、何も悪いこと、してないのに！")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("...さようでございますか。")

	receptionist.band("...サトシ様のこれまでの素行記録を、改めて、確認いたします。")

	b.narrator_band("...召喚直後、王都中央広場に全裸で出現。\n...盗賊団討伐時、アジトにて下着の展示品に対し異常な鑑賞時間あり。\n...先日、教会の覗き部屋への侵入、現行犯三度目。\n...先日、ギルド職員に対する下心凝視の嫌疑、並びに盗難事件の証拠隠滅容疑、継続調査中。\n...同件の暗部検証にて、アサシンとの密室接触の末、相手方を「深く恨ませる形」で勝利。")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("...教会様が警戒なさるのは、極めて妥当な措置と、私は判断いたします。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("そ、それ、全部、誤解が積み重なってて...！")

	receptionist.band("記録に残っているものが、事実でございます。")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("...ギルドから、サトシ様を庇護する特別措置は、差し上げられません。\n...宿の件、市街の件、各自でご対応願います。")

	hero.set_portrait(HERO_WEAK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("そ、そんな、受付嬢さん、ちょっとは味方してくれても...！")

	receptionist.band("...一つだけ、業務上の助言を差し上げます。")

	receptionist.band("...このまま放置すれば、教会側から「正式な異端審問」の申し立てが\n来る可能性が高うございます。\n異端審問は、ギルドでは止められません。\n...何らかの決着を、ご自身で、つけられるのが、よろしいかと。")

	pisuke.band("ゲコッ。...これ、受付嬢、暗に「教会に勝負挑んでこい」と言ってるぞ。", {"side": "left"})

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（...結局、自分で片付けろってこと、か...。）")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})
	receptionist.leave({"exit_effect": "fade", "exit_duration": 0.3})

# =========================================================
# 場面3+4: 教会乗り込み → 初戦（固定敗北）
# =========================================================
func _build_stage3_challenge(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var magdalena = b.character("magdalena")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage3_challenge")
	b.background(BG_CHURCH, 0.5)
	b.show_band()

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_RESOLVE, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	magdalena.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": MAGDALENA, "portrait_scale": 0.5, "position": [0, 10],
	})

	magdalena.band("...よくおいでくださいました、サトシ様。\nお呼びだてすることなく、自ら来てくださるとは。\n神のお導き、でしょうか。")

	hero.set_portrait(HERO_GLARE, {"scale": 0.74, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...マグダレナ様。単刀直入に伺います。最近の、毎日の手紙、\n市街での扱い、宿の件、孤児の子どもたちへの言い含め、\n...全部、あなたの指示ですよね。")

	magdalena.band("...サトシ様。私は、ただ、信徒の皆様に神のお心を伝えているだけで\nございます。")

	hero.band("...それは、嫌がらせです。")

	magdalena.band("...嫌がらせ、ですか。ふふ。\n...妹の審議が、サトシ様のご尽力で、聖職剥奪という形で終わった件、\n私は、異を唱えたりはいたしません。\n...神のご意志、でしょうから。")

	magdalena.band("...ただ、私の心は、神のご意志ほど、広くはないのです。")

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...野球拳で、決着をつけたい。俺が勝ったら、嫌がらせを全部止めて\nほしい。負けたら...。")

	magdalena.band("...負けたら、いかがいたします？")

	hero.set_portrait(HERO_PUZZLE, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...えっと、何か、罰、ですか、ね...？")

	magdalena.band("...それは、こちらからご指定させていただきます。\nサトシ様が敗れた場合、...王都から、出ていっていただきます。\n...二度と、お戻りにならないでください。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("お、追放...！？")

	magdalena.band("...ご安心を。\n教会の慈悲の掟に従い、追放の執行は、勝負から三日後といたします。\n...その三日の間、サトシ様には、一度のみ、再戦の権利を、\n神の御名において、お授けいたします。")

	hero.set_portrait(HERO_PUZZLE, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("慈悲、として...？")

	magdalena.band("...そうでございます。\n「敗者にも、もう一度、神に祈る機会を」。これは、聖アレクシア教会の、\n古くからの作法にございます。")

	pisuke.band("ゲコッ。...本音は「再戦でも負けさせて、追放を確定させたい」だろ。\n聖女の顔を崩したくないから、慈悲の体裁を整えてるだけだ。", {"side": "left"})

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（ピー助、黙って...！）")

	magdalena.band("...では、神の御前で、野球拳を、ご用意いたします。\n今すぐ、こちらで、神の御前で執り行いましょう。\n...再戦をご希望の場合は、本日以降、執行日までの間に、\nお申し込みください。同じく、教会にて、お受けいたします。")

	# 初戦準備の祈祷
	magdalena.band("神よ、この勝負が真実を照らす一助となりますように。")
	magdalena.band("神よ、聖職者特権として、「信仰の光」の使用、\nお許しくださいませ。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（信仰の光...！？ なんだ、それ...）")

	pisuke.band("ゲコッ...聞いたことのねぇスキルだ。\nチップで解析するが、初見の効果は読み切れねぇ。\n...サトシ、警戒しろ。", {"side": "left"})

	b.hide_band()
	b.label("stage3_battle1_start")
	# 初戦（固定敗北）
	b.battle("res://battle/chapters/Stage3BattleChapter.gd")
	b.label("stage3_battle1_done")

# =========================================================
# 場面5+6+7: 作戦会議 → 深夜侵入 → 懺悔室ミニゲーム → 再戦
# =========================================================
func _build_stage3_recover(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var magdalena = b.character("magdalena")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage3_recover")
	b.background(BG_RESTING, 0.5)
	b.show_band()

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_DESPAIR, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	hero.band("...ダメだ。信仰の光、何も見えない。手探りじゃ、絶対勝てない。")

	pisuke.band("まあ、そうだな。\n...が、ヒントが一つある。", {"side": "left"})

	hero.set_portrait(HERO_RELIEF, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ヒント？")

	pisuke.band("戦闘中、信仰の光を発動する度に、マグダレナの脳内活動が、\n異常に「特定の場所」を想起してた。\n祈祷の動作をしているのに、祭壇ではなく、\n「自室の床板」のデータが、脳内で光ってた。", {"side": "left"})

	hero.set_portrait(HERO_PUZZLE, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("自室の床板...？ 何かある、ってことか？")

	pisuke.band("可能性が高い。彼女にとって「一番守りたい場所」だ。\n...今夜、教会に潜り込んで、確認するぞ。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("えっ、教会に不法侵入！？ 俺、そんなの、嫌だよ！ 神罰が怖い！")

	pisuke.band("他にどうやって勝つんだ。正攻法じゃ信仰の光は破れない。\nあと、神罰は俺様のハックでは観測されてねえ。安心しろ。", {"side": "left"})

	hero.set_portrait(HERO_IRRITATE, {"scale": 0.74, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...それで、何を確認したら、どう勝つんだ？")

	pisuke.band("ゲコッ。それは、俺様に任せろ。\nお前は、今夜、現物を見つけて持ち帰るだけ、考えてろ。", {"side": "left"})

	hero.band("神罰を「観測」する話じゃない...！")

	pisuke.band("じゃあ、追放されるか。王都、出てくか？", {"side": "left"})

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...行く。行きますよ！")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面6: 深夜の教会侵入
	b.background(BG_CATHEDRAL, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NERVOUS, "portrait_scale": 0.53, "flip": 1, "position": [0, 70],
	})

	hero.band("（俺、どうしてこうなった...。）")

	pisuke.band("扉の電子錠、処理した。自室、奥だ。", {"side": "left"})

	b.narrator_band("マグダレナの自室。\n床板の下、魔力反応の隠蔽処理済み。明らかに何かある。")

	b.narrator_band("サトシ、床板を剥がす。隠し箱（鍵付き）→ ピー助のチップ処理で開錠。\n箱の中身：大量の書籍・手書き原稿・スケッチブック。")

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、本が...たくさん...？")

	pisuke.band("ゲコッ。全部 BL 本だ。しかも、過半数が本人の自作だ。", {"side": "left"})

	hero.set_portrait(HERO_DISTANT, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...俺、今、教会の大司祭の自作 BL を、夜中に、読んでる...。\n人生の最底辺を、また更新した。")

	pisuke.band("本、原稿、染みの目立つ書きかけ、全部スキャン済み。\nあとは現物を 1 冊だけ持ち出して、残りは元通りに戻す。\n潜入の痕跡もチップ経由で完全消去する。", {"side": "left"})

	pisuke.band("...これだけあれば、十分だ。\n明日、俺様の指示通りに動け。それで終わる。", {"side": "left"})

	hero.band("指示って、明日、何するんだよ...？")

	pisuke.band("...黙ってついてこい。今は、それだけだ。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面7: 教会で再戦申請＋懺悔室ミニゲーム
	b.background(BG_CHURCH, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NERVOUS, "portrait_scale": 0.53, "flip": 1, "position": [0, 70],
	})
	magdalena.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": MAGDALENA, "portrait_scale": 0.5, "position": [0, 10],
	})

	hero.band("ピー助、これから、何するんだ...？", {"side": "left"})
	pisuke.band("黙ってろ、サトシ。", {"side": "left"})

	hero.band("シスター・マグダレナ様。\n...本日、再戦の権利は、辞退いたします。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（え、辞退！？ 俺の声で、勝手に...！）")

	magdalena.band("...ほう。降伏、ということでしょうか。")

	hero.band("いえ、その前に、どうしても、お願いしたく。\n...これまでの数々の非礼、心から、悔い改めたいのです。\n懺悔の儀を、お受けいただけないでしょうか。\n聖書を、ご一緒に、朗読させていただければと。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（懺悔！？ ピー助、お前、何させる気だ...！）")

	magdalena.band("...まあ。\n罪人の魂の浄化は、聖職者の務めにございます。\n喜んで、お受けいたしましょう。\nどうぞ、こちらへ。懺悔室にて、お聞きしましょう。")

	b.hide_band()
	b.label("stage3_minigame_start")
	# ミニゲーム（書棚で妄想を誘発せよ）
	b.minigame("res://battle/chapters/Stage3MinigameChapter.gd")

	# ミニゲーム成功後、再戦
	b.set_flag("stage3_first_battle_done")
	b.show_band()
	b.label("stage3_battle2_start")
	b.battle("res://battle/chapters/Stage3BattleChapter.gd")
	b.label("stage3_battle2_done")

# =========================================================
# 場面8+9: 決着後の恨み・ギルド帰還
# =========================================================
func _build_stage3_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var magdalena = b.character("magdalena")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage3_post")
	b.background(BG_CHURCH, 0.5)
	b.show_band()

	magdalena.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": MAGDALENA, "portrait_scale": 0.5, "position": [0, 10],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_GUILTY, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	magdalena.band("...完敗、です。本の返却、嫌がらせの停止、承諾いたします。")

	hero.band("...マグダレナ様。お辛かったとは思いますが、どうか、お気を落とさず...。\n神様も、いつかきっと、お赦しくださいますから。")

	magdalena.band("...サトシ様。本日の、あなたのお言葉、\n...一生、忘れません。")

	magdalena.band("神は赦しを説きますが、私の心が、あなたを赦す日は、来ません。")

	magdalena.band("...私の祈りの中で、あなたの名は、生涯「許されぬ者」として、\n神に、捧げられ続けます。")

	magdalena.leave({"exit_effect": "fade", "exit_duration": 0.6, "exit_to": "right", "wait_for_exit": true})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	pisuke.band("ゲコッ。...お前、聖職者の生涯の祈念対象になったぞ。大したもんだ。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面9: ギルド帰還
	b.background(BG_GUILD, 0.5)
	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	receptionist.band("サトシ様。...教会からの全ての苦情、本日付で、正式取り下げの\n通達がございました。")

	hero.set_portrait(HERO_RELIEF, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、はい。ありがとうございます。宿主にも、もう追い出されずに\n済みそうです。")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("...なお、ギルドの記録に、本件を追記いたします。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、追記って、何を...。")

	receptionist.band("...「サトシ、深夜の教会に不法侵入し、大司祭の私室より書籍を\n持ち出した容疑あり。大司祭は告発をしていないが、行為の性質は、\n記録上、残す」と。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("告発してないのに、記録するんですか！？")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.45, "side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("...業務上の、必要措置でございます。")

	receptionist.band("...サトシ様の「要監視対象A」ランク、本件をもって、据え置きと\nいたします。\n...下がる要素は、ございませんので。")

	pisuke.band("ゲコッ。...受付嬢、相変わらずの冷徹ぶりだな。", {"side": "left"})

	hero.set_portrait(HERO_DISTANT, {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("俺、味方が一人もいないの、いつから定着したんだっけ...。")

	b.set_flag("stage3_complete")
