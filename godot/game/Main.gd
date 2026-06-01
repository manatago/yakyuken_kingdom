extends Control

const DefaultStoryScript := preload("res://story/DefaultStory.gd")
const PortraitLayoutDB = preload("res://story/PortraitLayout.gd")

@warning_ignore("unused_signal")
signal result_updated(text)

@export var enable_story_playback := true

@onready var background_rect = $Background
@onready var title_menu = $TitleMenu
@onready var new_game_button = $TitleMenu/NewGameButton
@onready var continue_button = $TitleMenu/ContinueButton
@onready var edit_mode_button = $TitleMenu/EditModeButton
@onready var jump_menu = $JumpMenu
@onready var jump_list = $JumpMenu/JumpScroll/JumpList
@onready var back_button = $JumpMenu/BackButton
@onready var battle_result_screen = $BattleResultScreen
@onready var result_title = $BattleResultScreen/ResultMenu/ResultTitle
@onready var result_message = $BattleResultScreen/ResultMenu/ResultMessage
@onready var result_buttons = $BattleResultScreen/ResultMenu/ResultButtons

# デフォルトインベントリ（各ジャンプポイントでも使い回す）
const DEFAULT_INVENTORY: Array = [
	{"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1}, {"hand": "rock", "grade": 1},
	{"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1}, {"hand": "scissors", "grade": 1},
	{"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1}, {"hand": "paper", "grade": 1},
]

# 開発用ジャンプ先定義
var _jump_points: Array = [
	{"label": "scene_university", "name": "大学",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_room", "name": "自室",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_lab1", "name": "研究室1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_lab2", "name": "研究室2",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_teleport1", "name": "転送広場1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_teleport2", "name": "転送広場2",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_prison", "name": "牢獄",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "tutorial_start", "name": "チュートリアル",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "after_tutorial", "name": "チュートリアル後〜バトル前",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "battle_start", "name": "本番バトル",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_result:win", "name": "バトル後（勝利）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_result:lose", "name": "バトル後（敗北）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_matilda_lose", "name": "マチルダ敗北後",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "scene_guild_street", "name": "--- Stage1 ---",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true}, "money": 0}},
	{"label": "scene_guild_street", "name": "ギルド通り", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "scene_analysis", "name": "道中・解析", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "scene_guild_hall", "name": "冒険者ギルド", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "stage1_battle_start", "name": "冒険者Aバトル", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "scene_guild_reception", "name": "ギルド受付", "sequence": "stage1",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true}, "money": 0}},
	{"label": "_guild_home", "name": "ギルドホーム",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true}, "money": 0}},
	{"label": "_subevent_pre1:subevent1", "name": "サブイベント1 前半1（ギルドホーム）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true}, "money": 100}},
	{"label": "_subevent_pre2:subevent1", "name": "サブイベント1 前半2（盗賊団アジト）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true}, "money": 100}},
	{"label": "subevent1_jin_battle", "name": "  └ ジン戦 戦闘前", "sequence": "subevent1_hideout",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true}, "money": 100}},
	{"label": "subevent1_jin_battle_done", "name": "  └ ジン戦 戦闘後", "sequence": "subevent1_hideout",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "encounter_jin_seen": true}, "money": 100}},
	{"label": "subevent1_marco_battle", "name": "  └ マルコ戦 戦闘前", "sequence": "subevent1_hideout",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "encounter_jin_seen": true}, "money": 100}},
	{"label": "subevent1_marco_battle_done", "name": "  └ マルコ戦 戦闘後", "sequence": "subevent1_hideout",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "encounter_jin_seen": true, "encounter_marco_seen": true}, "money": 100}},
	{"label": "subevent1_gald_battle", "name": "  └ ガルド戦 戦闘前", "sequence": "subevent1_hideout",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "encounter_jin_seen": true, "encounter_marco_seen": true}, "money": 100}},
	{"label": "subevent1_gald_battle_done", "name": "  └ ガルド戦 戦闘後", "sequence": "subevent1_hideout",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "encounter_jin_seen": true, "encounter_marco_seen": true, "encounter_gald_seen": true}, "money": 100}},
	{"label": "subevent1_boss_battle", "name": "  └ ベルカ戦 戦闘前", "sequence": "subevent1_hideout",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "encounter_jin_seen": true, "encounter_marco_seen": true, "encounter_gald_seen": true}, "money": 100}},
	{"label": "subevent1_belka_battle_done", "name": "  └ ベルカ戦 戦闘後", "sequence": "subevent1_hideout",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "encounter_jin_seen": true, "encounter_marco_seen": true, "encounter_gald_seen": true, "encounter_belka_seen": true}, "money": 100}},
	{"label": "_subevent_post:subevent1", "name": "サブイベント1 後半（ベルカ決着後）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true}, "money": 100}},
	{"label": "_subevent_pre1:subevent2", "name": "サブイベント2 前半1（ギルド→教会裏庭）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "subevent1_complete": true}, "money": 200}},
	{"label": "_subevent_pre2:subevent2", "name": "サブイベント2 前半2（礼拝室→シスター長戦）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "subevent1_complete": true}, "money": 200}},
	{"label": "subevent2_boss_battle", "name": "  └ シスター長戦 戦闘前", "sequence": "subevent2_pre2",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "subevent1_complete": true}, "money": 200}},
	{"label": "subevent2_boss_battle_done", "name": "  └ シスター長戦 戦闘後", "sequence": "subevent2_pre2",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "subevent1_complete": true, "encounter_sister_long_seen": true}, "money": 200}},
	{"label": "_subevent_post:subevent2", "name": "サブイベント2 後半（シスター長決着後）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "subevent1_complete": true}, "money": 200}},
	{"label": "subevent2_rematch_battle", "name": "  └ シスター長 再戦 戦闘前", "sequence": "subevent2_rematch",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "subevent1_complete": true, "encounter_sister_long_seen": true}, "money": 200}},
	{"label": "subevent2_rematch_battle_done", "name": "  └ シスター長 再戦 戦闘後", "sequence": "subevent2_rematch",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "met_pisuke": true, "guild_registered": true, "subevent1_complete": true, "encounter_sister_long_seen": true}, "money": 200}},
	{"label": "_subevent_pre:subevent3", "name": "--- Subevent3 (フィオナ) ---",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "_subevent_pre:subevent3", "name": "場面1 依頼受注",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "_subevent_pre2:subevent3", "name": "場面2 鍛冶屋ゴルン",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "_subevent_pre3:subevent3", "name": "場面3-7 エドモンド邸",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "subevent3_battle_start", "name": "  └ フィオナ戦 戦闘前", "sequence": "subevent3_visit",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "_subevent_post:subevent3", "name": "  └ フィオナ戦 戦闘後（場面8 決着）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "_subevent_pre:subevent4", "name": "--- Subevent4 (受付嬢) ---",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "_subevent_pre:subevent4", "name": "前半",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "subevent4_battle_start", "name": "  └ 受付嬢戦 戦闘前", "sequence": "subevent4_pre",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "_subevent_post:subevent4", "name": "  └ 受付嬢戦 戦闘後（後半）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true}, "money": 300}},
	{"label": "stage2_pre", "name": "--- Stage2 (レイラ) ---", "sequence": "stage2_pre",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true}, "money": 200}},
	{"label": "stage2_pre", "name": "場面1 盗難濡れ衣", "sequence": "stage2_pre",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true}, "money": 200}},
	{"label": "stage2_meet", "name": "場面2 月の葉亭・対面", "sequence": "stage2_meet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true}, "money": 200}},
	{"label": "stage2_battle1_start", "name": "  └ 1戦目 戦闘前", "sequence": "stage2_meet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true}, "money": 200}},
	{"label": "stage2_battle1_done", "name": "  └ 1戦目 戦闘後", "sequence": "stage2_meet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true}, "money": 200}},
	{"label": "stage2_recover", "name": "場面4 作戦会議", "sequence": "stage2_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true}, "money": 200}},
	{"label": "stage2_battle2_start", "name": "  └ 2戦目 戦闘前", "sequence": "stage2_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true, "stage2_first_battle_done": true}, "money": 200}},
	{"label": "stage2_battle2_done", "name": "  └ 2戦目 戦闘後", "sequence": "stage2_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true, "stage2_first_battle_done": true}, "money": 200}},
	{"label": "stage2_post", "name": "場面7 敗北後の恨み", "sequence": "stage2_post",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true}, "money": 200}},
	{"label": "stage2_close", "name": "場面8 ギルド帰還", "sequence": "stage2_close",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "subevent1_complete": true, "subevent2_complete": true}, "money": 200}},
	{"label": "stage3_harass", "name": "--- Stage3 (マグダレナ) ---", "sequence": "stage3_harass",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true}, "money": 300}},
	{"label": "stage3_harass", "name": "場面1-2 教会嫌がらせ", "sequence": "stage3_harass",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true}, "money": 300}},
	{"label": "stage3_challenge", "name": "場面3 教会乗り込み", "sequence": "stage3_challenge",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true}, "money": 300}},
	{"label": "stage3_battle1_start", "name": "  └ 1戦目 戦闘前", "sequence": "stage3_challenge",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true}, "money": 300}},
	{"label": "stage3_battle1_done", "name": "  └ 1戦目 戦闘後", "sequence": "stage3_challenge",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true}, "money": 300}},
	{"label": "stage3_recover", "name": "場面5 作戦会議", "sequence": "stage3_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true}, "money": 300}},
	{"label": "stage3_battle2_start", "name": "  └ 2戦目 戦闘前", "sequence": "stage3_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true, "stage3_first_battle_done": true}, "money": 300}},
	{"label": "stage3_battle2_done", "name": "  └ 2戦目 戦闘後", "sequence": "stage3_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true, "stage3_first_battle_done": true}, "money": 300}},
	{"label": "stage3_post", "name": "場面8 嫌がらせ停止", "sequence": "stage3_post",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage2_complete": true}, "money": 300}},
	{"label": "stage4_pre", "name": "--- Stage4 (セレス) ---", "sequence": "stage4_pre",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_pre", "name": "場面1 挑戦状", "sequence": "stage4_pre",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_infiltrate", "name": "場面2 潜入失敗", "sequence": "stage4_infiltrate",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_meet", "name": "場面3 セレス対面", "sequence": "stage4_meet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_battle1_start", "name": "  └ 1戦目 戦闘前", "sequence": "stage4_meet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_battle1_done", "name": "  └ 1戦目 戦闘後", "sequence": "stage4_meet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_contract", "name": "場面4.5 契約執行", "sequence": "stage4_contract",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_recover", "name": "場面5 ミニゲーム準備", "sequence": "stage4_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_battle2_start", "name": "  └ 2戦目 戦闘前", "sequence": "stage4_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true, "stage4_first_battle_done": true}, "money": 400}},
	{"label": "stage4_battle2_done", "name": "  └ 2戦目 戦闘後", "sequence": "stage4_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true, "stage4_first_battle_done": true}, "money": 400}},
	{"label": "stage4_post", "name": "場面8 セレスの執着", "sequence": "stage4_post",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage4_close", "name": "場面9 ギルド帰還", "sequence": "stage4_close",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage3_complete": true}, "money": 400}},
	{"label": "stage5_summon", "name": "--- Stage5 (フェリア) ---", "sequence": "stage5_summon",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true}, "money": 500}},
	{"label": "stage5_summon", "name": "場面1-2 出頭命令", "sequence": "stage5_summon",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true}, "money": 500}},
	{"label": "stage5_interrogation", "name": "場面3 取り調べ・決闘", "sequence": "stage5_interrogation",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true}, "money": 500}},
	{"label": "stage5_battle1_start", "name": "  └ 1戦目 戦闘前", "sequence": "stage5_interrogation",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true}, "money": 500}},
	{"label": "stage5_battle1_done", "name": "  └ 1戦目 戦闘後", "sequence": "stage5_interrogation",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true}, "money": 500}},
	{"label": "stage5_recover", "name": "場面5 作戦会議", "sequence": "stage5_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true}, "money": 500}},
	{"label": "stage5_battle2_start", "name": "  └ 2戦目 戦闘前", "sequence": "stage5_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true, "stage5_first_battle_done": true}, "money": 500}},
	{"label": "stage5_battle2_done", "name": "  └ 2戦目 戦闘後", "sequence": "stage5_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true, "stage5_first_battle_done": true}, "money": 500}},
	{"label": "stage5_post", "name": "場面7 再戦勝利後", "sequence": "stage5_post",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true}, "money": 500}},
	{"label": "stage5_close", "name": "場面9 ギルド帰還", "sequence": "stage5_close",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage4_complete": true}, "money": 500}},
	{"label": "stage6_pre", "name": "--- Stage6 (王女) ---", "sequence": "stage6_pre",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true}, "money": 600}},
	{"label": "stage6_pre", "name": "場面1 招待状", "sequence": "stage6_pre",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true}, "money": 600}},
	{"label": "stage6_banquet", "name": "場面2 晩餐会・初戦", "sequence": "stage6_banquet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true}, "money": 600}},
	{"label": "stage6_battle1_start", "name": "  └ 1戦目 戦闘前", "sequence": "stage6_banquet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true}, "money": 600}},
	{"label": "stage6_battle1_done", "name": "  └ 1戦目 戦闘後", "sequence": "stage6_banquet",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true}, "money": 600}},
	{"label": "stage6_recover", "name": "場面3 控えの間・ブチギレ", "sequence": "stage6_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true}, "money": 600}},
	{"label": "stage6_battle2_start", "name": "  └ 2戦目 戦闘前", "sequence": "stage6_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true, "stage6_first_battle_done": true}, "money": 600}},
	{"label": "stage6_battle2_done", "name": "  └ 2戦目 戦闘後", "sequence": "stage6_recover",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true, "stage6_first_battle_done": true}, "money": 600}},
	{"label": "stage6_post", "name": "場面4 再戦勝利・余韻", "sequence": "stage6_post",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage5_complete": true}, "money": 600}},
	{"label": "stage7_throne", "name": "--- Stage7 (エンディング) ---", "sequence": "stage7_throne",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage6_complete": true}, "money": 800}},
	{"label": "stage7_throne", "name": "場面1 王座継承", "sequence": "stage7_throne",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage6_complete": true}, "money": 800}},
	{"label": "stage7_epilogue", "name": "場面2 エピローグ", "sequence": "stage7_epilogue",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {"prologue_complete": true, "guild_registered": true, "stage6_complete": true}, "money": 800}},
	{"label": "_minigame:minigame_smoke", "name": "--- ミニゲーム ---",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_minigame:minigame_smoke", "name": "＜ミニゲーム＞スモークテスト",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_minigame:minigame_subevent3", "name": "＜ミニゲーム＞サブイベント3（羞恥の儀）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_minigame:minigame_stage2", "name": "＜ミニゲーム＞ST2（レイラ・相手の動揺を指摘せよ）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_minigame:minigame_stage3", "name": "＜ミニゲーム＞ST3（マグダレナ・書棚で妄想を誘発せよ）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_minigame:minigame_stage4", "name": "＜ミニゲーム＞ST4（セレス・強度を合わせて崩せ）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
	{"label": "_minigame:minigame_stage5", "name": "＜ミニゲーム＞ST5（フェリア・距離を詰めて自白を引き出せ）",
		"state": {"inventory": DEFAULT_INVENTORY, "flags": {}, "money": 0}},
]

var story_scene_scene = preload("res://StoryScene.tscn")
var battle_scene_scene = preload("res://BattleScene.tscn")
var guild_home_scene = preload("res://GuildHome.tscn")
const Stage1TownMapScript = preload("res://town/maps/Stage1TownMap.gd")
var story_scene_instance
var story_script: DefaultStory

var is_dialogue_active = false

func _ready():
	# 編集モードで ShowCharacter の呼び出し位置を記録するため、章登録より前に有効化。
	# これによりストーリー章の set_portrait/appear も edit_source_id を持ち、
	# バトル編集と同じ堅牢な保存（ファイル＋行番号特定）が使えるようになる。
	StoryCommands.editor_capture = true
	GameState.reset()
	GameState.init_default_inventory()
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	edit_mode_button.pressed.connect(_on_edit_mode)
	back_button.pressed.connect(_on_jump_back)
	title_menu.visible = true
	jump_menu.visible = false

func _on_new_game():
	title_menu.visible = false
	GameState.reset()
	GameState.init_default_inventory()
	_create_story_scene()
	await scenario()

func _on_continue():
	title_menu.visible = false
	_show_jump_menu()

func _show_jump_menu():
	for child in jump_list.get_children():
		child.queue_free()
	# 通常ジャンプポイント
	for point in _jump_points:
		var btn := Button.new()
		btn.text = point.name
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_jump_selected.bind(point))
		jump_list.add_child(btn)
	jump_menu.visible = true

# --- 編集モード選択メニュー ---

func _on_edit_mode():
	title_menu.visible = false
	_show_edit_menu()

func _show_edit_menu():
	title_menu.visible = false
	for child in jump_list.get_children():
		child.queue_free()
	# ランダムバトル編集ボタン
	var edit_btn := Button.new()
	edit_btn.text = "▶ ランダムバトル編集"
	edit_btn.add_theme_font_size_override("font_size", 20)
	edit_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	edit_btn.pressed.connect(_on_char_edit_mode)
	jump_list.add_child(edit_btn)
	# イベントバトル編集ボタン
	var event_edit_btn := Button.new()
	event_edit_btn.text = "▶ イベントバトル編集"
	event_edit_btn.add_theme_font_size_override("font_size", 20)
	event_edit_btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	event_edit_btn.pressed.connect(_on_event_battle_edit_mode)
	jump_list.add_child(event_edit_btn)
	# ストーリー編集ボタン
	var story_edit_btn := Button.new()
	story_edit_btn.text = "▶ ストーリー編集"
	story_edit_btn.add_theme_font_size_override("font_size", 20)
	story_edit_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	story_edit_btn.pressed.connect(_on_story_edit_mode)
	jump_list.add_child(story_edit_btn)
	jump_menu.visible = true

func _on_jump_selected(point: Dictionary):
	jump_menu.visible = false
	var label_name: String = point.label
	var sequence_id: String = point.get("sequence", "prologue")
	# ジャンプポイントの状態を GameState にセット
	GameState.reset()
	var state: Dictionary = point.get("state", {})
	GameState.apply(state)
	GameState.chapter = sequence_id
	GameState.label = label_name
	if label_name == "_guild_home":
		await _show_guild_home()
		title_menu.visible = true
		return
	if label_name == "_matilda_lose":
		_create_story_scene()
		await _play_scene("prologue_battle_lose")
		var matilda_choice: String = await _show_choice_overlay(["再挑戦する", "ホームに戻る"])
		print("[JUMP] 選択: %s" % matilda_choice)
		if story_scene_instance:
			story_scene_instance.queue_free()
			story_scene_instance = null
		title_menu.visible = true
		return
	if label_name.begins_with("_subevent_pre1:"):
		var quest_id := label_name.substr(15)
		await _run_subevent_part_standalone(quest_id, "pre1")
		title_menu.visible = true
		return
	if label_name.begins_with("_subevent_pre3:"):
		var quest_id := label_name.substr(15)
		await _run_subevent_part_standalone(quest_id, "pre3")
		if GameState.last_battle_result == "lose":
			await _show_guild_home()
		title_menu.visible = true
		return
	if label_name.begins_with("_subevent_pre2:"):
		var quest_id := label_name.substr(15)
		await _run_subevent_part_standalone(quest_id, "pre2")
		if GameState.last_battle_result == "lose":
			await _show_guild_home()
		title_menu.visible = true
		return
	if label_name.begins_with("_subevent_pre:"):
		var quest_id := label_name.substr(14)
		await _run_subevent_part_standalone(quest_id, "pre")
		if GameState.last_battle_result == "lose":
			await _show_guild_home()
		title_menu.visible = true
		return
	if label_name.begins_with("_subevent_post:"):
		var quest_id := label_name.substr(15)
		await _run_subevent_part_standalone(quest_id, "post")
		title_menu.visible = true
		return
	if label_name.begins_with("_subevent:"):
		var quest_id := label_name.substr(10)
		await _run_subevent_standalone(quest_id)
		if GameState.last_battle_result == "lose":
			await _show_guild_home()
		title_menu.visible = true
		return
	if label_name.begins_with("_minigame:"):
		var minigame_id := label_name.substr(10)
		await _run_minigame_standalone(minigame_id)
		title_menu.visible = true
		return
	if label_name.begins_with("_result:"):
		var result: String = label_name.substr(8)
		_create_story_scene()
		if result == "win":
			await _play_scene("prologue_battle_win")
		elif result == "lose":
			await _play_scene("prologue_battle_lose")
		story_scene_instance.visible = false
		var choice: String = await _show_battle_result_screen(result)
		story_scene_instance.visible = true
		if choice == "next":
			await scenario_from("stage1", "")
		elif choice == "retry":
			GameState.last_battle_result = ""
			await _play_scene_from("prologue", "battle_start")
			var entry = _scenario_order[0]
			await _handle_battle_aftermath(entry, 0)
		story_scene_instance.queue_free()
		story_scene_instance = null
		title_menu.visible = true
	else:
		_create_story_scene()
		# サブイベント章は遅延登録なので、ジャンプ前に確実にロード
		if sequence_id.begins_with("subevent1"):
			_ensure_subevent_registered("subevent1")
		elif sequence_id.begins_with("subevent2"):
			_ensure_subevent_registered("subevent2")
		elif sequence_id.begins_with("subevent3"):
			_ensure_subevent_registered("subevent3")
		elif sequence_id.begins_with("subevent4"):
			_ensure_subevent_registered("subevent4")
		await scenario_from(sequence_id, label_name)
		story_scene_instance.queue_free()
		story_scene_instance = null
		title_menu.visible = true

func _on_jump_back():
	jump_menu.visible = false
	title_menu.visible = true

# --- ランダムバトル編集モード ---

signal _char_edit_selected(char_id: String)

func _on_char_edit_mode():
	print("[EDIT] _on_char_edit_mode called")
	jump_menu.visible = false
	if not _current_town_map:
		_current_town_map = Stage1TownMapScript.new()
	var chars: Dictionary = _current_town_map.get_all_encounter_chars()
	if chars.is_empty():
		title_menu.visible = true
		return
	print("[EDIT] chars count: %d" % chars.size())
	await _show_char_select(chars)

func _show_char_select(chars: Dictionary):
	print("[EDIT] _show_char_select called")
	for child in jump_list.get_children():
		child.queue_free()
	var back_btn2 := Button.new()
	back_btn2.text = "← 戻る"
	back_btn2.add_theme_font_size_override("font_size", 20)
	back_btn2.pressed.connect(func():
		_show_edit_menu())
	jump_list.add_child(back_btn2)
	var sep := HSeparator.new()
	jump_list.add_child(sep)
	for char_id in chars:
		var char_data: Dictionary = chars[char_id]
		var btn := Button.new()
		btn.text = char_data.get("name", char_id)
		btn.add_theme_font_size_override("font_size", 20)
		var cid: String = char_id  # ラムダ用にローカルコピー
		btn.pressed.connect(func():
			print("[EDIT] button pressed: %s" % cid)
			_char_edit_selected.emit(cid))
		jump_list.add_child(btn)
	jump_menu.visible = true
	# 選択待ちループ
	while true:
		var selected_id: String = await _char_edit_selected
		print("[EDIT] selected: %s" % selected_id)
		jump_menu.visible = false
		await _run_char_edit_test(chars[selected_id])
		# テスト終了 → キャラ選択に戻る
		for child2 in jump_list.get_children():
			child2.queue_free()
		back_btn2 = Button.new()
		back_btn2.text = "← 戻る"
		back_btn2.add_theme_font_size_override("font_size", 20)
		back_btn2.pressed.connect(func():
			jump_menu.visible = false
			title_menu.visible = true)
		jump_list.add_child(back_btn2)
		sep = HSeparator.new()
		jump_list.add_child(sep)
		for char_id2 in chars:
			var char_data2: Dictionary = chars[char_id2]
			var btn2 := Button.new()
			btn2.text = char_data2.get("name", char_id2)
			btn2.add_theme_font_size_override("font_size", 20)
			btn2.pressed.connect(func(): _char_edit_selected.emit(char_id2))
			jump_list.add_child(btn2)
		jump_menu.visible = true

signal _edit_setup_done

func _run_char_edit_test(encounter_data: Dictionary):
	# 編集モードは保存→開き直しで即反映させたい。
	# EncounterDatabase.gd を強制再パースし、選択中エンカウントだけ最新値で差し替える。
	# （chars 一覧自体はピッカー再表示時にも再構築されるが、ここでも保険として実施）
	var enc_id_for_refresh: String = encounter_data.get("id", "")
	if not enc_id_for_refresh.is_empty():
		var db_script: GDScript = _load_script_fresh("res://encounter/EncounterDatabase.gd")
		if db_script:
			var fresh_db = db_script.new()
			if fresh_db and fresh_db.has_method("get_char"):
				var fresh: Dictionary = fresh_db.get_char(enc_id_for_refresh)
				if not fresh.is_empty():
					encounter_data = fresh

	GameState.reset()
	GameState.init_default_inventory()
	# 編集モード: 全アイテム・装備品・ゴールドを付与
	GameState.money = 1000
	for item_data in ItemDatabase.get_all_consumables():
		GameState.add_item({"id": item_data.id, "name": item_data.name, "count": 3})
	for equip_data in ItemDatabase.get_all_equipment():
		GameState.equipment.append({"id": equip_data.id, "name": equip_data.name})

	# エリア選択画面
	var bg_path: String = await _show_edit_area_select(encounter_data)

	# 装備選択画面
	await _show_edit_equip_screen()

	# GuildHome を表示
	var home: GuildHome = guild_home_scene.instantiate()
	add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_tex = load(bg_path) if not bg_path.is_empty() else null
	home.setup(bg_tex, _current_town_map)
	home.narration_band.visible = true
	home.narration_label.text = "【ランダムバトル編集モード】"

	# フェーズ遷移ループ: encounter(0) → battle(1) → farewell_win(2) → farewell_lose(3)
	# 各フェーズで ◀(prev) / ▶(next) / 戻る(exit) を受ける状態機械にする。
	# これでイベントバトル編集と同じ感覚でフェーズ間を ◀/▶ で行き来できる
	# （ランダムバトルは1フェーズあたり立ち絵1枚なので、◀/▶ はフェーズ移動に使う）。
	var phase_idx: int = 0
	while phase_idx >= 0 and phase_idx <= 3:
		# 直前のフェーズで保存があったかもしれない。EncounterDatabase.gd を
		# 強制再パースして encounter_data を最新化することで、◀ で戻ったときに
		# 直前に保存したスケール/位置がそのまま再表示される。
		var enc_id_refresh: String = encounter_data.get("id", "")
		if not enc_id_refresh.is_empty():
			var db_script_iter: GDScript = _load_script_fresh("res://encounter/EncounterDatabase.gd")
			if db_script_iter:
				var fresh_db_iter = db_script_iter.new()
				if fresh_db_iter and fresh_db_iter.has_method("get_char"):
					var fresh_iter: Dictionary = fresh_db_iter.get_char(enc_id_refresh)
					if not fresh_iter.is_empty():
						# battle_bg を保持（_random_phase_battle で setup に使う）
						var keep_bg: String = encounter_data.get("battle_bg", "")
						encounter_data = fresh_iter
						if not keep_bg.is_empty():
							encounter_data["battle_bg"] = keep_bg

		var action: String = ""
		match phase_idx:
			0: action = await _random_phase_portrait(home, encounter_data, "encounter")
			1: action = await _random_phase_battle(home, encounter_data, bg_tex, bg_path)
			2: action = await _random_phase_portrait(home, encounter_data, "farewell_win")
			3: action = await _random_phase_portrait(home, encounter_data, "farewell_lose")
		match action:
			"next":
				phase_idx += 1
				if phase_idx > 3:
					break
			"prev":
				if phase_idx == 0:
					break
				phase_idx -= 1
			_:
				break  # "exit" もしくはイレギュラー

	home._hide_encounter()
	# アイテム・装備品確認画面
	await _show_edit_result_screen(home)
	home.queue_free()

# ランダムバトル編集: encounter / farewell_win / farewell_lose で共通の
# 「home の立ち絵 + 編集パネル」フェーズ。◀/▶/戻る でフェーズ間を遷移する。
func _random_phase_portrait(home: GuildHome, encounter_data: Dictionary, portrait_key: String) -> String:
	var portrait_data: Dictionary = EncounterDatabase.get_portrait(encounter_data, portrait_key)
	var path: String = portrait_data.get("path", "")
	if path.is_empty():
		return "next"  # 立ち絵未設定ならスキップ
	var tex = load(path)
	if not tex:
		return "next"

	# 台詞: encounter→greetings / farewell_win→farewells_win / farewell_lose→farewells_lose
	var line_key: String = ""
	match portrait_key:
		"encounter": line_key = "greetings"
		"farewell_win": line_key = "farewells_win"
		"farewell_lose": line_key = "farewells_lose"
	var line_text: String = ""
	if not line_key.is_empty():
		line_text = EncounterDatabase.pick_line(encounter_data, line_key)

	home.visible = true
	home.encounter_portrait.texture = tex
	home._apply_encounter_portrait(tex, portrait_data)
	home.encounter_portrait.visible = true
	home.narration_label.visible = false
	home.nav_row.visible = false
	home.encounter_speaker.text = encounter_data.get("name", "")
	home.encounter_speaker.visible = true
	home.encounter_body.text = line_text if not line_text.is_empty() else "（台詞未設定）"
	home.encounter_right.visible = true
	# 「受ける/逃げる」は編集モードでは出さない（◀/▶/戻るで進む）
	for child in home.encounter_buttons.get_children():
		child.queue_free()
	home.encounter_buttons.visible = false
	home.narration_band.visible = true

	# 編集パネル（保存対象は EncounterDatabase の <portrait_key> ブロック）
	var edit_panel := _create_edit_overlay(encounter_data)
	edit_panel.set_meta("chapter_path", "res://encounter/EncounterDatabase.gd")
	edit_panel.set_meta("encounter_id", encounter_data.get("id", ""))
	edit_panel.set_meta("portrait_key", portrait_key)
	add_child(edit_panel)
	move_child(edit_panel, get_child_count() - 1)

	# _connect_edit_to_portrait は portraits.encounter からスケール/位置を読むため、
	# 編集対象のブロックを encounter キーへ詰め直して渡す
	var data_for_edit := encounter_data.duplicate()
	data_for_edit["portraits"] = {"encounter": portrait_data}
	_connect_edit_to_portrait(edit_panel, home.encounter_portrait, data_for_edit)

	# ターゲットラベルにフェーズ名を出す（[1/4] encounter のように）
	var phase_num: int = ({"encounter": 1, "farewell_win": 3, "farewell_lose": 4}).get(portrait_key, 0)
	var target_label: Label = edit_panel.find_child("TargetLabel", true, false)
	if target_label:
		target_label.text = "[%d/4] %s" % [phase_num, portrait_key]

	var action: String = await _random_wait_phase_action(edit_panel)
	edit_panel.queue_free()
	return action

# ランダムバトル編集: バトルフェーズ。立ち絵キャプチャ後に ◀/▶/戻る でフェーズ遷移する。
func _random_phase_battle(home: GuildHome, encounter_data: Dictionary, bg_tex, bg_path: String) -> String:
	home.visible = false

	var chapter := RandomBattleChapter.new()
	encounter_data["battle_bg"] = bg_path
	chapter.setup_from_encounter(encounter_data)

	var battle_edit_panel := _create_edit_overlay(encounter_data)
	battle_edit_panel.set_meta("chapter_path", "res://encounter/EncounterDatabase.gd")
	battle_edit_panel.set_meta("encounter_id", encounter_data.get("id", ""))
	battle_edit_panel.set_meta("portrait_key", "battle")
	add_child(battle_edit_panel)

	var edit_battle = battle_scene_scene.instantiate()
	add_child(edit_battle)
	edit_battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edit_battle.setup(story_script.get_cast() if story_script else {}, bg_tex, GameState.inventory)
	edit_battle.force_result_mode = true
	edit_battle.start_battle(chapter)
	move_child(battle_edit_panel, get_child_count() - 1)
	_connect_edit_to_battle(battle_edit_panel, edit_battle, encounter_data)

	# _connect_edit_to_battle が ◀/▶ を portrait_log 内のナビに繋いでいるが、
	# ランダムバトルは log エントリ1つしかないため事実上 no-op。同じボタンに
	# フェーズ nav も追加で connect する（log nav は何もせず、phase nav が発火）。
	var target_label: Label = battle_edit_panel.find_child("TargetLabel", true, false)
	if target_label:
		target_label.text = "[2/4] battle"

	var action: String = await _random_wait_phase_action(battle_edit_panel)

	_battle_edit_active = false
	_battle_edit_target_rect = null
	_battle_edit_panel = null
	_battle_edit_advancing = false
	_battle_edit_history_idx = -1
	_battle_edit_last_log_size = 0
	edit_battle.queue_free()
	battle_edit_panel.queue_free()
	return action

# 編集パネルの ◀(prev) / ▶(next) / 戻る(exit) の押下を待ち、押されたアクション名を返す。
func _random_wait_phase_action(edit_panel: PanelContainer) -> String:
	var action: Array = [""]
	var prev_btn: Button = edit_panel.find_child("PrevBtn", true, false)
	var next_btn: Button = edit_panel.find_child("NextBtn", true, false)
	var back_btn: Button = edit_panel.find_child("EditBackButton", true, false)
	if prev_btn:
		prev_btn.pressed.connect(func(): action[0] = "prev")
	if next_btn:
		next_btn.pressed.connect(func(): action[0] = "next")
	if back_btn:
		back_btn.pressed.connect(func(): action[0] = "exit")
	while action[0] == "":
		await get_tree().process_frame
	return action[0]

signal _area_selected(bg_path: String)

func _show_edit_area_select(encounter_data: Dictionary) -> String:
	# このキャラが出現するエリアを収集
	var areas: Dictionary = _current_town_map.get_areas()
	var char_areas: Array = []
	for area_id in areas:
		var encounters: Array = _current_town_map.get_encounters(area_id)
		for enc in encounters:
			if enc.id == encounter_data.id:
				char_areas.append({"id": area_id, "name": areas[area_id].name, "bg": areas[area_id].bg})
				break

	# 1つしかなければ選択不要
	if char_areas.size() <= 1:
		if char_areas.size() == 1:
			return char_areas[0].bg
		return _current_town_map.get_home_background()

	# エリア選択UI
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(400, 300)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "エリア選択"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "%s が出現するエリア:" % encounter_data.get("name", "")
	desc.add_theme_font_size_override("font_size", 16)
	vbox.add_child(desc)

	for area in char_areas:
		var btn := Button.new()
		btn.text = area.name
		btn.add_theme_font_size_override("font_size", 20)
		var area_bg: String = area.bg
		btn.pressed.connect(func(): _area_selected.emit(area_bg))
		vbox.add_child(btn)

	var selected_bg: String = await _area_selected
	panel.queue_free()
	return selected_bg

func _show_edit_equip_screen():
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(550, 500)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "装備・アイテム選択"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 装備品（着脱ボタン付き）
	var equip_title := Label.new()
	equip_title.text = "【装備品】クリックで着脱"
	equip_title.add_theme_font_size_override("font_size", 20)
	equip_title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(equip_title)

	var equip_container := VBoxContainer.new()
	equip_container.name = "EquipList"
	equip_container.add_theme_constant_override("separation", 4)
	vbox.add_child(equip_container)

	# アイテム
	var item_title := Label.new()
	item_title.text = "【消耗品】"
	item_title.add_theme_font_size_override("font_size", 20)
	item_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(item_title)

	var item_container := VBoxContainer.new()
	item_container.name = "ItemList"
	item_container.add_theme_constant_override("separation", 4)
	vbox.add_child(item_container)

	# バトルへ進むボタン
	var start_btn := Button.new()
	start_btn.text = "バトルへ進む"
	start_btn.add_theme_font_size_override("font_size", 20)
	start_btn.pressed.connect(func(): _edit_setup_done.emit())
	vbox.add_child(start_btn)

	# 装備品リストを描画
	_refresh_equip_list(equip_container)
	_refresh_item_list(item_container)

	await _edit_setup_done
	panel.queue_free()

func _refresh_equip_list(container: VBoxContainer):
	for child in container.get_children():
		child.queue_free()
	for equip_data in ItemDatabase.get_all_equipment():
		var is_equipped: bool = GameState.has_equipment(equip_data.id)
		var btn := Button.new()
		if is_equipped:
			btn.text = "✓ %s — %s" % [equip_data.name, equip_data.description]
			btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.8))
		else:
			btn.text = "  %s — %s" % [equip_data.name, equip_data.description]
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		btn.add_theme_font_size_override("font_size", 16)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var eid: String = equip_data.id
		btn.pressed.connect(func():
			if GameState.has_equipment(eid):
				GameState.unequip(eid)
			else:
				GameState.equipment.append({"id": eid, "name": equip_data.name})
			_refresh_equip_list(container))
		container.add_child(btn)

