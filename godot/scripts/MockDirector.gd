extends Node

# 舞台（StoryScene）への参照を持つ
# エディタ上で、StorySceneノードをここに割り当てる
@export var story_scene: Control

func _ready():
	# 1秒待つ
	await get_tree().create_timer(1.0).timeout

	# 監督「左の役者、喋れ！」
	print("監督: 左へ指示")
	story_scene.show_dialogue("left", "監督からの指示だ！\nまずは左！")

	# さらに2秒待つ
	await get_tree().create_timer(2.0).timeout

	# 監督「右の役者、位置をずらして喋れ！」
	print("監督: 右へ指示")
	story_scene.show_dialogue("right", "了解！\n右も反応するぞ！", Vector2(0, -20))
