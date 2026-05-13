extends RefCounted
class_name Stage7Chapter

# Stage7: 勝利エンディング（王座継承・王女の怨念・エピローグ）
# 詳細シナリオ: docs/scenarios/stage7_ending_win.txt

const BG_HALL := "res://assets/backgrounds/stage6/bg_royal_hall.png"
const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const BG_SUNSET := "res://assets/backgrounds/stage7/bg_capital_sunset.png"

const HERO_NORMAL := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_017.png"
const HERO_SHOCK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"
const HERO_AWKWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_014.png"
const HERO_GUILTY := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_034.png"
const HERO_DESPAIR := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_048.png"
const HERO_HOPE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_036.png"
const HERO_RESIGN := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_029.png"
const HERO_DISTANT := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_041.png"
const HERO_DAZED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_030.png"
const HERO_PROTEST := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_039.png"
const HERO_PANIC := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_018.png"
const HERO_WARM := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_036.png"
const HERO_RELIEF := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_017.png"

const PRINCESS := "res://assets/characters/main/princess/clothed/princess_clothed_001.png"
const FERIA := "res://assets/characters/main/feria/clothed/feria_clothed_001.png"
const CHAMBERLAIN := "res://assets/characters/mob/chamberlain/default/chamberlain_default_001.png"
const RECEP_NORMAL := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_005.png"
const RECEP_COLD := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_007.png"
const RECEP_JIT := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png"
const RECEP_BUSINESS := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_006.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "stage7_throne", "builder": "_build_stage7_throne"},
		{"id": "stage7_epilogue", "builder": "_build_stage7_epilogue"},
	]

