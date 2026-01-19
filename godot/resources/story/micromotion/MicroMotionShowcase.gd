extends Control
class_name MicroMotionShowcase

signal action_finished

const PROPERTY_OPEN := preload("res://assets/characters/samples/sample01-001.png")
const PROPERTY_BLINK := preload("res://assets/characters/samples/sample01-002.png")
const PROPERTY_TALK := preload("res://assets/characters/samples/sample01-003.png")

@onready var _title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var _description_label: Label = $Panel/Margin/VBox/DescriptionLabel
@onready var _backdrop: ColorRect = $Backdrop

@onready var _samples: Array[Node2D] = [
	$Samples/PropertySample,
	$Samples/BreathingSample,
	$Samples/DeformSample,
	$Samples/WindSample,
	$Samples/TweenSample,
]

@onready var _property_sample: Node2D = $Samples/PropertySample
@onready var _property_face: Sprite2D = $Samples/PropertySample/Face
@onready var _property_mouth: Sprite2D = $Samples/PropertySample/Mouth

@onready var _breathing_sample: Node2D = $Samples/BreathingSample
@onready var _breathing_body: Sprite2D = $Samples/BreathingSample/Body
@onready var _breathing_head: Sprite2D = $Samples/BreathingSample/Head

@onready var _deform_sample: Node2D = $Samples/DeformSample
@onready var _deform_head_bone: Bone2D = $Samples/DeformSample/Skeleton2D/TorsoBone/HeadBone
@onready var _deform_arm_bone: Bone2D = $Samples/DeformSample/Skeleton2D/TorsoBone/ArmBone
@onready var _deform_cape_bone: Bone2D = $Samples/DeformSample/Skeleton2D/TorsoBone/CapeBone

@onready var _wind_sample: Node2D = $Samples/WindSample
@onready var _wind_sprite: Sprite2D = $Samples/WindSample/WindSprite

@onready var _tween_sample: Node2D = $Samples/TweenSample
@onready var _tween_sprite: Sprite2D = $Samples/TweenSample/TweenSprite

var _sample_defaults: Dictionary = {}
var _head_default_rotation := 0.0
var _arm_default_rotation := 0.0
var _cape_default_rotation := 0.0
var _is_playing := false

func _ready() -> void:
	for node in _samples:
		_sample_defaults[node] = {
			"position": node.position,
			"scale": node.scale,
			"rotation": node.rotation,
		}
	_head_default_rotation = _deform_head_bone.rotation_degrees
	_arm_default_rotation = _deform_arm_bone.rotation_degrees
	_cape_default_rotation = _deform_cape_bone.rotation_degrees
	_property_mouth.visible = false
	visible = false
	_backdrop.visible = false

func play(mode: String, params: Dictionary = {}):
	if _is_playing:
		return null
	_is_playing = true
	visible = true
	_backdrop.visible = true
	modulate = Color(1, 1, 1, 1)
	_title_label.text = params.get("title", "Micro Motion Sample")
	_description_label.text = params.get("description", "")
	reset_samples()
	call_deferred("_run_showcase", mode, params)
	return action_finished

func _run_showcase(mode: String, params: Dictionary) -> void:
	await get_tree().process_frame
	match mode:
		"property_animation":
			await _play_property_animation()
		"breathing_transform":
			await _play_breathing_animation()
		"bone_deformation":
			await _play_deformation_animation()
		"wind_shader":
			await _play_wind_animation()
		"tween_transition":
			await _play_tween_animation()
		_:
			await _sleep(0.5)
	await _sleep(params.get("linger", 0.35))
	reset_samples()
	visible = false
	_backdrop.visible = false
	_is_playing = false
	action_finished.emit()

func reset_samples() -> void:
	for node in _samples:
		node.visible = false
		var defaults: Dictionary = _sample_defaults.get(node, {})
		node.position = defaults.get("position", node.position)
		node.scale = defaults.get("scale", node.scale)
		node.rotation = defaults.get("rotation", node.rotation)
	_property_face.texture = PROPERTY_OPEN
	_property_mouth.visible = false
	_property_mouth.modulate = Color(1, 1, 1, 1)
	_breathing_sample.position = _sample_defaults[_breathing_sample].position
	_breathing_sample.scale = Vector2.ONE
	_breathing_head.rotation_degrees = 0.0
	_deform_head_bone.rotation_degrees = _head_default_rotation
	_deform_arm_bone.rotation_degrees = _arm_default_rotation
	_deform_cape_bone.rotation_degrees = _cape_default_rotation
	if _wind_sprite.material:
		_wind_sprite.material.set_shader_parameter("amplitude", 6.0)
		_wind_sprite.material.set_shader_parameter("speed_multiplier", 1.0)
		_wind_sprite.material.set_shader_parameter("frequency", 2.5)
	_tween_sprite.modulate = Color(1, 1, 1, 1)

