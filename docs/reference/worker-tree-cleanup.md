# Worker-tree reclamation - inventory and decision record

Generated 2026-08-22 by the disk-reclamation pass over `tools/bmx-workers/`.
This file is written BEFORE any deletion so the decision is reviewable.

## 1. Why deleting a worker tree is safe

`scripts/harness.py` `_resolve_bmx_root()` (lines 71-85) resolves `NSS5_WORKER=<n>` to
`tools/bmx-workers/<n>` and **lazily recreates a missing tree**:

```python
    tree = os.path.join(WORKERS_DIR, str(w))
    if not os.path.exists(os.path.join(tree, "bin", "bmk.exe")):
        os.makedirs(WORKERS_DIR, exist_ok=True)
        tmp = tree + ".partial"
        shutil.rmtree(tmp, ignore_errors=True)
        shutil.copytree(BASE_BMX_ROOT, tmp)      # ~30-60s, once per worker
        os.replace(tmp, tree)
    return tree
```

**Confirmed: a fully absent tree is recreated automatically from
`tools/blitzmax-legacy-src` on next use.** The only cost is a one-off 30-60 s copy on the
first build under that worker id. No hard failure, no lost state. `tools/` is also
gitignored (`.gitignore:49 = /tools/`, `git ls-files tools/` returns 0 files), so worker
trees are untracked derived data by construction.

Two caveats found while confirming this, both of which shaped the keep list below:

1. **Regeneration restores a STOCK tree, never a customised one.** A tree whose
   `bin/bcc.exe` was rebuilt from patched `_src` is not reproduced by `copytree`.
   Such trees are *not* derived data and are kept.
2. **A PARTIAL tree is worse than an absent one.** `os.replace(tmp, tree)` fails on
   Windows when `tree` exists and is non-empty, so a tree that exists but lacks
   `bin/bmk.exe` will not self-heal - it will raise. Full deletion is safe; leaving a
   half-tree behind is not. See `603` in section 4.

## 2. Totals

| | trees | size |
|---|---|---|
| before  | 269 | 49.24 GiB |
| planned keep | 36 | 6.46 GiB |
| planned delete | 233 | 42.78 GiB |
| **actually deleted** | **232** | **42.60 GiB** |
| **after** | **41** | **7.38 GiB** |

Disk free went 1460.83 GiB -> 1504.72 GiB, i.e. **43.89 GiB reclaimed**. 232 removals, zero
failures, no path-length or locked-file problems.

The after-count of 41 exceeds the 36 planned keeps for two reasons, both good:

* `300` was **spared mid-run**. It was idle at scan time but an worker touched it at
  21:58:49 while batch 2 was executing; the per-tree re-check caught it and kept it. This
  is the clearest argument for re-checking liveness per batch rather than once up front.
* `713`, `720`, `724` and `730` **did not exist when the inventory was taken** and were
  created by other workers during the run. They were never in the delete list (frozen at
  scan time), so they were never at risk. `713`/`720`/`724` are on the named protect list;
  `730` is new work nobody had mentioned.

Master toolchain `tools/blitzmax-legacy-src`: 5,009 files, 187.9 MB,
`bcc.exe` sha256 `64835AEA...`, `bmk.exe` sha256 `DA76BF16...`. **Never touched.**

## 3. Liveness evidence used

* **Named protect list**: `711 712 713 720 722 724` and any name starting with those.
  At scan time only `711`, `712`, `722` existed on disk; `713`, `720`, `724` were created by
  other workers later, while the deletion was already running (see section 2).
* **Process sweep**: `Get-CimInstance Win32_Process` matched against
  `bmx-workers/<n>` in `CommandLine`/`ExecutablePath`. No live `bcc`/`bmk`/`ld`/
  `g++`/`fasm` found; one live `python scripts/workflow/w722_emit.py` (pid 28036).
* **Build locks**: `%TEMP%/nssforge/build.<tree>.lock` (`harness.py:1303`). Nine locks
  present (`cv123_4/5/6/10/11/12/13/15`, `220`); **every holder PID was dead**, so all
  nine are stale, not live.
* **Deep mtime**: max `LastWriteTime` over every file in the tree. Tree-root mtimes are
  useless here - `copytree` copies the master's directory stat, so all 269 roots read
  `2026-08-04`.
* **Toolchain hash**: sha256 of `bin/bcc.exe` and `bin/bmk.exe` vs master.
* **Content diff**: top-level entries vs master (17 entries); only `603` differs.

## 4. Kept trees (36)

