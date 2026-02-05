extends Node
class_name ArmSwingController
## 腕振りアニメーションを制御するコントローラー
## PrologueChapter.gd等のストーリースクリプトから呼び出して使用

signal swing_completed
signal loop_completed(loop_index: int)

enum SwingMode {
	ALTERNATE,    # 左右交互に振る
	SYNC,         # 左右同時に振る（同位相）
	MIRROR,       # 左右同時に振る（逆位相）
	LEFT_ONLY,    # 左腕のみ
	RIGHT_ONLY,   # 右腕のみ
}

enum EasingType {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
	BOUNCE,
	ELASTIC,
}

# 対象ボーン
var _bone_arm_l: Bone2D = null
var _bone_arm_r: Bone2D = null
var _skeleton: Skeleton2D = null

# アニメーション状態
var _is_playing := false
var _current_tween_l: Tween = null
var _current_tween_r: Tween = null
var _current_loop_index := 0
var _target_repeat_count := 0

# デフォルトの回転角度（ラジアン）を保存
var _default_rotation_l := 0.0
var _default_rotation_r := 0.0

## ボーンを設定（CharacterRigから呼び出し）
func setup(skeleton: Skeleton2D, bone_arm_l: Bone2D, bone_arm_r: Bone2D) -> void:
	_skeleton = skeleton
	_bone_arm_l = bone_arm_l
	_bone_arm_r = bone_arm_r

	if _bone_arm_l:
		_default_rotation_l = _bone_arm_l.rotation
	if _bone_arm_r:
		_default_rotation_r = _bone_arm_r.rotation

## ボーンを名前で検索して設定
func setup_from_skeleton(skeleton: Skeleton2D) -> void:
	_skeleton = skeleton
	if skeleton == null:
		return

	# BoneSpine/BoneArmL, BoneSpine/BoneArmR を探す
	var bone_spine = skeleton.get_node_or_null("BoneSpine")
	if bone_spine:
		_bone_arm_l = bone_spine.get_node_or_null("BoneArmL")
		_bone_arm_r = bone_spine.get_node_or_null("BoneArmR")

	if _bone_arm_l:
		_default_rotation_l = _bone_arm_l.rotation
	if _bone_arm_r:
		_default_rotation_r = _bone_arm_r.rotation

## 腕振りアニメーションを開始
## @param params: Dictionary with the following keys:
##   - angle_min: float (degrees, default: -10)
##   - angle_max: float (degrees, default: 10)
##   - duration: float (seconds for one swing cycle, default: 1.0)
##   - loop: bool (default: true)
##   - repeat_count: int (0 = infinite when loop=true, default: 0)
##   - mode: String or SwingMode (default: "alternate")
##   - phase_offset: float (degrees, for MIRROR/ALTERNATE modes, default: 180)
##   - easing: String or EasingType (default: "ease_in_out")
func start_arm_swing(params: Dictionary = {}) -> void:
	stop_arm_swing()

	var angle_min: float = deg_to_rad(params.get("angle_min", -10.0))
	var angle_max: float = deg_to_rad(params.get("angle_max", 10.0))
	var duration: float = max(params.get("duration", 1.0), 0.1)
	var do_loop: bool = params.get("loop", true)
	var repeat_count: int = max(params.get("repeat_count", 0), 0)
	var mode = _parse_swing_mode(params.get("mode", "alternate"))
	var phase_offset: float = deg_to_rad(params.get("phase_offset", 180.0))
	var easing = _parse_easing(params.get("easing", "ease_in_out"))

	_is_playing = true
	_current_loop_index = 0
	_target_repeat_count = repeat_count if do_loop else 1

	var half_duration := duration / 2.0

	match mode:
		SwingMode.ALTERNATE:
			_start_alternate_swing(angle_min, angle_max, half_duration, easing, phase_offset)
		SwingMode.SYNC:
			_start_sync_swing(angle_min, angle_max, half_duration, easing, false)
		SwingMode.MIRROR:
			_start_sync_swing(angle_min, angle_max, half_duration, easing, true)
		SwingMode.LEFT_ONLY:
			_start_single_arm_swing(_bone_arm_l, _default_rotation_l, angle_min, angle_max, half_duration, easing)
		SwingMode.RIGHT_ONLY:
			_start_single_arm_swing(_bone_arm_r, _default_rotation_r, angle_min, angle_max, half_duration, easing)

