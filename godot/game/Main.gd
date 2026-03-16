extends Control

const DefaultStoryScript := preload("res://story/DefaultStory.gd")

signal result_updated(text)

@export var enable_story_playback := true

@onready var background_rect = $Background

var story_scene_scene = preload("res://StoryScene.tscn")
var battle_scene_scene = preload("res://BattleScene.tscn")
var story_scene_instance
var story_script: DefaultStory

var is_dialogue_active = false

# Global Event Flags
var event_flags = {}

# Player card inventory (persistent across battles)
# Format: [{"hand": "rock", "grade": 1}, ...]
var player_inventory: Array = []

func _ready():
	_init_player_inventory()
	if enable_story_playback:
		_create_story_scene()
		await scenario()

func _init_player_inventory():
	if player_inventory.is_empty():
		# Starting cards: 3 normal of each type = 9 cards
		for hand_key in ["rock", "scissors", "paper"]:
			for i in range(3):
				player_inventory.append({"hand": hand_key, "grade": 1})

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
	story_scene_instance.battle_requested.connect(_on_battle_requested)

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

# --- Battle bridge ---

func _on_battle_requested(cmd):
	if cmd.chapter == null:
		story_scene_instance.complete_battle("win")
		return
	story_scene_instance.visible = false
	var battle_instance = battle_scene_scene.instantiate()
	add_child(battle_instance)
	battle_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_instance.setup(story_script.get_cast(), story_scene_instance.background_rect.texture, player_inventory)
	battle_instance.start_battle(cmd.chapter)
	var result: String = await battle_instance.battle_finished

	# Process card exchange
	var rewards = battle_instance.get_battle_rewards()
	if result == "win":
		# Player wins: gain opponent's lost cards, keep own cards
		for card in rewards.captured_by_player:
			player_inventory.append(card.duplicate())
	elif result == "lose":
		# Player loses: lose own lost cards
		for card in rewards.captured_by_opponent:
			_remove_card_from_inventory(card)
	# draw: no card exchange

	cmd.result = result
	battle_instance.queue_free()
	story_scene_instance.visible = true
	story_scene_instance.complete_battle(result)

func _remove_card_from_inventory(card: Dictionary):
	for i in range(player_inventory.size()):
		if player_inventory[i].hand == card.hand and int(player_inventory[i].grade) == int(card.grade):
			player_inventory.remove_at(i)
			return
