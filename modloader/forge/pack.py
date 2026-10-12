"""Strip the game's embedded files out of our built exe, so a release carries only our own
code and refills the rest from the player's own NSS5.exe.

Our exe embeds 11 files out of NSS5.exe's GameMedia/EngineMedia (fonts, Player.png, the
credits): about 6.7 MB of its 9.5 MB. Those are New Star Games' assets and cannot ship.
This zeroes them and records, per asset, where the hole is and the sha256 of what belongs
there, so refill.py can put the player's own bytes back and get our exact build.

    python pack.py <built exe> <out dir>

Writes <out dir>/nss5_forge.exe.stripped (zeroed, compresses to near nothing) and
<out dir>/refill.json. The full build's sha256 goes in the manifest as the target.
"""
import hashlib
import json
import lzma
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import incbin


def sha(b):
    return hashlib.sha256(b).hexdigest()


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: pack.py <built exe> <out dir>")
    exe, out = sys.argv[1], sys.argv[2]
    d = bytearray(open(exe, "rb").read())
    # The retail NSS5.exe is a GUI-subsystem program (no console). assemble.py builds a
    # console app for its debug prints, so the shipped build shows a console the original
    # never did. Flip the PE subsystem to GUI (2) to match; it only changes whether Windows
    # allocates a console, not any recovered code.
    pe = struct.unpack_from("<I", d, 0x3c)[0]
    sub_off = pe + 24 + 68
    if struct.unpack_from("<H", d, sub_off)[0] == 3:
        struct.pack_into("<H", d, sub_off, 2)
    full_sha = sha(d)
    rows = incbin.spans(d)
    if len(rows) != 11:
        sys.exit("expected 11 embedded assets, found %d -- aborting" % len(rows))
    os.makedirs(out, exist_ok=True)
    manifest = {"target_sha256": full_sha, "size": len(d), "assets": []}
    for path, start, end in rows:
        manifest["assets"].append(
            {"path": path, "offset": start, "length": end - start,
             "sha256": sha(d[start:end])})
        for i in range(start, end):
            d[i] = 0
    stub_sha = sha(d)
    open(os.path.join(out, "nss5_forge.exe.stripped"), "wb").write(d)
    with lzma.open(os.path.join(out, "nss5_forge.exe.xz"), "wb", preset=9) as f:
        f.write(d)
    manifest["stub_sha256"] = stub_sha
    json.dump(manifest, open(os.path.join(out, "refill.json"), "w"), indent=2)
    embedded = sum(a["length"] for a in manifest["assets"])
    print("built exe %d bytes, embedded game assets %d bytes (%.0f%%)"
          % (len(d), embedded, 100.0 * embedded / len(d)))
    print("stripped xz: %d bytes" % os.path.getsize(os.path.join(out, "nss5_forge.exe.xz")))
    print("target sha256 %s" % full_sha)


if __name__ == "__main__":
    main()
