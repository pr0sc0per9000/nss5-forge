# `binary/` - your copy of the original game

**Nothing in this directory is committed, and nothing in it ships with the
repository.** New Star Soccer 5 is a commercial product and its files belong to
New Star Games Ltd.

To populate this directory, run the setup script with the path to your own
installation:

```bash
python scripts/setup.py --steam-path "C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5"
```

It will locate a Steam install automatically where it can, so in most cases
plain `python scripts/setup.py` is enough.

## What lands here

| file | bytes | why it is needed |
|---|---|---|
| `NSS5.exe` | 9,383,424 | the reconstruction is compared against it byte for byte |
| `steamstub.dll` | 498,688 | present in the retail install; not used by the rebuild |
| `IRClipboardFunctions.dll` | 45,056 | present in the retail install; not used by the rebuild |

## Why the checksums matter

`checksums.json` records the exact SHA-256 of each file. The setup script
verifies your copy against it before doing anything else, so a different build
of the game is reported immediately and by name - rather than surfacing forty
minutes later as an inexplicable build failure.

If verification fails, your copy is a different version from the one this
reconstruction targets. That is worth knowing straight away; it is not a fault
in your install.
