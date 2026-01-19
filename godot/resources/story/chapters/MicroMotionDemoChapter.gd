extends StoryChapterBase
class_name MicroMotionDemoChapter

func get_sequence_builders() -> Array:
	return [sequence_builder("micro_motion_demo", "_build_demo")]

func _build_demo(b):
	b.background("res://assets/backgrounds/bg01_university.png", 0.4)
	b.show_band()
	b.band("微細モーションデモを開始します。", {"speaker_id": "narrator"})
	b.band("各ステップは StoryScene 上でそのまま再生できるサンプルです。", {"speaker_id": "narrator"})

	b.micro_motion("property_animation", {
		"title": "1. プロパティ・アニメーション",
		"description": "AnimationPlayer で Sprite2D.texture を差し替えて、目パチ・口パクをループ再生します。",
	})
	b.pause(0.3)

	b.micro_motion("breathing_transform", {
		"title": "2. 階層トランスフォーム",
		"description": "Node2D の親子構造とサイン波スケールで呼吸/浮遊感を表現します。",
	})
	b.pause(0.3)

	b.micro_motion("bone_deformation", {
		"title": "3. デフォーメーション",
		"description": "Skeleton2D + Bone2D を使い、腕やマントを回転させながらリッチに動かします。",
	})
	b.pause(0.3)

	b.micro_motion("wind_shader", {
		"title": "4. 頂点シェーダ",
		"description": "ShaderMaterial で VERTEX を揺らし、風になびく髪や布を GPU だけで生成します。",
	})
	b.pause(0.3)

	b.micro_motion("tween_transition", {
		"title": "5. Tween による登場/退場",
		"description": "コードから create_tween() を呼び、TRANS_QUART + EASE_OUT でスライド演出を付けます。",
	})

	b.band("以上でデモは終了です。必要がなければ DefaultStory.gd の設定から無効化してください。", {"speaker_id": "narrator"})
	b.hide_dialogue()
