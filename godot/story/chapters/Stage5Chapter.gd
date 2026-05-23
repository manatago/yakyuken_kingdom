extends RefCounted
class_name Stage5Chapter

# Stage5: フェリア編（出頭命令 → 取調 → 決闘敗北 → 潜入 → ミニゲーム → 再戦勝利 → 招待状）
# 詳細シナリオ: docs/scenarios/stage5_scenario.txt

const BG_STREET := "res://assets/backgrounds/stage5/bg_royal_street.png"
const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const BG_INTERR := "res://assets/backgrounds/stage5/bg_interrogation_room.png"
const BG_TRAIN := "res://assets/backgrounds/stage5/bg_training_ground.png"
const BG_RESTING := "res://assets/backgrounds/stage2/bg_guild_resting.png"
const BG_CORRIDOR := "res://assets/backgrounds/stage5/bg_royal_corridor_night.png"
const BG_OUTER := "res://assets/backgrounds/stage5/bg_outer_wall_night.png"
const BG_EVENING := "res://assets/backgrounds/stage5/bg_back_street_evening.png"

const HERO_NORMAL := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_001.png"
const HERO_PUZZLE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_006.png"
const HERO_DREAD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_064.png"
const HERO_SHOCK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"
const HERO_PROTEST := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_016.png"
const HERO_AWKWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_067.png"
const HERO_TIRED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_087.png"
const HERO_NERVOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_091.png"
const HERO_SERIOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_011.png"
const HERO_RESOLVE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_088.png"
const HERO_DESPAIR := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_018.png"
const HERO_HOPE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_015.png"
const HERO_COLD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_012.png"
const HERO_DAZED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_028.png"
const HERO_DISTANT := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_083.png"
const HERO_PANIC := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"

const RECEP_NORMAL := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_005.png"
const RECEP_BUSINESS := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_006.png"
const RECEP_JIT := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png"
const RECEP_COLD := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_007.png"
const FERIA := "res://assets/characters/main/feria/clothed/feria_clothed_001.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "stage5_summon", "builder": "_build_stage5_summon"},
		{"id": "stage5_interrogation", "builder": "_build_stage5_interrogation"},
		{"id": "stage5_recover", "builder": "_build_stage5_recover"},
		{"id": "stage5_post", "builder": "_build_stage5_post"},
		{"id": "stage5_close", "builder": "_build_stage5_close"},
	]

