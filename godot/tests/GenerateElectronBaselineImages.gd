extends SceneTree

const GameStateScript := preload("res://game/GameState.gd")
const BattleSystemTestChapterScript := preload("res://battle/chapters/BattleSystemTestChapter.gd")
const PrologueBattleChapterScript := preload("res://battle/chapters/PrologueBattleChapter.gd")
const RandomBattleChapterScript := preload("res://battle/chapters/RandomBattleChapter.gd")

const OUTPUT_DIR := "res://../docs/plans/baseline-images"

var failures := 0
var game_state

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_ensure_game_state()
	await _capture_title("title.png")
	await _capture_battle("matilda-tutorial.png", PrologueBattleChapterScript.new(), true)
	await _capture_battle("fixed-battle.png", BattleSystemTestChapterScript.new())
	await _capture_random_battle()
	_probe_save_load()
	quit(1 if failures > 0 else 0)

func _ensure_game_state() -> void:
	game_state = root.get_node_or_null("GameState")
	if game_state:
		return
	game_state = GameStateScript.new()
	game_state.name = "GameState"
	root.add_child(game_state)
	game_state.reset()
	game_state.init_default_inventory()

func _capture_title(file_name: String) -> void:
	var main = load("res://Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_capture(file_name)
	main.queue_free()
	await process_frame

func _capture_battle(file_name: String, chapter, tutorial := false) -> void:
	var battle = load("res://BattleScene.tscn").instantiate()
	root.add_child(battle)
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle.setup({}, null, game_state.inventory)
	battle.start_battle(chapter, tutorial)
	if tutorial:
		await _wait_frames(40)
		if not battle.hand_panel.visible:
			_fail("tutorial hand panel is missing")
	else:
		if not await _advance_to_deck_building(battle):
			_fail("deck building did not start for %s" % file_name)
			battle.queue_free()
			await process_frame
			return
		battle.auto_button.pressed.emit()
		battle.confirm_button.pressed.emit()
		await _wait_frames(40)
		if battle._deck_buttons.is_empty():
			_fail("battle cards were not created for %s" % file_name)
	await _wait_for_dialogue_text(battle)
	_capture(file_name)
	battle.queue_free()
	await process_frame

func _advance_to_deck_building(battle) -> bool:
	for attempt in range(20):
		if battle._deck_building:
			return true
		var press := InputEventAction.new()
		press.action = "ui_accept"
		press.pressed = true
		Input.parse_input_event(press)
		await process_frame
		var release := InputEventAction.new()
		release.action = "ui_accept"
		release.pressed = false
		Input.parse_input_event(release)
		await _wait_frames(20)
	return battle._deck_building

func _wait_frames(count: int) -> void:
	for frame in range(count):
		await process_frame

func _wait_for_dialogue_text(battle) -> void:
	for frame in range(180):
		if not battle._story_scene._typing_in_progress:
			return
		await process_frame
	_fail("dialogue did not finish typing")

func _capture_random_battle() -> void:
	var encounter_db = EncounterDatabase.new()
	var encounter: Dictionary = encounter_db.characters.get("merchant2", {}).duplicate(true)
	if encounter.is_empty():
		_fail("merchant2 encounter is missing")
		return
	encounter["battle_bg"] = ""
	var chapter = RandomBattleChapterScript.new()
	chapter.setup_from_encounter(encounter)
	await _capture_battle("random-battle.png", chapter)

func _probe_save_load() -> void:
	var probe_path := "user://electron_baseline_probe_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(probe_path):
		_fail("temporary save path already exists: %s" % probe_path)
		return
	game_state.chapter = "baseline_probe"
	game_state.label = "after_battle"
	game_state.money = 73
	var expected: Dictionary = game_state.to_dict()
	var payload := expected.duplicate(true)
	payload["save_version"] = 1
	var save_file := FileAccess.open(probe_path, FileAccess.WRITE)
	if save_file == null:
		_fail("could not create temporary save file")
		return
	save_file.store_string(JSON.stringify(payload))
	save_file.close()
	var load_file := FileAccess.open(probe_path, FileAccess.READ)
	if load_file == null:
		_fail("could not read temporary save file")
		return
	var restored = JSON.parse_string(load_file.get_as_text())
	load_file.close()
	if DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_path)) != OK:
		_fail("could not remove temporary save file")
	if not restored is Dictionary:
		_fail("temporary save file is not a JSON object")
		return
	game_state.reset()
	game_state.apply(restored)
	if game_state.to_dict() != expected:
		_fail("restored GameState does not match the saved state")
	else:
		print("[BASELINE] PASS: GameState restored from temporary save file")

func _capture(file_name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var output_path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name])
	if image.save_png(output_path) != OK:
		_fail("could not write %s" % output_path)

func _fail(message: String) -> void:
	printerr("[BASELINE] FAIL: %s" % message)
	failures += 1
