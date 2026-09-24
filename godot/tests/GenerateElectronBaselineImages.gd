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
	await _capture_title("save-load.png")
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
	var serialized := JSON.stringify(game_state.to_dict())
	var restored = JSON.parse_string(serialized)
	if not restored is Dictionary or restored.is_empty():
		_fail("in-memory save/load probe returned no data")

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
	battle.force_result_mode = true
	battle.start_battle(chapter, tutorial)
	await process_frame
	await process_frame
	_capture(file_name)
	battle.queue_free()
	await process_frame

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

func _capture(file_name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var output_path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name])
	if image.save_png(output_path) != OK:
		_fail("could not write %s" % output_path)

func _fail(message: String) -> void:
	printerr("[BASELINE] FAIL: %s" % message)
	failures += 1
