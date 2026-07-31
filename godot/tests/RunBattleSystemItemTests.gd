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

	var adjusted := ItemDatabaseScript.apply_probability_adjustment(
		{"rock": 0.4, "scissors": 0.3, "paper": 0.3}, "rock", 0.15
	)
	_check(is_equal_approx(float(adjusted.rock), 0.55), "probability item raises the target hand")
	_check(is_equal_approx(float(adjusted.scissors), 0.225), "probability item preserves the other-hand ratio")
	_check(is_equal_approx(float(adjusted.paper), 0.225), "probability item keeps total probability at one")
	var charm: Dictionary = ItemDatabaseScript.get_item("gold_charm")
	_check(int(charm.get("gold_bonus_amount", 0)) == 20, "gold charm has a configured bonus")
	_check(ItemDatabaseScript.get_capture_count([]) == 1, "normal wins capture one card")
	_check(ItemDatabaseScript.get_capture_count([{"id": "greed_ring"}]) == 2, "greed ring captures two cards on a win")
	_check(ItemDatabaseScript.get_gold_bonus([]) == 0, "no equipment gives no gold bonus")
	_check(ItemDatabaseScript.get_gold_bonus([{"id": "gold_charm"}]) == 20, "gold charm adds twenty gold on victory")

	var chapter = BattleSystemTestChapterScript.new()
	_check(chapter.get_player_deck_size() == 6 and chapter.get_opponent_deck_size() == 6, "normal test chapter has stable six-card decks")
	_check(chapter.get_player_outfit_count() == 3 and chapter.get_opponent_outfit_count() == 3, "normal test chapter has three rounds of durability")

	quit(1 if failures > 0 else 0)
