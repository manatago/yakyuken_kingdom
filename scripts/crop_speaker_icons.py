#!/usr/bin/env python3
"""Crop face-area from character portraits into speaker icons.

Takes a portrait image and crops a square region near the top (face area),
resizes to 256x256, and saves as a speaker icon.
"""

import os
import sys
from PIL import Image

ASSETS = "/Users/sin/Git/OtherRepositories/janken/godot/assets"
OUT_DIR = os.path.join(ASSETS, "ui", "speakers")

# (出力名, 入力画像相対パス, クロップ位置 "top" / "top-tight")
# top       : 顔が上寄り → 上からwidth分の正方形を中央クロップ
# top-tight : 顔がやや下 → 上から画像の上1/3境界を基点に少し余裕を持って正方形
# top-narrow: 顔がすごく上の細い範囲に集中 → 上部3割以内で収まるように
MAPPING = [
    # --- サトシ系 ---
    ("satoshi_normal.png",     "characters/stage1/char01_st1_001.png",   "top"),
    ("satoshi_nervous.png",    "characters/prologue/char01_pg_043.png",  "top"),  # 驚愕
    ("satoshi_worried.png",    "characters/prologue/char01_pg_038.png",  "top"),  # 興味/怪訝
    ("satoshi_gentle.png",     "characters/prologue/char01_pg_046.png",  "top"),  # 前向き笑顔
    ("satoshi_apologetic.png", "characters/prologue/char01_pg_037.png",  "top"),  # 弱気顔
    # --- フィオナ ---
    ("fiona_default.png",      "characters/subevent3/armor_001.png",     "top"),
    # --- セバス（仮：盗賊ガルドを流用 / 怪しい商人風） ---
    ("sebas_normal.png",       "characters/subevent1/gald_st2_001.png",  "top"),
    ("sebas_frown.png",        "characters/subevent1/gald_st2_002.png",  "top"),
    ("sebas_strict.png",       "characters/subevent1/gald_st2_003.png",  "top"),
    # --- ST2 アサシン・レイラ（格闘家） ---
    ("layla_default.png",      "characters/stage2/layla_001.png",        "top"),
    # --- ST3 シスター・マグダレナ（シスター姉） ---
    ("magdalena_default.png",  "characters/stage3/magdalena_001.png",    "top"),
    # --- ST4 魔法師団長セレス（魔法使い・ロリ） ---
    ("seles_default.png",      "characters/stage4/seles_001.png",        "top"),
    # --- ST5 騎士団長フェリア（金ドリル巻毛） ---
    ("feria_default.png",      "characters/stage5/feria_001.png",        "top"),
]

TARGET_SIZE = 256


def crop_face(src: Image.Image, mode: str) -> Image.Image:
    w, h = src.size
    if mode == "top-narrow":
        # very narrow face at top
        crop_size = min(w, int(h * 0.28))
    elif mode == "top-tight":
        crop_size = min(w, int(h * 0.5))
    else:
        # default "top"
        crop_size = min(w, int(h * 0.40))
    left = (w - crop_size) // 2
    top = 0
    right = left + crop_size
    bottom = crop_size
    return src.crop((left, top, right, bottom))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for out_name, src_rel, mode in MAPPING:
        src_path = os.path.join(ASSETS, src_rel)
        out_path = os.path.join(OUT_DIR, out_name)
        if not os.path.exists(src_path):
            print(f"  SKIP (not found): {src_path}")
            continue
        try:
            img = Image.open(src_path).convert("RGBA")
            cropped = crop_face(img, mode)
            resized = cropped.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
            resized.save(out_path, format="PNG")
            print(f"  OK: {out_name}  <- {src_rel} ({mode})")
        except Exception as e:
            print(f"  FAILED: {out_name} — {e}")


if __name__ == "__main__":
    main()
