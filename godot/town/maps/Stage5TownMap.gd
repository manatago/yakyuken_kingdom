extends TownMapBase
class_name Stage5TownMap

var _db := EncounterDatabase.new()

func get_home_background() -> String:
	return ""  # TODO

func get_home_connections() -> Array:
	return []  # TODO

func get_all_encounter_chars() -> Dictionary:
	return _db.get_all_chars()

# エリアごとの出現キャラ（weight=出現重み、grade_min/grade_max=カードグレード上限）
# グーチョキパーとグレードはどちらもランダム生成される（_build_encounter参照）
var _area_encounters := {
	# TODO: エリアと出現キャラを設定する
	# 例:
	# "area_id": [
	#   {"char": "thug_a", "weight": 2, "grade_min": 2, "grade_max": 3},
	# ],
}

func get_encounters(area_id: String) -> Array:
	var entries: Array = _area_encounters.get(area_id, [])
	var result: Array = []
	for entry in entries:
		var char_data: Dictionary = _db.get_char(entry.char)
		if char_data.is_empty():
			continue
		result.append(_build_encounter(char_data, entry))
	return result

func get_areas() -> Dictionary:
	return {
		# TODO: エリア定義
		# "area_id": {
		#   "name": "エリア名",
		#   "bg": "res://assets/backgrounds/stageN/bg_xxx.png",
		#   "description": "説明文",
		#   "connections": ["other_area"],
		#   "battle_rate": 0.6,
		#   "enemy_strength": 2,
		# },
	}
