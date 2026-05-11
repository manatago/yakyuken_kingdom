extends RefCounted
class_name Subevent3Chapter

# サブイベント3「呪われた鎧を脱がせ！」のストーリーシーケンス。
# 本編4シーケンス（pre/blacksmith/visit/post）＋敗北時2シーケンス
# 詳細シナリオ: docs/scenarios/subevent3_scenario.txt

const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const BG_BLACKSMITH := "res://assets/backgrounds/subevent3/bg_blacksmith.png"
const BG_NOBLE_ROOM := "res://assets/backgrounds/subevent3/bg_noble_room.png"

const HERO_NORMAL := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_017.png"
const HERO_SHOCK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"
const HERO_AWKWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_014.png"
const HERO_WEAK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_004.png"
const HERO_DREAD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_018.png"
const HERO_RESIGN := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_029.png"
const HERO_PUZZLE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_006.png"
const HERO_IRRITATE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png"
const HERO_SERIOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_032.png"
const HERO_RESOLVE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_021.png"
const HERO_DISTANT := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_041.png"
const HERO_DESPAIR := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_048.png"
const HERO_PANIC := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_039.png"

const RECEP_NORMAL := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_005.png"
const RECEP_COLD := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_007.png"
const RECEP_JIT := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png"
const RECEP_BUSINESS := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_006.png"
const FIONA := "res://assets/characters/main/fiona/clothed/fiona_clothed_001.png"
const SEBAS := "res://assets/characters/mob/sebas/default/sebas_default_001.png"
const GOREN := "res://assets/characters/mob/goren/default/goren_default_001.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "subevent3_pre", "builder": "_build_subevent3_pre"},
		{"id": "subevent3_blacksmith", "builder": "_build_subevent3_blacksmith"},
		{"id": "subevent3_visit", "builder": "_build_subevent3_visit"},
		{"id": "subevent3_post", "builder": "_build_subevent3_post"},
		{"id": "subevent3_minigame_lose", "builder": "_build_subevent3_minigame_lose"},
		{"id": "subevent3_battle_lose", "builder": "_build_subevent3_battle_lose"},
	]

