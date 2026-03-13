extends Resource
class_name StoryCommands

class Base extends Resource:
	func execute(_scene):
		return null

class Line extends Base:
	var speaker_id: String = ""
	var text: String = ""
	var portrait_id: String = ""
	var side_override: String = ""
	var offset: Vector2 = Vector2.ZERO
	var wait_for_input: bool = true
	var min_duration: float = 0.0
	var duration: float = 0.5
	func execute(scene):
		return scene.play_line(self)

class Background extends Base:
	var path: String = ""
	var fade: float = 0.0
	func execute(scene):
		scene.show_background_entry(self)

class Pause extends Base:
	var duration: float = 0.0
	func execute(scene):
		return scene.pause_entry(self)

class ShowCharacter extends Base:
	var character_id: String = ""
	var portrait_id: String = ""
	var side_override: String = ""
	var position_mode: String = ""
	var position: Vector2 = Vector2.ZERO
	var appear_effect: String = ""
	var appear_from: String = ""
	var appear_duration: float = 0.0
	var appear_distance: float = 200.0
	var portrait_scale: float = 0.0
	var transition: String = ""
	var transition_duration: float = 0.3
	var flip: int = -1
	func execute(scene):
		scene.show_character_command(self)

class HideCharacter extends Base:
	var character_id: String = ""
	var side_override: String = ""
	var exit_effect: String = ""
	var exit_to: String = ""
	var exit_duration: float = 0.0
	var exit_distance: float = 200.0
	var wait_for_exit: bool = false
	var wait_after: float = 0.0
	func execute(scene):
		return scene.hide_character_entry(self)

class Band extends Base:
	var visible: bool = true
	var speaker_id: String = ""
	var text: String = ""
	var wait_for_input: bool = false
	var min_duration: float = 0.0
	var portrait_id: String = ""
	var side_override: String = ""
	var clear_text: bool = false
	func execute(scene):
		return scene.apply_band_command(self)

class BandColor extends Base:
	var color: Color = Color(0.50, 0.38, 0.18, 0.85)
	func execute(scene):
		scene.set_inner_band_color(color)
		return null

class HideDialogue extends Base:
	func execute(scene):
		return scene.hide_dialogue_command(self)

class AnimatePortrait extends Base:
	var character_id: String = ""
	var portrait_ids: Array[String] = []
	var frame_duration: float = 0.15
	var loop_count: int = 0
	func execute(scene):
		if scene and scene.has_method("start_portrait_animation"):
			scene.start_portrait_animation(self)
		return null

class StopPortraitAnimation extends Base:
	var character_id: String = ""
	func execute(scene):
		if scene and scene.has_method("stop_portrait_animation"):
			scene.stop_portrait_animation(self)
		return null

class MicroMotion extends Base:
	var mode: String = ""
	var params: Dictionary = {}
	func execute(scene):
		if scene == null or not scene.has_method("play_micro_motion"):
			return null
		return scene.play_micro_motion(self)

class Sequence extends RefCounted:
	var id: String = ""
	var entries: Array = []
	var _skipping := false
	func skip_to_next_background():
		_skipping = true
