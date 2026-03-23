extends RefCounted
class_name Stage1Chapter

func get_sequence_builders() -> Array:
	return [
		{"id": "stage1", "builder": "_build_stage1"},
		{"id": "stage1_battle_win", "builder": "_build_battle_win"},
		{"id": "stage1_battle_lose", "builder": "_build_battle_lose"},
	]

func _build_stage1(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var adventurer_a = b.character("adventurer_a")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")

	# 前章のキャラクターをクリア
	b.character("matilda").leave({})
	b.character("main").leave({})

	# ============================================================
	# 場面10：王都アレクシア・ギルド通り
	# ============================================================
	b.label("scene_guild_street")
	b.background("res://assets/backgrounds/stage1/bg06_st1_001.png", 0.5)
	b.bg_filter(0.5, 0.3)
	b.show_band()

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/char01_st1_001.png",
		"portrait_scale": 0.5,
		"flip": 1,
	})
	hero.band("（マチルダさん……。あの「じゃんけん」に負けて服を脱ぐときの、屈辱と興奮が入り混じった顔。）")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_002.png", {"scale": 0.5, "side": "left", "flip": 1})
	hero.band("（……あかん、思い出したらニヤけてまう。俺、やっぱりあっちの世界の単位より、こっちの世界の「徳」の方が向いてるのかも。）")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_003.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("さて、まずは冒険者ギルドだな。この麻の服、ゴワゴワしてて痒いし、早く稼いでいい装備を買わないと。")

	# ピー助登場
	pisuke.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "top",
		"appear_duration": 0.6,
		"appear_distance": 300,
		"portrait": "res://assets/characters/stage1/char08_st1_001.png",
		"portrait_scale": 0.3,
        "position": [0, -600],
	})

	pisuke.band("ゲコゲコッ！ 見つけたぞ「欠陥適合者」！\n何をニヤニヤしてやがる。脳内のチップから桃色の信号がダダ漏れだぞ、このエロ猿！")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_004.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("うわっ！？ なんだ、この鳥。……喋った！？")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_001.png", {"scale": 0.3, "side": "right", "flip": 1, "position": [-200, -500]})
	pisuke.band("鳥と一緒にすんな。俺様は「ピー助」。お前をガイドするために遣わされた「聖霊（精霊）」様だ。\nお前、サトシだろ？ 異界から迷い込んだ「脳に隙間のある男」。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_005.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("聖霊……？ 見た目、完全にただのヨウムじゃないか。\nそれより「欠陥適合者」ってなんだよ。さっきから失礼な！")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_002.png", {"scale": 0.3, "side": "right", "flip": 1, "position": [0, -400]})
	pisuke.band("普通の人間なら、この世界のチップを埋め込まれたら精神が同化しちまうんだ。だがお前は、脳の使い方が偏りすぎてて、チップと脳の間に「隙間」ができてる。")
	pisuke.band("いわば、システムが正常に認識できない「バグ」みたいな存在なんだよ。")

	# ============================================================
	# 場面11：ギルドへの道中・解析
	# ============================================================
	b.label("scene_analysis")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_006.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("……なあ、ピー助。さっきから気になってたんだが。\nこの「チップ」ってやつ、マチルダさんは「身分証」とか「戦闘インターフェース」って言ってたけど……。")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_003.png", {"scale": 0.3, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("ああ、そうだ。この世界の理（ことわり）を司る「演算核」だよ。")

	# hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.53, "flip": 1})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_010.png", {"scale": 0.50, "side": "left", "flip": 1, "position": [ -50, 0]})
	hero.band("いや、俺がさっき「テーブル・オープン」って念じた時に出たログ……。\nあれ、完全にUNIX系のカーネル構造に似てなかったか？\nもしかして、このチップの内部って……。")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_004.png", {"scale": 0.3, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("……ほう。気づくのが早いな。\nそうさ、この世界の「法」は、巨大なメインフレームで管理された「プログラム」そのものだ。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_008.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("やっぱりか！ ってことは、マチルダさんが俺に入れたのは「汎用OS」みたいなものか。")
	hero.band("でも、マチルダさんの操作を見てて思ったんだ。アクセス権限のチェックがガバガバじゃないか？\n……ピー助、お前、この内部ログを読み取れるか？")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_005.png", {"scale": 0.3, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("俺様を誰だと思ってる。読み取りどころか、書き換えだって……おっと、これ以上は秘密だ。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("……やっぱりな。ピー助、協力しろ。\nこのチップ、第3層のライブラリに未定義の関数が放置されてる。")
	hero.band("ここに俺の「数理モデル」を流し込めば、システムの「予測演算」をこっちにバイパスできるはずだ。")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_006.png", {"scale": 0.3, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("ゲコッ！？ お前、神が作ったシステムに「パッチ」を当てようってのか？面白そうじゃねえか！ やれ、サトシ！ 俺がポートをこじ開けてやる！")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_005.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（……よし、数学科の意地を見せてやる。変数固定、ポインタを強制書き換え……\n……エンター！）")

	b.terminal_effect([
		"> scanning chip_layer3.lib ...",
		"> undefined function detected: predict()",
		"> injecting bayes_model.dat ...",
		"> rewriting pointer: 0x7F3A → math_core.so",
		"> compiling neural_bridge ...",
		"> .............................",
		"> BUILD SUCCESSFUL",
		"> ",
		"> SKILL REGISTERED: 確率の観測者（ベイズ・アイ）",
		"> STATUS: ACTIVE",
	])

	hero.set_portrait("res://assets/characters/stage1/char01_st1_009.png", {"scale": 0.75, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("できた……。新スキル「確率の観測者（ベイズ・アイ）」！\nこれで、相手の手札の統計から、次に出す手の「確率」が可視化されるはずだ。")
	hero.band("よっしゃ。これなら勝てる。")

	# ============================================================
	# 場面12：冒険者ギルド・入り口
	# ============================================================
	b.label("scene_guild_hall")
	b.background("res://assets/backgrounds/stage1/bg07_guild_hall.png", 0.5)
	b.bg_filter(0.25, 0.3)

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/char01_st1_002.png",
		"portrait_scale": 0.5,
	})

	hero.band("よっしゃ。これなら勝てる。")

	# 冒険者A登場
	adventurer_a.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/adventurer_a_001.png",
		"portrait_scale": 0.5,
	})

	adventurer_a.band("おい、新顔。その肩に乗せてる妙な鳥、高く売れそうじゃねえか。\nここじゃ強い奴がルールだ。俺様と「じゃんけん」して、負けたらその鳥を置いていきな！")

	pisuke.band("言ったな、三下！ サトシ、こいつのカードを全部剥ぎ取って、\n広場で「俺は確率の奴隷です」って叫ばせてやれ！")

	hero.band("（……やれやれ。でも、テストにはちょうどいい。）\nいいですよ。その勝負、受けます。")

	b.hide_band()

	# チュートリアル（ベイズ・アイ）があれば入れる
	b.label("stage1_battle_start")
	b.battle("res://battle/chapters/Stage1BattleChapter.gd")

	# ============================================================
	# 場面13：冒険者ギルド・受付
	# ============================================================
	b.label("scene_guild_reception")

	adventurer_a.band("バカな……！ まるで俺の手が透けてるみたいじゃねえか……！\nクソッ、服を返せ！ 覚えてろよ！")

	adventurer_a.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})

	receptionist.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/receptionist_001.png",
		"portrait_scale": 0.5,
	})

	receptionist.band("……あら、お見事です。あの方はギルドでも有名な「初心者狩り」だったのですが。\nあなた、もしかして高名な「戦略家」の家系の方ですか？")

	hero.band("いえ……ただの「数学好きのエロゲーマー」です。")

	receptionist.band("えっ？ エ……？")

	pisuke.band("「エリート・ゲーマー」って意味だよ！ ほら、さっさと登録しろ！")

	receptionist.band("あ、はい！ ではこちらの魔力水晶に……。\n……判定完了です。サトシ様、ランクF。\nですが、特殊スキル……「ベイズ・アイ」？\n聞いたことがないスキルですが……。")

	hero.band("（……フフ。この世界、俺にとっては「チート可能なクソゲー」にすぎないのかもな。）")

	hero.band("みのり、見てるか。俺、こっちで「革命」を起こせそうだよ。")

