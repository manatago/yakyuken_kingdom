extends Control

const DefaultStoryScript := preload("res://resources/story/DefaultStory.gd")
const DefaultOpponentData := preload("res://resources/characters/DefaultGirl.tres")
const DefaultRockTexture := preload("res://assets/battle/cards/rock.jpg")
const DefaultScissorsTexture := preload("res://assets/battle/cards/scissors.jpg")
const DefaultPaperTexture := preload("res://assets/battle/cards/paper.jpg")
const DefaultCardBackTexture := preload("res://assets/battle/cards/card_back.png")
const DefaultBattleBackgroundTexture := preload("res://assets/backgrounds/prologue/bg06_prison_arena.png")
const DefaultBattleChapterPath := "res://resources/battle/chapters/PrologueBattleChapter.gd"

signal ui_updated(turn, max_turns, player_wins, cpu_wins, draws)
signal result_updated(text)
signal opponent_spoke(text)
signal game_over(result_text)
signal opponent_updated(data)
signal battle_chapter_applied(chapter)

@export_file("*.gd") var battle_chapter_script_path: String = DefaultBattleChapterPath
@export var enable_story_playback := true

var opponent_data: CharacterData = DefaultOpponentData

var player_win_rate: float = 0.7
var draw_rate: float = 0.2
var player_lose_rate: float = 0.1

@onready var background_rect = $Background
@onready var info_label = $VBoxContainer/InfoLabel
@onready var result_label = $VBoxContainer/ResultLabel
@onready var cpu_hand_container = $VBoxContainer/CPUHandContainer
@onready var player_hand_container = $VBoxContainer/PlayerHandContainer
@onready var battle_area = $VBoxContainer/BattleArea
@onready var cpu_played_card = $VBoxContainer/BattleArea/CPUSlot/CPUPlayedCard
@onready var player_played_card = $VBoxContainer/BattleArea/PlayerSlot/PlayerPlayedCard
@onready var restart_button = $VBoxContainer/RestartButton
@onready var game_ui = $VBoxContainer

var story_scene_scene = preload("res://StoryScene.tscn")
var story_scene_instance
var story_script: DefaultStory

enum GameState { INTRO, BATTLE, RESULT }
var current_state = GameState.INTRO

enum Hand { ROCK, SCISSORS, PAPER }
const HAND_NAMES = {Hand.ROCK: "グー", Hand.SCISSORS: "チョキ", Hand.PAPER: "パー"}

var card_textures = {
	Hand.ROCK: DefaultRockTexture,
	Hand.SCISSORS: DefaultScissorsTexture,
	Hand.PAPER: DefaultPaperTexture,
}
var card_back_texture: Texture2D = DefaultCardBackTexture
var select_prompt_text := "カードを選んでください"
var final_result_texts := {
	"win": "You Win!",
	"lose": "You Lose...",
	"draw": "Draw",
}
var battle_chapter: CardBattleChapterBase
var battle_background_path := ""

var player_hand = []
var cpu_hand = []
var player_wins = 0
var cpu_wins = 0
var draws = 0
var turn_count = 0
const MAX_TURNS = 3

var is_dialogue_active = false

signal turn_finished

# Global Event Flags
var event_flags = {}

func _ready():
	_apply_default_battle_assets()
	_load_battle_chapter()
	restart_button.pressed.connect(_on_restart_pressed)

	if enable_story_playback:
		_create_story_scene()
	else:
		story_scene_instance = null
		current_state = GameState.BATTLE
		game_ui.visible = true

	# Notify listeners about the opponent
	opponent_updated.emit(opponent_data)

	# Hide internal labels as we use HUD now
	info_label.visible = false
	result_label.visible = false

	# Ensure styles are applied after UI is built
	_setup_styles()

	# Start the main game scenario or jump straight to battle
	if enable_story_playback:
		await scenario()
	else:
		await start_game()

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

