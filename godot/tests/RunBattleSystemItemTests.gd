extends SceneTree

const ItemDatabaseScript := preload("res://game/ItemDatabase.gd")
const BattleSystemTestChapterScript := preload("res://battle/chapters/BattleSystemTestChapter.gd")

var failures := 0

func _check(condition: bool, message: String) -> void:
	if condition:
		printerr("[BATTLE_SYSTEM] PASS: %s" % message)
	else:
		printerr("[BATTLE_SYSTEM] FAIL: %s" % message)
		failures += 1

func _initialize() -> void:
	var expected_deltas := {
		"rock_attract_white": 0.05,
		"rock_attract_crimson": 0.10,
		"rock_attract_gold": 0.15,
	}
	for item_id in expected_deltas:
		var item: Dictionary = ItemDatabaseScript.get_item(item_id)
		_check(not item.is_empty(), "%s is registered" % item_id)
		_check(item.get("effect", "") == "adjust_probability", "%s uses probability adjustment" % item_id)
		_check(is_equal_approx(float(item.get("probability_delta", 0.0)), expected_deltas[item_id]), "%s has the expected delta" % item_id)
		_check(ResourceLoader.exists(item.get("icon_path", "")), "%s icon exists" % item_id)

	var chapter = BattleSystemTestChapterScript.new()
	_check(chapter.get_player_deck_size() == 6 and chapter.get_opponent_deck_size() == 6, "normal test chapter has stable six-card decks")
	_check(chapter.get_player_outfit_count() == 3 and chapter.get_opponent_outfit_count() == 3, "normal test chapter has three rounds of durability")

	quit(1 if failures > 0 else 0)
