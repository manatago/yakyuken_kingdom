import os
from PIL import Image

TARGET_SIZE = (1216, 832)
ASSETS_DIR = "assets/prologue/backgrounds"
FILES = ["dungeon.png", "office.png"]

def resize_and_crop(image_path, target_size):
    try:
        img = Image.open(image_path)

        # Calculate aspect ratios
        img_ratio = img.width / img.height
        target_ratio = target_size[0] / target_size[1]

        if img_ratio > target_ratio:
            # Image is wider than target: resize by height
            new_height = target_size[1]
            new_width = int(new_height * img_ratio)
        else:
            # Image is taller than target: resize by width
            new_width = target_size[0]
            new_height = int(new_width / img_ratio)

        img = img.resize((new_width, new_height), Image.LANCZOS)

        # Center crop
        left = (new_width - target_size[0]) / 2
        top = (new_height - target_size[1]) / 2
        right = (new_width + target_size[0]) / 2
        bottom = (new_height + target_size[1]) / 2

        img = img.crop((left, top, right, bottom))

        # Save
        img.save(image_path)
        print(f"Processed: {image_path} -> {target_size}")

    except Exception as e:
        print(f"Error processing {image_path}: {e}")

def main():
    base_path = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.join(base_path, ASSETS_DIR)

    if not os.path.exists(target_dir):
        print(f"Directory not found: {target_dir}")
        return

    for filename in FILES:
        file_path = os.path.join(target_dir, filename)
        if os.path.exists(file_path):
            resize_and_crop(file_path, TARGET_SIZE)
        else:
            print(f"File not found: {file_path}")

if __name__ == "__main__":
    main()