func _refresh_item_list(container: VBoxContainer):
	for child in container.get_children():
		child.queue_free()
	for item in GameState.items:
		var item_info: Dictionary = ItemDatabase.get_item(item.id)
		if item_info.is_empty():
			continue
		var row := Label.new()
		row.text = "  %s ×%d — %s" % [item.get("name", item.id), item.get("count", 1), item_info.get("description", "")]
		row.add_theme_font_size_override("font_size", 16)
		container.add_child(row)

func _show_edit_result_screen(home: GuildHome):
	# バトル後のアイテム・装備品確認
	home.narration_label.visible = false
	home.nav_row.visible = false
	home.encounter_portrait.visible = false
	home.encounter_speaker.visible = false
	home.encounter_right.visible = false
	home.narration_band.visible = true

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(500, 450)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "バトル結果 — アイテム確認"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# カード内訳
	var card_title := Label.new()
	card_title.text = "【カード: %d枚】" % GameState.inventory.size()
	card_title.add_theme_font_size_override("font_size", 20)
	card_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(card_title)
	var card_counts := {}
	for card: Card in GameState.inventory:
		var key := "%s_%d" % [card.hand, card.grade]
		card_counts[key] = card_counts.get(key, 0) + 1
	var sorted_keys := card_counts.keys()
	sorted_keys.sort()
	for key in sorted_keys:
		var parts: PackedStringArray = key.split("_")
		vbox.add_child(GameState.create_card_label(parts[0], int(parts[1]), card_counts[key], 16, 22))

	# ゴールド
	vbox.add_child(GameState.create_gold_label(GameState.money, 20, 26, "所持金: "))

	# 装備品
	var equip_label := Label.new()
	equip_label.text = "【装備品】"
	equip_label.add_theme_font_size_override("font_size", 20)
	equip_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(equip_label)
	for eq in GameState.equipment:
		vbox.add_child(GameState.create_item_label(eq.get("name", eq.id), 1, 16, 22))
	if GameState.equipment.is_empty():
		var empty := Label.new()
		empty.text = "  なし"
		empty.add_theme_font_size_override("font_size", 16)
		vbox.add_child(empty)

	# アイテム残数
	var item_label := Label.new()
	item_label.text = "【アイテム残数】"
	item_label.add_theme_font_size_override("font_size", 20)
	item_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(item_label)
	for item in GameState.items:
		vbox.add_child(GameState.create_item_label(item.get("name", item.id), item.get("count", 1), 16, 22))
	if GameState.items.is_empty():
		var empty := Label.new()
		empty.text = "  なし"
		empty.add_theme_font_size_override("font_size", 16)
		vbox.add_child(empty)

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): _edit_setup_done.emit())
	vbox.add_child(close_btn)

	await _edit_setup_done
	panel.queue_free()

