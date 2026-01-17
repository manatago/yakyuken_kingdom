import shutil
import os
import platform

def get_path(windows_path):
    # If running in WSL (Linux) and path starts with C:, convert to /mnt/c/
    if platform.system() == "Linux" and "microsoft" in platform.release().lower():
        if windows_path.lower().startswith("c:"):
            return windows_path.replace("\\", "/").replace("C:", "/mnt/c").replace("c:", "/mnt/c")
    return windows_path

# Define the source files (artifacts) and their destinations
assets = [
    # Backgrounds (Already generated)
    {
        "src": get_path(r"C:\Users\sin\.gemini\antigravity\brain\451ce8fa-fac4-4342-8876-425ba0c24ce1\dungeon_background_landscape_1766033641946.png"),
        "dst": "assets/prologue/backgrounds/dungeon.png"
    },
    {
        "src": get_path(r"C:\Users\sin\.gemini\antigravity\brain\451ce8fa-fac4-4342-8876-425ba0c24ce1\office_background_1280x720_1766043515252.png"),
        "dst": "assets/prologue/backgrounds/office.png"
    },
    {
        "src": get_path(r"C:\Users\sin\.gemini\antigravity\brain\451ce8fa-fac4-4342-8876-425ba0c24ce1\arena_background_1280x720_1766117517150.png"),
        "dst": "assets/stage1/backgrounds/arena.png"
    },
    # Characters (To be generated)
    {
        "src": get_path(r"C:\Users\sin\.gemini\antigravity\brain\c49d65d8-7ef2-46f2-a5c6-6f07ebd5c2e9\matilda_gatekeeper_1766353043027.png"),
        "dst": "assets/prologue/characters/matilda.png"
    },
    {
        "src": get_path(r"C:\Users\sin\.gemini\antigravity\brain\c49d65d8-7ef2-46f2-a5c6-6f07ebd5c2e9\president_character_1766353060988.png"),
        "dst": "assets/prologue/characters/president.png"
    },
    {
        "src": get_path(r"C:\Users\sin\.gemini\antigravity\brain\c49d65d8-7ef2-46f2-a5c6-6f07ebd5c2e9\president_son_character_1766353082458.png"),
        "dst": "assets/prologue/characters/son.png"
    },
    {
        "src": get_path(r"C:\Users\sin\.gemini\antigravity\brain\c49d65d8-7ef2-46f2-a5c6-6f07ebd5c2e9\protagonist_salaryman_weak_1766353412904.png"),
        "dst": "assets/prologue/characters/protagonist.png"
    }
]

print("Starting asset installation...")

for asset in assets:
    src = asset["src"]
    dst = asset["dst"]

    # Ensure destination directory exists
    os.makedirs(os.path.dirname(dst), exist_ok=True)

    try:
        if os.path.exists(src):
            shutil.copy(src, dst)
            print(f"[OK] Copied {os.path.basename(src)} -> {dst}")
        else:
            print(f"[ERR] Source not found: {src}")
    except Exception as e:
        print(f"[ERR] Failed to copy {src}: {e}")

print("Installation complete.")
