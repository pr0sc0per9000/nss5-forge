# w600 -- "PACE training: arrow keys do not move the player"

Investigation only. No corpus file was modified.

## Verdict

Root cause found, and it is **not** in the training code at all. It is a whole-program
Global-wiring split: the six TPlayer movement-physics Globals are **written under one name
and read under another**, and no alias row merges them. The reader-side names are therefore
never written and stay `0.0`.

The decisive one is **0x00C5DE50**:

* `TPlayer.SetUp` (VA 0x004EC179) writes it as `g_player_friction`
* `TPlayer.UpdateMovement` (VA 0x004F0468) reads it as `g_player_float05`
* `extracted/global_alias_unified.tsv` has **no row for 0x00C5DE50**

so the assembled program declares two separate Globals, and every frame executes
`Self.xvel = Self.xvel * 0.0`.

## Decisive split (asked for in the brief)

Our build **does** poll the arrow keys, and the gate **does** pass. The bug is
**DOWNSTREAM, in the movement branch.**

## Causal chain (each step measured)

1. `TJoy.Update` polls `KeyDown(g_opt_ctrlleft[0])` etc. and sets `axis_x`/`axis_y`,
   `force`, `direction`. The four control arrays resolve to four distinct canonical Globals
   (`g_options_arr04` / `g_ctrl_right` / `g_options_arr02` / `g_ctrl_down`), all `Int[2]`,
   all filled by `TOptions.LoadOptions` from `Settings/Options.ini`. Polling is intact --
   corroborated by the reporter's own observation that **Z (kick) works**, since the kick
   button is read from the same arrays in the same function.
2. `TPlayer.UpdateMovement` reads `Self.joy.direction` / `Self.joy.force` and computes
   `Local speed:Float = pace * g_player_float10`.
3. Every branch of the velocity update ends with a damping multiply. From the emitted
   whole-program source:

   ```
   If force > 0.2
       Self.xvel = Self.xvel + Cos(dir) * speed
       Self.yvel = Self.yvel + Sin(dir) * speed
   EndIf
   Self.xvel = Self.xvel * g_player_float05
   Self.yvel = Self.yvel * g_player_float05
   ```

4. `g_player_float05` is declared `Global g_player_float05:Float` with **no initialiser**,
   and is **written by nothing in the whole program** (0 writes, 4 reads). It is `0.0`.
5. So `xvel` and `yvel` are annihilated every frame, in all three branches
   (`currentanim = g_player_arr13`; `PlayerOnFeet() = 0` uses `g_player_float06`; the normal
   branch uses `g_player_float05`) -- both Globals are dead.
6. `If TTraining.PlayerCanMove(Self)` passes (see below), and executes
   `Self.x = Self.x + Self.xvel` -- adding `0.0`.
7. **The player never moves, whatever the arrow keys do.**

`g_player_float10` (`speed = pace * g_player_float10`) and `g_player_float09` (the mid-run
speed ramp) are dead the same way, so the velocity *addition* in step 3 is also zero for the
first 1500 ms. Two independent reasons for zero displacement.

## The full set of split addresses

`TPlayer.SetUp` reads these from `incbin::Inc/Engine.ini`
(`extracted/exe-assets/Engine.ini`, real values shown):

| address | written by `TPlayer.SetUp` as | Engine.ini value | read by `TPlayer.UpdateMovement` as | merged? |
|---|---|---|---|---|
| 0x00C5DE48 | `g_player_accel` | acceleration=0.55 | `g_player_float03` | **YES** |
| 0x00C5DE50 | `g_player_friction` | playerfriction=0.85 | `g_player_float05` | no → 0.0 |
| 0x00C5DE54 | `g_player_slidefriction` | slidefriction=0.92 | `g_player_float06` | no → 0.0 |
| 0x00C5DE60 | `g_player_joggingspeed` | joggingspeed=0.85 | `g_player_float09` | no → 0.0 |
| 0x00C5DE64 | `g_player_walkingspeed` | walkingspeed=0.75 | `g_player_float10` | no → 0.0 |
| 0x00C5DE90 | `g_player_energydrain` | -- | `g_player_float17` | no → 0.0 |

0x00C5DE48 is the control: it is the **only** one of the six with an alias row
(`global_alias_unified.tsv:212`), and it is the only one that works in the build --
`Self.xvel = Self.xvel + g_player_accel * 0.5` is correctly wired.

### Why the alias rows are missing

`extracted/global_address_map.tsv` grounds a name to an address only when the aligner could
force it. For these five it could not:

```
g_player_float05   -   AMBIGUOUS   Float   1   no alignment forced it (1 bodies)
g_player_float06   -   AMBIGUOUS   Float   1   no alignment forced it (1 bodies)
g_player_float09   -   AMBIGUOUS   Float   1   no alignment forced it (1 bodies)
g_player_float10   -   AMBIGUOUS   Float   1   no alignment forced it (1 bodies)
g_player_float17   -   AMBIGUOUS   Float   1   no alignment forced it (1 bodies)
```

`emit_unified_aliases.py` only emits rows for grounded names, so an ungrounded reader-side
name silently becomes its own zero-valued Global. Note that the sources disagree:
`extracted/globals_final.tsv` *does* carry `0x00c5de50  Float  g_player_float05` at tier
`high`, so the address is known -- it is only the *aligner* that failed to force it, and the
alias emitter trusts the aligner alone.

## Scope -- this is NOT Pace-specific

