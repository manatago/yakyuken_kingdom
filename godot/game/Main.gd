extends Control

const DefaultStoryScript := preload("res://story/DefaultStory.gd")

signal result_updated(text)

@export var enable_story_playback := true

@onready var background_rect = $Background
@onready var title_menu = $TitleMenu
@onready var new_game_button = $TitleMenu/NewGameButton
@onready var continue_button = $TitleMenu/ContinueButton
@onready var jump_menu = $JumpMenu
@onready var jump_list = $JumpMenu/JumpList
@onready var back_button = $JumpMenu/BackButton
@onready var battle_result_screen = $BattleResultScreen
@onready var result_title = $BattleResultScreen/ResultMenu/ResultTitle
@onready var result_message = $BattleResultScreen/ResultMenu/ResultMessage
@onready var result_buttons = $BattleResultScreen/ResultMenu/ResultButtons

# 開発用ジャンプ先定義（本番では自動保存に置き換え）
var _jump_points: Array = [
	{"label": "scene_university", "name": "大学"},
	{"label": "scene_room", "name": "自室"},
	{"label": "scene_lab1", "name": "研究室1"},
	{"label": "scene_lab2", "name": "研究室2"},
	{"label": "scene_teleport1", "name": "転送広場1"},
	{"label": "scene_teleport2", "name": "転送広場2"},
	{"label": "scene_prison", "name": "牢獄"},
	{"label": "tutorial_start", "name": "チュートリアル"},
	{"label": "after_tutorial", "name": "チュートリアル後〜バトル前"},
	{"label": "battle_start", "name": "本番バトル"},
	{"label": "_result:win", "name": "バトル後（勝利）"},
	{"label": "_result:lose", "name": "バトル後（敗北）"},
	{"label": "scene_guild_street", "name": "--- Stage1 ---"},
	{"label": "scene_guild_street", "name": "ギルド通り", "sequence": "stage1"},
	{"label": "scene_analysis", "name": "道中・解析", "sequence": "stage1"},
	{"label": "scene_guild_hall", "name": "冒険者ギルド", "sequence": "stage1"},
	{"label": "stage1_tutorial_start", "name": "ベイズ・アイ チュートリアル", "sequence": "stage1"},
	{"label": "stage1_battle_start", "name": "冒険者Aバトル", "sequence": "stage1"},
	{"label": "scene_guild_reception", "name": "ギルド受付", "sequence": "stage1"},
]

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
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	back_button.pressed.connect(_on_jump_back)
	title_menu.visible = true
	jump_menu.visible = false

func _init_player_inventory():
	if player_inventory.is_empty():
		# Starting cards: 3 normal of each type = 9 cards
		for hand_key in ["rock", "scissors", "paper"]:
			for i in range(3):
				player_inventory.append({"hand": hand_key, "grade": 1})

func _on_new_game():
	title_menu.visible = false
	_create_story_scene()
	await scenario()

func _on_continue():
	title_menu.visible = false
	_show_jump_menu()

func _show_jump_menu():
	# Clear existing buttons
	for child in jump_list.get_children():
		child.queue_free()
	# Create buttons for each jump point
	for point in _jump_points:
		var btn := Button.new()
		btn.text = point.name
		btn.add_theme_font_size_override("font_size", 20)
		var seq_id: String = point.get("sequence", "prologue")
		btn.pressed.connect(_on_jump_selected.bind(point.label, seq_id))
		jump_list.add_child(btn)
	jump_menu.visible = true

func _on_jump_selected(label_name: String, sequence_id: String = "prologue"):
	jump_menu.visible = false
	player_inventory.clear()
	_init_player_inventory()
	if label_name.begins_with("_result:"):
		# Play win/lose dialogue then show result screen
		var result: String = label_name.substr(8)
		_create_story_scene()
		if result == "win":
			await _play_scene("prologue_battle_win")
		elif result == "lose":
			await _play_scene("prologue_battle_lose")
		story_scene_instance.visible = false
		var choice: String = await _show_battle_result_screen(result)
		story_scene_instance.visible = true
		if choice == "next":
			# 次の章から続行
			await scenario_from("stage1", "")
		elif choice == "retry":
			_last_battle_result = ""
			await _play_scene_from("prologue", "battle_start")
			var entry = _scenario_order[0]
			await _handle_battle_aftermath(entry, 0)
		story_scene_instance.queue_free()
		story_scene_instance = null
		title_menu.visible = true
	else:
		_create_story_scene()
		await scenario_from(sequence_id, label_name)
		story_scene_instance.queue_free()
		story_scene_instance = null
		title_menu.visible = true

func _on_jump_back():
	jump_menu.visible = false
	title_menu.visible = true

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

# ストーリーの全シーケンス順序（各要素にバトル後シーケンスIDを含む）
var _scenario_order: Array = [
	{"id": "prologue", "battle_win": "prologue_battle_win", "battle_lose": "prologue_battle_lose"},
	{"id": "stage1", "battle_win": "stage1_battle_win", "battle_lose": "stage1_battle_lose"},
]

