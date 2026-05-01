extends RefCounted
class_name Subevent2Chapter

# 背景（教会用素材）
const BG_GUILD := "res://assets/backgrounds/stage1/bg07_st1_001.png"
const BG_CHURCH_EXT := "res://assets/backgrounds/subevent2/bg01_church_exterior.png"
const BG_CHURCH_INT := "res://assets/backgrounds/subevent2/bg02_church_interior.png"
const BG_CHURCH_BACKYARD := "res://assets/backgrounds/subevent2/bg03_church_backyard.png"
const BG_CHURCH_CORRIDOR := "res://assets/backgrounds/subevent2/bg04_church_corridor.png"
const BG_PEEP_ROOM := "res://assets/backgrounds/subevent2/bg05_church_peep_room.png"
const BG_DUNGEON := "res://assets/backgrounds/subevent2/bg06_church_dungeon.png"

# キャラクター立ち絵（シスター関連は subevent2/ フォルダ）
const SISTER_HEAD_NORMAL := "res://assets/characters/subevent2/sister_head_001.png"
const SISTER_HEAD_SARCASM := "res://assets/characters/subevent2/sister_head_002.png"
const SISTER_HEAD_SAD := "res://assets/characters/subevent2/sister_head_003.png"
const SISTER_HEAD_ANGRY := "res://assets/characters/subevent2/sister_head_004.png"
const SISTER_HEAD_COMPOSED := "res://assets/characters/subevent2/sister_head_005.png"
const SISTER_HEAD_DEFEAT := "res://assets/characters/subevent2/sister_head_006.png"
const SISTER_HEAD_SHOUT := "res://assets/characters/subevent2/sister_head_007.png"
const SISTER_HEAD_LAUGH := "res://assets/characters/subevent2/sister_head_008.png"

const SISTER_A_ANXIOUS := "res://assets/characters/subevent2/sister_a_001.png"
const SISTER_A_PLEA := "res://assets/characters/subevent2/sister_a_002.png"
const SISTER_A_RESOLVE := "res://assets/characters/subevent2/sister_a_003.png"
const SISTER_A_SAD := "res://assets/characters/subevent2/sister_a_004.png"

# 受付嬢（stage1 既存流用）
const RECEP_NORMAL := "res://assets/characters/stage1/char10_st1_001.png"
const RECEP_HARD := "res://assets/characters/stage1/char10_st1_002.png"
const RECEP_SMILE := "res://assets/characters/stage1/char10_st1_003.png"
const RECEP_STERN := "res://assets/characters/stage1/char10_st1_004.png"

# 番兵（subevent1 既存流用）
const GUARD_NORMAL := "res://assets/characters/subevent1/guard_st2_001.png"
const GUARD_ANGRY := "res://assets/characters/subevent1/guard_st2_002.png"
const GUARD_TIRED := "res://assets/characters/subevent1/guard_st2_003.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "subevent2_pre1", "builder": "_build_subevent2_pre1"},
		{"id": "subevent2_pre2", "builder": "_build_subevent2_pre2"},
		{"id": "subevent2_post", "builder": "_build_subevent2_post"},
		{"id": "subevent2_battle_lose_retry", "builder": "_build_subevent2_battle_lose_retry"},
	]

