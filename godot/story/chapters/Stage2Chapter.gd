extends RefCounted
class_name Stage2Chapter

# Stage2: レイラ編（盗難濡れ衣 → アサシン対面 → 初戦敗北 → ミニゲーム → 再戦勝利）
# 詳細シナリオ: docs/scenarios/stage2_scenario.txt

const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const BG_INN := "res://assets/backgrounds/stage2/bg_inn_meeting.png"
const BG_RESTING := "res://assets/backgrounds/stage2/bg_guild_resting.png"

# サトシ立ち絵
const HERO_WEAK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_004.png"   # 身を縮めた弱気顔
const HERO_PUZZLE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_006.png" # 間の抜けた困惑
const HERO_IRRITATE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png" # 苛立ち腕組み
const HERO_SHOCK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"  # 驚愕、ぎょっと目を見開く
const HERO_AWKWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_014.png" # バツの悪い顔
const HERO_ENCHANTED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_022.png" # 見惚れて呆然
const HERO_HAPPY := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_024.png"  # 幸福顔
const HERO_EXALT := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_025.png"  # 陶酔
const HERO_DOWN := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_027.png"   # 机に突っ伏す
const HERO_FORWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_028.png" # 身を乗り出す
const HERO_RESIGN := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_029.png"  # 観念して伏し目
const HERO_DAZED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_030.png"   # 呆然
const HERO_DREAD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_031.png"   # 嫌な予感
const HERO_SERIOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_032.png" # 真剣
const HERO_COLD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_033.png"    # 冷静な断罪
const HERO_GUILTY := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_034.png"  # 気まずさと罪悪感
const HERO_TIRED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_035.png"   # 疲労
const HERO_HOPE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_036.png"    # 縋るような期待
const HERO_DESPAIR := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_038.png" # 愕然
const HERO_PROTEST := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_039.png" # 抗議顔
const HERO_DISTANT := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_041.png" # 遠い目
const HERO_DUSK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_042.png"    # 夕暮れ俯く

# その他
const RECEP_NORMAL := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_005.png"
const RECEP_JIT := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png"
const RECEP_COLD := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_007.png"
const STAFF_B := "res://assets/characters/mob/staff_b/default/staff_b_default_001.png"
const ADV_C := "res://assets/characters/mob/adventurer_a/clothed/adventurer_a_clothed_007.png"
const ADV_D := "res://assets/characters/mob/adventurer_a/clothed/adventurer_a_clothed_001.png"
const ADV_E := "res://assets/characters/mob/adventurer_a/clothed/adventurer_a_clothed_002.png"
const LAYLA := "res://assets/characters/main/layla/clothed/layla_clothed_001.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "stage2_pre", "builder": "_build_stage2_pre"},
		{"id": "stage2_meet", "builder": "_build_stage2_meet"},
		{"id": "stage2_recover", "builder": "_build_stage2_recover"},
		{"id": "stage2_post", "builder": "_build_stage2_post"},
		{"id": "stage2_close", "builder": "_build_stage2_close"},
	]

