extends StoryChapterBase
class_name Stage1Chapter

const StoryCharacterHandle := preload("res://resources/story/dsl/StoryCharacterHandle.gd")

func get_sequence_builders() -> Array:
	return [
		sequence_builder("stage1_intro", "_build_intro"),
		sequence_builder("stage1_win", "_build_win"),
		sequence_builder("battle_draw", "_build_battle_draw"),
		sequence_builder("battle_win", "_build_battle_win"),
		sequence_builder("battle_lose", "_build_battle_lose"),
	]

func _build_intro(b):
	var hero: StoryCharacterHandle = b.character("main")
	var matilda: StoryCharacterHandle = b.character("matilda")

	b.background("res://assets/backgrounds/bg06_prison_arena.png", 0.5)
	hero.appear({"side": "left"})
	matilda.appear({"side": "right"})
	hero.say("こぢんまりしてるけど、観客の視線が熱いな。王都の野球拳熱は本物か。", {"portrait": "Isekai"})
	matilda.say("ここが牢前の闘技スペース。床の白い円の中から出たら反則負けだよ。")
	matilda.say("ルールは単純。お互いのカード九枚で三本勝負。負けたら一枚脱ぎ、四枚剥けたら敗北。あんたが勝てばギルド通りの通行証を出す。")
	hero.say("そっちが看守なら、当然カード運用にも慣れてるんだろ？", {"portrait": "Isekai"})
	matilda.say("私は門番、つまりここを抜ける冒険者の尺度。手加減はしない。牢抜け新人に情けをかけたら、外で即死するからね。")
	hero.say("望むところ。さっそく初期デッキ十五枚の中から、勝率が高い並びを組んでみた。", {"portrait": "Isekai"})
	matilda.say("ふふ、数値化スキルを手に入れたばかりなのに、もう余裕の笑みか。だったらしばらく数字に振り回されてな。")
	hero.say("俺は数学オタクだぞ？　数字は親友だ。", {"portrait": "Isekai"})
	matilda.say("じゃあ、初戦だ。異世界野球拳、始め！")

func _build_win(b):
	var hero: StoryCharacterHandle = b.character("main")
	var matilda: StoryCharacterHandle = b.character("matilda")

	b.background("res://assets/backgrounds/bg06_prison_arena.png", 0.5)
	hero.appear({"side": "left"})
	matilda.appear({"side": "right"})
	matilda.say("くっ……本当に勝っちまうとはね。運値の差を読み切って、あっという間に四枚剥がされたよ。")
	hero.say("約束通り、外へ出してもらう。", {"portrait": "Isekai"})
	matilda.say("わかった。これがギルド通りの通行証。それと、牢番特製のカードケース。落とすんじゃないよ。")
	hero.say("サンキュー。あんたのカード運用、いいデータになった。", {"portrait": "Isekai"})
	matilda.say("次に会う時は門番じゃなく観客として応援してやるさ。だけど油断するな。ギルドで待ってる連中は、私とは比べものにならないよ。")
	hero.say("そっちも鍛えておけよ。どうせまた勝負するんだろ？", {"portrait": "Isekai"})
	matilda.say("ああ、今度は王都の中央アリーナでね。さっさと四天王への道を切り開いてきな。")
	hero.say("了解。異世界野球拳ロード、始まったばかりだ。", {"portrait": "Isekai"})

func _build_battle_draw(b):
	var hero: StoryCharacterHandle = b.character("main")
	var matilda: StoryCharacterHandle = b.character("matilda")

	hero.appear({"side": "left"})
	matilda.appear({"side": "right"})
	matilda.say("おっと、気が合うじゃないか！　あいこだ。もう一度勝負だよ！")
	hero.say("そう簡単には譲らないさ。", {"portrait": "Isekai"})

func _build_battle_win(b):
	var hero: StoryCharacterHandle = b.character("main")
	var matilda: StoryCharacterHandle = b.character("matilda")

	hero.appear({"side": "left"})
	matilda.appear({"side": "right"})
	matilda.say("くっ……やるじゃないか！　私の読みが外れるなんて……次は負けないよ！")
	hero.say("この調子で畳みかける。", {"portrait": "Isekai"})

func _build_battle_lose(b):
	var hero: StoryCharacterHandle = b.character("main")
	var matilda: StoryCharacterHandle = b.character("matilda")

	hero.appear({"side": "left"})
	matilda.appear({"side": "right"})
	matilda.say("あらあら、残念だったね。私の勝ちさ。もっと修行して出直してきな。")
	hero.say("まだまだこれからだ……！", {"portrait": "Isekai"})
