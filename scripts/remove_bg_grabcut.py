#!/usr/bin/env python3
"""Batch background removal using GrabCut (based on ProjectAriel's logic).

Automatically detects white/light backgrounds and table areas,
then runs GrabCut with erode=1, smooth=1 to produce transparent PNGs.
"""

import sys
import glob
import os

import cv2
import numpy as np
from PIL import Image, ImageFilter


def create_auto_mask(img_bgr):
    """Create a user mask that marks background areas (white bg + table).

    White pixels = areas to remove (probable background).
    Black pixels = areas to keep (probable foreground).
    """
    h, w = img_bgr.shape[:2]
    mask = np.zeros((h, w), dtype=np.uint8)

    # 1. Detect white/near-white background
    img_gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    # White background: high brightness, low saturation
    img_hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    # White: S < 30, V > 220
    white_bg = (img_hsv[:, :, 1] < 30) & (img_hsv[:, :, 2] > 220)
    mask[white_bg] = 255

    # 2. Detect light/cream backgrounds (some images have off-white bg)
    light_bg = (img_hsv[:, :, 1] < 40) & (img_hsv[:, :, 2] > 200)
    mask[light_bg] = 255

    # 3. Detect table area (brown/golden colors in lower portion)
    # Table is typically in the bottom 40% of the image
    table_region_start = int(h * 0.55)
    table_region = img_hsv[table_region_start:, :, :]
    # Brown/golden: H=10-30, S>50, V>80
    brown = (
        (table_region[:, :, 0] >= 8) & (table_region[:, :, 0] <= 35) &
        (table_region[:, :, 1] > 50) &
        (table_region[:, :, 2] > 60)
    )
    mask[table_region_start:][brown] = 255

    # 4. Also mark edges/corners as definite background
    border = 5
    mask[:border, :] = 255
    mask[-border:, :] = 255
    mask[:, :border] = 255
    mask[:, -border:] = 255

    return mask


def run_grabcut(img_bgr, user_mask, iterations=5, erode_px=1, smooth_px=1):
    """Run GrabCut segmentation and return foreground mask.

    Based on ProjectAriel's GrabCutService.segment_with_mask().
    """
    h, w = img_bgr.shape[:2]
    painted = user_mask > 128

    if not np.any(painted):
        print("  Warning: empty mask, skipping GrabCut")
        return np.full((h, w), 255, dtype=np.uint8)

    # Find bounding box from painted areas
    rows = np.any(painted, axis=1)
    cols = np.any(painted, axis=0)
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]

    padding = 10
    x_min = max(0, x_min - padding)
    y_min = max(0, y_min - padding)
    x_max = min(w - 1, x_max + padding)
    y_max = min(h - 1, y_max + padding)

    # Build GrabCut initialization mask
    gc_mask = np.full((h, w), cv2.GC_BGD, dtype=np.uint8)
    gc_mask[y_min:y_max + 1, x_min:x_max + 1] = cv2.GC_PR_FGD
    gc_mask[painted] = cv2.GC_PR_BGD

    # Run GrabCut
    bgd_model = np.zeros((1, 65), dtype=np.float64)
    fgd_model = np.zeros((1, 65), dtype=np.float64)
    cv2.grabCut(img_bgr, gc_mask, None, bgd_model, fgd_model,
                iterations, cv2.GC_INIT_WITH_MASK)

    # Build output: foreground = white
    output = np.where(
        (gc_mask == cv2.GC_FGD) | (gc_mask == cv2.GC_PR_FGD),
        255, 0
    ).astype(np.uint8)

    result_image = Image.fromarray(output, mode="L")

    # Erode (boundary shrink)
    if erode_px > 0:
        for _ in range(erode_px):
            result_image = result_image.filter(ImageFilter.MinFilter(3))

    # Smooth (edge blur)
    if smooth_px > 0:
        result_image = result_image.filter(ImageFilter.GaussianBlur(radius=smooth_px))
        arr = np.array(result_image)
        arr = ((arr >= 128) * 255).astype(np.uint8)
        result_image = Image.fromarray(arr, mode="L")

    return np.array(result_image)


def apply_mask_to_image(img_bgr, fg_mask):
    """Apply foreground mask to create transparent PNG."""
    img_rgba = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2BGRA)
    img_rgba[:, :, 3] = fg_mask
    return img_rgba


def process_image(input_path, output_path, erode_px=1, smooth_px=1):
    """Process a single image: detect bg, run GrabCut, save transparent PNG."""
    print(f"  Processing: {os.path.basename(input_path)}")

    img_bgr = cv2.imread(input_path)
    if img_bgr is None:
        print(f"  ERROR: Failed to read {input_path}")
        return False

    # Create automatic background mask
    user_mask = create_auto_mask(img_bgr)

    # Run GrabCut
    fg_mask = run_grabcut(img_bgr, user_mask, erode_px=erode_px, smooth_px=smooth_px)

    # Apply mask
    result = apply_mask_to_image(img_bgr, fg_mask)

    # Save
    cv2.imwrite(output_path, result)
    print(f"  Saved: {os.path.basename(output_path)}")
    return True


def main():
    input_dir = os.path.expanduser(
        "~/Git/OtherRepositories/janken/godot/assets/characters/subevent1_battle"
    )

    files = sorted(glob.glob(os.path.join(input_dir, "belka_battle_*.png")))
    if not files:
        print(f"No belka_battle_*.png files found in {input_dir}")
        sys.exit(1)

    print(f"Found {len(files)} images to process")
    print(f"Settings: erode=1, smooth=1 (GrabCut)")
    print()

    success = 0
    for f in files:
        if process_image(f, f, erode_px=1, smooth_px=1):
            success += 1

    print(f"\nDone: {success}/{len(files)} images processed")


if __name__ == "__main__":
    main()
