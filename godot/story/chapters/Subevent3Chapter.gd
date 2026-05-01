extends RefCounted
class_name Subevent3Chapter

# サブイベント3「呪われた鎧を脱がせ！」のストーリーシーケンス。
# 現状は **敗北時のリトライ用シーケンス** のみ実装。
# 場面1〜8 の本編シーケンスは未実装（ミニゲーム単体で動かしている）。

const BG_NOBLE_ROOM := "res://assets/backgrounds/subevent3/bg_noble_room.png"

func get_sequence_builders() -> Array:
	return [
		{"id": "subevent3_minigame_lose", "builder": "_build_subevent3_minigame_lose"},
		{"id": "subevent3_battle_lose", "builder": "_build_subevent3_battle_lose"},
	]

# =============================================
# ミニゲーム失敗時のシーケンス
# 加護度 130 到達時に再生される
# Subevent3MinigameChapter.get_lose_redirect から呼ばれる
# =============================================
func _build_subevent3_minigame_lose(b):
	var hero = b.character("main")
	var sebas = b.character("sebas")
	var fiona = b.character("fiona")

	b.set_protagonist("main")
	b.band_color("indigo")

	b.label("subevent3_minigame_lose")
	b.background(BG_NOBLE_ROOM, 0.5)
	b.show_band()

	b.narrator_band("水晶球は完全に漆黒に染まり、ピシリと小さなヒビが走った。\nフィオナの心は完全に閉ざされ、儀式は崩壊した。")

	fiona.band("...もう、結構です。...今日は、お引き取りください。")

	sebas.band("...本日は、ここまでに。\n...ご準備が整いましたら、改めてお越しくださいませ。")

	hero.appear({
		"side": "left",
		"appear_effect": "fade",
		"appear_duration": 0.4,
		"portrait": "res://assets/characters/prologue/char01_pg_037.png",
		"portrait_scale": 0.6,
		"flip": 1,
		"position": [0, 70],
	})
	hero.band("...くそっ。出直します...。")

	b.narrator_band("サトシは水晶球を抱え、エドモンド邸を辞した。\n...一度ギルドに戻り、態勢を立て直すしかない。")

	hero.leave({
		"exit_effect": "fade",
		"exit_duration": 0.4,
		"wait_for_exit": true,
	})

# =============================================
# カードバトル（フィオナ戦）敗北時のシーケンス
# 呪いが復活し、サトシが脱衣中継を停止して敗走するまで
# =============================================
func _build_subevent3_battle_lose(b):
	var hero = b.character("main")
	var sebas = b.character("sebas")

	b.set_protagonist("main")
	b.band_color("indigo")

	b.label("subevent3_battle_lose")
	b.background(BG_NOBLE_ROOM, 0.5)
	b.show_band()

	b.narrator_band("水晶球の色がふたたび漆黒へ戻り、鎧の亀裂が癒着していく。\n弱まっていた呪いの加護が、再び完全な形で立ち上がった。")

	b.narrator_band("水晶球の伝声塔中継は強制停止された。\n広場のスクリーンと王国中の伝声塔が一斉に暗転する。")

	sebas.band("...お、お若いの！ どうか、もう一度、水晶球から...！\nお嬢様を、よろしく、お願いいたします...！")

# 注: この後、Main.gd 側で共通ロスト・ナレーション
#     ({opponent}=セバス、A〜C 限定) が自動的に再生される。
