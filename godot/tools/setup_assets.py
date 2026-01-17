import os

base_path = "."
dirs = [
    "assets/common",
    "assets/prologue/backgrounds",
    "assets/prologue/characters",
    "assets/stage1/backgrounds",
    "assets/stage1/characters"
]

print(f"Creating directories in {os.path.abspath(base_path)}...")
for d in dirs:
    path = os.path.join(base_path, d)
    try:
        os.makedirs(path, exist_ok=True)
        print(f"OK: {path}")
    except Exception as e:
        print(f"FAIL: {path} - {e}")
