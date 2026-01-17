import shutil
import os

src = "/mnt/c/Users/sin/.gemini/antigravity/brain/451ce8fa-fac4-4342-8876-425ba0c24ce1/arena_background_1280x720_1766117517150.png"
dst = "assets/stage1/backgrounds/arena.png"

print(f"Copying from {src} to {dst}")

try:
    shutil.copy(src, dst)
    print("Success!")
except Exception as e:
    print(f"Error: {e}")
