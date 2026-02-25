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
	matilda.say("さあ、ここで勝負だ。ルールは単純だよ。お互いカードを出し合って、負けたほうが一枚脱ぐ。先に全部剥がされたほうが負けさ。")
	hero.say("つまり、じゃんけんで脱がせ合い……やっぱり野球拳じゃないか。", {"portrait": "Isekai"})
	matilda.say("だからヤキュウケンは知らないって。あんたの手札は、さっきの基本デッキ5枚だ。グー・チョキ・パーの相性はわかるね？")
	hero.say("そのくらい子供でも知ってるさ。", {"portrait": "Isekai"})
	matilda.say("ふふ、チップを入れたばかりなのに余裕の顔だね。でもね、実戦はただの確率じゃない。相手の手の癖を読み、裏をかく駆け引きさ。")
	hero.say("駆け引き……まさに俺の専門だ。数学オタクをなめるなよ。", {"portrait": "Isekai"})
	matilda.say("じゃあ見せてもらおうか。異世界野球拳、始め！")

func _build_win(b):
	var hero: StoryCharacterHandle = b.character("main")
	var matilda: StoryCharacterHandle = b.character("matilda")

	b.background("res://assets/backgrounds/bg06_prison_arena.png", 0.5)
	hero.appear({"side": "left"})
	matilda.appear({"side": "right"})
	matilda.say("……やるじゃないか。本当に数学で勝率を上げるなんてね。ちょっと信じられないよ。")
	hero.say("理論は裏切らないのさ。", {"portrait": "Isekai"})
	matilda.say("はいはい。約束通り、あんたを出してやるよ。外ではこれを持ちなさい。最低限の装備だ。")
	hero.say("……パンツ一枚？　HPが1って、つまり一回負けたら全裸ってことか。", {"portrait": "Isekai"})
	matilda.say("贅沢言うんじゃないよ。タダで出してやるだけありがたいと思いな。ギルド通りに出たら、まずは冒険者ギルドで登録することだ。")
	hero.say("みのり、心配すんな。俺はたぶん、正しい場所に来たみたいだ。", {"portrait": "Isekai"})

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