| tree | MB | last modified | why kept |
|---|---|---|---|
| `700` | 187.9 | 2026-08-22 20:34:06 | 7xx active family (adjacent to live trees) |
| `701` | 187.9 | 2026-08-22 20:34:06 | 7xx active family (adjacent to live trees) |
| `702` | 187.9 | 2026-08-22 20:59:27 | 7xx active family (adjacent to live trees) |
| `703` | 187.9 | 2026-08-22 21:09:45 | 7xx active family (adjacent to live trees) |
| `710` | 187.9 | 2026-08-22 21:22:00 | 7xx active family (adjacent to live trees) |
| `121` | 187.9 | 2026-08-22 15:10:40 | NON-STOCK toolchain / not regenerable |
| `200` | 190 | 2026-08-22 15:37:13 | NON-STOCK toolchain / not regenerable |
| `220` | 189.8 | 2026-08-22 16:21:12 | NON-STOCK toolchain / not regenerable |
| `221w` | 188.8 | 2026-08-22 16:12:45 | NON-STOCK toolchain / not regenerable |
| `229walloc` | 188.8 | 2026-08-22 16:16:00 | NON-STOCK toolchain / not regenerable |
| `232w` | 188.8 | 2026-08-22 16:15:09 | NON-STOCK toolchain / not regenerable |
| `255` | 188.8 | 2026-08-22 16:37:05 | NON-STOCK toolchain / not regenerable |
| `261` | 188.8 | 2026-08-22 16:58:16 | NON-STOCK toolchain / not regenerable |
| `431` | 188.8 | 2026-08-18 19:26:56 | NON-STOCK toolchain / not regenerable |
| `433` | 188.8 | 2026-08-18 19:18:19 | NON-STOCK toolchain / not regenerable |
| `435` | 188.8 | 2026-08-18 19:19:55 | NON-STOCK toolchain / not regenerable |
| `603` | 13.1 | 2026-08-22 20:13:47 | NON-STOCK toolchain / not regenerable |
| `w225walloc` | 188.8 | 2026-08-22 16:10:24 | NON-STOCK toolchain / not regenerable |
| `w233alloc` | 188.8 | 2026-08-22 16:11:29 | NON-STOCK toolchain / not regenerable |
| `w251` | 188.8 | 2026-08-22 16:53:47 | NON-STOCK toolchain / not regenerable |
| `w276walloc` | 188.8 | 2026-08-22 17:49:53 | NON-STOCK toolchain / not regenerable |
| `walloc` | 188.8 | 2026-08-22 17:10:05 | NON-STOCK toolchain / not regenerable |
| `walloc222` | 188.8 | 2026-08-22 16:06:15 | NON-STOCK toolchain / not regenerable |
| `walloc223` | 188.8 | 2026-08-22 16:10:03 | NON-STOCK toolchain / not regenerable |
| `walloc224` | 188.8 | 2026-08-22 16:08:54 | NON-STOCK toolchain / not regenerable |
| `walloc226` | 188.8 | 2026-08-22 16:11:14 | NON-STOCK toolchain / not regenerable |
| `walloc227` | 187.9 | 2026-08-22 16:10:24 | NON-STOCK toolchain / not regenerable |
| `walloc228` | 188.8 | 2026-08-22 16:19:38 | NON-STOCK toolchain / not regenerable |
| `walloc231` | 188.8 | 2026-08-22 16:11:55 | NON-STOCK toolchain / not regenerable |
| `walloc252` | 188.8 | 2026-08-22 16:35:34 | NON-STOCK toolchain / not regenerable |
| `walloc254` | 188.8 | 2026-08-22 16:37:00 | NON-STOCK toolchain / not regenerable |
| `walloc257` | 188.8 | 2026-08-22 16:37:41 | NON-STOCK toolchain / not regenerable |
| `walloc275` | 188.8 | 2026-08-22 17:22:12 | NON-STOCK toolchain / not regenerable |
| `711` | 187.9 | 2026-08-22 21:09:45 | protect-list prefix |
| `712` | 187.9 | 2026-08-22 21:30:09 | protect-list prefix |
| `722` | 187.9 | 2026-08-22 21:30:09 | protect-list prefix |

Five further trees survive on disk that are not in this table - `300`, `713`, `720`, `724`,
`730` - all for reasons that arose after the inventory was frozen. See section 2.

### Notes on the kept set

* **`603` is not a toolchain copy at all.** It is 32 files / 13.1 MB containing
  `w603/` with hand-written probe sources (`nullm.bmx`, `nullfn.bmx`,
  `nullchan.bmx`, `chan2probe.bmx`) and their build output, written 20:01-20:13 on
  2026-08-22. This is original work, not derived scratch, and nothing would regenerate
  it. It also has no `bin/` at all, so per caveat 2 above a `NSS5_WORKER=603` build
  would now fail rather than self-heal - worth a human decision (move `w603/` somewhere
  under `scratch/` and let the tree regenerate).
* **28 trees carry a non-stock `bcc.exe`**, each with a distinct hash - these are the
  allocator-instrumentation builds (`walloc*`, `*alloc*`, `221w`, `232w`, `w251`
  etc.). `rebuildbcc.bat` can rebuild an instrumented compiler in principle, but the
  specific patch per tree is not recorded anywhere retrievable, and `copytree` would
  return a stock compiler. Kept as not-regenerable.
* **`700 701 702 703 710`** are stock and just outside the 30-minute window
  (20:34-21:22), but they are the same active 7xx wave as the named-live `711`/`712`/
  `722`. Kept as ambiguous per the stated rule that a needless 188 MB beats killing a run.
