extends RefCounted
class_name PrologueChapter

const StoryDsl := preload("res://resources/story/dsl/StoryDsl.gd")
const StoryCast := preload("res://resources/story/StoryCast.gd")
const StorySequence := preload("res://resources/story/StorySequence.gd")
const StoryCharacterHandle := preload("res://resources/story/dsl/StoryCharacterHandle.gd")

static func build(cast: StoryCast) -> StorySequence:
	var dsl := StoryDsl.new(cast)
	return dsl.build("prologue", Callable(PrologueChapter, "_build_prologue"))

static func _build_prologue(b):
	# b は StoryDsl.build() から渡されるビルダープロキシで、背景・台詞などを登録するための DSL エントリポイント。
	var hero: StoryCharacterHandle = b.character("main")
	var heroine: StoryCharacterHandle = b.character("heroine")
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
		"portrait": "Default",
		"position_mode": "offset",
		"position": Vector2(0, -20),
	})
	b.narrator_band("5月の大学キャンパス。")
	b.narrator_band("主人公のサトシは、数学が得意で、国内No1の大学の数学科に在籍しているが、\n大学をサボってエロゲー三昧のアホ学生だ。")
	b.narrator_band("性的興奮を刺激し、少子化を解決する施作として野球拳をオリンピック競技にする政治活動をしているが、賛同者はエロ男子大学生のみ。")
	hero.leave({
		"exit_effect": "fade_slide",
		"exit_to": "left",
		"exit_duration": 0.8
	})

	heroine.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "bottom",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "Default",
		"position_mode": "offset",
		"position": Vector2(0, -120),
	})
	b.narrator_band("一方、幼馴染の女の子は有名私大の弁論サークルに所属しており、政治家秘書のバイトをやっており、将来は政治家を目指している。弁論大会で多数の受賞歴を誇る。")
	b.narrator_band("彼女は密かに主人公に思いを寄せているが、才能の無駄遣いをしている彼を呆れ顔で見つめる、典型的なツンデレタイプ。")
	heroine.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.8
	})


	hero.band("今日も数理モデルの講義をバックレたった...")
	hero.band("本気出せば主席でもいけるけどな。『異世界野球拳をオリンピック競技にする会』でかかりきりやし")
	hero.band("みのり には『また単位を落とすわよ』と呆れられたけど、ロマンを追う以外にどうやって青春を燃やせってんだ。")

	b.background("res://assets/backgrounds/bg02_room.png", 0.5)
	heroine.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "bottom",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "Default",
		"position_mode": "offset",
		"position": Vector2(0, -120),
	})
	hero.band("（部屋はエロゲ箱と政治パンフと教科書の雪崩。俺の人生を縮図みたく語ってくれるインスタレーションアートだ。）")
	hero.band("けど……単位があと三つ足りないのはガチで笑えない。目の前の編集済みセーブデータより、現実の単位をロードし直さないと。")
	hero.band("掲示板の『大型加速器実験補助、履修認定あり』って募集、まだ締切ってなかったはず。ギリギリ滑り込むしかない。")

	b.background("res://assets/backgrounds/bg03-1_lab.png", 0.5)
	hero.band("ここが噂の研究施設……SPring-8にそっくりじゃないか。")
	hero.band("受付嬢に防護メガネと白衣を手渡されて、制御室のボタンを押してくれってさ。数式中毒の俺からしたら、計測ログの生データに触れるだけでご褒美だ。")
	hero.band("これで単位を確保して、堂々と署名活動に専念――")
	b.clear_band_text() # バンドテキストをクリア
	b.hide_band()
	hero.hide_dialogue()

	b.background("res://assets/backgrounds/bg03-2_lab.png", 0.4)
	hero.say("うわっ！　制御盤が真っ白になってる!?　聞いてないぞ、こんなフラッシュ！", {"portrait": "Teleport"})
	hero.say("（身体の輪郭が空気に溶ける。慣性も重力も感じない。加速器って、テレポーターだったのかよ……！）", {"portrait": "Teleport"})

	b.background("res://assets/backgrounds/bg04_another_world.png", 0.5)
	hero.say("……空だ。雲が縦に流れてる。あれが異世界ってやつか。", {"portrait": "Teleport"})
	hero.say("平衡感覚が戻ると、俺は石造りの円形スペースに立っていた。観衆の視線、巨大なボード、そして中央に吊られた『勝率』のステータスバー……。")
	matilda.say("おいそこの新入り。ここは牢獄前闘技場だ。勝率を見せな。")
	hero.say("（すらっとした女看守。肩章からして階級も高い。いきなりラスボスの風格じゃないか。）", {"portrait": "Isekai"})
	matilda.say("名前は？　出身ギルドは？")
	hero.say("ギルド……？　いや、俺は――", {"portrait": "Isekai"})

	matilda.say("まあいい。ここに現れたってことは、皇女様に挑む資格を求めてるんだろ。だったら証拠を見せな。")
	hero.say("皇女？　いや、俺は単位が欲しいだけで――")
	matilda.say("異世界に飛ばされた学生さん、って顔してるな。だがここでは勝率が身分証だ。野球拳で四連勝すれば、ギルド通りに出る権利をやる。")
	hero.say("野球拳!?　異世界でも健在なのかよ！　俺に任せな。", {"portrait": "Isekai"})

	matilda.say("任せる？　ふふ、大口叩くね。私はマチルダ、牢番の門番。勝率を操作する術も訓練されてる。")
	hero.say("勝率の操作……それ、まさに俺が大学で研究してたやつだ。", {"portrait": "Isekai"})
	hero.say("（HUDに『数値化』のアイコン。どうやらスキルスロットに予備動作が入っている。今すぐ覚醒しそうだ。）", {"portrait": "Isekai"})
	matilda.say("どうした、固まって。初めての異世界は眺めるだけで精一杯か？")
	hero.say("いや……俺、まさかの異世界野球拳の主人公……！")

	matilda.say("落ち着け。深呼吸だ。ここでは冷静さも勝率に影響する。")
	hero.say("（呼吸を整えると、HUDから数式が浮かび上がった。『確率計算』スキルが解禁されたみたいだ。）", {"portrait": "Isekai"})
	hero.say("これで勝率の最適化ができる。まずはお姉さんを倒して、ギルド通りへ行く。", {"portrait": "Isekai"})
	matilda.say("お姉さん？　ふふ、面白い。いいだろう、数値の勇者さん。", {"portrait": "Default"})
	matilda.say("ただし一度勝ったくらいで調子に乗ると、すぐ丸裸だ。ここの観衆は勝率の上下に飢えてるからね。")
	hero.say("そっちの勝率も味わってもらうさ。", {"portrait": "Isekai"})

	b.background("res://assets/backgrounds/bg05_guard_room.png", 0.5)
	matilda.say("控室へ連れていこう。そこでスキルチュートリアルをやる。")
	hero.say("スキルチュートリアル……俺のMMO脳がうずく。", {"portrait": "Isekai"})
	matilda.say("はい、これが『確率計算』の第1段階。手札の勝率をざっくり表示する。使えば期待値がわかるよ。")
	hero.say("スキル、いきなり渡してくれるの？")
	matilda.say("私は門番で先生役。ここで変に詰まられたら仕事が増えるだろ？")
	hero.say("親切なんだか効率厨なんだか。ともあれサンキュー。", {"portrait": "Isekai"})

	matilda.say("さっそく勝率を見てみな。恐怖で手が震えてたらゼロに近づくし、落ち着けば盛り返す。自分の入力で上下してんのがわかるだろ。")
	hero.say("ほんとだ、心拍数も連動してる。これが異世界か……。", {"portrait": "Isekai"})
	matilda.say("ここからは地道な練習。カードを1枚ずつめくって、勝率の上がり下がりを身体に覚えさせな。")
	b.show_band()
	b.narrator_band("こうして主人公は勝率チュートリアルで汗を流し、本命の異世界野球拳ロードへと踏み出す。")
	hero.say("なるほど。HUDがレベルアップの階段みたいにつながってる。", {"portrait": "Isekai"})
	matilda.say("1段登るごとに『計算バフ』が解禁される。勝率予測→確率計算→真の確率計算→完全予測って感じ。")
	hero.say("完全予測って、いわゆる『このカードを出せば勝つ』ってやつだな。そこまで行けば異世界野球拳の覇王も夢じゃない。", {"portrait": "Isekai"})

	matilda.say("覇王？　はは、威勢がいい。そこまで行けりゃ皇女様にも会えるだろうね。")
	hero.say("皇女に勝って、異世界の国王になって、異世界スポーツ庁を作って、野球拳を国技にする。", {"portrait": "Isekai"})
	matilda.say("夢はでかい方がいい。けどまずはこの牢番を納得させな。")
	hero.say("望むところだ。")
	matilda.say("というわけで実戦チュートリアルだ。闘技スペースに戻ろう。")
	hero.say("うお、HUDがポップアップしてる！　次は『確率計算』、そのあと『真の確率計算』、最終的にはオートで最適手を出せる――みたいな階段ってわけだな。", {"portrait": "Isekai"})
	matilda.say("そこまで行けりゃ、ギルドの四天王にも挑戦できる。シスター、格闘家、宮廷魔術師、騎士団長……そいつらを野球拳で倒した者だけが皇女様への謁見を許される。")
	hero.say("皇女まで倒して、国王になればこの世界の設計者に会えるかも。よし、目標設定は完了だ。", {"portrait": "Isekai"})

	matilda.say("ただし牢番の私を突破できなきゃ話にならない。勝けばギルド通りへ出る許可を出してやる。負ければ、しばらく私のおもちゃ。どうする？")
	hero.say("（ムチムチなお姉さんに弄ばれるのも嫌いじゃないが……ここで勝って第一歩を刻む。）", {"portrait": "Isekai"})
	matilda.say("あんたが最初のボスってわけか。望むところだ。数値化スキルで勝率を叩き出してやる。")
	matilda.say("いい覚悟。でも油断するな。私は正規の門番、カード運用にも自信がある。")
	hero.say("こっちもCPU戦はSwitchで散々こなしたんでね。実戦で腕試しといこう。", {"portrait": "Isekai"})
	matilda.say("じゃあ牢前の闘技スペースへ。白いリングが描かれた場所で、服を賭けて踊りな。")
	hero.say("異世界野球拳、開幕だ。", {"portrait": "Isekai"})