func _create_edit_overlay(encounter_data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.70
	panel.anchor_right = 0.99
	panel.anchor_top = 0.02
	panel.anchor_bottom = 0.55
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "編集: %s" % encounter_data.get("name", "")
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	vbox.add_child(title)

	# ナビゲーション行: 表示中のキャラ枠 (left/center/right) を切替
	var nav_row := HBoxContainer.new()
	nav_row.name = "NavRow"
	nav_row.add_theme_constant_override("separation", 4)
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(nav_row)

	var prev_btn := Button.new()
	prev_btn.name = "PrevBtn"
	prev_btn.text = "◀ 戻る"
	prev_btn.tooltip_text = "前の画像へ（set_portrait 履歴を1つ戻る）"
	prev_btn.add_theme_font_size_override("font_size", 16)
	prev_btn.custom_minimum_size = Vector2(64, 36)
	nav_row.add_child(prev_btn)

	var target_label := Label.new()
	target_label.name = "TargetLabel"
	target_label.text = "(待機中)"
	target_label.add_theme_font_size_override("font_size", 13)
	target_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	target_label.custom_minimum_size = Vector2(140, 0)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_row.add_child(target_label)

	var next_btn := Button.new()
	next_btn.name = "NextBtn"
	next_btn.text = "次へ ▶"
	next_btn.tooltip_text = "次の画像へ（履歴の先頭ならバトルを1手進めて新規生成）"
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.custom_minimum_size = Vector2(64, 36)
	nav_row.add_child(next_btn)

	# スケール
	var scale_row := _create_slider_row("スケール", "ScaleSlider", 0.1, 1.5, 0.01, 0.4, "%.2f")
	vbox.add_child(scale_row)
	var scale_slider: HSlider = scale_row.get_node("ScaleSlider")

	# X位置
	var x_row := _create_slider_row("X", "XSlider", -500, 500, 1, 0, "%d")
	vbox.add_child(x_row)
	var x_slider: HSlider = x_row.get_node("XSlider")

	# Y位置
	var y_row := _create_slider_row("Y", "YSlider", -600, 300, 1, -199, "%d")
	vbox.add_child(y_row)
	var y_slider: HSlider = y_row.get_node("YSlider")

	# 現在の値表示
	var info := Label.new()
	info.name = "InfoLabel"
	info.text = "スライダーで調整 → 即反映"
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(info)

	# アクション行（コピー / 保存 / 戻る）
	var action_row := HBoxContainer.new()
	action_row.name = "ActionRow"
	action_row.add_theme_constant_override("separation", 4)
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(action_row)

	# コピーボタン
	var copy_btn := Button.new()
	copy_btn.name = "CopyBtn"
	copy_btn.text = "コピー"
	copy_btn.add_theme_font_size_override("font_size", 14)
	copy_btn.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	copy_btn.pressed.connect(func():
		var s: float = scale_slider.value
		var x: int = int(x_slider.value)
		var y: int = int(y_slider.value)
		var text: String = '"scale": %.2f, "side": "center", "position": [%d, %d],' % [s, x, y]
		DisplayServer.clipboard_set(text)
		info.text = "コピーしました！"
	)
	action_row.add_child(copy_btn)

	# 保存ボタン（バトル編集モード用。chapter_path meta が設定されている時のみ動作）
	var save_btn := Button.new()
	save_btn.name = "EditSaveButton"
	save_btn.text = "保存"
	save_btn.add_theme_font_size_override("font_size", 14)
	save_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	save_btn.tooltip_text = "編集中の立ち絵1箇所を保存（呼び出し位置を特定して更新）"
	save_btn.pressed.connect(func():
		_save_battle_edit(panel, info))
	action_row.add_child(save_btn)

	# 戻るボタン（編集メニューに戻る）
	var back_btn := Button.new()
	back_btn.name = "EditBackButton"
	back_btn.text = "← 戻る"
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	action_row.add_child(back_btn)

	return panel

func _create_slider_row(label_text: String, slider_name: String, min_val: float, max_val: float, step_val: float, default_val: float, _fmt: String = "") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.custom_minimum_size = Vector2(55, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.name = slider_name
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step_val
	slider.value = default_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 20)
	row.add_child(slider)

	var spin := SpinBox.new()
	spin.name = slider_name + "Spin"
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step_val
	spin.value = default_val
	spin.custom_minimum_size = Vector2(70, 0)
	spin.add_theme_font_size_override("font_size", 12)
	row.add_child(spin)

	# スライダーとスピンボックスを双方向連携（ループ防止）
	var updating := [false]
	slider.value_changed.connect(func(v: float):
		if updating[0]:
			return
		updating[0] = true
		if is_instance_valid(spin):
			spin.value = v
		updating[0] = false)
	spin.value_changed.connect(func(v: float):
		if updating[0]:
			return
		updating[0] = true
		if is_instance_valid(slider):
			slider.value = v
		updating[0] = false)

	return row

var _edit_target_rect: TextureRect = null

func _get_edit_sliders(edit_panel: PanelContainer) -> Dictionary:
	var vbox: VBoxContainer = edit_panel.get_child(0)
	return {
		"scale": vbox.find_child("ScaleSlider", true, false) as HSlider,
		"scale_spin": vbox.find_child("ScaleSliderSpin", true, false) as SpinBox,
		"x": vbox.find_child("XSlider", true, false) as HSlider,
		"x_spin": vbox.find_child("XSliderSpin", true, false) as SpinBox,
		"y": vbox.find_child("YSlider", true, false) as HSlider,
		"y_spin": vbox.find_child("YSliderSpin", true, false) as SpinBox,
	}

func _set_slider_range(slider: HSlider, spin: SpinBox, min_v: float, max_v: float, step_v: float, val: float):
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = val
	if spin:
		spin.min_value = min_v
		spin.max_value = max_v
		spin.step = step_v
		spin.value = val

func _connect_edit_to_portrait(edit_panel: PanelContainer, portrait: TextureRect, encounter_data: Dictionary = {}):
	_edit_target_rect = portrait
	var sl := _get_edit_sliders(edit_panel)
	# エンカウントデータからポートレート設定を読む
	var portrait_data: Dictionary = EncounterDatabase.get_portrait(encounter_data, "encounter")
	var init_scale: float = portrait_data.get("scale", 0.5)
	var init_pos = portrait_data.get("position", [0, 0])
	var init_x: float = init_pos[0] if init_pos is Array and init_pos.size() >= 2 else 0.0
	var init_y: float = init_pos[1] if init_pos is Array and init_pos.size() >= 2 else 0.0
	_set_slider_range(sl.scale, sl.scale_spin, 0.1, 1.5, 0.01, init_scale)
	_set_slider_range(sl.x, sl.x_spin, -500, 500, 1, init_x)
	_set_slider_range(sl.y, sl.y_spin, -600, 300, 1, init_y)
	sl.scale.value_changed.connect(_on_portrait_slider.bind(sl, portrait))
	sl.x.value_changed.connect(_on_portrait_slider.bind(sl, portrait))
	sl.y.value_changed.connect(_on_portrait_slider.bind(sl, portrait))

func _on_portrait_slider(_value: float, sl: Dictionary, portrait: TextureRect):
	print("[EDIT-PORTRAIT] slider changed. portrait valid=%s has_tex=%s" % [str(is_instance_valid(portrait)), str(portrait.texture != null) if is_instance_valid(portrait) else "N/A"])
	if not is_instance_valid(portrait) or not portrait.texture:
		return
	var s: float = sl.scale.value
	var offset_x: float = sl.x.value
	var offset_y: float = sl.y.value
	var tex_size: Vector2 = portrait.texture.get_size()
	portrait.size = tex_size
	portrait.scale = Vector2(s, s)
	var vp_size: Vector2 = get_viewport_rect().size
	var visual_w: float = tex_size.x * s
	var visual_h: float = tex_size.y * s
	portrait.position.x = (vp_size.x - visual_w) / 2.0 + offset_x
	portrait.position.y = vp_size.y - visual_h + offset_y
	# ラベル更新
	var row_parent = sl.scale.get_parent().get_parent()
	var info: Label = row_parent.find_child("InfoLabel", true, false)
	if info:
		info.text = '"scale": %.2f, "position": [%d, %d]' % [s, int(offset_x), int(offset_y)]

var _battle_edit_sl: Dictionary = {}
var _battle_edit_ref = null
var _battle_edit_last_tex: Texture2D = null
var _battle_edit_active := false
var _battle_edit_target_rect: TextureRect = null
var _battle_edit_panel: PanelContainer = null
var _battle_edit_click_count: int = 0
var _battle_edit_advancing: bool = false
# 画像履歴は StoryScene.portrait_log（set_portrait / appear 呼び出しごとに記録）を参照。
# _battle_edit_history_idx はその log への現在位置。
var _battle_edit_history_idx: int = -1
# 直近に観測した portrait_log のサイズ。ライブのバトルが自走して
# 立ち絵を追加したことを _process で検知し、history_idx を追従させるために使う。
var _battle_edit_last_log_size: int = 0

# battle の StoryScene.portrait_log を返す
func _battle_edit_get_log() -> Array:
	if not is_instance_valid(_battle_edit_ref):
		return []
	var sc = _battle_edit_ref._story_scene if "_story_scene" in _battle_edit_ref else null
	if sc == null or not ("portrait_log" in sc):
		return []
	return sc.portrait_log

func _battle_edit_restore_portrait(snap: Dictionary):
	var rect: TextureRect = snap.get("rect")
	if rect == null or not is_instance_valid(rect):
		return
	var tex: Texture2D = snap.get("texture")
	rect.texture = tex
	# _show_character / _reset_rect_with_scale と同じく size・pivot を作り直す
	rect.pivot_offset = Vector2.ZERO
	if tex:
		rect.size = tex.get_size()
	rect.flip_h = snap.get("flip_h", false)
	var s: float = snap.get("scale", 1.0)
	rect.scale = Vector2(s, s)
	rect.position = snap.get("position", Vector2.ZERO)
	rect.visible = true
	rect.modulate = Color.WHITE
	# その立ち絵が表示された時点の背景・セリフ帯へ戻す
	var sc = _battle_edit_ref._story_scene if is_instance_valid(_battle_edit_ref) and "_story_scene" in _battle_edit_ref else null
	if sc:
		# StoryScene._process が毎フレーム _char_locked_positions へ位置を戻すため、
		# ロック位置も更新しないと復元位置が次フレームで巻き戻る（横ずれの原因）
		if "_char_locked_positions" in sc:
			sc._char_locked_positions[rect] = rect.position
		if sc.has_method("restore_background"):
			sc.restore_background(snap.get("background"))
		if sc.has_method("restore_dialogue"):
			sc.restore_dialogue(snap.get("dialogue"))
	print("[BATTLE_EDIT] restore: tex=%s size=%s scale=%.3f pos=%s flip=%s" % [
		(tex.resource_path if tex else "null"), rect.size, s, rect.position, rect.flip_h])
	_battle_edit_last_tex = rect.texture
	_battle_edit_target_rect = rect
	_battle_edit_sync_sliders(rect)

# ▶ でバトルを進めた直後用: バトルが実際に表示している立ち絵に対象を合わせ、
# スライダーを同期する（テクスチャ等はバトル側が正しく描画済みなので触らない）。
func _battle_edit_sync_to_live():
	if not is_instance_valid(_battle_edit_ref):
		return
	var sc = _battle_edit_ref._story_scene if "_story_scene" in _battle_edit_ref else null
	if sc == null:
		return
	var rect: TextureRect = _find_visible_char_rect(sc)
	if rect == null:
		return
	_battle_edit_last_tex = rect.texture
	_battle_edit_target_rect = rect
	_battle_edit_sync_sliders(rect)

# rect の現在値をスライダー/SpinBox に反映（_process の検知部から抽出）
func _battle_edit_sync_sliders(rect: TextureRect):
	if _battle_edit_sl.is_empty() or rect == null or rect.texture == null:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var tex_size: Vector2 = rect.texture.get_size()
	var s: float = rect.scale.x
	var visual_w: float = tex_size.x * s
	var visual_h: float = tex_size.y * s
	var offset_x: float = rect.position.x - (vp_size.x - visual_w) / 2.0
	var offset_y: float = rect.position.y - (vp_size.y - visual_h)
	for key in ["scale", "x", "y"]:
		if _battle_edit_sl.has(key) and _battle_edit_sl[key]:
			_battle_edit_sl[key].set_block_signals(true)
	if _battle_edit_sl.get("scale_spin"): _battle_edit_sl.scale_spin.set_block_signals(true)
	if _battle_edit_sl.get("x_spin"): _battle_edit_sl.x_spin.set_block_signals(true)
	if _battle_edit_sl.get("y_spin"): _battle_edit_sl.y_spin.set_block_signals(true)
	_set_slider_range(_battle_edit_sl.scale, _battle_edit_sl.get("scale_spin"), 0.1, 1.5, 0.01, s)
	_set_slider_range(_battle_edit_sl.x, _battle_edit_sl.get("x_spin"), -500, 500, 1, offset_x)
	_set_slider_range(_battle_edit_sl.y, _battle_edit_sl.get("y_spin"), -600, 300, 1, offset_y)
	for key in ["scale", "x", "y"]:
		if _battle_edit_sl.has(key) and _battle_edit_sl[key]:
			_battle_edit_sl[key].set_block_signals(false)
	if _battle_edit_sl.get("scale_spin"): _battle_edit_sl.scale_spin.set_block_signals(false)
	if _battle_edit_sl.get("x_spin"): _battle_edit_sl.x_spin.set_block_signals(false)
	if _battle_edit_sl.get("y_spin"): _battle_edit_sl.y_spin.set_block_signals(false)

func _battle_edit_visible_rects(battle_ref) -> Array:
	if not is_instance_valid(battle_ref):
		return []
	var story_sc = battle_ref._story_scene
	if not story_sc:
		return []
	var rects: Array = []
	for r in [story_sc.left_char, story_sc.center_char, story_sc.right_char]:
		if r and r.visible and r.texture:
			rects.append(r)
	return rects

func _battle_edit_rect_label(battle_ref, rect: TextureRect) -> String:
	if rect == null or not is_instance_valid(battle_ref):
		return "(none)"
	var story_sc = battle_ref._story_scene
	if not story_sc:
		return "(none)"
	if rect == story_sc.left_char: return "LEFT"
	if rect == story_sc.center_char: return "CENTER"
	if rect == story_sc.right_char: return "RIGHT"
	return "(?)"

func _battle_edit_update_target_label():
	if _battle_edit_panel == null or not is_instance_valid(_battle_edit_panel):
		return
	var lbl: Label = _battle_edit_panel.find_child("TargetLabel", true, false)
	if lbl == null:
		return
	if _battle_edit_target_rect == null or not is_instance_valid(_battle_edit_target_rect):
		lbl.text = "(対象未選択)"
		return
	var name := _battle_edit_rect_label(_battle_edit_ref, _battle_edit_target_rect)
	lbl.text = "対象: %s" % name

func _battle_edit_cycle_target(dir: int):
	# 画像履歴ナビゲーション:
	#   ◀: 履歴を1つ前の画像へ
	#   ▶: 履歴を1つ次の画像へ。末尾にいる場合はバトルを1手進めて新しい画像を生成
	if _battle_edit_advancing:
		return
	_battle_edit_advancing = true
	await _battle_edit_handle_nav(dir)
	_battle_edit_advancing = false

func _battle_edit_handle_nav(dir: int):
	_battle_edit_click_count += 1
	var lbl: Label = _battle_edit_panel.find_child("TargetLabel", true, false) if _battle_edit_panel else null
	var log := _battle_edit_get_log()
	var total := log.size()
	# idx == -1 はライブ状態（=末尾 total-1 を表示中）とみなす
	var cur := _battle_edit_history_idx
	if cur < 0:
		cur = total - 1
	print("[BATTLE_EDIT] nav dir=%d idx=%d(cur=%d)/%d" % [dir, _battle_edit_history_idx, cur, total])
	if total == 0:
		if lbl:
			lbl.text = "（画像履歴なし）"
			_battle_edit_flash_label(lbl)
		return
	if dir < 0:
		# ◀ 前の画像へ
		if cur > 0:
			_battle_edit_history_idx = cur - 1
			_battle_edit_restore_portrait(log[_battle_edit_history_idx])
			if lbl:
				lbl.text = "◀ 画像 %d/%d" % [_battle_edit_history_idx + 1, total]
				_battle_edit_flash_label(lbl)
		else:
			_battle_edit_history_idx = 0
			if lbl:
				lbl.text = "◀ 先頭です (1/%d)" % total
				_battle_edit_flash_label(lbl)
	else:
		# ▶ 次の画像へ
		if cur < total - 1:
			_battle_edit_history_idx = cur + 1
			_battle_edit_restore_portrait(log[_battle_edit_history_idx])
			if lbl:
				lbl.text = "▶ 画像 %d/%d" % [_battle_edit_history_idx + 1, total]
				_battle_edit_flash_label(lbl)
		else:
			# 末尾。立ち絵は編集モード開始時に全てキャプチャ済みのため、
			# バトルを進める処理は行わず即座に末尾である旨を表示する。
			if lbl:
				if total <= 1:
					lbl.text = "この章の立ち絵は1枚です"
				else:
					lbl.text = "▶ 末尾です (%d枚)" % total
				_battle_edit_flash_label(lbl)

# バトルを1手進める。戻り値:
#   "advanced"      … 進行した
#   "blocked_match" … カード選択待ち。ユーザーが結果強制ボタン＋カードで勝負する必要あり
#   "done"          … バトル参照が無効
func _battle_edit_advance_state() -> String:
	if not is_instance_valid(_battle_edit_ref):
		return "done"
	var battle = _battle_edit_ref
	# デッキ構築中ならおまかせ編成して確定
	if "_deck_building" in battle and battle._deck_building:
		print("[BATTLE_EDIT] advance: auto-build deck + confirm")
		if battle.has_method("_on_auto_pressed"):
			battle._on_auto_pressed()
		await get_tree().process_frame
		if battle.has_method("_on_confirm_pressed"):
			battle._on_confirm_pressed()
		await get_tree().process_frame
		return "advanced"
	# ダイアログ進行中なら band を進める
	var sc = battle._story_scene if "_story_scene" in battle else null
	if sc and "_waiting_for_input" in sc and sc._waiting_for_input:
		print("[BATTLE_EDIT] advance: dialogue band")
		if sc.has_method("_trigger_advance"):
			sc._trigger_advance()
		await get_tree().process_frame
		return "advanced"
	# カード選択待ち
	if "action_prompt" in battle and battle.action_prompt and battle.action_prompt.visible:
		# select_hand 中（結果強制ボタンが出ている）はユーザーに勝負させる。
		# 自動解決すると select_hand の await を満たせずバトルが停止するため進めない。
		var has_force_btns: bool = "_force_result_container" in battle \
			and battle._force_result_container != null \
			and is_instance_valid(battle._force_result_container)
		if has_force_btns:
			print("[BATTLE_EDIT] advance: blocked — 勝負待ち")
			return "blocked_match"
		# force_select_hand（チュートリアル等の自動選択）は自動完了するので待つだけ
		print("[BATTLE_EDIT] advance: wait auto card-select")
		await get_tree().process_frame
		return "advanced"
	# それ以外は ui_accept を擬似発火
	print("[BATTLE_EDIT] advance: send ui_accept")
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	return "advanced"

# クリック時の視認性向上: ラベルを一瞬黄→緑→白で色変化させる
func _battle_edit_flash_label(lbl: Label):
	if not is_instance_valid(lbl):
		return
	lbl.modulate = Color(1.0, 1.0, 0.3)
	var tween := create_tween()
	tween.tween_property(lbl, "modulate", Color.WHITE, 0.4)

func _connect_edit_to_battle(edit_panel: PanelContainer, battle_ref, encounter_data: Dictionary = {}):
	var sl := _get_edit_sliders(edit_panel)
	var portrait_data: Dictionary = EncounterDatabase.get_portrait(encounter_data, "battle")
	var init_scale: float = portrait_data.get("scale", 0.4)
	var init_pos = portrait_data.get("position", [0, -199])
	var init_x: float = init_pos[0] if init_pos is Array and init_pos.size() >= 2 else 0.0
	var init_y: float = init_pos[1] if init_pos is Array and init_pos.size() >= 2 else -199.0
	_set_slider_range(sl.scale, sl.scale_spin, 0.1, 1.5, 0.01, init_scale)
	_set_slider_range(sl.x, sl.x_spin, -500, 500, 1, init_x)
	_set_slider_range(sl.y, sl.y_spin, -600, 300, 1, init_y)
	sl.scale.value_changed.connect(_on_battle_slider.bind(sl, battle_ref))
	sl.x.value_changed.connect(_on_battle_slider.bind(sl, battle_ref))
	sl.y.value_changed.connect(_on_battle_slider.bind(sl, battle_ref))
	# 画像変更検知用
	_battle_edit_sl = sl
	_battle_edit_ref = battle_ref
	_battle_edit_last_tex = null
	_battle_edit_active = true
	_battle_edit_target_rect = null
	_battle_edit_panel = edit_panel
	_battle_edit_click_count = 0
	_battle_edit_history_idx = -1
	_battle_edit_last_log_size = 0
	# battle 内 StoryScene の立ち絵履歴を有効化（set_portrait/appear ごとに記録される）
	var bsc = battle_ref._story_scene if "_story_scene" in battle_ref else null
	if bsc and "portrait_log_enabled" in bsc:
		bsc.portrait_log_enabled = true
		_battle_edit_last_log_size = bsc.portrait_log.size()
		print("[BATTLE_EDIT] portrait_log enabled (size=%d)" % bsc.portrait_log.size())
	else:
		print("[BATTLE_EDIT] WARN: could not enable portrait_log (bsc=%s)" % bsc)
	# ナビゲーション: ◀ / ▶ で画像履歴を行き来
	var prev_btn: Button = edit_panel.find_child("PrevBtn", true, false)
	var next_btn: Button = edit_panel.find_child("NextBtn", true, false)
	print("[BATTLE_EDIT] _connect_edit_to_battle: prev_btn=%s next_btn=%s" % [prev_btn, next_btn])
	if prev_btn:
		prev_btn.pressed.connect(_battle_edit_cycle_target.bind(-1))
		print("[BATTLE_EDIT]   prev_btn.pressed connected")
	if next_btn:
		next_btn.pressed.connect(_battle_edit_cycle_target.bind(1))
		print("[BATTLE_EDIT]   next_btn.pressed connected")
	_battle_edit_update_target_label()
	# 立ち絵キャプチャ直後の center_char は最後の立ち絵を映しているため、
	# 編集開始時は履歴の先頭（最初の立ち絵 = 勝負前）へ戻して表示する。
	if bsc and "portrait_log" in bsc and not bsc.portrait_log.is_empty():
		_battle_edit_history_idx = 0
		_battle_edit_restore_portrait(bsc.portrait_log[0])
		print("[BATTLE_EDIT] reset to first portrait (#0 of %d)" % bsc.portrait_log.size())

func _process(_delta: float):
	if not _battle_edit_active:
		return
	if not is_instance_valid(_battle_edit_ref):
		_battle_edit_active = false
		_battle_edit_target_rect = null
		_battle_edit_panel = null
		return
	# 対象未選択かつ表示中の rect があれば自動セット
	if _battle_edit_target_rect == null or not is_instance_valid(_battle_edit_target_rect) or not _battle_edit_target_rect.visible:
		var rects := _battle_edit_visible_rects(_battle_edit_ref)
		if not rects.is_empty():
			_battle_edit_target_rect = rects[0]
			_battle_edit_update_target_label()
	var story_sc = _battle_edit_ref._story_scene
	if not story_sc:
		return
	# ライブのバトルが自走して新しい立ち絵を表示した場合、portrait_log は ◀/▶ を
	# 介さず増える。このとき「ユーザーが今ライブの末尾画像を見ている」ときだけ
	# 増えた末尾へ追従する。◀ で古い画像に停車中（history_idx < 末尾）のときに
	# 末尾へ飛ばすと、画面の画像と保存対象（history_idx → edit_source_id）がズレて
	# 編集したのと別（次）の set_portrait 行が書き換わるため、追従しない。
	var log_size: int = story_sc.portrait_log.size() if "portrait_log" in story_sc else 0
	if log_size > _battle_edit_last_log_size:
		var prev_tail: int = _battle_edit_last_log_size - 1
		if _battle_edit_history_idx < 0 or _battle_edit_history_idx == prev_tail:
			_battle_edit_history_idx = log_size - 1
	_battle_edit_last_log_size = log_size
	var char_rect: TextureRect = _find_visible_char_rect(story_sc)
	if not char_rect:
		return
	# 画像が変わったらスライダー更新（履歴は StoryScene.portrait_log が担当）
	if char_rect.texture != _battle_edit_last_tex:
		_battle_edit_last_tex = char_rect.texture
		_battle_edit_sync_sliders(char_rect)

func _find_visible_char_rect(story_sc) -> TextureRect:
	# 編集モードでナビゲーションで選択中の rect を優先
	if _battle_edit_target_rect and is_instance_valid(_battle_edit_target_rect) and _battle_edit_target_rect.visible and _battle_edit_target_rect.texture:
		# 同じ story_sc 配下か確認
		var owner_sc = _battle_edit_target_rect.get_parent()
		if owner_sc == story_sc:
			return _battle_edit_target_rect
	for rect in [story_sc.center_char, story_sc.left_char, story_sc.right_char]:
		if rect and rect.visible and rect.texture:
			return rect
	return null

func _on_battle_slider(_value: float, sl: Dictionary, battle_ref):
	if not is_instance_valid(battle_ref):
		return
	var story_sc = battle_ref._story_scene
	if not story_sc:
		return
	var char_rect: TextureRect = _find_visible_char_rect(story_sc)
	if not char_rect:
		return
	var s: float = sl.scale.value
	var tex_size: Vector2 = char_rect.texture.get_size()
	char_rect.size = tex_size
	char_rect.scale = Vector2(s, s)
	var vp_size: Vector2 = get_viewport_rect().size
	var visual_w: float = tex_size.x * s
	var visual_h: float = tex_size.y * s
	var new_pos := Vector2(
		(vp_size.x - visual_w) / 2.0 + sl.x.value,
		vp_size.y - visual_h + sl.y.value
	)
	char_rect.position = new_pos
	if story_sc._char_locked_positions.has(char_rect):
		story_sc._char_locked_positions[char_rect] = new_pos
	# スライダー編集を立ち絵履歴へ反映（◀/▶ で戻っても編集が保持されるように）。
	# 書き込み先は「いま復元・表示しているエントリ」= _battle_edit_history_idx に
	# 一本化する。texture はチャプター内で複数の set_portrait が同一画像を使うため
	# 識別子に使えない（同画像の最後の出現を拾って別行を壊す原因になる）。
	var elog := _battle_edit_get_log()
	var ei := _battle_edit_history_idx
	if ei < 0:
		ei = elog.size() - 1
	if ei >= 0 and ei < elog.size() and elog[ei].get("rect") == char_rect:
		elog[ei]["scale"] = s
		elog[ei]["position"] = new_pos
	var row_parent2 = sl.scale.get_parent().get_parent()
	var info: Label = row_parent2.find_child("InfoLabel", true, false)
	if info:
		info.text = '"scale": %.2f, "position": [%d, %d]' % [s, int(sl.x.value), int(sl.y.value)]

func _create_story_scene():
	story_scene_instance = story_scene_scene.instantiate()
	add_child(story_scene_instance)
	story_scene_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if background_rect and background_rect.get_parent() == self:
		var insert_index = background_rect.get_index() + 1
		move_child(story_scene_instance, insert_index)
	else:
		move_child(story_scene_instance, 0)
	story_script = DefaultStoryScript.new()
	story_scene_instance.set_cast(story_script.get_cast())
	story_scene_instance.sequence_started.connect(_on_story_sequence_started)
	story_scene_instance.sequence_finished.connect(_on_story_sequence_finished)
	story_scene_instance.battle_requested.connect(_on_battle_requested)

# --- SCENARIO & STAGES ---

var _scenario_order: Array = [
	{"id": "prologue", "battle_win": "prologue_battle_win", "battle_lose": "prologue_battle_lose"},
	{"id": "stage1", "battle_win": "stage1_battle_win", "battle_lose": "stage1_battle_lose"},
]

func scenario():
	await _run_scenario_from(0, "")

func scenario_from(sequence_id: String, label_name: String = ""):
	for i in range(_scenario_order.size()):
		if _scenario_order[i].id == sequence_id:
			await _run_scenario_from(i, label_name)
			return
	# Sequence is not in the main scenario_order (e.g., stage2-7 standalone parts).
	# Play it as a single scene rather than restarting from prologue.
	if not label_name.is_empty() and label_name != sequence_id:
		await _play_scene_from(sequence_id, label_name)
	else:
		await _play_scene(sequence_id)

func _run_scenario_from(start_index: int, label_name: String):
	for i in range(start_index, _scenario_order.size()):
		var entry: Dictionary = _scenario_order[i]
		var seq_id: String = entry.id
		GameState.chapter = seq_id
		if not label_name.is_empty():
			GameState.label = label_name
			await _play_scene_from(seq_id, label_name)
			label_name = ""
		else:
			GameState.label = ""
			await _play_scene(seq_id)
		await _handle_battle_aftermath(entry, i)
	await _show_guild_home()

func _handle_battle_aftermath(entry: Dictionary, scene_index: int):
	if GameState.last_battle_result.is_empty():
		return
	var result: String = GameState.last_battle_result
	GameState.last_battle_result = ""
	var win_seq_id: String = entry.get("battle_win", "")
	var lose_seq_id: String = entry.get("battle_lose", "")
	if result == "win" and not win_seq_id.is_empty():
		await _play_scene(win_seq_id)
	elif result == "lose" and not lose_seq_id.is_empty():
		await _play_scene(lose_seq_id)
	story_scene_instance.visible = false
	var choice: String = await _show_battle_result_screen(result)
	story_scene_instance.visible = true
	if choice == "retry":
		GameState.last_battle_result = ""
		await _play_scene_from(entry.id, "battle_start")
		await _handle_battle_aftermath(entry, scene_index)

func _play_scene(sequence_key):
	var seq = story_script.get_sequence(sequence_key)
	if seq:
		await story_scene_instance.play_sequence(seq, {"id": sequence_key})

func _play_scene_from(sequence_key: String, label_name: String):
	var seq = story_script.get_sequence(sequence_key)
	if seq:
		await story_scene_instance.play_sequence(seq, {"id": sequence_key, "skip_to": label_name})

func _on_story_sequence_started(_sequence_id):
	is_dialogue_active = true

func _on_story_sequence_finished(_sequence_id):
	is_dialogue_active = false

# --- Battle bridge ---

func _on_battle_requested(cmd):
	# chapter_path からチャプターをロード（b.battle() で path のみ指定の場合）
	if cmd.chapter == null and not cmd.chapter_path.is_empty():
		var script = load(cmd.chapter_path)
		if script:
			cmd.chapter = script.new()
	if cmd.chapter == null:
		story_scene_instance.complete_battle("win")
		return

	if cmd.is_minigame:
		story_scene_instance.visible = false
		var mg_battle = battle_scene_scene.instantiate()
		add_child(mg_battle)
		mg_battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mg_battle.setup(story_script.get_cast(), story_scene_instance.background_rect.texture, GameState.inventory)
		mg_battle.start_battle(cmd.chapter, false, true)
		var mg_result: String = await mg_battle.battle_finished
		mg_battle.queue_free()
		story_scene_instance.visible = true
		cmd.result = mg_result
		story_scene_instance.complete_battle(mg_result)
		return

	if cmd.is_tutorial:
		story_scene_instance.visible = false
		var tut_battle = battle_scene_scene.instantiate()
		add_child(tut_battle)
		tut_battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tut_battle.setup(story_script.get_cast(), story_scene_instance.background_rect.texture, GameState.inventory)
		tut_battle.start_battle(cmd.chapter, true)
		var tut_result: String = await tut_battle.battle_finished
		var tut_rewards = tut_battle.get_battle_rewards()
		if tut_result == "win":
			if cmd.chapter.can_gain_cards():
				for card in tut_rewards.captured_by_player:
					GameState.add_card(card)
			var gold: int = tut_battle.get_rolled_gold()
			if gold > 0:
				GameState.money += gold
		elif tut_result == "lose":
			if cmd.chapter.can_lose_cards():
				for card in tut_rewards.captured_by_opponent:
					GameState.remove_card(card)
			var lost_gold: int = tut_battle.get_lost_gold()
			if lost_gold > 0:
				GameState.money = max(GameState.money - lost_gold, 0)
		tut_battle.queue_free()
		story_scene_instance.visible = true
		story_scene_instance.complete_battle("win")
		return

	var bg_tex: Texture2D = story_scene_instance.background_rect.texture
	story_scene_instance.visible = false
	var lose_behavior: String = cmd.chapter.get_lose_behavior()
	var final_result := "win"

	while true:
		# バトル実行
		var battle_result: Dictionary = await _execute_battle(cmd.chapter, bg_tex)
		final_result = battle_result.result

		if final_result == "win":
			break

		# 負け → ストーリーシーンでfarewell表示
		await _show_battle_farewell_in_scene(cmd.chapter, final_result, bg_tex)

		# リダイレクト判定
		if lose_behavior == "redirect":
			var redirect: Dictionary = cmd.chapter.get_lose_redirect()
			var rtype: String = redirect.get("type", "")
			if rtype == "retry_scene":
				var choice: String = await _show_retry_scene(redirect)
				if choice == "retry":
					continue
				else:
					final_result = "lose"
					break
			elif rtype == "story_sequence":
				# ストーリーシーケンスを再生 → 選択肢
				story_scene_instance.visible = true
				await _play_scene(redirect.get("sequence_id", ""))
				var choice2: String = await _show_choice_overlay(redirect.get("choices", ["再挑戦する", "ホームに戻る"]))
				if choice2 == "retry":
					continue
				else:
					final_result = "lose"
					break
			elif rtype == "story_sequence_then_guild_home":
				# 章固有のロスト・ナレーションを先に再生 → 共通ロスト・ナレーション
				# → ギルドホーム送還（選択肢なし）
				story_scene_instance.visible = true
				var seq_id: String = redirect.get("sequence_id", "")
				if seq_id != "":
					await _play_scene(seq_id)
				if not _should_skip_common_lose_narration(cmd):
					await _play_common_lose_narration(cmd)
				final_result = "lose"
				break
			else:
				break
		elif lose_behavior == "abort":
			# farewell の後、共通ロスト・ナレーションを再生してから guild_home へ
			if not _should_skip_common_lose_narration(cmd):
				story_scene_instance.visible = true
				await _play_common_lose_narration(cmd)
			break
		else:
			break

	cmd.result = final_result
	GameState.last_battle_result = final_result
	story_scene_instance.visible = true
	if final_result == "lose" and lose_behavior != "continue":
		story_scene_instance._abort_sequence = true
	story_scene_instance.complete_battle(final_result)

# ---------------------------------------------------------------
# サトシ敗北時の共通ロスト・ナレーション挿入
# ---------------------------------------------------------------

func _should_skip_common_lose_narration(cmd) -> bool:
	# cmd.lose_patterns == ["__skip__"] なら明示的にスキップ
	var patterns = cmd.get("lose_patterns") if cmd.has_method("get") else []
	if patterns is Array and patterns.size() == 1 and String(patterns[0]) == "__skip__":
		return true
	return false

func _play_common_lose_narration(cmd) -> void:
	var SatoshiLoseNarrationsScript = load("res://battle/SatoshiLoseNarrations.gd")
	if SatoshiLoseNarrationsScript == null:
		push_warning("SatoshiLoseNarrations module not found")
		return
	var allowed: Array = cmd.lose_patterns if "lose_patterns" in cmd else []
	if allowed.is_empty():
		allowed = SatoshiLoseNarrationsScript.ALL_IDS
	var last_id: String = String(GameState.flags.get("last_lose_narration_id", ""))
	var pattern: Dictionary = SatoshiLoseNarrationsScript.pick_random(allowed, last_id)
	GameState.flags["last_lose_narration_id"] = pattern.get("id", "")

	var opponent_name: String = String(cmd.lose_opponent if "lose_opponent" in cmd else "")
	if opponent_name == "":
		opponent_name = cmd.chapter.get_opponent_name()
	if opponent_name == "":
		opponent_name = "相手"

	var rendered_frames: Array = SatoshiLoseNarrationsScript.render_frames(pattern, opponent_name)

	# 一時シーケンスを構築して StoryScene で再生
	var Cmd = load("res://story/StoryCommands.gd")
	var seq = Cmd.Sequence.new()
	seq.id = "_satoshi_lose_narration"
	for f in rendered_frames:
		var speaker: String = String(f[0])
		var text: String = String(f[1])
		var band = Cmd.Band.new()
		band.visible = true
		band.text = text
		band.speaker_id = speaker
		band.wait_for_input = true
		seq.entries.append(band)

	if story_scene_instance and story_scene_instance.has_method("play_sequence"):
		await story_scene_instance.play_sequence(seq)

	# outcome 適用：服を取られたパターンは服の買い直し費用を減算
	if pattern.get("outcome", "") == "lose_clothes":
		var cost: int = SatoshiLoseNarrationsScript.REPLACEMENT_COST
		GameState.money = max(0, GameState.money - cost)

# --- バトル実行共通関数 ---

func _execute_battle(chapter: BattleChapterBase, bg_tex: Texture2D) -> Dictionary:
	var battle_instance = battle_scene_scene.instantiate()
	add_child(battle_instance)
	battle_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_instance.setup(story_script.get_cast() if story_script else {}, bg_tex, GameState.inventory)
	battle_instance.start_battle(chapter)
	var result: String = await battle_instance.battle_finished

	var rewards = battle_instance.get_battle_rewards()
	if result == "win":
		if chapter.can_gain_cards():
			for card in rewards.captured_by_player:
				GameState.add_card(card)
		var gold: int = battle_instance.get_rolled_gold()
		if gold > 0:
			GameState.money += gold
	elif result == "lose":
		if chapter.can_lose_cards():
			for card in rewards.captured_by_opponent:
				GameState.remove_card(card)
		var lost_gold: int = battle_instance.get_lost_gold()
		if lost_gold > 0:
			GameState.money = max(GameState.money - lost_gold, 0)

	battle_instance.queue_free()
	return {"result": result, "rewards": rewards}

# --- バトル後 farewell 表示（ストーリーシーン内） ---

signal _farewell_dismissed

func _show_battle_farewell_in_scene(chapter: BattleChapterBase, result: String, bg_tex: Texture2D):
	var farewell: Dictionary = chapter.get_farewell(result)
	if farewell.is_empty():
		return

	var narration: String = farewell.get("narration", "")
	var portrait_path: String = farewell.get("portrait", "")
	var text: String = farewell.get("text", "")
	if narration.is_empty() and portrait_path.is_empty() and text.is_empty():
		return

	# ストーリーシーンを再表示
	story_scene_instance.visible = true
	if bg_tex:
		story_scene_instance.background_rect.texture = bg_tex
	story_scene_instance.left_char.visible = false
	story_scene_instance.center_char.visible = false
	story_scene_instance.right_char.visible = false

	var speaker_label: Label = story_scene_instance.dialogue_band.get_node("VBox/SpeakerLabel")
	var body_label: Label = story_scene_instance.dialogue_band.get_node("VBox/BodyLabel")

	# 1. ナレーション表示（キャラなし）
	if not narration.is_empty():
		story_scene_instance.dialogue_band.visible = true
		if speaker_label:
			speaker_label.text = ""
		if body_label:
			body_label.text = narration
		story_scene_instance._waiting_for_input = true
		await story_scene_instance.advance_requested
		story_scene_instance._waiting_for_input = false

	# 2. 敵キャラ表示 + セリフ
	if not portrait_path.is_empty() or not text.is_empty():
		if not portrait_path.is_empty():
			var tex = load(portrait_path)
			if tex:
				var s: float = farewell.get("portrait_scale", 0.5)
				story_scene_instance.right_char.texture = tex
				story_scene_instance.right_char.size = tex.get_size()
				story_scene_instance.right_char.scale = Vector2(s, s)
				var vp_size := get_viewport_rect().size
				var visual_w: float = tex.get_size().x * s
				var visual_h: float = tex.get_size().y * s
				story_scene_instance.right_char.position.x = vp_size.x - visual_w - 100
				story_scene_instance.right_char.position.y = vp_size.y - visual_h
				story_scene_instance.right_char.flip_h = false
				story_scene_instance.right_char.visible = true
				story_scene_instance._char_locked_positions[story_scene_instance.right_char] = story_scene_instance.right_char.position

		if not text.is_empty():
			var speaker_name: String = chapter.get_opponent_name()
			story_scene_instance.dialogue_band.visible = true
			if speaker_label:
				speaker_label.text = speaker_name
			if body_label:
				body_label.text = text

		story_scene_instance._waiting_for_input = true
		await story_scene_instance.advance_requested
		story_scene_instance._waiting_for_input = false

	# クリーンアップ
	story_scene_instance.right_char.visible = false
	story_scene_instance._char_locked_positions.erase(story_scene_instance.right_char)
	story_scene_instance.dialogue_band.visible = false
	story_scene_instance.visible = false

# --- リトライシーン（マチルダ戦用） ---

signal _retry_choice_made(choice: String)

func _show_retry_scene(redirect: Dictionary) -> String:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# 背景画像
	var bg_path: String = redirect.get("background", "")
	if not bg_path.is_empty():
		var bg_tex = load(bg_path)
		if bg_tex:
			var bg_rect := TextureRect.new()
			bg_rect.texture = bg_tex
			bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bg_rect.expand_mode = 1
			bg_rect.stretch_mode = 6
			bg_rect.modulate = Color(0.4, 0.4, 0.4)
			panel.add_child(bg_rect)
			panel.move_child(bg_rect, 0)

	# ポートレート（敵キャラなど）
	var portrait_path: String = redirect.get("portrait", "")
	if not portrait_path.is_empty():
		var portrait_tex = load(portrait_path)
		if portrait_tex:
			var portrait_rect := TextureRect.new()
			portrait_rect.texture = portrait_tex
			portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var ptw: float = portrait_tex.get_width()
			var pth: float = portrait_tex.get_height()
			var p_scale: float = redirect.get("portrait_scale", 0.6)
			portrait_rect.custom_minimum_size = Vector2(ptw * p_scale, pth * p_scale)
			portrait_rect.size = Vector2(ptw * p_scale, pth * p_scale)
			portrait_rect.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			portrait_rect.position = Vector2(-ptw * p_scale - 40, -pth * p_scale * 0.5)
			panel.add_child(portrait_rect)

	# ナレーション
	var narration: String = redirect.get("narration", "")
	if not narration.is_empty():
		var label := Label.new()
		label.text = narration
		label.add_theme_font_size_override("font_size", 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(label)

	# 選択肢ボタン
	var choices: Array = redirect.get("choices", ["再挑戦する", "ホームに戻る"])
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_row)

	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(200, 50)
		var choice_val: String = "retry" if i == 0 else "home"
		btn.pressed.connect(_on_retry_choice.bind(choice_val))
		btn_row.add_child(btn)

	var choice: String = await _retry_choice_made
	panel.queue_free()
	return choice

func _on_retry_choice(choice: String):
	_retry_choice_made.emit(choice)

# ストーリーシーン上に半透明の選択肢オーバーレイを表示
func _show_choice_overlay(choices: Array) -> String:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	panel.add_child(btn_row)

	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(220, 56)
		var choice_val: String = "retry" if i == 0 else "home"
		btn.pressed.connect(_on_retry_choice.bind(choice_val))
		btn_row.add_child(btn)

	var choice: String = await _retry_choice_made
	panel.queue_free()
	return choice

# --- Battle Result Screen ---

signal _result_choice_made(choice: String)

func _show_battle_result_screen(result: String) -> String:
	for child in result_buttons.get_children():
		child.queue_free()

	if result == "win":
		result_title.text = "勝利！"
		result_message.text = "見事な勝利です！次の章へ進みますか？"
		_add_result_button("次の章へ", "next")
		_add_result_button("タイトルに戻る", "title")
	elif result == "lose":
		result_title.text = "敗北..."
		result_message.text = "残念...再戦しますか？"
		_add_result_button("再戦する", "retry")
		_add_result_button("タイトルに戻る", "title")
	else:
		result_title.text = "引き分け"
		result_message.text = "決着がつきませんでした。"
		_add_result_button("再戦する", "retry")
		_add_result_button("タイトルに戻る", "title")

	battle_result_screen.visible = true
	var choice: String = await _result_choice_made
	battle_result_screen.visible = false
	return choice

func _add_result_button(text: String, choice: String):
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): _result_choice_made.emit(choice))
	result_buttons.add_child(btn)

