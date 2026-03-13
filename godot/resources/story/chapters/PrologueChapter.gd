extends StoryChapterBase
class_name PrologueChapter

const StoryCharacterHandle := preload("res://resources/story/dsl/StoryCharacterHandle.gd")

func get_sequence_builders() -> Array:
	return [sequence_builder("prologue", "_build_prologue")]

func _build_prologue(b):
	# b は StoryDsl.build() から渡されるビルダープロキシで、背景・台詞などを登録するための DSL エントリポイント。
	var hero: StoryCharacterHandle = b.character("main")
	var heroine: StoryCharacterHandle = b.character("heroine")
	var receptionist: StoryCharacterHandle = b.character("receptionist")
	var passerby_male: StoryCharacterHandle = b.character("passerby_male")
	var passerby_female: StoryCharacterHandle = b.character("passerby_female")
	var guard: StoryCharacterHandle = b.character("guard")
	var matilda: StoryCharacterHandle = b.character("matilda")

	b.set_protagonist("main")
	# 内部バンドの色を設定（プリセット: StoryDsl.gd の _band_colors を参照）
	b.band_color("royal_blue")

	b.background("res://assets/backgrounds/bg01_university.png", 0.5)
	b.show_band()
	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "bottom",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_000.png",
		"portrait_scale": 1.0,
		"position_mode": "offset",
		"position": Vector2(0, 0),
	})
	b.narrator_band("5月の大学キャンパス。")
	b.narrator_band("主人公のサトシは、数学が得意で、国内No1の大学の数学科に在籍しているが、大学をサボってエロゲー三昧のアホ学生だ。")
	b.narrator_band("性的興奮を刺激し、少子化を解決する施作として野球拳をオリンピック競技にする政治活動をしているが、賛同者はエロ男子大学生のみ。")
	hero.leave({
		"exit_effect": "fade_slide",
		"exit_to": "left",
		"exit_duration": 0.8,
	})

	heroine.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "bottom",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char02_pg_000.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, 0),
	})
	b.narrator_band("一方、幼馴染の女の子は有名私大の弁論サークルに所属しており、政治家秘書のバイトをやっており、将来は政治家を目指している。弁論大会で多数の受賞歴を誇る。")
	b.narrator_band("彼女は密かに主人公に思いを寄せているが、才能の無駄遣いをしている彼を呆れ顔で見つめる、典型的なツンデレタイプ。")
	heroine.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_001.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, 0),
	})
	# ── 場面2：みのりとの会話 ──
	hero.set_portrait("res://assets/characters/prologue/char01_pg_002.png", 0.5)
	hero.band("今日も数理モデルの講義をバックレたった...")
	heroine.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char02_pg_001.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, 100),
	})
	heroine.band("あ、サトシ。こんなとこでブラブラして……また講義サボったでしょ。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_003.png", 0.5)
	hero.band("みのり？ なんでこっちにいんの。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_002.png", 0.5)
	heroine.band("秘書のバイト先がこっち方面なの。で、サボりでしょ？")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_004.png", 0.5)
	hero.band("サボりじゃない。戦略的欠席だ。本気出せば主席でもいけるけどな。\n『異世界野球拳をオリンピック競技にする会』でかかりきりやし。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_003.png", 0.5)
	heroine.band("その「本気出せば」、入学してから何回聞いたと思ってるの。\nもう三年目よ？")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_005.png", 0.5)
	hero.band("ロマンを追う以外にどうやって青春を燃やせってんだ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_004.png", 0.5)
	heroine.band("ロマン？ 署名が12人しか集まってない活動のどこがロマンなの。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_006.png", 0.5, 0.3, Vector2(25, 0))
	hero.band("12人の同志な。革命はいつだって少数から始まるんだよ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_005.png", 0.5)
	heroine.band("……はぁ。あんた去年も単位落としてたでしょ。\nもう後がないんじゃないの？")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_007.png", 0.5, 0.3, Vector2(25, 0))
	hero.band("へーきへーき。なんとかなるって。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_006.png", 0.5)
	heroine.band("……なんとかなったこと、一度もないじゃない。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_007.png", 0.5)
	heroine.band("あっ、もう行かなきゃ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_008.png", 0.5, 0.3, Vector2(150, 200))
	heroine.band("いい、今年こそ単位をちゃんととるのよ。")
	heroine.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})
	hero.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})

	b.background("res://assets/backgrounds/bg02_room.png", 0.5)
	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_008.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, 0),
	})
	# hero.set_portrait("res://assets/characters/prologue/char01_pg_008.png", 0.5)
	hero.band("（部屋はエロゲ箱と政治パンフと教科書の雪崩。俺の人生を縮図みたく語ってくれるインスタレーションアートだ。）")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_009.png", 0.5)
	hero.band("けど……単位があと三つ足りないのはガチで笑えない。目の前の編集済みセーブデータより、現実の単位をロードし直さないと。")

	b.narrator_band("スマホが震えた。みのりからのメッセージだ。")

	heroine.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 1.6,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char02_pg_009.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, -300),
		"flip": 0,
	})
	heroine.band("あんたの大学のサイトに出てたけど、「大型加速器実験補助、履修認定あり」って募集、知ってる？締切明日までだって。")
	# heroine.set_portrait("res://assets/characters/prologue/char02_pg_009.png", 0.6, 0.3, Vector2(150, 50))
	heroine.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})
	hero.set_portrait("res://assets/characters/prologue/char01_pg_010.png")
	hero.band("……なんでお前が俺の大学の掲示板チェックしてんだよ。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_011.png")
	hero.band("とは打てずに、「調査済み✌」とだけ返した。かっこわる。……ていうか全然調査してなかった。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_012.png")
	hero.band("掲示板……あった。ギリギリ滑り込むしかない。")
	hero.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})

	b.background("res://assets/backgrounds/bg03-1_lab.png", 0.5)

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_013.png",
		"portrait_scale": 0.7,
		"position_mode": "offset",
		"position": Vector2(0, 0),
	})
	hero.band("ここが噂の研究施設……SPring-8にそっくりじゃないか。")

	receptionist.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char03_pg_001.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, 0),
		"flip": 0,
	})
	receptionist.band("学生さん？ 実験補助のバイトね。はい、これ白衣と防護メガネ。")
	receptionist.set_portrait("res://assets/characters/prologue/char03_pg_002.png", 0.5, 0.3, null, "cross_fade", 0)
	hero.set_portrait("res://assets/characters/prologue/char01_pg_014.png", 0.5)
	hero.band("あ、どうも。えっと、具体的に何をすれば……")
	receptionist.set_portrait("res://assets/characters/prologue/char03_pg_003.png", 0.5, 0.3, null, "cross_fade", 0)
	receptionist.band(" 簡単よ。制御室に入って、合図があったらボタンを押すだけ。それ以外は絶対に触らないでね。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_015.png", 0.5)
	hero.band("ボタン一個で単位もらえるとか、最高のバイトじゃないすか。")
	receptionist.set_portrait("res://assets/characters/prologue/char03_pg_004.png", 0.5, 0.3, null, "cross_fade", 0)
	receptionist.band("ふふ、みんなそう言うわ。でもね、ここの装置、ちょっと気まぐれなの。何かあったらすぐ赤いボタンを押して。非常停止だから。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_016.png", 0.5)
	hero.band("（心の声）フラグ立ってる感がすごいんだが。")

	receptionist.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})
	hero.leave({
		"exit_effect": "fade_slide",
		"exit_to": "left",
		"exit_duration": 0.8,
	})

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_017.png",
		"position_mode": "offset",
		"position": Vector2(0, -20),
	})
	# hero.set_portrait("default_white_coat")
	hero.band("数式中毒の俺からしたら、計測ログの生データに触れるだけでご褒美だ。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_018.png", 0.5)
	hero.band("これで単位を確保して、堂々と署名活動に専念――っと")
	b.clear_band_text() # バンドテキストをクリア



	b.background("res://assets/backgrounds/bg03-2_lab.png", 0.4)
	hero.set_portrait("res://assets/characters/prologue/char01_pg_019.png", 0.5)
	hero.band("うわっ！")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_020.png", 0.5)
	hero.band("赤いボタン～～どこ～!?")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_021.png", 1.2, 0.3, Vector2(0, 50))
	hero.band("制御盤が真っ白になってる!? 聞いてないぞ、こんなフラッシュ！\nひっ、ひぃ～")

	# hero.animate_portrait([
	# 	"res://assets/characters/ch01-101_white_coat_surprise.png",
	# 	"res://assets/characters/ch01-102_white_coat_surprise.png",
	# 	"res://assets/characters/ch01-101_white_coat_surprise.png"
	# ], 0.08, 1)
	# await b.pause(0.3)

	# hero.hide_dialogue()
	# hero.set_portrait("default_white_coat_surprise")
	hero.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})

	hero.appear({
		"side": "center",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_022.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(50, -300),
	})
	hero.band("（身体の輪郭が空気に溶ける。慣性も重力も感じない。加速器って、テレポーターだったのかよ……！）")
	hero.leave({
		"side": "center",
		"exit_effect": "shrink",
		"exit_duration": 0.6,
		"wait_for_exit": true
	})

	b.background("res://assets/backgrounds/bg04-1_teleport_square.png", 0.5)
	hero.appear({
		"side": "center",
		"appear_effect": "fade_grow",
		"appear_duration": 1.2,
		"portrait": "res://assets/characters/prologue/char01_pg_023.png",
		"portrait_scale": 0.3,
		"position": Vector2(0, -400),
		"wait_for_input": false
	})

	hero.band("うわぁぁぁぁ")

	hero.leave({
		"side": "center",
		"exit_effect": "fade_slide",
		"exit_to": "bottom",
		"exit_duration": 1.2,
		"wait_for_exit": true
	})


	b.background("res://assets/backgrounds/bg04-2_teleport_square2.png", 0.5)
	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "bottom",
		"appear_duration": 1.2,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_024.png",
		"portrait_scale": 0.55,
		"position_mode": "offset",
		"position": Vector2(0, -0),
	})
	hero.band("いてて……。石畳……？ 城壁に塔……ここ、どこだ？")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_025.png", 0.55)
	hero.band("なんか中世ヨーロッパみたいな街だな。コスプレイベント？:\nいや、空気が違う。匂いも……リアルすぎる。")
	passerby_female.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char05_pg_001.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, 0),
		"flip": 0,
	})
	passerby_female.band("きゃあああ！ へ、変態！！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_026.png", 1.0, 0.3, Vector2(0, 50))
	hero.band("えっ？")
	passerby_female.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_027.png", 0.6)
	hero.band("……うわっ、裸!? 俺、裸じゃねーか！")
	passerby_male.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char06_pg_001.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, 0),
		"flip": 1,
	})
	passerby_male.band("おい誰か捕まえろ！ 白昼堂々、王都の広場でとんでもない奴だ！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_028.png", 0.6, 0.3, null, "cross_fade", 1)
	hero.band("待って、違うんです！ これは事故で――")
	passerby_male.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})
	hero.set_portrait("res://assets/characters/prologue/char01_pg_029.png", 0.6, 0.3, null, "cross_fade", 1)
	b.narrator_band("弁解むなしく、サトシは通行人たちに取り押さえられた。")

	guard.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char04_pg_001.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": Vector2(0, 0),
	})
	guard.band("何の騒ぎだ。……おい、そこの露出狂の変態！ 何してやがる。")


	hero.set_portrait("res://assets/characters/prologue/char01_pg_030.png", 0.6, 0.3, null, "cross_fade", 1)
	hero.band("スプリングエイトで実験してたら、急に周りが真っ白になって。。。")
	guard.set_portrait("res://assets/characters/prologue/char04_pg_002.png", 0.5, 0.3, null, "cross_fade", 1)
	guard.band("何言ってやがる。変態なうえに、気がくるっているのか？")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_031.png", 0.6, 0.3, null, "cross_fade", 1)
	hero.band("いや待って、ここどこですか？ 日本……だよな？")
	guard.set_portrait("res://assets/characters/prologue/char04_pg_003.png", 0.5, 0.3, null, "cross_fade", 1)
	guard.band("ニホン？ 何を寝ぼけてやがる。ここはヤクケン王国の王都アレクシアだ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_032.png", 1.05, 0.3, null, "cross_fade", 1)
	hero.band("ヤクケン王国……？ マジの異世界じゃねーか")
	guard.set_portrait("res://assets/characters/prologue/char04_pg_004.png", 0.5, 0.3, null, "cross_fade", 1)
	guard.band("おい聞いてんのか！ 王都のど真ん中で裸とは、不敬罪もいいところだ。ちょっとこっちに来い！")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_033.png", 1.05)
	hero.band("ちょっ、まっ、まって。いたい、いたい、、、")

	b.narrator_band("サトシは、番兵に有無を言わさず連れていかれた。")
	hero.leave({
		"side": "left",
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 1.2,
		"wait_for_exit": true
	})
	guard.leave({
		"side": "right",
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 1.2,
		"wait_for_exit": true
	})

	b.background("res://assets/backgrounds/bg05_prison_cell.png", 0.5)
	b.narrator_band("サトシが気が付くと、そこは牢の中だった。服が着せられていた。")

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "bottom",
		"appear_duration": 1.2,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_034.png",
		"portrait_scale": 0.7,
		"position_mode": "offset",
		"position": Vector2(0, 0),
	})

	hero.band("いてててて。あれっ、ここはどこだっけ。確か昨日はバイト先で光の渦に飲み込まれて、気が付いたら裸だったんだ。")
	hero.band("あの番兵、えらい怒っていたよな。すごい剣幕だった。しかし、人を変態呼ばわりしやがって。俺は被害者だっちゅーの")
	hero.band("しかし、ここはどこだ？日本語が通じるから日本？でも街の風景は異世界転生のまんまじゃね？")

	matilda.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char07_pg_001.png",
		"portrait_scale": 0.45,
		"position_mode": "offset",
		"position": Vector2(0, 10),
	})
	matilda.band("起きたか、変態。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_035.png", 0.7)
	hero.band("俺は変態じゃな。。。おっ、きれいなねーさんだな。おっぱいもでかい。。。")
	matilda.set_portrait("res://assets/characters/prologue/char07_pg_002.png", 0.65, 0.3, Vector2(-100, 10), "cross_fade", 0)
	matilda.band("おいおい、いやらしい目で見やがって。ほんとに変態ってやつは、どうしようもないな。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_036.png", 0.49)
	hero.band("ぐぬぬ。。。")

	b.narrator_band("変態の濡れ衣を着せられて悔しい思いをしたサトシだったけど、なんといっても牢屋に入れられている身。おとなしくするしかない")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_001.png", 0.45, 0.3, Vector2(0, 10), "cross_fade", -1)
	matilda.band("さて、変態の身元調査といこうか。\n変態、お前の名前は？ どこから来た。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", 0.5, 0.3, null, "cross_fade", 1)
	hero.band("(また変態って...)\nサトシ...です。日本ってところから来た？と思います。")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_003.png", 0.45, 0.3, Vector2(-80, 0), "cross_fade", -1)
	matilda.band("ニホン？ 聞いたことないね。この大陸の国じゃないのは確かだ。\n……まあ、異界渡りってやつかい。珍しいけど、前例がないわけじゃない。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", 0.5, 0.3, null, "cross_fade", 1)
	hero.band("異界渡り……？ そういう概念があるんですか。\nあの、ヤクケン王国って番兵の人が言ってたんですけど、ここは一体どういう国なんですか？")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_001.png", 0.45, 0.3, Vector2(0, 10), "cross_fade", -1)
	matilda.band("あんた本当に何も知らないんだね。\nこの大陸で一番でかい国さ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", 0.5, 0.3, null, "cross_fade", 1)
	hero.band("国の名前からして嫌な予感しかしないんですけど……。")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_004.png", 0.45, 0.3, Vector2(-200, 10), "cross_fade", -1)
	matilda.band("質問の前に、まずは身体検査だ。\n牢に入る奴は全員やる決まりでね。じっとしてな。")

	b.narrator_band("マチルダが手のひらをサトシの額にかざすと、淡い光が走った。\nだが――")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_005.png", 0.65, 0.3, Vector2(-100, 10), "cross_fade", -1)
	matilda.band("……エラー？ IDが存在しない……？\nまさか、脳にチップが入っていないの！？")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", 0.5, 0.3, null, "cross_fade", 1)
	hero.band("チップ？ 脳に？ な、なんの話ですか？")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_006.png", 0.45, 0.3, Vector2(-120, 0), "cross_fade", 0)
	matilda.band("この世界の住人は、生まれた時に識別チップを脳に埋め込まれるんだ。身分証であり、戦闘システムへのインターフェースでもある。それがないってことは……本当に異界の人間なんだね、あんた。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_040.png", 0.7, 0.3, null, "cross_fade", 1)
	hero.band("だから最初からそう言ってるじゃないですか……。")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_007.png", 0.65, 0.3, Vector2(-120, 10), "cross_fade", 0)
	matilda.band("……しょうがないね。特例だ。")
	b.narrator_band("マチルダは懐から小さな注射器のようなものを取り出した。")
	matilda.band("  旧式の汎用チップだけど、ないよりマシさ。うなじを出しな。ちょっとチクっとするよ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_041.png", 0.7, 0.3, null, "cross_fade", 1)
	hero.band("えっ、ちょ、いきなり注射!? 説明――いっっっ!!")

	b.narrator_band("マチルダに無理やり注射をされて、サトシのうなじに激痛が走った...")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_042.png", 0.5, 0.3, null, "cross_fade", 1)
	hero.band("いって――――――――――――ぇ。まじ、なんなの...")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_001.png", 0.45, 0.3, Vector2(0, 10), "cross_fade", -1)

	matilda.band("だらしないな、女みたいにビービー泣いてないで、心の中で、テーブルオープンって行ってみろ")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", 0.5, 0.3, null, "cross_fade", 1)
	hero.band("(なっ、なんだよ、自分だって女のくせに。うっ、睨まれている。\nテッ、テッ、テーブル...オープン)")

	b.narrator_band("サトシが心のなかで「テーブルオープン」と言った瞬間、視界が一変した")

	# b.background("res://assets/backgrounds/bg05_prison_cell.png", 0.5)
	b.background("res://assets/backgrounds/bg05_prison_cell.png", 0.5)

	# matilda.say("おいそこの新入り。ここは牢獄前闘技場だ。勝率を見せな。")
	# hero.say("（すらっとした女看守。肩章からして階級も高い。いきなりラスボスの風格じゃないか。）", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("名前は？　出身ギルドは？")
	# hero.say("ギルド……？　いや、俺は――", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})

	# matilda.say("まあいい。ここに現れたってことは、皇女様に挑む資格を求めてるんだろ。だったら証拠を見せな。")
	# hero.say("皇女？　いや、俺は単位が欲しいだけで――")
	# matilda.say("異世界に飛ばされた学生さん、って顔してるな。だがここでは勝率が身分証だ。野球拳で四連勝すれば、ギルド通りに出る権利をやる。")
	# hero.say("野球拳!?　異世界でも健在なのかよ！　俺に任せな。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})

	# matilda.say("任せる？　ふふ、大口叩くね。私はマチルダ、牢番の門番。勝率を操作する術も訓練されてる。")
	# hero.say("勝率の操作……それ、まさに俺が大学で研究してたやつだ。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# hero.say("（HUDに『数値化』のアイコン。どうやらスキルスロットに予備動作が入っている。今すぐ覚醒しそうだ。）", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("どうした、固まって。初めての異世界は眺めるだけで精一杯か？")
	# hero.say("いや……俺、まさかの異世界野球拳の主人公……！")

	# matilda.say("落ち着け。深呼吸だ。ここでは冷静さも勝率に影響する。")
	# hero.say("（呼吸を整えると、HUDから数式が浮かび上がった。『確率計算』スキルが解禁されたみたいだ。）", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# hero.say("これで勝率の最適化ができる。まずはお姉さんを倒して、ギルド通りへ行く。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("お姉さん？　ふふ、面白い。いいだろう、数値の勇者さん。", {"portrait": "res://assets/characters/char04-1_prison_guard.png"})
	# matilda.say("ただし一度勝ったくらいで調子に乗ると、すぐ丸裸だ。ここの観衆は勝率の上下に飢えてるからね。")
	# hero.say("そっちの勝率も味わってもらうさ。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})

	# b.background("res://assets/backgrounds/bg05_prison_cell.png", 0.5)
	# matilda.say("控室へ連れていこう。そこでスキルチュートリアルをやる。")
	# hero.say("スキルチュートリアル……俺のMMO脳がうずく。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("はい、これが『確率計算』の第1段階。手札の勝率をざっくり表示する。使えば期待値がわかるよ。")
	# hero.say("スキル、いきなり渡してくれるの？")
	# matilda.say("私は門番で先生役。ここで変に詰まられたら仕事が増えるだろ？")
	# hero.say("親切なんだか効率厨なんだか。ともあれサンキュー。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})

	# matilda.say("さっそく勝率を見てみな。恐怖で手が震えてたらゼロに近づくし、落ち着けば盛り返す。自分の入力で上下してんのがわかるだろ。")
	# hero.say("ほんとだ、心拍数も連動してる。これが異世界か……。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("ここからは地道な練習。カードを1枚ずつめくって、勝率の上がり下がりを身体に覚えさせな。")
	# b.show_band()
	# b.narrator_band("こうして主人公は勝率チュートリアルで汗を流し、本命の異世界野球拳ロードへと踏み出す。")
	# hero.say("なるほど。HUDがレベルアップの階段みたいにつながってる。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("1段登るごとに『計算バフ』が解禁される。勝率予測→確率計算→真の確率計算→完全予測って感じ。")
	# hero.say("完全予測って、いわゆる『このカードを出せば勝つ』ってやつだな。そこまで行けば異世界野球拳の覇王も夢じゃない。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})

	# matilda.say("覇王？　はは、威勢がいい。そこまで行けりゃ皇女様にも会えるだろうね。")
	# hero.say("皇女に勝って、異世界の国王になって、異世界スポーツ庁を作って、野球拳を国技にする。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("夢はでかい方がいい。けどまずはこの牢番を納得させな。")
	# hero.say("望むところだ。")
	# matilda.say("というわけで実戦チュートリアルだ。闘技スペースに戻ろう。")
	# hero.say("うお、HUDがポップアップしてる！　次は『確率計算』、そのあと『真の確率計算』、最終的にはオートで最適手を出せる――みたいな階段ってわけだな。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("そこまで行けりゃ、ギルドの四天王にも挑戦できる。シスター、格闘家、宮廷魔術師、騎士団長……そいつらを野球拳で倒した者だけが皇女様への謁見を許される。")
	# hero.say("皇女まで倒して、国王になればこの世界の設計者に会えるかも。よし、目標設定は完了だ。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})

	# matilda.say("ただし牢番の私を突破できなきゃ話にならない。勝けばギルド通りへ出る許可を出してやる。負ければ、しばらく私のおもちゃ。どうする？")
	# hero.say("（ムチムチなお姉さんに弄ばれるのも嫌いじゃないが……ここで勝って第一歩を刻む。）", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("あんたが最初のボスってわけか。望むところだ。数値化スキルで勝率を叩き出してやる。")
	# matilda.say("いい覚悟。でも油断するな。私は正規の門番、カード運用にも自信がある。")
	# hero.say("こっちもCPU戦はSwitchで散々こなしたんでね。実戦で腕試しといこう。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})
	# matilda.say("じゃあ牢前の闘技スペースへ。白いリングが描かれた場所で、服を賭けて踊りな。")
	# hero.say("異世界野球拳、開幕だ。", {"portrait": "res://assets/characters/ch01-200_isekai_anxious.png"})

	b.hide_band()
