import re

# Matches shorter than this get a single hint; longer ones get dual hints
MIN_DUAL_LENGTH = 15


def mark(text, args, Mark, extra_cli_args, *a):
    pattern = args.regex
    if not pattern:
        return []

    marks = []
    idx = 0
    for m in re.finditer(pattern, text, re.MULTILINE):
        grp = 1 if m.lastindex and m.lastindex >= 1 else 0
        start, end = m.start(grp), m.end(grp)
        matched = m.group(grp).replace('\n', '').replace('\r', '').replace('\0', '')
        if not matched:
            continue

        if len(matched) < MIN_DUAL_LENGTH:
            marks.append(Mark(idx, start, end, matched, {}))
            idx += 1
        else:
            # Same index for both → same hint label, same selection result
            marks.append(Mark(idx, start, start + 1, matched, {}))
            marks.append(Mark(idx, end - 1, end, matched, {}))
            idx += 1

    return marks
