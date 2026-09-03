extends SceneTree

const ItemDatabaseScript := preload("res://game/ItemDatabase.gd")
const BattleSystemTestChapterScript := preload("res://battle/chapters/BattleSystemTestChapter.gd")
const RandomBattleChapterScript := preload("res://battle/chapters/RandomBattleChapter.gd")
const CardScript := preload("res://game/Card.gd")
const NineCardChapterScripts := [
	preload("res://battle/chapters/Stage2BattleChapter.gd"),
	preload("res://battle/chapters/Stage3BattleChapter.gd"),
	preload("res://battle/chapters/Stage4BattleChapter.gd"),
	preload("res://battle/chapters/Stage5BattleChapter.gd"),
	preload("res://battle/chapters/Stage6BattleChapter.gd"),
	preload("res://battle/chapters/FionaBattleChapter.gd"),
	preload("res://battle/chapters/SisterBattleChapter.gd"),
]

var failures := 0

func _check(condition: bool, message: String) -> void:
	if condition:
		printerr("[BATTLE_SYSTEM] PASS: %s" % message)
	else:
		printerr("[BATTLE_SYSTEM] FAIL: %s" % message)
		failures += 1

func _initialize() -> void:
	var expected_probability_items := {
		"rock_attract_white": {"hand": "rock", "delta": 0.05},
		"rock_attract_crimson": {"hand": "rock", "delta": 0.10},
		"rock_attract_gold": {"hand": "rock", "delta": 0.15},
		"scissors_attract_white": {"hand": "scissors", "delta": 0.05},
		"scissors_attract_crimson": {"hand": "scissors", "delta": 0.10},
		"scissors_attract_gold": {"hand": "scissors", "delta": 0.15},
		"paper_attract_white": {"hand": "paper", "delta": 0.05},
		"paper_attract_crimson": {"hand": "paper", "delta": 0.10},
		"paper_attract_gold": {"hand": "paper", "delta": 0.15},
		"rock_break_white": {"hand": "rock", "delta": -0.05},
		"rock_break_crimson": {"hand": "rock", "delta": -0.10},
		"rock_break_gold": {"hand": "rock", "delta": -0.15},
		"scissors_dull_white": {"hand": "scissors", "delta": -0.05},
		"scissors_dull_crimson": {"hand": "scissors", "delta": -0.10},
		"scissors_dull_gold": {"hand": "scissors", "delta": -0.15},
		"paper_seal_white": {"hand": "paper", "delta": -0.05},
		"paper_seal_crimson": {"hand": "paper", "delta": -0.10},
		"paper_seal_gold": {"hand": "paper", "delta": -0.15},
	}
	for item_id in expected_probability_items:
		var expected: Dictionary = expected_probability_items[item_id]
		var item: Dictionary = ItemDatabaseScript.get_item(item_id)
		_check(not item.is_empty(), "%s is registered" % item_id)
		_check(item.get("effect", "") == "adjust_probability", "%s uses probability adjustment" % item_id)
		_check(item.get("target_hand", "") == expected.hand, "%s targets the expected hand" % item_id)
		_check(is_equal_approx(float(item.get("probability_delta", 0.0)), expected.delta), "%s has the expected delta" % item_id)
		_check(ResourceLoader.exists(item.get("icon_path", "")), "%s icon exists" % item_id)

	var expected_icon_items := [
		"substitute_card", "iron_shield", "rank_up_talisman", "smoke_bomb",
		"greed_ring", "gold_charm", "rare_find_pendant", "crystal_fragment",
	]
	for item_id in expected_icon_items:
		var item: Dictionary = ItemDatabaseScript.get_item(item_id)
		_check(not item.is_empty(), "%s is registered" % item_id)
		_check(ResourceLoader.exists(item.get("icon_path", "")), "%s icon exists" % item_id)
	_check(not ItemDatabaseScript.is_battle_usable(ItemDatabaseScript.get_item("rank_up_talisman")), "rank-up talisman remains disabled during battle")
	_check(not ItemDatabaseScript.is_battle_usable(ItemDatabaseScript.get_item("smoke_bomb")), "smoke bomb remains disabled during battle")

	var adjusted := ItemDatabaseScript.apply_probability_adjustment(
		{"rock": 0.4, "scissors": 0.3, "paper": 0.3}, "rock", 0.15
	)
	_check(is_equal_approx(float(adjusted.rock), 0.55), "probability item raises the target hand")
	_check(is_equal_approx(float(adjusted.scissors), 0.225), "probability item preserves the other-hand ratio")
	_check(is_equal_approx(float(adjusted.paper), 0.225), "probability item keeps total probability at one")
	var intimidation_adjusted := ItemDatabaseScript.apply_probability_adjustment(
		{"rock": 0.9, "scissors": 0.05, "paper": 0.05}, "rock", 0.20
	)
	_check(is_equal_approx(float(intimidation_adjusted.rock), 1.0), "intimidation caps the target hand at one hundred percent")
	_check(
		is_equal_approx(float(intimidation_adjusted.rock + intimidation_adjusted.scissors + intimidation_adjusted.paper), 1.0),
		"intimidation keeps the total probability at one hundred percent"
	)
	var charm: Dictionary = ItemDatabaseScript.get_item("gold_charm")
	_check(int(charm.get("gold_bonus_amount", 0)) == 20, "gold charm has a configured bonus")
	_check(ItemDatabaseScript.get_capture_count([]) == 1, "normal wins capture one card")
	_check(ItemDatabaseScript.get_capture_count([{"id": "greed_ring"}]) == 2, "greed ring captures two cards on a win")
	_check(ItemDatabaseScript.get_gold_bonus([]) == 0, "no equipment gives no gold bonus")
	_check(ItemDatabaseScript.get_gold_bonus([{"id": "gold_charm"}]) == 20, "gold charm adds twenty gold on victory")
	_check(
		ItemDatabaseScript.format_gold_reward_summary(100, 20) == "100G + 20G（金運のお守り）",
		"gold charm reward summary shows the base amount and bonus"
	)
	_check(
		CardScript.format_same_hand_grade_reason("paper", 4, 1) == "同じパー: 自分のゴールド > 相手のノーマル",
		"same-hand grade result explains the player's higher grade"
	)
	_check(
		CardScript.format_same_hand_grade_reason("paper", 2, 2) == "同じパー・同じブロンズ: 引き分け",
		"same-hand equal grades explain the draw"
	)

	var chapter = BattleSystemTestChapterScript.new()
	_check(chapter.get_player_deck_size() == 9 and chapter.get_opponent_deck_size() == 9, "normal test chapter has stable nine-card decks")
	_check(chapter.get_player_outfit_count() == 3 and chapter.get_opponent_outfit_count() == 3, "normal test chapter has three rounds of durability")
	_check(ResourceLoader.exists(BattleSystemTestChapterScript.TEST_OPPONENT_PORTRAIT), "normal test chapter opponent portrait exists")
	for chapter_script in NineCardChapterScripts:
		var nine_card_chapter = chapter_script.new()
		_check(nine_card_chapter.get_opponent_hand().size() == 9, "%s has nine opponent cards" % nine_card_chapter.get_opponent_name())
		_check(nine_card_chapter.get_player_deck_size() == 9 and nine_card_chapter.get_opponent_deck_size() == 9, "%s uses nine-card decks" % nine_card_chapter.get_opponent_name())
	var random_chapter = RandomBattleChapterScript.new()
	random_chapter.setup_from_encounter({
		"id": "test", "name": "検証用対戦相手", "randomize_opponent_grades": true,
		"hand": [{"hand": "rock", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "paper", "grade": 1}],
	})
	for card in random_chapter.get_opponent_hand():
		_check(int(card.get("grade", 0)) >= 1 and int(card.get("grade", 0)) <= 5, "random battle opponent grade stays within the supported range")

	quit(1 if failures > 0 else 0)
