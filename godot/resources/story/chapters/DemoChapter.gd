extends RefCounted
class_name DemoChapter

func get_sequence_builders() -> Array:
	return [{"id": "demo", "builder": "_build_demo"}]

func _build_demo(b):
	b.background("res://assets/backgrounds/bg01_university.png", 0.4)
	b.show_band()
	b.band("キャラクターリグ腕振りデモを開始します。", {"speaker_id": "narrator"})

	# 右腕を3回振る
	b.micro_motion("arm_swing", {
		"title": "右腕スイング",
		"description": "右腕のみを-10度から+10度まで3回振ります。",
		"arm": "right",
		"angle_min": -10,
		"angle_max": 10,
		"repeat_count": 3,
		"duration": 1.0,
	})

	# 左腕を3回振る
	b.micro_motion("arm_swing", {
		"title": "左腕スイング",
		"description": "左腕のみを-10度から+10度まで3回振ります。",
		"arm": "left",
		"angle_min": -10,
		"angle_max": 10,
		"repeat_count": 3,
		"duration": 1.0,
	})

	b.band("以上でデモは終了です。", {"speaker_id": "narrator"})
	b.hide_dialogue()
