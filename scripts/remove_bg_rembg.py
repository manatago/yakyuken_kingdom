#!/usr/bin/env python3
"""Batch background removal using rembg (AI-based)."""

import glob
import os
from PIL import Image
from rembg import remove

INPUT_DIR = os.path.expanduser(
    "~/JankenImages/thief/backup"
)
OUTPUT_DIR = os.path.expanduser(
    "~/Git/OtherRepositories/janken/godot/assets/characters/subevent1_battle"
)

# Source mapping: belka_battle_NNN.png -> thief_NNN.png
MAPPING = {
    "belka_battle_001.png": "thief_018.png",
    "belka_battle_002.png": "thief_031.png",
    "belka_battle_003.png": "thief_020.png",
    "belka_battle_004.png": "thief_019.png",
    "belka_battle_005.png": "thief_025.png",
    "belka_battle_006.png": "thief_046.png",
    "belka_battle_007.png": "thief_028.png",
    "belka_battle_008.png": "thief_039.png",
    "belka_battle_009.png": "thief_074.png",
    "belka_battle_010.png": "thief_077.png",
    "belka_battle_011.png": "thief_060.png",
    "belka_battle_012.png": "thief_073.png",
}

def main():
    print(f"Processing {len(MAPPING)} images with rembg...")
    print()

    success = 0
    for output_name, source_name in MAPPING.items():
        input_path = os.path.join(INPUT_DIR, source_name)
        output_path = os.path.join(OUTPUT_DIR, output_name)

        if not os.path.exists(input_path):
            print(f"  SKIP: {source_name} not found")
            continue

        print(f"  {source_name} -> {output_name} ...", end=" ", flush=True)

        img = Image.open(input_path)
        result = remove(img)
        result.save(output_path)

        print("OK")
        success += 1

    print(f"\nDone: {success}/{len(MAPPING)} images processed")

if __name__ == "__main__":
    main()
