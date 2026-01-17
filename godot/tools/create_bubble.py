from PIL import Image, ImageDraw
import os

def create_speech_bubble():
    # Image size
    width, height = 300, 200
    # Create RGBA image (transparent background)
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Colors
    bg_color = (255, 255, 255, 255) # White
    border_color = (0, 0, 0, 255)   # Black
    border_width = 4

    # Coordinates
    rect_coords = [10, 10, width-10, height-40]

    # Draw filled rounded rectangle (Body)
    draw.rounded_rectangle(rect_coords, radius=20, fill=bg_color, outline=border_color, width=border_width)

    # Draw tail (Triangle)
    # To make it look seamless, we draw the filled triangle first, then the outline manually if needed.
    # For simplicity in this script, we'll just draw a triangle on top of the border to hide it,
    # then redraw the border for the tail.

    # Tail points
    p1 = (60, height-40 - border_width + 1) # Base left (slightly up to cover border)
    p2 = (40, height-10)                    # Tip
    p3 = (90, height-40 - border_width + 1) # Base right

    # Draw filled tail
    draw.polygon([p1, p2, p3], fill=bg_color)

    # Draw tail outline (V shape)
    draw.line([p1, p2], fill=border_color, width=border_width)
    draw.line([p2, p3], fill=border_color, width=border_width)

    # Overwrite the top part of the tail with white to erase the body's border there
    # (A small rectangle or line)
    draw.line([p1, p3], fill=bg_color, width=border_width)

    output_dir = r"d:\Dropbox\Git\OtherRepositories\janken\godot\assets"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    output_path = os.path.join(output_dir, "speech_bubble.png")
    image.save(output_path)
    print(f"Created {output_path}")

if __name__ == "__main__":
    create_speech_bubble()