`TPlayer.UpdateMovement` is the shared movement update for **every** player. This defect
freezes all player movement everywhere, human and AI. It presents as "the first Pace
training" because that is the first moment in a new NSS5 career where the user directly
controls a player. That is a falsifiable prediction: if arrow keys DO move the player in some
other mode, this diagnosis is wrong.

## Positively ruled out

* **`TTraining.PlayerCanMove` (VA 0x005829ED)** -- the brief's prime suspect. Exonerated.
  Disassembly at 0x00582A0F reads `[0xc6cf90]`; `TTraining.Update`'s dispatch
  (`Select g_train_mode` → `Case 1: TTraining.UpdatePace()`) proves **Pace is mode 1**, and
  `Case 1` in `PlayerCanMove` is empty, so it falls through to `Return 1`. Only cases 3, 6
  and 10 can return 0, and even those require a live ball not controlled by the player.
* **The `g_intraining` rename in the uncommitted diff** -- harmless. All five files that use
  the name (`TTraining.PlayerCanMove` / `.Render` / `.TrainingSetPiece`, `TEngine.SkipTime` /
  `.UpdateMatchTime`) agree on 0x00C6CF90, and `global_alias_map()` collapses `g_tr_mode`,
  `g_train_mode`, `g_training_int03` and `g_intraining` onto one canonical name. Verified by
  running the assembler's own `global_alias_map()` (`scripts/workflow/w600_alias.py`).
* **The keyboard polling / key codes** -- `TJoy.Update` and the four `Int[2]` control arrays
  are consistently named and consistently filled by `TOptions.LoadOptions`. Independently
  corroborated by Z working.
* **Mode/state selection upstream** -- `TTraining.SetUpTraining` writes `g_training_int03 = a0`
  (canonicalises to `g_intraining`), and `StartChallenge` sets 0x00C6CF98 = 1, which
  `TTraining.Update` reads as `g_train_state` (also canonicalises to `g_training_state`).
  Both wired correctly.
* **Byte-level fidelity** -- irrelevant here. `PlayerCanMove` is 252/252 byte-identical and
  `UpdateMovement` is 4137/4137, and the game is still broken. This is exactly the
  whole-program-wiring class the brief warns about.

## Secondary defect found in passing (real, but NOT the cause of this symptom)

`TTraining.StartChallenge` (VA 0x0057FD35). The original is:

```
0x0057FD38  mov eax, dword ptr [0xc6efd4]     ; source
0x0057FD3D  mov dword ptr [0xc6cfa0], eax     ; destination
```

i.e. `g_train_lasttick(0xC6CFA0) = g_matchtime(0xC6EFD4)`. The file's own header states
`g_tr_screen = 0x00C6EFD4` and `g_tr_prevscreen = 0x00C6CFA0`, but
`extracted/global_address_map.tsv` has them **exactly inverted**:

```
g_tr_prevscreen   0x00C6EFD4   STRONG   forced in 1 body
g_tr_screen       0x00C6CFA0   STRONG   forced in 1 body
```

The likely mechanism is that the aligner pairs names in *source* order against addresses in
*code* order, and for a simple `a = b` assignment bcc emits the RHS load **before** the LHS
store, so the two are reversed. The emitted program consequently contains

```
g_matchtime = g_tr_screen
```

which clobbers the global millisecond clock with a never-written variable (0) and leaves
`g_train_lasttick` unseeded. The clobber is transient -- `g_matchtime = MilliSecs() - g_pausedms`
runs every frame -- so it does not cause the reported symptom, but it is a genuine defect and
the aligner bug behind it is systemic. Two further symptoms of the same corruption are visible
in the emitted source as the no-op self-assignments `g_matchtime = g_matchtime`.

## Proposed fix -- NOT APPLIED

Add five hand-verified rows to `extracted/global_alias_overrides.tsv` (the highest-precedence
table, which is exactly the documented escape hatch for "the groups build_alias_map.py
refused"):

```
0x00C5DE50	g_player_float05	g_player_friction
0x00C5DE54	g_player_float06	g_player_slidefriction
0x00C5DE60	g_player_float09	g_player_joggingspeed
0x00C5DE64	g_player_float10	g_player_walkingspeed
0x00C5DE90	g_player_float17	g_player_energydrain
```

Follow the existing file's column format. Do **not** fix this by editing
`TPlayer.UpdateMovement.bmx` -- it is byte-identical, and another worker is sweeping that tree.
The defect is in the alias table, not the body.

## How to confirm

Decisive, cheap, and runnable by anyone:

```
python scripts/workflow/w600_deadreads.py     # with W600_ASM pointing at an emitted build
```

It reports every Global that is read, never written, and has no initialiser -- 175 of them,
including `g_player_float05/06/09/10/17`. Then, in a private worker tree, add the five
override rows, re-emit, and re-run: those five must disappear from the list, and
`Self.xvel = Self.xvel * g_player_friction` must appear in `TPlayer.UpdateMovement`.

Behavioural confirmation: build in a private worker tree and start a new career; the player
should move under the arrow keys in the first Pace training.

## Scratch tooling written (safe, worker-600-scoped)

* `scripts/workflow/w600_alias.py` -- resolves names through the assembler's own `global_alias_map()`
* `scripts/workflow/w600_emit.py` -- emits the whole-program source into a scratch dir (never `src/assembled`)
* `scripts/workflow/w600_deadreads.py` -- the read-but-never-written Global detector
* `scripts/workflow/w600_readfloats.py`, `scripts/workflow/w600_xref.py` -- data-section reads and code xrefs
