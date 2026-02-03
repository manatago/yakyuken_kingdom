extends StoryChapterBase
class_name MicroMotionDemoChapter

func get_sequence_builders() -> Array:
	return [sequence_builder("micro_motion_demo", "_build_demo")]

func _build_demo(b):
	b.background("res://assets/backgrounds/bg01_university.png", 0.4)
	b.show_band()
	b.band("微細モーションデモを開始します。", {"speaker_id": "narrator"})
	b.band("各ステップは StoryScene 上でそのまま再生できるサンプルです。", {"speaker_id": "narrator"})

	b.micro_motion("wind_shader", {
		"title": "頂点シェーダ",
		"description": "ShaderMaterial で VERTEX を揺らし、風になびく髪や布を GPU だけで生成します。",
	})

	b.band("以上でデモは終了です。必要がなければ DefaultStory.gd の設定から無効化してください。", {"speaker_id": "narrator"})
	b.hide_dialogue()
