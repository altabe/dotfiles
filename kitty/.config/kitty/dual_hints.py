import re
import math
import unicodedata

# Matches shorter than this get a single hint; longer ones get dual hints
MIN_DUAL_LENGTH = 15
# Skip matches this short
MIN_MATCH_LENGTH = 2
# Kitty uses lowercase alphabet for hint labels
ALPHABET_SIZE = 26


def _is_safe(ch):
    """Characters known to be single-width and safe for hint placement."""
    cp = ord(ch)
    # ASCII printable (space through tilde) + common control chars
    if cp <= 0x7E:
        return True
    # Latin Extended (accented chars, etc.) — single-width
    if 0x00A0 <= cp <= 0x024F:
        return True
    # Cyrillic
    if 0x0400 <= cp <= 0x04FF:
        return True
    # Greek
    if 0x0370 <= cp <= 0x03FF:
        return True
    # Hebrew
    if 0x0590 <= cp <= 0x05FF:
        return True
    # Arabic
    if 0x0600 <= cp <= 0x06FF:
        return True
    return False


def _sanitize(text):
    """Replace problematic chars with spaces to keep positions aligned."""
    return ''.join(ch if _is_safe(ch) else ' ' for ch in text)


def _hint_label_length(num_hints):
    """How many characters kitty needs per hint label."""
    if num_hints <= 0:
        return 1
    return max(1, math.ceil(math.log(num_hints + 1) / math.log(ALPHABET_SIZE)))


def mark(text, args, Mark, extra_cli_args, *a):
    pattern = args.regex
    if not pattern:
        return []

    # Run regex on sanitized text; positions map 1:1 to original
    clean = _sanitize(text)

    # First pass: collect valid matches
    raw = []
    for m in re.finditer(pattern, clean, re.MULTILINE):
        grp = 1 if m.lastindex and m.lastindex >= 1 else 0
        start, end = m.start(grp), m.end(grp)
        matched = text[start:end].replace('\n', '').replace('\r', '').replace('\0', '')
        if not matched or len(matched) < MIN_MATCH_LENGTH:
            continue
        raw.append((start, end, matched))

    # Count unique hint indices to determine label length
    num_hints = sum(1 for s, e, m in raw)
    label_len = _hint_label_length(num_hints)

    # Second pass: create marks sized to fit the hint label
    marks = []
    idx = 0
    for start, end, matched in raw:
        match_len = end - start
        # Clamp mark width to not exceed match length
        w = min(label_len, match_len)

        if match_len < MIN_DUAL_LENGTH:
            marks.append(Mark(idx, start, start + w, matched, {}))
            idx += 1
        else:
            # Same index for both → same hint label, same selection result
            marks.append(Mark(idx, start, start + w, matched, {}))
            marks.append(Mark(idx, end - w, end, matched, {}))
            idx += 1

    return marks
