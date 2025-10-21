#!/usr/bin/env python


# create a function to list all the files in a given directory
import sys
import lib
from lib import valid_file_path, list_files

paths = []
# get command line arguments if any, else use the default paths
if len(sys.argv) > 1:
    paths = sys.argv[1:]

# ./ls.py < sys_path.txt
if len(paths) == 0:
    paths = sys.stdin.readlines()
    paths = [path.strip() for path in paths if not path.startswith('#') and path.strip() != '']
    paths = [path for path in paths if valid_file_path([path])]
    print('Scan List:', paths)
    print()

for path in paths:
    list_files(path)
    print()
