import shutil
import os

source = r'C:\Users\sin\.gemini\antigravity\brain\915f4b65-4cec-43ca-a594-a45d90b779b2\matilda_new_1767159839496.png'
dest = r'd:\Dropbox\Git\OtherRepositories\janken\godot\assets\prologue\characters\matilda.png'

print(f"Copying from {source} to {dest}")

try:
    shutil.copy2(source, dest)
    print("Copy successful.")

    # Remove .import file to force re-import
    import_file = dest + ".import"
    if os.path.exists(import_file):
        os.remove(import_file)
        print(f"Removed check file: {import_file}")
    else:
        print("Import file not found, skipping removal.")

except Exception as e:
    print(f"Error copying file: {e}")
