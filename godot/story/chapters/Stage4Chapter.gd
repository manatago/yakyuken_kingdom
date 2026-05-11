extends RefCounted
class_name Stage4Chapter

# Stage4: セレス編（挑戦状 → 潜入失敗 → 対面 → 初戦敗北 → ミニゲーム → 再戦勝利）
# 詳細シナリオ: docs/scenarios/stage4_scenario.txt

const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const BG_BACK := "res://assets/backgrounds/stage4/bg_military_back_wall.png"
const BG_ALLEY := "res://assets/backgrounds/prologue/bg06_prison_arena.png"
const BG_RESTING := "res://assets/backgrounds/stage2/bg_guild_resting.png"
const BG_DOJO := "res://assets/backgrounds/stage4/bg_dojo_third.png"

const HERO_NORMAL := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_017.png"
const HERO_DREAD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_018.png"
const HERO_SHOCK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"
const HERO_PROTEST := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_039.png"
const HERO_AWKWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_014.png"
const HERO_TIRED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_027.png"
const HERO_NERVOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_028.png"
const HERO_SERIOUS := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_032.png"
const HERO_RESOLVE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_021.png"
const HERO_DAZED := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_030.png"
const HERO_GLOOM := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_038.png"
const HERO_HOPE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_036.png"
const HERO_FORWARD := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_028.png"
const HERO_GUILTY := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_034.png"
const HERO_INSPIRE := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_009.png"
const HERO_RESIGN := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_029.png"
const HERO_DESPAIR := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_048.png"
const HERO_BLANK := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_041.png"

const RECEP_NORMAL := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_005.png"
const RECEP_JIT := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_008.png"
const RECEP_COLD := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_007.png"
const RECEP_BUSINESS := "res://assets/characters/main/receptionist/clothed/receptionist_clothed_006.png"
const SELES := "res://assets/characters/main/seles/clothed/seles_clothed_001.png"
const MAGE_STAFF := "res://assets/characters/mob/mage_staff/default/mage_staff_default_001.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "stage4_pre", "builder": "_build_stage4_pre"},
		{"id": "stage4_infiltrate", "builder": "_build_stage4_infiltrate"},
		{"id": "stage4_meet", "builder": "_build_stage4_meet"},
		{"id": "stage4_contract", "builder": "_build_stage4_contract"},
		{"id": "stage4_recover", "builder": "_build_stage4_recover"},
		{"id": "stage4_post", "builder": "_build_stage4_post"},
		{"id": "stage4_close", "builder": "_build_stage4_close"},
	]

