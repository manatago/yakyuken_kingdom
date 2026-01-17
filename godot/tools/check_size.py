import struct

def get_png_dimensions(file_path):
    with open(file_path, 'rb') as f:
        data = f.read(24)
        if data[:8] != b'\x89PNG\r\n\x1a\n':
            return None
        w, h = struct.unpack('>II', data[16:24])
        return w, h

path = "assets/backgrounds/bg01_university.png"
dims = get_png_dimensions(path)
print(f"Dimensions of {path}: {dims}")
