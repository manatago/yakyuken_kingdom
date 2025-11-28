extends Resource
class_name CharacterData

@export var name: String = "Character"
@export var portrait: Texture2D
@export_multiline var intro_quotes: Array[String] = ["よろしくお願いします"]
@export_multiline var win_quotes: Array[String] = ["やった！", "私の勝ちね"]
@export_multiline var lose_quotes: Array[String] = ["負けちゃった...", "くやしい！"]
@export_multiline var draw_quotes: Array[String] = ["引き分けね", "気が合うわね"]
@export_multiline var game_win_quotes: Array[String] = ["私の完全勝利ね！"]
@export_multiline var game_lose_quotes: Array[String] = ["完敗です...おめでとう"]
