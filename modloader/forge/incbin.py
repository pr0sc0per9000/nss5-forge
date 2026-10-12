"""Locate the Incbin'd assets inside a BlitzMax exe, by content, with no fixed offsets.

This is scripts/extract_incbin.py's locator, but taking the exe bytes as an argument so it
works on any build (ours or the player's NSS5.exe). The two exes are different sizes, so an
asset sits at a different file offset in each, but the asset BYTES are the same game media.
That is what lets the stripped build be refilled from the player's own copy.
"""
import struct

BBSTR_LITERAL_REFS = 0x7FFFFFFF
ALIGN = 4


def _table(d):
    """[(hdr_off, path, char_len)] in file order -- the incbin path table itself."""
    entries = []
    needle = b"I\x00n\x00c\x00"          # every path starts "Inc/"
    i = 0
    while True:
        i = d.find(needle, i)
        if i < 0:
            break
        if i >= 12:
            cls, refs, ln = struct.unpack("<III", d[i - 12:i])
            if refs == BBSTR_LITERAL_REFS and 0 < ln < 512 and 0x400000 <= cls < 0x1000000:
                path = d[i:i + ln * 2].decode("utf-16-le", errors="replace")
                if "\x00" not in path:
                    entries.append((i - 12, path, ln))
        i += 1
    entries.sort()
    return entries


def spans(d):
    """[[path, start, end]] -- the exact byte range of each asset's data in `d`.

    Each asset's data ends where its own path BBString begins; the next begins just past
    that string, 4-byte aligned. The first asset has no preceding entry, so its start is
    the last NUL before its data (Credits.txt is plain text, no embedded NUL). Trailing
    0x90 alignment filler between data and the path string is not asset content.
    """
    entries = _table(d)
    if not entries:
        return []
    rows = []
    for idx, (hdr, path, _ln) in enumerate(entries):
        if idx == 0:
            rows.append([path, None, hdr])
            continue
        phdr, _pp, pln = entries[idx - 1]
        start = (phdr + 12 + pln * 2 + ALIGN - 1) & ~(ALIGN - 1)
        rows.append([path, start, hdr])
    s = rows[0][2]
    while s > 0 and d[s - 1] != 0x00:
        s -= 1
    rows[0][1] = s
    for row in rows:
        start, end = row[1], row[2]
        n = 0
        while n < ALIGN - 1 and end - 1 > start and d[end - 1] == 0x90:
            end -= 1
            n += 1
        row[2] = end
    return rows
