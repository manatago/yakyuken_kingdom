import os
import shutil

base_dir = r"d:\Dropbox\Git\OtherRepositories\janken\godot\assets"
dirs = {
    "backgrounds": ["bg01_university.png", "bg02_room.png", "bg03_lab.png"],
    "characters": ["char_1.png", "char_2.png", "girl.png"],
    "ui": ["speech_bubble.png", "speech_bubble_v2.png", "card_back.png"],
    "cards": ["rock.jpg", "paper.jpg", "scissors.jpg"]
}

for subdir, files in dirs.items():
    target_dir = os.path.join(base_dir, subdir)
    os.makedirs(target_dir, exist_ok=True)
    for file in files:
        src = os.path.join(base_dir, file)
        dst = os.path.join(target_dir, file)

        # Move file
        if os.path.exists(src):
            try:
                shutil.move(src, dst)
                print(f"Moved {src} to {dst}")
            except Exception as e:
                print(f"Error moving {src}: {e}")

        # Move import file if exists
        src_import = src + ".import"
        dst_import = dst + ".import"
        if os.path.exists(src_import):
            try:
                shutil.move(src_import, dst_import)
                print(f"Moved {src_import} to {dst_import}")
            except Exception as e:
                print(f"Error moving {src_import}: {e}")

print("Reorganization complete.")
