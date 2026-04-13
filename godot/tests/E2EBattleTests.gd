extends TestSuite
class_name E2EBattleTests

# E2Eテスト: バトルシステムの統合テスト
# - バトルチャプターのロード・設定の整合性
# - ストーリー中のバトル呼び出しフロー
# - 負け時のリダイレクト動作

const Cmd := preload("res://story/StoryCommands.gd")
const StoryScenePacked := preload("res://StoryScene.tscn")
const DefaultStoryScript := preload("res://story/DefaultStory.gd")
const Subevent1ChapterScript := preload("res://story/chapters/Subevent1Chapter.gd")

const BattleChapterBase := preload("res://battle/BattleChapterBase.gd")
const ThiefJinChapter := preload("res://battle/chapters/ThiefJinBattleChapter.gd")
const ThiefMarcoChapter := preload("res://battle/chapters/ThiefMarcoBattleChapter.gd")
const ThiefGaldChapter := preload("res://battle/chapters/ThiefGaldBattleChapter.gd")
const Stage2Chapter := preload("res://battle/chapters/Stage2BattleChapter.gd")
const PrologueChapter := preload("res://battle/chapters/PrologueBattleChapter.gd")
const Stage1Chapter := preload("res://battle/chapters/Stage1BattleChapter.gd")
const ReceptionistChapter := preload("res://battle/chapters/ReceptionistBattleChapter.gd")

func get_name() -> String:
	return "E2EBattle"

func get_tests() -> Array:
	return [
		# バトルチャプター基本チェック
		{"name": "all_chapters_load", "callable": Callable(self, "_test_all_chapters_load")},
		{"name": "all_chapters_have_required_methods", "callable": Callable(self, "_test_required_methods")},
		{"name": "all_chapters_have_lose_behavior", "callable": Callable(self, "_test_lose_behavior")},
		{"name": "all_chapters_have_valid_lose_redirect", "callable": Callable(self, "_test_lose_redirect")},
		{"name": "outfit_count_matches_functions", "callable": Callable(self, "_test_outfit_count")},
		# ストーリーシーケンスチェック
		{"name": "subevent1_sequences_registered", "callable": Callable(self, "_test_subevent1_sequences")},
		{"name": "subevent1_battle_paths_valid", "callable": Callable(self, "_test_battle_paths_in_sequence")},
		# 画像パスチェック
		{"name": "all_portrait_paths_exist", "callable": Callable(self, "_test_portrait_paths")},
		# farewell チェック
		{"name": "abort_chapters_have_farewell", "callable": Callable(self, "_test_farewell_on_abort")},
		# Main.gd フロー制御チェック（静的解析）
		{"name": "main_battle_requested_connected", "callable": Callable(self, "_test_main_battle_requested_connected")},
		{"name": "main_chapter_path_loading", "callable": Callable(self, "_test_main_chapter_path_loading")},
		{"name": "main_lose_guild_home_redirect", "callable": Callable(self, "_test_main_lose_guild_home_redirect")},
		{"name": "main_subevent_has_battle_requested", "callable": Callable(self, "_test_main_subevent_battle_requested")},
	]

# --- バトルチャプター基本チェック ---

func _get_all_chapters() -> Array:
	return [
		{"name": "ThiefJin", "instance": ThiefJinChapter.new()},
		{"name": "ThiefMarco", "instance": ThiefMarcoChapter.new()},
		{"name": "ThiefGald", "instance": ThiefGaldChapter.new()},
		{"name": "Stage2(Belka)", "instance": Stage2Chapter.new()},
		{"name": "Prologue(Matilda)", "instance": PrologueChapter.new()},
		{"name": "Stage1(AdvA)", "instance": Stage1Chapter.new()},
		{"name": "Receptionist", "instance": ReceptionistChapter.new()},
	]

func _test_all_chapters_load() -> bool:
	var all_ok := true
	for ch in _get_all_chapters():
		if ch.instance == null:
			all_ok = fail("Failed to load chapter: %s" % ch.name) and false
	return all_ok

func _test_required_methods() -> bool:
	var all_ok := true
	var required := [
		"get_opponent_id", "get_opponent_name",
		"get_opponent_outfit_count", "get_player_outfit_count",
		"get_opponent_hand", "get_opponent_deck_size", "get_player_deck_size",
	]
	for ch in _get_all_chapters():
		for method in required:
			if not ch.instance.has_method(method):
				all_ok = fail("%s missing method: %s" % [ch.name, method]) and false
	return all_ok

