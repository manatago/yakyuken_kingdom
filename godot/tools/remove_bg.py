import os
import argparse
from rembg import remove, new_session
from PIL import Image

# Constants
DEFAULT_INPUT_DIR = "raw_images"
DEFAULT_OUTPUT_DIR = "assets"
VALID_EXTENSIONS = {".png", ".jpg", ".jpeg"}

# Configuration
USE_ALPHA_MATTING = True  # Set to True for better hair/edge detail
ALPHA_MATTING_FOREGROUND_THRESHOLD = 240
ALPHA_MATTING_BACKGROUND_THRESHOLD = 10
ALPHA_MATTING_ERODE_SIZE = 10

# Model options:
# 1. "u2net" (Default/General purpose)
#    - Pros: Good for general use (photos, objects, animals).
#    - Cons: Fine details like hair might be a bit blurry.
# 2. "u2net_human_seg" (Human specialized)
#    - Pros: Optimized for real human segmentation.
#    - Cons: Might struggle with anime/illustration styles or clothes matching background.
# 3. "isnet-anime" (Anime/Illustration specialized)
#    - Pros: Excellent for high-contrast lines and fine hair details in illustrations.
#    - Cons: Might over-segment on blurry real-life photos.
# 4. "isnet-general-use" (General purpose IS-Net)

# Select model here by uncommenting:
# MODEL_NAME = "u2net"
# MODEL_NAME = "u2net_human_seg"
MODEL_NAME = "isnet-anime"
# MODEL_NAME = "isnet-general-use"

def get_unique_filename(directory, filename):
    name, ext = os.path.splitext(filename)
    # Always use .png for transparency
    ext = ".png"

    output_filename = f"{name}{ext}"
    counter = 1

    while os.path.exists(os.path.join(directory, output_filename)):
        counter += 1
        output_filename = f"{name}_{counter:02d}{ext}"

    return output_filename

def process_images(input_dir, output_dir):
    if not os.path.exists(input_dir):
        print(f"Error: Input directory '{input_dir}' not found.")
        return

    if not os.path.exists(output_dir):
        print(f"Creating output directory: {output_dir}")
        os.makedirs(output_dir)

    print(f"Scanning directory: {input_dir}")
    print(f"Output directory: {output_dir}")
    print(f"Model: {MODEL_NAME}, Alpha Matting: {USE_ALPHA_MATTING}")

    # Initialize session with selected model
    session = new_session(MODEL_NAME)

    count = 0
    for filename in os.listdir(input_dir):
        name, ext = os.path.splitext(filename)

        # Skip non-image files
        if ext.lower() not in VALID_EXTENSIONS:
            continue

        input_path = os.path.join(input_dir, filename)

        # Generate unique output filename
        output_filename = get_unique_filename(output_dir, filename)
        output_path = os.path.join(output_dir, output_filename)

        print(f"Processing {filename} -> {output_filename}...")

        try:
            input_image = Image.open(input_path)

            output_image = remove(
                input_image,
                session=session,
                alpha_matting=USE_ALPHA_MATTING,
                alpha_matting_foreground_threshold=ALPHA_MATTING_FOREGROUND_THRESHOLD,
                alpha_matting_background_threshold=ALPHA_MATTING_BACKGROUND_THRESHOLD,
                alpha_matting_erode_size=ALPHA_MATTING_ERODE_SIZE
            )

            output_image.save(output_path)
            count += 1
        except Exception as e:
            print(f"Error processing {filename}: {e}")

    print(f"Done! Processed {count} images.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Remove background from images in a directory.")
    parser.add_argument("-i", "--input", default=DEFAULT_INPUT_DIR, help=f"Input directory (default: {DEFAULT_INPUT_DIR})")
    parser.add_argument("-o", "--output", default=DEFAULT_OUTPUT_DIR, help=f"Output directory (default: {DEFAULT_OUTPUT_DIR})")

    args = parser.parse_args()

    # Resolve absolute paths
    input_dir = os.path.abspath(args.input)
    output_dir = os.path.abspath(args.output)

    process_images(input_dir, output_dir)