# =============================================
# サブイベント2（前半1）: ギルド呼び出し〜シスターA相談
# 場面1〜3
# =============================================
func _build_subevent2_pre1(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")
	var sister_a = b.character("sister_a")

	b.set_protagonist("main")
	b.band_color("royal_blue")

	hero.leave({})

	# ============================================================
	# 場面1：冒険者ギルド・受付前
	# ============================================================
	b.label("scene_guild_call")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	hero.appear({
		"side": "left",
		"appear_effect": "fade_slide",
		"appear_from": "left",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": "res://assets/characters/stage1/char01_st1_006.png",
		# (旧スケール) "portrait_scale": 0.53,
		"portrait_scale": 0.6,
		"flip": 0,
		"position": [0, 70],
	})

	receptionist.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": RECEP_HARD,
		"portrait_scale": 0.45,
		"flip": 0,
	})

	receptionist.band("...サトシ様。少しよろしいですか。\n...お聞きしたいことがあります。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 74]})
	hero.band("（受付嬢から声をかけられた...！\nようやく俺の実力が認められて...！）")

	pisuke.band("おい。あの目は呼び出しじゃねえぞ。\n...取り調べの目だ。", {"side": "left"})

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 64]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 64]})
	hero.band("は、はい。なんでしょう？")

	receptionist.band("...単刀直入に伺います。\nサトシ様、ここ数日、聖アレクシア教会の周辺を\nうろついていませんでしたか？")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え？ いえ、行ってませ...")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_020.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 61]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_020.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 61]})
	hero.band("（...待て。三日前、ピー助に「妙な電波を感知した」と\n教会の裏手まで引きずり回されたよな...？）")

	pisuke.band("...おい。顔がギクッてなってるぞ。", {"side": "left"})

	receptionist.set_portrait(RECEP_STERN, {"side": "right", "flip": 0})
	receptionist.band("...今、何か思い当たりましたね。\n教会から「不審な若い男がうろついていた」と苦情が入っております。\n...特徴が、サトシ様にそっくりなのですが。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("ち、違うんです！ あれはピー助が勝手に...！")

	pisuke.band("...俺は他人には見えてねえからな。\n言えば言うほど、お前は頭のおかしい奴に見えるぞ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_047.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 9]})
	hero.band("（詰んだ...！）")

	receptionist.band("...前回の盗賊団のアジトの件、覚えていらっしゃいますか。\nサトシ様が「証拠品」として持ち帰ろうとしたあの...コレクション。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("あれは持ち帰ってません！ ピー助が勝手に...！")

	receptionist.band("...ギルドの記録には、しっかり残っております。\n「対象者：サトシ。傾向：女性の私物に強い執着」と。")

	pisuke.band("...おい、お前もう前科者扱いだぞ。", {"side": "left"})

	receptionist.set_portrait(RECEP_NORMAL, {"side": "right", "flip": 0})
	receptionist.band("...それで、本題ですが。\n教会の若いシスターが、先日ギルドに駆け込んできました。\n「更衣室に覗き穴がある」と。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 16]})
	hero.band("覗き穴！？ それ、本当の話なんですか？")

	receptionist.band("...ええ。それで、念のためお伺いしたのです。\nサトシ様が、何かご存じではないかと。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("俺、関係ないですよ！ 本当に！")

	receptionist.set_portrait(RECEP_SMILE, {"side": "right", "flip": 0})
	receptionist.band("...わかりました。一旦、信じます。\n...ただし、条件があります。")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("一旦？ 条件？")

	receptionist.band("この件、サトシ様に調査していただきます。\n...正式な依頼ではなく、非公式で。")

	hero.band("え、俺がですか？\n...それって、信用してくれてるってことですか？")

	receptionist.set_portrait(RECEP_STERN, {"side": "right", "flip": 0})
	receptionist.band("...いいえ。逆です。\n...サトシ様を野放しにしておくより、\n私の管理下で動かした方が安全だからです。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_037.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...。")

	receptionist.band("調査の進捗は、毎日この受付に報告してください。\n...不審な行動があれば、即座に騎士団へ引き渡します。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("これ、依頼じゃなくて保護観察じゃないですか！？")

	receptionist.set_portrait(RECEP_SMILE, {"side": "right", "flip": 0})
	receptionist.band("...ご理解いただけて何よりです。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_047.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 9]})
	hero.band("（目が、一切、笑ってない。\n...これ、断ったら本気で通報されるやつだ...。）")

	receptionist.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})

	b.hide_band()

	# ============================================================
	# 場面2：聖アレクシア教会・正面入り口
	# ============================================================
	b.label("scene_church_exterior")
	b.background(BG_CHURCH_EXT, 0.5)
	b.show_band()

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_015.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_015.png", {"scale": 0.6, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("ここが聖アレクシア教会か...。立派なもんだな。")

	hero.band("...で、どうすんだよ。正面から入るのか？\n奥の部屋とか、入れるのか？")

	pisuke.band("教会は誰でも入れる。まずは普通に中で情報を集めろ。\n...「懺悔」をしに来た信徒を装えば自然だろ。", {"side": "left"})

	pisuke.band("懺悔か。...まあ、お前は盗賊団のアジトで\nパンツコレクションに見入ってた前科があるからな。\n懺悔する内容には困らねえだろ。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("見入ってない！ お前が勝手に褒めたんだろ！\n...行くぞ。")

	b.hide_band()

	# ============================================================
	# 場面3：教会内部 → 裏庭
	# ============================================================
	b.label("scene_church_interior")
	b.background(BG_CHURCH_INT, 0.5)
	b.show_band()

	hero.set_portrait("res://assets/characters/prologue/char01_pg_038.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 74]})
	hero.band("（すごいな...。天井が高くて、光が差し込んで...。\nこんな場所で不正なんて、本当にやってるのか？）")

	b.narrator_band("柔らかな栗色の髪を白いヴェールの下にまとめた、若いシスターが、\n祈祷の列から抜け出し、慌てた様子でサトシへ小走りに近づいてくる。")

	sister_a.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 200,
		"portrait": SISTER_A_ANXIOUS,
		"portrait_scale": 0.85,
		"flip": 0,
		"position": [0, 60],
	})

	sister_a.band("あ、あの...！ あなた、もしかして冒険者ギルドの...？")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("え？ あ、はい。サトシです。")

	sister_a.set_portrait(SISTER_A_PLEA, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_a.band("よかった...！ 私、ギルドに相談に行ったシスターです。\n...ここでは話せません。裏庭に来てください。")

	b.hide_band()

	# 裏庭へ
	b.label("scene_church_backyard")
	b.background(BG_CHURCH_BACKYARD, 0.5)
	b.show_band()

	sister_a.set_portrait(SISTER_A_SAD, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_a.band("...シスター長が、更衣室の壁に小さな穴を開けているんです。\nそこから隣の「特別礼拝室」に覗けるようになっていて...。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("特別礼拝室...？")

	sister_a.band("表向きは「高額献金者のための祈祷室」ですが...\n実際は、覗き穴から私たちの着替えを見せる\n...「プレミアム礼拝サービス」なんです。")

	pisuke.band("「プレミアム礼拝サービス」...名前だけは上品だな。\nやってることは最低だが。", {"side": "left"})

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_020.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 61]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_020.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 61]})
	hero.band("それで献金額が異常に増えてたのか...。\nシスターたちは知ってるんですか？")

	sister_a.band("...薄々気づいている人もいます。でも、シスター長は教会の最高権力者です。\n逆らえば破門されてしまう...。")

	sister_a.set_portrait(SISTER_A_PLEA, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_a.band("...お願いです。証拠を押さえて、シスター長を止めてください。\nこのままでは、教会の信用が...。")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...わかりました。必ず暴きます。\nその「特別礼拝室」の場所、教えてください。")

	sister_a.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})

	b.hide_band()

# =============================================
# サブイベント2（前半2）: 廊下→礼拝室→シスター長対面→バトル
# 場面4
# =============================================
func _build_subevent2_pre2(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var sister_head = b.character("sister_head")
	var guard = b.character("guard")

	b.set_protagonist("main")
	b.band_color("royal_blue")

	# ============================================================
	# 場面4：教会廊下 → 特別礼拝室
	# ============================================================
	b.label("scene_church_corridor")
	b.background(BG_CHURCH_CORRIDOR, 0.5)
	b.show_band()

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_015.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_015.png", {"scale": 0.6, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("...ここか。鍵がかかってる。")

	pisuke.band("任せろ。この程度の電子錠ならチップ経由でハックできる。\n...ポチっとな。", {"side": "left"})

	b.narrator_band("重厚な金属錠の内部で、何かが滑らかに噛み合う微かな駆動音。\n続いて、カチリ──と決定的な音を響かせ、閂がひとりでに外れた。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 16]})
	hero.band("...お前、便利すぎないか。")

	pisuke.band("俺様を誰だと思ってる。...ほら、入れ。", {"side": "left"})

	b.hide_band()

	# 特別礼拝室
	b.label("scene_peep_room")
	b.background(BG_PEEP_ROOM, 0.5)
	b.show_band()

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("...これか。壁に穴が...。向こうは更衣室だな。")

	pisuke.band("おい、覗くなよ？ 証拠を押さえるのが先だ。", {"side": "left"})

	hero.band("覗かない！ ...覗かないって！")

	pisuke.band("...おい、あっちを見ろ。机の上に帳簿が置いてあるぞ。\n「プレミアム礼拝 顧客名簿」...。", {"side": "left"})

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 16]})
	hero.band("顧客名簿...！？ これ、完全な証拠じゃないか！")

	pisuke.band("中身をスキャンしたぞ。...すごいな。\n商人ギルド長、貴族院議員、王都警備隊長...。\nお得意様が権力者ばかりだ。誰も告発できなかったわけだ。\n...だが、この帳簿があれば話は別だ。", {"side": "left"})

	b.narrator_band("突然、扉が開く。")

	sister_head.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": SISTER_HEAD_NORMAL,
		"portrait_scale": 0.85,
		"flip": 0,
		"position": [0, 60],
	})

	sister_head.band("...あら。「特別礼拝室」にお客様？\n...予約制なのですけれど。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("！ シスター長...！")

	sister_head.set_portrait(SISTER_HEAD_SAD, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_head.band("...その帳簿、見てしまったのね。\n困ったわ。本当に困ったわ。")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("証拠は押さえました。この帳簿をギルドに持っていきます。")

	sister_head.set_portrait(SISTER_HEAD_SARCASM, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_head.band("ふふ。持っていく？ ...それは無理よ。")

	b.narrator_band("バタン！と扉が勢いよく開き、見覚えのある番兵たちが踏み込んできた。\n先頭の番兵がサトシを見た瞬間、その動きが止まった。")

	guard.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 150,
		"portrait": GUARD_NORMAL,
		"portrait_scale": 0.43,
		"flip": 0,
		"position": [-180, 62],
	})

	guard.band("通報を受けて駆けつけました！\n...「教会の特別礼拝室に不審な男が侵入した」と...\n......…は？\n...また、お前か！！")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_047.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 9]})
	hero.band("げっ...あ、あんた、あの時の...！")

	guard.set_portrait(GUARD_ANGRY, {"scale": 0.43, "side": "right", "flip": 0, "position": [-180, 62]})
	guard.band("...お前なぁ...。\nこっちは、お前の顔を見るのが今日で三回目だぞ。\n...街の真ん中ですっ裸で発見された「全裸転入者」。\nそんで先週は、盗賊団のアジトで女物の下着の前で硬直してた「変態冒険者」。\n...今回は教会の覗き部屋か。\n...お前、人生のどの瞬間を切り取っても通報案件だな？")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("違います！ 今回は調査で...！")

	sister_head.set_portrait(SISTER_HEAD_SAD, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_head.band("...あら、お知り合い？ ...ますます好都合ね。\n番兵の方々、この方、覗き穴の前で...ああ、口に出すのも恐ろしい。")

	hero.band("ちょ、違っ...俺は帳簿を──！")

	sister_head.set_portrait(SISTER_HEAD_NORMAL, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_head.band("「帳簿」？ ...何のことかしら。")

	guard.set_portrait(GUARD_TIRED, {"scale": 0.43, "side": "right", "flip": 0, "position": [-180, 62]})
	guard.band("...はぁ。三度目の現行犯、か。ほら、来い。")

	hero.band("ま、待って！ 違うんです、話を聞いて──！")

	# ピー助がサトシの声色を真似る
	hero.band("(ピー助)──待ってください、シスター長。\n神の御前で、じゃんけん勝負といきましょう。\n俺が勝ったら、無実を認めてください。\n負けたら、大人しく連行されます。\n...教会のあなたが、「神の裁き」を拒みはしないでしょう？")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 16]})
	hero.band("えっ！？ お、俺！？ 俺、今そんなこと言った！？\nい、言ってない！ 言ってないですよ！？")

	pisuke.band("黙ってろ。ここは賭けに出るしかねえ。", {"side": "left"})

	sister_head.set_portrait(SISTER_HEAD_COMPOSED, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_head.band("...ふふ。いいでしょう。神はきっと、真実を見ていらっしゃるわ。\n番兵の方々、席を外していただけるかしら。\n神聖な裁きに、余人は無用ですもの。")

	guard.band("...はぁ。まあ、お望みなら。")

	guard.leave({
		"exit_effect": "fade_slide",
		"exit_to": "right",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})

	pisuke.band("...ここで勝てば全部ひっくり返せる。やるぞ、サトシ。", {"side": "left"})

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...ああ。やってやる。")

	b.hide_band()

	# --- イベントバトル：シスター長戦 ---
	b.label("subevent2_boss_battle")
	b.set_flag("encounter_sister_long_seen", true)
	b.battle("res://battle/chapters/SisterBattleChapter.gd")

# =============================================
# サブイベント2（後半）: シスター長戦決着後〜ギルド帰還
# 場面5〜7
# =============================================
func _build_subevent2_post(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")
	var receptionist = b.character("receptionist")
	var sister_a = b.character("sister_a")
	var sister_head = b.character("sister_head")

	b.set_protagonist("main")
	b.band_color("royal_blue")

	# ============================================================
	# 場面5：教会・礼拝堂（決着後）
	# ============================================================
	b.label("scene_church_aftermath")
	b.background(BG_CHURCH_INT, 0.0)
	b.show_band()

	sister_head.set_portrait(SISTER_HEAD_DEFEAT, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_head.band("...そんな...。私が...負けるなんて...。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_046.png", {"scale": 0.5, "side": "left", "flip": 1, "position": [0, 9]})
	hero.band("...終わりです、シスター長。")

	# シスターAが駆けつける
	sister_a.appear({
		"side": "center",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.6,
		"appear_distance": 200,
		"portrait": SISTER_A_RESOLVE,
		"portrait_scale": 0.85,
		"flip": 0,
		"position": [200, 60],
	})

	sister_a.band("シスター長！ 私たち...全部見ていました！\nもう...隠せませんよ！")

	sister_head.band("...っ。")

	pisuke.band("よし、帳簿は確保した。チップにもデータをコピー済みだ。\nこれをギルド経由で騎士団に提出すりゃ...\n「プレミアム礼拝サービス」もおしまいだな。", {"side": "left"})

	sister_head.set_portrait(SISTER_HEAD_COMPOSED, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_head.band("...ふふ。やるじゃない、あなた。\n...まさか、あんな冴えない冒険者に負けるなんて。\n...でもね、覚えておきなさい。")

	sister_head.set_portrait(SISTER_HEAD_SARCASM, {"scale": 0.85, "side": "right", "flip": 0, "position": [0, 60]})
	sister_head.band("この世界で「清廉潔白」なんて幻想よ。\n権力を持てば、誰だって堕ちる。...あなたも、いずれね。")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_028.png", {"scale": 0.53, "side": "left", "flip": 1, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_028.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...俺は堕ちません。\n...たぶん。...いや、脱がすのは別問題として。")

	pisuke.band("最後の台無し感よ。", {"side": "left"})

	sister_head.leave({
		"exit_effect": "fade",
		"exit_duration": 0.6,
		"wait_for_exit": false,
	})

	sister_a.leave({
		"exit_effect": "fade",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})

	b.hide_band()

	# ============================================================
	# 場面6：ギルド帰還
	# ============================================================
	b.label("scene_guild_return")
	b.background(BG_GUILD, 0.5)
	b.show_band()

	b.narrator_band("帳簿は騎士団に提出され、シスター長は聖職を剥奪された。\n「プレミアム礼拝サービス」の顧客リストは王都中に知れ渡り、\n商人ギルド長をはじめとする常連客たちは社会的に抹殺された。")

	b.narrator_band("教会は新しいシスター長のもとで再建が始まった。\n若いシスターAがその任に就くことになったという。")

	receptionist.appear({
		"side": "right",
		"appear_effect": "fade_slide",
		"appear_from": "right",
		"appear_duration": 0.8,
		"appear_distance": 200,
		"portrait": RECEP_STERN,
		"portrait_scale": 0.45,
		"flip": 0,
	})

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_003.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_003.png", {"scale": 0.6, "side": "left", "flip": 0, "position": [0, 70]})

	receptionist.band("...サトシ様。")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 64]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.6, "side": "left", "flip": 0, "position": [0, 64]})
	hero.band("あ、はい！ 帰還しました！")

	receptionist.band("...一応、確認させてください。\n教会の件、結果は伺っております。\n...ですが、そこに至るまでの経緯について、\nいくつか不明な点が。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("不明な点...？")

	receptionist.band("まず、現場に駆けつけた番兵からの報告。\n「対象者サトシ、特別礼拝室の覗き穴の真正面で発見」と。")

	hero.band("ち、違うんです！ 部屋に入ったら、たまたま目の前に...！")

	receptionist.band("...次に、シスターAさんの証言。\n「サトシ様は、特別礼拝室に侵入した際、\nまっすぐ覗き穴のある壁に向かって歩いていった」と。")

	hero.band("それは構造的に部屋の正面が...！")

	receptionist.set_portrait(RECEP_SMILE, {"side": "right", "flip": 0})
	receptionist.band("...不審な男の徘徊、覗き部屋への侵入、覗き穴への直行。\n......。")

	b.narrator_band("受付嬢が、カウンターの端に置かれた封筒にそっと手を伸ばす。\n封蝋済み。宛名は「ギルド長殿 親展」。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_047.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 9]})
	hero.band("...え。え、え。ちょっと待って、待ってください。\n...その封筒、何ですか。...今、何をしようと...。")

	receptionist.band("...サトシ様が教会に向かわれた時点で、\n...念のため、下書きは用意しておりました。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("念のためって何ですか！？ 信頼ゼロじゃないですか！？")

	hero.band("お、俺、不正を暴いたんですよ！？ 結果、出してますよね！？\nギルド長に出さないで！ それだけは出さないで！")

	receptionist.set_portrait(RECEP_STERN, {"side": "right", "flip": 0})
	receptionist.band("......。")

	b.narrator_band("受付嬢はしばらく沈黙し、深いため息をついた。\nそして封筒を、カウンター下の引き出しにすっと戻す。")

	receptionist.band("...この件は、一旦、保留にいたします。\n...あくまで、「一旦」、です。")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 64]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_018.png", {"scale": 0.6, "side": "left", "flip": 0, "position": [0, 64]})
	hero.band("た、助かっ──")

	b.narrator_band("引き出しを閉める音。\n受付嬢は続けて、別の台帳を取り出して開いた。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_039.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 16]})
	hero.band("...えっ。")

	receptionist.band("...ですが、こちらは別件です。\n...サトシ様は本日付で、「要監視冒険者」に登録させていただきます。\n...こちらは、譲れません。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("ええっ！？ 報告書は保留なのに、監視は確定なんですか！？")

	receptionist.band("...報告書は、ギルド長のご判断が絡みますので。\n...監視登録は、私の判断で完結いたしますので。")

	hero.band("それ、一番怖いやつじゃないですか！？")

	b.narrator_band("受付嬢は羽根ペンで、氏名欄にさらさらと「サトシ」と記入した。")

	receptionist.band("...はい、報酬です。")

	b.narrator_band("受付嬢が、つまむように革袋をカウンターに置く。\nサトシの方には押しやらない。")

	# (旧スケール) hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.set_portrait("res://assets/characters/stage1/char01_st1_016.png", {"scale": 0.6, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("...あ、あの、これは...。")

	receptionist.band("...結果に対する報酬は、規約上、お渡ししないわけにはまいりませんので。\n...お渡しします。\n...渡します。\n...渡しますとも。")

	hero.band("本当に渡したくないんですね！？")

	receptionist.band("...盗賊団のアジトでは下着の展示に感嘆し、\n教会では覗き穴の部屋に侵入。\n...サトシ様。私の中で、サトシ様は完全に「要監視対象A」です。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_043.png", {"scale": 0.53, "side": "left", "flip": 0, "position": [0, 70]})
	hero.band("Aって何ですか！？ 他にもいるんですか！？")

	receptionist.band("...今のところ、サトシ様だけです。")

	b.narrator_band("受付嬢が、革袋を一センチだけサトシ側に押した。")

	receptionist.band("...どうぞ。")

	hero.set_portrait("res://assets/characters/prologue/char01_pg_047.png", {"scale": 0.5, "side": "left", "flip": 0, "position": [0, 9]})
	hero.band("（...教会の不正を暴いた英雄のはずなのに。\nなんで俺の犯罪者リストだけが充実していくんだ...。）")

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


# =============================================
# シスター長戦敗北時のシーケンス
# 場面4.5：教会地下牢・脱獄〜街潜伏〜ギルド帰還
# SisterBattleChapter.get_lose_redirect から呼ばれる
# =============================================
func _build_subevent2_battle_lose_retry(b):
	var hero = b.character("main")
	var pisuke = b.character("pisuke")

	b.set_protagonist("main")
	b.band_color("indigo")

	b.label("subevent2_battle_lose_retry")
	b.background(BG_DUNGEON, 0.5)
	b.show_band()

	b.narrator_band("サトシは番兵に拘束され、教会の地下牢に放り込まれた...。")

	hero.appear({
		"side": "left",
		"appear_effect": "fade",
		"appear_duration": 0.6,
		"portrait": "res://assets/characters/prologue/char01_pg_037.png",
		"portrait_scale": 0.6,
		"flip": 1,
		"position": [0, 70],
	})
	hero.band("(小声で) くそっ...こんなところに連れて来られて...。")

	pisuke.band("(小声) ゲコッ。これくらいの檻、俺様にかかれば余裕だ。\n看守の鍵、解析完了。今だ、出るぞ。", {"side": "left"})

	b.narrator_band("ピー助の機転で、サトシは地下牢を抜け出した。\n裏路地に身を潜め、夜が明けるのを待つ。\n教会側はサトシの脱獄に気付いていないらしい。")

	hero.set_portrait("res://assets/characters/stage1/char01_st1_007.png", {"scale": 0.6, "side": "left", "flip": 1, "position": [0, 70]})
	hero.band("...一旦、ギルドに戻る。\nカードは一部失った。立て直してから、もう一度あの聖女を叩く。")

	b.narrator_band("サトシは人通りに紛れ、ギルドホームへ戻った。")

	hero.leave({
		"exit_effect": "fade",
		"exit_duration": 0.6,
		"wait_for_exit": true,
	})
