extends SceneTree
# ストーリー編集レイアウト（ナビ帯＋左右カード）の構造とカード bind を検証。
# 実行: Godot --path godot --headless --script res://tests/RunStoryEditLayout.gd

const GameStateScript := preload("res://game/GameState.gd")

var _fails: int = 0

func _check(cond: bool, msg: String):
	if cond:
		printerr("[SL] PASS: %s" % msg)
	else:
		printerr("[SL] FAIL: %s" % msg)
		_fails += 1

func _initialize():
	printerr("[SL] start")
	var gs = GameStateScript.new(); gs.name = "GameState"; root.add_child(gs)
	await process_frame
	var main_inst = load("res://Main.tscn").instantiate()
	root.add_child(main_inst)
	await process_frame; await process_frame

	# 1. レイアウト生成
	var layout: Control = main_inst._create_story_edit_layout()
	root.add_child(layout)
	await process_frame

	var nav_bar: PanelContainer = layout.find_child("StoryEditNavBar", true, false)
	var left_card: PanelContainer = layout.find_child("StoryEditCard_Left", true, false)
	var right_card: PanelContainer = layout.find_child("StoryEditCard_Right", true, false)
	_check(nav_bar != null, "nav bar exists")
	_check(left_card != null, "left card exists")
	_check(right_card != null, "right card exists")

	# 2. ナビ帯のボタン
	if nav_bar:
		_check(nav_bar.find_child("PrevBtn", true, false) != null, "nav bar has PrevBtn")
		_check(nav_bar.find_child("NextBtn", true, false) != null, "nav bar has NextBtn")
		_check(nav_bar.find_child("ExitBtn", true, false) != null, "nav bar has ExitBtn")
		_check(nav_bar.find_child("IdxLabel", true, false) != null, "nav bar has IdxLabel")
		_check(nav_bar.find_child("CmdLabel", true, false) != null, "nav bar has CmdLabel")

	# 3. カードのボタン・スライダー
	for label_name in ["Left", "Right"]:
		var card: PanelContainer = layout.find_child("StoryEditCard_" + label_name, true, false)
		if not card:
			continue
		_check(card.find_child("SaveBtn", true, false) != null, "%s card has SaveBtn" % label_name)
		_check(card.find_child("CopyBtn", true, false) != null, "%s card has CopyBtn" % label_name)
		_check(card.find_child("ScaleSlider", true, false) != null, "%s card has ScaleSlider" % label_name)
		_check(card.find_child("XSlider", true, false) != null, "%s card has XSlider" % label_name)
		_check(card.find_child("YSlider", true, false) != null, "%s card has YSlider" % label_name)
		_check(card.has_meta("card_side"), "%s card has card_side meta" % label_name)
		# 初期状態は非表示（立ち絵なし）
		_check(not card.visible, "%s card is hidden initially" % label_name)

	# 4. アンカー: 左カード=左上、右カード=右上
	if left_card and right_card:
		_check(left_card.anchor_left < 0.5, "left card anchored to left side (anchor_left=%.2f)" % left_card.anchor_left)
		_check(right_card.anchor_left > 0.5, "right card anchored to right side (anchor_left=%.2f)" % right_card.anchor_left)

	# 5. _bind_story_edit_card: fake rect を bind すると visible になり、target meta が入る
	if left_card:
		var fake_rect := TextureRect.new()
		var fake_tex := ImageTexture.create_from_image(Image.create(100, 100, false, Image.FORMAT_RGBA8))
		fake_rect.texture = fake_tex
		fake_rect.visible = true
		root.add_child(fake_rect)
		# scene の代わりに簡易 stub を作る（_bind_story_edit_card は scene 引数を使わない）
		main_inst._bind_story_edit_card(left_card, null, "left", fake_rect)
		_check(left_card.visible, "left card becomes visible after bind")
		_check(left_card.get_meta("bound_side") == "left", "left card bound_side=left")
		_check(left_card.get_meta("bound_rect") == fake_rect, "left card bound_rect set")
		# unbind (null)
		main_inst._bind_story_edit_card(left_card, null, "", null)
		_check(not left_card.visible, "left card hidden after unbind")
		fake_rect.queue_free()

	printerr("[SL] done, fails=%d" % _fails)
	quit(1 if _fails > 0 else 0)
