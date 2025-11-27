extends Control

@onready var info_label = $VBoxContainer/InfoLabel
@onready var result_label = $VBoxContainer/ResultLabel
@onready var cpu_hand_container = $VBoxContainer/CPUHandContainer
@onready var player_hand_container = $VBoxContainer/PlayerHandContainer
@onready var restart_button = $VBoxContainer/RestartButton

enum Hand { ROCK, SCISSORS, PAPER }
const HAND_NAMES = {Hand.ROCK: "グー", Hand.SCISSORS: "チョキ", Hand.PAPER: "パー"}

var card_textures = {
	Hand.ROCK: preload("res://assets/rock.png"),
	Hand.SCISSORS: preload("res://assets/scissors.png"),
	Hand.PAPER: preload("res://assets/paper.png")
}
var card_back_texture = preload("res://assets/card_back.png")

var player_hand = []
var cpu_hand = []
var player_wins = 0
var cpu_wins = 0
var turn_count = 0
const MAX_TURNS = 3

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	Dialogic.start("start")
	start_game()

func start_game():
	player_hand = _generate_hand()
	cpu_hand = _generate_hand()
	player_wins = 0
	cpu_wins = 0
	turn_count = 1

	restart_button.visible = false
	result_label.text = "カードを選んでください"
	_update_ui()

func _generate_hand():
	var hand = []
	for i in range(MAX_TURNS):
		hand.append(Hand.values().pick_random())
	return hand

func _update_ui():
	# Update Info Label
	info_label.text = "ターン: %d / %d\nスコア - あなた: %d  CPU: %d" % [min(turn_count, MAX_TURNS), MAX_TURNS, player_wins, cpu_wins]

	# Update CPU Hand (Show back of cards)
	for child in cpu_hand_container.get_children():
		child.queue_free()

	for i in range(cpu_hand.size()):
		var card = Button.new()
		card.icon = card_back_texture
		card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.expand_icon = true
		card.custom_minimum_size = Vector2(100, 140)
		card.disabled = true
		cpu_hand_container.add_child(card)

	# Update Player Hand
	for child in player_hand_container.get_children():
		child.queue_free()

	for i in range(player_hand.size()):
		var card = Button.new()
		card.icon = card_textures[player_hand[i]]
		card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.expand_icon = true
		card.custom_minimum_size = Vector2(100, 140)
		card.pressed.connect(_on_card_selected.bind(i))
		player_hand_container.add_child(card)

func _on_card_selected(index):
	if turn_count > MAX_TURNS:
		return

	var player_card = player_hand.pop_at(index)
	# CPU picks a random card from their hand
	var cpu_card_index = randi() % cpu_hand.size()
	var cpu_card = cpu_hand.pop_at(cpu_card_index)

	var result_msg = _evaluate_turn(player_card, cpu_card)

	turn_count += 1
	_update_ui()

	if turn_count > MAX_TURNS:
		_end_game()
	else:
		result_label.text = "あなた: %s  CPU: %s\n%s" % [HAND_NAMES[player_card], HAND_NAMES[cpu_card], result_msg]

func _evaluate_turn(p, c):
	if p == c:
		return "あいこ"
	elif (p == Hand.ROCK and c == Hand.SCISSORS) or \
		 (p == Hand.SCISSORS and c == Hand.PAPER) or \
		 (p == Hand.PAPER and c == Hand.ROCK):
		player_wins += 1
		return "勝ち！"
	else:
		cpu_wins += 1
		return "負け..."

func _end_game():
	var final_result = ""
	if player_wins > cpu_wins:
		final_result = "最終結果: あなたの勝利！"
	elif player_wins < cpu_wins:
		final_result = "最終結果: あなたの敗北..."
	else:
		final_result = "最終結果: 引き分け"

	result_label.text = final_result
	restart_button.visible = true

func _on_restart_pressed():
	start_game()
