#!/usr/bin/env python3
"""BiRefNet 一括背景除去（ProjectAriel API 経由）.

ProjectAriel の pose-api バックエンド（localhost:9403）を利用して
BiRefNet で背景除去を行う。モデルが常駐しているので高速。

ProjectAriel が起動していない場合は、別途 ProjectAriel を起動してから使う。

デフォルト設定:
  - モデル: birefnet-general (最高精度)
  - erode: 0
  - smooth: 0
  - threshold: 128

使い方:
    python3 bgremove.py image.png                # 単一ファイル（上書き）
    python3 bgremove.py img1.png img2.png        # 複数ファイル
    python3 bgremove.py ~/JankenImages/somedir/  # ディレクトリ
    python3 bgremove.py image.png -o out/        # 別ディレクトリに出力
"""

import argparse
import glob
import io
import os
import sys
import urllib.request
import urllib.error

from PIL import Image

API_URL = "http://localhost:9403/segment/mask"
MODEL = "birefnet-general"
ERODE = 0
SMOOTH = 0
THRESHOLD = 128


def build_multipart(file_bytes: bytes, filename: str):
    """Build a minimal multipart/form-data body."""
    boundary = "----bgremove-boundary-xyz"
    lines = []
    lines.append(f"--{boundary}".encode())
    lines.append(f'Content-Disposition: form-data; name="file"; filename="{filename}"'.encode())
    lines.append(b"Content-Type: image/png")
    lines.append(b"")
    lines.append(file_bytes)
    lines.append(f"--{boundary}--".encode())
    lines.append(b"")
    body = b"\r\n".join(lines)
    return body, f"multipart/form-data; boundary={boundary}"


def request_mask(image_path: str) -> bytes:
    """Call the ProjectAriel /segment/mask API and return PNG mask bytes."""
    with open(image_path, "rb") as f:
        file_bytes = f.read()

    body, content_type = build_multipart(file_bytes, os.path.basename(image_path))

    params = f"?model={MODEL}&erode={ERODE}&smooth={SMOOTH}&threshold={THRESHOLD}"
    url = API_URL + params

    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Content-Type", content_type)
    req.add_header("Content-Length", str(len(body)))

    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()


def apply_mask(image_path: str, mask_bytes: bytes, output_path: str) -> None:
    """Apply mask as alpha channel and save."""
    mask = Image.open(io.BytesIO(mask_bytes)).convert("L")
    source = Image.open(image_path).convert("RGBA")
    if source.size != mask.size:
        mask = mask.resize(source.size, Image.NEAREST)
    source.putalpha(mask)
    source.save(output_path, format="PNG")


def check_api_available() -> bool:
    try:
        with urllib.request.urlopen("http://localhost:9403/health", timeout=3) as resp:
            return resp.status == 200
    except Exception:
        return False


def main():
    parser = argparse.ArgumentParser(
        description="BiRefNet 一括背景除去（ProjectAriel API 経由）"
    )
    parser.add_argument("inputs", nargs="+", help="画像ファイルまたはディレクトリ")
    parser.add_argument("-o", "--output", type=str, default=None,
                        help="出力ディレクトリ（省略時は元ファイルを上書き）")
    args = parser.parse_args()

    if not check_api_available():
        print("エラー: ProjectAriel の pose-api (localhost:9403) が起動していません")
        print("ProjectAriel を起動してから再実行してください")
        sys.exit(1)

    # ファイルリスト収集
    files = []
    for inp in args.inputs:
        if os.path.isdir(inp):
            for ext in ("*.png", "*.jpg", "*.jpeg", "*.webp"):
                files.extend(glob.glob(os.path.join(inp, ext)))
        elif os.path.isfile(inp):
            files.append(inp)
        else:
            print(f"警告: 見つかりません: {inp}", file=sys.stderr)
    files = sorted(set(files))

    if not files:
        print("処理対象のファイルがありません", file=sys.stderr)
        sys.exit(1)

    # 出力ディレクトリ準備
    if args.output:
        os.makedirs(args.output, exist_ok=True)

    print(f"BiRefNet で {len(files)} 枚を処理します (API 経由)")
    print(f"設定: model={MODEL} erode={ERODE} smooth={SMOOTH} threshold={THRESHOLD}")
    print()

    success = 0
    for i, path in enumerate(files, 1):
        name = os.path.basename(path)
        print(f"  [{i}/{len(files)}] {name} ...", end=" ", flush=True)
        try:
            mask_bytes = request_mask(path)
            if args.output:
                base = os.path.splitext(name)[0] + ".png"
                out_path = os.path.join(args.output, base)
            else:
                out_path = path
            apply_mask(path, mask_bytes, out_path)
            print("OK")
            success += 1
        except urllib.error.HTTPError as e:
            print(f"失敗 (HTTP {e.code}): {e.read().decode(errors='replace')[:100]}")
        except Exception as e:
            print(f"失敗: {e}")

    print(f"\n完了: {success}/{len(files)} 枚")


if __name__ == "__main__":
    main()