func _apply_default_battle_assets():
	opponent_data = DefaultOpponentData
	player_win_rate = 0.7
	draw_rate = 0.2
	player_lose_rate = 0.1
	card_textures[Hand.ROCK] = DefaultRockTexture
	card_textures[Hand.SCISSORS] = DefaultScissorsTexture
	card_textures[Hand.PAPER] = DefaultPaperTexture
	card_back_texture = DefaultCardBackTexture
	if background_rect:
		background_rect.texture = DefaultBattleBackgroundTexture
	select_prompt_text = "カードを選んでください"
	final_result_texts = {
		"win": "You Win!",
		"lose": "You Lose...",
		"draw": "Draw",
	}

func _load_battle_chapter():
	var path = battle_chapter_script_path.strip_edges()
	if path.is_empty():
		return
	var script = load(path)
	if script == null:
		push_warning("Failed to load battle chapter script: %s" % path)
		return
	var instance = script.new()
	if instance is CardBattleChapterBase:
		battle_chapter = instance
		_apply_battle_chapter_settings()
	else:
		push_warning("Battle chapter must extend CardBattleChapterBase: %s" % path)

func _apply_battle_chapter_settings():
	if not battle_chapter:
		return
	var opponent_path = battle_chapter.opponent_resource_path()
	var loaded_opponent = _load_resource(opponent_path)
	if loaded_opponent:
		opponent_data = loaded_opponent
	var card_paths = battle_chapter.card_texture_paths()
	_apply_card_textures(card_paths)
	var back_texture = _load_texture(battle_chapter.card_back_texture_path())
	if back_texture:
		card_back_texture = back_texture
	var win_config = battle_chapter.win_rate_config()
	player_win_rate = win_config.get("player", player_win_rate)
	draw_rate = win_config.get("draw", draw_rate)
	player_lose_rate = win_config.get("cpu", player_lose_rate)
	select_prompt_text = battle_chapter.select_prompt_text()
	final_result_texts = battle_chapter.final_result_texts()
	battle_background_path = battle_chapter.battle_background_texture_path()
	_apply_background_texture(battle_background_path)
	battle_chapter.configure_main(self)
	battle_chapter_applied.emit(battle_chapter)

func _apply_card_textures(paths: Dictionary):
	if paths.is_empty():
		return
	var rock = _load_texture(paths.get("rock", ""))
	if rock:
		card_textures[Hand.ROCK] = rock
	var scissors = _load_texture(paths.get("scissors", ""))
	if scissors:
		card_textures[Hand.SCISSORS] = scissors
	var paper = _load_texture(paths.get("paper", ""))
	if paper:
		card_textures[Hand.PAPER] = paper

func _load_texture(path: String) -> Texture2D:
	var resource = _load_resource(path)
	if resource and resource is Texture2D:
		return resource
	return null

func _load_resource(path: String):
	if path.is_empty():
		return null
	return load(path)

func _apply_background_texture(path: String):
	if not background_rect:
		return
	var texture = _load_texture(path)
	if texture:
		background_rect.texture = texture
	elif DefaultBattleBackgroundTexture:
		background_rect.texture = DefaultBattleBackgroundTexture

func get_battle_chapter() -> CardBattleChapterBase:
	return battle_chapter

func get_battle_background_path() -> String:
	return battle_background_path

# --- SCENARIO & STAGES ---

func scenario():
	# Play the demo and jump straight into the first card battle
	var demo_sequence = story_script.get_sequence("demo")
	if demo_sequence:
		await story_scene_instance.play_sequence(demo_sequence, {"id": "demo"})

	await _play_stage("prologue", MAX_TURNS, "stage1_win")

	print("All Stages Cleared!")

# --- GENERIC STAGE FUNCTIONS ---

# Play a scene with only dialogue (no battle)
func _play_scene(sequence_key):
	current_state = GameState.INTRO
	game_ui.visible = false

	await story_scene_instance.play_sequence(story_script.get_sequence(sequence_key), {"id": sequence_key})

