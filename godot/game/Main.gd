extends Control

const DefaultStoryScript := preload("res://story/DefaultStory.gd")

signal result_updated(text)

@export var enable_story_playback := true

@onready var background_rect = $Background

var story_scene_scene = preload("res://StoryScene.tscn")
var story_scene_instance
var story_script: DefaultStory

var is_dialogue_active = false

# Global Event Flags
var event_flags = {}

func _ready():
	if enable_story_playback:
		_create_story_scene()
		await scenario()

func _create_story_scene():
	story_scene_instance = story_scene_scene.instantiate()
	add_child(story_scene_instance)
	story_scene_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if background_rect and background_rect.get_parent() == self:
		var insert_index = background_rect.get_index() + 1
		move_child(story_scene_instance, insert_index)
	else:
		move_child(story_scene_instance, 0)
	story_script = DefaultStoryScript.new()
	story_scene_instance.set_cast(story_script.get_cast())
	story_scene_instance.sequence_started.connect(_on_story_sequence_started)
	story_scene_instance.sequence_finished.connect(_on_story_sequence_finished)

# --- SCENARIO & STAGES ---

func scenario():
	await _play_scene("prologue")
	print("All Stages Cleared!")

# Play a scene with only dialogue
func _play_scene(sequence_key):
	var seq = story_script.get_sequence(sequence_key)
	if seq:
		await story_scene_instance.play_sequence(seq, {"id": sequence_key})

func _on_story_sequence_started(_sequence_id):
	is_dialogue_active = true

func _on_story_sequence_finished(_sequence_id):
	is_dialogue_active = false