func _show_sample(sample_node: Node2D) -> void:
	for node in _samples:
		node.visible = node == sample_node

func _play_property_animation() -> void:
	_show_sample(_property_sample)
	_property_mouth.visible = true
	_property_mouth.modulate = Color(1, 1, 1, 0.0)
	for i in range(3):
		_property_face.texture = PROPERTY_OPEN
		await _sleep(0.25)
		_property_face.texture = PROPERTY_BLINK
		await _sleep(0.1)
		_property_face.texture = PROPERTY_OPEN
		_property_mouth.texture = PROPERTY_TALK
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_property_mouth, "modulate:a", 1.0, 0.15)
		tween.tween_property(_property_mouth, "modulate:a", 0.0, 0.15)
		await tween.finished
	_property_face.texture = PROPERTY_OPEN
	_property_mouth.visible = false

func _play_breathing_animation() -> void:
	_show_sample(_breathing_sample)
	_breathing_sample.scale = Vector2.ONE
	_breathing_sample.position = _sample_defaults[_breathing_sample].position
	_breathing_head.rotation_degrees = -2.0
	for i in range(2):
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_breathing_sample, "scale", Vector2(1.02, 1.02), 0.8)
		tween.parallel().tween_property(_breathing_sample, "position:y", _breathing_sample.position.y - 10.0, 0.8)
		tween.parallel().tween_property(_breathing_head, "rotation_degrees", 2.5, 0.8)
		tween.tween_property(_breathing_sample, "scale", Vector2.ONE, 0.8)
		tween.parallel().tween_property(_breathing_sample, "position:y", _sample_defaults[_breathing_sample].position.y, 0.8)
		tween.parallel().tween_property(_breathing_head, "rotation_degrees", -2.0, 0.8)
		await tween.finished
	_breathing_sample.scale = Vector2.ONE
	_breathing_sample.position = _sample_defaults[_breathing_sample].position
	_breathing_head.rotation_degrees = 0.0

func _play_deformation_animation() -> void:
	_show_sample(_deform_sample)
	_deform_head_bone.rotation_degrees = -4.0
	_deform_arm_bone.rotation_degrees = -12.0
	_deform_cape_bone.rotation_degrees = -2.0
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_deform_head_bone, "rotation_degrees", 12.0, 0.8)
	tween.parallel().tween_property(_deform_arm_bone, "rotation_degrees", -40.0, 0.8)
	tween.parallel().tween_property(_deform_cape_bone, "rotation_degrees", 18.0, 0.8)
	tween.tween_property(_deform_head_bone, "rotation_degrees", -6.0, 0.8)
	tween.parallel().tween_property(_deform_arm_bone, "rotation_degrees", 8.0, 0.8)
	tween.parallel().tween_property(_deform_cape_bone, "rotation_degrees", -10.0, 0.8)
	await tween.finished
	_deform_head_bone.rotation_degrees = _head_default_rotation
	_deform_arm_bone.rotation_degrees = _arm_default_rotation
	_deform_cape_bone.rotation_degrees = _cape_default_rotation

func _play_wind_animation() -> void:
	_show_sample(_wind_sample)
	if _wind_sprite.material == null:
		await _sleep(1.0)
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_wind_sprite.material, "shader_parameter/amplitude", 12.0, 0.8)
	tween.parallel().tween_property(_wind_sprite.material, "shader_parameter/speed_multiplier", 1.8, 0.8)
	tween.tween_property(_wind_sprite.material, "shader_parameter/amplitude", 5.0, 0.8)
	tween.parallel().tween_property(_wind_sprite.material, "shader_parameter/speed_multiplier", 0.8, 0.8)
	await tween.finished
	_wind_sprite.material.set_shader_parameter("amplitude", 6.0)
	_wind_sprite.material.set_shader_parameter("speed_multiplier", 1.0)

func _play_tween_animation() -> void:
	_show_sample(_tween_sample)
	_tween_sample.position = Vector2(-500, 0)
	_tween_sprite.modulate = Color(1, 1, 1, 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_tween_sample, "position", Vector2(0, -20), 0.75)
	tween.parallel().tween_property(_tween_sprite, "modulate:a", 1.0, 0.5)
	tween.tween_interval(0.25)
	tween.tween_property(_tween_sample, "position", Vector2(140, 10), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.2)
	tween.tween_property(_tween_sample, "position", Vector2(400, -40), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_tween_sprite, "modulate:a", 0.0, 0.45)
	await tween.finished
	_tween_sample.position = _sample_defaults[_tween_sample].position
	_tween_sprite.modulate = Color(1, 1, 1, 1)

func _sleep(duration: float) -> Signal:
	return get_tree().create_timer(duration).timeout