# Play a stage with dialogue -> battle -> result dialogue
func _play_stage(intro_sequence_key, turns, win_sequence_key):
	# 1. Intro Dialogue
	current_state = GameState.INTRO
	game_ui.visible = false
	await story_scene_instance.play_sequence(story_script.get_sequence(intro_sequence_key), {"id": intro_sequence_key})

	# 2. Battle
	current_state = GameState.BATTLE
	game_ui.visible = true
	await _run_rpg_battle(turns)

	# 3. Result
	current_state = GameState.RESULT
	game_ui.visible = false

	if player_wins > cpu_wins:
		await story_scene_instance.play_sequence(story_script.get_sequence(win_sequence_key), {"id": win_sequence_key})
	else:
		# For now, just play a generic lose timeline or restart
		await story_scene_instance.play_sequence(story_script.get_sequence("battle_lose"), {"id": "stage_loss"})

# --- RPG BATTLE SYSTEM ---

func _run_rpg_battle(max_turns):
	# Reset game state for new battle
	await start_game(true)

	# Loop for each turn
	for i in range(max_turns):
		print("Turn Start: ", i + 1)

		# Wait for the player to finish one turn
		await turn_finished

		# Check for Global Events (Interrupts)
		await _check_global_events()

		# Check if game should end early (optional rule)
		# if player_wins >= 2: break

# --- GLOBAL EVENT SYSTEM ---

func _check_global_events():
	# --- EVENT: Enemy gets angry if losing ---
	# Condition: Player has 2 wins AND event hasn't happened yet
	if player_wins == 2 and not event_flags.get("enemy_angry", false):
		event_flags["enemy_angry"] = true
		print("EVENT: Enemy Angry! Difficulty UP!")

		# 1. Pause Battle UI
		game_ui.visible = false

		# 2. Change Battle Parameters (Effect)
		player_win_rate = 0.3 # Make it harder for player!

		# 3. Play Event Dialogue (placeholder text for now)
		result_updated.emit("敵が本気を出した！勝率が下がった！")

		# 4. Resume Battle UI
		game_ui.visible = true

	# --- EVENT: Sub-event example ---
	# Condition: Turn 2 finished
	if turn_count == 3 and not event_flags.get("turn_2_talk", false):
		event_flags["turn_2_talk"] = true
		# Insert some mid-battle banter
		pass

func _on_story_sequence_started(_sequence_id):
	is_dialogue_active = true
	_set_hand_enabled(false)

func _on_story_sequence_finished(_sequence_id):
	is_dialogue_active = false
	_set_hand_enabled(current_state == GameState.BATTLE)
	if current_state == GameState.BATTLE:
		result_updated.emit(select_prompt_text)


func _setup_styles():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.border_color = Color.TRANSPARENT
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0

	for slot in cpu_hand_container.get_children():
		if slot is PanelContainer: slot.add_theme_stylebox_override("panel", style)
	for slot in player_hand_container.get_children():
		if slot is PanelContainer: slot.add_theme_stylebox_override("panel", style)

	$VBoxContainer/BattleArea/CPUSlot.add_theme_stylebox_override("panel", style)
	$VBoxContainer/BattleArea/PlayerSlot.add_theme_stylebox_override("panel", style)

func start_game(show_prompt: bool = true):
	player_hand = _generate_hand()
	cpu_hand = _generate_hand()
	player_wins = 0
	cpu_wins = 0
	draws = 0
	turn_count = 1

	restart_button.visible = false
	player_played_card.texture = null
	cpu_played_card.texture = null
	result_updated.emit("")
	_update_ui()

	# Wait a frame to ensure Table3D is ready to receive the signal
	await get_tree().process_frame
	if show_prompt:
		result_updated.emit(select_prompt_text)

func _generate_hand():
	var hand = []
	for i in range(MAX_TURNS):
		hand.append(Hand.values().pick_random())
	return hand

