extends Node2D
class_name CharacterRig
## キャラクターリグの制御スクリプト
## char01_rig.tscn にアタッチして使用

const ArmSwingControllerScript := preload("res://scripts/ArmSwingController.gd")

## デフォルトのボーンウェイト（配列リテラル）
const DEFAULT_ARM_R_WEIGHTS: Array[float] = [
	0.2, 0.2, 0.5, 0.5, 0.5, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 0.5, 0.2, 0.2
]
const DEFAULT_ARM_L_WEIGHTS: Array[float] = [
	0.5, 0.5, 0.8, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 0.8, 0.5
]

@export_group("Bone Weights")
@export var arm_r_weights: Array[float] = DEFAULT_ARM_R_WEIGHTS:
	set(value):
		arm_r_weights = value
		if is_inside_tree():
			set_arm_r_weights(PackedFloat32Array(value))

@export var arm_l_weights: Array[float] = DEFAULT_ARM_L_WEIGHTS:
	set(value):
		arm_l_weights = value
		if is_inside_tree():
			set_arm_l_weights(PackedFloat32Array(value))

@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var polygon_arm_r: Polygon2D = $Skeleton2D/PolygonArmR
@onready var polygon_arm_l: Polygon2D = $Skeleton2D/PolygonArmL

var _arm_swing_controller: ArmSwingController = null

func _ready() -> void:
	_setup_arm_swing_controller()
	_apply_default_bone_weights()

func _setup_arm_swing_controller() -> void:
	_arm_swing_controller = ArmSwingControllerScript.new()
	add_child(_arm_swing_controller)

	if skeleton:
		_arm_swing_controller.setup_from_skeleton(skeleton)

## 腕振りアニメーションを開始
## @param params: Dictionary with the following keys:
##   - angle_min: float (degrees, default: -10)
##   - angle_max: float (degrees, default: 10)
##   - duration: float (seconds for one swing cycle, default: 1.0)
##   - loop: bool (default: true)
##   - repeat_count: int (0 = infinite when loop=true, default: 0)
##   - mode: String ("alternate", "sync", "mirror", "left_only", "right_only")
##   - phase_offset: float (degrees, default: 180)
##   - easing: String ("linear", "ease_in", "ease_out", "ease_in_out", "bounce", "elastic")
func start_arm_swing(params: Dictionary = {}) -> void:
	if _arm_swing_controller:
		_arm_swing_controller.start_arm_swing(params)

## 腕振りアニメーションを停止
func stop_arm_swing() -> void:
	if _arm_swing_controller:
		_arm_swing_controller.stop_arm_swing()

## 腕をデフォルト位置にリセット
func reset_arms() -> void:
	if _arm_swing_controller:
		_arm_swing_controller.reset_arms()

## 腕振りが再生中かどうか
func is_arm_swing_playing() -> bool:
	if _arm_swing_controller:
		return _arm_swing_controller.is_playing()
	return false

## 腕振り完了シグナルを取得
func get_arm_swing_completed_signal() -> Signal:
	if _arm_swing_controller:
		return _arm_swing_controller.swing_completed
	return Signal()

## ループ完了シグナルを取得
func get_arm_swing_loop_signal() -> Signal:
	if _arm_swing_controller:
		return _arm_swing_controller.loop_completed
	return Signal()

## ボーンを直接回転（角度はdegrees）
func rotate_arm_left(angle_degrees: float) -> void:
	if skeleton:
		var bone_spine = skeleton.get_node_or_null("BoneSpine")
		if bone_spine:
			var bone_arm_l = bone_spine.get_node_or_null("BoneArmL")
			if bone_arm_l:
				bone_arm_l.rotation = deg_to_rad(angle_degrees)

## ボーンを直接回転（角度はdegrees）
func rotate_arm_right(angle_degrees: float) -> void:
	if skeleton:
		var bone_spine = skeleton.get_node_or_null("BoneSpine")
		if bone_spine:
			var bone_arm_r = bone_spine.get_node_or_null("BoneArmR")
			if bone_arm_r:
				bone_arm_r.rotation = deg_to_rad(angle_degrees)

## 両腕を回転（角度はdegrees）
func rotate_arms(left_angle: float, right_angle: float) -> void:
	rotate_arm_left(left_angle)
	rotate_arm_right(right_angle)

## AnimationPlayerでアニメーションを再生
func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

## AnimationPlayerのアニメーションを停止
func stop_animation() -> void:
	if animation_player:
		animation_player.stop()

## ボーンウェイトを適用（export変数の値を使用）
func _apply_default_bone_weights() -> void:
	set_arm_r_weights(PackedFloat32Array(arm_r_weights))
	set_arm_l_weights(PackedFloat32Array(arm_l_weights))

## 右腕のボーンウェイトを設定
func set_arm_r_weights(weights: PackedFloat32Array) -> void:
	if polygon_arm_r:
		var bone_idx := _find_bone_index(polygon_arm_r, "BoneSpine/BoneArmR")
		if bone_idx >= 0:
			polygon_arm_r.set_bone_weights(bone_idx, weights)

## 左腕のボーンウェイトを設定
func set_arm_l_weights(weights: PackedFloat32Array) -> void:
	if polygon_arm_l:
		var bone_idx := _find_bone_index(polygon_arm_l, "BoneSpine/BoneArmL")
		if bone_idx >= 0:
			polygon_arm_l.set_bone_weights(bone_idx, weights)

## 右腕のボーンウェイトを取得
func get_arm_r_weights() -> PackedFloat32Array:
	if polygon_arm_r:
		var bone_idx := _find_bone_index(polygon_arm_r, "BoneSpine/BoneArmR")
		if bone_idx >= 0:
			return polygon_arm_r.get_bone_weights(bone_idx)
	return PackedFloat32Array()

## 左腕のボーンウェイトを取得
func get_arm_l_weights() -> PackedFloat32Array:
	if polygon_arm_l:
		var bone_idx := _find_bone_index(polygon_arm_l, "BoneSpine/BoneArmL")
		if bone_idx >= 0:
			return polygon_arm_l.get_bone_weights(bone_idx)
	return PackedFloat32Array()

## ボーンウェイトをデフォルトにリセット
func reset_bone_weights() -> void:
	_apply_default_bone_weights()

## ボーンインデックスを検索
func _find_bone_index(polygon: Polygon2D, bone_path: String) -> int:
	for i in polygon.get_bone_count():
		if str(polygon.get_bone_path(i)) == bone_path:
			return i
	return -1
