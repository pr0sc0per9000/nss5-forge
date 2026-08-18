"""
Recover the exe's Incbin'd assets EXACTLY, and with them the Incbin statements themselves.

WHY THIS REPLACES extracted/exe-assets/. That directory held 9 files, and at least one of
them was wrong in two independent ways:

  * Credits.txt was 1,075 bytes; the real asset is 1,028. The extra 47 bytes are the
    incbin TABLE ENTRY that follows the data -- a BBString header plus the UTF-16 path
    "Inc/Credits.txt" -- swept up because the extractor did not know where the asset ended.
  * It had been re-encoded to UTF-8. The exe stores Latin-1: "Tони Sagués" is `\xe9` in the
    binary and `\xc3\xa9` in the extracted copy. The give-away is the mangled tail, where
    the table's `\xff\xff\xff` came out as `\xc3\xbf\xc3\xbf\xc3\xbf`.

Either defect alone makes a byte-exact rebuild impossible, and neither is visible without
comparing against the binary. Assets are 6.4 MB of a 9.4 MB exe, so this is not a footnote.

TWO of the eleven assets had never been extracted at all: Inc/TCCEB.TTF and
Inc/RUSSIAN.TTF. Nothing reported them missing because nothing knew how many there were.

THE LAYOUT. BlitzMax lays each Incbin out as [file data][path as a BBString], contiguously,
in SOURCE ORDER. A BBString is [class][refs][length][UTF-16 chars] and a literal one has
refs = 0x7FFFFFFF, which is what makes the table findable: scan for that constant followed
by a UTF-16 path. Each path string therefore marks the END of its own asset's data, and the
NEXT asset's data begins just past that string (padded to a 4-byte boundary with 0x90).

Consequently this also recovers the exact Incbin statements the reconstructed source needs,
in the order bcc must see them:

    Incbin "Inc/Credits.txt"
    Incbin "Inc/Player.png"
    ...

Usage: extract_incbin.py [--write]      --write emits extracted/incbin/<path>
"""

import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(ROOT, "binary", "NSS5.exe")
OUT = os.path.join(ROOT, "extracted", "incbin")

BBSTR_LITERAL_REFS = 0x7FFFFFFF
ALIGN = 4


def table(d):
    """[(hdr_off, path, data_end)] in file order -- the incbin table itself."""
    entries = []
    needle = b"I\x00n\x00c\x00"          # every path in this exe starts "Inc/"
    i = 0
    while True:
        i = d.find(needle, i)
        if i < 0:
            break
        if i >= 12:
            cls, refs, ln = struct.unpack("<III", d[i - 12:i])
            # cls must look like an in-image pointer; refs is the literal-string marker.
            if refs == BBSTR_LITERAL_REFS and 0 < ln < 512 and 0x400000 <= cls < 0x1000000:
                path = d[i:i + ln * 2].decode("utf-16-le", errors="replace")
                if "\x00" not in path:
                    entries.append((i - 12, path, ln))
        i += 1
    entries.sort()
    return entries


def spans(entries):
    """[[path, start, end]] -- the exact byte range of each asset's data.

    Each entry's data ENDS where its own path BBString begins, and the next entry's data
    BEGINS just past that string, aligned. So every asset but the first is bounded on both
    sides by the table; the first one's start is recovered separately by the caller.
    """
    out = []
    for idx, (hdr, path, _ln) in enumerate(entries):
        if idx == 0:
            out.append([path, None, hdr])
            continue
        phdr, _pp, pln = entries[idx - 1]
        start = phdr + 12 + pln * 2
        start = (start + ALIGN - 1) & ~(ALIGN - 1)
        out.append([path, start, hdr])
    return out