# --- Guild Home ---

var _current_town_map: TownMapBase = null

func _show_guild_home():
	if story_scene_instance:
		story_scene_instance.visible = false
	if not _current_town_map:
		_current_town_map = Stage1TownMapScript.new()
	var home = guild_home_scene.instantiate()
	add_child(home)
	home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_tex = load(_current_town_map.get_home_background())
	home.setup(bg_tex, _current_town_map)
	home.battle_encounter.connect(_on_town_battle.bind(home))
	while true:
		var action: String = await home.home_action
		if action == "exit":
			home.queue_free()
			if story_scene_instance:
				story_scene_instance.queue_free()
				story_scene_instance = null
			title_menu.visible = true
			return
		elif action == "next_story":
			home.queue_free()
			if story_scene_instance:
				story_scene_instance.visible = true
			return
		elif action.begins_with("quest:"):
			var quest_id := action.trim_prefix("quest:")
			await _run_subevent(quest_id, home)

func _on_town_battle(area_id: String, chapter: BattleChapterBase, home: GuildHome):
	if not chapter:
		home.arrive_at(area_id)
		return
	home.visible = false
	var bg_tex = load(chapter.get_battle_background()) if not chapter.get_battle_background().is_empty() else null
	var battle_result: Dictionary = await _execute_battle(chapter, bg_tex)
	var result: String = battle_result.result
	home.visible = true

	# 去り際シーン（ランダムバトル用）
	if chapter.has_method("get_encounter_farewell"):
		var farewell_line: String = chapter.get_encounter_farewell(result)
		if not farewell_line.is_empty():
			var fw_key: String = "farewell_win" if result == "win" else "farewell_lose"
			var fw_portrait: Dictionary = EncounterDatabase.get_portrait(chapter._data, fw_key) if chapter.has_method("get_encounter_farewell_portrait") else {}
			var fw_path: String = fw_portrait.get("path", "")
			if not fw_path.is_empty():
				var fw_tex = load(fw_path)
				if fw_tex:
					home.encounter_portrait.texture = fw_tex
					home._apply_encounter_portrait(fw_tex, fw_portrait)
			home.encounter_portrait.visible = true
			home.narration_label.visible = false
			home.nav_row.visible = false
			home.encounter_speaker.text = chapter.get_opponent_name()
			home.encounter_speaker.visible = true
			home.encounter_body.text = farewell_line
			home.encounter_right.visible = true
			home.narration_band.visible = true
			home._waiting_for_click = true
			await home._click_received
			home._waiting_for_click = false
			home._hide_encounter()

	home.arrive_at(area_id)

# --- サブイベント実行 ---

const Subevent1ChapterScript := preload("res://story/chapters/Subevent1Chapter.gd")
const Subevent2ChapterScript := preload("res://story/chapters/Subevent2Chapter.gd")
var _subevent_in_progress := false

const SUBEVENT_CHAPTERS := {
	"subevent1": {
		"name": "盗賊団を解体せよ！",
		"chapter_script": "Subevent1ChapterScript",
		"pre_sequence_id": "subevent1_pre",
		"pre2_sequence_id": "subevent1_hideout",
		"post_sequence_id": "subevent1_post",
	},
	"subevent2": {
		"name": "教会の不正を暴け！",
		"chapter_script": "Subevent2ChapterScript",
		"pre_sequence_id": "subevent2_pre1",
		"pre2_sequence_id": "subevent2_pre2",
		"post_sequence_id": "subevent2_post",
		# 再受注時の短縮ルート: encounter_sister_long_seen フラグが立っていれば
		# pre1/pre2 をスキップしてこのシーケンスを再生（特別礼拝室直接潜入→対面→バトル）
		"rematch_sequence_id": "subevent2_rematch",
		"rematch_flag": "encounter_sister_long_seen",
	},
	"subevent3": {
		"name": "呪われた鎧を脱がせ！",
		"chapter_script": "Subevent3ChapterScript",
		"pre_sequence_id": "subevent3_pre",
		"pre2_sequence_id": "subevent3_blacksmith",
		"pre3_sequence_id": "subevent3_visit",
		"post_sequence_id": "subevent3_post",
	},
	"subevent4": {
		"name": "受付嬢を脱がせ！",
		"chapter_script": "Subevent4ChapterScript",
		"pre_sequence_id": "subevent4_pre",
		"post_sequence_id": "subevent4_post",
	},
}

func _ensure_subevent_registered(quest_id: String):
	if not story_script:
		story_script = DefaultStoryScript.new()
	if quest_id == "subevent1":
		if not story_script.get_sequence("subevent1_pre"):
			story_script._register_chapter(Subevent1ChapterScript.new())
	elif quest_id == "subevent2":
		if not story_script.get_sequence("subevent2_pre1"):
			story_script._register_chapter(Subevent2ChapterScript.new())
	# subevent3, subevent4 は DefaultStory._build_chapters で登録済み

func _run_subevent(quest_id: String, home: GuildHome):
	var quest_data: Dictionary = SUBEVENT_CHAPTERS.get(quest_id, {})
	if quest_data.is_empty():
		print("[QUEST] Unknown quest: ", quest_id)
		return

	var pre_id: String = quest_data.get("pre_sequence_id", "")
	if pre_id.is_empty():
		print("[QUEST] %s: ストーリー未実装" % quest_data.get("name", quest_id))
		return

	_ensure_subevent_registered(quest_id)

	# 再受注時の短縮ルート判定:
	# rematch_flag が立っていれば pre1/pre2 を飛ばして rematch_sequence_id へ
	var rematch_id: String = quest_data.get("rematch_sequence_id", "")
	var rematch_flag: String = quest_data.get("rematch_flag", "")
	var use_rematch: bool = (
		rematch_id != ""
		and rematch_flag != ""
		and GameState.flags.get(rematch_flag, false)
	)

	var pre_seq = null
	if use_rematch:
		pre_seq = story_script.get_sequence(rematch_id)
		if not pre_seq:
			# rematch シーケンスがなければ通常ルートに fallback
			print("[QUEST] Rematch sequence not found, using full pre: ", rematch_id)
			use_rematch = false
	if not use_rematch:
		pre_seq = story_script.get_sequence(pre_id)
	if not pre_seq:
		print("[QUEST] Sequence not found: ", pre_id)
		return

	# Hide home, show story scene
	home.visible = false
	_subevent_in_progress = true

	if not story_scene_instance:
		story_scene_instance = story_scene_scene.instantiate()
		add_child(story_scene_instance)
		story_scene_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		story_scene_instance.set_cast(story_script.get_cast())
		story_scene_instance.sequence_started.connect(_on_story_sequence_started)
		story_scene_instance.sequence_finished.connect(_on_story_sequence_finished)
		story_scene_instance.battle_requested.connect(_on_battle_requested)
	else:
		story_scene_instance.visible = true

	# 前半ストーリー再生（rematch 時は短縮ルート、それ以外は pre1）
	var played_id: String = rematch_id if use_rematch else pre_id
	await story_scene_instance.play_sequence(pre_seq, {"id": played_id})

	# バトルで負けたらギルドホームに戻る
	if GameState.last_battle_result == "lose":
		_subevent_in_progress = false
		story_scene_instance.visible = false
		home.visible = true
		return

	# 前半2（分割されている場合のみ）— rematch ルートではスキップ
	if not use_rematch:
		var pre2_id: String = quest_data.get("pre2_sequence_id", "")
		if not pre2_id.is_empty():
			var pre2_seq = story_script.get_sequence(pre2_id)
			if pre2_seq:
				await story_scene_instance.play_sequence(pre2_seq, {"id": pre2_id})
				if GameState.last_battle_result == "lose":
					_subevent_in_progress = false
					story_scene_instance.visible = false
					home.visible = true
					return
		# 前半3（4分割の場合のみ：subevent3 用）
		var pre3_id: String = quest_data.get("pre3_sequence_id", "")
		if not pre3_id.is_empty():
			var pre3_seq = story_script.get_sequence(pre3_id)
			if pre3_seq:
				await story_scene_instance.play_sequence(pre3_seq, {"id": pre3_id})
				if GameState.last_battle_result == "lose":
					_subevent_in_progress = false
					story_scene_instance.visible = false
					home.visible = true
					return

	# 後半ストーリー再生
	var post_id: String = quest_data.get("post_sequence_id", "")
	if not post_id.is_empty():
		var post_seq = story_script.get_sequence(post_id)
		if post_seq:
			await story_scene_instance.play_sequence(post_seq, {"id": post_id})

	_subevent_in_progress = false
	story_scene_instance.visible = false
	home.visible = true

func _run_subevent_part_standalone(quest_id: String, part: String):
	var quest_data: Dictionary = SUBEVENT_CHAPTERS.get(quest_id, {})
	if quest_data.is_empty():
		print("[QUEST] Unknown quest: ", quest_id)
		return

	var seq_id: String = ""
	if part == "pre" or part == "pre1":
		seq_id = quest_data.get("pre_sequence_id", "")
	elif part == "pre2":
		seq_id = quest_data.get("pre2_sequence_id", "")
	elif part == "pre3":
		seq_id = quest_data.get("pre3_sequence_id", "")
	elif part == "post":
		seq_id = quest_data.get("post_sequence_id", "")
	if seq_id.is_empty():
		print("[QUEST] %s %s: 未実装" % [quest_data.get("name", quest_id), part])
		return

	_create_story_scene()
	_ensure_subevent_registered(quest_id)

	var seq = story_script.get_sequence(seq_id)
	if not seq:
		print("[QUEST] Sequence not found: ", seq_id)
		return

	await story_scene_instance.play_sequence(seq, {"id": seq_id})

	if story_scene_instance:
		story_scene_instance.queue_free()
		story_scene_instance = null

func _run_subevent_standalone(quest_id: String):
	var quest_data: Dictionary = SUBEVENT_CHAPTERS.get(quest_id, {})
	if quest_data.is_empty():
		print("[QUEST] Unknown quest: ", quest_id)
		return

	var pre_id: String = quest_data.get("pre_sequence_id", "")
	if pre_id.is_empty():
		print("[QUEST] %s: ストーリー未実装" % quest_data.get("name", quest_id))
		return

	_create_story_scene()
	_ensure_subevent_registered(quest_id)
	_subevent_in_progress = true

	var pre_seq = story_script.get_sequence(pre_id)
	if not pre_seq:
		print("[QUEST] Sequence not found: ", pre_id)
		return

	# 前半
	await story_scene_instance.play_sequence(pre_seq, {"id": pre_id})

	# バトルで負けたら終了
	if GameState.last_battle_result == "lose":
		_subevent_in_progress = false
		if story_scene_instance:
			story_scene_instance.queue_free()
			story_scene_instance = null
		return

	# 前半2（分割されている場合のみ）
	var pre2_id: String = quest_data.get("pre2_sequence_id", "")
	if not pre2_id.is_empty():
		var pre2_seq = story_script.get_sequence(pre2_id)
		if pre2_seq:
			await story_scene_instance.play_sequence(pre2_seq, {"id": pre2_id})
			if GameState.last_battle_result == "lose":
				_subevent_in_progress = false
				if story_scene_instance:
					story_scene_instance.queue_free()
					story_scene_instance = null
				return

	# 前半3（4分割の場合のみ：subevent3 用）
	var pre3_id: String = quest_data.get("pre3_sequence_id", "")
	if not pre3_id.is_empty():
		var pre3_seq = story_script.get_sequence(pre3_id)
		if pre3_seq:
			await story_scene_instance.play_sequence(pre3_seq, {"id": pre3_id})
			if GameState.last_battle_result == "lose":
				_subevent_in_progress = false
				if story_scene_instance:
					story_scene_instance.queue_free()
					story_scene_instance = null
				return

	# 後半
	var post_id: String = quest_data.get("post_sequence_id", "")
	if not post_id.is_empty():
		var post_seq = story_script.get_sequence(post_id)
		if post_seq:
			await story_scene_instance.play_sequence(post_seq, {"id": post_id})

	_subevent_in_progress = false
	if story_scene_instance:
		story_scene_instance.queue_free()
		story_scene_instance = null

# --- ストーリー編集モード ---

