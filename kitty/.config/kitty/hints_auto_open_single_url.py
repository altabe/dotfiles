import re
from kitty.utils import open_url

URL_RE = re.compile(
    r'(https?://[^\s<>"\'()]+)',
    re.IGNORECASE,
)

def mark(text, args, Mark, extra_cli_args, *a):
    print(Mark)
    matches = list(URL_RE.finditer(text))

    # Exactly one URL → auto-open
    if len(matches) == 1:
        m = matches[0]
        open_url(m.group(1))

        # Zero-width dummy mark to suppress "no matches found"
        return [Mark(m.start(1), m.start(1), '', {})]

    # Multiple URLs → normal hints UI
    return [
        Mark(m.start(1), m.end(1), m.group(1), {})
        for m in matches
    ]

