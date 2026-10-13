"""Rebuild NSS5-Mod-Loader.zip, the player download on the download branch. CI runs it.

    python modloader/download_zip.py <previous zip> <out dir> [--gcc path\\to\\gcc.exe]

winmm.dll and launcher.exe are built from this checkout. The game part (nss5_forge.exe.stripped,
refill.bin) needs NSS5.exe to build, so it comes from the newest release when that release
carries it, the same release the launcher's update looks at, otherwise from the previous zip.
Writes <out dir>.zip and changed=true|false (to $GITHUB_OUTPUT when set).
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.environ.get("GITHUB_REPOSITORY", "pr0sc0per9000/nss5-forge")
GAME = ("nss5_forge.exe.stripped", "refill.bin")


def fetch(url, token=None):
    req = urllib.request.Request(url, headers={"User-Agent": "nss5-forge-ci"})
    if token:
        req.add_header("Authorization", "Bearer " + token)
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


def contents(path):
    if not os.path.isfile(path):
        return {}
    with zipfile.ZipFile(path) as z:
        return {n: z.read(n) for n in z.namelist() if not n.endswith("/")}


def write(path, data):
    with open(path, "wb") as f:
        f.write(data)


def main():
    args = sys.argv[1:]
    gcc = []
    if "--gcc" in args:
        i = args.index("--gcc")
        gcc = args[i:i + 2]
        del args[i:i + 2]
    if len(args) != 2:
        sys.exit("usage: download_zip.py <previous zip> <out dir> [--gcc path]")
    prev, out = args

    # Drafts show up for a signed-in caller but not for the launcher, so skip them.
    releases = json.loads(fetch("https://api.github.com/repos/%s/releases?per_page=10" % REPO,
                                os.environ.get("GH_TOKEN")))
    releases = [r for r in releases if not r.get("draft")]
    tag = releases[0]["tag_name"] if releases else "0"
    assets = {a["name"]: a["browser_download_url"] for a in (releases[0]["assets"] if releases else [])}

    game = tempfile.mkdtemp()
    if all(n in assets for n in GAME):
        for n in GAME:
            write(os.path.join(game, n), fetch(assets[n]))
        write(os.path.join(game, "installed.txt"), tag.encode())  # no download on first play
        print("game part: release", tag, flush=True)
    else:
        old = contents(prev)
        for n in GAME + ("installed.txt",):
            if "Mods/core/" + n in old:
                write(os.path.join(game, n), old["Mods/core/" + n])
        if not all(os.path.isfile(os.path.join(game, n)) for n in GAME):
            sys.exit("no game part: release %s does not carry one and there is no previous zip" % tag)
        print("game part: previous zip (release %s does not carry one)" % tag, flush=True)

    subprocess.check_call([sys.executable, os.path.join(HERE, "build.py")] + gcc)
    subprocess.check_call([sys.executable, os.path.join(HERE, "pack_release.py"),
                           "--core", game, out, "--version", tag])
    shutil.rmtree(game)

    changed = contents(out.rstrip("\\/") + ".zip") != contents(prev)
    print("changed:", "true" if changed else "false")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write("changed=%s\n" % ("true" if changed else "false"))


if __name__ == "__main__":
    main()
