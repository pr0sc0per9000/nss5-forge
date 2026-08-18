' TCompetition.CreateFixtureListLeague -- NOT VERIFIED (worker boot_FixturesLeague)
' VA 0x0050B420   1530 bytes   vtable slot 0x68   sig ()i
' Ours: 1518 bytes (delta -12, orig 1530), as of this pass. Was 1548/+18/207-of-1530
' matched (13.5%) at the start of this pass. localise_diff.py now reports 9
' length-changing gaps (-12 total, COMPLETE) and 3 same-length subs, first real
' divergence at ORIGINAL +617 -- up from 26 gaps/+18/39 subs/first_diff=+3.
'
' THIS PASS's FIX -- a THIRD codegen shape was missing from the prior notes below: a
' block-scoped boolean Local (`Local x:Int = False` then a couple of `If`s that set it,
' then `If x Then ...`) that stands in for what the ORIGINAL compiles as ONE compound
' `And`/`Or` condition directly on the `If`/`While`, with NO Local at all. Confirmed by
' `localise_diff.py` for FIVE separate occurrences in this body (each one an `insert`
' gap showing OURS doing an extra `mov reg,0`/register init that the original simply
' does not have at that point, immediately followed downstream by matching materialize-
' then-branch bytes once the compound condition is inlined):
'   * Case 1 of the `navailweeks` Select (`wk`) -> `If d.GetWeek()<48 And d.GetWeek()>6`
'   * the `special` flag -> folded directly into the cascade's first test:
'     `If level = 1 And duration < 9 ... ElseIf shortfall>0 And matchnum Mod
'     shortfallstep=0 ... Else ... EndIf` (no `special` Local; this ALSO fixed the loop
'     shape underneath -- see next point)
'   * `dok`, `ok3`, `ok2` -- each was a `Repeat/Forever` with a Local materializing the
'     exit test; the original is a `While/Wend` (a forward `jmp` straight to the
'     condition check before the first body execution, THEN loop back -- the classic
'     goto-while shape, not Repeat's fall-into-body-first shape) with the condition
'     written directly as the `And`/`Or` compound, and with `CheckFixtureClash(d)` used
'     BARE (no `<> 0`) whenever it is the trailing operand of an Or feeding a branch --
'     writing the explicit `<>0` on a bare-call-as-condition costs an extra
'     setne/movzx that the original does not pay.
'   * `clash` (final fallback branch's second While) -- same story, no Local:
'     `While CheckFixtureClash(d) <> 0 ... Wend` calls it fresh each iteration; the
'     original never caches the first call into a Local before the loop.
' Two more (small, `sub`-level, not gap-level) fixes alongside these:
'   * `poolsize`/`extra` initialisation order was swapped (`extra=0` before
'     `poolsize=nqual` in the old draft; the original stores poolsize's slot BEFORE
'     extra's -- plain statement-order, not a register issue).
'   * `navailweeks < matchesneeded` vs `matchesneeded > navailweeks` -- same truth
'     table, but the original's `cmp esi,[mem]/jle` puts the register operand FIRST,
'     which only the second spelling reproduces (10.1's "relational spelling" note,
'     same family as the `groups>=5` vs `groups>4` swap already noted below).
' The `(g/2)+(matchnum-1)*4` formula also needed its literal (and otherwise pointless)
' `+1 ... -1` round trip restored -- `(g / 2 + 1) + (matchnum - 1) * 4 - 1` -- Ghidra's
' decompile silently constant-folds it away, but the raw bytes keep both the `add eax,1`
' and the later `sub eax,1` as separate instructions (confirmed by a GAP showing OURS
' missing exactly those 5 bytes), so the original source really did write it that way.
'
' Builds a league season's round-robin fixture list (docs/game/career/season-structure.md
' documents the football-level behaviour this backs). Depends on the now-VERIFIED module
' Function `SelectFixtureTable` (src/recovered_module/SelectFixtureTable.bmx, 713/713
' MATCH) for the DefData/RestoreData pairing-table dispatch, and on
' `TCompetition.GetHomeAndAwayTeam` (classtable slot 0x70, masked structurally by slot --
' does not itself need to be recovered for THIS body to verify) for pulling one pair at a
' time out of whichever table SelectFixtureTable pointed at.
'
' STRUCTURAL FINDINGS -- confirmed by reading the raw disassembly (this VA has no
' reflection record beyond the Method itself; nothing here came from the decompiler's
' variable names, only from `harness.disasm_original` / `localise_diff.py` read directly
' against NSS5.exe):
'
'  1. The opening guard is a REAL early return, not a wrapping `If Not(...) Then <body>
'     EndIf`. `comptype=0 And duration=0` is tested as two chained sete/movzx pairs
'     (short-circuit, comptype checked first) and only THEN does `Return 0` fire; the rest
'     of the function is flat, not nested inside an If. Getting this right was the single
'     biggest structural fix (dropped the body from 1660 to ~1660 immediately, then
'     unblocked everything downstream -- a wrapping-If draft can never converge because
'     every later branch's jump targets are offset by the extra nesting).
'  2. `If Not lfixturelist Then lfixturelist = CreateList()` -- NOT `If lfixturelist =
'     Null`. The `Not` object-truthiness form is the longer 19-21 byte
'     mov/cmp/setne/movzx/cmp/jne shape (codegen-patterns.md 10.3); the original uses it
'     here even though a plain Null test would be semantically identical and shorter.
'  3. TWO places dispatch on `level` (0/1) with `Select level / Case 0 ... Case 1 ...`,
'     NOT `If level=0 ... ElseIf level=1 ...` -- confirmed by the classic Select shape
'     (both `cmp`s emitted back-to-back before either body, guide 10.2): once inside the
'     per-week `navailweeks` counting loop, and once in the spacing/shortfall setup
'     (`spacing = navailweeks/(matchesneeded+1)` vs the level=0 shortfall calc).
'  4. **`matchnum` (the "which round" counter, `local_10` in Ghidra's naming) is
'     incremented IN PLACE, once, unconditionally, the instant `i Mod half = 0` is true**:
'     `matchnum = matchnum + 1` compiles to a single `add dword [slot],1` right at the top
'     of that block, BEFORE the special/shortfall/normal dispatch even begins. Ghidra's
'     decompile shows a separate `iVar1 = local_10 + 1` temp with scattered `local_10 =
'     iVar1` copies inside each branch -- that reading is an SSA artifact, not source
'     structure. There is no separate "rnd" Local in the real source; every place that
'     needs the OLD (pre-increment) value writes `matchnum - 1` explicitly (confirmed at
'     the `groups*(matchnum-1)+g` / `(g/2)+(matchnum-1)*4` formulas, which is literally
'     `mov ecx,[slot] / sub ecx,1` in the disassembly, not a second stored copy).
'  5. The `secondarymatchday=99` sub-branch's `groups<5` test is SWAPPED under
'     codegen-patterns.md 21's solo-relational branch-swap rule: the real source tests
'     the complex-calc side positively (confirmed spelled as `If groups > 4` -- NOT
'     `>= 5`: that spelling is what actually reproduces `cmp groups,4 / jle <simple,
'     i.e. the ELSE content>` byte for byte; `>=5` alone left a stray extra `mov
'     ecx,ebx` a few bytes downstream even with the jump/immediate already matching, so
'     treat `>4` as the confirmed spelling, not just "some >=5-equivalent test") with
'     the complex content at the fallthrough. Writing the naive `If groups<5 Then simple
'     Else complex` gives the wrong branch/jump mapping even though both formulas
'     themselves were already right.
'  6. The three-way `special / shortfall-decrement / normal` cascade's middle test is
'     `shortfall > 0 And matchnum Mod shortfallstep = 0` (POSITIVE polarity, gating entry
'     to the decrement/esi-loop branch), not `shortfall < 1 Or matchnum Mod shortfallstep
'     <> 0` gating the normal branch -- De Morgan's-equivalent but different bytes; match
'     the literal original polarity, not just the logical meaning.
'  7. `If matchnum > 1 / If spacing > 1 Then AddWeeks(spacing) Else AddDays(1)` -- ANOTHER
'     instance of the branch-swap rule (21): the literal-1 `jle`/`jg` immediate also
'     matters (`spacing<=1`/`spacing>1`, not `spacing<2`/`spacing>=2` -- same truth table,
'     different immediate operand, guide 10.1's "relational spelling" note).
'
' RULED OUT / RESIDUAL -- as of THIS pass, 9 gaps remain (-12 bytes total, COMPLETE) and
' 3 same-length subs, all in TWO small clusters, both look like REGISTER ALLOCATION
' (codegen-patterns.md 17/18/22), not remaining logic bugs -- no Local was found still
' standing in for a compound condition, and no branch was found with the wrong polarity:
'   * `poolsize+extraflag` / `rounds` product (the `g`-loop's `half`/`grpsize`/the
'     `(grpsize-1)*rounds` factor of the `i`-loop's upper bound, ORIGINAL offsets
'     ~617-716): original keeps `grpsize` in `ecx` and the constant divisor `2` in
'     `esi`, and pre-computes `(grpsize-1)*rounds` into `esi` early (right after the
'     `grpsize` mod-2 fixup, BEFORE the `SelectFixtureTable`/`Rand` calls), caching it
'     across those two calls for reuse at the `For i` bound. Ours swaps which of
'     `ecx`/`esi` holds which value, and computes the `(grpsize-1)*rounds` factor
'     LATE, inline at the `For i` bound itself, instead of hoisting it early. The
'     SOURCE TEXT for this stretch (`grpsize`/`half`/the `For i` bound expression) was
'     re-checked against the decompile and against sibling `For`-loop bound patterns
'     elsewhere in this project and looks right as written; this reads as the
'     allocator choosing a different live-range/hoist point for one sub-product, not a
'     missing statement. Left alone rather than guessing at an artificial intermediate
'     Local with no textual evidence for one.
'   * The `special`-branch's `groups > 4` complex-calc tail (ORIGINAL offset ~875,
'     `push edx` vs ours `push ecx`, one instruction, 0 net bytes at that exact
'     instruction but shifted by a stray 2-byte `mov ecx,ebx` a few instructions
'     earlier): which callee-saved register holds the cached copy of `d` across the two
'     `AddDays`-shaped calls in that branch differs (edx there vs ecx here). Byte-
'     neutral per 18.1 (`ebx`/`ecx`/`edx`/`esi`/`edi` moves are all the same length) EXCEPT
'     for the extra `mov ecx,ebx` itself, which is exactly the kind of early-vs-late
'     cache point the allocator decides on its own (same family as the point above).
'   * The `d.GetDay() <> primarymatchday And ndays < 7 Then shortfall -= 1` check AFTER
'     the shortfall-decrement `While` (ORIGINAL offset ~1142-1173) compiles with the
'     FIRST operand materialized as its OWN NEGATION (`sete`, i.e. `GetDay()=primary`,
'     `jne`-skip-with-the-stale-true-flag-reused-as-the-join-value) rather than the
'     direct-polarity `setne`/`je`-skip shape used at this body's OTHER `And`-guards
'     (the top-of-function guard, `wk`, `special`, `dok`). Logic was re-verified
'     bit-for-bit against this alternate shape and the source as written
'     (`d.GetDay() <> primarymatchday And ndays < 7`) is semantically correct either
'     way; only the polarity of the INTERMEDIATE materialization differs, and no
'     rewording tried so far (including the `matchesneeded > navailweeks` /
'     `groups > 4` operand-order trick that fixed two other spots in this pass) flips
'     it. Likely a genuine allocator/canonicalization quirk specific to this one
'     `And`-guard's context, not a wording bug -- flagged for the next pass rather than
'     guessed at further.
'   * `SUB 1/3`+`SUB 2/3` (ORIGINAL +617/+627, `ecx`/`esi` swap) are the SAME cluster as
'     the `half`/`grpsize` gap above, not independent findings.
'
' Field offsets used (object_model.json, TCompetition): +0x08 id, +0x0C name, +0x18 locale
' (unused here), +0x1C level, +0x24 comptype, +0x28 startyear, +0x2C startweek, +0x30
' duration, +0x38 primarymatchday, +0x3C secondarymatchday, +0x40 groups, +0x44 rounds,
' +0x60 lfixturelist:TList. TMyDate: +0x08 sdate (piVar5[2] in the decompile = d.sdate).
' TMyDate.Create is slot 0x30 (Function); SetDate 0x38; AddDays 0x3C; AddWeeks 0x40;
' GetDay 0x4C; GetWeek 0x50 -- all from extracted/vtable_map.tsv, all already VERIFIED
' Type methods so their call sites mask by classtable+slot regardless of this body's own
' status. `TFixture.CreateFixture` (Function, slot 0x30, sig
' (i,i,i,i,i,i,i,i,i):TFixture) likewise already VERIFIED
' (src/recovered/TFixture.CreateFixture.bmx) -- args in field-declaration order: sdate,
' matchtype=1, round=matchnum, groupno=g+1, leg=0, hometeam, awayteam, level, id.
' `GetNoofQualifiers` and `CheckFixtureClash` and `SortFixtureList` are already-VERIFIED
' Methods on Self called bare (Self. has no codegen effect).
'
' 27-TEAM GAP (season-structure.md cross-check): CONFIRMED directly from
' SelectFixtureTable's disassembly (0x004C5280), not merely re-asserted from spec 02's
' data-side inference -- the mode-0 (round-robin) dispatch chain reads
' `cmp eax,0x1a / je ... / cmp eax,0x1c / je ...` with NO `cmp eax,0x1b` anywhere in the
' function. A 27-team pool leaves the shared table cursor (g_competition_int01,
' 0x00C58F88) pointing at whatever the previous call left it. This body's own
' `SelectFixtureTable(poolsize + extraflag, 0)` call is exactly the call site that could
' hit that gap if a competition's team pool (after the `groups`-way split and `extra`
' remainder) ever lands on 27. Nothing in CreateFixtureListLeague itself guards against it.
'
' NEXT PASS: do not re-derive points 1-7, or this pass's boolean-Local/loop-shape/
' operand-order fixes; all are confirmed against the raw bytes via `localise_diff.py`
' (`python scripts/localise_diff.py TCompetition.CreateFixtureListLeague
' src/recovered_unverified/TCompetition.CreateFixtureListLeague.bmx` -- safe to run
' repeatedly, builds an isolated per-worker probe, does not touch shared state; just
' don't run `scripts/assemble.py`). Re-run it first -- 9 gaps / 3 subs / first_diff=+617
' at this save. The three residual clusters are documented just above ("RULED OUT /
' RESIDUAL"); all three read as the allocator's own live-range/hoist-point choice, not a
' missing or misworded statement, so the next lever is 18.1-18.4/22.1-22.4's
' block_count/degree formula applied to THIS body's specific Locals (`grpsize`, `half`,
' the `d`-cache register in the `groups>4` branch), not another pass over the control
' flow -- that has now been checked twice and is believed complete.
	Method CreateFixtureListLeague:Int()
		LogLine("CreateFixtureListLeague:" + name)
		If comptype = 0 And duration = 0
			Return 0
		EndIf
		If Not lfixturelist Then lfixturelist = CreateList()
		lfixturelist.Clear()
		Local d:TMyDate = TMyDate.Create(primarymatchday, startweek, startyear)
		Local navailweeks:Int = 1
		If startweek < 48
			For Local w:Int = 1 To duration - 1
				d.AddWeeks(1)
				Select level
				Case 0
					If d.GetWeek() < 48
						navailweeks = navailweeks + 1
					EndIf
				Case 1
					If d.GetWeek() < 48 And d.GetWeek() > 6
						navailweeks = navailweeks + 1
					EndIf
				End Select
			Next
			If level = 0
				navailweeks = navailweeks - 2
			EndIf
		EndIf
		Local nqual:Int = GetNoofQualifiers()
		Local poolsize:Int = nqual
		Local extra:Int = 0
		If groups > 1
			poolsize = nqual / groups
			extra = nqual - poolsize * groups
		EndIf
		Local matchesneeded:Int = (poolsize - 1) * rounds
		If extra <> 0
			matchesneeded = poolsize * rounds
			If poolsize Mod 2 = 1
				matchesneeded = (poolsize + 1) * rounds
			EndIf
		EndIf
		Local spacing:Int = navailweeks / (matchesneeded + 1)
		Local shortfall:Int = 0
		Local shortfallstep:Int = 0
		Select level
		Case 0
			If matchesneeded > navailweeks
				shortfall = matchesneeded - navailweeks
				shortfallstep = matchesneeded / shortfall
			EndIf
		Case 1
			spacing = navailweeks / (matchesneeded / 2 + 1)
		End Select
		Local home:Int = 0
		Local away:Int = 0
		Local matchnum:Int = 0
		For Local g:Int = 0 To groups - 1
			d.SetDate(primarymatchday, startweek, startyear)
			matchnum = 0
			Local extraflag:Int = 0
			If extra <> 0
				extraflag = 1
				extra = extra - 1
			EndIf
			Local grpsize:Int = poolsize + extraflag
			If grpsize Mod 2 = 1
				grpsize = grpsize + 1
			EndIf
			Local half:Int = grpsize / 2
			SelectFixtureTable(poolsize + extraflag, 0)
			Local seed:Int = Rand(poolsize, 1)
			For Local i:Int = 0 To half * (grpsize - 1) * rounds - 1
				GetHomeAndAwayTeam(Varptr home, Varptr away, poolsize + extraflag, seed)
				If i Mod half = 0
					matchnum = matchnum + 1
					If level = 1 And duration < 9
						If secondarymatchday = 99
							d.SetDate(primarymatchday, startweek, startyear)
							If groups > 4
								d.AddDays((g / 2 + 1) + (matchnum - 1) * 4 - 1)
							Else
								d.AddDays(groups * (matchnum - 1) + g)
							EndIf
						Else
							d.AddDays(1)
							While d.GetDay() <> primarymatchday And d.GetDay() <> secondarymatchday
								d.AddDays(1)
							Wend
						EndIf
					ElseIf shortfall > 0 And matchnum Mod shortfallstep = 0
						Local ndays:Int = 1
						d.AddDays(1)
						While d.GetDay() = primarymatchday Or CheckFixtureClash(d)
							d.AddDays(1)
							ndays = ndays + 1
						Wend
						If d.GetDay() <> primarymatchday And ndays < 7
							shortfall = shortfall - 1
						EndIf
					Else
						If level = 1 And matchnum Mod 2 = 0
							While d.GetDay() <> secondarymatchday Or CheckFixtureClash(d)
								d.AddDays(1)
							Wend
						Else
							If matchnum > 1
								If spacing > 1
									d.AddWeeks(spacing)
								Else
									d.AddDays(1)
								EndIf
							EndIf
							While d.GetDay() <> primarymatchday
								d.AddDays(1)
							Wend
							While CheckFixtureClash(d) <> 0
								d.AddDays(1)
							Wend
						EndIf
					EndIf
				EndIf
				If home > 0 And away > 0
					lfixturelist.AddLast(TFixture.CreateFixture(d.sdate, 1, matchnum, g + 1, 0, home, away, level, id))
				EndIf
			Next
		Next
		SortFixtureList()
		Return 0
	End Method