# =========================================================
# 場面1: 王座継承・王女の怨念
# =========================================================
func _build_stage7_throne(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var princess = b.character("princess")
	var feria = b.character("feria")
	var chamberlain = b.character("chamberlain")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage7_throne")
	b.background(BG_HALL, 0.5)
	b.show_band()

	chamberlain.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": CHAMBERLAIN, "portrait_scale": 0.5, "position": [200, 0],
	})
	chamberlain.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})

	princess.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": PRINCESS, "portrait_scale": 0.5, "position": [0, 50],
	})
	princess.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})

	feria.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": FERIA, "portrait_scale": 0.5, "position": [-200, 100],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_GUILTY, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	chamberlain.band("（震える声で）\n...勝者、冒険者サトシ殿。4回勝負、1勝取得。本試合の勝利者で\nございます。")

	b.narrator_band("サトシ、膝から崩れ落ちて大広間の床に土下座。額を床につける。")

	hero.band("殿下！ 本当に、申し訳、ございませんでした！\n不敬罪でも、何でも、お受けいたします！")

	princess.band("（フェリアに支えられたまま、震える声）\n...サトシ。...今のは、...「儀礼」...では、ない、...のですよね？")

	hero.set_portrait(HERO_GUILTY, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...は、はい。申し訳ございません、儀礼では、ありません。")

	princess.band("（長い沈黙）\n...わかりました。\n...公式記録上は、「異邦の秘技『異邦の急所伝達術』による、王家権威\nの一時解除」と、記載いたします。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（そんな名前、王宮公式記録に残るの、嫌すぎる...！）")

	princess.band("...ですが、サトシ様。先ほどの賭け、王位を賭ける、という、私の\n申し出は、王族として、正式な発言でございました。\n...本試合、あなたの勝利、確定いたしました。\n...王位は、あなたに、明け渡します。それが、野球拳の、掟です。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...殿下、あの、俺、本当に、王座なんて...。")

	princess.band("...ですが、サトシ様。\n...私の、心が、あなたを、真の王と認める日は、来ないでしょう。\n...あの、異邦の秘技は、一生、忘れません。\n忘れられる、はずが、ないのです。")

	hero.set_portrait(HERO_GUILTY, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...で、殿下、本当に、申し訳、ございませんでした、何度でも謝ります。")

	princess.band("...執政の実務は、フェリアに、託します。\n...私は、自室に、戻ります。\n...しばらく、誰にも、会えそうに、ございません。")

	princess.leave({"exit_effect": "fade", "exit_duration": 0.6, "exit_to": "right"})

	feria.band("（去り際、振り返って、冷たい目）\n...卑怯者の、ノゾキ魔の、国王殿下。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("その呼び方、公式記録に、残さないで！")

	feria.band("...王宮記録は、極めて正確でございます。")

	feria.leave({"exit_effect": "fade", "exit_duration": 0.5, "exit_to": "right"})

	chamberlain.band("（震える声）\n...新国王陛下の即位の儀は、本日の混乱が、落ち着き次第、正式に、\n執り行います。\n...それまで、陛下には、暫定の王宮居室を、ご用意、いたします。")

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...俺、国王、なっちゃったのか...。")

# =========================================================
# 場面2: エピローグ・ギルド→夕暮れの王都
# =========================================================
func _build_stage7_epilogue(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage7_epilogue")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_RESIGN, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...サトシ様。国王ご即位、おめでとうございます。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、はい、ありがとう、ございます...。")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...本日付で、ギルドの「要監視対象A」欄は、閉じさせていただきます。")

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、やっと、外れる...！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...代わりに、「国王陛下専用・要監視対象A」という新規台帳を、\n開設いたします。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("なんで俺専用で、新台帳が、できるの！？")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...これまでの記録をすべて引き継ぎ、加えて、本日より、以下を\n第一行目に記載いたしました。\n\n「国王陛下。公の場で、女性に、急所を触らせる習性あり。\n...最大の警戒対象は、陛下のお膝元、王都全域」。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("もう何も、勝ってない、俺、一つも、勝ってない...！")

	receptionist.band("...なお、王宮記録からも、追加の項目が、届いております。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（嫌な予感...！）")

	receptionist.band("「晩餐会・王座戦に於いて、挑戦者サトシ、王女殿下に急所を触れ\nさせる際、不覚にも勃起の状態にあり。\n王家記録官、これを、『御前勃起』と正式記載。\nよって、陛下に、新称号を贈呈：『御前勃起王（ごぜん・ぼっき・おう）』」。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("称号！？ 称号になったの、それ！？\nしかも、御前勃起王！？ 歴代の王様の名に並ぶの、それ！？")

	receptionist.band("...歴代の王の称号一覧に、本日付で、追記いたしました。\n「初代サトシ、通称『御前勃起王』。異邦より来たり、王女殿下に\n急所を触れさせ、その際、予期せず勃起することで、王家の秘技を\n永久封印した、異邦の王」。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("誰が、見ても、変な王だよ、それ！")

	pisuke.band("ゲコッ。ロイヤル・ネーム、勲章クラスだな。", {"side": "left"})

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("勲章じゃない！ 歴史的汚点だ！")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...なお、陛下の礼装は、王宮の仕立てにて、すでに裾の硬さに\n耐える特注品に、改修が進んでおります。")

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("国の予算で、そんなの、作らないで！")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...ですが、一点だけ、申し添えさせてください。")

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("？")

	receptionist.band("...サトシ国王陛下の、これまでの一貫性について。\nアサシン・レイラ様、シスター姉マグダレナ様、魔法師団長セレス様、\n騎士団長フェリア様、そして王女殿下。\n...五人の王国要人の秘密を崩しながら、一度も、その秘密を、\n公に晒していらっしゃらない。")

	receptionist.band("...これは、ギルド史上、類を見ない「秘密保持の誠実性」でございます。\n...民の中には、既にそれを「卑怯だが誠実な王」と評する声も\nございます。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...卑怯だが、誠実...って、同時に成立する評価なのか、それ。")

	receptionist.band("...評価は、民がいたします。\n...改めて、おめでとうございます。...陛下。")

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...受付嬢さん、それ、初めて、笑ってくれた、よな。")

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...気のせいでございます。")

	hero.set_portrait(HERO_WARM, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("絶対に、笑った！")

	pisuke.band("ゲコッ。...良かったな、サトシ。やっと、この国で一人、お前を\n認めてくれる人が出てきた。", {"side": "left"})

	hero.band("（...まあ、一人でも、いてくれれば、それで、いいか。）")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})
	receptionist.leave({"exit_effect": "fade", "exit_duration": 0.3})

	# 夕暮れの王都
	b.background(BG_SUNSET, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_DISTANT, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("...みのり。...俺、ちょっと、忙しくなりそうだよ。\nでも、いつか、戻るから。\n...それまで、こっちで、なんとかやってみる。")

	pisuke.band("ゲコッ。...王様稼業、気楽にやれ。お前の人生、もうこれ以上、\n落ちようがねえんだ。", {"side": "left"})

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("それ、慰めになってないからな！")

	b.narrator_band("サトシ、王都の通りを歩き出す。夕陽が、その背中を、照らしていた。")
