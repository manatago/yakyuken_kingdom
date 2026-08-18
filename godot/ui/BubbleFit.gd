extends RefCounted
class_name BubbleFit

# 吹き出しの箱の高さを文字量から求める。
#
# BattleScene から切り出してあるのは、BattleScene.gd が GameState オートロードに
# 依存していて --script 実行では完全コンパイルされず、静的関数を呼べないため
# （定数だけは読めるので気付きにくい）。ここは Font 計算だけで依存が無いので、
# 実機・紙芝居編集のプレビュー・テストのどこからでも同じ式を呼べる。

# BUBBLE_SIDE_ANCHORS の高さを下回らず、画面のこの比率を超えては伸ばさない。
const MAX_HEIGHT_RATIO := 0.62

# ui/SpeechBubble.tscn の BubbleLabel が箱に占める割合
const LABEL_W_RATIO := 0.92   # 横 4%〜96%
const LABEL_H_RATIO := 0.80   # 縦 10%〜90%

# text を font/font_size で box_w 幅に流し込んだときに必要な箱の高さ(px)。
# min_h / max_h でクランプする。
static func box_height(text: String, font: Font, font_size: int, box_w: float, min_h: float, max_h: float) -> float:
	if font == null or box_w <= 0.0 or font_size <= 0:
		return min_h
	var label_w: float = box_w * LABEL_W_RATIO
	var text_h: float = font.get_multiline_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, label_w, font_size).y
	return clampf(text_h / LABEL_H_RATIO, min_h, max_h)