const STORY_EDIT_SEQUENCES := [
	# Prologue 場面label単位
	{"id": "prologue", "label": "scene_university", "name": "大学"},
	{"id": "prologue", "label": "scene_room", "name": "自室"},
	{"id": "prologue", "label": "scene_lab1", "name": "研究室1"},
	{"id": "prologue", "label": "scene_lab2", "name": "研究室2"},
	{"id": "prologue", "label": "scene_teleport1", "name": "転送広場1"},
	{"id": "prologue", "label": "scene_teleport2", "name": "転送広場2"},
	{"id": "prologue", "label": "scene_prison", "name": "牢獄"},
	{"id": "prologue", "label": "tutorial_start", "name": "チュートリアル"},
	{"id": "prologue", "label": "after_tutorial", "name": "チュートリアル後〜バトル前"},
	{"id": "prologue", "label": "battle_start", "name": "本番バトル"},
	{"id": "prologue_battle_win", "name": "マチルダ戦 勝利後"},
	{"id": "prologue_battle_lose", "name": "マチルダ戦 敗北後"},
	# Stage1
	{"separator": true, "name": "--- Stage1 ---"},
	{"id": "stage1", "label": "scene_guild_street", "name": "ギルド通り"},
	{"id": "stage1", "label": "scene_analysis", "name": "道中・解析"},
	{"id": "stage1", "label": "scene_guild_hall", "name": "冒険者ギルド"},
	{"id": "stage1", "label": "stage1_battle_start", "name": "冒険者Aバトル"},
	{"id": "stage1", "label": "scene_guild_reception", "name": "ギルド受付"},
	# Subevent1 / 2（シーケンス単位、prefix label のため細分なし）
	{"separator": true, "name": "--- サブイベント ---"},
	{"id": "subevent1_pre", "name": "サブイベント1 前半1（ギルドホーム）", "chapter": "Subevent1ChapterScript"},
	{"id": "subevent1_hideout", "name": "サブイベント1 前半2（盗賊団アジト）", "chapter": "Subevent1ChapterScript"},
	{"id": "subevent1_post", "name": "サブイベント1 後半（ベルカ決着後）", "chapter": "Subevent1ChapterScript"},
	{"id": "subevent2_pre1", "name": "サブイベント2 前半1（ギルド→教会裏庭）", "chapter": "Subevent2ChapterScript"},
	{"id": "subevent2_pre2", "name": "サブイベント2 前半2（礼拝室→シスター長戦）", "chapter": "Subevent2ChapterScript"},
	{"id": "subevent2_post", "name": "サブイベント2 後半（シスター長決着後）", "chapter": "Subevent2ChapterScript"},
	# Stage2
	{"separator": true, "name": "--- Stage2 ---"},
	{"id": "stage2_pre", "name": "Stage2 場面1 盗難濡れ衣"},
	{"id": "stage2_meet", "name": "Stage2 場面2 月の葉亭・対面"},
	{"id": "stage2_recover", "name": "Stage2 場面4 作戦会議"},
	{"id": "stage2_post", "name": "Stage2 場面7 敗北後の恨み"},
	{"id": "stage2_close", "name": "Stage2 場面8 ギルド帰還"},
	# Stage3
	{"separator": true, "name": "--- Stage3 ---"},
	{"id": "stage3_harass", "name": "Stage3 場面1-2 教会嫌がらせ"},
	{"id": "stage3_challenge", "name": "Stage3 場面3 教会乗り込み"},
	{"id": "stage3_recover", "name": "Stage3 場面5 作戦会議"},
	{"id": "stage3_post", "name": "Stage3 場面8 嫌がらせ停止"},
	# Stage4
	{"separator": true, "name": "--- Stage4 ---"},
	{"id": "stage4_pre", "name": "Stage4 場面1 挑戦状"},
	{"id": "stage4_infiltrate", "name": "Stage4 場面2 潜入失敗"},
	{"id": "stage4_meet", "name": "Stage4 場面3 セレス対面"},
	{"id": "stage4_contract", "name": "Stage4 場面4.5 契約執行"},
	{"id": "stage4_recover", "name": "Stage4 場面5 ミニゲーム準備"},
	{"id": "stage4_post", "name": "Stage4 場面8 セレスの執着"},
	{"id": "stage4_close", "name": "Stage4 場面9 ギルド帰還"},
	# Stage5
	{"separator": true, "name": "--- Stage5 ---"},
	{"id": "stage5_summon", "name": "Stage5 場面1-2 出頭命令"},
	{"id": "stage5_interrogation", "name": "Stage5 場面3 取り調べ・決闘"},
	{"id": "stage5_recover", "name": "Stage5 場面5 作戦会議"},
	{"id": "stage5_post", "name": "Stage5 場面7 再戦勝利後"},
	{"id": "stage5_close", "name": "Stage5 場面9 ギルド帰還"},
	# Stage6
	{"separator": true, "name": "--- Stage6 (王女) ---"},
	{"id": "stage6_pre", "name": "Stage6 場面1 招待状"},
	{"id": "stage6_banquet", "name": "Stage6 場面2 晩餐会・初戦"},
	{"id": "stage6_recover", "name": "Stage6 場面3 控えの間・ブチギレ"},
	{"id": "stage6_post", "name": "Stage6 場面4 再戦勝利・余韻"},
	# Stage7
	{"separator": true, "name": "--- Stage7 (エンディング) ---"},
	{"id": "stage7_throne", "name": "Stage7 場面1 王座継承"},
	{"id": "stage7_epilogue", "name": "Stage7 場面2 エピローグ"},
	# Subevent3
	{"separator": true, "name": "--- Subevent3 (フィオナ) ---"},
	{"id": "subevent3_pre", "name": "Subevent3 場面1 依頼受注"},
	{"id": "subevent3_blacksmith", "name": "Subevent3 場面2 鍛冶屋"},
	{"id": "subevent3_visit", "name": "Subevent3 場面3-7 エドモンド邸"},
	{"id": "subevent3_post", "name": "Subevent3 場面8 決着・後日談"},
	# Subevent4
	{"separator": true, "name": "--- Subevent4 (受付嬢) ---"},
	{"id": "subevent4_pre", "name": "Subevent4 前半"},
	{"id": "subevent4_post", "name": "Subevent4 後半"},
]

signal _story_edit_selected(index: int)

func _on_story_edit_mode():
	jump_menu.visible = false
	while true:
		# Show sequence selection
		for child in jump_list.get_children():
			child.queue_free()
		var title_label := Label.new()
		title_label.text = "ストーリー編集 — シーケンス選択"
		title_label.add_theme_font_size_override("font_size", 22)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		jump_list.add_child(title_label)
		for i in STORY_EDIT_SEQUENCES.size():
			var seq_entry = STORY_EDIT_SEQUENCES[i]
			if seq_entry.get("separator", false):
				var sep_label := Label.new()
				sep_label.text = seq_entry.name
				sep_label.add_theme_font_size_override("font_size", 16)
				sep_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
				sep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				jump_list.add_child(sep_label)
				continue
			var btn := Button.new()
			btn.text = seq_entry.name
			btn.add_theme_font_size_override("font_size", 20)
			btn.pressed.connect(_story_edit_emit_selected.bind(i))
			jump_list.add_child(btn)
		var back_btn := Button.new()
		back_btn.text = "← 戻る"
		back_btn.add_theme_font_size_override("font_size", 18)
		back_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		back_btn.pressed.connect(_story_edit_emit_selected.bind(-1))
		jump_list.add_child(back_btn)
		jump_menu.visible = true

		var selected: int = await _story_edit_selected
		jump_menu.visible = false
		if selected < 0:
			_show_edit_menu()
			return

		var entry = STORY_EDIT_SEQUENCES[selected]
		await _run_story_edit(entry)
		# シーケンス選択に戻る（バトル編集の章選択ループと同じ挙動）

func _run_story_edit(entry: Dictionary):
	var sequence_id: String = entry.id

	# 編集モードでは set_portrait/appear の呼び出し位置(edit_source_id)を記録する必要がある。
	# 通常バトルをプレイすると BattleScene が editor_capture を false にするため、
	# ストーリー編集に入るたびに必ず true へ戻す（保存に edit_source_id が要る）。
	StoryCommands.editor_capture = true

	_create_story_scene()

	# 編集モード: 章スクリプトを強制再パースして再登録する（preload キャッシュをバイパス）。
	# これがないと「保存 → 編集を閉じて開き直し」で古い値が再表示される。
	_force_reload_story_chapters()

	# Register subevent chapters (chapter フィールド指定時)
	if entry.has("chapter") and entry.chapter == "Subevent1ChapterScript":
		var s1 = _load_script_fresh("res://story/chapters/Subevent1Chapter.gd")
		if s1:
			story_script._register_chapter(s1.new())
	elif entry.has("chapter") and entry.chapter == "Subevent2ChapterScript":
		var s2 = _load_script_fresh("res://story/chapters/Subevent2Chapter.gd")
		if s2:
			story_script._register_chapter(s2.new())

	var seq = story_script.get_sequence(sequence_id)
	if not seq:
		print("[STORY_EDIT] Sequence not found: ", sequence_id)
		return

	var entries: Array = seq.entries
	if entries.is_empty():
		print("[STORY_EDIT] No entries in sequence")
		return

	# Build edit layout (上部ナビ帯 + 左右カード)
	var edit_root := _create_story_edit_layout()
	add_child(edit_root)
	move_child(edit_root, get_child_count() - 1)

	var idx := 0
	_story_edit_nav_action = ""

	var nav_bar: PanelContainer = edit_root.find_child("StoryEditNavBar", true, false)
	var left_card: PanelContainer = edit_root.find_child("StoryEditCard_Left", true, false)
	var right_card: PanelContainer = edit_root.find_child("StoryEditCard_Right", true, false)
	var prev_btn: Button = nav_bar.find_child("PrevBtn", true, false)
	var next_btn: Button = nav_bar.find_child("NextBtn", true, false)
	var exit_btn: Button = nav_bar.find_child("ExitBtn", true, false)
	var idx_label: Label = nav_bar.find_child("IdxLabel", true, false)
	var cmd_label: Label = nav_bar.find_child("CmdLabel", true, false)

	prev_btn.pressed.connect(_story_edit_set_nav.bind("prev"))
	next_btn.pressed.connect(_story_edit_set_nav.bind("next"))
	exit_btn.pressed.connect(_story_edit_set_nav.bind("exit"))

	# 各カードのスライダー・保存・コピーを wire
	for card in [left_card, right_card]:
		if not card:
			continue
		# GDScript ラムダのクロージャ late-binding 対策で、各イテレーション専用の
		# ローカル変数 bound_card を作って閉包に取り込ませる（card を直接捕捉すると
		# ループ終了後の最終値で全ラムダが動くリスクを残すため）。
		var bound_card: PanelContainer = card
		var sl_c := _get_edit_sliders(bound_card)
		if not sl_c.is_empty():
			sl_c.scale.value_changed.connect(_on_story_edit_card_slider.bind(bound_card))
			sl_c.x.value_changed.connect(_on_story_edit_card_slider.bind(bound_card))
			sl_c.y.value_changed.connect(_on_story_edit_card_slider.bind(bound_card))
		var save_btn_c: Button = bound_card.find_child("SaveBtn", true, false)
		if save_btn_c:
			save_btn_c.pressed.connect(func():
				# idx は閉包で参照（後段で更新される _current_idx に追従）
				_save_story_edit_card(bound_card, entries, _story_edit_current_idx))
		var copy_btn_c: Button = bound_card.find_child("CopyBtn", true, false)
		if copy_btn_c:
			copy_btn_c.pressed.connect(func():
				_story_edit_copy_card(bound_card))
		var pick_btn_c: Button = bound_card.find_child("PickImageBtn", true, false)
		if pick_btn_c:
			pick_btn_c.pressed.connect(func():
				_show_story_edit_image_picker(bound_card))
		var flip_btn_c: Button = bound_card.find_child("FlipBtn", true, false)
		if flip_btn_c:
			flip_btn_c.pressed.connect(func():
				_on_story_edit_card_flip(bound_card))

	# Track source file for saving
	var source_file: String = ""
	if entry.has("chapter") and entry.chapter == "Subevent1ChapterScript":
		source_file = "res://story/chapters/Subevent1Chapter.gd"
	elif entry.has("chapter") and entry.chapter == "Subevent2ChapterScript":
		source_file = "res://story/chapters/Subevent2Chapter.gd"
	elif sequence_id == "prologue":
		source_file = "res://story/chapters/PrologueChapter.gd"
	elif sequence_id == "stage1":
		source_file = "res://story/chapters/Stage1Chapter.gd"
	_story_edit_source_file = source_file

	# Disable StoryScene input handling in edit mode
	story_scene_instance._waiting_for_input = false
	# 編集モード: portrait_log を有効化（保存時に bound_rect から edit_source_id を引くために必要）
	if "portrait_log_enabled" in story_scene_instance:
		story_scene_instance.portrait_log_enabled = true
		if "portrait_log" in story_scene_instance:
			story_scene_instance.portrait_log.clear()

	# 初期セットアップ: 指定labelがあればそのラベル直後の最初の発話まで進める。
	# なければシーケンス先頭から最初の発話までの命令を実行。
	# これにより StoryScene.tscn のデフォルト背景ではなく、対象シーンの背景・キャラ・ダイアログ枠が初期表示される
	var start_label: String = entry.get("label", "")
	var scan_from := 0
	if not start_label.is_empty():
		var label_idx := -1
		for i in range(entries.size()):
			var e_scan = entries[i]
			if e_scan is StoryCommands.SeqLabel and e_scan.label_name == start_label:
				label_idx = i
				break
		if label_idx < 0:
			print("[STORY_EDIT] Label not found: ", start_label, " — fallback to start")
		else:
			scan_from = label_idx + 1
	# scan_from から最初の停止ポイント（実機の入力待ち位置と同じ単位）まで進める
	var setup_end: int = _story_edit_next_stop(entries, scan_from)
	if setup_end < 0:
		setup_end = scan_from
	if setup_end > 0:
		idx = setup_end
	_story_edit_current_idx = idx
	_story_edit_reset_scene(story_scene_instance)
	# label指定時はラベル直後から実行（以前のシーンを再生しない）。指定なしは0から。
	_story_edit_execute_to(entries, idx, story_scene_instance, scan_from)
	_story_edit_update_info(idx_label, cmd_label, entries, idx)
	_refresh_story_edit_cards(edit_root, story_scene_instance)

	# Main edit loop
	while true:
		_story_edit_nav_action = ""

		await get_tree().process_frame

		if _story_edit_nav_action == "":
			continue

		if _story_edit_nav_action == "exit":
			break
		elif _story_edit_nav_action == "prev":
			# 実機のクリック/Enter と同じく「前の入力待ち（停止ポイント）」へ戻る。
			# 停止ポイント単位なので、絵だけ／テキストだけ、というチラ見せが起きない。
			var prev_idx: int = _story_edit_prev_stop(entries, idx)
			if prev_idx >= 0 and prev_idx != idx:
				idx = prev_idx
				_story_edit_current_idx = idx
				_story_edit_reset_scene(story_scene_instance)
				_story_edit_execute_to(entries, idx, story_scene_instance)
				_story_edit_update_info(idx_label, cmd_label, entries, idx)
				_refresh_story_edit_cards(edit_root, story_scene_instance)
		elif _story_edit_nav_action == "next":
			# 実機と同じく「次の入力待ち（停止ポイント）」まで一気に進める。
			# 間にある set_portrait/background/hide_character/SeqLabel 等は順に execute_single
			# で適用され、Battle/TerminalEffect は editor 上ではスキップ。
			var next_idx: int = _story_edit_next_stop(entries, idx + 1)
			if next_idx >= 0:
				for i in range(idx + 1, next_idx + 1):
					var e = entries[i]
					if e == null:
						continue
					if e is StoryCommands.Battle:
						continue
					if e is StoryCommands.TerminalEffect:
						continue
					_story_edit_execute_single(e, story_scene_instance)
				idx = next_idx
				_story_edit_current_idx = idx
				_story_edit_update_info(idx_label, cmd_label, entries, idx)
				_refresh_story_edit_cards(edit_root, story_scene_instance)
			else:
				# 末尾到達 → 編集終了（次へを連打すると閉じる）
				break

	edit_root.queue_free()
	if story_scene_instance:
		story_scene_instance.queue_free()
		story_scene_instance = null

func _story_edit_emit_selected(index: int):
	_story_edit_selected.emit(index)

func _story_edit_toggle_side(_edit_panel: PanelContainer):
	# 旧 L/R トグル。新レイアウトでは廃止（左右カードが画面位置と1対1で対応する）。
	pass

func _story_edit_set_nav(action: String):
	_story_edit_nav_action = action

func _story_edit_copy_values(edit_panel: PanelContainer):
	# 旧API互換: side 情報なしで scale/position だけクリップボードへ
	var sl := _get_edit_sliders(edit_panel)
	if sl.is_empty():
		return
	var text: String = '"scale": %.2f, "position": [%d, %d],' % [sl.scale.value, int(sl.x.value), int(sl.y.value)]
	DisplayServer.clipboard_set(text)

# カード単位のコピー: bound_side（left/right/center）を含めて整形しクリップボードへ
func _story_edit_copy_card(card: PanelContainer):
	var sl := _get_edit_sliders(card)
	if sl.is_empty():
		return
	var s: float = sl.scale.value
	var x: int = int(sl.x.value)
	var y: int = int(sl.y.value)
	var side: String = card.get_meta("bound_side", "center")
	var text: String = '"scale": %.2f, "side": "%s", "position": [%d, %d],' % [s, side, x, y]
	DisplayServer.clipboard_set(text)
	var info: Label = card.find_child("InfoLabel", true, false)
	if info:
		info.text = "コピーしました"

# 実機のクリック/Enter と同じ「次の入力待ちまで一気に進める」単位を判定する。
# 停止ポイント:
#   - Band/Line で text が非空（実機もここで _waiting_for_input になる）
#   - Battle コマンド（制御フロー上、ここで止めて手前の状態を見る）
func _story_edit_is_stop_point(e) -> bool:
	if e == null:
		return false
	if e is StoryCommands.Band and not e.text.is_empty():
		return true
	if e is StoryCommands.Line and not e.text.is_empty():
		return true
	if e is StoryCommands.Battle:
		return true
	return false

# from_idx 以降で最初の停止ポイントの index を返す。無ければ -1。
func _story_edit_next_stop(entries: Array, from_idx: int) -> int:
	var start: int = max(0, from_idx)
	for i in range(start, entries.size()):
		if _story_edit_is_stop_point(entries[i]):
			return i
	return -1

# 画像差し替えピッカー用ヘルパ群 ----------------------------------------------

# ファイル名から「末尾の連番を除いた prefix」を返す。
# 例: "satoshi_isekai_007.png" → "satoshi_isekai_"
# 末尾が数字でなければ basename をそのまま返す（マッチは厳密一致になる）。
func _story_edit_prefix_of(filename: String) -> String:
	var base: String = filename.get_basename()
	var r := RegEx.new()
	r.compile("^(.+?)(\\d+)$")
	var m := r.search(base)
	if m:
		return m.get_string(1)
	return base

# 同フォルダの画像名が _story_edit_prefix_of() で得た prefix にマッチするか。
# prefix + 全桁数字（任意桁）を sibling として認める。
func _story_edit_match_prefix(filename: String, prefix: String) -> bool:
	var base: String = filename.get_basename()
	if not base.begins_with(prefix):
		return false
	var rest: String = base.substr(prefix.length())
	if rest.is_empty():
		return false
	for c in rest:
		if not (c >= "0" and c <= "9"):
			return false
	return true

# res:// 配下を再帰的に走査し、.gd ファイル一覧を out に格納する
func _walk_gd_files_under(res_path: String, out: Array) -> void:
	var dir := DirAccess.open(res_path)
	if not dir:
		return
	# パス連結用に末尾スラッシュを確保（"res://" は rstrip すると "res:" になるので注意）
	var base: String = res_path if res_path.ends_with("/") else res_path + "/"
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var full: String = base + name
			if dir.current_is_dir():
				_walk_gd_files_under(full, out)
			elif name.ends_with(".gd"):
				out.append(full)
		name = dir.get_next()
	dir.list_dir_end()

# プロジェクト全 .gd ファイルを連結したキャッシュ。ピッカー1セッションの間だけ使う。
var _story_edit_gd_cache: String = ""

func _story_edit_rebuild_gd_cache() -> void:
	var files: Array = []
	_walk_gd_files_under("res://", files)
	var sb := PackedStringArray()
	for f in files:
		var fa := FileAccess.open(f, FileAccess.READ)
		if fa:
			sb.append(fa.get_as_text())
			fa.close()
	_story_edit_gd_cache = "\n".join(sb)

# 画像パスがプロジェクト全 .gd で何箇所参照されているかを返す。
# _story_edit_rebuild_gd_cache を事前に呼んでおく前提。
func _story_edit_count_image_uses(img_path: String) -> int:
	if _story_edit_gd_cache.is_empty():
		return 0
	return _story_edit_gd_cache.count(img_path)

# 画像差し替えピッカー本体 -----------------------------------------------------

