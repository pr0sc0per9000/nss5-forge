"""Assemble the mod-loader release a player unzips into their game folder.

    python modloader/pack_release.py <built nss5_forge exe> <out dir> [--version TAG]

Lays out, from a freshly built exe and the compiled winmm.dll + launcher.exe in build/:

    <out>/winmm.dll
    <out>/Mods/core/winmm.dll
    <out>/Mods/core/launcher.exe
    <out>/Mods/core/nss5_forge.exe.stripped
    <out>/Mods/core/refill.bin
    <out>/Mods/core/version.txt          (the release tag; drives GitHub auto-update)
    <out>/Drop these into your New Star Soccer 5 folder.txt

Ships none of the game: nss5_forge.exe.stripped holds this project's own code with the game's
embedded files zeroed; the launcher refills them from the player's own NSS5.exe on first play.
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")

NOTE = (
    "New Star Soccer 5 mod loader\r\n\r\n"
    "Copy winmm.dll and the Mods folder next to NSS5.exe in your game folder:\r\n"
    "  Steam > New Star Soccer 5 > right click > Manage > Browse local files.\r\n\r\n"
    "Then press Play in Steam as normal. The first launch takes a second longer while it\r\n"
    "builds the game from your own copy. To remove the loader, delete winmm.dll and Mods.\r\n"
)


def main():
    version = "0"
    rest = sys.argv[1:]
    if "--version" in rest:
        i = rest.index("--version")
        version = rest[i + 1] if i + 1 < len(rest) else "0"
        del rest[i:i + 2]
    args = [a for a in rest if not a.startswith("--")]
    if len(args) != 2:
        sys.exit("usage: pack_release.py <built exe> <out dir> [--version TAG]")
    exe, out = args
    winmm = os.path.join(BUILD, "winmm.dll")
    launcher = os.path.join(BUILD, "launcher.exe")
    for p in (exe, winmm, launcher):
        if not os.path.isfile(p):
            sys.exit("missing %s (run modloader/build.py first)" % p)

    core = os.path.join(out, "Mods", "core")
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(core)

    subprocess.check_call([sys.executable, os.path.join(HERE, "forge", "pack.py"), exe, core])
    os.remove(os.path.join(core, "nss5_forge.exe.xz"))     # the launcher uses the raw .stripped
    os.remove(os.path.join(core, "refill.json"))           # tooling only; the launcher reads .bin
    shutil.copy2(winmm, os.path.join(out, "winmm.dll"))
    shutil.copy2(winmm, os.path.join(core, "winmm.dll"))
    shutil.copy2(launcher, os.path.join(core, "launcher.exe"))
    with open(os.path.join(core, "version.txt"), "w", newline="") as f:
        f.write(version)
    with open(os.path.join(out, "Drop these into your New Star Soccer 5 folder.txt"), "w", newline="") as f:
        f.write(NOTE)

    print("release laid out in", out)
    for root, _dirs, files in os.walk(out):
        for fn in sorted(files):
            p = os.path.join(root, fn)
            print("  %8d  %s" % (os.path.getsize(p), os.path.relpath(p, out).replace("\\", "/")))

    import zipfile
    zippath = out.rstrip("\\/") + ".zip"
    with zipfile.ZipFile(zippath, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for root, _dirs, files in os.walk(out):
            for fn in files:
                p = os.path.join(root, fn)
                z.write(p, os.path.relpath(p, out))
    print("player download: %s (%d bytes)" % (zippath, os.path.getsize(zippath)))


if __name__ == "__main__":
    main()