## 腕振りアニメーションを停止
func stop_arm_swing() -> void:
	_is_playing = false

	if _current_tween_l and _current_tween_l.is_valid():
		_current_tween_l.kill()
	_current_tween_l = null

	if _current_tween_r and _current_tween_r.is_valid():
		_current_tween_r.kill()
	_current_tween_r = null

## 腕をデフォルト位置にリセット
func reset_arms() -> void:
	stop_arm_swing()

	if _bone_arm_l:
		_bone_arm_l.rotation = _default_rotation_l
	if _bone_arm_r:
		_bone_arm_r.rotation = _default_rotation_r

## 再生中かどうか
func is_playing() -> bool:
	return _is_playing

## 単一の腕のスイングを開始
func _start_single_arm_swing(bone: Bone2D, default_rot: float, angle_min: float, angle_max: float, half_duration: float, easing: EasingType) -> void:
	if bone == null:
		_is_playing = false
		swing_completed.emit()
		return

	var tween := _create_swing_tween(bone, default_rot, angle_min, angle_max, half_duration, easing)
	if bone == _bone_arm_l:
		_current_tween_l = tween
	else:
		_current_tween_r = tween

## 交互スイングを開始（左右が交互に動く）
func _start_alternate_swing(angle_min: float, angle_max: float, half_duration: float, easing: EasingType, phase_offset: float) -> void:
	# 右腕: min → max → min
	if _bone_arm_r:
		_current_tween_r = _create_swing_tween(_bone_arm_r, _default_rotation_r, angle_min, angle_max, half_duration, easing)

	# 左腕: 位相をずらして開始（max → min → max）
	if _bone_arm_l:
		# phase_offset が180度なら、逆位相でスタート
		if abs(phase_offset - deg_to_rad(180)) < 0.01:
			_current_tween_l = _create_swing_tween(_bone_arm_l, _default_rotation_l, angle_max, angle_min, half_duration, easing, true)
		else:
			_current_tween_l = _create_swing_tween(_bone_arm_l, _default_rotation_l, angle_min, angle_max, half_duration, easing)

## 同期スイングを開始（両腕が同時に動く）
func _start_sync_swing(angle_min: float, angle_max: float, half_duration: float, easing: EasingType, mirror: bool) -> void:
	if _bone_arm_r:
		_current_tween_r = _create_swing_tween(_bone_arm_r, _default_rotation_r, angle_min, angle_max, half_duration, easing)

	if _bone_arm_l:
		if mirror:
			# ミラー: 逆方向に動く
			_current_tween_l = _create_swing_tween(_bone_arm_l, _default_rotation_l, -angle_min, -angle_max, half_duration, easing)
		else:
			# 同期: 同方向に動く
			_current_tween_l = _create_swing_tween(_bone_arm_l, _default_rotation_l, angle_min, angle_max, half_duration, easing)

## スイング用のTweenを作成
func _create_swing_tween(bone: Bone2D, default_rot: float, angle_start: float, angle_end: float, half_duration: float, easing: EasingType, is_secondary: bool = false) -> Tween:
	var tween := create_tween()
	var trans := _get_tween_transition(easing)
	var ease_type := _get_tween_ease(easing)

	# 初期位置へ
	bone.rotation = default_rot + angle_start

	# angle_start → angle_end
	tween.tween_property(bone, "rotation", default_rot + angle_end, half_duration).set_trans(trans).set_ease(ease_type)
	# angle_end → angle_start
	tween.tween_property(bone, "rotation", default_rot + angle_start, half_duration).set_trans(trans).set_ease(ease_type)

	tween.finished.connect(_on_swing_cycle_completed.bind(is_secondary))

	return tween