func _show_story_edit_image_picker(card: PanelContainer) -> void:
	if not is_instance_valid(card):
		return
	var rect: TextureRect = card.get_meta("bound_rect", null) if card.has_meta("bound_rect") else null
	if not is_instance_valid(rect) or not rect.texture or rect.texture.resource_path.is_empty():
		print("[STORY_EDIT] 画像選択: bound_rect の現在画像が取れない")
		return
	# 現在パス（pending があればそちら）から folder と prefix を決定
	var current_path: String = rect.texture.resource_path
	if card.has_meta("pending_portrait_path"):
		current_path = card.get_meta("pending_portrait_path")
	var folder: String = current_path.get_base_dir()
	var current_file: String = current_path.get_file()
	var prefix: String = _story_edit_prefix_of(current_file)

	# 同フォルダ + 同 prefix の画像を列挙
	var matches: Array = []
	var dir := DirAccess.open(folder)
	if dir:
		dir.list_dir_begin()
		var n := dir.get_next()
		while n != "":
			if n != "." and n != ".." and not dir.current_is_dir():
				var lower: String = n.to_lower()
				var is_img: bool = lower.ends_with(".png") or lower.ends_with(".jpg") or lower.ends_with(".jpeg") or lower.ends_with(".webp")
				if is_img and _story_edit_match_prefix(n, prefix):
					matches.append(n)
			n = dir.get_next()
		dir.list_dir_end()
	matches.sort()

	# 全 .gd ファイルを読み込んで使用数カウント用キャッシュを構築
	_story_edit_rebuild_gd_cache()

	# モーダル UI 構築
	var modal := PanelContainer.new()
	modal.name = "StoryEditImagePicker"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.88)
	modal.add_theme_stylebox_override("panel", bg_style)
	add_child(modal)
	move_child(modal, get_child_count() - 1)

	var vbox := VBoxContainer.new()
	vbox.name = "PickerVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.anchor_left = 0.02
	vbox.anchor_right = 0.98
	vbox.anchor_top = 0.04
	vbox.anchor_bottom = 0.96
	vbox.add_theme_constant_override("separation", 8)
	modal.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	var title_lbl := Label.new()
	title_lbl.text = "画像選択  folder: %s  prefix: %s*  該当: %d 件" % [folder, prefix, matches.size()]
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	header.add_child(title_lbl)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "× 閉じる"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func(): modal.queue_free())
	header.add_child(close_btn)

	# 本体を左右2分割: 左にサムネグリッド、右に大きいプレビューペイン
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body)

	# 左: スクロール可能なサムネグリッド
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 0.72
	body.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "PickerGrid"
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	# 右: 大きいプレビューペイン
	var preview_pane := VBoxContainer.new()
	preview_pane.add_theme_constant_override("separation", 8)
	preview_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_pane.size_flags_stretch_ratio = 0.28
	body.add_child(preview_pane)

	var preview_title := Label.new()
	preview_title.text = "プレビュー"
	preview_title.add_theme_font_size_override("font_size", 13)
	preview_title.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	preview_pane.add_child(preview_title)

	var preview_tex_rect := TextureRect.new()
	preview_tex_rect.name = "PreviewTex"
	preview_tex_rect.custom_minimum_size = Vector2(320, 480)
	preview_tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 背景を少し明るく（黒地に絵が溶けないように）
	var pv_bg := PanelContainer.new()
	var pv_style := StyleBoxFlat.new()
	pv_style.bg_color = Color(0.12, 0.12, 0.14, 1.0)
	pv_bg.add_theme_stylebox_override("panel", pv_style)
	pv_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pv_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv_bg.add_child(preview_tex_rect)
	preview_pane.add_child(pv_bg)

	var preview_name_lbl := Label.new()
	preview_name_lbl.name = "PreviewName"
	preview_name_lbl.text = current_file
	preview_name_lbl.add_theme_font_size_override("font_size", 13)
	preview_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	preview_pane.add_child(preview_name_lbl)

	var preview_count_lbl := Label.new()
	preview_count_lbl.name = "PreviewCount"
	preview_count_lbl.add_theme_font_size_override("font_size", 12)
	preview_pane.add_child(preview_count_lbl)

	var confirm_btn := Button.new()
	confirm_btn.text = "✔ この画像で確定"
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	confirm_btn.disabled = true  # サムネを選ぶまで押せない
	preview_pane.add_child(confirm_btn)

	# 初期状態: 現在の画像をプレビューに表示
	var current_tex: Texture2D = load(current_path)
	if current_tex:
		preview_tex_rect.texture = current_tex
	var cur_count: int = _story_edit_count_image_uses(current_path)
	preview_count_lbl.text = "（現在の画像）  %s" % ("未使用" if cur_count == 0 else "%d箇所使用" % cur_count)

	# サムネ選択状態を closure 越しに共有
	var sel_state: Dictionary = {"path": "", "button": null}
	const THUMB_W: int = 200    # サムネの幅
	const THUMB_H: int = 400    # サムネの高さ（縦方向は2倍にして顔/上半身が見切れないように）
	for fn in matches:
		var full_path: String = folder.rstrip("/") + "/" + fn
		var tex: Texture2D = load(full_path)
		if not tex:
			continue
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(THUMB_W + 10, THUMB_H + 60)
		# 立ち絵は縦長。横方向は中央の 1/2 幅をクロップ（2倍ズーム）、
		# 縦方向はその2倍の高さ（=元の上半身分量）を取り、顔/上半身が見切れないようにする。
		# 顔位置（画像上部 14% あたり）が thumb の上 1/3 〜 中央に来るよう垂直オフセットを寄せる。
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		var tw: int = tex.get_width()
		var th: int = tex.get_height()
		var crop_w: int = max(1, min(int(tw / 2), int(th * 0.25)))
		var crop_h: int = max(1, min(th, crop_w * 2))
		var face_y_est: int = int(th * 0.14)
		var crop_y: int = clampi(face_y_est - int(crop_h / 3), 0, max(0, th - crop_h))
		var crop_x: int = max(0, int((tw - crop_w) / 2))
		atlas.region = Rect2(crop_x, crop_y, crop_w, crop_h)
		var btn := TextureButton.new()
		btn.texture_normal = atlas
		btn.custom_minimum_size = Vector2(THUMB_W, THUMB_H)
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.ignore_texture_size = true
		btn.tooltip_text = full_path
		# 現在選択中の画像は控えめなハイライト
		if full_path == current_path:
			btn.modulate = Color(1.15, 1.3, 1.15)
		cell.add_child(btn)
		var name_lbl := Label.new()
		name_lbl.text = fn
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_lbl.custom_minimum_size = Vector2(THUMB_W, 0)
		cell.add_child(name_lbl)
		var count: int = _story_edit_count_image_uses(full_path)
		var count_lbl := Label.new()
		count_lbl.text = "未使用" if count == 0 else "%d箇所使用" % count
		count_lbl.add_theme_font_size_override("font_size", 11)
		count_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if count == 0 else Color(0.9, 0.85, 0.5))
		cell.add_child(count_lbl)
		grid.add_child(cell)
		# クリック: 選択ハイライト + プレビューペイン更新（まだカードに反映しない）
		btn.pressed.connect(func():
			# 前の選択のハイライトを戻す（現在の画像のハイライトは保つ）
			var prev_btn: TextureButton = sel_state.get("button")
			if prev_btn and prev_btn != btn:
				if sel_state.get("path") == current_path:
					prev_btn.modulate = Color(1.15, 1.3, 1.15)
				else:
					prev_btn.modulate = Color.WHITE
			# 新しい選択を強調
			btn.modulate = Color(1.5, 1.7, 1.5)
			sel_state["button"] = btn
			sel_state["path"] = full_path
			# プレビューを更新
			preview_tex_rect.texture = tex
			preview_name_lbl.text = fn
			var marker: String = "  ★ 選択中" if full_path != current_path else "  （現在の画像）"
			preview_count_lbl.text = "%s%s" % [("未使用" if count == 0 else "%d箇所使用" % count), marker]
			confirm_btn.disabled = false)

	# 確定ボタン: 選択中の画像をカードに反映してピッカーを閉じる
	confirm_btn.pressed.connect(func():
		var p: String = sel_state.get("path", "")
		if p.is_empty():
			return
		_on_story_edit_image_picked(card, p)
		modal.queue_free())

# 反転ボタンのハンドラ：bound_rect.flip_h を即トグル（プレビュー）。
# 実ファイルへの書き込みは保存ボタン経由でのみ行う（rect.flip_h vs 履歴 flip_h の差分検出で保存判定）。
func _on_story_edit_card_flip(card: PanelContainer) -> void:
	if not is_instance_valid(card):
		return
	var rect: TextureRect = card.get_meta("bound_rect", null) if card.has_meta("bound_rect") else null
	if not is_instance_valid(rect):
		return
	rect.flip_h = not rect.flip_h
	# タイトルに反転中マーカー（実機の見た目と一致させるための補助表示）
	var title: Label = card.find_child("Title", true, false)
	if title:
		var side: String = card.get_meta("bound_side", "")
		var tx_name: String = ""
		if rect.texture and rect.texture.resource_path:
			tx_name = rect.texture.resource_path.get_file()
		var swap_marker: String = "* " if card.has_meta("pending_portrait_path") else ""
		var flip_marker: String = "↔ " if rect.flip_h else ""
		title.text = "[%s] %s%s%s" % [side, swap_marker, flip_marker, tx_name]
	print("[STORY_EDIT] 反転トグル: flip_h=%s" % rect.flip_h)

# ピッカーで画像が選択されたときの処理：bound_rect.texture を即差し替え、
# card に pending_portrait_path meta を立て、未保存マーカー * をタイトルに出す。
# 実ファイルへの書き込みは保存ボタン経由でのみ行う。
func _on_story_edit_image_picked(card: PanelContainer, new_path: String) -> void:
	if not is_instance_valid(card):
		return
	var rect: TextureRect = card.get_meta("bound_rect", null) if card.has_meta("bound_rect") else null
	if not is_instance_valid(rect):
		return
	var new_tex = load(new_path)
	if not new_tex:
		print("[STORY_EDIT] 画像ロード失敗: %s" % new_path)
		return
	rect.texture = new_tex
	# 既存のサイズ/スケール/位置はそのまま維持（ユーザーが必要なら手で調整）
	# サイズだけは新テクスチャに合わせる（スライダーの中心算出に必要）
	rect.size = new_tex.get_size()
	# 同じ画像が選ばれた場合は pending を立てない（無意味な保存を避ける）
	var current_path_meta: String = ""
	if card.has_meta("pending_portrait_path"):
		current_path_meta = card.get_meta("pending_portrait_path")
	var prev_actual: String = ""
	if story_scene_instance and "portrait_log" in story_scene_instance:
		var plog: Array = story_scene_instance.portrait_log
		for i in range(plog.size() - 1, -1, -1):
			var e = plog[i]
			if e.get("rect") == rect:
				prev_actual = e.get("texture_path", "")
				break
	if new_path == prev_actual:
		# 元と同じに戻す選択。pending をクリア。
		card.remove_meta("pending_portrait_path")
	else:
		card.set_meta("pending_portrait_path", new_path)
	# タイトルに未保存マーカーを反映
	var title: Label = card.find_child("Title", true, false)
	if title:
		var side: String = card.get_meta("bound_side", "")
		var marker: String = "* " if card.has_meta("pending_portrait_path") else ""
		title.text = "[%s] %s%s" % [side, marker, new_path.get_file()]
	print("[STORY_EDIT] 画像差し替え (未保存): %s" % new_path)

# from_idx より手前で最後の停止ポイントの index を返す。無ければ -1。
func _story_edit_prev_stop(entries: Array, from_idx: int) -> int:
	var start: int = min(from_idx, entries.size()) - 1
	for i in range(start, -1, -1):
		if _story_edit_is_stop_point(entries[i]):
			return i
	return -1

func _story_edit_execute_single(e, scene):
	# Execute a single command with animations disabled
	if e is StoryCommands.ShowCharacter:
		var saved_effect: String = e.appear_effect
		var saved_duration: float = e.appear_duration
		var saved_transition: String = e.transition
		var saved_transition_dur: float = e.transition_duration
		e.appear_effect = ""
		e.appear_duration = 0.0
		e.transition = ""
		e.transition_duration = 0.0
		e.execute(scene)
		e.appear_effect = saved_effect
		e.appear_duration = saved_duration
		e.transition = saved_transition
		e.transition_duration = saved_transition_dur
	elif e is StoryCommands.HideCharacter:
		var saved_effect: String = e.exit_effect
		var saved_duration: float = e.exit_duration
		e.exit_effect = ""
		e.exit_duration = 0.0
		e.execute(scene)
		e.exit_effect = saved_effect
		e.exit_duration = saved_duration
	else:
		e.execute(scene)
	scene._waiting_for_input = false

func _story_edit_execute_to(entries: Array, target_idx: int, scene, start_idx: int = 0):
	for i in range(start_idx, target_idx + 1):
		var e = entries[i]
		if e == null:
			continue
		if e is StoryCommands.Battle:
			continue
		# TerminalEffect は async でオーバーレイを生成する。edit modeでは
		# overlay が永続化して次シーンに残るためスキップ
		if e is StoryCommands.TerminalEffect:
			continue
		_story_edit_execute_single(e, scene)

func _story_edit_reset_scene(scene):
	# Reset character visibility
	scene.left_char.visible = false
	scene.center_char.visible = false
	scene.right_char.visible = false
	scene.dialogue_band.visible = false
	scene._character_side_cache.clear()
	# 立ち絵履歴も破棄して、続く [0..idx] の再生で作り直す。
	# クリアしないと ◀ で前の画像へ戻っても、以前 ▶ で先へ進んだ時に積まれた
	# 「後の画像」エントリが rect の最後のエントリとして残り、保存が現在表示中の
	# 画像ではなく次の画像の set_portrait 行を書き換えてしまう。
	if "portrait_log" in scene:
		scene.portrait_log.clear()
	if "_portrait_log_current_idx" in scene:
		scene._portrait_log_current_idx = -1
	# Remove any leftover terminal effect overlays (RichTextLabel/ColorRect)
	for child in scene.get_children():
		if child is RichTextLabel or (child is ColorRect and child.color.a < 1.0):
			child.queue_free()

func _story_edit_update_info(idx_label: Label, cmd_label: Label, entries: Array, idx: int):
	idx_label.text = "%d / %d" % [idx + 1, entries.size()]
	var e = entries[idx]
	if e == null:
		cmd_label.text = "(null)"
	elif e is StoryCommands.Band:
		var speaker: String = e.speaker_id if not e.speaker_id.is_empty() else "narrator"
		var text_preview: String = e.text.substr(0, 30).replace("\n", " ")
		cmd_label.text = "Band [%s]: %s..." % [speaker, text_preview]
	elif e is StoryCommands.ShowCharacter:
		cmd_label.text = "Show [%s] side=%s" % [e.character_id, e.side_override]
	elif e is StoryCommands.HideCharacter:
		cmd_label.text = "Hide [%s]" % e.character_id
	elif e is StoryCommands.Background:
		cmd_label.text = "BG: %s" % e.path.get_file()
	elif e is StoryCommands.SeqLabel:
		cmd_label.text = "Label: %s" % e.label_name
	elif e is StoryCommands.Battle:
		cmd_label.text = "Battle: %s" % e.chapter_path.get_file()
	elif e is StoryCommands.HideDialogue:
		cmd_label.text = "HideDialogue"
	else:
		cmd_label.text = "(other)"

var _story_edit_slider_target: TextureRect = null
var _story_edit_nav_action := ""
var _story_edit_source_file := ""
# 新レイアウト用: 現在表示中の entries[idx]。各カードの保存ボタン閉包がこれを参照する。
var _story_edit_current_idx: int = 0

# 各カード（左/右）の slider value_changed ハンドラ。card に bind 中の rect を動かす。
func _on_story_edit_card_slider(_value: float, card: PanelContainer):
	if not is_instance_valid(card):
		return
	var target: TextureRect = card.get_meta("bound_rect") if card.has_meta("bound_rect") else null
	if not is_instance_valid(target) or not target.texture:
		return
	var sl := _get_edit_sliders(card)
	if sl.is_empty():
		return
	var s: float = sl.scale.value
	var tex_size: Vector2 = target.texture.get_size()
	target.size = tex_size
	target.scale = Vector2(s, s)
	var base_pos: Vector2 = _story_edit_get_base_pos(target, s)
	var new_pos := Vector2(base_pos.x + sl.x.value, base_pos.y + sl.y.value)
	target.position = new_pos
	# StoryScene._process が _char_locked_positions で位置を復元するため、ロックも更新
	if story_scene_instance and "_char_locked_positions" in story_scene_instance:
		if story_scene_instance._char_locked_positions.has(target):
			story_scene_instance._char_locked_positions[target] = new_pos
	var info: Label = card.find_child("InfoLabel", true, false)
	if info:
		var bound_side: String = card.get_meta("bound_side", "")
		info.text = '"scale": %.2f, "side": "%s", "position": [%d, %d]' % [s, bound_side, int(sl.x.value), int(sl.y.value)]

# 各カードをシーンの現在の立ち絵状態に応じて bind し直す。
# 左カード → left_char、右カード → center_char があれば center, なければ right_char。
# それぞれ立ち絵がない場合は非表示。
func _refresh_story_edit_cards(root: Control, scene):
	var left_card: PanelContainer = root.find_child("StoryEditCard_Left", true, false)
	var right_card: PanelContainer = root.find_child("StoryEditCard_Right", true, false)
	if not left_card or not right_card:
		return
	# ナビゲーション（◀/▶）は execute_to で立ち絵を再生成するので、未保存の
	# 画像差し替え（pending_portrait_path）はその時点で破棄される。meta も消す。
	if left_card.has_meta("pending_portrait_path"):
		left_card.remove_meta("pending_portrait_path")
	if right_card.has_meta("pending_portrait_path"):
		right_card.remove_meta("pending_portrait_path")
	_bind_story_edit_card(left_card, scene, "left", scene.left_char)
	# right カードは center を優先（バトル/ミニゲームと位置を揃えるため）
	var right_rect: TextureRect = null
	var right_side: String = ""
	if scene.center_char and scene.center_char.visible and scene.center_char.texture:
		right_rect = scene.center_char
		right_side = "center"
	elif scene.right_char and scene.right_char.visible and scene.right_char.texture:
		right_rect = scene.right_char
		right_side = "right"
	_bind_story_edit_card(right_card, scene, right_side, right_rect)

func _bind_story_edit_card(card: PanelContainer, _scene, side: String, rect: TextureRect):
	if not is_instance_valid(rect) or not rect.visible or not rect.texture:
		card.visible = false
		card.set_meta("bound_rect", null)
		card.set_meta("bound_side", "")
		return
	card.visible = true
	card.set_meta("bound_rect", rect)
	card.set_meta("bound_side", side)
	var title: Label = card.find_child("Title", true, false)
	if title:
		var tex_name: String = rect.texture.resource_path.get_file() if rect.texture.resource_path else "(no texture)"
		title.text = "[%s] %s" % [side, tex_name]
	var sl := _get_edit_sliders(card)
	if sl.is_empty():
		return
	var s: float = rect.scale.x
	var base_pos: Vector2 = _story_edit_get_base_pos(rect, s)
	var off_x: float = rect.position.x - base_pos.x
	var off_y: float = rect.position.y - base_pos.y
	# Range は他用途のままで OK。値だけ反映（slider 操作の循環を避ける）
	sl.scale.set_block_signals(true); sl.scale.value = s; sl.scale.set_block_signals(false)
	sl.x.set_block_signals(true); sl.x.value = off_x; sl.x.set_block_signals(false)
	sl.y.set_block_signals(true); sl.y.value = off_y; sl.y.set_block_signals(false)
	if sl.scale_spin: sl.scale_spin.set_block_signals(true); sl.scale_spin.value = s; sl.scale_spin.set_block_signals(false)
	if sl.x_spin: sl.x_spin.set_block_signals(true); sl.x_spin.value = off_x; sl.x_spin.set_block_signals(false)
	if sl.y_spin: sl.y_spin.set_block_signals(true); sl.y_spin.value = off_y; sl.y_spin.set_block_signals(false)

# ストーリー編集レイアウト: 上部に細いナビ帯、左上に左キャラ用カード、
# 右上に右キャラ用カード（中央キャラは右カードに割当）を配置する。
# 各カードはバトル編集カードと同等のスケール/X/Y スライダー + 保存/コピーを持ち、
# その瞬間に画面上に表示されている立ち絵にそれぞれ独立して binding される。
# L/R 切り替えボタンは廃止（画面上の位置と UI 上のカード位置が対応するため不要）。
func _create_story_edit_layout() -> Control:
	var root := Control.new()
	root.name = "StoryEditRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 子のパネルだけがクリックを受ける

	var nav_bar := _create_story_edit_nav_bar()
	root.add_child(nav_bar)

	var left_card := _create_story_edit_char_card("left")
	root.add_child(left_card)

	var right_card := _create_story_edit_char_card("right")
	root.add_child(right_card)

	return root

# 画面上部の細いナビ帯（◀ idx/total cmd ▶ 戻る）
func _create_story_edit_nav_bar() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "StoryEditNavBar"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	style.content_margin_left = 12
	style.content_margin_top = 6
	style.content_margin_right = 12
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	# 上部中央、左右カードの間にコンパクトに配置
	panel.anchor_left = 0.32
	panel.anchor_right = 0.68
	panel.anchor_top = 0.01
	panel.anchor_bottom = 0.01
	panel.offset_bottom = 48
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var prev_btn := Button.new()
	prev_btn.name = "PrevBtn"
	prev_btn.text = "◀ 前へ"
	prev_btn.add_theme_font_size_override("font_size", 14)
	hbox.add_child(prev_btn)

	var idx_label := Label.new()
	idx_label.name = "IdxLabel"
	idx_label.text = "0 / 0"
	idx_label.add_theme_font_size_override("font_size", 13)
	idx_label.custom_minimum_size = Vector2(70, 0)
	idx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(idx_label)

	var cmd_label := Label.new()
	cmd_label.name = "CmdLabel"
	cmd_label.text = ""
	cmd_label.add_theme_font_size_override("font_size", 12)
	cmd_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cmd_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hbox.add_child(cmd_label)

	var next_btn := Button.new()
	next_btn.name = "NextBtn"
	next_btn.text = "次へ ▶"
	next_btn.add_theme_font_size_override("font_size", 14)
	hbox.add_child(next_btn)

	var exit_btn := Button.new()
	exit_btn.name = "ExitBtn"
	exit_btn.text = "← 戻る"
	exit_btn.add_theme_font_size_override("font_size", 13)
	exit_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	hbox.add_child(exit_btn)

	return panel

# 左キャラ用 or 右キャラ用の編集カード。バトル編集カードと同等の作り
# （スケール/X/Y スライダー + コピー/保存）。
func _create_story_edit_char_card(side: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "StoryEditCard_" + side.capitalize()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	# 左カード=左上、右カード=右上（バトル編集カードと同じ位置）
	if side == "left":
		panel.anchor_left = 0.01
		panel.anchor_right = 0.30
	else:
		panel.anchor_left = 0.70
		panel.anchor_right = 0.99
	panel.anchor_top = 0.02
	# 余白削減: 下端を画面比で固定せず内容の高さにフィットさせる
	# （anchor_bottom=0.55 だと黒パネルが縦に伸び、下に大きな余白ができていた）
	panel.anchor_bottom = 0.02
	panel.grow_vertical = Control.GROW_DIRECTION_END
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.name = "Title"
	title.text = "(空き)"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	vbox.add_child(title)

	var scale_row := _create_slider_row("スケール", "ScaleSlider", 0.1, 2.0, 0.01, 0.5, "%.2f")
	vbox.add_child(scale_row)
	var x_row := _create_slider_row("X", "XSlider", -500, 500, 1, 0, "%d")
	vbox.add_child(x_row)
	var y_row := _create_slider_row("Y", "YSlider", -800, 400, 1, 0, "%d")
	vbox.add_child(y_row)

	var info := Label.new()
	info.name = "InfoLabel"
	info.text = ""
	info.add_theme_font_size_override("font_size", 11)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(info)

	var action_row := HBoxContainer.new()
	action_row.name = "ActionRow"
	action_row.add_theme_constant_override("separation", 4)
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(action_row)

	var copy_btn := Button.new()
	copy_btn.name = "CopyBtn"
	copy_btn.text = "コピー"
	copy_btn.add_theme_font_size_override("font_size", 13)
	copy_btn.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	action_row.add_child(copy_btn)

	var pick_btn := Button.new()
	pick_btn.name = "PickImageBtn"
	pick_btn.text = "🖼 画像"
	pick_btn.add_theme_font_size_override("font_size", 13)
	pick_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	pick_btn.tooltip_text = "同フォルダの同 prefix 画像から差し替え（明示保存が必要）"
	action_row.add_child(pick_btn)

	var flip_btn := Button.new()
	flip_btn.name = "FlipBtn"
	flip_btn.text = "🔁 反転"
	flip_btn.add_theme_font_size_override("font_size", 13)
	flip_btn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.9))
	flip_btn.tooltip_text = "立ち絵を左右反転（明示保存が必要）"
	action_row.add_child(flip_btn)

	var save_btn := Button.new()
	save_btn.name = "SaveBtn"
	save_btn.text = "保存"
	save_btn.add_theme_font_size_override("font_size", 13)
	save_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	action_row.add_child(save_btn)

	panel.set_meta("card_side", side)  # "left" or "right"
	panel.visible = false  # 立ち絵が bind されるまでは非表示
	return panel

func _story_edit_get_base_pos(target: TextureRect, s: float) -> Vector2:
	# Calculate base position the same way StoryScene._reset_rect_with_scale does
	if not story_scene_instance or not target or not target.texture:
		return Vector2.ZERO
	var tex_size: Vector2 = target.texture.get_size()
	var vp_size: Vector2 = get_viewport_rect().size
	var visual_w: float = tex_size.x * s
	var visual_h: float = tex_size.y * s
	var base_x: float
	if target == story_scene_instance.left_char:
		base_x = 100.0  # _CHAR_MARGIN
	elif target == story_scene_instance.right_char:
		base_x = vp_size.x - visual_w - 100.0
	else:  # center
		base_x = (vp_size.x - visual_w) / 2.0
	return Vector2(base_x, vp_size.y - visual_h)

# 旧: 単一パネル用の slider ハンドラ。新レイアウト導入後は未使用（card 側に置換）。
# 互換のため残置（呼ばれても何もしない）。
func _on_story_edit_slider(_value: float, _panel: PanelContainer):
	pass

# 編集モード用: GDScript を毎回ソースから再パースしてキャッシュを完全に回避する。
# ResourceLoader.CACHE_MODE_REPLACE は GDScript の class table までは作り直さない
# ため、編集モードで「保存 → 開き直し」しても古いコンパイル済みコードが動いてしまう。
# 保存値を即反映するにはここで強制再コンパイルが必要。
func _load_script_fresh(path: String) -> GDScript:
	var abs_path: String = ProjectSettings.globalize_path(path)
	var f := FileAccess.open(abs_path, FileAccess.READ)
	if not f:
		push_warning("[EDIT] fresh load failed (cannot open) %s; falling back to ResourceLoader" % path)
		return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as GDScript
	var src: String = f.get_as_text()
	f.close()
	var script := GDScript.new()
	script.source_code = src
	# resource_path をセットしないと extends による親クラス解決が現在地基準になる。
	# 一旦未設定で reload() するとパースエラーになるケースがあるため設定する。
	script.resource_path = path
	var err: int = script.reload()
	if err != OK:
		push_warning("[EDIT] fresh reload err=%d for %s; falling back" % [err, path])
		return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as GDScript
	return script

# 立ち絵スケール/位置の正規表現（保存用・共通）
func _battle_edit_scale_regex() -> RegEx:
	var r := RegEx.new()
	r.compile('"scale":\\s*[\\d.]+')
	return r

func _battle_edit_pos_regex() -> RegEx:
	var r := RegEx.new()
	r.compile('"position":\\s*\\[[^\\]]*\\]')
	return r

