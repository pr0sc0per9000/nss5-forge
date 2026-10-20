"""Stamp version info (and, for launcher.exe, an application manifest) into a linked PE file.

    python modloader/stamp.py <file> --description TEXT --name FILE --version TAG [--manifest]

The BlitzMax MinGW has no resource compiler, so this writes the resources after linking with the
Windows UpdateResource API. Run it before the file is signed: signing hashes the whole file.
Windows only.
"""
import ctypes
import re
import struct
import sys
from ctypes import wintypes

PRODUCT = "NSS5 Mod Loader"
COMPANY = "NSS5 Forge"
URL = "https://github.com/pr0sc0per9000/nss5-forge"
COPYRIGHT = "Copyright (c) 2026 nss5-forge contributors. MIT License."

RT_VERSION, RT_MANIFEST = 16, 24
LANG = 0x0409        # US English
CODEPAGE = 0x04B0    # Unicode

# asInvoker: never asks for elevation. The compatibility list keeps Windows from applying
# legacy shims to a file with no manifest.
MANIFEST = b"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
      </requestedPrivileges>
    </security>
  </trustInfo>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <supportedOS Id="{e2011457-1546-43c5-a5fe-008deee3d3f0}"/>
      <supportedOS Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"/>
      <supportedOS Id="{4a2f28e3-53b9-4441-ba9c-d69d4a4a6e38}"/>
      <supportedOS Id="{1f676c76-80e1-4239-95bb-83d0f6d0da78}"/>
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
    </application>
  </compatibility>
</assembly>
"""


def u16(s):
    return s.encode("utf-16-le") + b"\0\0"


def pad4(b):
    return b + b"\0" * (-len(b) % 4)


def node(key, value=b"", children=b"", text=True, value_words=None):
    """One VS_VERSIONINFO-style node: wLength, wValueLength, wType, szKey, value, children."""
    head = struct.pack("<HHH", 0, 0, 1 if text else 0)
    body = pad4(head + u16(key))
    if value:
        body += pad4(value)
    body += children
    vlen = value_words if value_words is not None else (len(value) // 2 if text else len(value))
    return struct.pack("<HH", len(body), vlen) + body[4:]


def version_numbers(tag):
    nums = [int(n) for n in re.findall(r"\d+", tag)[:3]]
    return tuple(nums + [0] * (4 - len(nums)))


def version_info(name, description, tag):
    a, b, c, d = version_numbers(tag)
    ver = "%d.%d.%d.%d" % (a, b, c, d)
    fixed = struct.pack("<IIIIIIIIIIIII", 0xFEEF04BD, 0x00010000,
                        (a << 16) | b, (c << 16) | d, (a << 16) | b, (c << 16) | d,
                        0x3F, 0, 0x00040004, 0x2 if name.lower().endswith(".exe") else 0x1, 0, 0, 0)
    strings = [
        ("CompanyName", COMPANY), ("FileDescription", description), ("FileVersion", ver),
        ("InternalName", name), ("LegalCopyright", COPYRIGHT), ("OriginalFilename", name),
        ("ProductName", PRODUCT), ("ProductVersion", tag), ("Comments", "Source and build: " + URL),
    ]
    table = b"".join(pad4(node(k, u16(v))) for k, v in strings)
    sfi = node("StringFileInfo", children=node("%04X%04X" % (LANG, CODEPAGE), children=table))
    vfi = node("VarFileInfo", children=node("Translation", struct.pack("<HH", LANG, CODEPAGE),
                                            text=False))
    return node("VS_VERSION_INFO", fixed, pad4(sfi) + vfi, text=False)


def update(path, resources):
    k = ctypes.WinDLL("kernel32", use_last_error=True)
    k.BeginUpdateResourceW.restype = wintypes.HANDLE
    k.BeginUpdateResourceW.argtypes = [wintypes.LPCWSTR, wintypes.BOOL]
    k.UpdateResourceW.restype = wintypes.BOOL
    k.UpdateResourceW.argtypes = [wintypes.HANDLE, ctypes.c_void_p, ctypes.c_void_p, wintypes.WORD,
                                  ctypes.c_void_p, wintypes.DWORD]
    k.EndUpdateResourceW.restype = wintypes.BOOL
    k.EndUpdateResourceW.argtypes = [wintypes.HANDLE, wintypes.BOOL]
    h = k.BeginUpdateResourceW(path, False)
    if not h:
        raise OSError(ctypes.get_last_error(), "BeginUpdateResource " + path)
    ok = True
    for rtype, data in resources:
        buf = ctypes.create_string_buffer(data, len(data))
        ok = k.UpdateResourceW(h, rtype, 1, LANG, buf, len(data)) and ok
    if not k.EndUpdateResourceW(h, not ok):
        raise OSError(ctypes.get_last_error(), "EndUpdateResource " + path)
    if not ok:
        raise OSError("UpdateResource failed for " + path)


def main():
    args = sys.argv[1:]

    def opt(flag, default=None):
        return args[args.index(flag) + 1] if flag in args else default

    if not args or args[0].startswith("--") or not (opt("--description") and opt("--version")):
        sys.exit(__doc__)
    path = args[0]
    name = opt("--name", path.replace("\\", "/").rsplit("/", 1)[-1])
    res = [(RT_VERSION, version_info(name, opt("--description"), opt("--version")))]
    if "--manifest" in args:
        res.append((RT_MANIFEST, MANIFEST))
    update(path, res)
    print("stamped", path)


if __name__ == "__main__":
    main()
