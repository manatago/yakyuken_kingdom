extends TestSuite

const SatoshiLoseNarrations := preload("res://battle/SatoshiLoseNarrations.gd")

func get_name() -> String:
	return "SatoshiLoseNarrations"

func get_tests() -> Array:
	return [
		{"name": "all_ids_match_pattern_keys", "callable": Callable(self, "_test_all_ids_match")},
		{"name": "every_pattern_has_required_fields", "callable": Callable(self, "_test_required_fields")},
		{"name": "outcome_is_recover_or_lose", "callable": Callable(self, "_test_outcome_values")},
		{"name": "categories_split_correctly", "callable": Callable(self, "_test_categories")},
		{"name": "render_substitutes_opponent_placeholder", "callable": Callable(self, "_test_render")},
		{"name": "pick_random_excludes_specified_id", "callable": Callable(self, "_test_pick_excludes")},
		{"name": "pick_random_returns_id", "callable": Callable(self, "_test_pick_returns_id")},
	]

func _test_all_ids_match() -> bool:
	# ALL_IDS と PATTERNS のキー集合が一致することを確認
	var pattern_keys = SatoshiLoseNarrations.PATTERNS.keys()
	var all_ids = SatoshiLoseNarrations.ALL_IDS
	if pattern_keys.size() != all_ids.size():
		push_error("ALL_IDS と PATTERNS のサイズが違う: %d vs %d" % [all_ids.size(), pattern_keys.size()])
		return false
	for id in all_ids:
		if not SatoshiLoseNarrations.PATTERNS.has(id):
			push_error("ALL_IDS の '%s' が PATTERNS にない" % id)
			return false
	for id in pattern_keys:
		if not all_ids.has(id):
			push_error("PATTERNS の '%s' が ALL_IDS にない" % id)
			return false
	return true

func _test_required_fields() -> bool:
	# 各 PATTERN が category / outcome / frames を持つことを確認
	for id in SatoshiLoseNarrations.PATTERNS:
		var p: Dictionary = SatoshiLoseNarrations.PATTERNS[id]
		if not p.has("category"):
			push_error("PATTERNS[%s] に category がない" % id)
			return false
		if not p.has("outcome"):
			push_error("PATTERNS[%s] に outcome がない" % id)
			return false
		if not p.has("frames"):
			push_error("PATTERNS[%s] に frames がない" % id)
			return false
		var frames: Array = p["frames"]
		if frames.is_empty():
			push_error("PATTERNS[%s] の frames が空" % id)
			return false
		for f in frames:
			if not (f is Array) or f.size() < 2:
				push_error("PATTERNS[%s] の frame の形式が違う: %s" % [id, str(f)])
				return false
	return true

func _test_outcome_values() -> bool:
	# outcome は "recover_clothes" か "lose_clothes" のみ。
	# A/B/C は recover_clothes、D は lose_clothes。
	for id in SatoshiLoseNarrations.PATTERNS:
		var p: Dictionary = SatoshiLoseNarrations.PATTERNS[id]
		var outcome: String = p["outcome"]
		var category: String = p["category"]
		if outcome != "recover_clothes" and outcome != "lose_clothes":
			push_error("PATTERNS[%s] の outcome が不正: %s" % [id, outcome])
			return false
		if category in ["A", "B", "C"] and outcome != "recover_clothes":
			push_error("PATTERNS[%s] (cat=%s) の outcome は recover_clothes であるべき: %s" % [id, category, outcome])
			return false
		if category == "D" and outcome != "lose_clothes":
			push_error("PATTERNS[%s] (cat=D) の outcome は lose_clothes であるべき: %s" % [id, outcome])
			return false
	return true

func _test_categories() -> bool:
	# A/B/C/D 各 3 件ずつあることを確認
	var counts: Dictionary = {"A": 0, "B": 0, "C": 0, "D": 0}
	for id in SatoshiLoseNarrations.PATTERNS:
		var p: Dictionary = SatoshiLoseNarrations.PATTERNS[id]
		var cat: String = p["category"]
		if not counts.has(cat):
			push_error("PATTERNS[%s] のカテゴリが不正: %s" % [id, cat])
			return false
		counts[cat] = counts[cat] + 1
	for c in ["A", "B", "C", "D"]:
		if counts[c] != 3:
			push_error("カテゴリ %s が 3 件でない: %d 件" % [c, counts[c]])
			return false
	return true

func _test_render() -> bool:
	# render_frames が {opponent} を opponent_name で置換することを確認
	var pattern: Dictionary = SatoshiLoseNarrations.PATTERNS["A-1"]
	var rendered: Array = SatoshiLoseNarrations.render_frames(pattern, "テスト相手")
	var found_substitution: bool = false
	for f in rendered:
		var text: String = String(f[1])
		if text.contains("テスト相手"):
			found_substitution = true
		if text.contains("{opponent}"):
			push_error("render 後も {opponent} が残っている: %s" % text)
			return false
	if not found_substitution:
		push_error("A-1 の render 後に opponent_name が含まれていない")
		return false
	return true

func _test_pick_excludes() -> bool:
	# exclude_id を指定すると、そのパターン以外から選ばれることを確認
	var allowed: Array = ["A-1", "A-2", "A-3"]
	for i in range(20):
		var picked: Dictionary = SatoshiLoseNarrations.pick_random(allowed, "A-1")
		if picked["id"] == "A-1":
			push_error("exclude_id=A-1 を指定したのに A-1 が選ばれた (試行 %d)" % i)
			return false
	return true

func _test_pick_returns_id() -> bool:
	# pick_random の戻り値に id フィールドが含まれることを確認
	var picked: Dictionary = SatoshiLoseNarrations.pick_random(SatoshiLoseNarrations.ALL_IDS)
	if not picked.has("id"):
		push_error("pick_random の戻り値に id がない")
		return false
	if not SatoshiLoseNarrations.ALL_IDS.has(picked["id"]):
		push_error("pick_random の id が ALL_IDS に存在しない: %s" % picked["id"])
		return false
	return true
