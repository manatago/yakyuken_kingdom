extends RefCounted
class_name PrologueChapter

func get_sequence_builders() -> Array:
	return [
		{"id": "prologue", "builder": "_build_prologue"},
	]

func _build_prologue(b):
	var hero = b.character("main")
	var heroine = b.character("heroine")
	var receptionist = b.character("receptionist")
	var passerby_male = b.character("passerby_male")
	var passerby_female = b.character("passerby_female")
	var guard = b.character("guard")
	var matilda = b.character("matilda")

	b.set_protagonist("main")
	# 内部バンドの色を設定（プリセット: StoryCommands.gd の _band_colors を参照）
	b.band_color("royal_blue")

	b.background("res://assets/backgrounds/prologue/bg01_university.png", 0.5)
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
		"position": [0, 0],
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
		"position": [0, 0],
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
		"position": [0, 0],
	})
	# ── 場面2：みのりとの会話 ──
	hero.set_portrait("res://assets/characters/prologue/char01_pg_002.png", {"scale": 0.5})
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
		"position": [0, 100],
	})
	heroine.band("あ、サトシ。こんなとこでブラブラして……また講義サボったでしょ。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_003.png", {"scale": 0.5})
	hero.band("みのり？ なんでこっちにいんの。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_002.png", {"scale": 0.5})
	heroine.band("秘書のバイト先がこっち方面なの。で、サボりでしょ？")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_004.png", {"scale": 0.5})
	hero.band("サボりじゃない。戦略的欠席だ。\n本気出せば主席でもいけるけどな。\n『異世界野球拳をオリンピック競技にする会』でかかりきりやし。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_003.png", {"scale": 0.5})
	heroine.band("その「本気出せば」、入学してから何回聞いたと思ってるの。\nもう三年目よ？")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_005.png", {"scale": 0.5})
	hero.band("ロマンを追う以外にどうやって青春を燃やせってんだ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_004.png", {"scale": 0.5})
	heroine.band("ロマン？ 署名が12人しか集まってない活動のどこがロマンなの。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_006.png", {"scale": 0.5, "position": [25, 0]})
	hero.band("12人の同志な。革命はいつだって少数から始まるんだよ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_005.png", {"scale": 0.5})
	heroine.band("……はぁ。あんた去年も単位落としてたでしょ。\nもう後がないんじゃないの？")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_007.png", {"scale": 0.5, "position": [25, 0]})
	hero.band("へーきへーき。なんとかなるって。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_006.png", {"scale": 0.5})
	heroine.band("……なんとかなったこと、一度もないじゃない。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_007.png", {"scale": 0.5})
	heroine.band("あっ、もう行かなきゃ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_008.png", {"scale": 0.5, "position": [150, 200]})
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

	b.background("res://assets/backgrounds/prologue/bg02_room.png", 0.5)
	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_008.png",
		"portrait_scale": 0.5,
		"position_mode": "offset",
		"position": [0, 0],
	})
	# hero.set_portrait("res://assets/characters/prologue/char01_pg_008.png", {"scale": 0.5})
	hero.band("（部屋はエロゲ箱と政治パンフと教科書の雪崩。俺の人生を縮図みたく語ってくれるインスタレーションアートだ。）")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_009.png", {"scale": 0.5})
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
		"position": [0, -300],
		"flip": 0,
	})
	heroine.band("あんたの大学のサイトに出てたけど、「大型加速器実験補助、履修認定あり」って募集、知ってる？締切明日までだって。")
	# heroine.set_portrait("res://assets/characters/prologue/char02_pg_009.png", {"scale": 0.6, "position": [150, 50]})
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

	b.background("res://assets/backgrounds/prologue/bg03-1_lab.png", 0.5)

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_013.png",
		"portrait_scale": 0.7,
		"position_mode": "offset",
		"position": [0, 0],
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
		"position": [0, 0],
		"flip": 0,
	})
	receptionist.band("学生さん？ 実験補助のバイトね。はい、これ白衣と防護メガネ。")
	receptionist.set_portrait("res://assets/characters/prologue/char03_pg_002.png", {"scale": 0.5, "flip": 0})
	hero.set_portrait("res://assets/characters/prologue/char01_pg_014.png", {"scale": 0.5})
	hero.band("あ、どうも。えっと、具体的に何をすれば……")
	receptionist.set_portrait("res://assets/characters/prologue/char03_pg_003.png", {"scale": 0.5, "flip": 0})
	receptionist.band("簡単よ。制御室に入って、合図があったらボタンを押すだけ。それ以外は絶対に触らないでね。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_015.png", {"scale": 0.5})
	hero.band("ボタン一個で単位もらえるとか、最高のバイトじゃないすか。")
	receptionist.set_portrait("res://assets/characters/prologue/char03_pg_004.png", {"scale": 0.5, "flip": 0})
	receptionist.band("ふふ、みんなそう言うわ。でもね、ここの装置、ちょっと気まぐれなの。何かあったらすぐ赤いボタンを押して。非常停止だから。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_016.png", {"scale": 0.5})
	hero.band("（フラグ立ってる感がすごいんだが。）")

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
		"position": [0, -20],
	})
	# hero.set_portrait("default_white_coat")
	hero.band("数式中毒の俺からしたら、計測ログの生データに触れるだけでご褒美だ。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_018.png", {"scale": 0.5})
	hero.band("これで単位を確保して、堂々と署名活動に専念――っと。")
	b.clear_band_text() # バンドテキストをクリア



	b.background("res://assets/backgrounds/prologue/bg03-2_lab.png", 0.4)
	hero.set_portrait("res://assets/characters/prologue/char01_pg_019.png", {"scale": 0.5})
	hero.band("うわっ！")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_020.png", {"scale": 0.5})
	hero.band("赤いボタン～～どこ～!?")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_021.png", {"scale": 1.2, "position": [0, 50]})
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
		"position": [50, -300],
	})
	hero.band("（身体の輪郭が空気に溶ける。慣性も重力も感じない。加速器って、テレポーターだったのかよ……！）")
	hero.leave({
		"side": "center",
		"exit_effect": "shrink",
		"exit_duration": 0.6,
		"wait_for_exit": true
	})

	b.background("res://assets/backgrounds/prologue/bg04-1_teleport_square.png", 0.5)
	hero.appear({
		"side": "center",
		"appear_effect": "fade_grow",
		"appear_duration": 1.2,
		"portrait": "res://assets/characters/prologue/char01_pg_023.png",
		"portrait_scale": 0.3,
		"position": [0, -400],
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


	b.background("res://assets/backgrounds/prologue/bg04-2_teleport_square2.png", 0.5)
	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "bottom",
		"appear_duration": 1.2,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char01_pg_024.png",
		"portrait_scale": 0.55,
		"position_mode": "offset",
		"position": [0, -0],
	})
	hero.band("いてて……。石畳……？ 城壁に塔……ここ、どこだ？")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_025.png", {"scale": 0.55})
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
		"position": [0, 0],
		"flip": 0,
	})
	passerby_female.band("きゃあああ！ へ、変態！！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_026.png", {"scale": 1.0, "position": [0, 50]})
	hero.band("えっ？")
	passerby_female.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_027.png", {"scale": 0.6})
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
		"position": [0, 0],
		"flip": 1,
	})
	passerby_male.band("おい誰か捕まえろ！ 白昼堂々、王都の広場でとんでもない奴だ！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_028.png", {"scale": 0.6, "flip": 1})
	hero.band("待って、違うんです！ これは事故で――")
	passerby_male.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})
	hero.set_portrait("res://assets/characters/prologue/char01_pg_029.png", {"scale": 0.6, "flip": 1})
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
		"position": [0, 0],
	})
	guard.band("何の騒ぎだ。……おい、そこの露出狂の変態！ 何してやがる。")


	hero.set_portrait("res://assets/characters/prologue/char01_pg_030.png", {"scale": 0.6, "flip": 1})
	hero.band("スプリングエイトで実験してたら、急に周りが真っ白になって...")
	guard.set_portrait("res://assets/characters/prologue/char04_pg_002.png", {"scale": 0.5, "flip": 1})
	guard.band("何言ってやがる。変態なうえに、気がくるっているのか？")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_031.png", {"scale": 0.6, "flip": 1})
	hero.band("いや待って、ここどこですか？ 日本……だよな？")
	guard.set_portrait("res://assets/characters/prologue/char04_pg_003.png", {"scale": 0.5, "flip": 1})
	guard.band("ニホン？ 何を寝ぼけてやがる。ここはヤクケン王国の王都アレクシアだ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_032.png", {"scale": 1.05, "flip": 1})
	hero.band("ヤクケン王国……？ マジの異世界じゃねーか")
	guard.set_portrait("res://assets/characters/prologue/char04_pg_004.png", {"scale": 0.5, "flip": 1})
	guard.band("おい聞いてんのか！ 王都のど真ん中で裸とは、不敬罪もいいところだ。ちょっとこっちに来い！")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_033.png", {"scale": 1.05})
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

	b.background("res://assets/backgrounds/prologue/bg05_prison_cell.png", 0.5)
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
		"position": [0, 0],
	})

	hero.band("いてててて。あれっ、ここはどこだっけ。確か昨日はバイト先で光の渦に飲み込まれて、気が付いたら裸だったんだ。")
	hero.band("あの番兵、えらい怒っていたよな。すごい剣幕だった。しかし、人を変態呼ばわりしやがって。俺は被害者だっちゅーの。")
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
		"position": [0, 10],
	})
	matilda.band("起きたか、変態。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_035.png", {"scale": 0.7})
	hero.band("俺は変態じゃな... おっ、きれいなねーさんだな。おっぱいもでかい。")
	matilda.set_portrait("res://assets/characters/prologue/char07_pg_002.png", {"scale": 0.65, "position": [-100, 10], "flip": 0})
	matilda.band("おいおい、いやらしい目で見やがって。ほんとに変態ってやつは、どうしようもないな。")
	hero.set_portrait("res://assets/characters/prologue/char01_pg_036.png", {"scale": 0.49})
	hero.band("ぐぬぬ。。。")

	b.narrator_band("変態の濡れ衣を着せられて悔しい思いをしたサトシだったけど、なんといっても牢屋に入れられている身。おとなしくするしかない。")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_001.png", {"scale": 0.45, "position": [0, 10]})
	matilda.band("さて、変態の身元調査といこうか。\n変態、お前の名前は？ どこから来た。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", {"scale": 0.5, "flip": 1})
	hero.band("(また変態って...)\nサトシ...です。日本ってところから来た？と思います。")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_003.png", {"scale": 0.45, "position": [-80, 0]})
	matilda.band("ニホン？ 聞いたことないね。この大陸の国じゃないのは確かだ。\n……まあ、異界渡りってやつかい。珍しいけど、前例がないわけじゃない。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.5, "flip": 1})
	hero.band("異界渡り……？ そういう概念があるんですか。\nあの、ヤクケン王国って番兵の人が言ってたんですけど、ここは一体どういう国なんですか？")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_001.png", {"scale": 0.45, "position": [0, 10]})
	matilda.band("あんた本当に何も知らないんだね。\nこの大陸で一番でかい国さ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", {"scale": 0.5, "flip": 1})
	hero.band("国の名前からして嫌な予感しかしないんですけど……。")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_004.png", {"scale": 0.45, "position": [-200, 10]})
	matilda.band("質問の前に、まずは身体検査だ。\n牢に入る奴は全員やる決まりでね。じっとしてな。")

	b.narrator_band("マチルダが手のひらをサトシの額にかざすと、淡い光が走った。\nだが――")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_005.png", {"scale": 0.65, "position": [-100, 10]})
	matilda.band("……エラー？ IDが存在しない……？\nまさか、脳にチップが入っていないの！？")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "flip": 1})
	hero.band("チップ？ 脳に？ な、なんの話ですか？")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_006.png", {"scale": 0.45, "position": [-120, 0], "flip": 0})
	matilda.band("この世界の住人は、生まれた時に識別チップを脳に埋め込まれるんだ。身分証であり、戦闘システムへのインターフェースでもある。それがないってことは……本当に異界の人間なんだね、あんた。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_040.png", {"scale": 0.7, "flip": 1})
	hero.band("だから最初からそう言ってるじゃないですか……。")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_007.png", {"scale": 0.65, "position": [-120, 10], "flip": 0})
	matilda.band("……しょうがないね。特例だ。")
	b.narrator_band("マチルダは懐から小さな注射器のようなものを取り出した。")
	matilda.band("旧式の汎用チップだけど、ないよりマシさ。うなじを出しな。ちょっとチクっとするよ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_041.png", {"scale": 0.7, "flip": 1})
	hero.band("えっ、ちょ、いきなり注射!? 説明――いっっっ!!")

	b.background("res://assets/backgrounds/prologue/bg05_prison_cell.png", 0.5)
	b.narrator_band("マチルダに無理やり注射をされて、サトシのうなじに激痛が走った...")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_042.png", {"scale": 0.5, "flip": 1})
	hero.band("いって――――――――――――ぇ。まじ、なんなの...")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_001.png", {"scale": 0.45, "position": [0, 10]})

	matilda.band("だらしないな、女みたいにビービー泣いてないで、心の中で、テーブルオープンって行ってみろ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", {"scale": 0.5, "flip": 1})
	hero.band("(なっ、なんだよ、自分だって女のくせに。うっ、睨まれている。\nテッ、テッ、テーブル...オープン)")

	b.narrator_band("サトシが心のなかで「テーブルオープン」と言った瞬間、視界が一変した。")
	b.hide_band()

	b.label("tutorial_start")
	b.tutorial("res://battle/chapters/PrologueBattleChapter.gd")

	matilda.set_portrait("res://assets/characters/prologue/char07_pg_001.png", {"scale": 0.45, "side": "right", "position": [0, 10]})
	matilda.band("「じゃんけん」に負けると、服を脱がなきゃならない。1回負けるたびに服を1枚脱ぐ。全て脱がされたら、相手のいうことを聞かなきゃなんない。")
	matilda.band("「じゃんけん」勝負をするときは服は3枚と決まっている。これは王国ルールだ。ただ、市民にはあんまり根付いてなくてな、街中では 1回勝負が好まれている。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", {"scale": 0.5, "side": "left", "flip": 1})
	hero.band("そっそれって、野球拳じゃ...")

	matilda.band("ヤキュウケン？ 聞いたことないね。\nこの国ではすべての争いごとを「じゃんけん」で決める。それが法律だ。")

	hero.band("じゃんけんで!? 裁判も、商取引もですか？")

	matilda.band("領土争いから税率の決定、犯罪者の刑期まで、全部「じゃんけん」だ。")

	hero.band("（カードを使ったじゃんけんか...）それって、確率と読みあいのゲーム....ですか？")

	matilda.band("そういうこと。強い奴が出世し、弱い奴は這いつくばる。\n実力主義のわかりやすい世界だろ？")

	hero.band("（確率と読み合い……それ、まさに俺が大学で研究してた分野じゃないか。）")
	hero.band("（混合戦略のナッシュ均衡、ベイズ推定による相手の手の予測……。\nここでは俺の数学が、そのまま「戦闘力」になるってことか？））")
	matilda.band("おい、なに黙り込んでるんだ。怖気づいたか？")

	hero.band("……いえ、ちょっとワクワクしてき……ました。")

	matilda.band("は？ 牢屋の中でワクワクとか、やっぱり変態じゃないか。")
	hero.band("(くっそぉ、変態、変態言いやがって、、、\nまてよ、ゲームに勝てば牢屋から出られる？！。)")
	hero.band("しょっ、勝負しませんか？")

	matilda.band("おっ、小心者の変態にもそんな度胸があったんだな。いいぜ、受けてやるよ。")
	matilda.band("お前が勝ったら、晴れて無罪放免だ。負けたら牢屋からは出られねぇ。覚悟しておけよ。")
	matilda.band("まあ、今日始めたひよっこに全力で勝負したらマチルダさんの名が廃るからな、同じカードで勝負してやるよ。")

	hero.band("（この人なんか、最初にグーを出すのが癖じゃないかと思うんだよね。勝負師の感？）")

	b.battle("res://battle/chapters/PrologueBattleChapter.gd")

	matilda.band("負けた...素人に。この屈辱は必ず晴らす。\n私はここにいるから必ず再戦しにこい。待っている。")
	hero.band("うへへっ、おいしい思いもしたし。これでやっと牢から出られるぞ。")















