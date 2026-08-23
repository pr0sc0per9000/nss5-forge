# Null-dereference probes

Four minimal BlitzMax programs that establish, empirically, what the runtime does when you
touch a `Null` Global. Every runtime crash diagnosed on 2026-08-22 turned on one of these
answers, and each was previously being *assumed*.

They exist because the dominant defect in this reconstruction is a Global that is written
under one name and read under another: the reader half is never written and holds `Null` or
`0` for the whole run. What that costs you at the moment of the read is not obvious -- some
Null accesses fault, some quietly return zero -- and the difference decides whether a defect
presents as a hard crash or as a silently wrong number.

## Running one

Any worker tree will do. From a tree's root:

    NSS5_WORKER=<n> <tree>/bin/bmk.exe makeapp -d -t console nullm.bmx

Build with `-d`. A release build strips the null checks and several of these simply return 0
instead of faulting, which is the opposite of what you are trying to measure.

## What each one establishes

### `nullm.bmx` -- field read vs method call on a Null object
Declares a Type with eight methods, sets a Global of that type to `Null`, reads a field, then
calls the eighth method. Output stopped after:

    field read: 0
    about to call M8 on Null

So **reading a field of a Null object succeeds and yields 0; calling a method on it faults.**
The eight methods are there to put the call well down the vtable rather than at slot 0, which
is what makes it a test of the call itself rather than of the object pointer.

This is the behaviour behind the ball-pickup crash: `TBall.CheckSideLines` does
`If g_playerteam.id = p.teamid`, and `g_playerteam` was `Null`.

### `nullfn.bmx` -- calling a Null function pointer
Prints the pointer as an integer, then calls it. An unassigned function-pointer Global does
not hold 0 -- it holds BlitzMax's null-function stub, and calling it throws rather than
returning.

This is behind the training-completion crash: `TEngine.EndMatch` ends with
`g_engine_fnend()`, and nothing wrote that slot.

### `nullchan.bmx` -- `StopChannel(Null)`
Output stopped after:

    chn1 is Null: 1
    about to StopChannel(Null)

**BRL's `StopChannel` is an unguarded `channel.Stop`, so a Null channel faults.** This is
the quit crash exactly: `StopChannels` passed four never-allocated channel Globals straight
into it.

Worth noting for the enumerator: a Global handed to a function that dereferences it is just
as fatal as dereferencing it yourself, but `scripts/dead_globals.py` classifies the call site
as SILENT because there is no `.` after the name. Its CRASH count is a lower bound.

### `chan2probe.bmx` -- which `TChannel` methods fault on Null
Calls `SetVolume`, `SetPaused` and `Stop` in turn on a Null channel. Output stopped after:

    A: about to SetVolume on Null

So `SetVolume` faults too, not only `Stop`. That mattered for `TEngine.UpdateSounds`, which
calls `.SetVolume` on the same channels every frame of a real match and would have faulted on
the first one.

## Why they live here

They were written in `tools/bmx-workers/603/`, which disk-reclamation passes treat as
disposable derived scratch -- worker trees are copies of the master toolchain and are meant to
be deletable. The 2026-08-22 cleanup deleted 232 trees and spared this one only incidentally,
because it hash-checked `bin/bcc.exe` and found it missing. Hand-authored work does not belong
in a directory whose whole contract is "safe to delete", so the sources moved here and the
build output was discarded.

See `docs/reference/worker-tree-cleanup.md` section 4.
