extends SceneTree
# ストーリー編集の画像差し替え（ピッカー）機能の検証:
# - prefix 抽出と sibling マッチのヘルパ動作
# - プロジェクト全体の使用数カウント
# - 「ピッカー選択 → プレビュー → 明示保存」で対象1行のパスのみ置換され、
#   同一旧画像の他の出現には波及しないこと（差し替え時は波及スキップ）。
# 対象ファイルはバックアップ→復元。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditImagePicker.gd

const GameStateScript := preload("res://game/GameState.gd")
const SRC := "res://story/chapters/Subevent1Chapter.gd"
const OLD_IMG := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png"
const NEW_IMG := "res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png"

var _fails: int = 0
func _check(c, m):
	if c:
		printerr("[PICK] PASS: %s" % m)
	else:
		printerr("[PICK] FAIL: %s" % m)
		_fails += 1

func _read(p) -> String:
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.READ)
	if not f: return ""
	var t := f.get_as_text(); f.close(); return t

func _write(p, c):
	var f := FileAccess.open(ProjectSettings.globalize_path(p), FileAccess.WRITE)
	if f: f.store_string(c); f.close()

func _initialize():
	printerr("[PICK] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# --- ヘルパ動作 ---
	var prefix: String = main_inst._story_edit_prefix_of("satoshi_isekai_007.png")
	_check(prefix == "satoshi_isekai_", "prefix_of('satoshi_isekai_007.png') = 'satoshi_isekai_' (got '%s')" % prefix)
	_check(main_inst._story_edit_match_prefix("satoshi_isekai_010.png", "satoshi_isekai_"), "match_prefix sibling 同 prefix")
	_check(not main_inst._story_edit_match_prefix("pisuke_default_001.png", "satoshi_isekai_"), "match_prefix 別キャラは弾く")
	_check(not main_inst._story_edit_match_prefix("satoshi_isekai_pose.png", "satoshi_isekai_"), "match_prefix 末尾が数字でないものは弾く")

	# --- 使用数カウント（プロジェクト全 .gd 文字列検索）---
	main_inst._story_edit_rebuild_gd_cache()
	var c_old: int = main_inst._story_edit_count_image_uses(OLD_IMG)
	# 実行時に組み立てて、このテストソースに literal が現れないようにする
	# （cache はテストファイル自身も走査するので、書いた文字列はヒットしてしまう）
	var nonex_path: String = "%s://%s/%s/never_%s.png" % ["res", "zzzimaginary", "path_xyzq", str(randi())]
	var c_unused: int = main_inst._story_edit_count_image_uses(nonex_path)
	_check(c_old > 0, "satoshi_007 の使用数は >0 (got %d)" % c_old)
	_check(c_unused == 0, "存在しない画像は 0 件 (got %d)" % c_unused)

	# --- 画像差し替え保存 end-to-end ---
	var snapshot := _read(SRC)
	var lines := snapshot.split("\n")
	# Subevent1Chapter から satoshi_007 を使う set_portrait 行を探す
	var sp_line := -1
	var occ_count := 0
	for i in range(lines.size()):
		if OLD_IMG in lines[i] and "set_portrait(" in lines[i] and not lines[i].strip_edges().begins_with("#"):
			if sp_line < 0:
				sp_line = i + 1
			occ_count += 1
	_check(sp_line > 0, "satoshi_007 を使う set_portrait 行を発見 (行%d)" % sp_line)
	_check(occ_count >= 2, "比較用に satoshi_007 set_portrait が 2 箇所以上ある (got %d)" % occ_count)
	printerr("[PICK] target line=%d, satoshi_007 set_portrait 総数=%d" % [sp_line, occ_count])

	main_inst._create_story_scene()
	var sc = main_inst.story_scene_instance
	sc.portrait_log_enabled = true
	sc.portrait_log.clear()
	var rect: TextureRect = sc.left_char
	rect.visible = true
	var old_tex := ImageTexture.create_from_image(Image.create(50, 50, false, Image.FORMAT_RGBA8))
	old_tex.resource_path = OLD_IMG
	rect.texture = old_tex
	sc.portrait_log.append({
		"rect": rect, "side": "left", "texture": old_tex,
		"texture_path": OLD_IMG, "character_id": "main",
		"scale": 0.71, "position": Vector2(0, 70), "flip_h": false,
		"background": null, "dialogue": {},
		"edit_source_id": "%s:%d" % [SRC, sp_line],
	})

	var layout: Control = main_inst._create_story_edit_layout()
	main_inst.add_child(layout)
	await process_frame
	var card: PanelContainer = layout.find_child("StoryEditCard_Left", true, false)
	main_inst._bind_story_edit_card(card, sc, "left", rect)

	# ピッカー選択をシミュレート
	main_inst._on_story_edit_image_picked(card, NEW_IMG)
	_check(card.has_meta("pending_portrait_path"), "pending_portrait_path meta が立っている")
	_check(card.get_meta("pending_portrait_path") == NEW_IMG, "pending が新パスを指す")

	# スライダー値は維持（変えない）→ 既存値で保存
	main_inst._save_story_edit_card(card, [], 0)
	for _w in range(4): await process_frame
	var info: Label = card.find_child("InfoLabel", true, false)
	var msg: String = info.text if info else ""
	printerr("[PICK] InfoLabel = '%s'" % msg)

	_check(msg.begins_with("[保存]"), "保存成功 (got '%s')" % msg)
	_check("画像差し替え" in msg, "InfoLabel に「画像差し替え」表示")
	_check(not card.has_meta("pending_portrait_path"), "保存後 pending が消える")

	# ファイル検証: 編集対象行は新パス、他の satoshi_007 行はそのまま（波及スキップ）
	var after := _read(SRC)
	var after_lines := after.split("\n")
	var after_old_count := 0
	var target_line_has_new := false
	for i in range(after_lines.size()):
		if "set_portrait(" in after_lines[i]:
			if (i + 1) == sp_line:
				target_line_has_new = NEW_IMG in after_lines[i]
			elif OLD_IMG in after_lines[i] and not after_lines[i].strip_edges().begins_with("#"):
				after_old_count += 1
	# 復元
	_write(SRC, snapshot)
	printerr("[PICK] (file restored)")

	_check(target_line_has_new, "対象行（行%d）が新画像 %s に置換された" % [sp_line, NEW_IMG.get_file()])
	_check(after_old_count == occ_count - 1, "他の satoshi_007 set_portrait は据え置き（旧:%d → 残:%d 期待:%d）" % [occ_count, after_old_count, occ_count - 1])

	printerr("[PICK] fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