# =========================================================
# 場面1: ギルド・挑戦状
# =========================================================
func _build_stage4_pre(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage4_pre")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.45, "side": "right"})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NORMAL, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	receptionist.band("サトシ様。本日、貴殿宛てに、大変、重い書状がございます。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...嫌な予感しかしない。")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.45, "side": "right"})
	receptionist.band("...魔法師団長セレス・ソルヴェイグ様より、正式なご指名勝負の\n挑戦状でございます。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("魔法師団長！ って、戦争の時に最前線に立つ人でしょう！？")

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.45, "side": "right"})
	receptionist.band("...はい。現役の王都四傑の一角でございます。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("俺、冒険者だぞ！ 格が違いすぎる！")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.45, "side": "right"})
	receptionist.band("...挑戦状の名目は「王都四傑の一角として、連勝中の異邦冒険者の\n実力を直接見極めたい」とのことでございます。")

	pisuke.band("...無害な文面だな。公式には「親善的な実力検証」って体裁だ。", {"side": "left"})

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.45, "side": "right"})
	receptionist.band("...なお、挑戦状には、追記がございます。")

	receptionist.band("「師団本部・第三演習場にて、観客入場不可の条件で実施。\n魔道器具による記録を行う。\n使用する魔術・技能の事前申告は不要。不意打ち・隠し技、\n双方自由とする」")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("観客不可、記録あり、不意打ちも自由...なんか、不穏ですね。")

	pisuke.band("普通の決闘なら、使う魔術や技能は前もって相手に伝え合う慣習だ。\nそれを「不要」と指定してきた。何を仕掛けてくるか、こっちは\n全く分からねえぞ。", {"side": "left"})

	receptionist.set_portrait(RECEP_BUSINESS, {"scale": 0.45, "side": "right"})
	receptionist.band("...なお、挑戦状は既に受理済みでございます。当方に拒否権は\nございません。\n...お心づもりを、ご自身で、お立てください。")

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.45, "side": "right"})
	receptionist.band("...ご健闘を、とは、申し上げません。\n...いずれ、敗れる相手だろうと、私は、思っております。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("えっ、な、なんで俺が負ける前提で話すんですか！？")

	receptionist.band("...魔法師団長様は、王国外との魔術戦の最終兵器。\n国の命運を背負うお方に、一介の冒険者が勝てる確率は、ギルド統計上、\n約一割でございます。")

	pisuke.band("ギルド統計、お前みたいな奴に合わせてねえだろ、絶対。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})
	receptionist.leave({"exit_effect": "fade", "exit_duration": 0.3})

# =========================================================
# 場面2+2.5+2.6: 潜入提案→警報→撤退→作戦立て直し
# =========================================================
func _build_stage4_infiltrate(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage4_infiltrate")
	b.background(BG_ALLEY, 0.5)
	b.show_band()

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_DREAD, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	pisuke.band("サトシ、こいつ、正攻法じゃ勝てねえ。\nこれまでのパターンを踏襲しよう。事前に、弱みを握る。", {"side": "left"})

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("また、弱み探し？")

	pisuke.band("ああ。師団本部の裏手、研究室がある。公的記録じゃ読めないデータが、\nそこに眠ってるはずだ。\n...チップ経由でハックして、夜のうちに内部記録を抜く。", {"side": "left"})

	hero.set_portrait(HERO_RESIGN, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...嫌な予感しかしないけど、行くしかないか。")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面2.5: 外壁・警報
	b.background(BG_BACK, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NERVOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	pisuke.band("...外壁ギリギリまで近寄れ。そこで、俺様が接続を試みる。", {"side": "left"})

	pisuke.band("...接続...接続...あっ、ブロックされた。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え？")

	pisuke.band("魔道封印が、こっちのハック手法を先読みしてる。\n...しかも、防御だけじゃねえ。逆探知も走ってやがる。", {"side": "left"})

	b.narrator_band("頭上で魔道警報の甲高い音が響く。壁の魔法陣が一斉に赤く光る。")

	b.narrator_band("「侵入者検知。魔法師団本部、裏手、外壁付近。聖霊系の反応あり」")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、え、え、俺らの存在、バレてる！？")

	pisuke.band("ゲコッ、撤退だ、今すぐ！", {"side": "left"})

	b.narrator_band("衛兵の足音が複数方向から接近する。サトシは慌てて裏路地に駆け込んだ。")

	hero.set_portrait(HERO_TIRED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ピー助、今の、完全に記録されたよね！？ 顔は見られてないけど、\nあの反応の仕方...！")

	pisuke.band("...ゲコッ。まずい。こっちの「接続手法の指紋」が、向こうの\n防御ログに残った。師団長が見れば、「何者かが師団本部の魔道\nネットワークにハックを試みた」って即座に分かる。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("それが、俺の仕業だって、特定されたら...！？")

	pisuke.band("...次の対面で、セレス本人から、直接、問い詰められるだろうな。\n向こうは確信犯扱いで来るぞ。", {"side": "left"})

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面2.6: 作戦立て直し
	b.background(BG_RESTING, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	pisuke.band("公的記録だけは読めた。...ただ、中身は乾ききってる。\n冷徹。部下に厳格。独身。公演説歴ゼロ。趣味：魔法研究。", {"side": "left"})

	hero.set_portrait(HERO_SERIOUS, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("公的記録が「完璧すぎる」って、逆に怪しいパターン、ですよね。")

	pisuke.band("...お前、成長したな。そうだ、正解だ。自分から「完璧」を見せたがる\n心理こそ、隠し事の証だ。\n...だが、中に入れない以上、詳細は掴めねえ。\n戦闘中に拾う。それしか手がない。", {"side": "left"})

	hero.band("...初戦は、データ収集目的か。")

	pisuke.band("ああ。勝ちにいくな。データだけ取って、撤退しろ。\n...それより、さっきの潜入失敗、バレてるぞ。\n向こうの態度が、格段に硬くなる可能性が高い。", {"side": "left"})

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("俺、卑怯者認定、更に格上げされるパターンじゃ...？")

	pisuke.band("ゲコッ。濃厚、だな。", {"side": "left"})

# =========================================================
# 場面3+4: 第三演習場・対面 → 初戦（固定敗北）
# =========================================================
func _build_stage4_meet(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var seles = b.character("seles")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage4_meet")
	b.background(BG_DOJO, 0.5)
	b.show_band()

	seles.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": SELES, "portrait_scale": 0.45, "position": [0, 10],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_NERVOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	seles.band("...お待たせした、サトシ殿。セレス・ソルヴェイグだ。")

	hero.band("あ、はじ、はじめまして、サトシです。")

	seles.band("本日は、王都四傑の一角として、貴殿の実力を、直接、見極めさせて\nいただく。")

	seles.band("...ところで、サトシ殿。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("は、はい。")

	seles.band("昨夜、師団本部の裏手、外壁付近にて、魔道ネットワークへの不正\nアクセスの痕跡が、残されております。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（...！ 来た！）")

	seles.band("ご丁寧に、聖霊系の反応まで、検知されております。\n...この国で、聖霊を帯同する冒険者は、極めて、稀でございます。\n...心当たりは、ございますか。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、いや、あの、それは、その...！")

	pisuke.band("サトシ、落ち着け。具体的に特定されてるわけじゃねえ。", {"side": "left"})

	seles.band("...否定なさいますか。\n結構。否定するのは、貴殿の、自由でございます。")

	seles.band("ですが、私には、貴殿が「相手の弱みを握って、戦いを有利に進める\n卑怯な男」であるという、強い、心証がございます。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("そ、それは、誤解で...！")

	seles.band("...先のアサシン・レイラ殿との戦、聖女マグダレナ殿との戦。\n貴殿が勝利なさった経緯、私なりに、研究させていただきました。\n...完全には、読み切れていない。ですが、貴殿の勝ち方には、共通する\n不自然さが、ございます。")

	seles.band("...そこで、本日の勝負に、一つ、条件を、付けさせていただきます。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("条件？")

	seles.band("私が勝った場合、貴殿には、「秘密保持の魔道契約」を、結んで\nいただきます。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("秘密、保持...？")

	seles.band("貴殿が、本勝負、並びに本日までに知り得た、私に関する一切の事柄を、\n二度と、第三者に口外できなくなる、という契約でございます。\n...口外を試みた瞬間、魔道封印により、言葉が、消えます。")

	hero.set_portrait(HERO_PROTEST, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ええ！？ それ、ほぼ、奴隷契約じゃ...！")

	seles.band("...「秘密保持契約」でございます。言葉の選び方、お間違えなきよう。")

	seles.band("ルールは通常の三本勝負。\n...なお、私は、本試合にて、師団長個人の秘技「縛鎖魔法」を、\n使用する。詳細は、発動時にご覧に入れる。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("縛鎖、魔法...？")

	seles.band("新開発の個人術である。師団にも公式登録はしていない。\n...貴殿にとっては、全く初見の術になるだろう。")

	seles.band("...では、始めよう。")

	b.hide_band()
	b.label("stage4_battle1_start")
	# 初戦（固定敗北・縛鎖魔法で完敗）
	b.battle("res://battle/chapters/Stage4BattleChapter.gd")

# =========================================================
# 場面4.5+4.6: 契約執行→ピー助解析・解除
# =========================================================
func _build_stage4_contract(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var seles = b.character("seles")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage4_contract")
	b.background(BG_DOJO, 0.5)
	b.show_band()

	seles.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": SELES, "portrait_scale": 0.45, "position": [0, 10],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_GLOOM, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	seles.band("...勝負、ありでございます。")

	seles.band("では、約定通り、秘密保持契約を、執行いたします。\nこの魔法陣の上に、手を、置いてください。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、いや、あの、それ、本当に、やるんですか...！")

	seles.band("...敗者の義務でございます。")

	pisuke.band("...サトシ、飲むしかねえ。この場で断れば、魔道不敬罪で、\nその場で拘束される。あとで、俺様が、なんとかする。", {"side": "left"})

	b.narrator_band("サトシ、渋々、魔法陣に手を置く。魔法陣が赤から青へ変色し、喉元に微細な魔道刻印が刻まれた。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（うわっ...なんか、喉がチリチリする...！）")

	seles.band("これで、契約は成立。\n...以後、本日までに貴殿が知り得た、私に関する一切の事柄。\nそれを第三者に口外しようとした瞬間、喉の刻印が発動し、言葉が\n魔道的に消去されます。")

	seles.band("...なお、再戦の権利は、慣習として、一度だけ、認めます。\n三日後、同演習場にて。")

	hero.set_portrait(HERO_RESOLVE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("再戦、お願いします。")

	seles.band("結構。\n...ですが、結果は変わりません。縛鎖魔法が破れる道理は、ございません。\n...そして、仮に奇跡が起きても、契約の刻印は、消えません。\n貴殿が勝っても、本日までに知り得た秘密は、生涯、口外できません。")

	hero.set_portrait(HERO_GLOOM, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（...勝っても、負けても、秘密は封じられる、仕組みか...！）")

	seles.leave({"exit_effect": "fade", "exit_duration": 0.5})
	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面4.6: ギルド休憩室で解析
	b.background(BG_RESTING, 0.5)
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("ピー助、この、喉の刻印...。")

	pisuke.band("...ちょっと待て、スキャンする。\n...ほう、魔道契約式、階層3か。高度だな。だが、俺様の権限なら、\n解除可能だ。", {"side": "left"})

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("できるの！？ よかった...！")

	pisuke.band("ただし、解除には、契約式の内部構造を完全にリバースする必要がある。\n...で、内部構造ってのは、術者の「核」で組まれてる。\n魔道契約式は、術者の「深層の魔力パターン」を鍵にしてる。\n解除のためには、俺様が、セレスの深層パターンを、丸ごと読み解く\n必要がある。", {"side": "left"})

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("つまり...？")

	pisuke.band("ゲコッ。...セレスの「心の中身」が、刻印経由で、筒抜けになる。\n本人が隠したい秘密も、全部、読めちまう。", {"side": "left"})

	pisuke.band("...サトシ、聞いて驚け。", {"side": "left"})

	hero.set_portrait(HERO_FORWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("？")

	pisuke.band("セレス、ドMだ。特に、「自分が縛られて、身動きが取れなくなる」\n構図が、深層魔力の核そのものになってる。\n...毎晩、自分を縛って、妄想に浸る習慣がある。", {"side": "left"})

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、え、師団長、そういう人なの！？")

	pisuke.band("さらに言うと、「魔法縛の術式解析」って論文を大量に書いてる。\n表向きは対魔族拘束術の研究だが、内容は、自分に施す拘束魔法の\n精度向上の記録だ。挿絵は全部、自画像。縛られた状態の。", {"side": "left"})

	hero.set_portrait(HERO_BLANK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...研究という体で、自己緊縛の記録を、公的論文にしてる...？")

	pisuke.band("ゲコッ。本人は「これは研究だ」と信じてる。自分の性癖として\n自覚してない。", {"side": "left"})

	pisuke.band("そして縛鎖魔法、あれの魔力源が、本人のドM願望だ。\n相手を縛る魔法を使うたび、深層では「縛られたい自分」を妄想している。\nその妄想濃度が、魔法の威力そのものになってる。", {"side": "left"})

	hero.set_portrait(HERO_INSPIRE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...それ、弱点、そのものじゃないか！")

	pisuke.band("ゲコッ。ビンゴだ。\n「縛る／縛られる」の向きの非対称性を戦闘中に崩せば、縛鎖は自分に\n跳ね返る。縛鎖が自分を縛る。", {"side": "left"})

	hero.set_portrait(HERO_SERIOUS, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("で、契約の刻印は？")

	pisuke.band("深層パターン、完全解読。...解除作業、完了。", {"side": "left"})

	hero.set_portrait(HERO_HOPE, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、もう！？")

	pisuke.band("ゲコッ。俺様を、誰だと思ってる。\nただし、セレス本人には、解除したことをバラすな。表面上は、\n刻印が有効なフリを続けろ。再戦で、不意を突ける。", {"side": "left"})

# =========================================================
# 場面5+6+7: ミニゲーム準備→再戦中強度合わせ→勝利
# =========================================================
func _build_stage4_recover(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage4_recover")
	b.background(BG_RESTING, 0.5)
	b.show_band()

	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_SERIOUS, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	hero.band("で、その「ドM」を、どうやって戦闘中に突くんだ？")

	pisuke.band("...ドMの本質は、「強度を合わせること」だ。\n最初から侮辱を浴びせると、プライドが反発して固まる。\n軽い命令から始めて、徐々に侮辱まで持っていく必要がある。", {"side": "left"})

	pisuke.band("戦闘中、彼女の「魔法集中」ゲージを表示する。\n- 赤ゾーン（高集中）：プライドが固い。軽口（命令口調）が刺さる。\n- 黄〜緑ゾーン（崩れ気味）：プライド剥がれてくる。侮辱で深部を抉れ。\nゾーンに合わない強度を投げると、サトシ側が決まり悪くなって +5 自傷。", {"side": "left"})

	hero.band("...ゾーンを見ながら、強度を切り替えるんだな。")

	pisuke.band("毎ターン、軽口 1 件 ＋ 侮辱 1 件 ＋ 当たり障りのないハズレ 1 件 ＋\n「ピー助任せ」の 4 択が出る。\nハズレは常に +5、選ぶ意味なし。\n迷ったら「ピー助任せ」、現ゾーンの正解強度を俺様が選ぶ。", {"side": "left"})

	hero.band("...ちなみに、秘密保持契約の刻印は、本当に、解けてるんだよな？")

	pisuke.band("ゲコッ。完璧だ。だが、本人の前ではあるフリをしろ。\n勝負中、お前が秘密に触れても、「刻印に弾かれて言葉にできない」って\n体裁が保てる。", {"side": "left"})

	hero.band("なるほど...。")

	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

	# 場面6: 再戦中のミニゲーム
	b.background(BG_DOJO, 0.5)

	b.hide_band()
	b.label("stage4_minigame_start")
	b.minigame("res://battle/chapters/Stage4MinigameChapter.gd")

	# ミニゲーム成功後、再戦
	b.set_flag("stage4_first_battle_done")
	b.show_band()
	b.label("stage4_battle2_start")
	b.battle("res://battle/chapters/Stage4BattleChapter.gd")

# =========================================================
# 場面8: 決着後・セレスの倒錯的執着
# =========================================================
func _build_stage4_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var seles = b.character("seles")
	var mage = b.character("mage_staff")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage4_post")
	b.background(BG_DOJO, 0.5)
	b.show_band()

	seles.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": SELES, "portrait_scale": 0.45, "position": [0, 10],
	})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_GUILTY, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	seles.band("...完敗、だ。\n...検証は、完了した。...結果は、師団内部記録として、残す。")

	hero.band("...お疲れさまでした。")

	seles.band("...サトシ殿。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("は、はい。")

	seles.band("...本日、貴殿は、私の、最も深い、場所を、暴いた。\n...私の研究、私の論文、私の公的な顔、その全てが、実は、\n私自身の「隠された願望」の、隠蔽だった。...そのことを、私に、\n突きつけた。")

	seles.band("...ありがたく、ない。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("そ、そうですよね、すみません...。")

	seles.band("...だが、不思議と、貴殿を、憎みきれない。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え？")

	seles.band("...貴殿は、私を、言葉で、徹底的に、支配した。\n...あの、「逆に引く」「強く締める」という、私の結び目に、\n貴殿の指示が、直接、刻まれた。")

	seles.band("...それは、私の、研究の、最高到達点だった。\n...本物の、被験者体験を、貴殿が、与えてくれた。")

	seles.band("...それに、貴殿は、刻印を、巧みに、かいくぐった。\n私の秘密そのものには、決して、直接、触れず。\n魔法陣の仕組みにだけ、指示を与える、という形で。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（...ピー助、契約、とっくに解除してくれてるんだよな！？）")

	pisuke.band("ゲコッ。黙ってろ。こいつ、「刻印は有効」と信じたまま、敗因を\n「技術的な隙」と整理してる。その方が、こっちに都合がいい。", {"side": "left"})

	seles.band("...本来、不可能なはずの勝ち方を、貴殿は、見事、成立させた。")

	hero.set_portrait(HERO_DREAD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("（え、なんだ、この雲行き...。）")

	seles.band("...サトシ殿。\n...本日以降、私の、全ての研究は、「貴殿への対抗術式の開発」に、\n捧げられる。")

	hero.set_portrait(HERO_DAZED, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("はい？")

	seles.band("そして、その「研究」とは、貴殿を、師団の研究室に、被験体として、\n生涯、拘束する術式の開発、である。")

	hero.set_portrait(HERO_SHOCK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ええ！？")

	seles.band("次、お会いする時、私は、必ず、貴殿を、捕獲する。\n...そして、今度は、私が、貴殿を、「研究対象」として、結び上げる。")

	seles.band("...楽しみに、しております。")

	pisuke.band("ゲコッ。...サトシ、これ、一生つけ狙われる系の執着を付与したぞ。", {"side": "left"})

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("勝ったのに、捕獲予告が出た...！")

	mage.appear({
		"side": "right", "appear_effect": "fade", "appear_duration": 0.4,
		"portrait": MAGE_STAFF, "portrait_scale": 0.4, "position": [200, 100],
	})
	seles.band("師団員、本日の結果を、公式通達に。\n「魔法師団長、冒険者サトシに敗北。以降、対策研究を、個人研究として、\n無期限で継続する」と。")

	mage.band("しょ、承知いたしました...。", {"side": "right"})

	mage.leave({"exit_effect": "fade", "exit_duration": 0.3})
	seles.leave({"exit_effect": "fade", "exit_duration": 0.5})
	hero.leave({"exit_effect": "fade", "exit_duration": 0.5, "wait_for_exit": true})

# =========================================================
# 場面9: ギルド帰還
# =========================================================
func _build_stage4_close(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")

	b.set_protagonist("main")
	b.band_color("royal_blue")
	b.label("stage4_close")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	receptionist.set_portrait(RECEP_NORMAL, {"scale": 0.45, "side": "right"})
	hero.appear({
		"side": "left", "appear_effect": "fade", "appear_duration": 0.5,
		"portrait": HERO_TIRED, "portrait_scale": 0.5, "flip": 1, "position": [0, 70],
	})

	receptionist.band("サトシ様。...魔法師団本部からの、公式通達、受領いたしました。\n「魔法師団長、敗北。技量検証、完了」。")

	hero.band("あ、はい。勝ちました。")

	receptionist.set_portrait(RECEP_COLD, {"scale": 0.45, "side": "right"})
	receptionist.band("...なお、師団長から、サトシ様宛ての個人書簡が、同封されて\nございます。")

	hero.set_portrait(HERO_AWKWARD, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え、...嫌な予感。")

	b.narrator_band("書簡：「次にお会いする時が、待ち遠しく存じます。——セレス」")

	hero.set_portrait(HERO_BLANK, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ピー助、これ、アサシンのレイラさんと、似たような...。")

	pisuke.band("ゲコッ。二人目の終生執着者が誕生、だな。\nお前、生涯、つけ狙われる女が、また一人増えたぞ。", {"side": "left"})

	receptionist.set_portrait(RECEP_JIT, {"scale": 0.45, "side": "right"})
	receptionist.band("...ギルドの「要監視対象A」摘要欄に、追記いたします。\n「対象、王国高官二名より個人的追跡対象として認定。暗部調査部門の\nアサシン、および、魔法師団長。以後、王都滞在時の、生命の危機、\n増加の可能性あり」。")

	hero.set_portrait(HERO_DESPAIR, {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ギルド、本気で俺の死亡リスク管理始めた...！")

	b.set_flag("stage4_complete")
