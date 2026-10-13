"""Assemble the mod-loader release a player unzips into their game folder.

    python modloader/pack_release.py <built nss5_forge exe> <out dir> [--version TAG]
    python modloader/pack_release.py --core <dir> <out dir> [--version TAG]

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

--core takes nss5_forge.exe.stripped and refill.bin (and installed.txt, if there) from <dir>
instead of a built exe. CI uses it, since it cannot build the game.
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")

NOTE = (
    "New Star Soccer 5 mod loader\r\n\r\n"
    "1. Extract this zip.\r\n"
    "2. Move everything inside it into your New Star Soccer 5 folder (the one with NSS5.exe):\r\n"
    "   in Steam, right click New Star Soccer 5 > Manage > Browse local files.\r\n"
    "3. Press Play in Steam as normal.\r\n\r\n"
    "The first launch takes a second longer while it builds the game from your own copy.\r\n"
    "To remove the loader, delete winmm.dll and the Mods folder.\r\n"
)


def main():
    version = "0"
    core_from = None
    rest = sys.argv[1:]
    if "--version" in rest:
        i = rest.index("--version")
        version = rest[i + 1] if i + 1 < len(rest) else "0"
        del rest[i:i + 2]
    if "--core" in rest:
        i = rest.index("--core")
        core_from = rest[i + 1] if i + 1 < len(rest) else ""
        del rest[i:i + 2]
    args = [a for a in rest if not a.startswith("--")]
    if len(args) != (1 if core_from else 2):
        sys.exit("usage: pack_release.py <built exe> <out dir> [--version TAG]\n"
                 "       pack_release.py --core <dir> <out dir> [--version TAG]")
    out = args[-1]
    winmm = os.path.join(BUILD, "winmm.dll")
    launcher = os.path.join(BUILD, "launcher.exe")
    need = [winmm, launcher]
    if core_from:
        need += [os.path.join(core_from, fn) for fn in ("nss5_forge.exe.stripped", "refill.bin")]
    else:
        need.append(args[0])
    for p in need:
        if not os.path.isfile(p):
            sys.exit("missing %s (run modloader/build.py first)" % p)

    core = os.path.join(out, "Mods", "core")
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(core)

    if core_from:
        for fn in ("nss5_forge.exe.stripped", "refill.bin", "installed.txt"):
            if os.path.isfile(os.path.join(core_from, fn)):
                shutil.copy2(os.path.join(core_from, fn), os.path.join(core, fn))
    else:
        subprocess.check_call([sys.executable, os.path.join(HERE, "forge", "pack.py"), args[0], core])
        os.remove(os.path.join(core, "nss5_forge.exe.xz"))     # the launcher uses the raw .stripped
        os.remove(os.path.join(core, "refill.json"))           # tooling only; the launcher reads .bin
    shutil.copy2(winmm, os.path.join(out, "winmm.dll"))
    shutil.copy2(winmm, os.path.join(core, "winmm.dll"))
    shutil.copy2(launcher, os.path.join(core, "launcher.exe"))
    shutil.copy2(os.path.join(HERE, "mods_icon.png"), os.path.join(core, "mods_icon.png"))
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
