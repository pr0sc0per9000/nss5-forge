"""Rebuild our exe from the stripped copy and the player's own NSS5.exe.

    python refill.py <stripped exe or .xz> <refill.json> <NSS5.exe> <out exe>

Each asset is taken from NSS5.exe by path, checked against the sha256 in the manifest, and
written into its hole. The result must hash to the manifest's target, or nothing is written.
"""
import hashlib
import json
import lzma
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import incbin


def sha(b):
    return hashlib.sha256(b).hexdigest()


def refill(stripped, manifest, nss5):
    if sha(stripped) != manifest["stub_sha256"]:
        raise ValueError("stripped exe does not match its manifest")
    theirs = {path: nss5[s:e] for path, s, e in incbin.spans(nss5)}
    out = bytearray(stripped)
    for a in manifest["assets"]:
        data = theirs.get(a["path"])
        if data is None:
            raise ValueError("NSS5.exe has no embedded %s" % a["path"])
        if len(data) != a["length"] or sha(data) != a["sha256"]:
            raise ValueError("NSS5.exe's %s is not the expected file" % a["path"])
        out[a["offset"]:a["offset"] + a["length"]] = data
    if sha(out) != manifest["target_sha256"]:
        raise ValueError("refilled exe does not match the target build")
    return bytes(out)


def main():
    if len(sys.argv) != 5:
        sys.exit("usage: refill.py <stripped exe or .xz> <refill.json> <NSS5.exe> <out exe>")
    src, man, nss5, out = sys.argv[1:]
    stripped = lzma.open(src).read() if src.endswith(".xz") else open(src, "rb").read()
    built = refill(stripped, json.load(open(man)), open(nss5, "rb").read())
    tmp = out + ".tmp"
    open(tmp, "wb").write(built)
    os.replace(tmp, out)
    print("refilled %s, sha256 %s" % (out, sha(built)))


if __name__ == "__main__":
    main()