# =========================================================
# 場面1+1.5: 盗難濡れ衣〜暗部送致
# =========================================================
func _build_stage2_pre(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var staff_b = b.character("staff_b")
	var receptionist = b.character("receptionist")
	var adv_c = b.character("adv_c")
	var adv_d = b.character("adv_d")
	var adv_e = b.character("adv_e")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage2_pre")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	staff_b.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": STAFF_B, "portrait_scale": 0.5, "position": [0, 50],
	})
	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "position": [0, 0], "flip": 0})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_WEAK, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	staff_b.band("...私の指輪が、ないんです！ 昨日、カウンター裏の引き出しに、\n確かに入れていたのに...！ 祖母の形見の、銀の指輪で...！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...B嬢。カウンター裏への出入りは、職員と、許可を得た冒険者のみ。\n昨日の出入り者を、確認いたします。")

	adv_c.appear({
		"side": "center", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": ADV_C, "portrait_scale": 0.5, "position": [-200, 100],
	})
	adv_c.band("受付嬢様、昨日、B嬢をジロジロ舐めるように見てる、気色悪い男が\nカウンター裏で一人、いたぜ。あれ、絶対、指輪ついでに下心が出てた。")

	adv_c.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})


	adv_d.appear({
		"side": "center", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": ADV_D, "portrait_scale": 0.5, "position": [0, 100],
	})
	adv_d.band("あー、あいつか。...要監視対象Aの、あの。")

	adv_d.leave({"exit_effect": "fade", "exit_duration": 0.25, "wait_for_exit": false})


	adv_e.appear({
		"side": "center", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": ADV_E, "portrait_scale": 0.5, "position": [200, 100],
	})
	adv_e.band("そうそう、あの「変態顔」のやつ。B嬢の胸元から引き出しまで、視線が\n舐めるように動いてた。")

	hero.set_portrait(HERO_PUZZLE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（俺、昨日、書類届けに行っただけだぞ...！\n...いや、B嬢、綺麗だなとは思ったけど、ジロジロは...\n...あれ、数秒、視線、止まったか？ いや、普通の範囲、だよな...？）")

	staff_b.band("...サトシ様、昨日、確かに、カウンター裏に、いらしてましたけど...。\nジロジロ見られてたって言われると、ちょっと、怖いです...。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、いや、B嬢、俺、ジロジロなんて、見てないです！\n...確かに、綺麗な方だなとは、一瞬、思いましたけど...！")

	staff_b.band("（涙目）...やっぱり、見ていらしたんじゃ...。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あっ、違くて、視界に入った瞬間の反射みたいな...！")

	b.narrator_band("冒険者たちがざわつく。サトシを犯人と決めつけ、勝ち誇った笑み。")

	adv_c.leave({"exit_effect": "fade", "exit_duration": 0.3})
	adv_d.leave({"exit_effect": "fade", "exit_duration": 0.3})
	adv_e.leave({"exit_effect": "fade", "exit_duration": 0.3})
	staff_b.leave({"exit_effect": "fade", "exit_duration": 0.3})

	# --- 場面1.5: 一次聴取 ---
	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...サトシ様。過去の素行記録を確認いたします。")

	receptionist.band("...王都広場で全裸、冒険者Aに戦闘挑発、盗賊団アジトで下着展示に\n異常鑑賞、教会覗き部屋三度の現行犯。\n...本件の状況証拠と、この素行を総合勘案いたしますと、有罪相当と\n判断されます。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（...過去の記録、重すぎる...！）")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...ご本人のご意向を確認する必要もなく、既に暗部に回しました。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("聞いてくれよ、せめて！")

	receptionist.band("...暗部検証は、「実力を示せば嫌疑は晴れる」制度。\n裁判よりはマシでございます。\n...精々、ご奮闘ください。")

	pisuke.band("ゲコッ。完全に結論ありきの送致だ。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.4, "wait_for_exit": true})
	receptionist.leave({"exit_effect": "fade", "exit_duration": 0.4})

# =========================================================
# 場面2: 月の葉亭・饗応＋場面3バトル（初戦・固定敗北）
# =========================================================
func _build_stage2_meet(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var layla = b.character("layla")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage2_meet")
	b.background(BG_INN, 0.5)
	b.show_band()

	layla.appear({
		"side": "right", "appear_effect": "fade_slide", "appear_from": "right",
		"appear_duration": 0.8, "appear_distance": 200,
		"portrait": LAYLA, "portrait_scale": 0.5, "position": [0, 10],
	})
	layla.band("サトシ様。...ようこそ、おいでくださいました。\n暗部調査部門のレイラ、でございます。")

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_ENCHANTED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	hero.band("あ、サ、サトシ、です...。")

	pisuke.band("...おい、サトシ。相手、えらい別嬪だな...。", {"side": "left"})

	hero.band("ピー助、お前、警戒担当だろ。")

	pisuke.band("...ちゃんとスキャンは、してる。してる、ぞ。", {"side": "left"})

	b.narrator_band("（ピー助もレイラに釘付け、スキャン精度は普段の3割。本人たち自覚なし。）")

	layla.band("検証前に、ささやかなお食事を。...どうぞ。")

	b.narrator_band("スープ、ワイン、パンが並ぶ。手つきはプロの給仕、完璧に滑らかな所作。")

	hero.set_portrait(HERO_HAPPY, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...うまい、このスープ、複雑な香りで...。")

	layla.band("...お気に召されましたか。暗部直営の料理人の一品でございます。")

	layla.band("...お勝負前の緊張を、少し、ほぐさせていただきましょうか。")

	hero.set_portrait(HERO_EXALT, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（天国だ...俺、今日、何かに選ばれたのか...？）")

	pisuke.band("...夜会の王者扱いだな、お前、今日。", {"side": "left"})

	b.narrator_band("二人、完全に鵜呑み。饗応を完食・完飲。")

	layla.band("...では、検証、開始でございます。\n暗部規定により、判断力検査として、じゃんけんによる三本勝負。\nサトシ様の「実力」を、私が直に拝見させていただきます。")

	hero.set_portrait(HERO_HAPPY, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あっ、はい、ばっちりです！\n（...あれ、体、ふわふわしてる、気が...。高揚感、かな？）")

	pisuke.band("暗部の慣例だ...盗難の判断力を、じゃんけんで測る建前。\n気を引き締めろ、サトシ。", {"side": "left"})

	b.hide_band()
	b.label("stage2_battle1_start")
	# 初戦（固定敗北）
	b.battle("res://battle/chapters/Stage2BattleChapter.gd")
	b.label("stage2_battle1_done")

# =========================================================
# 場面4: 作戦会議・事後解析
# =========================================================
func _build_stage2_recover(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage2_recover")
	b.background(BG_RESTING, 0.5)
	b.show_band()

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_DOWN, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	hero.band("...完敗だった。ベイズ・アイ、外しまくった。")

	pisuke.band("...サトシ。事後解析、共有しとく。\nあの饗応、毒だ。スープに鎮静毒、ワインに注意力減衰のハーブ。\nお前の血中成分、はっきり出てる。", {"side": "left"})

	hero.set_portrait(HERO_FORWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ええ！？ なんでリアルタイムで警告しなかったんだよ！")

	pisuke.band("...あの女、所作が完璧すぎて、一瞬、データ処理を鑑賞に振ってしまった。", {"side": "left"})

	hero.set_portrait(HERO_IRRITATE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("完全に見とれてただろ！")

	pisuke.band("お前も、スープ完飲・ワイン半飲だった。お互い様だ。\n...で、見とれた分の挽回に、事後スキャンで、お前の敗北分のデータを拾った。", {"side": "left"})

	b.narrator_band("対面じゃ気づけなかった、微細な動揺：\n  ・スープ皿を置いた時、手 0.1秒 震え\n  ・乾杯の瞬間、視線 0.3秒 逸れ\n  ・肩に触れた時、指先 0.05秒 強張り\n  ・耳元で囁く前、唇の震え 3ミリ")

	pisuke.band("俺様の推論：レイラ、訓練は完璧、実戦はゼロ。\n暗部の履修記録、「色仕掛け・座学A」「実地演習：未実施」。\n...たぶん、唇も肌も、経験ゼロだ。", {"side": "left"})

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("アサシンで、色仕掛けで、実戦ゼロって...。\n俺ら、それに、まんまとやられたのか...。")

	pisuke.band("超純情のまま、Aランクで卒業してる。常人には完璧に見える色仕掛けだ。\n...勝ち筋は、そこだ。再検証で言葉責めで動揺させる。", {"side": "left"})

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...それって、つまり、俺、彼女に下品なこと言うってこと？")

	pisuke.band("ちがう。下品で、卑猥で、彼女の純情を直撃する質問は、\n俺様が不意打ちで投げる。\nお前は、その瞬間の彼女の表情から、動揺の出ている箇所を読み取って、\n指摘しろ。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、俺、表情の異常を、指摘するだけ...？\nでも、そんなの、見抜けるかなぁ...。\n失敗したら、その場で斬られるんでしょ...？")

	pisuke.band("命の代わりだ。腹をくくれ。\n彼女が本気を出したら、お前、瞬殺されるぞ。", {"side": "left"})

	hero.set_portrait(HERO_RESIGN, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...うう...分かった、やるよ...。")

	pisuke.band("決まりだ。じゃあ、行くぞ。", {"side": "left"})

	b.hide_band()
	b.label("stage2_minigame_start")
	# ミニゲーム（表情選択式・言葉責め）
	b.minigame("res://battle/chapters/Stage2MinigameChapter.gd")

	# ミニゲーム成功後、再戦（場面6）
	b.set_flag("stage2_first_battle_done")
	b.show_band()
	b.label("stage2_battle2_start")
	b.battle("res://battle/chapters/Stage2BattleChapter.gd")
	b.label("stage2_battle2_done")

# =========================================================
# 場面7: 決着後・レイラの恨み
# =========================================================
func _build_stage2_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var layla = b.character("layla")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage2_post")
	b.background(BG_INN, 0.5)
	b.show_band()

	layla.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": LAYLA, "portrait_scale": 0.5, "position": [0, 10],
	})
	layla.band("...完敗、です。")

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_GUILTY, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	hero.band("あの、レイラさん、俺、経験の話を外に広めたりは...。")

	layla.band("...サトシ様。\n...私が、誰にも、口外せず、誰にも触れさせず、唯一、自分の矜持として\n抱えてきた部分を、貴方は、検証の場で、白日の下に、晒した。")

	layla.band("...この屈辱、忘れない。")

	layla.band("暗部への報告は「以後、介入せず」と記す。\n...公的には、貴方は、安全だ。\n...ですが、私個人は、貴方を、一生、忘れない。\n...いつか、検証ではない形で、お会いする日が、来るやも。")

	layla.leave({"exit_effect": "fade", "exit_duration": 0.6, "exit_to": "right", "wait_for_exit": true})

	pisuke.band("...サトシ、一人、終生の敵を作ったな。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("勝ったのに、なんでだよ...！")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.4, "wait_for_exit": true})

# =========================================================
# 場面8: ギルド帰還・指輪発見、それでも晴れぬ疑い
# =========================================================
func _build_stage2_close(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")
	var staff_b = b.character("staff_b")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage2_close")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.5, "side": "right", "flip": 0})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	receptionist.band("サトシ様。...暗部検証、勝利の報告、受領いたしました。")

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("はい、勝ちました。これで嫌疑、晴れましたよね！？")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...朗報がございます。B嬢の指輪、昨日、ギルド裏の廃品置き場で\n発見されました。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、見つかったんですか！？ じゃあ、事件解決じゃ...！")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.5, "side": "right", "flip": 0})
	receptionist.band("...いいえ。発見されたのは「指輪」のみ。「誰が盗んだか」は依然、\n不明でございます。")

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("でも、俺じゃないのは、もう明らかでしょう？ 検証も勝ったし！")

	receptionist.band("...それが、ギルド内で、別の見解が有力視されておりまして。")

	receptionist.band("「犯人は、暗部検証での敗北を恐れ、証拠隠滅のために指輪を廃品\n置き場に捨てた」のではないか、との推論でございます。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ええ！？ 俺が、指輪を、捨てた、って！？")

	receptionist.band("...「盗んだ本人が、責任追及を逃れるため、発見されやすい場所に\n敢えて放置する」。よくあるパターンでございます。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("それ、俺を犯人にしたいだけの、新しい話じゃ...！")

	receptionist.band("...「要監視対象A」ランク、据え置きでございます。摘要欄に追記\nいたします。\n「対象、ギルド職員に対し『綺麗だと思った』と自認。\n 盗難事件の証拠隠滅容疑、継続調査中」。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("悪意の記録！")

	staff_b.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": STAFF_B, "portrait_scale": 0.5, "position": [-100, 50],
	})

	staff_b.band("...サトシ様。指輪、見つかりました。ご丁寧に、お礼を申し上げるべき\nところ、なのでしょうね。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、いや、俺、見つけた訳じゃなくて、廃品置き場で偶然...！")

	staff_b.band("...ええ。そう、伺っております。\n...サトシ様が暗部検証に勝たれた、まさに、その日に。\n...とても、運命的な、タイミングでございましたね。")

	hero.band("い、いや、それは、本当に、偶然で...！")

	staff_b.band("...それと。「綺麗だと、一瞬、思った」というお話。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（また、それ！？）")

	staff_b.band("...私、今後、サトシ様にお会いする際、背中を向けないよう、\n注意して仕事いたします。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("背中を！？ そこまで！？")

	staff_b.band("...引き出しの中身も、念のため、毎朝、数えることに、いたしました。")

	hero.band("数える前提！？")

	staff_b.band("...カウンター裏へのご出入りも、サトシ様の場合は、別の職員を\n介する運用に、変更させていただきます。")

	hero.band("個別対応！？ 俺、一人だけ！？")

	staff_b.band("...ご理解、いただけますと。それでは、失礼いたします。")

	staff_b.leave({"exit_effect": "fade", "exit_duration": 0.5})

	hero.set_portrait(HERO_DISTANT, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ピー助、俺、ギルドの中でも、居場所、失いかけてる...。")

	pisuke.band("ゲコッ。陰謀ってのは、最初に決めた結論から、逆算して理屈を\nつけるゲームだ。\n...お前を犯人にしたい勢力が、ギルドのどこかにいる、ってだけの話だ。", {"side": "left"})

	hero.set_portrait(HERO_WEAK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("それ、俺、一人で抗うしかないの...？")

	pisuke.band("俺様は、ここにいる。一応。", {"side": "left"})

	hero.set_portrait(HERO_IRRITATE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("お前が警告しそびれた結果が、今の展開なんだよ！")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})
	receptionist.leave({"exit_effect": "fade", "exit_duration": 0.3})

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_DUSK, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})
	hero.band("（指輪は、見つかったのに、俺の容疑は、更に、強化された...。\n一体、どういう、ことだよ...！）")

	b.set_flag("stage2_complete")