func _update_ui():
	ui_updated.emit(min(turn_count, MAX_TURNS), MAX_TURNS, player_wins, cpu_wins, draws)

	# Update CPU Hand (Show back of cards)
	var cpu_slots = cpu_hand_container.get_children()
	for slot in cpu_slots:
		for child in slot.get_children(): child.queue_free()

	for i in range(cpu_hand.size()):
		if i < cpu_slots.size():
			var card = TextureButton.new()
			card.texture_normal = card_back_texture
			card.ignore_texture_size = true
			card.stretch_mode = TextureButton.STRETCH_SCALE
			card.disabled = true
			cpu_slots[i].add_child(card)
			card.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Update Player Hand
	var player_slots = player_hand_container.get_children()
	for slot in player_slots:
		for child in slot.get_children(): child.queue_free()

	for i in range(player_hand.size()):
		if i < player_slots.size():
			var card = TextureButton.new()
			card.texture_normal = card_textures[player_hand[i]]
			card.ignore_texture_size = true
			card.stretch_mode = TextureButton.STRETCH_SCALE
			card.pressed.connect(_on_card_selected.bind(i))
			player_slots[i].add_child(card)
			card.set_anchors_preset(Control.PRESET_FULL_RECT)

func _on_card_selected(index):
	if turn_count > MAX_TURNS or is_dialogue_active:
		return

	# Disable input immediately
	_set_hand_enabled(false)

	# Hide "Select Card" message
	result_updated.emit("")

	var player_card = player_hand.pop_at(index)

	# --- Determine CPU Card based on Win Rates ---
	var r = randf()
	var desired_outcome = "" # "WIN", "LOSE", "DRAW" relative to PLAYER

	if r < player_win_rate:
		desired_outcome = "WIN"
	elif r < player_win_rate + draw_rate:
		desired_outcome = "DRAW"
	else:
		desired_outcome = "LOSE"

	var target_cpu_card = -1

	if desired_outcome == "DRAW":
		target_cpu_card = player_card
	elif desired_outcome == "WIN":
		# Player wins, so CPU needs to lose
		# Rock(0) beats Scissors(1), Scissors(1) beats Paper(2), Paper(2) beats Rock(0)
		if player_card == Hand.ROCK: target_cpu_card = Hand.SCISSORS
		elif player_card == Hand.SCISSORS: target_cpu_card = Hand.PAPER
		elif player_card == Hand.PAPER: target_cpu_card = Hand.ROCK
	else: # LOSE
		# Player loses, so CPU needs to win
		if player_card == Hand.ROCK: target_cpu_card = Hand.PAPER
		elif player_card == Hand.SCISSORS: target_cpu_card = Hand.ROCK
		elif player_card == Hand.PAPER: target_cpu_card = Hand.SCISSORS

	# Check if CPU has the target card
	var cpu_card_index = -1
	if target_cpu_card in cpu_hand:
		cpu_card_index = cpu_hand.find(target_cpu_card)
	else:
		# Cheat! Replace a random card in CPU hand with target card
		cpu_card_index = randi() % cpu_hand.size()
		cpu_hand[cpu_card_index] = target_cpu_card
		print("DEBUG: Cheated to force outcome: ", desired_outcome)

	var cpu_card = cpu_hand.pop_at(cpu_card_index)
	# ---------------------------------------------

	# Get references to the actual card nodes before they are removed/hidden
	var player_card_node = player_hand_container.get_child(index).get_child(0)
	var cpu_card_node = cpu_hand_container.get_child(cpu_card_index).get_child(0)

	# Hide the played cards immediately (so we can animate copies)
	player_card_node.modulate.a = 0
	cpu_card_node.modulate.a = 0

	# Animate cards moving to the center
	# Fire animations in parallel (they handle their own cleanup)
	_animate_card_move(player_card_node, player_played_card, card_back_texture)
	_animate_card_move(cpu_card_node, cpu_played_card, card_back_texture)

	# Animate remaining cards shifting to fill the gap
	_animate_hand_shift(index, player_hand_container)
	_animate_hand_shift(cpu_card_index, cpu_hand_container)

	# Wait for animations to finish (0.5s duration defined in _animate_card_move)
	await get_tree().create_timer(0.5).timeout

	# Show backs of cards immediately (texture set by animation, but ensure it's set on the actual node)
	player_played_card.texture = card_back_texture
	cpu_played_card.texture = card_back_texture

	# Update UI to remove cards from hand
	_update_ui()

	# Wait 1 second
	await get_tree().create_timer(1.0).timeout

	# Reveal CPU card
	await _flip_card(cpu_played_card, card_textures[cpu_card])

	# Wait 1 second
	await get_tree().create_timer(1.0).timeout

	# Reveal Player card
	await _flip_card(player_played_card, card_textures[player_card])

	# Determine winner
	var result_msg = await _evaluate_turn(player_card, cpu_card)
	result_updated.emit(result_msg)

	# Update score (emit ui_updated with new values)
	ui_updated.emit(min(turn_count, MAX_TURNS), MAX_TURNS, player_wins, cpu_wins, draws)

	turn_count += 1

	# Notify that the turn is fully complete
	turn_finished.emit()

