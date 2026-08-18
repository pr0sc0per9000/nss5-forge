' TCompetition.CreateFixtureListLeague -- NOT VERIFIED (worker boot_FixturesLeague)
' VA 0x0050B420   1530 bytes   vtable slot 0x68   sig ()i
' Ours: 1524 bytes (delta -6, orig 1530). localise_diff.py reports 3 length-changing
' gaps (-6 total, COMPLETE), no same-length subs, first real divergence at ORIGINAL
' +1044 (a near-vs-short `je` encoding, itself a downstream consequence of the one
' remaining gap below). The single residual cluster is documented under RESIDUAL.
'
' Every compound `And`/`Or` condition in this body (the `Select`/`Case` `wk` test, the
' `special`/shortfall/normal three-way cascade's guard, the `dok`/`ok2`/`ok3` loop exit
' tests, the final fallback's `clash` loop) is written directly on the `If`/`While` with
' NO block-scoped boolean Local standing in for it -- the original never materializes a
' compound condition into a `Local x:Int = False` intermediate before branching on it.
' `While`/`Wend` (not `Repeat`/`Forever`) is used everywhere a loop's exit condition is a
' compound test, matching the original's goto-while shape (forward `jmp` to the condition
' check, then loop back) rather than `Repeat`'s fall-into-body-first shape. `CheckFixture-
' Clash(d)` is used BARE (no `<> 0`) whenever it is the trailing operand of an `Or` feeding
' a branch; the final fallback's second `While CheckFixtureClash(d) <> 0 ... Wend` calls it
' fresh every iteration rather than caching the first call into a Local.
'
' The `poolsize`/`extra` initialisation stores `poolsize` before `extra` (plain statement
' order). `matchesneeded > navailweeks` (not `navailweeks < matchesneeded`) is the spelling
' that reproduces the original's `cmp esi,[mem]/jle` with the register operand first
' (codegen-patterns.md 10.1's "relational spelling" note; same family as the `groups > 4`
' spelling in finding 5 below). The `(g/2)+(matchnum-1)*4` formula keeps its literal (and
' otherwise pointless) `+1 ... -1` round trip -- `(g / 2 + 1) + (matchnum - 1) * 4 - 1` --
' which Ghidra's decompile silently constant-folds away but the raw bytes keep as separate
' `add eax,1`/`sub eax,1` instructions.
'
' The `g`-loop's per-group match count is written as three Locals in this exact order --
' `grouprounds:Int = (grpsize - 1) * rounds`, THEN `half:Int = grpsize / 2`, THEN
' `nmatches:Int = half * grouprounds` -- because the original computes `(grpsize-1)*rounds`
' BEFORE `grpsize/2`, not after: reading the raw bytes shows `esi` holding `(grpsize-1)*
' rounds` already at the point `half` is being computed, so that product cannot be a single
' inline sub-expression of the `For i = 0 To half*(grpsize-1)*rounds-1` bound written where
' the `For` line sits textually -- it is computed earlier and merely referenced (as
' `nmatches - 1`) once the `For` line is reached, and it survives the intervening
' `SelectFixtureTable`/`Rand` calls in `esi` (the only free callee-saved register, since
' `ebx` holds `d` and `edi` holds `Self` for the whole function) without ever needing a
' stack slot of its own -- `half`, unlike `nmatches`, DOES get a stack slot (`grpsize/2` is
' still needed later for `i Mod half`), so it is stored and then immediately reloaded by
' the very next statement, which is exactly what a spilled Local's use looks like. The
' `secondarymatchday=99` branch's `groups > 4` arm likewise names its computed offset --
' `Local ndaysoffset:Int = (g / 2 + 1) + (matchnum - 1) * 4 - 1` before `d.AddDays
' (ndaysoffset)` -- rather than passing the expression inline to `AddDays`; inlining it
' makes the compiler cache `d` into a scratch register before the offset arithmetic
' instead of right before the call, which the original does not do.
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
' RESIDUAL -- localise_diff.py's 3 remaining gaps (-6 bytes, COMPLETE, no same-length
' subs) are ONE cluster, at ORIGINAL offsets ~1044-1173, all downstream of a single
' branch-polarity question:
'   * The `d.GetDay() <> primarymatchday And ndays < 7 Then shortfall -= 1` check AFTER
'     the shortfall-decrement `While` compiles with the FIRST operand materialized as its
'     OWN NEGATION (`sete`, i.e. `GetDay()=primary`, `jne`-skip-with-the-stale-true-flag-
'     reused-as-the-join-value, and the `sub` reached BY the join's `je` rather than
'     skipped by it) rather than the direct-polarity `setne`/`je`-skips-the-action shape
'     used at this body's other `And`-guards (the top-of-function guard, `wk`, `special`,
'     the `While d.GetDay() <> primarymatchday And d.GetDay() <> secondarymatchday` loop a
'     few lines above this same `If`, which uses direct `setne` for an otherwise identical
'     field comparison). Every other `And`/`Or` guard in this body -- solo relational or
'     compound, `If` or `While`, comparing a call result to a field or to a Local -- uses
'     the direct-polarity shape; this is the one exception found so far. Confirmed
'     semantically correct either way (De Morgan's-equivalent); only the polarity of the
'     INTERMEDIATE materialization and which side of the final branch is the jump target
'     differs. Operand-order swaps (`ndays < 7 And ...`, `primarymatchday <> d.GetDay()`),
'     the `<=6`/`<7` relational-spelling variants, and splitting the `And` into two nested
'     `If`s were all tried against the raw bytes and none reproduces it -- the nested-`If`
'     rewrite in particular made the whole function's register allocation reshuffle
'     (+125 bytes across 46 gaps starting at ORIGINAL +3), a reminder that this allocator
'     operates on the whole function's interference graph and a change anywhere in the
'     body can ripple far from its own line. The near-vs-short `je` encoding difference at
'     ORIGINAL +1044 (a `0F 84`/6-byte original vs a `74`/2-byte here) is a length
'     consequence of this cluster, not an independent finding: fixing the polarity above
'     should restore the 4 bytes and the near encoding together.
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
' NEXT PASS: do not re-derive the structural findings above, or re-try the operand-order/
' relational-spelling/nested-`If` rewordings already ruled out for the RESIDUAL cluster;
' all are confirmed against the raw bytes via `localise_diff.py` (`python
' scripts/localise_diff.py TCompetition.CreateFixtureListLeague
' src/recovered_unverified/TCompetition.CreateFixtureListLeague.bmx` -- safe to run
' repeatedly, builds an isolated per-worker probe, does not touch shared state; just don't
' run `scripts/assemble.py`). Re-run it first -- 3 gaps / 0 subs / first_diff=+1044 at this
' save. The next lever for the RESIDUAL cluster is reading `cgallocregs.cpp`'s actual
' spill-cost/scheduling logic (codegen-patterns.md 18.1-18.4) for why a compound `And`'s
' first operand would materialize as its own negation in exactly this one context and no
' other in this body, rather than guessing at more source spellings -- the one attempt
' that changed the shape (splitting into nested `If`s) reshuffled unrelated code 800+
' bytes earlier in the function, so treat this cluster as high blast-radius and verify
' with `localise_diff.py` after every single-line change, not after a batch of them.
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
			Local grouprounds:Int = (grpsize - 1) * rounds
			Local half:Int = grpsize / 2
			Local nmatches:Int = half * grouprounds
			SelectFixtureTable(poolsize + extraflag, 0)
			Local seed:Int = Rand(poolsize, 1)
			For Local i:Int = 0 To nmatches - 1
				GetHomeAndAwayTeam(Varptr home, Varptr away, poolsize + extraflag, seed)
				If i Mod half = 0
					matchnum = matchnum + 1
					If level = 1 And duration < 9
						If secondarymatchday = 99
							d.SetDate(primarymatchday, startweek, startyear)
							If groups > 4
								Local ndaysoffset:Int = (g / 2 + 1) + (matchnum - 1) * 4 - 1
								d.AddDays(ndaysoffset)
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
