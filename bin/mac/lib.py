
def list_files(directory):
    import os
    for root, dirs, files in os.walk(directory):
        print("Dir:", root)
        for file in files:
            if file.startswith('com.apple'):
                continue
            print("\t", file)


def valid_file_path(paths):
    import os
    for path in paths:
        if not os.path.exists(path):
            print(f'Path {path} does not exist')
            return False
    return True