* `w16_G0` and `w21_L4`, named in `docs/archive/waves/` as holding instrumented
  compilers, **no longer exist** - removed by an earlier cleanup. Those doc references are
  stale.

## 5. Deleted trees (232 of the 233 listed)

The list below is the delete plan as frozen at scan time. All 233 were removed **except
`300`**, which the batch-2 liveness re-check spared; it is still on disk.

All were stock (`bcc.exe` and `bmk.exe` byte-identical to master), had no extra
top-level content, held no live lock or process, and were idle well beyond 30 minutes.
Each regenerates on demand at a one-off 30-60 s cost.

Deleted, grouped by family:

**cv123_* (stale-lock batch, all holder PIDs dead)** (16):

```
cv123_0 cv123_1 cv123_10 cv123_11 cv123_12 cv123_13 cv123_14 cv123_15 cv123_2 cv123_3 cv123_4 cv123_5 cv123_6 cv123_7 cv123_8 cv123_9
```

**named-worker trees (script defaults)** (31):

```
agent_tball_checkforplayerratings census check_literal_order_modfns check_literal_order2 check_literals composition finish fm g1 gm_bp12 localise probe probe1 refine2_gpp refine2_rps refine9 refineSR reverify scratchscore task_checkfmt tmp_probe_panel w13_TBallUM w23_final w23_final2 w23_L1 w23_L2 w23_L3 w23_verify w23_verify2 w24dpb w50refine_gcs
```

**numeric shard trees** (186):

```
1 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 120 123 130 131 132 133 134 135 136 137 160 170 180 190 2 201 205 206 207 210 211 212 213 214 215 216 217 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 245 246 247 248 249 250 251 252 253 254 256 257 258 260 262 269 27 270 271 272 273 274 275 276 277 278 290 291 292 293 294 295 3 300 310 320 320b 321 321b 322 322b 323 3232 324 325 325b 326 326b 340 341 350 351 352 353 354 355 356 360 361 362 363 364 365 366 367 368 379 380 380b 381 381b 382 382b 383 383b 384 385 385b 385c 385d 385e 385f 385g 385h 385i 385j 385k 385l 4 400 401 402 403 404 405 406 407 408 409 410 411 412 420 421 422 423 430 432 434 440 441 442 443 5 500 501 6 600 604 7 8
```

Named-worker trees are the defaults hard-coded in checked-in scripts
(`check_assembled.py`=composition, `check_floats.py`=floats,
`check_literals.py`=check_literals, `framework_assembled.py`=fwasm,
`framework_probe.py`=fwprobe, `localise_diff.py`=localise, `reverify.py`=reverify).
Deleting them is safe; the next run of each script simply pays the 30-60 s recopy once.

## 6. Other bulk reviewed (NOT deleted)

| path | size | finding |
|---|---|---|
| `status/debugruns/` | 5.1 MB over 7 runs | Already small. The 164 MB `trace.bin` from the earlier run is **already gone**. `20260822-213034` (0.3 MB) preserved as instructed. No action needed. |
| `src/assembled/` | 280.2 MB, 879 files | Derived build output, but `nss5_dbg.exe`/`nss5_assembled.exe` were rewritten at 21:29-21:30 tonight - actively in use. `dbg*.txt` are 62.5 MB over 16 files. Regenerating needs `assemble.py`, which is out of bounds while workers are live. **Recommend deferring**; the stale `dbgA.txt` (13.7 MB, 08-15) and `err.txt` (7.2 MB, 08-16) are the only clearly cold items. |
| `ghidra-project/` | 85.3 MB | Ghidra analysis DB. Not scratch. Keep. |
| `scratchpad/blitzmax-upstream/` | 41.7 MB | Reference git clone. Keep. |
| everything else outside `tools/` | ~500 MB total | Nothing worth reclaiming. |

The 50 GB problem was entirely `tools/bmx-workers/`; no other directory in the repo is
large enough to matter.

## 7. Verification after the run

* `tools/blitzmax-legacy-src` untouched: `bin/bcc.exe` and `bin/bmk.exe` both present,
  hashes unchanged. Nothing outside `tools/bmx-workers/` was deleted.
* 232 DEL, 5 KEEP, **0 FAIL**, 0 SKIP in the deletion log.
* Every removal was a recursive forced delete followed by a `Test-Path` assertion, so a
  silently-partial removal would have been reported as a failure. None occurred.

### How to redo this

The guards that mattered, ordered by how much they saved:

1. sha256 of `bin/bcc.exe` + `bin/bmk.exe` vs the master - caught 28 non-regenerable trees.
2. Fresh deep-mtime check **per tree at deletion time** - caught `300` mid-run.
3. Top-level entry diff vs the master - caught `603`, a probe workspace, not a toolchain.
4. Lock-file PID liveness (`%TEMP%/nssforge/*.lock`) - all 9 locks were stale; without the
   PID check they would have looked live and cost ~1.7 GB of needless retention.

Tree-root mtime is useless as a liveness signal here and must not be relied on: `copytree`
copies the master directory stat, so all 269 roots reported the same 2026-08-04 timestamp.