# --- バトル後（勝利） ---

func _build_battle_win(b):
	var hero = b.character("main")
	var adventurer_a = b.character("adventurer_a")

	b.background("res://assets/backgrounds/stage1/bg07_guild_hall.png", 0)
	adventurer_a.set_portrait("res://assets/characters/stage1/adventurer_a_002.png", {"scale": 0.5, "side": "right"})
	adventurer_a.band("バカな……！ 俺の手が読まれてるだと！？")
	hero.set_portrait("res://assets/characters/stage1/char01_st1_002.png", {"scale": 0.5, "side": "left"})
	hero.band("（ベイズ・アイ……使えるな。）")

# --- バトル後（敗北） ---

func _build_battle_lose(b):
	var hero = b.character("main")
	var adventurer_a = b.character("adventurer_a")

	b.background("res://assets/backgrounds/stage1/bg07_guild_hall.png", 0)
	adventurer_a.set_portrait("res://assets/characters/stage1/adventurer_a_001.png", {"scale": 0.5, "side": "right"})
	adventurer_a.band("ハッ！ 口だけの小僧だったな！")
	hero.set_portrait("res://assets/characters/stage1/char01_st1_001.png", {"scale": 0.5, "side": "left"})
	hero.band("くっ……まだスキルの使い方が甘いか……。")