# =========================================================
# 場面1+2: 出頭命令 → 受付嬢のしぶしぶ助言
# =========================================================
func _build_stage5_summon(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage5_summon")
	b.background(BG_STREET, 0.5)
	b.show_band()

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NORMAL, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("（何だ、この噂...？ 俺、王女殿下、会ったこともないぞ...？）")

	pisuke.band("ゲコッ。連勝中のお前の名を、殿下が侍女の前で一言でも漏らせば、\n翌日には尾鰭が付く。貴族社会ってのは、そういう場所だ。", {"side": "left"})

	b.narrator_band("騎士団使者がサトシの行く手を遮った。\n「冒険者サトシ殿。王都騎士団本部・第三部の使者でございます。」")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（げっ、騎士団の人...！）は、はい、サトシです。")

	b.narrator_band("「貴殿宛てに、公式書面を持参いたしました。」\n出頭命令——「王女殿下の御身辺に関する、複数の不審事案」について事情聴取。明朝、日の出とともに本部へ出頭。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("えっ、俺、殿下と、関わった覚えないですよ！？")

	b.narrator_band("「...詳細は、本部にて。それまでは王都を離れぬよう。」\n一礼して立ち去る使者の後ろ姿。")

	pisuke.band("動いたな、フェリア。噂を深読みして、捜査の体裁で呼び出してきた。\n「事情聴取」の拒否は公務執行妨害。逃げ場はねえ。\n...明朝までに、準備しろ。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面2: ギルド
	b.background(BG_GUILD, 0.5)
	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_PANIC, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("受付嬢さん！ お願い、お願いします、助けてください！\n俺、騎士団に呼び出されて、何にも分からなくて！\n何でもいいです、何か、何かアドバイスだけでも！")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...サトシ様。当ギルドに、王都騎士団の案件への庇護権は、ございません。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("いや、庇護じゃなくていいんです！ ほんのちょっとの、助言で！\n受付嬢さん、色んな冒険者、見てきてますよね！ ね！？")

	receptionist.band("...。")

	hero.band("土下座でも、なんでも、します！")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("（長い沈黙）\n...お立ちください。他のお客様のご迷惑です。")

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("立つから、教えてください！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("（深いため息）\n...あくまで、ギルドの一般業務の範囲内で、一つだけ、申し上げます。")

	receptionist.band("取り調べでは、何を聞かれても、「分かりません」「覚えていません」\nで通すのが、最も安全でございます。\n下手に弁解すると、その言葉自体が、新たな容疑の材料になります。")

	hero.set_portrait(HERO_PUZZLE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...でも、なんで、そんなに「言うな」を強調するんですか？")

	receptionist.band("...騎士団の取り調べには、心鏡の珠が用いられます。\n範囲内で、最も心が動揺する者を、自動で追尾する装置でございます。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("しん...きょうの、たま...？")

	receptionist.band("あの装置を扱えるのは、絶対の感情統制を持つ者のみ。\nすなわち、騎士団長フェリア様、ただお一人にございます。\n...サトシ様は、ただ一方的に、動揺を読まれる側です。\nですから、余計なことは言わない。これが鉄則でございます。")

	pisuke.band("...サトシ、この助言、珍しく、マジで有益だぞ。\n心鏡の珠か...扱える人間が限られるってことは、何か抜け道がありそうだな。\n...俺様の方で、ちょっと調べておく。", {"side": "left"})

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...以上です。ご健闘を、とは申し上げません。\n...生還を、お祈り申し上げます。")

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("「生還」って単語で送り出さないでください！")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})
	receptionist.leave({"exit_effect": "fade", "exit_duration": 0.3})

# =========================================================
# 場面3+4: 心鏡の珠取調 → 決闘提案 → 初戦（固定敗北）
# =========================================================
func _build_stage5_interrogation(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var feria = b.character("feria")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage5_interrogation")
	b.background(BG_INTERR, 0.5)
	b.show_band()

	feria.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": FERIA, "portrait_scale": 0.5, "position": [0, 10],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NERVOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	feria.band("...ようこそ、冒険者サトシ殿。\n本日は、特殊取調具「心鏡の珠」を使用いたします。")

	feria.band("対象者の心の動揺を、色で可視化する魔道具。平静なら無色透明、\n動揺すると、赤く染まります。")

	pisuke.band("嘘発見器じゃねえ、動揺検知器だ。潔白でも、質問の内容次第で、\n誰でも真っ赤になる類のやつだぞ。", {"side": "left"})

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、それ、俺、超不利じゃ...！")

	feria.band("Q1。貴殿は、王女殿下のお名前を、ご存知ですか？")

	b.narrator_band("珠がかすかに赤く染まる。")

	feria.band("...珠が反応。知識ではない、特別な感情が込もっている、と。")

	feria.band("Q2。夜分、王宮北門付近を、徘徊したことは？")

	b.narrator_band("珠、更に濃い赤に染まる。")

	feria.band("...二つ目。")

	feria.band("Q3。王女殿下の御姿を、夢に見たことは？")

	b.narrator_band("珠、くっきり赤。")

	feria.band("...三つ目。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("違います！ 今の、質問で反応しただけで！")

	feria.band("Q4。王女殿下の、お召し物の下について、想像は？")

	b.narrator_band("珠、真っ赤。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（完全に、質問内容だけで誰でも動揺するやつ！）")

	feria.band("Q5。王女殿下の、ご入浴の御姿について、想像は？")

	b.narrator_band("珠、深紅で脈打つ。")

	feria.band("...五つ目。これ以上、続ける必要はございませんね。")

	feria.band("珠、五連続で深紅。\n「王女殿下に対する、異常に強い、個人的な関心及び想像」の物証です。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あなたの質問が誰でも動揺する内容だから！")

	feria.band("...動揺するということは、触れられたくない何かがある、という\n証左でございます。")

	pisuke.band("否定しても「だからこそ怪しい」で丸め込まれるパターンだ。詰んでる。", {"side": "left"})

	feria.band("...嫌疑、確定。処罰は王都地下牢・無期拘留。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("む、無期！？")

	pisuke.band("サトシ、ここで何か出さないと終わりだぞ！", {"side": "left"})

	hero.band("ま、待って、ください！ や、野球拳で、決着、させてください！\n俺、勝ったら、疑い、全部撤回で！ 負けたら、処罰、受けます！")

	feria.band("...ほう。貴殿の方から、望まれる、と。")

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("はい、お願いします！")

	feria.band("...承知いたしました。敗者の処罰は、私の裁量にて決めます。")

	pisuke.band("これ、勝手に拘留期間決められるぞ。無期どころか、もっと酷くもあり得る。", {"side": "left"})

	feria.band("...ただちに、中央訓練場にて執り行います。お立ちなさい。")

	feria.leave({"exit_effect": "fade", "exit_duration": 0.4})
	hero.leave({"exit_effect": "fade", "exit_duration": 0.4, "wait_for_exit": true})

	# 場面4: 訓練場・決闘
	b.background(BG_TRAIN, 0.5)
	feria.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": FERIA, "portrait_scale": 0.5, "position": [0, 10],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NERVOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	feria.band("では、始めましょう。ルールは三本勝負。")

	pisuke.band("サトシ、このフェリア、目の奥が異様に個人的だ。幼なじみとしての\n嫉妬と独占欲が混じってる。...覚えておけ。", {"side": "left"})

	feria.band("始めよう。")

	b.hide_band()
	b.label("stage5_battle1_start")
	# 初戦（固定敗北・プラチナ加護）
	b.battle("res://battle/chapters/Stage5BattleChapter.gd")
	b.label("stage5_battle1_done")

# =========================================================
# 場面5+6+7+8+9: 罪上乗せ→再戦権獲得→潜入→ミニゲーム→再戦勝利
# =========================================================
func _build_stage5_recover(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var feria = b.character("feria")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage5_recover")
	b.background(BG_TRAIN, 0.5)
	b.show_band()

	feria.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": FERIA, "portrait_scale": 0.5, "position": [0, 10],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_DESPAIR, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	feria.band("...貴様の敗北により、取り調べで確定した嫌疑に加え、決闘での敗北\n自体を、「王家への反逆行為の実証」として、上乗せします。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、罪、更に増えた！？")

	feria.band("よって、処罰は王都地下牢・無期拘留。\n裁量権は、先ほど貴殿自身が、同意されたもの。")

	pisuke.band("...サトシ、黙れ。ここは、俺様が、お前の声で喋る。", {"side": "left"})

	hero.set_portrait(HERO_COLD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("騎士団長殿下。一つだけ、お尋ねします。")

	hero.band("この処罰、殿下は、望んでおられますか？")

	feria.band("...何を、申しておる。")

	hero.band("殿下のご確認もなく、独断で無期拘留を執行なさって。\nもし殿下が「そこまでは望まなかった」と仰られたら。\n...騎士団長殿下のお立場は、どうなります？")

	feria.band("...。")

	hero.band("...三日の再戦権だけ、お認めください。\n結果が出てから、殿下にご報告なされる方が、安全でございます。")

	feria.band("（長い沈黙）\n...よかろう。\n...三日の再戦権を、与える。次は、貴様に一切の加減をせぬ。\n三日後、ここに戻ってくるがよい。")

	feria.leave({"exit_effect": "fade", "exit_duration": 0.5})
	hero.leave({"exit_effect": "fade", "exit_duration": 0.4, "wait_for_exit": true})

	# 場面5: ギルド・潜入計画
	b.background(BG_RESTING, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("ピー助、今の、助かった...けど、三日後、また負けたら無期拘留だよ？")

	pisuke.band("だから、三日間で、プラチナカードを一枚、奪う。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、盗む！？")

	pisuke.band("プラチナ三種は、三つ揃って初めて「完全加護」が発動する。\n一枚でも欠ければ、全体の加護が崩れるってのが、神器の性質だ。\n...勝負の前に、一枚抜いておけば、フェリアの優位は消える。", {"side": "left"})

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...完全に詰みの条件で、単独潜入で、窃盗、か...。")

	pisuke.band("ゲコッ。...足音を、殺せ。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面6: 王宮潜入
	b.background(BG_CORRIDOR, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NERVOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	pisuke.band("魔力スキャン。...プラチナカード三枚の反応、ベッドルーム側だ。", {"side": "left"})

	hero.band("え、ベッドルーム！？")

	pisuke.band("...神器は、本人が肌身離さず、寝所にまで持ち込んでる。\n枕元の台座に、三枚並べて置いてやがる。", {"side": "left"})

	pisuke.band("...いや、待て。ベッドルームから、音がする。", {"side": "left"})

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、寝言？")

	pisuke.band("...違う。サトシ、これ以上詳しく言わせるな。悟ってくれ。", {"side": "left"})

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...もしかして、ストレス解消の、独り寝の時間、ってやつ...？")

	pisuke.band("当たりだ。\n...ただ、台座がベッドのすぐ横。手を伸ばせば、フェリアの視界に入る\n距離。今、カード盗むのは、自殺行為だ。\n...撤退だ。深追いすれば、お前が捕まる。", {"side": "left"})

	b.narrator_band("サトシは歯噛みしながら撤退する。ピー助は密かにサトシの網膜へ音声・影絵・魔力波形をキャプチャした（サトシは気付かない）。")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面6.5: 撤退後・路上
	b.background(BG_OUTER, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_DESPAIR, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("...カード、結局、一枚も盗めなかった。...ピー助、再戦、勝ち目、\nあるのかよ...。")

	pisuke.band("...方法は、考える。任せろ。", {"side": "left"})

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("任せろ、って、何も取れてないじゃないか！")

	pisuke.band("...ゲコッ。とにかく、一旦、引け。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面7+8: ブリーフィング → ミニゲーム
	b.background(BG_TRAIN, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_SERIOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("ピー助、本当に、勝ち目、あるのかよ...。")

	pisuke.band("...ある。今回の決め手は、彼女の「心鏡の珠」だ。\n仕掛けはこうだ。\n心鏡の珠は「最も動揺している心」を自動で追尾する。\nこれを利用する。彼女自身の鼓動を珠に追尾させて、\nプラチナ加護を「自分の動揺」に向けさせる。", {"side": "left"})

	hero.band("...動揺、させるって、どうやって...？")

	pisuke.band("尋問は彼女からだ。が、彼女自身の質問の中に、\n「漏らし語」が混じる。本人は無自覚で漏らしてくる。\n日常では言わない、彼女の毎晩の儀式から漏れた語彙だ。\n\nお前は、その漏らし語を選択肢から拾って、彼女に投げ返せ。\n俺様が直後に「なぜそんな語を選んだ？」と被せる。\n彼女の心が動揺すれば、心鏡の珠は彼女自身を追尾し、\nプラチナ加護は使えなくなる。", {"side": "left"})

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...なるほど、わかった。やるしかないか。")

	b.hide_band()
	b.label("stage5_minigame_start")
	b.minigame("res://battle/chapters/Stage5MinigameChapter.gd")

	# ミニゲーム成功後、再戦
	b.set_flag("stage5_first_battle_done")
	b.show_band()
	b.label("stage5_battle2_start")
	b.battle("res://battle/chapters/Stage5BattleChapter.gd")
	b.label("stage5_battle2_done")

# =========================================================
# 場面9+9.5: 決着後・卑怯者のノゾキ魔
# =========================================================
func _build_stage5_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var feria = b.character("feria")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage5_post")
	b.background(BG_TRAIN, 0.5)
	b.show_band()

	feria.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": FERIA, "portrait_scale": 0.5, "position": [0, 10],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_SERIOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("団長、約束は、守りました。")

	b.narrator_band("ピー助経由でフェリアの目前に全データ消去ログが提示された。")

	feria.band("...消えた、のだな。")

	b.narrator_band("（長い沈黙。フェリアが立ち上がる。顔は怒り。）")

	feria.band("...サトシ。貴様ぁ...！\n...卑怯者の、ノゾキ魔が...！")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（えっ！？）")

	feria.band("...私の意趣返しが混じっていたのは、認める。\n...だが、私室への侵入、神器窃盗の企て、覗きの記録、指向性投影で\n本人だけに突きつけるという貴様の応じ方は、窃盗、覗き、脅迫の\n三連コンボ。武人の道から最も遠い所業だ。")

	hero.set_portrait(HERO_COLD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...騎士団長殿下。失礼ながら、一言。\nバトル界隈では、「卑怯者」は、褒め言葉でございます。\n知略、詭計、奇襲。これ全部、凡百の戦士にゃ真似できない高等戦術。\n戦術書にも「卑怯を極めた者が、真の勝者」と、明記されております。\n...私、ありがたく、頂戴いたします。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（ピー助、やめろ、やめろ、やめろ、今、さらに怒らせてる！）")

	feria.band("（奥歯が砕けるほど噛む。それ以上、声が出ない。）\n...貴様の顔を、見せるな。出ていけ。")

	feria.leave({"exit_effect": "fade", "exit_duration": 0.5})
	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面9.5: 退場後の路上
	b.background(BG_EVENING, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("ピー助、お前、最後のアレ、何で俺の口で返したんだよ！\n「卑怯は褒め言葉です」って、本人の前で言うか、普通！？")

	pisuke.band("ゲコッ。黙って罵倒されっぱなしは、俺様の矜持に反する。", {"side": "left"})

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("お前の矜持のために、俺、顔、覚えられたんですけど！？\n...ていうか、「卑怯」の方はフォローしたけど、「ノゾキ魔」の方は、\nどうすんだよ？")

	pisuke.band("...いや、そっちは、普通に悪口だな。", {"side": "left"})

	hero.band("半分しかフォローしてねえじゃねえか！")

	pisuke.band("人生、完璧にフォローできる悪口なんて、存在しねえんだよ。", {"side": "left"})

# =========================================================
# 場面10: ギルド帰還・通称＋宮中招待状
# =========================================================
func _build_stage5_close(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage5_close")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	receptionist.band("サトシ様。...騎士団本部での野球拳決着、勝利の報告を受けております。\n王女殿下絡みの嫌疑、本日付ですべて撤回となりました。")

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、はい、ありがとうございます。")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...なお、騎士団本部からの通達：「相手方の戦術は、騎士道精神に照らし、\n卑怯の極みと評する。しかし、勝敗の規則は曲げられぬ。規則通り履行」。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("「卑怯の極み」、記録に残るんですか！？")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...ギルドとしても、摘要欄に追記いたします。\n「サトシ、戦闘前に王宮騎士団本部最上階への潜入あり。通称\n『卑怯者のノゾキ魔』」。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("通称まで、記録するの！？")

	receptionist.band("...加えて、現場目撃者の証言として、もう一件。\n「敗北を認めた騎士団長殿下に対し、当該冒険者が『卑怯者は褒め言葉\nでございます。ありがたく頂戴いたします』と返答した」と。")

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("そっ、それも、もう、ギルドに、届いてるの！？")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...騎士団本部の正式記録、極めて、迅速でございます。\n...サトシ様、王都最強の戦士の罵倒を、真正面から受け止めて、\n逆に煽り返す胆力。\n...普通の冒険者には、まず、できません。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("俺じゃない！ 俺じゃないんですって、それ！ 言ったの、俺じゃ...！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...「俺じゃない」というご主張、これも、記録に残しておきます。\n「容疑者、自身の発言を、別人の所業と主張」。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("記録の方向性、悪意ある！")

	pisuke.band("ゲコッ。二つ名持ち、煽り耐性持ち、自己責任放棄持ち。\nおめでとう、三冠だ。", {"side": "left"})

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("どれも、嬉しくない！")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...あと一件。王宮より、「サトシ様を宮中晩餐会にご招待する」旨、\n正式な召喚状が届いております。王都高官四名連破の労いを、王女殿下\n直々に、との仰せでございます。")

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...王女、本人から...。")

	pisuke.band("...いよいよ、来たぞ。", {"side": "left"})

	b.set_flag("stage5_complete")
