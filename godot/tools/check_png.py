import os

path = r'd:\Dropbox\Git\OtherRepositories\janken\godot\assets\prologue\characters\matilda.png'
print(f'Exists: {os.path.exists(path)}')

try:
    with open(path, 'rb') as f:
        header = f.read(8)
        print(f'Header: {header}')
        print(f'Is PNG: {header == b"\x89PNG\r\n\x1a\n"}')
except Exception as e:
    print(f'Error: {e}')