## スイングサイクル完了時のコールバック
func _on_swing_cycle_completed(is_secondary: bool) -> void:
	if not _is_playing:
		return

	# セカンダリ（左腕）の完了は無視（右腕のみでカウント）
	if is_secondary:
		return

	_current_loop_index += 1
	loop_completed.emit(_current_loop_index)

	# 繰り返し回数チェック
	if _target_repeat_count > 0 and _current_loop_index >= _target_repeat_count:
		_is_playing = false
		swing_completed.emit()
		return

	# 継続する場合は再度スイング開始
	if _is_playing:
		_restart_current_swing()

## 現在のスイングを再開
func _restart_current_swing() -> void:
	# 現在のTweenの設定を再利用して再開
	if _current_tween_r and _bone_arm_r:
		var tween := create_tween()
		var current_rot := _bone_arm_r.rotation
		var default_rot := _default_rotation_r
		var angle := current_rot - default_rot

		# 同じパターンを繰り返す
		tween.tween_property(_bone_arm_r, "rotation", default_rot - angle, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_bone_arm_r, "rotation", default_rot + angle, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.finished.connect(_on_swing_cycle_completed.bind(false))
		_current_tween_r = tween

	if _current_tween_l and _bone_arm_l:
		var tween := create_tween()
		var current_rot := _bone_arm_l.rotation
		var default_rot := _default_rotation_l
		var angle := current_rot - default_rot

		tween.tween_property(_bone_arm_l, "rotation", default_rot - angle, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_bone_arm_l, "rotation", default_rot + angle, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.finished.connect(_on_swing_cycle_completed.bind(true))
		_current_tween_l = tween

## SwingModeをパース
func _parse_swing_mode(value) -> SwingMode:
	if value is SwingMode:
		return value
	if value is String:
		match value.to_lower():
			"alternate":
				return SwingMode.ALTERNATE
			"sync":
				return SwingMode.SYNC
			"mirror":
				return SwingMode.MIRROR
			"left", "left_only":
				return SwingMode.LEFT_ONLY
			"right", "right_only":
				return SwingMode.RIGHT_ONLY
	return SwingMode.ALTERNATE

## EasingTypeをパース
func _parse_easing(value) -> EasingType:
	if value is EasingType:
		return value
	if value is String:
		match value.to_lower():
			"linear":
				return EasingType.LINEAR
			"ease_in", "easein":
				return EasingType.EASE_IN
			"ease_out", "easeout":
				return EasingType.EASE_OUT
			"ease_in_out", "easeinout":
				return EasingType.EASE_IN_OUT
			"bounce":
				return EasingType.BOUNCE
			"elastic":
				return EasingType.ELASTIC
	return EasingType.EASE_IN_OUT

## TweenのTransitionタイプを取得
func _get_tween_transition(easing: EasingType) -> Tween.TransitionType:
	match easing:
		EasingType.LINEAR:
			return Tween.TRANS_LINEAR
		EasingType.EASE_IN, EasingType.EASE_OUT, EasingType.EASE_IN_OUT:
			return Tween.TRANS_SINE
		EasingType.BOUNCE:
			return Tween.TRANS_BOUNCE
		EasingType.ELASTIC:
			return Tween.TRANS_ELASTIC
	return Tween.TRANS_SINE

## TweenのEaseタイプを取得
func _get_tween_ease(easing: EasingType) -> Tween.EaseType:
	match easing:
		EasingType.LINEAR:
			return Tween.EASE_IN_OUT
		EasingType.EASE_IN:
			return Tween.EASE_IN
		EasingType.EASE_OUT:
			return Tween.EASE_OUT
		EasingType.EASE_IN_OUT:
			return Tween.EASE_IN_OUT
		EasingType.BOUNCE:
			return Tween.EASE_OUT
		EasingType.ELASTIC:
			return Tween.EASE_OUT
	return Tween.EASE_IN_OUT
