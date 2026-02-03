#!/usr/bin/env python3
"""
キャラクター画像分割スクリプト

char01-skeleton-transparent.png から4つのパーツを切り出す:
- 右腕 (arm_r)
- 頭部 (head)
- 体 (body)
- 左腕 (arm_l)
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
    from scipy import ndimage
except ImportError:
    print("Error: PIL, numpy, scipy が必要です")
    print("  pip install Pillow numpy scipy")
    sys.exit(1)


def find_large_components(img_array, min_pixels=1000):
    """
    連結成分分析で大きなパーツを検出する
    """
    alpha = img_array[:, :, 3]
    mask = alpha > 0  # 完全透明以外はすべて含める

    labeled, num_features = ndimage.label(mask)

    components = []
    for i in range(1, num_features + 1):
        component = labeled == i
        pixel_count = np.sum(component)

        if pixel_count >= min_pixels:
            rows = np.any(component, axis=1)
            cols = np.any(component, axis=0)
            y_indices = np.where(rows)[0]
            x_indices = np.where(cols)[0]

            y_min, y_max = y_indices[0], y_indices[-1]
            x_min, x_max = x_indices[0], x_indices[-1]

            components.append({
                'id': i,
                'x': x_min,
                'y': y_min,
                'width': x_max - x_min + 1,
                'height': y_max - y_min + 1,
                'pixels': pixel_count,
                'center_x': (x_min + x_max) / 2,
                'center_y': (y_min + y_max) / 2,
                'mask': component
            })

    return components


def identify_parts(components, img_width, img_height):
    """
    成分の位置からパーツを識別する
    """
    parts = {}

    # ピクセル数でソートして主要な4成分を取得
    main_components = sorted(components, key=lambda c: c['pixels'], reverse=True)[:4]

    for c in main_components:
        # 位置から推測
        if c['center_x'] < img_width * 0.3:
            part_name = 'arm_r'  # 右腕（画像の左側）
        elif c['center_x'] > img_width * 0.7:
            part_name = 'arm_l'  # 左腕（画像の右側）
        elif c['center_y'] < img_height * 0.4:
            part_name = 'head'   # 頭（画像の上部）
        else:
            part_name = 'body'   # 体（画像の下部）

        if part_name not in parts:
            parts[part_name] = c

    return parts


def extract_part(img, component, img_array, padding=5):
    """
    成分のマスクを適用して、該当パーツのピクセルだけを切り出す
    """
    x = max(0, component['x'] - padding)
    y = max(0, component['y'] - padding)
    x2 = min(img.width, component['x'] + component['width'] + padding)
    y2 = min(img.height, component['y'] + component['height'] + padding)

    # 切り出し領域の画像データをコピー
    cropped_array = img_array[y:y2, x:x2].copy()

    # マスクを切り出し領域に合わせて切り出す
    mask_cropped = component['mask'][y:y2, x:x2]

    # マスク外のピクセルを透明にする
    cropped_array[~mask_cropped, 3] = 0

    return Image.fromarray(cropped_array)


def main():
    # パス設定
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    input_path = project_root / "godot/assets/characters/samples/char01-skeleton-transparent.png"
    output_dir = project_root / "godot/assets/characters/hero"

    # コマンドライン引数でパスを上書き可能
    if len(sys.argv) > 1:
        input_path = Path(sys.argv[1])
    if len(sys.argv) > 2:
        output_dir = Path(sys.argv[2])

    print(f"入力: {input_path}")
    print(f"出力: {output_dir}")

    # 入力画像を読み込み
    if not input_path.exists():
        print(f"Error: 入力ファイルが見つかりません: {input_path}")
        sys.exit(1)

    img = Image.open(input_path).convert('RGBA')
    img_array = np.array(img)

    print(f"画像サイズ: {img.width} x {img.height}")

    # 連結成分分析でパーツを検出
    print("\nパーツを検出中（連結成分分析）...")
    components = find_large_components(img_array, min_pixels=1000)
    print(f"検出された大きな成分数: {len(components)}")

    for c in components:
        print(f"  成分 {c['id']}: x={c['x']}, y={c['y']}, "
              f"w={c['width']}, h={c['height']}, pixels={c['pixels']}")

    # パーツを識別
    parts = identify_parts(components, img.width, img.height)

    if len(parts) < 4:
        print(f"Warning: 4パーツ未満 ({len(parts)}パーツ検出)")

    print(f"\n識別されたパーツ:")
    for name, c in parts.items():
        print(f"  {name}: x={c['x']}, y={c['y']}, "
              f"w={c['width']}, h={c['height']}")

    # 出力ディレクトリを作成
    output_dir.mkdir(parents=True, exist_ok=True)

    # 各パーツを切り出して保存
    print(f"\nパーツを保存中...")
    for name, component in parts.items():
        part_img = extract_part(img, component, img_array, padding=2)
        output_path = output_dir / f"char01_{name}.png"
        part_img.save(output_path, 'PNG')
        print(f"  保存: {output_path} ({part_img.width}x{part_img.height})")

    print("\n完了!")
    print(f"\n出力ファイル:")
    for name in ['body', 'head', 'arm_r', 'arm_l']:
        if name in parts:
            print(f"  - char01_{name}.png")


if __name__ == "__main__":
    main()
