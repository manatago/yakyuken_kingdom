extends Node3D

@onready var sub_viewport = $SubViewport
@onready var screen = $Screen
@onready var camera = $Camera3D
@onready var info_label = $HUD/InfoLabel
@onready var result_label = $HUD/ResultLabel
@onready var restart_button = $HUD/RestartButton
@onready var opponent_image = $HUD/OpponentImage
@onready var dialogue_panel = $HUD/DialoguePanel
@onready var dialogue_label = $HUD/DialoguePanel/DialogueLabel
@onready var card_top_marker = $Screen/CardTopMarker

func _ready():
	# Get the viewport texture
	var viewport_texture = sub_viewport.get_texture()

	# Assign it to the material
	# We use surface_material_override/0 which corresponds to the first surface
	var material = screen.get_surface_override_material(0)
	if material:
		material.albedo_texture = viewport_texture

	# Ensure camera looks at the board
	camera.position = Vector3(0, 6, 8)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	# Connect signals from Main scene
	var main_scene = $SubViewport/Main
	if main_scene:
		main_scene.ui_updated.connect(_on_ui_updated)
		main_scene.result_updated.connect(_on_result_updated)
		main_scene.opponent_spoke.connect(_on_opponent_spoke)
		main_scene.game_over.connect(_on_game_over)

	# Initialize label state
	_on_result_updated("")
	dialogue_panel.visible = false
	restart_button.visible = false

	# Setup button styles
	_setup_button_styles()
	restart_button.pressed.connect(_on_restart_pressed)

func _setup_button_styles():
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.6, 1, 1)
	normal_style.set_corner_radius_all(10)
	normal_style.shadow_size = 4
	normal_style.shadow_offset = Vector2(2, 2)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.7, 1, 1)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.5, 0.9, 1)
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(1, 1)

	restart_button.add_theme_stylebox_override("normal", normal_style)
	restart_button.add_theme_stylebox_override("hover", hover_style)
	restart_button.add_theme_stylebox_override("pressed", pressed_style)

func _on_ui_updated(turn, max_turns, player_wins, cpu_wins, draws):
	info_label.text = "Turn: %d / %d\n%d勝 %d敗 %d分" % [turn, max_turns, player_wins, cpu_wins, draws]

func _on_result_updated(text):
	result_label.text = text

	# Adjust font size based on text length
	if text.length() > 10:
		# "カードを選んでください" -> Smaller font
		result_label.label_settings.font_size = 40
		result_label.label_settings.font_color = Color.WHITE
	else:
		# "WIN", "LOSE", "DRAW" -> Large font
		result_label.label_settings.font_size = 80

		# Set color based on result
		if "WIN" in text or "Win" in text:
			result_label.label_settings.font_color = Color(1, 0.84, 0) # Gold
		elif "LOSE" in text or "Lose" in text:
			result_label.label_settings.font_color = Color(0.2, 0.2, 1) # Blue
		elif "DRAW" in text or "Draw" in text:
			result_label.label_settings.font_color = Color(0.8, 0.8, 0.8) # Light Gray
		else:
			result_label.label_settings.font_color = Color.WHITE

	# Always center the label
	result_label.anchors_preset = Control.PRESET_CENTER
	result_label.anchor_top = 0.5
	result_label.anchor_bottom = 0.5
	result_label.offset_left = -200
	result_label.offset_right = 200
	result_label.offset_top = -60
	result_label.offset_bottom = 60

func _on_opponent_spoke(text):
	dialogue_panel.visible = true
	dialogue_label.text = text
	dialogue_label.visible_ratio = 0.0

	var tween = create_tween()
	var duration = text.length() * 0.1 # 0.1s per character
	tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)

	# Hide after some time (duration + 2 seconds)
	tween.tween_interval(2.0)
	tween.tween_callback(func(): dialogue_panel.visible = false)

func _on_game_over(result_text):
	restart_button.visible = true

func _on_restart_pressed():
	restart_button.visible = false
	var main_scene = $SubViewport/Main
	if main_scene:
		main_scene.start_game()

func _process(delta):
	if !camera or !card_top_marker or !opponent_image:
		return

	# Project the 3D marker position to 2D screen space
	var screen_pos = camera.unproject_position(card_top_marker.global_position)

	# Position the image so its bottom center is at the marker's screen position
	# We add a small gap (e.g., 10px) if needed, or just touch
	var gap = 0
	opponent_image.position.x = screen_pos.x - opponent_image.size.x / 2
	opponent_image.position.y = screen_pos.y - opponent_image.size.y - gap
