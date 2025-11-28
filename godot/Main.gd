extends Control

signal ui_updated(turn, max_turns, player_wins, cpu_wins, draws)
signal result_updated(text)
signal opponent_spoke(text)
signal game_over(result_text)
signal opponent_updated(data)

@export var opponent_data: CharacterData

@onready var info_label = $VBoxContainer/InfoLabel
@onready var result_label = $VBoxContainer/ResultLabel
@onready var cpu_hand_container = $VBoxContainer/CPUHandContainer
@onready var player_hand_container = $VBoxContainer/PlayerHandContainer
@onready var battle_area = $VBoxContainer/BattleArea
@onready var cpu_played_card = $VBoxContainer/BattleArea/CPUSlot/CPUPlayedCard
@onready var player_played_card = $VBoxContainer/BattleArea/PlayerSlot/PlayerPlayedCard
@onready var restart_button = $VBoxContainer/RestartButton

enum Hand { ROCK, SCISSORS, PAPER }
const HAND_NAMES = {Hand.ROCK: "グー", Hand.SCISSORS: "チョキ", Hand.PAPER: "パー"}

var card_textures = {
	Hand.ROCK: preload("res://assets/rock.jpg"),
	Hand.SCISSORS: preload("res://assets/scissors.jpg"),
	Hand.PAPER: preload("res://assets/paper.jpg")
}
var card_back_texture = preload("res://assets/card_back.png")

var player_hand = []
var cpu_hand = []
var player_wins = 0
var cpu_wins = 0
var draws = 0
var turn_count = 0
const MAX_TURNS = 3

var is_dialogue_active = false

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)

	# Load default character if none selected
	if not opponent_data:
		opponent_data = load("res://resources/characters/DefaultGirl.tres")

	# Notify listeners about the opponent
	opponent_updated.emit(opponent_data)

	# Hide internal labels as we use HUD now
	info_label.visible = false
	result_label.visible = false

	# Initialize game (deal cards, show UI)
	await start_game()

	# Ensure styles are applied after UI is built
	_setup_styles()

	# Initial greeting
	Dialogic.start("res://timelines/start.dtl")

func _process(delta):
	# Poll Dialogic state to handle input locking
	var dialogic_active = (Dialogic.current_timeline != null)

	if dialogic_active != is_dialogue_active:
		is_dialogue_active = dialogic_active
		_set_hand_enabled(!is_dialogue_active)

		if is_dialogue_active:
			# Don't hide the result message (WIN/LOSE) when dialogue starts
			pass
		else:
			result_updated.emit("カードを選んでください")
			# Check if game over happened while dialogue was playing
			if turn_count > MAX_TURNS:
				_end_game()

func _on_timeline_started():
	is_dialogue_active = true
	_set_hand_enabled(false)
	# result_updated.emit("") # Don't hide prompt

func _on_timeline_ended():
	is_dialogue_active = false
	_set_hand_enabled(true)
	result_updated.emit("カードを選んでください")

	# Check if game over happened while dialogue was playing
	if turn_count > MAX_TURNS:
		_end_game()

func _setup_styles():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 2
	style.border_width_top = 4 # Thicker top border to prevent cutoff
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	# Add margins so the card is inside the border
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4

	for slot in cpu_hand_container.get_children():
		if slot is PanelContainer: slot.add_theme_stylebox_override("panel", style)
	for slot in player_hand_container.get_children():
		if slot is PanelContainer: slot.add_theme_stylebox_override("panel", style)

	$VBoxContainer/BattleArea/CPUSlot.add_theme_stylebox_override("panel", style)
	$VBoxContainer/BattleArea/PlayerSlot.add_theme_stylebox_override("panel", style)

func start_game():
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
	result_updated.emit("カードを選んでください")

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
	# CPU picks a random card from their hand
	var cpu_card_index = randi() % cpu_hand.size()
	var cpu_card = cpu_hand.pop_at(cpu_card_index)

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
	var result_msg = _evaluate_turn(player_card, cpu_card)
	result_updated.emit(result_msg)

	# Update score (emit ui_updated with new values)
	ui_updated.emit(min(turn_count, MAX_TURNS), MAX_TURNS, player_wins, cpu_wins, draws)

	turn_count += 1

	# Note: We don't wait for Dialogic here anymore.
	# Dialogic.start() was called in _evaluate_turn.
	# The _on_timeline_started signal will handle locking input.

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
	if p == c:
		draws += 1
		Dialogic.start("res://timelines/draw.dtl")
		return "DRAW"
	elif (p == Hand.ROCK and c == Hand.SCISSORS) or \
		 (p == Hand.SCISSORS and c == Hand.PAPER) or \
		 (p == Hand.PAPER and c == Hand.ROCK):
		player_wins += 1
		Dialogic.start("res://timelines/win.dtl")
		return "WIN"
	else:
		cpu_wins += 1
		Dialogic.start("res://timelines/lose.dtl")
		return "LOSE"

func _end_game():
	var final_result = ""
	if player_wins > cpu_wins:
		final_result = "You Win!"
		# Dialogic.start("game_win") # Create this timeline later
	elif cpu_wins > player_wins:
		final_result = "You Lose..."
		# Dialogic.start("game_lose") # Create this timeline later
	else:
		final_result = "Draw"
		# Dialogic.start("game_draw") # Create this timeline later

	# result_label.text = final_result
	result_updated.emit(final_result)
	# restart_button.visible = true # Handled by HUD now
	game_over.emit(final_result)

func _on_restart_pressed():
	start_game()