func _set_hand_enabled(enabled: bool):
	for slot in player_hand_container.get_children():
		for child in slot.get_children():
			if child is TextureButton:
				child.disabled = !enabled

func _flip_card(card: TextureRect, target_texture: Texture2D):
	# Set pivot to center for rotation effect
	card.pivot_offset = card.size / 2

	var tween = create_tween()
	# Scale X to 0 (close)
	tween.tween_property(card, "scale:x", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Swap texture
	tween.tween_callback(func(): card.texture = target_texture)
	# Scale X back to 1 (open)
	tween.tween_property(card, "scale:x", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished

func _animate_card_move(start_node: Control, end_node: Control, texture: Texture2D):
	var temp_card = TextureRect.new()
	temp_card.texture = texture
	temp_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	temp_card.stretch_mode = TextureRect.STRETCH_SCALE
	temp_card.size = start_node.size
	temp_card.global_position = start_node.global_position
	temp_card.pivot_offset = temp_card.size / 2
	add_child(temp_card)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(temp_card, "global_position", end_node.global_position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(temp_card, "size", end_node.size, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Also match rotation if needed, but we assume 0 for now

	await tween.finished
	temp_card.queue_free()

func _animate_hand_shift(gap_index: int, container: Control):
	var slots = container.get_children()
	# Iterate through slots to the right of the gap
	for i in range(gap_index + 1, slots.size()):
		var slot = slots[i]
		if slot.get_child_count() > 0:
			var card = slot.get_child(0)
			if card is TextureButton:
				# Create a temporary duplicate for animation
				var temp_card = TextureRect.new()
				temp_card.texture = card.texture_normal
				temp_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				temp_card.stretch_mode = TextureRect.STRETCH_SCALE
				temp_card.size = card.size
				temp_card.global_position = card.global_position
				add_child(temp_card)

				# Hide original
				card.modulate.a = 0

				# Target position is the previous slot's position
				var target_slot = slots[i - 1]
				var target_pos = target_slot.global_position

				var tween = create_tween()
				tween.tween_property(temp_card, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

				# Cleanup
				tween.finished.connect(func(): temp_card.queue_free())

func _evaluate_turn(p, c):
	var result = "DRAW"
	if p == c:
		draws += 1
		result = "DRAW"
	elif (p == Hand.ROCK and c == Hand.SCISSORS) or \
		 (p == Hand.SCISSORS and c == Hand.PAPER) or \
		 (p == Hand.PAPER and c == Hand.ROCK):
		player_wins += 1
		result = "WIN"
	else:
		cpu_wins += 1
		result = "LOSE"

	if enable_story_playback and story_scene_instance and story_script:
		var sequence_id = "battle_draw"
		if result == "WIN":
			sequence_id = "battle_win"
		elif result == "LOSE":
			sequence_id = "battle_lose"
		await story_scene_instance.play_sequence(story_script.get_sequence(sequence_id), {"id": sequence_id})

	return result

func _end_game():
	var final_result = ""
	if player_wins > cpu_wins:
		final_result = final_result_texts.get("win", "You Win!")
		# TODO: Hook up a dedicated victory sequence
	elif cpu_wins > player_wins:
		final_result = final_result_texts.get("lose", "You Lose...")
		# TODO: Hook up a dedicated defeat sequence
	else:
		final_result = final_result_texts.get("draw", "Draw")
		# TODO: Hook up a dedicated draw sequence

	# result_label.text = final_result
	result_updated.emit(final_result)
	# restart_button.visible = true # Handled by HUD now
	game_over.emit(final_result)

func _on_restart_pressed():
	start_game()
