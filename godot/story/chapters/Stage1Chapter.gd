extends RefCounted
class_name Stage1Chapter

func get_sequence_builders() -> Array:
	return [
		{"id": "stage1", "builder": "_build_stage1"},
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
		"portrait_scale": 0.2,
        "position": [0, -600],
	})

	pisuke.band("ゲコゲコッ！ 見つけたぞ「欠陥適合者」！\n何をニヤニヤしてやがる。脳内のチップから桃色の信号がダダ漏れだぞ、このエロ猿！")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_004.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("うわっ！？ なんだ、この鳥。……喋った！？")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_001.png", {"scale": 0.2, "side": "right", "flip": 1, "position": [-200, -500]})
	pisuke.band("鳥と一緒にすんな。俺様は「ピー助」。お前をガイドするために遣わされた「聖霊（精霊）」様だ。\nお前、サトシだろ？ 異界から迷い込んだ「脳に隙間のある男」。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_005.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("聖霊……？ 見た目、完全にただのヨウムじゃないか。\nそれより「欠陥適合者」ってなんだよ。さっきから失礼な！")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_002.png", {"scale": 0.2, "side": "right", "flip": 1, "position": [0, -400]})
	pisuke.band("普通の人間なら、この世界のチップを埋め込まれたら精神が同化しちまうんだ。だがお前は、脳の使い方が偏りすぎてて、チップと脳の間に「隙間」ができてる。")
	pisuke.band("いわば、システムが正常に認識できない「バグ」みたいな存在なんだよ。")

	# ============================================================
	# 場面11：ギルドへの道中・解析
	# ============================================================
	b.label("scene_analysis")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_006.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("……なあ、ピー助。さっきから気になってたんだが。\nこの「チップ」ってやつ、マチルダさんは「身分証」とか「戦闘インターフェース」って言ってたけど……。")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_003.png", {"scale": 0.2, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("ああ、そうだ。この世界の理（ことわり）を司る「演算核」だよ。")

	# hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.53, "flip": 1})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_010.png", {"scale": 0.50, "side": "left", "flip": 1, "position": [ -50, 0]})
	hero.band("いや、俺がさっき「テーブル・オープン」って念じた時に出たログ……。\nあれ、完全にUNIX系のカーネル構造に似てなかったか？\nもしかして、このチップの内部って……。")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_004.png", {"scale": 0.2, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("……ほう。気づくのが早いな。\nそうさ、この世界の「法」は、巨大なメインフレームで管理された「プログラム」そのものだ。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_008.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("やっぱりか！ ってことは、マチルダさんが俺に入れたのは「汎用OS」みたいなものか。")
	hero.band("でも、マチルダさんの操作を見てて思ったんだ。アクセス権限のチェックがガバガバじゃないか？\n……ピー助、お前、この内部ログを読み取れるか？")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_005.png", {"scale": 0.2, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("俺様を誰だと思ってる。読み取りどころか、書き換えだって……おっと、これ以上は秘密だ。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("……やっぱりな。ピー助、協力しろ。\nこのチップ、第3層のライブラリに未定義の関数が放置されてる。")
	hero.band("ここに俺の「数理モデル」を流し込めば、システムの「予測演算」をこっちにバイパスできるはずだ。")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_006.png", {"scale": 0.2, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("ゲコッ！？ お前、神が作ったシステムに「パッチ」を当てようってのか？面白そうじゃねえか！ やれ、サトシ！ 俺がポートをこじ開けてやる！")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_005.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（……よし、数学科の意地を見せてやる。変数固定、ポインタを強制書き換え…………エンター！）")

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

	# ピー助の透明化
	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_004.png", {"scale": 0.2, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("おい、サトシ。ギルドに入る前に一つ言っておく。\n俺様の姿は、人前じゃ見せない方がいい。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_011.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え？ なんで？")

	pisuke.band("この世界で精霊を連れてる人間ってのは、\n「契約者」か「呪われた者」のどっちかだ。\nどちらにしても厄介事に巻き込まれる。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_012.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("呪われた者って……。俺、どっちなの？")

	pisuke.set_portrait("res://assets/characters/stage1/char08_st1_006.png", {"scale": 0.2, "side": "right", "flip": 1, "position": [0, -200]})
	pisuke.band("さあな。それはおいおい分かる。\n……というわけで、透明化するぞ。ただし声は消せねえ。\n俺様の声は周りにも聞こえる。だから余計なことは喋るなよ。")

	# ピー助退場（その場で徐々に透明化）
	pisuke.leave({
		"exit_effect": "fade",
		"exit_duration": 1.5,
		"wait_for_exit": true,
	})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_013.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("えっ、消えた！？ ……って、声は聞こえるのに姿が見えないのか。\n光学迷彩みたいだな。")

	b.narrator_band("サトシの右肩に、何かがストンと降り立つ感触があった。\n見えないが、小さな爪が服に食い込んでいる。")

	pisuke.band("ここが俺様の定位置だ。がたがた言ってないで、冒険者ギルドに行くぞ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_014.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("へいへい。（爪が痛いんだが...）")
	hero.leave({
		"side": "left",
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 1.2,
		"wait_for_exit": true
	})

	# ============================================================
	# 場面12：冒険者ギルド・入り口
	# ============================================================
	b.label("scene_guild_hall")
	b.background("res://assets/backgrounds/stage1/bg07_st1_001.png", 0.5)

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/char01_st1_015.png",
		"portrait_scale": 0.5,
		"flip": 0,
	})

	hero.band("（ここが冒険者ギルド……。ガラの悪そうな連中ばっかりだ。\n目を合わせないように……端っこを歩いて受付に……。）")

	# ピー助（透明・小声）
	pisuke.band("おい、キョロキョロすんな。弱そうに見えるだろうが。", {"side": "left"})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_017.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("（いや、実際弱いし……。）")

	# 冒険者A登場（立ちふさがる）
	adventurer_a.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/char09_st1_001.png",
		"portrait_scale": 0.6,
		"flip": 0,
	})

	adventurer_a.band("おい、そこの変態顔。ニヤニヤしやがって気持ち悪ぃな。\nここは冒険者ギルドだ。新入りは「通過儀礼」を受けてもらうぜ。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("（変態顔……！？ そんなにニヤけてたか俺……。\nいや確かにマチルダさんのこと思い出してたけど……くそ、地味に傷つく……。）")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("へ、変態じゃないです……。つ、通過儀礼……？")


	adventurer_a.set_portrait("res://assets/characters/stage1/char09_st1_002.png", {"scale": 0.53, "side": "right", "flip": 0, "position": [0, 70]})
	adventurer_a.band("俺と「じゃんけん」して勝ったら通してやる。\n負けたら……そのボロ服を脱いでもらおうか。ガハハ！")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_019.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("え、いや、あの……急いでるので……。")

	# ピー助がサトシの声色を真似て挑発
	hero.band("はぁ！？ 通過儀礼だぁ？ そんなもん、こっちから望むところだ！\nてめえみたいな三下のカードを全部剥いで、\nギルドの入り口に「敗北者の記念碑」として飾ってやるよ！")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("！？ ちょ、俺そんなこと一言も……！")

	adventurer_a.set_portrait("res://assets/characters/stage1/char09_st1_003.png", {"scale": 0.53, "side": "right", "flip": 0, "position": [0, 70]})
	adventurer_a.band("……あ？ 今、なんつったテメェ？\n「三下」だと？ 「記念碑」だと？")

	adventurer_a.set_portrait("res://assets/characters/stage1/char09_st1_004.png", {"scale": 0.53, "side": "right", "flip": 0, "position": [0, 70]})
	adventurer_a.band("……上等だ。テメェの顔、覚えたぞ。\n逃げんなよ？ ここで決着つけてやる！")

	b.narrator_band("ギルドの入り口に人だかりができ始めた。\n冒険者Aの怒号に、他の冒険者たちが野次馬のように集まってくる。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_020.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("（ピー助このやろう……！ 俺の声で勝手に啖呵切りやがって……！\n周りの目もあるし……もう逃げられない……。）")

	# ピー助（小声でスキャン結果）
	pisuke.band("ゲコッ。こいつのデッキ、スキャンしたぞ。ノーマルカードばっかりだ。\nベイズ・アイを使えば余裕で勝てる。\n……ほら、覚悟を決めろ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_021.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("……はぁ。（もうどうにでもなれ。）\n……わかりましたよ。その勝負、受けます。")

	b.hide_band()

	b.label("stage1_battle_start")
	b.tutorial("res://battle/chapters/Stage1BattleChapter.gd")

	# ============================================================
	# 場面13：冒険者ギルド・受付
	# ============================================================
	b.label("scene_guild_reception")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_015.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	adventurer_a.set_portrait("res://assets/characters/stage1/char09_st1_005.png", {"scale": 0.7, "side": "right", "flip": 1, "position": [0, 100]})
	# adventurer_a.set_portrait("res://assets/characters/stage1/adventurer_a_001.png", {"scale": 0.5, "side": "right"})
	# バトル後（チュートリアルなので必ず勝利）
	adventurer_a.band("バカな……！ 俺の手が読まれてるだと……！？\nクソッ、覚えてろよ！")
	adventurer_a.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})

	pisuke.band("ゲコッ！ な？ 俺様が背中を押してやったから勝てたんだろうが。\n感謝しろよ。", {"side": "left"})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("（勝手に巻き込んでおいて恩着せがましい……。\nでも、ベイズ・アイ……使えるな。）")

	# 受付へ
	b.narrator_band("野次馬が散り、ギルドの喧騒が戻ってくる。\nサトシは気を取り直して受付カウンターへ向かった。")

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

	hero.set_portrait("res://assets/characters/stage1/char01_st1_022.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（受付嬢……めっちゃ美人じゃないか。この世界、レベル高いな……。）")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_002.png", {"side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("……あの。何かご用ですか？")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_023.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あっ！ す、すみません！ 冒険者登録をしたいんですけど……。")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_003.png", {"side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("……はい。こちらの魔力水晶に触れてください。")

	pisuke.band("おいおい、また変態顔になってるぞ。\nさっき入り口で言われたの忘れたのか。", {"side": "left"})

	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（うるさい……。見てただけだ。）")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_004.png", {"side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("……判定完了です。サトシ様、登録が完了しました。")
	receptionist.band("……犯罪歴は、ないようですね。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_024.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（……今、めちゃくちゃジト目で見られた。\n犯罪歴って……そんな目で見られるほど怪しいのか俺……。）")

	receptionist.set_portrait("res://assets/characters/stage1/char10_st1_005.png", {"side": "right", "flip": 0, "position": [0, 0]})
	receptionist.band("冒険者証をお渡しします。……どうぞ。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_027.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あ、ありがとうございます……。")
	hero.band("（……カウンター置きだった。完全に変態だと思われてる。）")
	pisuke.band("自業自得だな。まあ登録できたんだし、第一歩だ。", {"side": "left"})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_028.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（……はぁ。異世界に来て最初にやったことが、\n牢番のお姉さんを脱がせて、ギルドで変態扱いされることって……。\n俺の人生、どこで道を間違えたんだ。）")

	receptionist.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})





	hero.set_portrait("res://assets/characters/stage1/char01_st1_025.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（……いや、待てよ。）")
	hero.band("（ベイズ・アイ……水晶には反応したけど、受付嬢には見えてなかった。\nこのスキル、俺にしか見えないのか。）")
	hero.band("（人にドン引きされるのは辛いけど……\n誰にも見えないスキルで確率を操れるってことは……\nこれ、めちゃくちゃ有利じゃないか？）")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_026.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（……フフ。変態扱いされてる場合じゃない。\nこの世界、俺にとっては「チート可能なクソゲー」にすぎないのかもな。）")
	hero.band("……みのり、見てるか。俺、こっちで「革命」を起こせそうだよ。\n……人としての評判は崩壊気味だけど。")

	b.narrator_band("こうしてサトシは冒険者ギルドに登録された。\nここが、この世界での拠点となる。")
	b.narrator_band("クエストの受注、カードの管理、装備の購入……\n冒険者としての生活が、ここから始まる。")

