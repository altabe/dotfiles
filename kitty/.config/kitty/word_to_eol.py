#!/usr/bin/env python3

from kitty.clipboard import set_clipboard_string, set_primary_selection

import os
import time
file_path = "/tmp/kitty.test"
# if os.path.exists(file_path):
#     os.remove(file_path)

def dp(f, s):
    f.write(s + "\n")

def main(args):
    pass

def mark(text, args, Mark, extra_cli_args, *a):
    raise ValueError("is this called?")
    with open(file_path, "a") as f:
        dp(f, str(time.time()))
        dp(f, "mark called")
    import re
    marks = []
    
    for match in re.finditer(r'\b\w+', text):
        mark = Mark(
            index=len(marks),
            start=match.start(), 
            end=match.end(),
            text=match.group()
        )
        yield mark
    
    # with open(file_path, "a") as f:
    #     dp(f, str(marks))
    # return marks

def handle_result(args, data, target_window_id, boss):
    with open(file_path, "a") as f:
        dp(f, str(time.time()))
        dp(f, "handle called")
        dp(f, str(args))
        dp(f, str(data))
    """Handle the selected text - copy to clipboard."""
    
    with open('/tmp/kitty_debug.log', 'a') as f:
        dp(f, f"handle_result called with data: {data}")

handle_result.no_ui = True
