extends RefCounted
class_name Subevent4Chapter

# Subevent4: 受付嬢リーゼを脱がせ！（処罰審査→野球拳→過去開示）
# 詳細シナリオ: docs/scenarios/subevent4_scenario.txt

const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"

const HERO_NORMAL := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_017.png"
const HERO_PUZZLE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_006.png"
const HERO_SHOCK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"
const HERO_AWKWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_014.png"
const HERO_IRRITATE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png"
const HERO_RESOLVE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_021.png"
const HERO_SERIOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_032.png"
const HERO_DREAD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_018.png"
const HERO_DISTANT := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_041.png"
const HERO_HOPE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_036.png"
const HERO_DESPAIR := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_048.png"
const HERO_PROTEST := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_039.png"
const HERO_RELIEF := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_036.png"

const RECEP_NORMAL := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_005.png"
const RECEP_BUSINESS := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_006.png"
const RECEP_COLD := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_007.png"
const RECEP_JIT := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png"
const RECEP_TOPLESS := "res://assets/characters/main/receptionist/topless/receptionist_topless_001.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "subevent4_pre", "builder": "_build_subevent4_pre"},
		{"id": "subevent4_post", "builder": "_build_subevent4_post"},
	]

# =========================================================
# 場面1+2: 酒場の気づき → 処罰審査 → 申請
# =========================================================
func _build_subevent4_pre(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("subevent4_pre")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NORMAL, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	b.narrator_band("依頼を終えたサトシが、ギルドの酒場でぼんやりしている。\nカウンターの向こうでは、受付嬢が書類を整理している。")

	hero.set_portrait(HERO_PUZZLE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...なあ、ピー助。")

	pisuke.band("なんだ。", {"side": "left"})

	hero.band("この世界、野球拳で挑むのが当たり前だろ。\n貴族にも、シスターにも、呪われた鎧にも、みんな挑んでる。\n...でも、受付嬢さんに挑んだ奴、一人もいなくないか？")

	pisuke.band("...ほう。", {"side": "left"})

	hero.band("あんなに美人なのに。毎日、全冒険者が顔を合わせてるのに。\n...不自然だろ。")

	pisuke.band("お前、いいところに気づいたな。ちょっとスキャンしてみる。", {"side": "left"})

	pisuke.band("...出た。ギルド内の全冒険者のチップに\n「対象：リーゼ」の挑戦抑制バイアスがかかってる。\n...「リーゼ」ってのが受付嬢の本名だ。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("リーゼ...。名前、初めて聞いた。")

	pisuke.band("名前すら認識しにくくなるレベルのバイアスだ。\nお前は「欠陥適合者」だから効かねえ。", {"side": "left"})

	pisuke.band("...おい、もっとヤバいもん出てきたぞ。\n受付嬢のステータス。カードデッキのグレードが尋常じゃねえ。\n...元・王宮の上位戦闘要員クラスだ。\nしかもバイアスをかけたのは本人。自分で自分にプロテクトをかけてる。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...あの受付嬢さんが、そんなに強い...？")

	pisuke.band("ああ。で、だ。\nあの女、お前のことを散々犯罪者扱いしてきたよな？\nお前のことを裁いてる側が、自分だけ安全圏。\n...ちょっと、ズルくねえか？", {"side": "left"})

	hero.set_portrait(HERO_DISTANT, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...確かに、ちょっとズルい、かも...。")

	pisuke.band("だろ？\n...ただ、覚えとけ。\nお前だけは、あの女に挑める唯一の男だってことをな。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面2: 翌日・処罰審査
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NORMAL, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})

	b.narrator_band("翌朝。サトシがギルドに顔を出すと、\n受付嬢がカウンターの前で直立不動で待っていた。")

	receptionist.band("...サトシ様。お待ちしておりました。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("お、おはようございます...。")

	receptionist.band("...本日は、お伝えしなければならないことがございます。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("な、なんですか...。")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("サトシ様の監視ファイルが、規定の四件に到達いたしました。\nギルド規約第二十七条に基づき、正式な処罰審査を行います。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("しょ、処罰審査！？")

	receptionist.band("...内容をご説明いたします。\n一件目、盗賊団アジトにおける下着コレクション感嘆。\n二件目、教会特別礼拝室の覗き穴事件。\n三件目、エドモンド家ご令嬢を肌着姿で王国中に生中継した件。\n四件目、ご令嬢フィオナ様より正式な被害届が提出されております。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("四件目！？ フィオナさんから被害届！？")

	receptionist.band("...「一生恨む」と書かれた書簡がございましたので、\n被害届として受理いたしました。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あれ、被害届だったんですか！？")

	receptionist.band("...四件到達により、処罰内容は「ギルド永久追放」となります。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、永久追放！？ 嘘でしょ！？")

	receptionist.band("...嘘は申しません。\n本日中に処罰が確定いたします。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ちょ、ちょっと待って！ 全部俺じゃないんです！\n下着は見ただけだし、覗き穴は調査だし、全国中継はピー助が──！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...ピー助？")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...なんでもないです。")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...弁明の機会は規約上ございません。\n処罰は本日中に執行されます。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（小声）落ち着けるわけないだろ！ 永久追放だぞ！")

	pisuke.band("...今、ギルド規約をスキャンした。\n第二十七条の但し書きに、こう書いてある。\n「被処罰者は、審査官との野球拳に勝利した場合、処罰を免れることができる」", {"side": "left"})

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（小声）...え？ そんな抜け道が？")

	pisuke.band("あるんだよ。審査官ってのは、この場合、受付嬢だ。\n...つまり、あの女に野球拳で勝てば、追放を免れる。", {"side": "left"})

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（小声）で、でも、元・上位戦闘要員だぞ！？ 勝てるわけ──！")

	pisuke.band("...お前、昨日なんて言った？ 「ズルい」って言っただろ。\n...やるしかねえんだよ。", {"side": "left"})

	# ピー助操作（サトシの声で大声宣言）
	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("──待ってください！\nギルド規約第二十七条但し書きに基づき、\n審査官との野球拳を申請します！")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("言ってない！！ 今のは──！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...今、なんと仰いましたか。")

	hero.band("いや、だから俺じゃ──")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...「審査官との野球拳を申請する」と、\nただ今、サトシ様ご本人のお声でお聞きしました。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("だからそれは──！")

	receptionist.band("...記録済みでございます。")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...第二十七条但し書き。\n...確かに、そのような規定がございます。\n\n...よろしいでしょう。受けます。")

	receptionist.band("...ただし、条件がございます。\n...サトシ様が負けた場合。\n永久追放に加え、監視ランクを「SSS」に昇格いたします。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("まだ上があるんですか！？")

	receptionist.band("...今、作りました。")

	receptionist.band("...勝負は本日、ギルドの全員の前で行います。\n...閉店後の二人きりなどという、犯罪の温床になる環境ではなく。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("犯罪じゃないって...。")

# =========================================================
# 場面3+4: 処罰審査バトル → 決着後の過去開示
# =========================================================
func _build_subevent4_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("subevent4_post")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_SERIOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	b.narrator_band("ギルドのホールに冒険者たちが集まっている。\n「処罰審査の野球拳」という前代未聞の事態に、\n酒場は立ち見が出る騒ぎになっていた。")

	b.narrator_band("受付嬢がカウンターの前に立つ。\nいつもの制服姿だが、目つきが違う。\n鋭く、静かに、戦う者の目。")

	receptionist.band("...改めまして。\n本日の処罰審査、被処罰者サトシ様の申請により、\n野球拳にて執行いたします。\n\n...なお、この勝負の全記録は、\nギルド長および貴族院に報告されます。\n...いつも通りでございます。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("勝負の前から報告書！？")

	receptionist.band("...備えあれば憂いなし。")

	pisuke.band("スキャン完了。...やっぱりヤバい。\n高グレードカードが大量にある。\nベイズ・アイをフル活用しても厳しい。\n...覚悟しろ、サトシ。", {"side": "left"})

	hero.set_portrait(HERO_SERIOUS, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...ピー助。今回は、頼むから余計なことを言わないでくれ。")

	pisuke.band("...善処する。", {"side": "left"})

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("「善処」って何！？ やるかやらないかで答えて！")

	pisuke.band("...善処する。", {"side": "left"})

	receptionist.band("...準備はよろしいですか、サトシ様。")

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...はい。")

	receptionist.band("...では。\n...ギルドの受付嬢を、甘く見ないでくださいね。")

	b.hide_band()
	b.label("subevent4_battle_start")
	# 受付嬢バトル（既存ReceptionistBattleChapter）
	b.battle("res://battle/chapters/ReceptionistBattleChapter.gd")

	# 場面4: 決着後
	b.show_band()
	receptionist.set_portrait(RECEP_TOPLESS, {"scale": 0.5, "side": "right", "flip": 0})

	receptionist.band("...負けました。")

	b.narrator_band("ギルド全体が一瞬静まり返り、数秒後、爆発するような歓声が湧き起こった。")

	# ピー助操作（大音声）
	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("いやーみんな！ ついに受付嬢を脱がせたぞー！\n王都一の鉄壁、このサトシが攻略してやったー！")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("言ってない！！ 一言も言ってない！！")

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("......。")

	receptionist.band("...サトシ様。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("は、はい...。")

	receptionist.band("...処罰審査の結果、サトシ様の勝利が認められました。\nギルド永久追放は、撤回いたします。")

	hero.set_portrait(HERO_RELIEF, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...よ、よかった...。")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...ですが。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...ですが？")

	receptionist.band("...先ほどの「脱がせたぞ」発言について。\nギルド内の冒険者百二十名が証人です。\n...五件目として監視ファイルに記録いたしました。\n件名は「受付嬢を公衆の面前で脱がせたことへの歓喜の絶叫」。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("件名が長い！！ しかも俺じゃない！！")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...SSランクは据え置きでございます。")

	hero.band("勝ったのに下がらないんですか！？")

	receptionist.band("...勝敗と素行は、別の話でございます。")

	# 過去開示
	hero.set_portrait(HERO_SERIOUS, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...リーゼさん。ひとつ、聞いてもいいですか。")

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...なんですか。")

	hero.band("...なんで、プロテクトをかけていたんですか？")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...強すぎたのです。誰と勝負しても勝ってしまう。\nそのうち、誰も私に挑まなくなった。\n...だからプロテクトをかけて、最初から挑まれないようにした。\n...それだけです。")

	hero.band("...。")

	receptionist.band("...馬鹿みたいでしょう。")

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...いえ。\n...でも、もうプロテクトは要らないんじゃないですか。")

	receptionist.band("...。")

	hero.band("...俺がいますから。\n...また挑みますよ。何度でも。")

	receptionist.band("......。")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...サトシ様。")

	hero.band("はい。")

	receptionist.band("...今の発言、監視ファイルに記録してよろしいですか。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("えっ。")

	receptionist.band("...「受付嬢に対し、繰り返し勝負を挑む宣言」。\n...つきまとい宣言と解釈される可能性がございます。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("違う！！ そういう意味じゃない！！")

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...ふふ。\n...冗談でございます。\n...記録はいたしません。...今回だけは。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...「今回だけ」って何ですか...。")

	receptionist.band("...それから、サトシ様。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...まだあるんですか。")

	receptionist.band("...あなたの実力は、認めます。\n今日、それが証明されました。\n...いずれ、もっと大きな相手と戦うことになるかもしれません。\n...その時は、ギルドとして支援いたします。")

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...ありがとうございます。")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...もちろん、行動記録は全て提出させていただきますが。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("最後まで監視付きなんですか！")

	receptionist.band("...「支援」と「監視」は、両立いたします。")

	hero.band("しないでしょ普通！")

	receptionist.band("...ご安心ください。\nわたくしが監視いたしますので。\n...他の誰よりも、丁寧に。")

	hero.set_portrait(HERO_DISTANT, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...それ、一番怖いやつじゃないですか...。")

	pisuke.band("...ゲコッ。\nまあ、悪くねえ展開じゃねえか。", {"side": "left"})

	hero.set_portrait(HERO_IRRITATE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("お前のせいで五件目が増えたんだけどな！！")

	b.set_flag("subevent4_complete")