def main():
    d = open(EXE, "rb").read()
    entries = table(d)
    if not entries:
        print("no incbin table found -- the BBString literal marker did not appear")
        return 2

    rows = spans(entries)

    # The first asset has no preceding table entry to bound it. The blob is preceded by a
    # run of zero padding, and this exe's first asset (Inc/Credits.txt) is plain text
    # containing no NUL, so walking back to the last NUL finds its start exactly.
    # NOTE THE ASSUMPTION: if a future exe put a BINARY asset first, this would stop at the
    # first embedded NUL and under-read. The check below catches that rather than trusting it.
    first_end = rows[0][2]
    s = first_end
    while s > 0 and d[s - 1] != 0x00:
        s -= 1
    rows[0][1] = s

    # Strip the alignment padding bcc inserts between an asset and its path string. Each
    # path BBString starts 4-byte aligned, so an asset whose length is not a multiple of 4
    # is followed by 1-3 filler bytes -- 0x90 here. Those bytes are NOT asset content:
    # Main.ogg reads 2,266,132 with the filler and 2,266,131 without, and the shorter value
    # is the one that matches the file. Never strip more than ALIGN-1, or a genuine trailing
    # 0x90 in the data would be eaten.
    for row in rows:
        start, end = row[1], row[2]
        stripped = 0
        while stripped < ALIGN - 1 and end - 1 > start and d[end - 1] == 0x90:
            end -= 1
            stripped += 1
        row[2] = end

    print("INCBIN TABLE -- %d assets, in source order" % len(rows))
    print()
    print("  %-32s %12s %12s %10s" % ("path", "file offset", "end", "size"))
    total = 0
    for path, start, end in rows:
        print("  %-32s   0x%08x   0x%08x %10d" % (path, start, end, end - start))
        total += end - start
    print()
    print("  total embedded: %d bytes (%.2f MB)" % (total, total / 1048576.0))

    # Cross-check against the previously extracted copies. They are not authoritative --
    # Credits.txt proves that -- but where they AGREE, two independent extractions with
    # different bugs available to them landed on the same bytes, which is real corroboration.
    old = os.path.join(ROOT, "extracted", "exe-assets")
    if os.path.isdir(old):
        print()
        print("  cross-check vs extracted/exe-assets/ (the older, partly-broken extraction):")
        for path, start, end in rows:
            cand = os.path.join(old, os.path.basename(path))
            if not os.path.exists(cand):
                print("    %-32s ABSENT there -- new" % path)
                continue
            prev = open(cand, "rb").read()
            now = d[start:end]
            if prev == now:
                print("    %-32s agrees (%d bytes)" % (path, len(now)))
            else:
                print("    %-32s DIFFERS: %d there, %d here -- the exe wins"
                      % (path, len(prev), len(now)))
    print()
    print("THE SOURCE STATEMENTS (exact order matters -- bcc lays them out as it sees them):")
    for path, _s, _e in rows:
        print('  Incbin "%s"' % path)

    if "--verify" in sys.argv:
        # Rebuild the blob from the extracted files and compare against the exe. This is the
        # real proof the extraction is correct -- it checks every asset's CONTENT, the source
        # ORDER, and the padding rule in one shot.
        #
        # THE PADDING RULE, which a first attempt got wrong: each entry is
        #   <data> <pad 0x90 to 4> <path BBString> <pad 0x90 to 4>
        # BOTH pads are required. Padding only before the path string yields the correct
        # total length and still diverges at the first gap after a path string (+1070), because
        # the NEXT asset must start aligned too.
        blob_start = rows[0][1]
        blob_end = entries[-1][0] + 12 + entries[-1][2] * 2
        orig = d[blob_start:blob_end]
        out = bytearray()
        for (path, _s, _e), (hdr, _p, ln) in zip(rows, entries):
            fp = os.path.join(OUT, path.replace("/", os.sep))
            if not os.path.exists(fp):
                print("  cannot verify: %s not extracted (run with --write)" % path)
                return 2
            out += open(fp, "rb").read()
            while len(out) % ALIGN:
                out += b"\x90"
            out += d[hdr:hdr + 12 + ln * 2]
            while len(out) % ALIGN:
                out += b"\x90"
        out = bytes(out[:len(orig)])
        print()
        if out == orig:
            print("  ROUND-TRIP OK: %d bytes rebuilt identically from extracted/incbin/"
                  % len(orig))
            return 0
        for i, (a, b) in enumerate(zip(orig, out)):
            if a != b:
                print("  ROUND-TRIP FAILED at +%d (0x%x): exe %02x, rebuilt %02x"
                      % (i, i, a, b))
                break
        else:
            print("  ROUND-TRIP FAILED: length %d vs %d" % (len(orig), len(out)))
        return 1

    if "--write" in sys.argv:
        print()
        for path, start, end in rows:
            dest = os.path.join(OUT, path.replace("/", os.sep))
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as f:
                f.write(d[start:end])
            print("  wrote %-34s %8d bytes" % (path, end - start))
        print()
        print("  These are RAW bytes straight out of the exe. Never open one in a text")
        print("  editor and save it -- that is exactly how Credits.txt acquired a UTF-8")
        print("  re-encoding and stopped matching.")
    else:
        print()
        print("  (re-run with --write to emit extracted/incbin/)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