func _save_battle_edit(edit_panel: PanelContainer, info: Label):
	if not edit_panel.has_meta("chapter_path"):
		info.text = "[保存NG] chapter_pathが未設定"
		return
	var sl := _get_edit_sliders(edit_panel)
	var new_scale: float = sl.scale.value
	var new_x: int = int(sl.x.value)
	var new_y: int = int(sl.y.value)
	var chapter_path: String = edit_panel.get_meta("chapter_path")
	if "EncounterDatabase.gd" in chapter_path:
		# ランダムバトル: EncounterDatabase の該当エンカウントの portrait_key 立ち絵を更新
		# （portrait_key meta が "encounter"/"battle"/"farewell_win"/"farewell_lose"）
		_save_encounter_portrait(edit_panel, info, new_scale, new_x, new_y)
	else:
		# バトルチャプター: 編集中シーンの set_portrait 呼び出し行を直接更新
		_save_chapter_portrait(info, new_scale, new_x, new_y)

# 編集中の立ち絵1シーンに対応する set_portrait 呼び出し行（edit_source_id =
# "ファイル:行"）だけを更新する。定数参照（LAYLA_PORTRAIT 等）でも、同名画像が
# 他所で使われていても、編集中の1箇所だけを正しく保存できる。
func _save_chapter_portrait(info: Label, new_scale: float, new_x: int, new_y: int):
	var elog := _battle_edit_get_log()
	var idx := _battle_edit_history_idx
	if idx < 0:
		idx = elog.size() - 1
	if idx < 0 or idx >= elog.size():
		info.text = "[保存NG] 編集中の立ち絵が不明"
		return
	var src_id: String = elog[idx].get("edit_source_id", "")
	if src_id.is_empty() or not (":" in src_id):
		info.text = "[保存NG] 呼び出し位置が未記録（デバッグ実行が必要）"
		return
	var colon: int = src_id.rfind(":")
	var src_file: String = src_id.substr(0, colon)
	var line_no: int = int(src_id.substr(colon + 1))
	var abs_path: String = ProjectSettings.globalize_path(src_file)
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if not file:
		info.text = "[保存NG] ファイルを開けない"
		return
	var lines: PackedStringArray = file.get_as_text().split("\n")
	file.close()
	var li: int = line_no - 1
	if li < 0 or li >= lines.size():
		info.text = "[保存NG] 行番号が範囲外"
		return
	var line: String = lines[li]
	if not ("set_portrait" in line):
		info.text = "[保存NG] %d行目が set_portrait でない" % line_no
		return
	if '"scale"' in line:
		line = _battle_edit_scale_regex().sub(line, '"scale": %.2f' % new_scale)
	if '"position"' in line:
		line = _battle_edit_pos_regex().sub(line, '"position": [%d, %d]' % [new_x, new_y])
	lines[li] = line
	var wf := FileAccess.open(abs_path, FileAccess.WRITE)
	if not wf:
		info.text = "[保存NG] 書き込み不可"
		return
	wf.store_string("\n".join(lines))
	wf.close()
	info.text = "[保存] %s 行%d を更新" % [src_file.get_file(), line_no]
	print("[BATTLE_EDIT] SAVED %s:%d scale=%.2f pos=[%d,%d]" % [src_file.get_file(), line_no, new_scale, new_x, new_y])

# ランダムバトル: EncounterDatabase.gd の "<encounter_id>" → "<portrait_key>"
# 立ち絵の scale/position を更新する（encounter_id と portrait_key でスコープ）。
# portrait_key は "encounter" / "battle" / "farewell_win" / "farewell_lose" のいずれか。
# panel の meta "portrait_key" を見て対象ブロックを切り替える（meta なしなら "battle"）。
func _save_encounter_portrait(edit_panel: PanelContainer, info: Label, new_scale: float, new_x: int, new_y: int):
	var enc_id: String = edit_panel.get_meta("encounter_id", "")
	if enc_id.is_empty():
		info.text = "[保存NG] encounter_id未設定"
		return
	var portrait_key: String = edit_panel.get_meta("portrait_key", "battle")
	var chapter_path: String = edit_panel.get_meta("chapter_path")
	var abs_path: String = ProjectSettings.globalize_path(chapter_path)
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if not file:
		info.text = "[保存NG] ファイルを開けない"
		return
	var lines: PackedStringArray = file.get_as_text().split("\n")
	file.close()
	# "<enc_id>": { の行を探す
	var enc_line: int = -1
	for i in range(lines.size()):
		if ('"%s":' % enc_id) in lines[i] and "{" in lines[i]:
			enc_line = i
			break
	if enc_line < 0:
		info.text = "[保存NG] エンカウント %s が見つからない" % enc_id
		return
	# その後の "<portrait_key>": { を探す（同エンカウント内の最初の出現＝portraits 内のキー）
	var key_line: int = -1
	for i in range(enc_line, min(enc_line + 100, lines.size())):
		if ('"%s":' % portrait_key) in lines[i] and "{" in lines[i]:
			key_line = i
			break
	if key_line < 0:
		info.text = "[保存NG] %s の %s 立ち絵が見つからない" % [enc_id, portrait_key]
		return
	var updated := 0
	for j in range(key_line, min(key_line + 5, lines.size())):
		var line: String = lines[j]
		var changed := false
		if '"scale"' in line:
			line = _battle_edit_scale_regex().sub(line, '"scale": %.2f' % new_scale)
			changed = true
		if '"position"' in line:
			line = _battle_edit_pos_regex().sub(line, '"position": [%d, %d]' % [new_x, new_y])
			changed = true
		if changed:
			lines[j] = line
			updated += 1
	if updated == 0:
		info.text = "[保存NG] %s/%s に scale/position 行なし" % [enc_id, portrait_key]
		return
	var wf := FileAccess.open(abs_path, FileAccess.WRITE)
	if not wf:
		info.text = "[保存NG] 書き込み不可"
		return
	wf.store_string("\n".join(lines))
	wf.close()
	info.text = "[保存] %s の %s 立ち絵を更新" % [enc_id, portrait_key]
	print("[BATTLE_EDIT] SAVED encounter %s/%s: scale=%.2f pos=[%d,%d]" % [enc_id, portrait_key, new_scale, new_x, new_y])

# 新レイアウト用: カード（左/右）の保存。
# card に bind されている rect について、StoryScene.portrait_log から最も新しい
# 同一 rect のエントリを探し、その edit_source_id（"ファイル:行"）を直接更新する。
# これによりバトル編集と同じく呼び出し行ピンポイント保存ができ、源ファイルも
# 各エントリが持つため _story_edit_source_file のハードコード章マッピングに
# 依存しない（プロローグ以外の章でも動く）。edit_source_id が空のときだけ、
# 旧 portrait_id + ファイル名出現回数マッチングへフォールバックする。
# ストーリー編集の保存ヘルパ: lines[li] から始まる set_portrait/appear/show ブロックの
# scale/position を new 値へ更新する。PackedStringArray は値渡しのため、更新後の配列を返す。
# 戻り値: {"lines": PackedStringArray, "changed": bool, "block_end": int, "scale_key": String}
func _story_edit_apply_scale_pos_to_block(lines: PackedStringArray, li: int, new_scale: float, new_x: int, new_y: int) -> Dictionary:
	# ガード: 開始行が set_portrait/appear/show でなければ何もしない。
	# 過去に band 行へ scale/position を誤挿入する事故痕跡があったため、入口でブロック。
	if li < 0 or li >= lines.size():
		return {"lines": lines, "changed": false, "block_end": li, "scale_key": "scale", "rejected": "out_of_range"}
	var head: String = lines[li]
	var is_portrait_call: bool = (".set_portrait(" in head) or (".appear(" in head) or (".show(" in head)
	if not is_portrait_call:
		return {"lines": lines, "changed": false, "block_end": li, "scale_key": "scale", "rejected": "not_portrait_call"}
	var block_end: int = _story_edit_find_call_block_end(lines, li)
	# appear() なら "portrait_scale"、それ以外（set_portrait）は "scale" を使う
	var scale_key: String = "portrait_scale" if "appear(" in lines[li] else "scale"
	var has_scale_key := false
	var has_pos_key := false
	for j0 in range(li, block_end + 1):
		if ('"%s"' % scale_key) in lines[j0]:
			has_scale_key = true
		if '"scale"' in lines[j0] and scale_key == "portrait_scale":
			# appear() なのに "scale" を持っているケース（手書き混在）。fallback で "scale" を使う
			scale_key = "scale"
			has_scale_key = true
		if '"position"' in lines[j0]:
			has_pos_key = true
	var changed_any := false
	# 既存キーがあれば置換
	if has_scale_key or has_pos_key:
		for j in range(li, block_end + 1):
			var line_j: String = lines[j]
			var orig: String = line_j
			if ('"%s"' % scale_key) in line_j:
				var r_ps := RegEx.new()
				r_ps.compile('"%s":\\s*[\\d.]+' % scale_key)
				line_j = r_ps.sub(line_j, '"%s": %.2f' % [scale_key, new_scale])
			if '"position"' in line_j:
				line_j = _battle_edit_pos_regex().sub(line_j, '"position": [%d, %d]' % [new_x, new_y])
			if line_j != orig:
				lines[j] = line_j
				changed_any = true
	# 不足キーは追加する（dict があれば末尾へ、無ければ dict を新規引数として挿入）
	if not has_scale_key or not has_pos_key:
		var dict_loc: Dictionary = _story_edit_find_dict_close(lines, li, block_end)
		var dict_end_li: int = dict_loc.get("li", -1)
		var dict_end_col: int = dict_loc.get("col", -1)
		var insert_scale: bool = not has_scale_key
		var insert_pos: bool = not has_pos_key
		if dict_end_li >= 0:
			var ln: String = lines[dict_end_li]
			var before: String = ln.substr(0, dict_end_col)
			var last_ch: String = _story_edit_dict_last_char(lines, dict_end_li, dict_end_col)
			var need_comma: bool = not (last_ch == "{" or last_ch == "," or last_ch == "")
			var parts: String = ""
			if insert_scale:
				parts += '"%s": %.2f' % [scale_key, new_scale]
			if insert_pos:
				if not parts.is_empty(): parts += ", "
				parts += '"position": [%d, %d]' % [new_x, new_y]
			if not parts.is_empty():
				if need_comma:
					parts = ", " + parts
				lines[dict_end_li] = before + parts + ln.substr(dict_end_col)
				changed_any = true
		else:
			var ln2: String = lines[block_end]
			var paren_col: int = ln2.rfind(")")
			if paren_col >= 0:
				var dict_parts: String = ""
				if insert_scale:
					dict_parts += '"%s": %.2f' % [scale_key, new_scale]
				if insert_pos:
					if not dict_parts.is_empty(): dict_parts += ", "
					dict_parts += '"position": [%d, %d]' % [new_x, new_y]
				lines[block_end] = ln2.substr(0, paren_col) + ', {' + dict_parts + '}' + ln2.substr(paren_col)
				changed_any = true
	return {"lines": lines, "changed": changed_any, "block_end": block_end, "scale_key": scale_key}

# lines 全体から、img_path を参照する set_portrait/appear/show ブロックの開始行(0始まり)を返す。
# コメント行(#始まり)はスキップする。
func _story_edit_blocks_for_image(lines: PackedStringArray, img_path: String) -> Array:
	var starts: Array = []
	var i := 0
	while i < lines.size():
		var ln: String = lines[i]
		var is_call: bool = (".set_portrait(" in ln) or (".appear(" in ln) or (".show(" in ln)
		if is_call and not ln.strip_edges().begins_with("#"):
			var be: int = _story_edit_find_call_block_end(lines, i)
			var found := false
			for j in range(i, be + 1):
				if img_path in lines[j]:
					found = true
					break
			if found:
				starts.append(i)
			i = be + 1
		else:
			i += 1
	return starts

# レジストリ(PortraitLayout.gd)の該当画像の scale/position を書き換える。
# 立ち絵の scale/position はレジストリが唯一の真実源なので、登録済み画像の保存は
# ここだけで完結する（ソース章ファイルは触らない）。成功すれば true。
func _save_portrait_layout(img_path: String, new_scale: float, new_x: int, new_y: int) -> bool:
	var layout_path := "res://story/PortraitLayout.gd"
	var abs_path := ProjectSettings.globalize_path(layout_path)
	var f := FileAccess.open(abs_path, FileAccess.READ)
	if not f:
		return false
	var lines: PackedStringArray = f.get_as_text().split("\n")
	f.close()
	var key := '"' + img_path + '"'
	var hit := -1
	for i in range(lines.size()):
		if key in lines[i]:
			hit = i
			break
	var new_line := '\t%s: {"scale": %s, "position": [%d, %d]},' % [key, _trim_num(new_scale), new_x, new_y]
	if hit >= 0:
		lines[hit] = new_line
	else:
		# 未登録 → LAYOUT 辞書の閉じ "}" の直前に挿入
		var insert_at := -1
		for i in range(lines.size()):
			if lines[i].strip_edges() == "}":
				insert_at = i
				break
		if insert_at < 0:
			return false
		lines.insert(insert_at, new_line)
	var wf := FileAccess.open(abs_path, FileAccess.WRITE)
	if not wf:
		return false
	wf.store_string("\n".join(lines))
	wf.close()
	return true

# 0.50 -> "0.5"、0.53 -> "0.53" のように末尾ゼロを落とした数値文字列を返す
func _trim_num(v: float) -> String:
	var s := "%.2f" % v
	if "." in s:
		s = s.rstrip("0").rstrip(".")
	return s

func _save_story_edit_card(card: PanelContainer, entries: Array, _idx: int):
	var info: Label = card.find_child("InfoLabel", true, false)
	if not info:
		return
	var bound_side: String = card.get_meta("bound_side", "")
	if bound_side.is_empty():
		info.text = "[保存NG] このカードに立ち絵がない"
		return
	var bound_rect = card.get_meta("bound_rect", null)
	if not is_instance_valid(bound_rect):
		info.text = "[保存NG] 立ち絵の参照が無効"
		return
	if not story_scene_instance:
		info.text = "[保存NG] story_scene なし"
		return
	var sl := _get_edit_sliders(card)
	if sl.is_empty():
		info.text = "[保存NG] スライダーなし"
		return
	var new_scale: float = sl.scale.value
	var new_x: int = int(sl.x.value)
	var new_y: int = int(sl.y.value)

	# 画像差し替えモード（ピッカーで新しい画像を選んだが保存していない状態）
	var pending_path: String = card.get_meta("pending_portrait_path", "") if card.has_meta("pending_portrait_path") else ""
	var is_image_swap: bool = not pending_path.is_empty()

	# portrait_log から最後の bound_rect 向けエントリを取得。
	# 通常は視覚上の bound_rect.texture と一致するエントリだけを許可する（band の側面上書きで
	# 別画像の行を誤書き換えする事故を防ぐため）。画像差し替えモードでは bound_rect.texture が
	# 新画像（履歴に未記録）なので、texture 一致は要求せず rect 一致だけで last_entry を決める。
	var plog: Array = story_scene_instance.portrait_log if "portrait_log" in story_scene_instance else []
	var displayed_tex: Texture2D = bound_rect.texture
	var displayed_tex_path: String = ""
	if displayed_tex and displayed_tex.resource_path:
		displayed_tex_path = displayed_tex.resource_path
	var last_entry: Dictionary = {}
	for i in range(plog.size() - 1, -1, -1):
		var e = plog[i]
		if e.get("rect") != bound_rect:
			continue
		if is_image_swap:
			# 旧画像のエントリを掴む（履歴側は旧パス、bound_rect.texture は新画像）
			last_entry = e
			break
		# 通常: texture 一致を検証
		var e_tex = e.get("texture")
		var e_path: String = e.get("texture_path", "")
		var ok_tex: bool = (e_tex != null and displayed_tex != null and e_tex == displayed_tex)
		var ok_path: bool = (not e_path.is_empty() and e_path == displayed_tex_path)
		if ok_tex or ok_path:
			last_entry = e
			break
	if last_entry.is_empty():
		if is_image_swap:
			info.text = "[保存NG] 立ち絵履歴に該当エントリなし（差し替え先不明）"
		else:
			info.text = "[保存NG] 表示中の画像と履歴が食い違う（band で側面上書き等の可能性）"
			print("[STORY_EDIT][NG] bound_rect.tex='%s' に一致する portrait_log エントリなし" % displayed_tex_path)
		return

	var src_id: String = last_entry.get("edit_source_id", "")

	# レジストリ経路: 編集中の画像が PortraitLayout に登録済みなら、scale/position は
	# レジストリへ保存して完結する（章ソースには scale/position を書かない方針）。
	# 画像差し替え（pending）は別処理なので除外。flip はソース行に残すため後段に委ねず、
	# レジストリ保存時は flip 変更があれば src 行も更新する。
	var reg_img: String = last_entry.get("texture_path", "")
	if not is_image_swap and not reg_img.is_empty() and not PortraitLayoutDB.get_layout(reg_img).is_empty():
		if _save_portrait_layout(reg_img, new_scale, new_x, new_y):
			PortraitLayoutDB.set_runtime(reg_img, new_scale, new_x, new_y)
			_apply_save_to_log_entry(last_entry, new_scale, new_x, new_y)
			# レジストリは画像1つ=1値なので、同じ画像を使う全シーンへ自動反映される。
			# in-memory の ShowCharacter コマンドにも反映（◀/▶ 再生整合）。
			for cmd in entries:
				if cmd is StoryCommands.ShowCharacter and ("portrait_id" in cmd) and cmd.portrait_id == reg_img:
					cmd.portrait_scale = new_scale
					cmd.position = Vector2(new_x, new_y)
					cmd.position_mode = "offset"
			info.text = "[保存] PortraitLayout: %s (scale=%s pos=[%d,%d])" % [reg_img.get_file(), _trim_num(new_scale), new_x, new_y]
			print("[STORY_EDIT] SAVED registry %s scale=%.2f pos=[%d,%d]" % [reg_img, new_scale, new_x, new_y])
			return
		else:
			info.text = "[保存NG] PortraitLayout 書き込み失敗"
			return

	# edit_source_id 経路: ファイル:行 を直接更新
	if not src_id.is_empty() and (":" in src_id):
		var colon: int = src_id.rfind(":")
		var src_file: String = src_id.substr(0, colon)
		var line_no: int = int(src_id.substr(colon + 1))
		var abs_path0: String = ProjectSettings.globalize_path(src_file)
		var f0 := FileAccess.open(abs_path0, FileAccess.READ)
		if not f0:
			info.text = "[保存NG] ファイルを開けない: %s" % src_file
			return
		var lines0: PackedStringArray = f0.get_as_text().split("\n")
		f0.close()
		var li: int = line_no - 1
		if li < 0 or li >= lines0.size():
			info.text = "[保存NG] 行番号が範囲外: %d" % line_no
			return
		# 編集対象のブロックを更新（呼び出しが複数行に渡る appear も括弧バランスで検出）
		var prim: Dictionary = _story_edit_apply_scale_pos_to_block(lines0, li, new_scale, new_x, new_y)
		lines0 = prim["lines"]
		var changed_any: bool = prim["changed"]
		var block_end: int = prim["block_end"]
		var scale_key: String = prim["scale_key"]
		# 画像差し替えモード: ブロック内の旧パス文字列を新パスへ置換する。
		# 生パス記述（"res://..."）の章のみ対象。定数参照（HERO_NORMAL 等）の章は
		# パス文字列が現れないため置換が起きず、ここで NG にする。
		var img_path: String = last_entry.get("texture_path", "")
		var path_replaced: bool = false
		if is_image_swap:
			if img_path.is_empty():
				info.text = "[保存NG] 旧画像パスが取れない"
				return
			var quoted_old: String = '"' + img_path + '"'
			var quoted_new: String = '"' + pending_path + '"'
			for j in range(li, block_end + 1):
				if quoted_old in lines0[j]:
					lines0[j] = lines0[j].replace(quoted_old, quoted_new)
					path_replaced = true
					changed_any = true
					break
			if not path_replaced:
				info.text = "[保存NG] %s 行%d-%d に旧パスの文字列が無い（定数参照?）" % [src_file.get_file(), line_no, block_end + 1]
				return
		# --- 反転 (flip_h) の差分検出と書き込み ---
		# bound_rect.flip_h は反転ボタンで直接トグルされる。履歴と比較して差があれば
		# 対象ブロックの "flip" キーを書き換える。波及はしない（per-line）。
		var current_flip: bool = bound_rect.flip_h
		var logged_flip: bool = last_entry.get("flip_h", false)
		var flip_changed: bool = current_flip != logged_flip
		var new_flip_val: int = 1 if current_flip else 0
		if flip_changed:
			var flip_found_in_block: bool = false
			for j in range(li, block_end + 1):
				var line_j: String = lines0[j]
				if '"flip"' in line_j:
					var r_flip := RegEx.new()
					r_flip.compile('"flip"\\s*:\\s*[01]')
					var new_line: String = r_flip.sub(line_j, '"flip": %d' % new_flip_val)
					if new_line != line_j:
						lines0[j] = new_line
						changed_any = true
					flip_found_in_block = true
					break
			if not flip_found_in_block:
				# dict 末尾に "flip": N を挿入（scale/position の挿入ロジックと同じ）
				var dict_loc_f: Dictionary = _story_edit_find_dict_close(lines0, li, block_end)
				var dict_end_li_f: int = dict_loc_f.get("li", -1)
				var dict_end_col_f: int = dict_loc_f.get("col", -1)
				if dict_end_li_f >= 0:
					var ln_f: String = lines0[dict_end_li_f]
					var before_f: String = ln_f.substr(0, dict_end_col_f)
					var last_ch_f: String = _story_edit_dict_last_char(lines0, dict_end_li_f, dict_end_col_f)
					var need_comma_f: bool = not (last_ch_f == "{" or last_ch_f == "," or last_ch_f == "")
					var insert_str: String = '"flip": %d' % new_flip_val
					if need_comma_f:
						insert_str = ", " + insert_str
					lines0[dict_end_li_f] = before_f + insert_str + ln_f.substr(dict_end_col_f)
					changed_any = true
		if not changed_any:
			# 差分が無い = 既に目的の値が入っている（保存済み）か、本当に書けなかったか。
			var _bt: String = "\n".join(lines0.slice(li, block_end + 1))
			var _want_scale: String = '"%s": %.2f' % [scale_key, new_scale]
			var _want_pos: String = '"position": [%d, %d]' % [new_x, new_y]
			if not ((_want_scale in _bt) and (_want_pos in _bt)):
				info.text = "[保存NG] %s 行%d-%d を更新できない" % [src_file.get_file(), line_no, block_end + 1]
				print("[STORY_EDIT][NG] block in %s:%d-%d:" % [src_file, line_no, block_end + 1])
				for j_dbg in range(li, block_end + 1):
					if j_dbg >= 0 and j_dbg < lines0.size():
						print("[STORY_EDIT][NG]   %d| %s" % [j_dbg + 1, lines0[j_dbg]])
				return
			# else: 既に目的値（成功扱い）。波及は下で行う。
		# --- 同一画像への波及（ストーリー編集・保存時のみ）---
		# 同じ画像を使う他の set_portrait/appear/show を同じ scale/position へ揃える。
		# 画像差し替え時は意味が変わるのでスキップ（新旧で別画像）。
		var propagated := 0
		if not is_image_swap and not img_path.is_empty():
			for bi in _story_edit_blocks_for_image(lines0, img_path):
				if bi == li:
					continue
				var rp: Dictionary = _story_edit_apply_scale_pos_to_block(lines0, bi, new_scale, new_x, new_y)
				lines0 = rp["lines"]
				if rp["changed"]:
					propagated += 1
		if changed_any or propagated > 0:
			var wf0 := FileAccess.open(abs_path0, FileAccess.WRITE)
			if not wf0:
				info.text = "[保存NG] 書き込み不可"
				return
			wf0.store_string("\n".join(lines0))
			wf0.close()
		# in-memory にも反映:
		# (a) 立ち絵履歴エントリを更新（再描画整合）。画像差し替え時は texture_path/texture も更新。
		_apply_save_to_log_entry(last_entry, new_scale, new_x, new_y)
		if is_image_swap:
			last_entry["texture_path"] = pending_path
			var new_tex = load(pending_path)
			if new_tex:
				last_entry["texture"] = new_tex
		# (b) ShowCharacter コマンドの portrait_scale / position / portrait_id / flip を上書き。
		#     画像差し替え時は src_id 一致の1コマンドだけ更新（他の同一画像は触らない）。
		#     通常時は scale/pos は同じ画像を使う全コマンドへ波及、flip は primary のみ。
		if flip_changed:
			last_entry["flip_h"] = current_flip
		for cmd in entries:
			if not (cmd is StoryCommands.ShowCharacter):
				continue
			var is_primary: bool = ("edit_source_id" in cmd) and cmd.edit_source_id == src_id
			var match_cmd: bool = is_primary
			if not match_cmd and not is_image_swap and not img_path.is_empty() and ("portrait_id" in cmd):
				match_cmd = (cmd.portrait_id == img_path)
			if match_cmd:
				cmd.portrait_scale = new_scale
				cmd.position = Vector2(new_x, new_y)
				cmd.position_mode = "offset"
				# flip は primary のみ更新（波及しない、per-line）
				if flip_changed and is_primary:
					cmd.flip = new_flip_val
				if is_image_swap:
					cmd.portrait_id = pending_path
					break  # 差し替え時は primary 1コマンドのみ
		var flip_note: String = (" 反転%s" % ("ON" if current_flip else "OFF")) if flip_changed else ""
		if is_image_swap:
			# pending を消費。タイトルは現在の rect 状態に合わせて再構築。
			card.remove_meta("pending_portrait_path")
			var title_lbl: Label = card.find_child("Title", true, false)
			if title_lbl:
				var fm: String = "↔ " if current_flip else ""
				title_lbl.text = "[%s] %s%s" % [bound_side, fm, pending_path.get_file()]
			info.text = "[保存] %s 行%d (画像差し替え: %s%s)" % [src_file.get_file(), line_no, pending_path.get_file(), flip_note]
			print("[STORY_EDIT] SAVED %s:%d (%s) image swap -> %s flip=%s" % [src_file.get_file(), line_no, bound_side, pending_path, current_flip])
		else:
			var extra: String = "（+%d箇所）" % propagated if propagated > 0 else ""
			info.text = "[保存] %s 行%d%s%s" % [src_file.get_file(), line_no, extra, flip_note]
			print("[STORY_EDIT] SAVED %s:%d (%s) scale=%.2f pos=[%d,%d] propagated=%d flip_changed=%s" % [src_file.get_file(), line_no, bound_side, new_scale, new_x, new_y, propagated, flip_changed])
		return

	# フォールバック: 章マッピングが設定されていれば portrait_id ベースで保存
	if _story_edit_source_file.is_empty():
		info.text = "[保存NG] edit_source_id 不在 + 章マッピング未登録"
		return
	var portrait_id_filename: String = last_entry.get("texture_path", "").get_file()
	if portrait_id_filename.is_empty():
		info.text = "[保存NG] texture_path 未取得"
		return
	var abs_path: String = ProjectSettings.globalize_path(_story_edit_source_file)
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if not file:
		info.text = "[保存NG] ファイルを開けない: %s" % _story_edit_source_file
		return
	var lines: PackedStringArray = file.get_as_text().split("\n")
	file.close()
	var matches: Array = []
	for i in range(lines.size()):
		if portrait_id_filename in lines[i] and '"scale"' in lines[i]:
			matches.append(i)
	if matches.is_empty():
		info.text = "[保存NG] %s を含む行なし" % portrait_id_filename
		return
	# ヒューリスティックに最初のヒットを更新（fallback の精度は低い）
	var found_line: int = matches[0]
	var line: String = lines[found_line]
	line = _battle_edit_scale_regex().sub(line, '"scale": %.2f' % new_scale)
	if '"position"' in line:
		line = _battle_edit_pos_regex().sub(line, '"position": [%d, %d]' % [new_x, new_y])
	lines[found_line] = line
	var wf := FileAccess.open(abs_path, FileAccess.WRITE)
	if not wf:
		info.text = "[保存NG] 書き込み不可"
		return
	wf.store_string("\n".join(lines))
	wf.close()
	_apply_save_to_log_entry(last_entry, new_scale, new_x, new_y)
	info.text = "[保存] %s 行%d（fb）" % [_story_edit_source_file.get_file(), found_line + 1]
	print("[STORY_EDIT] SAVED (fallback) %s:%d (%s)" % [_story_edit_source_file.get_file(), found_line + 1, bound_side])