var _last_battle_result: String = ""

func scenario():
	await _run_scenario_from(0, "")

func scenario_from(sequence_id: String, label_name: String = ""):
	for i in range(_scenario_order.size()):
		if _scenario_order[i].id == sequence_id:
			await _run_scenario_from(i, label_name)
			return
	# sequence_idが見つからない場合、先頭から
	await _run_scenario_from(0, "")

func _run_scenario_from(start_index: int, label_name: String):
	for i in range(start_index, _scenario_order.size()):
		var entry: Dictionary = _scenario_order[i]
		var seq_id: String = entry.id
		if not label_name.is_empty():
			await _play_scene_from(seq_id, label_name)
			label_name = ""
		else:
			await _play_scene(seq_id)
		# バトル後の処理
		await _handle_battle_aftermath(entry, i)
	print("All Stages Cleared!")

func _handle_battle_aftermath(entry: Dictionary, scene_index: int):
	if _last_battle_result.is_empty():
		return
	var result: String = _last_battle_result
	_last_battle_result = ""
	# 勝ち/負け会話を同じstory_scene_instanceで再生
	var win_seq_id: String = entry.get("battle_win", "")
	var lose_seq_id: String = entry.get("battle_lose", "")
	if result == "win" and not win_seq_id.is_empty():
		await _play_scene(win_seq_id)
	elif result == "lose" and not lose_seq_id.is_empty():
		await _play_scene(lose_seq_id)
	# 結果画面
	story_scene_instance.visible = false
	var choice: String = await _show_battle_result_screen(result)
	story_scene_instance.visible = true
	if choice == "retry":
		# バトルラベルから再開（再帰）
		var battle_label: String = entry.id.replace("prologue", "battle_start").replace("stage1", "stage1_battle_start")
		# 汎用的にバトルラベルを探す
		_last_battle_result = ""
		await _play_scene_from(entry.id, "battle_start")
		await _handle_battle_aftermath(entry, scene_index)

# Play a scene with only dialogue
func _play_scene(sequence_key):
	var seq = story_script.get_sequence(sequence_key)
	if seq:
		await story_scene_instance.play_sequence(seq, {"id": sequence_key})

# Play a scene from a specific label
func _play_scene_from(sequence_key: String, label_name: String):
	var seq = story_script.get_sequence(sequence_key)
	if seq:
		await story_scene_instance.play_sequence(seq, {"id": sequence_key, "skip_to": label_name})

func _on_story_sequence_started(_sequence_id):
	is_dialogue_active = true

func _on_story_sequence_finished(_sequence_id):
	is_dialogue_active = false

# --- Battle bridge ---

func _on_battle_requested(cmd):
	if cmd.chapter == null:
		story_scene_instance.complete_battle("win")
		return

	# Tutorial battles don't show result screen
	if cmd.is_tutorial:
		story_scene_instance.visible = false
		var battle_instance = battle_scene_scene.instantiate()
		add_child(battle_instance)
		battle_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		battle_instance.setup(story_script.get_cast(), story_scene_instance.background_rect.texture, player_inventory)
		battle_instance.start_battle(cmd.chapter, true)
		await battle_instance.battle_finished
		battle_instance.queue_free()
		story_scene_instance.visible = true
		story_scene_instance.complete_battle("win")
		return

	# Normal battle: run battle and return result
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
		for card in rewards.captured_by_player:
			player_inventory.append(card.duplicate())
	elif result == "lose":
		for card in rewards.captured_by_opponent:
			_remove_card_from_inventory(card)

	battle_instance.queue_free()
	cmd.result = result
	_last_battle_result = result
	story_scene_instance.visible = true
	story_scene_instance.complete_battle(result)

# --- Battle Result Screen ---

signal _result_choice_made(choice: String)

func _show_battle_result_screen(result: String) -> String:
	# Clear previous buttons
	for child in result_buttons.get_children():
		child.queue_free()

	if result == "win":
		result_title.text = "勝利！"
		result_message.text = "見事な勝利です！次の章へ進みますか？"
		_add_result_button("次の章へ", "next")
		_add_result_button("タイトルに戻る", "title")
	elif result == "lose":
		result_title.text = "敗北..."
		result_message.text = "残念...再戦しますか？"
		_add_result_button("再戦する", "retry")
		_add_result_button("タイトルに戻る", "title")
	else:
		result_title.text = "引き分け"
		result_message.text = "決着がつきませんでした。"
		_add_result_button("再戦する", "retry")
		_add_result_button("タイトルに戻る", "title")

	battle_result_screen.visible = true
	var choice: String = await _result_choice_made
	battle_result_screen.visible = false
	return choice

func _add_result_button(text: String, choice: String):
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): _result_choice_made.emit(choice))
	result_buttons.add_child(btn)

func _remove_card_from_inventory(card: Dictionary):
	for i in range(player_inventory.size()):
		if player_inventory[i].hand == card.hand and int(player_inventory[i].grade) == int(card.grade):
			player_inventory.remove_at(i)
			return
