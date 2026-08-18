' TScreen_Leagues.ComboClub
' VA 0x00545746   orig length 697 bytes (Ghidra-authoritative)
' KIND=Function ()i, slot 0x48.
'
' STATUS: MATCH (697/697, see "RESOLVED (this pass)" below for the fix that closed it
' -- earlier drafts got close but not to MATCH, our_len 643 vs orig 697, matched=264/697). History
' of the earlier misses kept below for anyone reconstructing a sibling body with the same
' shape (Select-on-array-element with GetText'd Case values, a missing TTable.AddItem call,
' a classtable+slot tail call).
'
' RESOLVED (high confidence, reusable):
'   - LogLine("ComboClub") is the entry trace call.
'   - combo = g_Object467:TCombo (0x00c66f3c) .GetSelectedItemId()  [TCombo slot 0xc0]
'   - club:TClub = TClub.SelectById(comboId)   [TClub slot 0x60, via classtable+slot at
'     0x00c59e0c -> TClub off 0x60]
'   - branch-swap rule (codegen-patterns.md #21) applies: source must read
'     `If club <> Null Then <bigblock> Else ComboLeague()` to reproduce bcc's `je` (0F 84)
'     -- writing `If club = Null Then ComboLeague() Else <bigblock>` compiles to a SHORT
'     `jne` instead and is wrong shape. Confirmed: this swap alone fixed the first
'     divergence (byte offset moved from 57 to 264-matched, with the `je` opcode now
'     correct; remaining diff at the jump TARGET is normal relocation noise from the
'     downstream length delta).
'   - TScreen_Leagues.ComboLeague() is classtable+slot at 0x00c67198 -> TScreen_Leagues
'     slot 0x44 = ComboLeague.
'   - g_Object468/469/470/471/472 : TButton (0x00c66f48/4c/50/54/58) .Hide()  [slot 0x54]
'   - g_Object462 : TPanel (0x00c66f1c)
'     .SetText(club.labelshortname + " " + GetText("Fixtures"), "", -1, -1)
'     [TGadget slot 0x64 SetText($,$,i,i)i, inherited by TPanel]
'     club.labelshortname is TBase_Team field at offset 0x20 (object_model.json).
'     GetText is the recovered module Function (src/recovered_module/GetText.bmx).
'   - g_screen_leagues_tplayer02 : TTable (0x00c66f24) .Hide()   [slot 0x54]
'   - g_screen_leagues_tplayer03 : TTable (0x00c66f28) .Show()   [slot 0x58]
'     .ClearItems()                                              [slot 0x9c]
'   - The loop is `For Local slate:String[] = EachIn club.GetStringArrayFixtureList(-1)`.
'     GetStringArrayFixtureList is TBase_Team (super of TClub) slot 0x34, inherited,
'     signature (i):TList. Confirmed by decompiling 0x004bd132: it builds a TList of
'     TFixture.GetStringArrayForTeamId(teamId) results -- TFixture slot 0x4c, sig (i)[]$
'     -- i.e. the list holds STRING ARRAYS, not custom objects. That is why the downcast
'     target class in ComboClub's own disassembly (0x00c59058) is NOT a game Type's
'     classtable -- it is the synthetic array-type descriptor for String[], which lives in
'     an unnamed block of tiny synthetic classtables starting at 0x00c58ff4
'     (z_1a09b2da_..., instance_size 8) running up to the next real entry at 0x00c59250.
'     `puVar4[0xb]` in the decompile is NOT field 11 -- BBArray data starts at +0x18, so
'     element index 5 (since (0x2c-0x18)/4 = 5) -- i.e. `slate[5]`.
'   - `slate[5] = "sla_Won"` / "sla_Lost" / "sla_Drawn" compile to `_bbStringCompare`
'     (confirmed helper 0x004a6a30) == 0, matching the decompile's `FUN_004a6a30(...) == 0`
'     branches exactly.
'   - Row colouring: `g_screen_leagues_tplayer03.SetRowColour(g_screen_leagues_tplayer03
'     .CountItems(), "99FF99"/"FF9999"/"9999FF")` for Won/Lost/Drawn respectively --
'     TTable slot 0xec = CountItems, slot 0xac = SetRowColour(i,$)i. NOTE: ClearItems() is
'     called immediately before this loop, so CountItems() is 0 for the whole loop unless
'     the original really does call SetRowColour(0, ...) repeatedly -- reproduce as found,
'     do not "fix". (ORIGINAL BUG candidate, or table population happens in a sibling
'     function such as SetUpFixturesTable and survives ClearItems in a way not yet
'     understood -- UNCERTAIN.)
'
' NOT YET RESOLVED -- where the remaining -54 bytes live:
'   localise_diff (see workdir dumps this pass) shows TWO gaps, both inside the
'   Won/Lost/Drawn/else chain starting around orig +388 (VA 0x005458CA):
'     1. a -62 byte DELETE gap: our compiled Lost/Drawn checks do not match the original's
'        three sequential `je`-chained string comparisons. Our probe's disassembly for this
'        region shows a call to 0x004f4290 (NOT 0x004a6a30/_bbStringCompare) reading
'        [esi+0x2c] directly instead of doing a string compare -- meaning the ElseIf chain
'        as written did NOT compile the way expected. Suspect: `slate` may have gone out of
'        scope / been re-typed, OR bcc handles a 4-armed If/ElseIf-with-trailing-plain-If
'        differently than the original's actual shape (which may be nested If/Else, not
'        parallel ElseIf) for the last arm (`ElseIf firstidx = -1 Then firstidx = idx`).
'        NEXT STEP: rewrite the last arm as a NESTED `Else If firstidx = -1 Then ... EndIf`
'        inside the Drawn check's Else, rather than a 4th ElseIf, and re-run localise_diff.
'     2. a -34 byte REPLACE gap immediately after (orig +546..589): our probe skips straight
'        from the Drawn-branch's SetRowColour to the `cmp [ebp-4],-1` firstidx check,
'        meaning our compiled body only has ONE colour-check arm's worth of code where the
'        original repeats the CountItems/SetRowColour/jmp pattern for a THIRD time (Drawn).
'        This is consistent with gap 1: the ElseIf chain is collapsing/restructuring wrong.
'   Once gaps 1-2 close, re-run localise_diff to confirm no further gaps before writing the
'   final source and moving it to src/recovered/ (only after a clean MATCH from
'   harness.try_method).
'
' Header comment above is honest about the not-yet-closed gap. THIS FILE MUST NOT BE
' MOVED TO src/recovered/ until harness.try_method returns MATCH.
'
' TRIED AND RULED OUT: rewriting the last arm as a nested
' `Else / If firstidx = -1 Then ... EndIf / EndIf` (per the "NEXT STEP" note above) instead
' of a 4th ElseIf. Result: BYTE-IDENTICAL to the flat ElseIf chain (still 643/697,
' matched=264, same gaps). BlitzMax's ElseIf desugars to nested If/Else identically at the
' codegen level -- this is NOT the lever. Reverted to the flat ElseIf form below for
' readability since it compiles the same.
' Also localised (localise_diff, max_gaps=20): the -54 delta is 8 gaps (not the 2 first
' logged), all still inside the Won/Lost/Drawn/else chain (orig +331..+669). The gap detail
' shows OUR compiled code calling a DIFFERENT runtime helper (0x004f4290 in the probe) where
' the original calls what should be the string-compare/field-access helper -- but this
' appeared consistently in a SECOND unrelated near-miss this same session
' (TScreen_Kits.SetUpScreen, same -helper-address-mismatch inside its own 5-way string
' equality chain against a Local). Given it recurs across two independent String-equality-
' chain reconstructions, suspect it is a SYMPTOM of the surrounding register-allocation
' drift (once one gap desyncs the instruction stream, every downstream call operand reads as
' "wrong" even when the logic is right) rather than two independent wrong-predicate bugs.
' NEXT PASS: before touching predicates again, try shrinking block_count / adjusting
' reference counts on `slate`/`firstidx`/`idx` per codegen-patterns.md section 18/22 (the
' documented, not-yet-tried lever for this exact class of problem) rather than re-guessing
' the If-chain shape a third time.
'
' RESOLVED (this pass, w45): three real bugs, found with scripts/localise_diff.py against
' this file directly (all 8 gaps + the trailing SUB are accounted for now):
'   1. MISSING STATEMENT. The decompile's `if (puVar4 != &DAT_005c9c80) { (**...+0x94))
'      (PTR_DAT_00c66f28,puVar4,&PTR_PTR_005c7d40,&PTR_PTR_005c7d40); uVar2 = puVar4[0xb];
'      ...` shows a call to TTable slot 0x94 -- `AddItem([]$,$,$)i`
'      (src/recovered/TTable.AddItem.bmx, VA 0x005163B7) -- made with (slate, "", "")
'      BEFORE the colour chain, that our body never made at all. 0x5c7d40 is the plain
'      empty-string singleton (same address used to zero-init String fields all over the
'      game's New() constructors), hence AddItem(slate, "", "").
'   2. WRONG CODEGEN SHAPE FOR THE COLOUR CHAIN. `0x004f4290` (the "different runtime
'      helper" noted above) is what a *raw literal* `slate[5] = "sla_Won"` compiles to --
'      that is not what the original does. FUN_004c5549 is GetText (VA 0x004c5549, see
'      src/recovered_module/GetText.bmx) -- the decompile's
'      `uVar5 = FUN_004c5549(&PTR_PTR_00c70fd0); iVar6 = FUN_004a6a30(uVar2,uVar5);` is
'      `slate[5] = GetText("sla_Won")`, i.e. the fixture-result code is compared against
'      the *localised* text, not a bare literal. Also, `esi` (slate[5]) is loaded into a
'      register exactly ONCE and reused for all three compares -- that is Select's own
'      subject-caching, not a hoisted Local: confirmed against
'      src/recovered/THorse.GetValue.bmx ("the per-form add is a Select, not an If/ElseIf
'      chain (an ElseIf chain reloads the element into a fresh register and comes out
'      short)"), which Selects directly on an array element (`Select form[i]`) the same
'      way. So the chain is `Select slate[5] / Case GetText("sla_Won") / Case
'      GetText("sla_Lost") / Case GetText("sla_Drawn") / Default (firstidx check) / End
'      Select` -- not If/ElseIf.
'   3. WRONG TAIL CALL. The last SUB the localiser reported (orig +669, `call [0xc671a0]`)
'      is `PTR_FUN_00c671a0`, not `ButtonLevel()`. Using the already-confirmed
'      `PTR_FUN_00c67198 = TScreen_Leagues classtable + slot 0x44 = ComboLeague` to derive
'      the classtable base (0xc67198 - 0x44 = 0xc67154): 0xc671c0 - 0xc67154 = slot 0x6c =
'      RefreshComboColours (already correct, matched), but 0xc671a0 - 0xc67154 = slot 0x4c
'      = SetUpLeagueTable (extracted/decomp/TScreen_Leagues.SetUpLeagueTable@005459ff.c),
'      NOT slot 0x68 (ButtonLevel). Fixed the final call.
' CONFIRMED: re-run through scripts.harness.try_method('TScreen_Leagues','ComboClub', <this
' file>) after the fix above -> status='MATCH', matched=total=697/697 (orig_len=our_len=697,
' reloc_masked=49). localise_diff also reports CLEAN, delta +0. This file is byte-perfect
' and ready to move to src/recovered/ -- left in place here since the mandate was
' to edit only this file, not to perform the promotion/move step.

	'!Global g_Object467:TCombo
	'!Global g_Object468:TButton
	'!Global g_Object469:TButton
	'!Global g_Object470:TButton
	'!Global g_Object471:TButton
	'!Global g_Object472:TButton
	'!Global g_Object462:TPanel
	'!Global g_screen_leagues_tplayer02:TTable
	'!Global g_screen_leagues_tplayer03:TTable
	LogLine("ComboClub")
	Local club:TClub = TClub.SelectById(g_Object467.GetSelectedItemId())
	If club <> Null
		g_Object468.Hide()
		g_Object469.Hide()
		g_Object470.Hide()
		g_Object471.Hide()
		g_Object472.Hide()
		g_Object462.SetText(club.labelshortname + " " + GetText("Fixtures"), "", -1, -1)
		g_screen_leagues_tplayer02.Hide()
		g_screen_leagues_tplayer03.Show()
		g_screen_leagues_tplayer03.ClearItems()
		Local firstidx:Int = -1
		Local idx:Int = 0
		For Local slate:String[] = EachIn club.GetStringArrayFixtureList(-1)
			g_screen_leagues_tplayer03.AddItem(slate, "", "")
			Select slate[5]
				Case GetText("sla_Won")
					g_screen_leagues_tplayer03.SetRowColour(g_screen_leagues_tplayer03.CountItems(), "99FF99")
				Case GetText("sla_Lost")
					g_screen_leagues_tplayer03.SetRowColour(g_screen_leagues_tplayer03.CountItems(), "FF9999")
				Case GetText("sla_Drawn")
					g_screen_leagues_tplayer03.SetRowColour(g_screen_leagues_tplayer03.CountItems(), "9999FF")
				Default
					If firstidx = -1 Then firstidx = idx
			End Select
			idx :+ 1
		Next
		g_screen_leagues_tplayer03.SelectItemByRow(0)
		If firstidx > -1
			g_screen_leagues_tplayer03.ShowItem(firstidx + 10)
		EndIf
		RefreshComboColours()
		SetUpLeagueTable()
	Else
		ComboLeague()
	EndIf