# =========================================================
# 場面1: ギルド受付・依頼受注
# =========================================================
func _build_subevent3_pre(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var fiona = b.character("fiona")
	var sebas = b.character("sebas")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("indigo")
	b.label("subevent3_pre")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.45, "side": "right"})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NORMAL, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	b.narrator_band("ギルドの扉が静かに開かれ、漆黒の甲冑姿の人物が、\n一歩後ろの老執事に伴われておずおずと入ってきた。")

	fiona.appear({
		"side": "center", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": FIONA, "portrait_scale": 0.4, "position": [0, 50],
	})
	sebas.appear({
		"side": "center", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": SEBAS, "portrait_scale": 0.4, "position": [180, 100],
	})

	sebas.band("...失礼いたします。\n当家のお嬢様の呪いを解いてくださる方を。報酬は金貨百枚。")

	hero.set_portrait(HERO_PUZZLE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...なんで、みんな逃げるんですか？")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.45, "side": "right"})
	receptionist.band("...エドモンド家ご令嬢フィオナ様でございます。\n一月前、呪いの鎧「ヴァニティ・チェイン」に閉じ込められて以来、\n抜け出せずにおられます。\nすでに魔術師二十人・冒険者三十人が野球拳で挑戦しましたが、\n...全員、逆に脱がされて帰っております。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あの鎧、野球拳そんなに強いんですか！？")

	receptionist.band("呪いが装着者に「絶対に勝つ」ことを強制するそうで。\nフィオナ様ご本人は脱ぎたがっていらっしゃるのに、\n自ら負けることもできないご様子でございます。")

	pisuke.band("...チップに解呪条件が出た。手順は二段階いる。\n①羞恥を与えて呪いを弱める、②弱まった隙に野球拳で勝つ。\n羞恥を先に与える手段を、誰も思いつかなかったんだろうな。", {"side": "left"})

	pisuke.band("...で、羞恥を与えるための道具に心当たりがある。\n鍛冶師ゴルンってじじいの工房に「真言の水晶球」って魔具が眠ってるはずだ。\n装着者の心を丸裸にできる代物だ。あのじじいを頼れ。", {"side": "left"})

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.45, "side": "right"})
	receptionist.band("...ところで、サトシ様。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("は、はい？")

	receptionist.band("丁度ようございました。この依頼、サトシ様がお引き受けください。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え！？ いやいや、魔術師二十人が無理だったんですよ！？")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.45, "side": "right"})
	receptionist.band("サトシ様の監視ファイル、現在三件目を記入したばかりでございます。\nここで社会貢献いただいた方が、よろしいかと。")

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("強制労働！？")

	receptionist.band("...「実績を積んで名誉を回復する機会」と申し上げております。")

	sebas.band("...受付嬢様のご推薦がおありなら、お任せいたしたく。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("いやいや、俺、受けるなんて──！")

	# ピー助操作（サトシの声で大声）
	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("受けます！ 必ずや呪いを解いてみせます！")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("言ってない！！ 今のは俺じゃ──！")

	sebas.band("（深々と一礼）\n...ありがたき幸せ。詳細は屋敷にてお伝えいたします。")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.45, "side": "right"})
	receptionist.band("...ただ今のお声、記録済みでございます。\n行動記録は例によってギルド長と貴族院へ提出いたします。")

	hero.set_portrait(HERO_IRRITATE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（ピー助に）お前、絶対わざとだろ！？")

	pisuke.band("ゲコッ。金貨百枚だぞ。家賃が足りねえんだろ。", {"side": "left"})

	hero.set_portrait(HERO_RESIGN, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...じゃあ、さっきの鍛冶師の工房に行けばいいんだな？")

	pisuke.band("ああ。セバスたちは屋敷で先に待ってる。先に工房だ。", {"side": "left"})

# =========================================================
# 場面2: 鍛冶師ゴルンの工房
# =========================================================
func _build_subevent3_blacksmith(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var goren = b.character("goren")

	b.set_protagonist("main")
	b.band_color("indigo")
	b.label("subevent3_blacksmith")
	b.background(BG_BLACKSMITH, 0.5)
	b.show_band()

	goren.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": GOREN, "portrait_scale": 0.45, "position": [0, 20],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NORMAL, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	b.narrator_band("煤けた看板の下、扉を押すと鉄と石炭の匂いが押し寄せる。\n奥の火床の前に、白髪の老鍛冶が腰を下ろしていた。")

	goren.band("...「ヴァニティ・チェイン」、のぅ。懐かしい名前じゃ。\n儂も若い頃、「真言の水晶球」で色々と遊んだことがある。")

	hero.set_portrait(HERO_PUZZLE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("遊んだ？ ...その後、どうなったんですか？")

	goren.band("...女房の心を広場で生中継した。\n翌朝、工房は全焼しておった。女房の手でな。\n...「羞恥は取り返しがつかん」。ゆめゆめ、忘れるな。")

	b.narrator_band("ゴルンは棚から青白い光の水晶球を取り出し、サトシに差し出した。")

	goren.band("これが「真言の水晶球」。装着者の心の声を映像化する魔具じゃ。\nこれで鎧の精神防御を突破できる。\n\n「伝声塔接続モード」を起動すれば、王都広場のスクリーンと\n王国中の主要通りの伝声塔に映像が同時中継される。\n使いどころには気をつけよ。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("王国中に中継って...使うんですか！？")

	pisuke.band("（便利じゃねえか。）", {"side": "left"})

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ピー助、今なんか不穏な声が──！")

	pisuke.band("気のせいだ。", {"side": "left"})

	goren.band("...手順は守れよ。\n①羞恥の儀で呪いを弱めてから、②野球拳を挑む。\n逆にした者は皆、脱がされて帰ってきた。")

# =========================================================
# 場面3+4+5+6+7: エドモンド邸〜羞恥の儀〜伝声塔起動〜フィオナ戦〜鎧崩壊
# =========================================================
func _build_subevent3_visit(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var fiona = b.character("fiona")
	var sebas = b.character("sebas")

	b.set_protagonist("main")
	b.band_color("indigo")
	b.label("subevent3_visit")
	b.background(BG_NOBLE_ROOM, 0.5)
	b.show_band()

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NORMAL, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	sebas.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": SEBAS, "portrait_scale": 0.45, "position": [200, 0],
	})
	fiona.appear({
		"side": "center", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": FIONA, "portrait_scale": 0.45, "position": [0, 30],
	})

	b.narrator_band("エドモンド邸の奥、来客の通らぬ一室。\nエドモンド卿本人は領地出張中で、セバスが立ち会う。")

	sebas.band("...して、お若いの。具体的には何をなさるおつもりですか？")

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("「真言の水晶球」です。\n...これを使って、お嬢様に羞恥を与えます。")

	sebas.band("...羞恥を、与える？")

	hero.band("え、えっと、順を追って説明します。\nまず、呪いの鎧は「野球拳で装着者を絶対に勝たせる」仕組みで、\nお嬢様が脱ぎたくても自分で負けられないんです。")

	sebas.band("...存じております。お嬢様は日々そのことに苦しんでおられます。")

	hero.band("呪いの加護を弱める唯一の方法が、装着者に強い羞恥を与えることで...\nでも、鎧が中身を隠している限り、普通に喋りかけても羞恥は発生しません。")

	hero.band("この水晶球は、お嬢様の心の声を強制的に映像化する魔具です。\n心の内を晒されると、鎧の内側でも羞恥が発生して、呪いが弱まります。\n呪いが弱まった直後に野球拳を挑めば、今度こそ勝てる...そういう仕組みです。")

	sebas.band("...つまり、お嬢様のお心の内を、\nわたくしの眼前で晒すと仰っしゃるのですか。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...は、はい。")

	sebas.band("...断じて受け入れがたい所業にございます。")

	hero.band("で、ですよね...。")

	hero.set_portrait(HERO_SERIOUS, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...あ、あの、でも、進捗は目で確認できます。\nこの水晶球、呪いの強さと色がリンクしていて、\n呪いが強いと漆黒、弱まると金色に変わるんです。\n色が薄くなっていけば「効いている」証拠になります。")

	sebas.band("...色が薄まれば進展、濃くなれば後退、と。")

	hero.band("は、はい。")

	sebas.band("...お嬢様は一月の間、鎧の中で衰弱の一途でございます。\nお言葉も、お笑いも、消えつつあります。\nご当主様が不在の今、わたくしの一存で判断せねばなりません。")

	sebas.band("...わたくし、この色を見張らせていただきます。\n色が薄まっている限り、口出しはいたしません。\n...ですが、濃くなるようなことがあれば、その時は──。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...そ、その時は？")

	sebas.band("...お察しください。")

	sebas.band("...お嬢様。この冒険者の方にお任せしたく。")

	fiona.band("...う、うん...セバスが、そう言うなら...。")

	sebas.band("（サトシに深々と一礼）\nお嬢様の尊厳、くれぐれもお守りいただきたく。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...せ、善処します...。")

	# 場面4: 羞恥の儀・スクリプト導入
	b.narrator_band("水晶球は漆黒のまま、壁の一角に映像投影窓が浮かび上がる。\n伝声塔接続モードはまだオフ。映像は個室内にのみ表示される。")

	hero.set_portrait(HERO_NORMAL, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...え、えっと、フィオナさん。\n...一か月、辛かったですよね...本当にお疲れ様でした。")

	b.narrator_band("水晶球の漆黒が、さらに深くなる。呪いの加護度が上昇した。（100 → 110）")

	fiona.band("...あ、ありがとう...お優しい方ですね...。")

	sebas.band("（眉をひそめて水晶球を見る）\n...色が濃くなっておりますな、サトシ様。")

	pisuke.band("...サトシ、お前、ただのねぎらいじゃねえか。", {"side": "left"})

	# 場面5: 羞恥の儀本番（ミニゲーム）
	b.hide_band()
	b.label("subevent3_minigame_start")
	b.minigame("res://battle/chapters/Subevent3MinigameChapter.gd")

	# 場面6: 伝声塔接続・強制公開
	b.show_band()
	b.narrator_band("水晶球の光が強まり、鎧の表面に深い亀裂が走った。\nしかし、完全崩壊には至らない。")

	fiona.band("はぁ...はぁ...。")

	pisuke.band("...ダメだ、個室じゃ最後の一押しが届かねえ。呪いはまだ半分残ってる。\n仕方ねえ。伝声塔、起動するぜ。", {"side": "left"})

	b.narrator_band("水晶球が激しく明滅し、光の柱が天井まで伸びた。\n遠く、王都中央広場の巨大スクリーンが点灯し、\n王国中の伝声塔が次々と起動していく。")

	sebas.band("な、なんでございますか、この光は──！？")

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...フィオナさん。この水晶球、伝声塔接続モードに切り替えました。\n今から、王国中の伝声塔で、あなたの心の声が同時中継されます。")

	fiona.band("...は？")

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("言ってない！ 俺、絶対言ってない！")

	sebas.band("お、お、お待ちくださいませ──！？")

	fiona.band("...い、いや...けして...けして...！")

	hero.band("止めろピー助！ 本当に止めろ！")

	pisuke.band("ここで止めたら呪いが戻るぞ。", {"side": "left"})

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("みなさーん！ 聞こえますかー！\nエドモンド家ご令嬢、フィオナ様の心の内、お届けしまーす！")

	b.narrator_band("スクリーン映像（王国中に中継）：\n「...み、見ないで...誰も、見ないで...\n...わたくし、もう、嫁に行けません...」")

	sebas.band("お、お嬢様ァ──！")

	b.narrator_band("水晶球の光が爆発し、鎧全体に深い亀裂が縦横に走る。\n呪いの加護はここに完全に弱体化した。")

	pisuke.band("よし、準備完了だ。...野球拳、いくぞ。", {"side": "left"})

	b.hide_band()
	b.label("subevent3_battle_start")
	# 共通ロスト・ナレーションは {opponent}=セバス、A〜C パターン限定
	b.battle("res://battle/chapters/FionaBattleChapter.gd", {
		"lose_opponent": "セバス",
		"lose_patterns": ["A-1", "A-2", "A-3", "B-1", "B-2", "B-3", "C-1", "C-2", "C-3"],
	})

	# 場面7: 鎧崩壊・全裸中継
	b.show_band()
	b.narrator_band("最後のじゃんけんが決まった瞬間、\n鎧全体にピシィッと深い亀裂が走り、黒い破片が風に舞った。")

	b.narrator_band("一か月間鎧の下で擦れ続けた肌着の残骸、乱れた栗色の髪、\n汗ばんだ白い肌、羞恥で真っ赤に染まった貴族令嬢の姿。")

	b.narrator_band("水晶球を通じて広場のスクリーンと王国中の伝声塔に、その姿が鮮明に投影される。")

	fiona.band("いや...いや、いやぁぁぁ...！")

	sebas.band("お嬢様ァァァ──！")

	hero.set_portrait(HERO_PANIC, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ピー助、止めろ！ 早く！")

	pisuke.band("...あー、停止スイッチが見つからねえなぁ。", {"side": "left"})

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("いやーみんな、よく見ろよ！\nこれがエドモンド家ご令嬢、フィオナ様の本当の姿だー！")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("言ってない！！ 一言も言ってない！！")

	sebas.band("...ごく一部、でございます...ごく一部の、全、国、民、で...。")

	fiona.band("全国民じゃないですかぁぁ...。")

	pisuke.band("...お、見つけた見つけた、停止スイッチ。", {"side": "left"})

	b.narrator_band("しかし、もう遅かった。")

	hero.set_portrait(HERO_IRRITATE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...ピー助、お前、絶対わざとだよな...。")

	pisuke.band("...ゲコッ。", {"side": "left"})

# =========================================================
# 場面8: 数日後・ギルド受付・恨み書簡
# =========================================================
func _build_subevent3_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("indigo")
	b.label("subevent3_post")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.45, "side": "right"})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_DISTANT, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	receptionist.band("...サトシ様。ご報酬です。金貨百枚。\nセバス様からの書簡が添えられております。")

	b.narrator_band("「拝啓 サトシ様。\n　呪いを解いていただき感謝いたします。\n　ただし、お嬢様の肌着姿は王国の津々浦々に中継されました。\n　婚約者候補七名のうち六名が辞退。お嬢様は嫁に行けぬ身となられました。\n　この恨み、墓まで持ってまいります。\n　なお、報酬は正当な対価ゆえ、お受け取りください。\n　二度とお嬢様にお近づきにならぬよう。\n　　　　　　　　　　　　　　　　エドモンド家執事 セバス」")

	receptionist.band("もう一通、フィオナ様ご本人からの書簡もございます。")

	b.narrator_band("「...サトシ。\n　...一生、恨みます。\n　...下着のこと、脇のこと、匂いのこと、\n　...全部、全部、王国中に流されました。\n　...わたくしはもう、外を歩けません。\n　...婚約者候補は全員いなくなりました。\n　...あなたのせいです。\n　...絶対に許しません。\n　　　　　　　　　　　　　　　　フィオナ」")

	hero.band("...。")

	pisuke.band("...おい、だいぶ恨まれてるな。", {"side": "left"})

	hero.set_portrait(HERO_IRRITATE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("お前のせいだろ！！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.45, "side": "right"})
	receptionist.band("...監視区分を『最重要監視対象SS』へ昇格いたします。\nサトシ様専用に本日新設いたしました。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("俺専用！？")

	receptionist.band("...下着コレクションに感嘆し、覗き穴に侵入し、\nご令嬢を肌着姿で全国中継。\n...もはや偶然では済みませんね。")

	pisuke.band("ゲコッ。なに、人生なんてこんなもんさ。", {"side": "left"})

	hero.set_portrait(HERO_IRRITATE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("お前のせいだろ！！")

	b.set_flag("subevent3_complete")

# =========================================================
# 敗北時シーケンス（既存）
# =========================================================
func _build_subevent3_minigame_lose(b):
	var hero = b.character("main")
	var sebas = b.character("sebas")
	var fiona = b.character("fiona")

	b.set_protagonist("main")
	b.band_color("indigo")

	b.label("subevent3_minigame_lose")
	b.background(BG_NOBLE_ROOM, 0.5)
	b.show_band()

	b.narrator_band("水晶球は完全に漆黒に染まり、ピシリと小さなヒビが走った。\nフィオナの心は完全に閉ざされ、儀式は崩壊した。")

	fiona.band("...もう、結構です。...今日は、お引き取りください。")

	sebas.band("...本日は、ここまでに。\n...ご準備が整いましたら、改めてお越しくださいませ。")

	hero.appear({
		"side": "left",
		"appear_effect": "fade",
		"appear_duration": 0.4,
		"portrait": HERO_WEAK,
		"portrait_scale": 0.6,
		"flip": 1,
		"position": [0, 70],
	})
	hero.band("...くそっ。出直します...。")

	b.narrator_band("サトシは水晶球を抱え、エドモンド邸を辞した。\n...一度ギルドに戻り、態勢を立て直すしかない。")

	hero.leave({
		"exit_effect": "fade",
		"exit_duration": 0.4,
		"wait_for_exit": true,
	})

func _build_subevent3_battle_lose(b):
	var sebas = b.character("sebas")

	b.set_protagonist("main")
	b.band_color("indigo")

	b.label("subevent3_battle_lose")
	b.background(BG_NOBLE_ROOM, 0.5)
	b.show_band()

	b.narrator_band("水晶球の色がふたたび漆黒へ戻り、鎧の亀裂が癒着していく。\n弱まっていた呪いの加護が、再び完全な形で立ち上がった。")

	b.narrator_band("水晶球の伝声塔中継は強制停止された。\n広場のスクリーンと王国中の伝声塔が一斉に暗転する。")

	sebas.band("...お、お若いの！ どうか、もう一度、水晶球から...！\nお嬢様を、よろしく、お願いいたします...！")