func _test_lose_behavior() -> bool:
	var expected := {
		"ThiefJin": "abort",
		"ThiefMarco": "abort",
		"ThiefGald": "abort",
		"Stage2(Belka)": "abort",
		"Prologue(Matilda)": "redirect",
		"Stage1(AdvA)": "continue",
		"Receptionist": "continue",
	}
	var all_ok := true
	for ch in _get_all_chapters():
		var behavior: String = ch.instance.get_lose_behavior()
		var exp: String = expected.get(ch.name, "continue")
		if behavior != exp:
			all_ok = fail("%s: lose_behavior = '%s', expected '%s'" % [ch.name, behavior, exp]) and false
	return all_ok

func _test_lose_redirect() -> bool:
	var all_ok := true
	for ch in _get_all_chapters():
		var behavior: String = ch.instance.get_lose_behavior()
		if behavior == "abort" or behavior == "redirect":
			var redirect: Dictionary = ch.instance.get_lose_redirect()
			if redirect.is_empty():
				all_ok = fail("%s: lose_behavior='%s' but get_lose_redirect() is empty" % [ch.name, behavior]) and false
			elif not redirect.has("type"):
				all_ok = fail("%s: get_lose_redirect() missing 'type' key" % ch.name) and false
	return all_ok

func _test_outfit_count() -> bool:
	var all_ok := true
	for ch in _get_all_chapters():
		var count: int = ch.instance.get_opponent_outfit_count()
		# Check outfit_N functions exist for each count
		for i in range(count, 0, -1):
			var method_name := "outfit_%d" % i
			if not ch.instance.has_method(method_name):
				all_ok = fail("%s: outfit_count=%d but missing method %s" % [ch.name, count, method_name]) and false
		# Check setup_scene exists
		if not ch.instance.has_method("setup_scene"):
			all_ok = fail("%s: missing setup_scene" % ch.name) and false
	return all_ok

# --- ストーリーシーケンスチェック ---

func _test_subevent1_sequences() -> bool:
	var story_script = DefaultStoryScript.new()
	var chapter = Subevent1ChapterScript.new()
	story_script._register_chapter(chapter)

	var all_ok := true
	var pre_seq = story_script.get_sequence("subevent1_pre")
	var post_seq = story_script.get_sequence("subevent1_post")

	if pre_seq == null:
		all_ok = fail("subevent1_pre sequence not found") and false
	elif pre_seq.entries.is_empty():
		all_ok = fail("subevent1_pre has no entries") and false

	if post_seq == null:
		all_ok = fail("subevent1_post sequence not found") and false
	elif post_seq.entries.is_empty():
		all_ok = fail("subevent1_post has no entries") and false

	return all_ok

func _test_battle_paths_in_sequence() -> bool:
	var story_script = DefaultStoryScript.new()
	var chapter = Subevent1ChapterScript.new()
	story_script._register_chapter(chapter)

	var all_ok := true

	for seq_id in ["subevent1_pre", "subevent1_post"]:
		var seq = story_script.get_sequence(seq_id)
		if seq == null:
			continue
		for entry in seq.entries:
			if entry is Cmd.Battle:
				var path: String = entry.chapter_path
				if path.is_empty():
					all_ok = fail("%s: Battle command with empty chapter_path" % seq_id) and false
				elif not ResourceLoader.exists(path):
					all_ok = fail("%s: Battle chapter not found: %s" % [seq_id, path]) and false
				else:
					# Verify the chapter can be instantiated
					var script = load(path)
					if script == null:
						all_ok = fail("%s: Failed to load battle chapter: %s" % [seq_id, path]) and false
					else:
						var instance = script.new()
						if instance == null:
							all_ok = fail("%s: Failed to instantiate: %s" % [seq_id, path]) and false
						elif not instance.has_method("get_opponent_outfit_count"):
							all_ok = fail("%s: %s is not a valid BattleChapter" % [seq_id, path]) and false
	return all_ok

# --- 画像パスチェック ---

func _test_portrait_paths() -> bool:
	var story_script = DefaultStoryScript.new()
	var chapter = Subevent1ChapterScript.new()
	story_script._register_chapter(chapter)

	var all_ok := true
	var checked := {}

	for seq_id in ["subevent1_pre", "subevent1_post"]:
		var seq = story_script.get_sequence(seq_id)
		if seq == null:
			continue
		for entry in seq.entries:
			if entry is Cmd.ShowCharacter and not entry.portrait_id.is_empty():
				var path: String = entry.portrait_id
				if path in checked:
					continue
				checked[path] = true
				if not ResourceLoader.exists(path):
					all_ok = fail("%s: Portrait not found: %s" % [seq_id, path]) and false

	# Also check battle chapter portraits
	for ch in _get_all_chapters():
		var farewell: Dictionary = ch.instance.get_farewell("lose")
		if not farewell.is_empty():
			var portrait: String = farewell.get("portrait", "")
			if not portrait.is_empty() and portrait not in checked:
				checked[portrait] = true
				if not ResourceLoader.exists(portrait):
					all_ok = fail("%s: Farewell portrait not found: %s" % [ch.name, portrait]) and false

	return all_ok

