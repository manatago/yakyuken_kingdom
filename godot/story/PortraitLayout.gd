extends RefCounted

# 立ち絵の scale / position を画像パス単位で一元管理するレジストリ。
# set_portrait/appear/show 側では scale/position を書かず、ここを唯一の真実源とする。
# （flip は向きの都合でシーン毎に変わるため、各呼び出し側の引数に残す）
# 編集モードの保存先もこのファイル。

const LAYOUT := {
	"res://assets/characters/main/matilda/clothed/matilda_clothed_001.png": {"scale": 0.9, "position": [0, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_002.png": {"scale": 0.9, "position": [-100, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_003.png": {"scale": 0.9, "position": [-80, 0]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_004.png": {"scale": 0.9, "position": [-200, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_005.png": {"scale": 0.9, "position": [-100, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_006.png": {"scale": 0.9, "position": [-120, 0]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_007.png": {"scale": 0.9, "position": [-120, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_008.png": {"scale": 0.9, "position": [0, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_009.png": {"scale": 0.9, "position": [0, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_010.png": {"scale": 0.9, "position": [0, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_011.png": {"scale": 0.9, "position": [0, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_012.png": {"scale": 0.9, "position": [0, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_013.png": {"scale": 0.9, "position": [0, 10]},
	"res://assets/characters/main/matilda/clothed/matilda_clothed_014.png": {"scale": 0.9, "position": [-200, 10]},
	"res://assets/characters/main/minori/modern/minori_modern_001.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/minori/modern/minori_modern_002.png": {"scale": 0.5, "position": [0, 100]},
	"res://assets/characters/main/minori/modern/minori_modern_003.png": {"scale": 0.5, "position": [0, 100]},
	"res://assets/characters/main/minori/modern/minori_modern_004.png": {"scale": 0.5, "position": [0, 100]},
	"res://assets/characters/main/minori/modern/minori_modern_005.png": {"scale": 0.5, "position": [0, 100]},
	"res://assets/characters/main/minori/modern/minori_modern_006.png": {"scale": 0.5, "position": [0, 100]},
	"res://assets/characters/main/minori/modern/minori_modern_007.png": {"scale": 0.5, "position": [0, 100]},
	"res://assets/characters/main/minori/modern/minori_modern_008.png": {"scale": 0.5, "position": [0, 100]},
	"res://assets/characters/main/minori/modern/minori_modern_009.png": {"scale": 0.5, "position": [150, 200]},
	"res://assets/characters/main/minori/modern/minori_modern_010.png": {"scale": 0.5, "position": [0, -300]},
	"res://assets/characters/main/receptionist/clothed/receptionist_clothed_001.png": {"scale": 0.45, "position": [0, 0]},
	"res://assets/characters/main/receptionist/clothed/receptionist_clothed_002.png": {"scale": 0.45, "position": [0, 0]},
	"res://assets/characters/main/receptionist/clothed/receptionist_clothed_003.png": {"scale": 0.45, "position": [0, 0]},
	"res://assets/characters/main/receptionist/clothed/receptionist_clothed_004.png": {"scale": 0.45, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_001.png": {"scale": 0.7, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_002.png": {"scale": 0.7, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_003.png": {"scale": 0.49, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_004.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_005.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_006.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_007.png": {"scale": 0.7, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_008.png": {"scale": 0.7, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_009.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_010.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_019.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_024.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_037.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_038.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_049.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_050.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_055.png": {"scale": 0.68, "position": [0, 0]},
	"res://assets/characters/main/satoshi/isekai/satoshi_isekai_082.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/lab/satoshi_lab_001.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/lab/satoshi_lab_002.png": {"scale": 0.5, "position": [0, -10]},
	"res://assets/characters/main/satoshi/lab/satoshi_lab_003.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/lab/satoshi_lab_004.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/lab/satoshi_lab_005.png": {"scale": 1.2, "position": [0, 50]},
	"res://assets/characters/main/satoshi/lab/satoshi_lab_006.png": {"scale": 0.5, "position": [50, -300]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_001.png": {"scale": 1, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_002.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_004.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_005.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_006.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_007.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_008.png": {"scale": 0.5, "position": [25, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_009.png": {"scale": 0.5, "position": [25, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_010.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_011.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_012.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_013.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_014.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_015.png": {"scale": 0.7, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_016.png": {"scale": 0.5, "position": [0, 10]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_017.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/modern/satoshi_modern_018.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_001.png": {"scale": 0.3, "position": [0, -400]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_002.png": {"scale": 0.55, "position": [0, 0]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_003.png": {"scale": 0.55, "position": [0, 0]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_004.png": {"scale": 1, "position": [0, 50]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_005.png": {"scale": 0.6, "position": [0, 60]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_006.png": {"scale": 0.6, "position": [0, 60]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_007.png": {"scale": 0.6, "position": [0, 60]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_008.png": {"scale": 0.6, "position": [0, 60]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_009.png": {"scale": 0.6, "position": [0, 60]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_010.png": {"scale": 1.05, "position": [0, 80]},
	"res://assets/characters/main/satoshi/nude/satoshi_nude_011.png": {"scale": 1.05, "position": [0, 70]},
	"res://assets/characters/mob/guard/default/guard_default_001.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/mob/guard/default/guard_default_002.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/mob/guard/default/guard_default_003.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/mob/guard/default/guard_default_004.png": {"scale": 0.5, "position": [0, 0]},
	"res://assets/characters/mob/passerby_female/default/passerby_female_default_001.png": {"scale": 0.5, "position": [0, 100]},
	"res://assets/characters/mob/passerby_male/default/passerby_male_default_001.png": {"scale": 0.5, "position": [0, 30]},
}

# 編集モードで保存した値の実行時オーバーライド。const LAYOUT は preload 時に固定され
# ファイルを書き換えても実行中メモリには反映されないため、保存時にここへ入れて即反映する。
static var _runtime_override: Dictionary = {}

# 画像パスから {scale, position} を返す。未登録なら {} （呼び出し側がデフォルト処理）。
# 実行時オーバーライドがあればそちらを優先（編集モードでの保存即反映用）。
static func get_layout(image_path: String) -> Dictionary:
	if _runtime_override.has(image_path):
		return _runtime_override[image_path]
	return LAYOUT.get(image_path, {})

# 編集モードの保存時に呼ぶ。メモリ上の値を更新して、再パースなしで即座に表示へ反映する。
static func set_runtime(image_path: String, scale: float, x: int, y: int) -> void:
	_runtime_override[image_path] = {"scale": scale, "position": [x, y]}
