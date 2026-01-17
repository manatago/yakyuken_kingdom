extends Control

const StoryScriptResource := preload("res://resources/story/DefaultStory.gd")

@onready var story_scene := $StoryScene

func _ready():
	print("--- StoryScene smoke test ---")
	var script := StoryScriptResource.new()
	story_scene.set_cast(script.get_cast())
	await story_scene.play_sequence(script.get_sequence("prologue"), {"id": "test_prologue"})
	print("--- Sequence finished ---")
