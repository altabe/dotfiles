import re
from kitty.utils import open_url

URL_RE = re.compile(
    r'(https?://[^\s<>"\'()]+)',
    re.IGNORECASE,
)

# Matches shorter than this get a single hint; longer ones get dual hints
MIN_DUAL_LENGTH = 15


def mark(text, args, Mark, extra_cli_args, *a):
    matches = list(URL_RE.finditer(text))

    # Exactly one URL → auto-open
    if len(matches) == 1:
        m = matches[0]
        open_url(m.group(1))

        # Zero-width dummy mark to suppress "no matches found"
        return [Mark(0, m.start(1), m.start(1), '', {})]

    # Multiple URLs → dual hints for long ones
    marks = []
    idx = 0
    for m in matches:
        start, end = m.start(1), m.end(1)
        url = m.group(1)
        if len(url) < MIN_DUAL_LENGTH:
            marks.append(Mark(idx, start, end, url, {}))
            idx += 1
        else:
            marks.append(Mark(idx, start, start + 1, url, {}))
            marks.append(Mark(idx, end - 1, end, url, {}))
            idx += 1
    return marks
