#!/usr/bin/env python3
"""
緑背景を透明化するスクリプト

char01-skeleton.png の緑背景を検出して透明化する
"""

import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Error: PILとnumpyが必要です")
    print("  pip install Pillow numpy")
    sys.exit(1)


def remove_green_background(img_array, tolerance=60):
    """
    緑背景を透明化する

    緑色の判定: G成分が高く、RとBが低い
    """
    r = img_array[:, :, 0].astype(np.int16)
    g = img_array[:, :, 1].astype(np.int16)
    b = img_array[:, :, 2].astype(np.int16)

    # 緑背景の条件:
    # - G が R より十分大きい
    # - G が B より十分大きい
    # - G がある程度の値を持つ（暗すぎない）
    is_green = (
        (g > r + 20) &  # GがRより20以上大きい
        (g > b + 20) &  # GがBより20以上大きい
        (g > 80)        # Gが80以上
    )

    # 緑色のピクセルを透明にする
    result = img_array.copy()
    result[is_green, 3] = 0

    return result, np.sum(is_green)


def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    input_path = project_root / "godot/assets/characters/samples/char01-skeleton.png"
    output_path = project_root / "godot/assets/characters/samples/char01-skeleton-transparent.png"

    if len(sys.argv) > 1:
        input_path = Path(sys.argv[1])
    if len(sys.argv) > 2:
        output_path = Path(sys.argv[2])

    print(f"入力: {input_path}")
    print(f"出力: {output_path}")

    if not input_path.exists():
        print(f"Error: 入力ファイルが見つかりません: {input_path}")
        sys.exit(1)

    # 画像を読み込み
    img = Image.open(input_path).convert('RGBA')
    img_array = np.array(img)

    print(f"画像サイズ: {img.width} x {img.height}")
    print(f"総ピクセル数: {img.width * img.height}")

    # 緑背景を透明化
    print("\n緑背景を透明化中...")
    result_array, green_count = remove_green_background(img_array)

    print(f"透明化したピクセル数: {green_count}")
    print(f"透明化率: {green_count / (img.width * img.height) * 100:.1f}%")

    # 保存
    result_img = Image.fromarray(result_array)
    result_img.save(output_path, 'PNG')
    print(f"\n保存完了: {output_path}")


if __name__ == "__main__":
    main()
