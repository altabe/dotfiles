import re
import unicodedata
from kitty.utils import open_url

URL_RE = re.compile(
    r'(https?://[^\s<>"\'()]+)',
    re.IGNORECASE,
)

# Matches shorter than this get a single hint; longer ones get dual hints
MIN_DUAL_LENGTH = 15


def _is_safe(ch):
    """Characters known to be single-width and safe for hint placement."""
    cp = ord(ch)
    if cp <= 0x7E:
        return True
    if 0x00A0 <= cp <= 0x024F:
        return True
    if 0x0400 <= cp <= 0x04FF:
        return True
    if 0x0370 <= cp <= 0x03FF:
        return True
    if 0x0590 <= cp <= 0x05FF:
        return True
    if 0x0600 <= cp <= 0x06FF:
        return True
    return False


def _sanitize(text):
    return ''.join(ch if _is_safe(ch) else ' ' for ch in text)


def mark(text, args, Mark, extra_cli_args, *a):
    clean = _sanitize(text)
    matches = list(URL_RE.finditer(clean))

    # Exactly one URL → auto-open
    if len(matches) == 1:
        m = matches[0]
        open_url(text[m.start(1):m.end(1)])

        # Zero-width dummy mark to suppress "no matches found"
        return [Mark(0, m.start(1), m.start(1), '', {})]

    # Multiple URLs → dual hints for long ones
    marks = []
    idx = 0
    for m in matches:
        start, end = m.start(1), m.end(1)
        url = text[start:end]
        if len(url) < MIN_DUAL_LENGTH:
            marks.append(Mark(idx, start, end, url, {}))
            idx += 1
        else:
            marks.append(Mark(idx, start, start + 1, url, {}))
            marks.append(Mark(idx, end - 1, end, url, {}))
            idx += 1
    return marks
