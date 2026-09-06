"""Re-run the byte oracle over src/recovered_module/, the tree nothing else re-verifies.

    python scripts/reverify_module.py                 # every body carrying the marker
    python scripts/reverify_module.py --all           # every body, marker or not
    python scripts/reverify_module.py Name [Name ...] # just these
    python scripts/reverify_module.py --shard i/n     # files[i::n], for running n at once

WHY THIS EXISTS
===============
scripts/reverify.py walks src/recovered/ and matches `Type.Method.bmx` names, so it never
opens src/recovered_module/ at all -- those bodies are module-level Functions and have no
Type. That is a blind spot of 89 bodies and roughly 21,000 bytes, and it is not theoretical:
LoadImageChecked.bmx and LoadAnimImageChecked.bmx both carried
`byte-identical vs NSS5.exe` while compiling a deliberate BOOT SHIM that the oracle rejects
(253 vs 251 and 272 vs 271). Their own headers said the shim was there. Nothing checked.

A marker is a CLAIM. In a tree no tool re-reads, a claim is whatever it was the day someone
typed it, and progress.py counts it forever.

WHAT IT DOES
============
For each file, read the VA and sig from the header, extract the interior of the Function
whose name the filename gives (`Foo.bmx` -> Foo, `Fn_0058D90B.Name.bmx` -> Name), keep the
file's own '! pragmas, and hand it to harness.try_function with NSS5_NO_LEARN forced on.
Then compare the verdict against what the header claims:

    OK          marker present, oracle says MATCH
    FALSE       marker present, oracle disagrees   <- the ones that matter
    UNBANKED    no marker, oracle says MATCH       <- free bytes, banking was missed
    KNOWN       no marker, oracle disagrees        <- honest near-miss, nothing to do
    SKIP        could not be probed (build failure, no VA, no parseable Function)

A SKIP is not a pass. It is reported separately and counted, because a body the oracle
cannot reach is exactly how the two false markers above survived.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ["NSS5_NO_LEARN"] = "1"          # docs/RULES.md 5.5, not optional
import harness

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODDIR = os.path.join(ROOT, "src", "recovered_module")

VA_RE = re.compile(r"^'\s*VA\s+(0x[0-9A-Fa-f]+)[,\s]\s*(\d+)\s+bytes", re.M)
# Capture the sig as BALANCED PARENS plus the return code, not as one whitespace-delimited
# token. Real headers write `sig ($ Var,$)$` and `sig (*i,*i)i`; a \S+ capture stops at the
# first space and yields "($", which harness.parse_sig then indexes off the end of. That
# surfaced as a bare IndexError and read like a broken body rather than a broken reader.
SIG_RE = re.compile(r"\bsig\s+(\([^)]*\)\S*)")
MARKER = "byte-identical vs NSS5.exe"


def target_name(stem):
    """Foo.bmx -> Foo ; Fn_0058D90B.SyncSteamAchievements.bmx -> SyncSteamAchievements."""
    return stem.split(".", 1)[1] if re.match(r"^Fn_[0-9A-Fa-f]+\.", stem) else stem


# BlitzMax type -> the reflection signature letter harness.parse_sig speaks.
_SIGCODE = {"int": "i", "float": "f", "double": "d", "string": "$",
            "byte": "b", "short": "s", "long": "l"}


def sigcode(ty):
    ty = ty.strip()
    base = ty.split()[0] if ty else ""            # "String Var" -> "String"
    return _SIGCODE.get(base.lower(), ":" + base)


def declared(text, fname):
    """-> (param list verbatim, return type) from the file's own Function line, or None.

    THE PARAMETER LIST MUST BE PASSED THROUGH VERBATIM, not regenerated from the header's
    sig. build_source_function rebuilds it positionally as a0:Int, a1:String..., and that
    silently DROPS `Var`. A scalar `Var` compiles the same as a Ptr so nothing shows, but
    `String Var` has no Ptr spelling: NextFieldInt.bmx declares
        Function NextFieldInt:Int(a0:String Var, a1:String)
    and rebuilt by-value it emits 96 bytes against the original's 153 -- a confident
    MISMATCH that says nothing about the body. harness.try_function takes `decl` for
    exactly this and it is why that parameter exists."""
    for l in text.splitlines():
        m = re.match(r"^\s*Function\s+%s\s*(:([^(]+))?\((.*)\)\s*$"
                     % re.escape(fname), l)
        if m:
            return m.group(3).strip(), (m.group(2) or "Int").strip()
    return None


def siblings_as_raw(text, fname):
    """Other Functions declared in the SAME file, re-emitted as '!Raw module-scope lines.

    build_source_function bundles every OTHER module-function file as `others` so one body
    can call another, but it drops any file containing `Function <target>:` -- it is about
    to define that name itself and a duplicate would not compile. When the target's file
    declares a HELPER TOO, that helper goes out with it and the probe fails to link.
    LoadImageChecked.bmx is the case: it declares MissingArtImage() beside the target and
    calls it twice, so probing the target reported BUILD_FAIL "Identifier 'MissingArtImage'
    not found" -- a broken reader that reads exactly like a broken body.

    '!Raw is the pragma for a verbatim module-scope line, which is precisely what a
    sibling Function needs to be."""
    lines, out, depth, keeping = text.splitlines(), [], 0, False
    for l in lines:
        s = l.strip()
        if re.match(r"^Function\b", s):
            depth += 1
            if depth == 1:
                keeping = not re.match(r"^Function\s+%s\s*[:(]" % re.escape(fname), s)
        if keeping:
            out.append("'!Raw " + (l[1:] if l.startswith("\t") else l))
        if re.match(r"^End Function\b", s):
            depth -= 1
            if depth == 0:
                keeping = False
    return out


def interior(text, fname):
    """The statements inside `Function fname(...)`, de-indented one level, plus the
    file's '! pragmas -- which live outside the Function and must travel with it."""
    prag = [l for l in text.split("\n") if l.lstrip().startswith("'!")]
    prag += siblings_as_raw(text, fname)
    lines = text.split("\n")
    start = None
    for i, l in enumerate(lines):
        if re.match(r"^\s*Function\s+%s\s*[:(]" % re.escape(fname), l):
            start = i
            break
    if start is None:
        # BODY-ONLY FORMAT. Some module-function files carry statements alone, with no
        # `Function ... End Function` wrapper -- the same two on-disk shapes reverify.py
        # documents for src/recovered/. build_source_function supplies the wrapper, so
        # the whole file minus its comments IS the body.
        body = [l for l in lines
                if not l.lstrip().startswith("'") and l.strip()]
        if not body:
            return None
        return "\n".join(prag + [l[1:] if l.startswith("\t") else l for l in body])
    depth, end = 0, None
    for i in range(start, len(lines)):
        s = lines[i].strip()
        if re.match(r"^Function\b", s):
            depth += 1
        if re.match(r"^End Function\b", s):
            depth -= 1
            if depth == 0:
                end = i
                break
    if end is None:
        return None
    body = [l[1:] if l.startswith("\t") else l for l in lines[start + 1:end]]
    return "\n".join(prag + body)


def check(path):
    stem = os.path.basename(path)[:-4]
    text = open(path, encoding="utf-8", errors="replace").read()
    head = "\n".join(l for l in text.split("\n") if l.lstrip().startswith("'"))
    claimed = MARKER in text
    m = VA_RE.search(head)
    if not m:
        return stem, claimed, "SKIP", "no parseable VA header"
    va, size = int(m.group(1), 16), int(m.group(2))
    sm = SIG_RE.search(head)
    if not sm:
        d0 = declared(text, target_name(stem))
        if d0 is None:
            return stem, claimed, "SKIP", "no sig in header and no Function line to read"
        params = [x for x in d0[0].split(",") if x.strip()]
        codes = [sigcode(x.split(":", 1)[1]) if ":" in x else "i" for x in params]
        sm = re.match(r"(.*)", "(%s)%s" % (",".join(codes), sigcode(d0[1])))
    name = target_name(stem)
    if declared(text, name) is None:
        # A file may name its Function something other than its stem (the Fn_<va>. prefix
        # convention is not universal). Fall back to whatever single Function it declares.
        fns = re.findall(r"^\s*Function\s+([A-Za-z_]\w*)", text, re.M)
        if len(set(fns)) == 1:
            name = fns[0]
    body = interior(text, name)
    if body is None:
        return stem, claimed, "SKIP", "no `Function %s` found in the file" % name
    d = declared(text, name)
    r = harness.try_function(name, sm.group(1), body, va, decl=(d[0] if d else None))
    st = r.get("status")
    if st == "MATCH":
        return stem, claimed, ("OK" if claimed else "UNBANKED"), \
               "MATCH %s/%s mode=%s" % (r.get("matched"), size, r.get("mode"))
    if st in ("BUILD_FAIL", "ERROR", "UNCERTAIN_LEN"):
        return stem, claimed, "SKIP", "%s: %s" % (st, str(r.get("message"))[:150])
    detail = "%s our_len=%s orig_len=%s matched=%s first_diff=%s" % (
        st, r.get("our_len"), r.get("orig_len"), r.get("matched"), r.get("first_diff"))
    return stem, claimed, ("FALSE" if claimed else "KNOWN"), detail


def main():
    argv = sys.argv[1:]
    # --shard takes a VALUE ("0/4") which does not start with "--", so it must be removed
    # explicitly or it is read as a name filter and silently selects nothing.
    skip = set()
    for i, a in enumerate(argv):
        if a == "--shard" and i + 1 < len(argv):
            skip.add(i + 1)
    args = [a for i, a in enumerate(argv) if not a.startswith("--") and i not in skip]
    files = sorted(f for f in os.listdir(MODDIR) if f.endswith(".bmx"))
    if args:
        files = [f for f in files if any(a.lower() in f.lower() for a in args)]
    elif "--all" not in sys.argv:
        files = [f for f in files
                 if MARKER in open(os.path.join(MODDIR, f), encoding="utf-8",
                                   errors="replace").read()]
    if "--shard" in sys.argv:
        i, n = sys.argv[sys.argv.index("--shard") + 1].split("/")
        files = files[int(i)::int(n)]

    buckets = {}
    for f in files:
        stem, claimed, verdict, detail = check(os.path.join(MODDIR, f))
        buckets.setdefault(verdict, []).append((stem, detail))
        print("%-9s %-46s %s" % (verdict, stem, detail), flush=True)

    print("\n%s" % ("=" * 72))
    for k in ("FALSE", "UNBANKED", "SKIP", "KNOWN", "OK"):
        if k in buckets:
            print("%-9s %d" % (k, len(buckets[k])))
    if "FALSE" in buckets:
        print("\nMARKERS THE ORACLE REJECTS -- progress.py counts these and should not:")
        for stem, detail in buckets["FALSE"]:
            print("   %-46s %s" % (stem, detail))
    return 1 if "FALSE" in buckets else 0


if __name__ == "__main__":
    raise SystemExit(main())
