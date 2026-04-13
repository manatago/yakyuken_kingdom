extends RefCounted
class_name Subevent1Chapter

func get_sequence_builders() -> Array:
	return [
		{"id": "subevent1_pre", "builder": "_build_subevent1_pre"},
		{"id": "subevent1_post", "builder": "_build_subevent1_post"},
	]

# =============================================
# サブイベント1（前半）: 盗賊団アジト突入〜ベルカとの対面
# 場面1〜5（ベルカ戦直前まで）
# =============================================
func _build_subevent1_pre(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")
	var jin = b.character("jin")
	var marco = b.character("marco")
	var gald = b.character("gald")
	var belka = b.character("belka")

	b.set_protagonist("main")
	b.band_color("royal_blue")

	# Clear previous characters
	hero.leave({})

	# ============================================================
	# 場面1：冒険者ギルド・掲示板前
	# ============================================================
	b.label("scene_quest_board")
	b.background("res://assets/backgrounds/stage1/bg07_st1_001.png", 0.5)
	b.show_band()

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/char01_st1_006.png",
		"portrait_scale": 0.53,
		"flip": 0,
		"position": [0, 70],
	})

	hero.band("（うーん、「スライム10匹討伐」で銅貨5枚……。\n「薬草採取」で銅貨3枚……。割に合わねえ……。）")

	pisuke.band("おい、もっと上の方を見ろ。赤い紙が貼ってあるだろ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/subevent1/char01_st2_001.png", {"scale": 0.54, "side": "left", "flip": 0, "position": [0, 75]})
	hero.band("「緊急依頼：パンツ専門盗賊団『シルキーファング』の討伐」……？\n報酬……金貨50枚！？")

	pisuke.band("ゲコッ、金貨50枚ありゃ当分は食える。\nやるしかねえだろ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_025.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 69]})
	hero.band("いや待て。「パンツ専門盗賊団」って何だよ。\n……金品じゃなくてパンツだけ盗むのか？")

	pisuke.band("この世界じゃ下着にも魔力が宿るんだよ。\n特に美女の下着は闘市場で高値がつく。\n……まあ、それ以外の動機もあるんだろうがな。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 74]})
	hero.band("（パンツに魔力……。この世界の設定、どこまで本気なんだ。\n……でも金貨50枚は魅力的だ。）")

	# 受付嬢登場
	receptionist.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/char10_st1_002.png",
		"portrait_scale": 0.45,
		"flip": 0,
	})

	receptionist.band("あの……サトシ様。その依頼、おすすめしません。\nシルキーファングの首領……ベルカ・マニエラは元A級冒険者です。\n腕利きの冒険者が何人も返り討ちにされています。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_040.png", {"scale": 0.75, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、そんなに強いんですか……？")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_001.png", {"side": "right", "flip": 0})
	receptionist.band("……はい。しかも返り討ちにされた冒険者は全員、\nパンツを奪われて帰ってきました。\n……男性冒険者も、です。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("男のパンツも……？")

	receptionist.band("……ええ。ですので、この依頼は現在、\n受注者ゼロの状態が3か月続いています。")

	pisuke.band("おいおい、男のパンツまで狩るのか。\n……逆に清々しいな。平等主義だ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 74]})
	hero.band("（全然清々しくない……。でも金貨50枚は魅力的だ。）")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_008.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 65]})
	hero.band("……受けます。この依頼。")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_002.png", {"side": "right", "flip": 0})
	receptionist.band("……本気ですか？")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_017.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 65]})
	hero.band("はい。……たぶん。")
	# ピー助がサトシの声色で叫ぶ
	hero.band("パンツ盗賊を許すわけにはいかねえ！\nパンツは俺が守る！ この手で！ この目で！\n美女のパンツは俺が取り戻してやるぜ！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("！？ 俺そんなこと一言も……！")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_004.png", {"side": "right", "flip": 0})
	receptionist.band("……サトシ様。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 64]})
	hero.band("は、はい。")

	receptionist.band("……今の発言、記録しました。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("違うんです！ あれは俺じゃなくて……！\n（……って、ピー助の存在は言えない。）")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_003.png", {"side": "right", "flip": 0})
	receptionist.band("……この依頼は「盗品の回収」も含まれます。\n押収した盗品は、全てギルドに提出してください。\n……全て、です。1枚残らず。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 64]})
	hero.band("もちろんです！")

	receptionist.band("……生還をお祈りしております。\n……パンツではなく、あなたの。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（……なんで俺がパンツ目当てみたいな空気になってるんだ。\nピー助のせいだ。絶対ピー助のせいだ。）")

	receptionist.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})

	b.hide_band()

	# ============================================================
	# 場面2：王都裏通り・アジトへの道
	# ============================================================
	b.label("scene_back_alley")
	b.background("res://assets/backgrounds/prologue/bg06_prison_arena.png", 0.5)
	b.show_band()

	hero.set_portrait("res://assets/characters/stage1/char01_st1_015.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("……この辺りか。受付嬢が教えてくれた場所に向かって……。\nにしても、裏路地って昼間でも薄暗いな。")

	pisuke.band("おい、サトシ。前方に反応がある。\n……1人だ。こっちを見張ってやがる。", {"side": "left"})

	# 盗賊ジン登場
	jin.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 200,
		"portrait": "res://assets/characters/subevent1/jin_st2_001.png",
		"portrait_scale": 0.50,
		"flip": 0,
		"position": [0, 68],
	})

	jin.band("へっ、来たな冒険者。\nアジトの場所を嗅ぎつけるとは、やるじゃねえか。\nだが、ここから先は通さねえぜ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_034.png", {"scale": 0.75, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("見張り……か。")

	jin.set_portrait("res://assets/characters/subevent1/jin_st2_002.png", {"scale": 0.50, "side": "right", "flip": 0, "position": [0, 68]})
	jin.band("俺は「シルキーファング」の斥候、ジン。\n通りたきゃ俺に勝ってからにしな！")

	pisuke.band("こいつのデッキ、スキャンしたぞ。\nチョキに偏ってる典型的なスピード型だ。\n……グーで押せば楽勝だ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_040.png", {"scale": 0.75, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("はいはい。……もう驚かないよ、この展開には。")

	jin.set_portrait("res://assets/characters/subevent1/jin_st2_003.png", {"scale": 0.50, "side": "right", "flip": 0, "position": [0, 68]})
	jin.band("余裕ぶってんじゃねえぞ！\n俺の「疾風のハサミ」を食らいな！")

	hero.set_portrait("res://assets/characters/subevent1/char01_st2_001.png", {"scale": 0.54, "side": "left", "flip": 1, "position": [0, 75]})
	hero.band("（技名つけてるのか……。チョキに技名……。）")

	b.hide_band()

	# --- ランダムバトル：盗賊ジン戦 ---
	b.battle("res://battle/chapters/ThiefJinBattleChapter.gd")

	b.show_band()

	# ============================================================
	# 場面3：裏路地・さらに奥へ
	# ============================================================
	b.label("scene_back_alley_2")

	# ジン敗北
	jin.set_portrait("res://assets/characters/subevent1/jin_st2_006.png", {"scale": 0.71, "side": "right", "flip": 0})
	jin.band("ば、バカな……俺の「疾風のハサミ」が通じないだと……！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_040.png", {"scale": 0.75, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("だからチョキばっかりだって言ったのに。")

	jin.leave({
		"exit_effect": "fade",
		"exit_duration": 0.8,
		"wait_for_exit": true,
	})

	pisuke.band("ゲコッ。もう1人いるぞ。この先の角だ。\n……今度はさっきより手強い。", {"side": "left"})

	# 盗賊マルコ登場
	marco.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 200,
		"portrait": "res://assets/characters/subevent1/marco_st2_001.png",
		"portrait_scale": 0.52,
		"flip": 0,
		"position": [0, 65],
	})

	marco.band("…………。")

	hero.set_portrait("res://assets/characters/subevent1/char01_st2_001.png", {"scale": 0.54, "side": "left", "flip": 1, "position": [0, 75]})
	hero.band("……無言で立ちふさがるタイプか。")

	# marco.band("……ジンがやられたか。……俺が相手だ。")	marco.band("…………。")

	pisuke.band("こいつ、さっきのとは違うぞ。デッキのバランスがいい。\nグー・チョキ・パーが均等に入ってる。\n……偏りがないから、ベイズ・アイでも読みにくい。\n慎重にいけ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_044.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（バランス型か……。偏りがない相手は確率で優位を取りにくい。\nこういう時こそ、相手の「癖」を観察するんだ。）")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("……行くぞ。")

	marco.band("…………。")

	b.hide_band()

	# --- ランダムバトル：盗賊マルコ戦 ---
	b.battle("res://battle/chapters/ThiefMarcoBattleChapter.gd")

	b.show_band()

	# マルコ敗北
	marco.set_portrait("res://assets/characters/subevent1/marco_st2_002.png", {"scale": 0.84, "side": "right", "flip": 0, "position": [0, 65]})
	marco.band("…………。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_040.png", {"scale": 0.75, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("なんか、言えよ。ていうか、前を隠せよ...")

	marco.leave({
		"exit_effect": "fade",
		"exit_duration": 0.8,
		"wait_for_exit": true,
	})

	pisuke.band("2人片付けた。あとはアジトの中だ。\n……残り2人と、首領だな。気を引き締めろ。", {"side": "left"})

	b.hide_band()

	# ============================================================
	# 場面4：盗賊団のアジト前
	# ============================================================
	b.label("scene_hideout_entrance")
	b.show_band()

	hero.set_portrait("res://assets/characters/stage1/char01_st1_015.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("ここがアジトか。……思ったよりちゃんとした建物だな。")

	pisuke.band("中に3人だ。副首領のガルドと、もう1人の構成員。\nそれと首領。……正面から行くのか？", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 74]})
	hero.band("いや、まずは様子を見よう。潜入して……")

	# ピー助がサトシの声で叫ぶ
	# hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("(ピー助)おーい！ シルキーファングのド変態ども！\n天下のサトシ様が来てやったぞ！\nパンツ返してもらおうか！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("！？ おまっ……またか！！")

	# ガルド登場
	gald.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 200,
		"portrait": "res://assets/characters/subevent1/gald_st2_001.png",
		"portrait_scale": 0.53,
		"flip": 0,
	})

	gald.band("あぁん？ 誰だてめえ。\n……ひとりで来たのか？ 度胸あるな。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 64]})
	hero.band("あ、いや、これは誤解で……。")

	gald.set_portrait("res://assets/characters/subevent1/gald_st2_002.png", {"scale": 0.50, "side": "right", "flip": 0, "position": [0, 62]})
	gald.band("「ド変態」だと？ 俺たちは「美学の追求者」だ！\nパンツは芸術だろうが！！")

	pisuke.band("……芸術って言い張るタイプか。面倒くせえ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（自分でも分かってるだろ、犯罪だって……。）")

	gald.set_portrait("res://assets/characters/subevent1/gald_st2_002.png", {"scale": 0.50, "side": "right", "flip": 0, "position": [0, 62]})
	gald.band("てめえ、冒険者ギルドの刺客か。\n上等だ。ここで俺と勝負しろ！\n負けたらてめえのパンツ、いただくぜ！")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("俺のパンツに何の価値が……。")

	gald.set_portrait("res://assets/characters/subevent1/gald_st2_002.png", {"scale": 0.50, "side": "right", "flip": 0, "position": [0, 62]})
	gald.band("パンツに貴賤なし！ それがシルキーファングの掟だ！")

	pisuke.band("……掟にすんなよ。まあいい、こいつは雑魚だ。\nデッキをスキャンしたが、脳筋タイプだ。グーばっかり。\nベイズ・アイで楽勝だぞ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_021.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("……はぁ。今日何回目だこの展開。\nいいよ、来いよ。")

	b.hide_band()

	# --- ランダムバトル：ガルド戦 ---
	b.battle("res://battle/chapters/ThiefGaldBattleChapter.gd")

	b.show_band()

	# ガルド敗北
	gald.set_portrait("res://assets/characters/subevent1/gald_st2_003.png", {"scale": 0.50, "side": "right", "flip": 0})
	gald.band("バカな……俺の手が全部読まれてる……。\nお、お頭ぉぉぉ！ 助けてくだせえ！")

	# ============================================================
	# 場面5：アジト内部・突入
	# ============================================================
	b.label("scene_hideout_interior")

	b.narrator_band("サトシはガルドを退け、アジトの中へ足を踏み入れた。\n薄暗い倉庫の中は、壁一面に額縁入りのパンツが飾られていた。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_004.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("……うわ。壁にパンツが飾ってある。しかも額縁入り。\n……美術館かよ。")

	pisuke.band("「パンツ・ギャラリー」だな……。\n作品名のプレートまで付いてやがる。\n「朝露に濡れたシルク」「黄昏のレース」……。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_044.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("（タイトルのセンスだけは認めざるを得ない……いや、認めちゃダメだ。）")

	# ピー助がサトシの声で感嘆
	# hero.set_portrait("res://assets/characters/stage1/char01_st1_004.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("(ピー助)すげえ……！ この保存状態、プロの仕事だ……！\n湿度管理まで完璧じゃねえか……！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("俺は一言も感心してない！ やめろ！")

	# ベルカ登場
	b.narrator_band("奥の扉が開いた。\nショートカットの少女が現れる。小柄だが目つきが鋭い。\nダボっとした盗賊コートを羽織り、ブーツで床を鳴らしながら歩いてくる。")

	belka.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 200,
		"portrait": "res://assets/characters/subevent1/belka_st2_001.png",
		"portrait_scale": 0.41,
		"flip": 0,
	})

	belka.band("……うっさいな。何の騒ぎだよ。")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_002.png", {"scale": 0.49, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("ジンもマルコもガルドもやられたって？\n……ひとりで？ マジで？\n……あんた、ギルドの冒険者？\nなんか頼りなさそうだけど……。")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_003.png", {"scale": 0.49, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("……ふーん。ボクのギャラリー、じっくり見てたろ。\nさっき聞こえたぜ。「保存状態がプロの仕事」だって？")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("それは俺じゃなくて……！")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_005.png", {"scale": 0.49, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("あんたしかいないだろ、ここに。\nへへ、でも嬉しいね。分かるヤツがいるとさ。\n湿度管理とか、苦労してんだよあれ。")

	pisuke.band("おい、こいつヤバいぞ。チップのデータ、相当なもんだ。\n元A級冒険者ってのは本当だ。カードの質も高い。\n……見た目に騙されるなよ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_020.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 61]})
	hero.band("（ピー助の存在を説明できない……。\nでも否定すると「じゃあ誰が言ったの？」ってなるし……。\n……詰んでる。）")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_015.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、えっと……シルキーファングの首領さんですか？\nパンツ泥棒をやめるように……。")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_006.png", {"scale": 0.49, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("「パンツ泥棒」？")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_001.png", {"scale": 0.49, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("……ボクたちは「解放」してるんだよ。\nこの窮屈な社会で、布一枚に縛られた人々の魂をね。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（いや、縛ってるのはパンツのゴムだけだろ……。）")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_007.png", {"scale": 0.49, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("ボクのコレクション、見たろ？\nあれは「解放された魂の結晶」だ。\n芸術が分かんないヤツは帰りな。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("盗んだパンツを額縁に入れてるだけでは……。")

	# belka.set_portrait("res://assets/characters/subevent1/belka_st2_001.png", {"scale": 0.5, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("「額装」って言え。")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_008.png", {"scale": 0.49, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("……面白いヤツだね。部下を3人も倒してここまで来るとか、\nしかもコレクションの良さが分かる目も持ってるし。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("分かってない！ 鑑賞もしてない！")

	# belka.set_portrait("res://assets/characters/subevent1/belka_st2_001.png", {"scale": 0.5, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("ルールは簡単だ。ボクに勝ったら盗賊団を解散してやるよ。\nでも負けたら……あんたのパンツだけじゃ済まないぜ？\n……冒険者証も、もらうから。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 16]})
	hero.band("冒険者証まで！？ それは困る……。")

	pisuke.band("落ち着け。ベイズ・アイでデータを取れ。\nこいつのデッキは読み型だ。こっちの癖を分析して対応してくる。\nさっきまでの3戦でお前の癖を部下に分析させてた可能性がある。\n……序盤でわざとパターンを見せて、途中で切り替えろ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 74]})
	hero.band("（なるほど……部下との戦いはデータ収集も兼ねてたのか。\n偽の癖を見せて、裏をかく。\n数学的に言えば「ベイジアン・トラップ」だ。）")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("……いいですよ。受けて立ちます。")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_001.png", {"scale": 0.49, "side": "right", "flip": 0, "position": [0, 61]})
	belka.band("へっ、いい目じゃん。……さあ、始めようぜ。")

	b.hide_band()

	# --- イベントバトル：ベルカ戦 ---
	b.label("subevent1_boss_battle")
	b.battle("res://battle/chapters/Stage2BattleChapter.gd")

# =============================================
# サブイベント1（後半）: ベルカ戦決着後〜ギルド帰還
# 場面6〜7
# =============================================
func _build_subevent1_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")
	var belka = b.character("belka")
	var guard = b.character("guard")

	b.set_protagonist("main")
	b.band_color("royal_blue")

	# ============================================================
	# 場面6：アジト内部・決着後
	# ============================================================
	b.label("scene_hideout_aftermath")
	b.background("res://assets/backgrounds/prologue/bg06_prison_arena.png", 0.0)
	b.show_band()

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_009.png", {"scale": 0.5, "side": "right", "flip": 0, "position": [0, 68]})
	belka.band("……うそだろ。ボクが……負けるなんて。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_046.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 9]})
	hero.band("……勝った。")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_010.png", {"scale": 0.5, "side": "right", "flip": 0, "position": [0, 68]})
	belka.band("……ふーん。あんた、何者だよ。\nまるで、確率が見えてるみたいだった。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_034.png", {"scale": 0.75, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("いや、まあ、ちょっとした数学の応用です。")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_011.png", {"scale": 0.5, "side": "right", "flip": 0, "position": [0, 68]})
	belka.band("約束は守るよ。シルキーファングは今日で解散だ。\n盗品も返す。……騎士団、呼べばいいよ。")

	pisuke.band("よし、依頼は達成だ。", {"side": "left"})

	b.narrator_band("しばらくして、番兵が駆けつけてくる。")

	# 番兵登場
	guard.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/subevent1/guard_st2_001.png",
		"portrait_scale": 0.46,
		"flip": 0,
	})

	guard.band("通報を受けて来た。現場はここか。……ん？")

	b.narrator_band("番兵がサトシの顔をまじまじと見る。")

	guard.set_portrait("res://assets/characters/subevent1/guard_st2_002.png", {"scale": 0.43, "side": "right", "flip": 0, "position": [0, 62]})
	guard.band("……お前、あの時の露出狂の変態じゃねえか！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 16]})
	hero.band("！？\nあ、あなた……あの時の番兵さん……！？")

	guard.set_portrait("res://assets/characters/subevent1/guard_st2_003.png", {"scale": 0.43, "side": "right", "flip": 0, "position": [0, 62]})
	guard.band("今度はパンツ盗賊団のアジトだと？\n……お前、順調に人生を踏み外してるな。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ち、違います！ 俺は討伐依頼を受けて……！")

	# ベルカが番兵に話しかける
	belka.set_portrait("res://assets/characters/subevent1/belka_st2_012.png", {"scale": 0.5, "side": "right", "flip": 0, "position": [0, 68]})
	belka.band("なあ、おっさん。ちょっといいかい？")

	guard.set_portrait("res://assets/characters/subevent1/guard_st2_001.png", {"scale": 0.43, "side": "right", "flip": 0, "position": [0, 62]})
	guard.band("……なんだ、女盗賊。")

	belka.set_portrait("res://assets/characters/subevent1/belka_st2_012.png", {"scale": 0.5, "side": "right", "flip": 0, "position": [0, 68]})
	belka.band("ボクを倒したあいつ、すげえ奴だぜ。\nボクのコレクション見て、「プロの仕事だ」「湿度管理が完璧だ」って\n保存状態を絶賛してたよ。\n……捕まえるなら、ボクじゃなくてあいつの方かもな？")

	guard.set_portrait("res://assets/characters/subevent1/guard_st2_004.png", {"scale": 0.43, "side": "right", "flip": 0, "position": [0, 62]})
	guard.band("……ほう、ほう。興味深い証言だな。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("言ってない！ 俺はそんなこと一言も……！")

	guard.set_portrait("res://assets/characters/subevent1/guard_st2_005.png", {"scale": 0.43, "side": "right", "flip": 0, "position": [0, 62]})
	guard.band("ふん。……露出狂の次はパンツ鑑定士か。\n報告書は正式に提出しておく。\n「要注意人物」として、な。")

	belka.leave({
		"exit_effect": "fade",
		"exit_duration": 0.5,
		"wait_for_exit": false,
	})

	guard.leave({
		"exit_effect": "fade",
		"exit_duration": 0.5,
		"wait_for_exit": true,
	})

	b.hide_band()

	# ============================================================
	# 場面7：ギルド帰還
	# ============================================================
	b.label("scene_guild_return")
	b.background("res://assets/backgrounds/stage1/bg07_st1_001.png", 0.5)
	b.show_band()

	receptionist.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/char10_st1_001.png",
		"portrait_scale": 0.45,
		"flip": 0,
	})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_003.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})

	receptionist.band("サトシ様。盗賊団討伐の報酬です。金貨50枚。\n……お見事でした。")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_004.png", {"side": "right", "flip": 0})
	receptionist.band("……それと、騎士団から報告書が届いています。\nベルカ・マニエラの供述と、現場責任者の番兵からの所見……\n「当該冒険者サトシ、過去に全裸での不敬罪連行歴あり。\n　今回の件と合わせ、要注意人物として記録する」と。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 16]})
	hero.band("あ、あの番兵さん……俺のこと覚えてて……！")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_003.png", {"side": "right", "flip": 0})
	receptionist.band("……過去の露出歴、コレクション鑑賞の証言。\n……合計2件の記録です。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("違うんです！ 全部誤解で！")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_003.png", {"side": "right", "flip": 0})
	receptionist.band("……金貨50枚、確かにお渡ししました。\n……次の依頼もお待ちしております。\n……犯罪歴がつかない範囲で。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_028.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("（パンツ盗賊団を壊滅させた英雄のはずなのに……\nなんであの番兵がまた来るんだ……運が悪すぎる……。）")

	pisuke.band("ゲコッ。まあ、金は稼げたな。次の仕事を探すぞ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_047.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 9]})
	hero.band("（お前のせいだからな。全部お前のせいだからな。）")

	receptionist.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})

	hero.leave({
		"exit_effect": "fade_slide",
		"exit_to": "left",
		"exit_duration": 0.8,
		"wait_for_exit": true,
	})
