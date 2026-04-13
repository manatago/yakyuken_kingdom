#!/usr/bin/env python3
"""BiRefNet background removal script.

Replicates ProjectAriel's batch background removal with BiRefNet (最高精度).
Same logic as pose-api/app/segment_service.py SegmentationService.segment_mask().

Usage:
    python3 remove_bg_birefnet.py <image_path> [image_path ...]
    python3 remove_bg_birefnet.py --dir <directory>

Parameters (match ProjectAriel defaults):
    erode_px=0, smooth_px=0, threshold=128, close_gaps=0
"""

import argparse
import glob
import io
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from rembg import new_session, remove


def segment_and_apply(
    image_path: str,
    session,
    *,
    erode_px: int = 0,
    smooth_px: int = 0,
    threshold: int = 128,
    close_gaps: int = 0,
) -> Image.Image:
    """Apply background removal using BiRefNet and return RGBA image."""
    with open(image_path, "rb") as f:
        image_bytes = f.read()

    # Generate mask using BiRefNet
    mask_result = remove(image_bytes, session=session, only_mask=True)
    if isinstance(mask_result, bytes):
        mask_image = Image.open(io.BytesIO(mask_result)).convert("L")
    else:
        mask_image = mask_result.convert("L")

    # Binarize at threshold
    mask_array = np.array(mask_image)
    binary = ((mask_array >= threshold) * 255).astype(np.uint8)
    binary_image = Image.fromarray(binary, mode="L")

    # Close gaps (morphological closing)
    if close_gaps > 0:
        kernel = close_gaps * 2 + 1
        binary_image = binary_image.filter(ImageFilter.MinFilter(kernel))
        binary_image = binary_image.filter(ImageFilter.MaxFilter(kernel))

    # Erode foreground to remove fringe
    if erode_px > 0:
        for _ in range(erode_px):
            binary_image = binary_image.filter(ImageFilter.MinFilter(3))

    # Smooth edges with Gaussian blur + re-binarize
    if smooth_px > 0:
        radius = max(1, smooth_px)
        binary_image = binary_image.filter(ImageFilter.GaussianBlur(radius=radius))
        arr = np.array(binary_image)
        arr = ((arr >= 128) * 255).astype(np.uint8)
        binary_image = Image.fromarray(arr, mode="L")

    # Apply mask to source image as alpha channel
    source = Image.open(image_path).convert("RGBA")
    if source.size != binary_image.size:
        binary_image = binary_image.resize(source.size, Image.NEAREST)
    source.putalpha(binary_image)
    return source


def main():
    parser = argparse.ArgumentParser(description="BiRefNet background removal (ProjectAriel compatible)")
    parser.add_argument("paths", nargs="*", help="Image file paths")
    parser.add_argument("--dir", type=str, help="Directory to process (all PNG/JPG)")
    parser.add_argument("--erode", type=int, default=0, help="Erode pixels (default: 0)")
    parser.add_argument("--smooth", type=int, default=0, help="Smooth pixels (default: 0)")
    parser.add_argument("--threshold", type=int, default=128, help="Binarization threshold (default: 128)")
    parser.add_argument("--close-gaps", type=int, default=0, help="Morphological close gaps (default: 0)")
    parser.add_argument("--output-dir", type=str, default=None, help="Output directory (default: same as input)")
    parser.add_argument("--suffix", type=str, default="", help="Output filename suffix (default: overwrite)")
    args = parser.parse_args()

    # Collect target files
    files = []
    if args.dir:
        for ext in ("*.png", "*.jpg", "*.jpeg", "*.webp"):
            files.extend(glob.glob(os.path.join(args.dir, ext)))
    files.extend(args.paths)
    files = sorted(set(files))

    if not files:
        print("No files to process. Provide paths or use --dir")
        sys.exit(1)

    print(f"Processing {len(files)} file(s) with BiRefNet...")
    print(f"Settings: erode={args.erode} smooth={args.smooth} threshold={args.threshold} close_gaps={args.close_gaps}")
    print()

    # Initialize BiRefNet session (downloads model on first run, ~400MB)
    print("Loading BiRefNet model (may take a while on first run)...")
    session = new_session("birefnet-general")
    print("Model loaded.\n")

    success = 0
    for i, path in enumerate(files, 1):
        name = os.path.basename(path)
        print(f"  [{i}/{len(files)}] {name}...", end=" ", flush=True)
        try:
            result = segment_and_apply(
                path,
                session,
                erode_px=args.erode,
                smooth_px=args.smooth,
                threshold=args.threshold,
                close_gaps=args.close_gaps,
            )
            # Determine output path
            if args.output_dir:
                os.makedirs(args.output_dir, exist_ok=True)
                base = os.path.splitext(name)[0] + args.suffix + ".png"
                out_path = os.path.join(args.output_dir, base)
            else:
                if args.suffix:
                    base = os.path.splitext(path)[0] + args.suffix + ".png"
                else:
                    base = path
                out_path = base
            result.save(out_path, format="PNG")
            print("OK")
            success += 1
        except Exception as e:
            print(f"FAILED: {e}")

    print(f"\nDone: {success}/{len(files)} files processed")


if __name__ == "__main__":
    main()