# 編集モード用: ストーリー章スクリプトを全て強制再パースし、story_script の
# シーケンスを最新ソースで上書き再登録する。これで「保存→閉じて開き直し」しても
# preload キャッシュのまま古いコードが動くことを防ぐ。
const _STORY_CHAPTER_PATHS := [
	"res://story/chapters/PrologueChapter.gd",
	"res://story/chapters/Stage1Chapter.gd",
	"res://story/chapters/Stage2Chapter.gd",
	"res://story/chapters/Stage3Chapter.gd",
	"res://story/chapters/Stage4Chapter.gd",
	"res://story/chapters/Stage5Chapter.gd",
	"res://story/chapters/Stage6Chapter.gd",
	"res://story/chapters/Stage7Chapter.gd",
	"res://story/chapters/Subevent3Chapter.gd",
	"res://story/chapters/Subevent4Chapter.gd",
]

func _force_reload_story_chapters() -> void:
	if not story_script:
		return
	StoryCommands.editor_capture = true  # 章再パース中に edit_source_id を記録させる
	for path in _STORY_CHAPTER_PATHS:
		var fresh: GDScript = _load_script_fresh(path)
		if not fresh:
			continue
		var instance = fresh.new()
		if instance and story_script.has_method("_register_chapter"):
			story_script._register_chapter(instance)

# portrait_log のエントリのスケール/位置を保存値で更新（in-memory 整合用）
func _apply_save_to_log_entry(entry: Dictionary, new_scale: float, _new_x: int, _new_y: int):
	entry["scale"] = new_scale
	# position は画面座標なので、entry["position"] は再計算が必要だが、
	# 編集中の rect はスライダー操作で既に正しい位置にあるためそこから取り直す。
	var rect: TextureRect = entry.get("rect")
	if is_instance_valid(rect):
		entry["position"] = rect.position

# dict の閉じ `}`（end_li, end_col）の直前にある最後の非空白文字を、行をまたいで
# 後方走査して返す（区切りカンマの要否判定に使う）。見つからなければ "" を返す。
func _story_edit_dict_last_char(file_lines: PackedStringArray, end_li: int, end_col: int) -> String:
	var li: int = end_li
	var col: int = end_col - 1
	while li >= 0:
		var s: String = file_lines[li]
		if li != end_li:
			col = s.length() - 1
		while col >= 0:
			var ch: String = s[col]
			if ch != " " and ch != "\t":
				return ch
			col -= 1
		li -= 1
	return ""

# 呼び出しブロック内の dict の閉じ `}` の位置を返す。{"li": int, "col": int}
# dict が見つからない場合は {"li": -1, "col": -1} を返す。
func _story_edit_find_dict_close(file_lines: PackedStringArray, start_li: int, end_li: int) -> Dictionary:
	var depth: int = 0
	var started: bool = false
	var in_str := false
	var str_ch := ""
	for j in range(start_li, end_li + 1):
		var s: String = file_lines[j]
		var k := 0
		while k < s.length():
			var c: String = s[k]
			if in_str:
				if c == "\\" and k + 1 < s.length():
					k += 2
					continue
				if c == str_ch:
					in_str = false
			else:
				if c == '"' or c == "'":
					in_str = true
					str_ch = c
				elif c == "{":
					depth += 1
					started = true
				elif c == "}":
					depth -= 1
					if started and depth == 0:
						return {"li": j, "col": k}
			k += 1
	return {"li": -1, "col": -1}

# 呼び出しの開始行（start_li）から、括弧バランスを取りつつ対応する `)` を含む
# 終了行までを返す。文字列リテラル中の括弧は無視する。複数行 dict 引数の
# 範囲特定に使う（hero.appear({\n ... \n}) の終端行を返す）。
func _story_edit_find_call_block_end(file_lines: PackedStringArray, start_li: int) -> int:
	var depth: int = 0
	var started: bool = false
	for j in range(start_li, file_lines.size()):
		var s: String = file_lines[j]
		var in_str := false
		var str_ch := ""
		var k := 0
		while k < s.length():
			var c: String = s[k]
			if in_str:
				if c == "\\" and k + 1 < s.length():
					k += 2
					continue
				if c == str_ch:
					in_str = false
			else:
				if c == '"' or c == "'":
					in_str = true
					str_ch = c
				elif c == "(":
					depth += 1
					started = true
				elif c == ")":
					depth -= 1
					if started and depth == 0:
						return j
			k += 1
	return file_lines.size() - 1

func _story_edit_save_current(entries: Array, idx: int, edit_panel: PanelContainer):
	var e = entries[idx]
	if not (e is StoryCommands.ShowCharacter):
		print("[STORY_EDIT] Current command is not ShowCharacter, cannot save")
		return
	if _story_edit_source_file.is_empty():
		print("[STORY_EDIT] No source file set")
		return

	var sl := _get_edit_sliders(edit_panel)
	if sl.is_empty():
		return

	var new_scale: float = sl.scale.value
	var new_x: int = int(sl.x.value)
	var new_y: int = int(sl.y.value)

	# 1. Update command object (session)
	e.portrait_scale = new_scale
	e.position = Vector2(new_x, new_y)
	e.position_mode = "offset"

	# 2. Save to file
	var portrait_id: String = e.portrait_id
	if portrait_id.is_empty():
		print("[STORY_EDIT] No portrait_id on command, cannot find line in source")
		return

	# Find the line in source file that contains this portrait path
	var abs_path: String = ProjectSettings.globalize_path(_story_edit_source_file)
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if not file:
		print("[STORY_EDIT] Cannot open file: %s" % abs_path)
		return
	var lines: PackedStringArray = file.get_as_text().split("\n")
	file.close()

	# Search for the line with this portrait
	var portrait_filename: String = portrait_id.get_file()
	var found_line := -1
	for i in range(lines.size()):
		if portrait_filename in lines[i] and ("set_portrait" in lines[i] or "portrait" in lines[i]):
			# Check if this is a set_portrait or appear with this portrait
			if '"scale"' in lines[i] or '"portrait_scale"' in lines[i]:
				found_line = i
				# Don't break — we want the last match up to current command
				# Actually we need to match the right occurrence

	# Better approach: find all lines with this portrait and pick by order
	var matches: Array = []
	for i in range(lines.size()):
		if portrait_filename in lines[i] and '"scale"' in lines[i]:
			matches.append(i)

	if matches.is_empty():
		print("[STORY_EDIT] Could not find line with portrait: %s" % portrait_filename)
		return

	# Count how many ShowCharacter commands before idx use this portrait
	var occurrence := 0
	for i in range(idx + 1):
		var cmd = entries[i]
		if cmd is StoryCommands.ShowCharacter and cmd.portrait_id.get_file() == portrait_filename:
			if i == idx:
				break
			occurrence += 1

	if occurrence >= matches.size():
		occurrence = matches.size() - 1
	found_line = matches[occurrence]

	# Replace scale and position in the line
	var line: String = lines[found_line]
	var regex_scale := RegEx.new()
	regex_scale.compile('"scale":\\s*[\\d.]+')
	line = regex_scale.sub(line, '"scale": %.2f' % new_scale)

	var regex_pos := RegEx.new()
	regex_pos.compile('"position":\\s*\\[[^\\]]*\\]')
	line = regex_pos.sub(line, '"position": [%d, %d]' % [new_x, new_y])

	lines[found_line] = line

	# Write back
	var write_file := FileAccess.open(abs_path, FileAccess.WRITE)
	if not write_file:
		print("[STORY_EDIT] Cannot write file: %s" % abs_path)
		return
	write_file.store_string("\n".join(lines))
	write_file.close()

	print("[STORY_EDIT] SAVED line %d: %s" % [found_line + 1, portrait_filename])
	print('[STORY_EDIT]   "scale": %.2f, "position": [%d, %d]' % [new_scale, new_x, new_y])

# --- イベントバトル編集モード ---

const EVENT_BATTLE_CHAPTERS := [
	# --- チュートリアル ---
	{"id": "prologue_tutorial", "name": "プロローグ チュートリアル", "path": "res://battle/chapters/PrologueBattleChapter.gd", "bg": "res://assets/backgrounds/prologue/bg05_prison_cell.png", "mode": "tutorial"},
	# 冒険者A戦は本編で b.tutorial(Stage1BattleChapter.gd) として起動される固定スクリプト戦
	# （Stage1Chapter.gd 参照）。通常バトル（b.battle）は存在しないため、編集モードも
	# 実ゲームと揃えて tutorial モードで開く。
	{"id": "stage1", "name": "ステージ1 チュートリアル（冒険者A戦）", "path": "res://battle/chapters/Stage1BattleChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_st1_001.png", "mode": "tutorial"},
	# --- イベントバトル ---
	{"id": "prologue", "name": "プロローグ（マチルダ戦）", "path": "res://battle/chapters/PrologueBattleChapter.gd", "bg": "res://assets/backgrounds/prologue/bg05_prison_cell.png", "mode": "battle"},
	{"id": "stage2", "name": "ステージ2（レイラ戦）", "path": "res://battle/chapters/Stage2BattleChapter.gd", "bg": "res://assets/backgrounds/stage2/bg_inn_meeting.png", "mode": "battle"},
	{"id": "stage3", "name": "ステージ3（マグダレナ戦）", "path": "res://battle/chapters/Stage3BattleChapter.gd", "bg": "res://assets/backgrounds/subevent2/bg02_church_interior.png", "mode": "battle"},
	{"id": "stage4", "name": "ステージ4（セレス戦）", "path": "res://battle/chapters/Stage4BattleChapter.gd", "bg": "res://assets/backgrounds/stage4/bg_dojo_third.png", "mode": "battle"},
	{"id": "stage5", "name": "ステージ5（フェリア戦）", "path": "res://battle/chapters/Stage5BattleChapter.gd", "bg": "res://assets/backgrounds/stage5/bg_training_ground.png", "mode": "battle"},
	{"id": "stage6", "name": "ステージ6（王女戦）", "path": "res://battle/chapters/Stage6BattleChapter.gd", "bg": "res://assets/backgrounds/stage6/bg_royal_hall.png", "mode": "battle"},
	{"id": "subevent1_boss", "name": "サブイベント1（ベルカ戦）", "path": "res://battle/chapters/BelkaBattleChapter.gd", "bg": "res://assets/backgrounds/prologue/bg06_prison_arena.png", "mode": "battle"},
	{"id": "subevent2_boss", "name": "サブイベント2（シスター長戦）", "path": "res://battle/chapters/SisterBattleChapter.gd", "bg": "res://assets/backgrounds/subevent2/bg05_church_peep_room.png", "mode": "battle"},
	{"id": "subevent3_fiona", "name": "サブイベント3（フィオナ戦）", "path": "res://battle/chapters/FionaBattleChapter.gd", "bg": "res://assets/backgrounds/subevent3/bg_noble_room.png", "mode": "battle"},
	{"id": "subevent4_recep", "name": "サブイベント4（受付嬢戦）", "path": "res://battle/chapters/ReceptionistBattleChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_st1_001.png", "mode": "battle"},
	# --- ミニゲーム ---
	{"id": "minigame_smoke", "name": "＜ミニゲーム＞スモークテスト", "path": "res://battle/chapters/MinigameSmokeChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_st1_001.png", "mode": "minigame"},
	{"id": "minigame_subevent3", "name": "＜ミニゲーム＞サブイベント3（羞恥の儀）", "path": "res://battle/chapters/Subevent3MinigameChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_st1_001.png", "mode": "minigame"},
	{"id": "minigame_stage2", "name": "＜ミニゲーム＞ST2（レイラ・相手の動揺を指摘せよ）", "path": "res://battle/chapters/Stage2MinigameChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_st1_001.png", "mode": "minigame"},
	{"id": "minigame_stage3", "name": "＜ミニゲーム＞ST3（マグダレナ・書棚で妄想を誘発せよ）", "path": "res://battle/chapters/Stage3MinigameChapter.gd", "bg": "res://assets/backgrounds/subevent2/bg05_church_peep_room.png", "mode": "minigame"},
	{"id": "minigame_stage4", "name": "＜ミニゲーム＞ST4（セレス・強度を合わせて崩せ）", "path": "res://battle/chapters/Stage4MinigameChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_st1_001.png", "mode": "minigame"},
	{"id": "minigame_stage5", "name": "＜ミニゲーム＞ST5（フェリア・距離を詰めて自白を引き出せ）", "path": "res://battle/chapters/Stage5MinigameChapter.gd", "bg": "res://assets/backgrounds/stage1/bg07_st1_001.png", "mode": "minigame"},
]

signal _event_chapter_selected(index: int)

func _on_event_battle_edit_mode():
	jump_menu.visible = false
	await _show_event_chapter_select()

func _show_event_chapter_select():
	for child in jump_list.get_children():
		child.queue_free()
	var back_btn := Button.new()
	back_btn.text = "← 戻る"
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(func():
		_show_edit_menu())
	jump_list.add_child(back_btn)
	var sep := HSeparator.new()
	jump_list.add_child(sep)

	for i in range(EVENT_BATTLE_CHAPTERS.size()):
		var ch_info: Dictionary = EVENT_BATTLE_CHAPTERS[i]
		var btn := Button.new()
		btn.text = ch_info.name
		btn.add_theme_font_size_override("font_size", 20)
		var idx: int = i
		btn.pressed.connect(func(): _event_chapter_selected.emit(idx))
		jump_list.add_child(btn)
	jump_menu.visible = true

	while true:
		var selected_idx: int = await _event_chapter_selected
		jump_menu.visible = false
		await _run_event_battle_edit(EVENT_BATTLE_CHAPTERS[selected_idx])
		# チャプター選択に戻る
		for child2 in jump_list.get_children():
			child2.queue_free()
		var back_btn2 := Button.new()
		back_btn2.text = "← 戻る"
		back_btn2.add_theme_font_size_override("font_size", 20)
		back_btn2.pressed.connect(func():
			_show_edit_menu())
		jump_list.add_child(back_btn2)
		var sep2 := HSeparator.new()
		jump_list.add_child(sep2)
		for i2 in range(EVENT_BATTLE_CHAPTERS.size()):
			var ch_info2: Dictionary = EVENT_BATTLE_CHAPTERS[i2]
			var btn2 := Button.new()
			btn2.text = ch_info2.name
			btn2.add_theme_font_size_override("font_size", 20)
			var idx2: int = i2
			btn2.pressed.connect(func(): _event_chapter_selected.emit(idx2))
			jump_list.add_child(btn2)
		jump_menu.visible = true

func _run_event_battle_edit(ch_info: Dictionary):
	GameState.reset()
	GameState.init_default_inventory()
	GameState.money = 1000

	# 編集中のファイルを反映するためソースから強制再パース（GDScript キャッシュは
	# ResourceLoader.CACHE_MODE_REPLACE だけでは無効化されないため）
	var script_res = _load_script_fresh(ch_info.path)
	if not script_res:
		return
	var chapter = script_res.new()
	var bg_tex = load(ch_info.bg) if not ch_info.bg.is_empty() else null

	# スライダーパネル作成
	var edit_panel := _create_edit_overlay({"name": ch_info.name})
	add_child(edit_panel)

	# バトル開始
	var event_battle = battle_scene_scene.instantiate()
	add_child(event_battle)
	event_battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not story_script:
		story_script = DefaultStoryScript.new()
	event_battle.setup(story_script.get_cast(), bg_tex, GameState.inventory)
	event_battle.force_result_mode = true
	# 編集モードのモード判定: ch_info の "mode" を厳密に参照（自動判定は廃止）
	#   "minigame"  → ミニゲーム
	#   "tutorial"  → チュートリアル
	#   "battle" 等 → 通常バトル
	var entry_mode: String = ch_info.get("mode", "battle")
	var use_minigame: bool = entry_mode == "minigame"
	var use_tutorial: bool = entry_mode == "tutorial"
	event_battle.start_battle(chapter, use_tutorial, use_minigame)
	move_child(edit_panel, get_child_count() - 1)
	edit_panel.set_meta("chapter_path", ch_info.path)
	_connect_edit_to_battle(edit_panel, event_battle, {})

	# 戻るボタンで battle_finished をエミットして終了
	var back_btn: Button = edit_panel.find_child("EditBackButton", true, false)
	if back_btn:
		back_btn.pressed.connect(func():
			if is_instance_valid(event_battle):
				event_battle.battle_finished.emit("abort"))

	var _result: String = await event_battle.battle_finished
	_battle_edit_active = false
	_battle_edit_target_rect = null
	_battle_edit_panel = null
	_battle_edit_advancing = false
	_battle_edit_history_idx = -1
	_battle_edit_last_log_size = 0
	event_battle.queue_free()
	edit_panel.queue_free()

# --- 中断（Continue）からミニゲーム単体起動 ---
func _run_minigame_standalone(minigame_id: String):
	var entry: Dictionary = {}
	for info in EVENT_BATTLE_CHAPTERS:
		if info.get("id", "") == minigame_id and info.get("mode", "") == "minigame":
			entry = info
			break
	if entry.is_empty():
		push_error("Minigame not found: %s" % minigame_id)
		return

	var script_res = _load_script_fresh(entry.path)
	if not script_res:
		push_error("Failed to load minigame chapter: %s" % entry.path)
		return
	var chapter = script_res.new()
	var bg_tex = load(entry.bg) if not entry.bg.is_empty() else null

	var mg_battle = battle_scene_scene.instantiate()
	add_child(mg_battle)
	mg_battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not story_script:
		story_script = DefaultStoryScript.new()
	mg_battle.setup(story_script.get_cast(), bg_tex, GameState.inventory)
	mg_battle.start_battle(chapter, false, true)
	var result: String = await mg_battle.battle_finished
	mg_battle.queue_free()

	# 敗北時：chapter の get_lose_redirect に従ってロストシーケンスを再生
	# + 共通ロスト・ナレーション。standalone でも本筋と同じ挙動を提供。
	if result == "lose":
		var lose_behavior: String = chapter.get_lose_behavior()
		if lose_behavior == "redirect":
			var redirect: Dictionary = chapter.get_lose_redirect()
			var rtype: String = redirect.get("type", "")
			if rtype == "story_sequence_then_guild_home":
				_create_story_scene()
				var seq_id: String = redirect.get("sequence_id", "")
				if seq_id != "":
					await _play_scene(seq_id)
				# standalone では cmd オブジェクトがないので、デフォルトで共通ナレを再生
				var fake_cmd: Dictionary = {
					"chapter": chapter,
					"lose_opponent": "",
					"lose_patterns": [],
				}
				await _play_common_lose_narration_dict(fake_cmd)
				if story_scene_instance:
					story_scene_instance.queue_free()
					story_scene_instance = null

# Dictionary 版ヘルパー（cmd が Battle インスタンスではなく Dictionary の場合）
func _play_common_lose_narration_dict(cmd: Dictionary) -> void:
	var SatoshiLoseNarrationsScript = load("res://battle/SatoshiLoseNarrations.gd")
	if SatoshiLoseNarrationsScript == null:
		return
	var allowed: Array = cmd.get("lose_patterns", [])
	if allowed.is_empty():
		allowed = SatoshiLoseNarrationsScript.ALL_IDS
	if allowed.size() == 1 and String(allowed[0]) == "__skip__":
		return
	var last_id: String = String(GameState.flags.get("last_lose_narration_id", ""))
	var pattern: Dictionary = SatoshiLoseNarrationsScript.pick_random(allowed, last_id)
	GameState.flags["last_lose_narration_id"] = pattern.get("id", "")

	var opponent_name: String = String(cmd.get("lose_opponent", ""))
	if opponent_name == "":
		var ch = cmd.get("chapter", null)
		if ch != null and ch.has_method("get_opponent_name"):
			opponent_name = ch.get_opponent_name()
	if opponent_name == "":
		opponent_name = "相手"

	var rendered_frames: Array = SatoshiLoseNarrationsScript.render_frames(pattern, opponent_name)
	var Cmd = load("res://story/StoryCommands.gd")
	var seq = Cmd.Sequence.new()
	seq.id = "_satoshi_lose_narration"
	for f in rendered_frames:
		var band = Cmd.Band.new()
		band.visible = true
		band.text = String(f[1])
		band.speaker_id = String(f[0])
		band.wait_for_input = true
		seq.entries.append(band)

	if story_scene_instance and story_scene_instance.has_method("play_sequence"):
		await story_scene_instance.play_sequence(seq)

	if pattern.get("outcome", "") == "lose_clothes":
		var cost: int = SatoshiLoseNarrationsScript.REPLACEMENT_COST
		GameState.money = max(0, GameState.money - cost)