# --- farewell チェック ---

func _test_farewell_on_abort() -> bool:
	var all_ok := true
	for ch in _get_all_chapters():
		var behavior: String = ch.instance.get_lose_behavior()
		if behavior == "abort":
			var farewell: Dictionary = ch.instance.get_farewell("lose")
			if farewell.is_empty():
				all_ok = fail("%s: lose_behavior='abort' but get_farewell('lose') is empty" % ch.name) and false
			elif not farewell.has("text"):
				all_ok = fail("%s: farewell missing 'text'" % ch.name) and false
			elif not farewell.has("portrait"):
				all_ok = fail("%s: farewell missing 'portrait'" % ch.name) and false
	return all_ok

# --- Main.gd フロー制御チェック（静的解析） ---

func _load_main_source() -> String:
	var file := FileAccess.open("res://game/Main.gd", FileAccess.READ)
	if not file:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content

func _test_main_battle_requested_connected() -> bool:
	# _create_story_scene で battle_requested が接続されているか
	var source := _load_main_source()
	if source.is_empty():
		return fail("Cannot read Main.gd")
	return expect_true(
		source.contains("battle_requested.connect(_on_battle_requested)"),
		"_create_story_scene must connect battle_requested signal"
	)

func _test_main_chapter_path_loading() -> bool:
	# _on_battle_requested で chapter_path からチャプターをロードしているか
	var source := _load_main_source()
	if source.is_empty():
		return fail("Cannot read Main.gd")
	return expect_true(
		source.contains("cmd.chapter_path") and source.contains("load(cmd.chapter_path)"),
		"_on_battle_requested must load chapter from chapter_path when cmd.chapter is null"
	)

func _test_main_lose_guild_home_redirect() -> bool:
	# サブイベントで負けた時に _show_guild_home が呼ばれるか
	var source := _load_main_source()
	if source.is_empty():
		return fail("Cannot read Main.gd")

	var all_ok := true

	# _subevent_pre ラベルのハンドラに guild_home リダイレクトがあるか
	if not source.contains('_subevent_pre:') or not source.contains('_subevent:'):
		all_ok = fail("Jump menu must handle _subevent_pre and _subevent labels") and false

	# lose時に _show_guild_home が呼ばれるパスがあるか
	# last_battle_result == "lose" の後に _show_guild_home があるか
	var lines := source.split("\n")
	var found_lose_check := false
	var found_guild_home_after := false
	for i in range(lines.size()):
		if 'last_battle_result == "lose"' in lines[i]:
			found_lose_check = true
			# 次の数行に _show_guild_home があるか
			for j in range(i + 1, min(i + 5, lines.size())):
				if "_show_guild_home" in lines[j]:
					found_guild_home_after = true
					break

	if not found_lose_check:
		all_ok = fail("Must check GameState.last_battle_result == 'lose' after subevent") and false
	if not found_guild_home_after:
		all_ok = fail("Must call _show_guild_home() when subevent battle is lost") and false

	return all_ok

func _test_main_subevent_battle_requested() -> bool:
	# _run_subevent でストーリーシーンを作る時に battle_requested が接続されるか
	var source := _load_main_source()
	if source.is_empty():
		return fail("Cannot read Main.gd")

	# _run_subevent 内の story_scene_instance 作成ブロックを探す
	var lines := source.split("\n")
	var in_run_subevent := false
	var found_instantiate := false
	var found_battle_connect := false
	var found_next_func := false

	for line in lines:
		if "func _run_subevent(" in line and "standalone" not in line and "part" not in line:
			in_run_subevent = true
			found_instantiate = false
			found_battle_connect = false
			continue
		if in_run_subevent:
			if line.begins_with("func ") and "func _run_subevent(" not in line:
				found_next_func = true
				break
			if "story_scene_scene.instantiate()" in line:
				found_instantiate = true
			if "battle_requested.connect" in line:
				found_battle_connect = true

	if not found_instantiate:
		return fail("_run_subevent must instantiate story_scene")
	if not found_battle_connect:
		return fail("_run_subevent must connect battle_requested when creating story_scene_instance")
	return true
