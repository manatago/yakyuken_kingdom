extends StoryChapterBase
class_name PrologueChapter

const StoryCharacterHandle := preload("res://resources/story/dsl/StoryCharacterHandle.gd")

func get_sequence_builders() -> Array:
	return [sequence_builder("prologue", "_build_prologue")]

func _build_prologue(b):
	# b は StoryDsl.build() から渡されるビルダープロキシで、背景・台詞などを登録するための DSL エントリポイント。
	var hero: StoryCharacterHandle = b.character("main")
	var heroine: StoryCharacterHandle = b.character("heroine")
	var guard: StoryCharacterHandle = b.character("guard")
	var matilda: StoryCharacterHandle = b.character("matilda")

	b.set_protagonist("main")

	b.background("res://assets/backgrounds/bg01_university.png", 0.5)
	b.show_band()
	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "bottom",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/char01-001_smile.png",
		"position_mode": "offset",
		"position": Vector2(0, -20),
	})
	b.narrator_band("5月の大学キャンパス。")
	b.narrator_band("主人公のサトシは、数学が得意で、国内No1の大学の数学科に在籍しているが、\n大学をサボってエロゲー三昧のアホ学生だ。")
	b.narrator_band("性的興奮を刺激し、少子化を解決する施作として野球拳をオリンピック競技にする政治活動をしているが、賛同者はエロ男子大学生のみ。")
	# hero.leave({
	# 	"exit_effect": "fade_slide",
	# 	"exit_to": "left",
	# 	"exit_duration": 0.8,
	# })

	# heroine.appear({
	# 	"side": "right",
	# 	"appear_effect": "fade_slide",
	# 	"appear_from": "bottom",
	# 	"appear_duration": 0.8,
	# 	"appear_distance": 200,
	# 	"portrait": "res://assets/characters/prologue/char02_pg_001.png",
	# 	"position_mode": "offset",
	# 	"position": Vector2(0, -120),
	# })
	b.narrator_band("一方、幼馴染の女の子は有名私大の弁論サークルに所属しており、政治家秘書のバイトをやっており、将来は政治家を目指している。弁論大会で多数の受賞歴を誇る。")
	b.narrator_band("彼女は密かに主人公に思いを寄せているが、才能の無駄遣いをしている彼を呆れ顔で見つめる、典型的なツンデレタイプ。")
	# heroine.leave({
	# 	"exit_effect": "fade_slide",
	# 	"exit_to": "right",
	# 	"exit_duration": 0.8,
	# })

	# hero.appear({
	# 	"side": "left",
	# 	"appear_effect": "fade_slide",
	# 	"appear_from": "left",
	# 	"appear_duration": 0.8,
	# 	"appear_distance": 200,
	# 	"portrait": "res://assets/characters/char01-005_smirk.png",
	# 	"position_mode": "offset",
	# 	"position": Vector2(0, -20),
	# })
	# ── 場面2：みのりとの会話 ──
	# hero.set_portrait("res://assets/characters/char01-001_smile.png")
	hero.band("今日も数理モデルの講義をバックレたった...")
	heroine.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/prologue/char02_pg_001.png",
		"position_mode": "offset",
		"position": Vector2(0, -120),
	})
	heroine.band("あ、サトシ。こんなとこでブラブラして……また講義サボったでしょ。")
	hero.band("みのり？ なんでこっちにいんの。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_002.png")
	heroine.band("秘書のバイト先がこっち方面なの。で、サボりでしょ？")
	hero.band("サボりじゃない。戦略的欠席だ。本気出せば主席でもいけるけどな。\n『異世界野球拳をオリンピック競技にする会』でかかりきりやし。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_003.png")
	heroine.band("その「本気出せば」、入学してから何回聞いたと思ってるの。\nもう三年目よ？")
	hero.band("ロマンを追う以外にどうやって青春を燃やせってんだ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_004.png")
	heroine.band("ロマン？ 署名が12人しか集まってない活動のどこがロマンなの。")
	hero.band("12人の同志な。革命はいつだって少数から始まるんだよ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_005.png")
	heroine.band("……はぁ。あんた去年も単位落としてたでしょ。\nもう後がないんじゃないの？")
	hero.band("へーきへーき。なんとかなるって。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_006.png")
	heroine.band("……なんとかなったこと、一度もないじゃない。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_007.png")
	heroine.band("あっ、もう行かなきゃ。")
	heroine.set_portrait("res://assets/characters/prologue/char02_pg_008.png")
	heroine.band("いい、今年こそ単位をちゃんととるのよ。")
	heroine.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8,
	})

	b.background("res://assets/backgrounds/bg02_room.png", 0.5)
	hero.set_portrait("res://assets/characters/char01-004_thinking.png")
	hero.band("（部屋はエロゲ箱と政治パンフと教科書の雪崩。俺の人生を縮図みたく語ってくれるインスタレーションアートだ。）")
	hero.band("けど……単位があと三つ足りないのはガチで笑えない。目の前の編集済みセーブデータより、現実の単位をロードし直さないと。")
	hero.band("掲示板の『大型加速器実験補助、履修認定あり』って募集、まだ締切ってなかったはず。ギリギリ滑り込むしかない。")

	b.background("res://assets/backgrounds/bg03-1_lab.png", 0.5)
	hero.set_portrait("res://assets/characters/char01-002_surprise.png")
	hero.band("ここが噂の研究施設……SPring-8にそっくりじゃないか。")
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
		"portrait": "res://assets/characters/ch01-100_white_coat.png",
		"position_mode": "offset",
		"position": Vector2(0, -20),
	})
	# hero.set_portrait("default_white_coat")
	hero.band("受付嬢に防護メガネと白衣を手渡されて、制御室のボタンを押してくれってさ。数式中毒の俺からしたら、計測ログの生データに触れるだけでご褒美だ。")
	hero.band("これで単位を確保して、堂々と署名活動に専念――")
	b.clear_band_text() # バンドテキストをクリア

	b.background("res://assets/backgrounds/bg03-2_lab.png", 0.4)
	hero.set_portrait("res://assets/characters/ch01-101_white_coat_surprise.png")
	hero.animate_portrait([
		"res://assets/characters/ch01-101_white_coat_surprise.png",
		"res://assets/characters/ch01-102_white_coat_surprise.png",
		"res://assets/characters/ch01-101_white_coat_surprise.png"
	], 0.08, 1)
	await b.pause(0.3)
	hero.say("うわっ！")
	hero.stop_portrait_animation()
	hero.band("制御盤が真っ白になってる!? 聞いてないぞ、こんなフラッシュ！")
	# hero.set_portrait("default_white_coat_surprise_closed_eyes")

	hero.hide_dialogue()
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
		"portrait": "res://assets/characters/ch01-103_teleport_white_coat.png",
		"position_mode": "offset",
		"position": Vector2(0, -120),
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
		"portrait": "res://assets/characters/ch01-150_teleport_naked.png",
		"position": Vector2(0, -120),
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
		"portrait": "res://assets/characters/ch01-151_naked.png",
		"position_mode": "offset",
		"position": Vector2(0, -20),
	})


	hero.band("こっここは...? あれっ、しかも裸じゃねーか。ヤバイ、誰か来る。")

	guard.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/char03-1_guard.png",
		"position_mode": "offset",
		"position": Vector2(0, -20),
	})

	guard.band("おい、そこの露出狂の変態！何してやがる。")
	hero.band("スプリングエイトで実験してたら、急に周りが真っ白になって。。。")
	guard.band("何言ってやがる。変態なうえに、気がくるっているのか？ちょっとこっちに来い！")
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
		"portrait": "res://assets/characters/ch01-200_isekai_anxious.png",
		"position_mode": "offset",
		"position": Vector2(0, -20),
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
		"portrait": "res://assets/characters/char04-1_prison_guard.png",
		"position_mode": "offset",
		"position": Vector2(0, -20),
	})

	matilda.band("起きたか、変態。")
	hero.band("俺は変態じゃな。。。きれいなねーさんだな。おっぱいも大きい。。。")
	matilda.band("おいおい、いやらしい目で見やがって。ほんとに変態ってやつは、どうしようもないな。")
	hero.band("ぐぬぬ。。。")

	b.narrator_band("変態の濡れ衣を着せられて悔しい思いをしたサトシだったけど、なんといっても牢屋に入れられている身。")
	b.narrator_band("なんとか気を取り直して、マチルダからこの政界の情報を聞き出すのだった。")
	b.narrator_band("----- (中略) -----")


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
