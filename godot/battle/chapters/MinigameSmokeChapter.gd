extends BattleChapterBase

# ミニゲーム基盤の最小スモークテスト。
# BattleScene を minigame モードで起動し、
# narrator_band/wait が動作することを目視確認する。

func get_opponent_id() -> String:
	return "smoke"

func get_opponent_name() -> String:
	return "スモーク"

func get_battle_background() -> String:
	return "res://assets/backgrounds/stage1/bg07_st1_001.png"

func setup_scene(bt):
	bt.narrator_band("【ミニゲーム基盤スモークテスト】")

func minigame(bt):
	await bt.wait(1.0)
	bt.narrator_band("ミニゲームモード起動成功。")
	await bt.wait(2.0)
	bt.narrator_band("カードUIが非表示で、ストーリー層のみ動作しています。")
	await bt.wait(2.5)
	bt.narrator_band("スモークテスト完了。\nクリックか待機で終了します。")
	await bt.wait(2.5)
	return "win"
