' TTeam.CheckComManagement -- VERIFIED MATCH (confirmed by scripts/harness.py.try_method,
'   run standalone with NSS5_NO_LEARN=1: status=="MATCH", mode=="reloc"). Still filed under
'   src/recovered_unverified because that is what THIS refine pass was scoped to touch; the
'   whole-program status/score/TTeam.CheckComManagement.txt report (raw, unmasked bytematch
'   against the fully assembled game) may still show a low percentage until assemble.py is
'   rerun and/or until unrelated not-yet-fixed functions elsewhere stop shifting the overall
'   link layout -- that is whole-program noise, not a defect in this body. Re-verify in
'   isolation with scripts/localise_diff.py before trusting any raw whole-program number.
' VA 0x004E1B6C   838 bytes (Ghidra-authoritative)   vtable slot 0x94   sig ()i   KIND=Method
' byte-identical vs NSS5.exe
' (original candidate, 811/838, 14 unstructured gaps)
' (837/838 in isolation, 3 length-changing gaps left, all precisely
'   localised -- see the fix log below for what worked and what was rejected).
' (this pass): closed all 3 remaining gaps. scripts/localise_diff.py
'   now reports "CLEAN -- byte-identical modulo the oracle's masks" (delta 0, naming: full,
'   no gaps, no subs), and scripts/harness.py try_method independently confirms MATCH. See
'   "LATEST FIXES" below the earlier fix log for exactly what changed and why.
'
' WHAT AN EARLIER PASS FIXED (all confirmed by re-running the oracle after each isolated change --
' see the fix log at the bottom for what was tried and REJECTED, so nobody re-tries it):
'   1. `subbedontime`/`subbedofftime >= 0` -> `> -1`. Same truth table, different bytes
'      (cmp reg,-1/setg vs cmp reg,0/setge) -- codegen-patterns.md #10.1, match the literal.
'   2. The `If Not ok1 And g_engine_int20 > 54 And subbedontime < 0 Then <body> EndIf` WRAPPED
'      compound-If is WRONG SHAPE. The original compiles this as THREE SEQUENTIAL EARLY
'      RETURNS followed by an UNWRAPPED body (no EndIf to jump over) -- each guard has its own
'      `mov eax,0 / jmp <final tail>`, not a shared skip-the-whole-block jump. Rewritten as:
'        If ok1 Then Return 0
'        If g_engine_int20 < 55 Then Return 0      ' literal is 55 (0x37) with jge, NOT 54 with jg
'        If target.matchstats.subbedontime > -1 Then Return 0
'        <body, unconditional, falls into the final trailing Return 0 at EOF>
'      This alone took the candidate from 811 to 845 (+34) before the literal/operand fixes
'      below trimmed it back down.
'   3. Every `TEngine.DoYourSubstitutionOff(0)` call (4 sites: heavy, energy, rating, sub2)
'      needs an explicit trailing `Return 0`. Without it bcc merges the tail with whatever
'      follows and the branch is 5 bytes short each time (codegen-patterns.md #21 secondary
'      effect). Confirmed independently at all 4 sites.
'   4. `0 < g_engine_int22 And g_engine_int22 <= g_engine_int20` is a byte-identical-LENGTH but
'      WRONG-OPCODE match (setl/sete instead of setg/setge) -- rewritten operand-order-first as
'      `g_engine_int22 > 0 And g_engine_int20 >= g_engine_int22` (codegen-patterns.md #10.1).
'      Length-neutral, but removes 2 SUBs.
'   5. The `target = Null` (now `Else`) branch's `If side = -1 ... ElseIf side = 1 ... EndIf`
'      is WRONG SHAPE. The original does BOTH compares back-to-back before either body (Select
'      shape, codegen-patterns.md #10.2: `cmp eax,-1;je L1; cmp eax,1;je L2; jmp NoMatch`),
'      not a nested/cascading If/ElseIf. Rewritten as `Select side / Case -1 ... / Case 1 ... /
'      End Select` (no Default). This alone was -15 bytes (845 area -> 830, before other fixes
'      landed net -1 overall) and eliminated GAP1(-10)/GAP3(+5) entirely.
'   6. The EachIn-loop target-selection condition needed the OUTER `Not(reds Or selectionno>10)`
'      test to be its own If, with `newstar <> 0` in a SEPARATE NESTED If -- NOT one compound
'      `Not(A Or B) And C`. (`Not(A Or B) And C` all-in-one was tried and made the divergence
'      START EARLIER, at +92 instead of +134 -- do not retry that form.) Rewritten as:
'        If Not(p.matchstats.reds Or p.selectionno > 10)
'            If p.newstar <> 0
'                target = p
'            EndIf
'        EndIf
'   7. `Local losingby:Int = Self.GetLosingBy() > 0` (materialise the boolean into the Local,
'      not the raw Int) then `If losingby`. Tried `Local losingby:Int = Self.GetLosingBy()`
'      then `If losingby > 0` (worse, 821) and inlining the call with no Local at all into
'      `If Self.GetLosingBy() > 0` (worse, 830) -- both REJECTED, current form (837) is best
'      found. This is the site of the ONE remaining unresolved gap (#1 below).
'
' LATEST FIXES (all 3 remaining gaps; each verified in isolation with
' `python scripts/localise_diff.py TTeam.CheckComManagement src/recovered_unverified/TTeam.CheckComManagement.bmx`
' after every change -- that tool builds a private probe via harness.try_method(NO_LEARN=1),
' so it is safe to run without touching shared state; it is NOT scripts/assemble.py):
'
'   GAP 3 fix (was -2 bytes, ORIGINAL +134, EachIn loop): the earlier nested-If guess
'     (`If Not(reds Or selectionno>10) / If newstar<>0 / target=p / EndIf / EndIf`) was the
'     wrong SHAPE, not just missing a jump. The byte-identical sibling
'     `src/recovered/TTeam.GetShootoutPositions.bmx` uses the EXACT SAME guard condition
'     (`p.matchstats.reds Or p.selectionno > 10`) as a `Continue`:
'       If p.matchstats.reds Or p.selectionno > 10 Then Continue
'       If p.newstar <> 0
'           target = p
'       EndIf
'     `Continue`'s explicit jump to the enumerator-advance code is exactly what produces the
'     original's `je (fallthrough) / jmp (skip to enumerator advance)` pair -- the sibling's own
'     header documents this trade (`74 02 EB 0C`, 2 bytes shorter to invert-and-fold, but the
'     original does NOT). This alone closed GAP 3 (confirmed: first divergence moved from +134
'     to +271, i.e. everything up to GAP 2 now matches exactly).
'
'   GAP 2 fix (was -6 bytes, ORIGINAL +271, the `heavy`/yellows test): collapsed the
'     `Local heavy:Int = False` + `If yellows=1 Then heavy = CountStat(11)>4` two-statement form
'     into ONE expression:
'       Local heavy:Int = (target.matchstats.yellows = 1) And (target.matchstats.CountStat(11) > 4)
'     This was flagged as "unconfirmed whether bcc short-circuits And in an assignment
'     context" -- CONFIRMED, it does, and it reproduces the original's full `sete/movzx`
'     materialisation of the first comparison before the `cmp eax,0/je` guard around the
'     `CountStat` call. Closed GAP 2 exactly (verified: that region is now byte-for-byte
'     identical, remaining divergence moved to GAP 1 only).
'
'   GAP 1 fix (was +7 bytes, ORIGINAL +520, the `losingby`/sub2 branch): same technique as
'     GAP 2, applied to the sibling pattern one `Else` arm down:
'       Local sub2:Int = (Self.GetLosingBy() > 0) And (target.matchstats.rating < thresh + 10)
'     (replacing the separate `Local losingby:Int = ... > 0` / `Local sub2:Int = False` /
'     `If losingby Then sub2 = ...` three-statement form). This removed the `mov edx,eax /
'     mov eax,0` register shuffle seen earlier -- that shuffle was bcc keeping `losingby` alive
'     across the separate `sub2 = False` initialiser; folding both into one short-circuited
'     expression means there is only ever one Local's worth of live state. Closed the last gap:
'     `scripts/localise_diff.py` now reports delta 0, "CLEAN -- byte-identical modulo the
'     oracle's masks", and `scripts/harness.py try_method` (run with NSS5_NO_LEARN=1)
'     independently reports status "MATCH", mode "reloc".
'
' TAKEAWAY for future bodies: a `Local x:Int = False` immediately followed by an `If <cond>
' Then x = <expr>` that only ever assigns that SAME Local is very often really a single
' short-circuited `Local x:Int = <cond2> And <expr-that-only-runs-if-cond2>` in the original
' source -- try that collapse before accepting a register-shuffle mismatch as unfixable.
'
' Per codegen-patterns.md #13.3, this is NOT a "stub to make a caller mask" situation -- every
' callee here (TEngine.DoYourSubstitutionOn/Off, TEngine.ForcePositionResetAll,
' TScreenMessage.ClearAll/Create, TPlayer.GetHumanPlayer, LogLine, GetText) is independently
' named via vtable_map.tsv/class-table slots or already-recovered module Functions, so masking
' is real, not self-fulfilling -- the oracle's `naming: full` line confirms every E8 operand
' DOES mask by name.
'
' WHAT IS TRUSTWORTHY (re-derived from object_model.json / vtable_map.tsv / globals_final.tsv,
' cross-checked against the C runtime source where noted):
'   Self.squad : TList              (TTeam field, offset 28)
'   TPlayer.newstar : Int  (offset 8)   -- decompiled puVar3[2]
'   TPlayer.matchstats : TStats_Match (offset 392) -- decompiled puVar3[0x62]/puVar8[0x62]
'   TStats_Match.reds (offset 16), .yellows (offset 12), .subbedontime (offset 28),
'     .subbedofftime (offset 32), .rating (offset 40), .CountStat(i)i @ slot 0x3C
'   TPlayer.selectionno : Int (offset 188)
'   TPlayer.GetShootingDirection()i @ slot 0x160 -- NAME IS SUSPECT for this call site (used to
'     pick which flank's sub-message to show); the reflection name may simply not describe this
'     particular use. Re-confirm before trusting semantics; the SLOT is correct (vtable_map.tsv).
'   TPlayer.GetHumanPlayer():TPlayer @ TPlayer classtable+0x164 (static)
'   TEngine.DoYourSubstitutionOn()i @ +0xd0, DoYourSubstitutionOff(i)i @ +0xd4,
'     ForcePositionResetAll()i @ +0xe8  (all static, class-table calls)
'   TScreenMessage.ClearAll(i)i @ +0x40, Create(i,i,$,i,:TBitmapFont,:TImage,f,$)i @ +0x30
'   TTeam.GetLosingBy()i @ slot 0x98 (virtual, Self)
'   g_training_int03:Int (0x00C6CF90), g_engine_int22:Int (0x00C5B228),
'     g_engine_int20:Int (0x00C5B210), g_engine_int17:Int (0x00C5B1F8),
'     g_Object15:TBitmapFont (0x00C5B1C4, construction-typed),
'     g_Object29 (0x00C5B2F4), g_Object30 (0x00C5B2F8) -- both used as Create's :TImage arg6,
'       globals_final.tsv types them plain Object (usage) -- TImage is inferred from the call
'       site's declared param type, not independently confirmed.
'     g_contractoffer_tplayer:TProfile (0x00C6F028, hand-verified in globals_final.tsv despite
'       the misleading name) -- .energy:Float @ offset 348 (0x15c), .relationboss:Int @ offset
'       260 (0x104).
'   Float constant at 0x00C75D6C = 6.0 (read directly out of the exe, harness read_va).
'   TScreenMessage.Create's call: GetText takes exactly ONE String arg (sig ($)$, confirmed in
'     src/recovered_module/GetText.bmx) -- the decompiled arg list is Ghidra's known
'     merged-pushes artefact (guide 8/16.2). The real call is
'     TScreenMessage.Create(0, 0, Lower(GetText("Substitution")), g_engine_int17 Shl 1,
'     g_Object15, g_Object29 [or g_Object30], 1.0, "FFFFFF") -- confirmed by add-esp byte counts
'     (GetText pops 4, Create pops 0x20 = 8 args) at VA 0x004E1E1C-0x004E1E5E.

'!Global g_training_int03:Int
'!Global g_engine_int22:Int
'!Global g_engine_int20:Int
'!Global g_engine_int17:Int
'!Global g_Object15:TBitmapFont
'!Global g_Object29:TImage
'!Global g_Object30:TImage
'!Global g_contractoffer_tplayer:TProfile

LogLine("CheckComManagement")
If g_training_int03 <> 0 Then Return 0
Local target:TPlayer = Null
For Local p:TPlayer = EachIn Self.squad
	If p.matchstats.reds Or p.selectionno > 10 Then Continue
	If p.newstar <> 0
		target = p
	EndIf
Next
If target <> Null
	Local ok1:Int = target.matchstats.subbedontime > -1
	If Not ok1
		ok1 = target.matchstats.subbedofftime > -1
	EndIf
	If ok1 Then Return 0
	If g_engine_int20 < 55 Then Return 0
	If target.matchstats.subbedontime > -1 Then Return 0
	Local heavy:Int = (target.matchstats.yellows = 1) And (target.matchstats.CountStat(11) > 4)
	If heavy
		TEngine.DoYourSubstitutionOff(0)
		Return 0
	Else If g_contractoffer_tplayer.energy < 6.0
		TEngine.DoYourSubstitutionOff(0)
		Return 0
	Else
		Local thresh:Int = 45
		If g_contractoffer_tplayer.relationboss < 90 Then thresh = 50
		If g_contractoffer_tplayer.relationboss < 60 Then thresh = 55
		If g_contractoffer_tplayer.relationboss < 30 Then thresh = 60
		If target.matchstats.rating < thresh
			TEngine.DoYourSubstitutionOff(0)
			Return 0
		Else
			Local sub2:Int = (Self.GetLosingBy() > 0) And (target.matchstats.rating < thresh + 10)
			If sub2
				TEngine.DoYourSubstitutionOff(0)
				Return 0
			EndIf
		EndIf
	EndIf
Else
	If g_engine_int22 > 0 And g_engine_int20 >= g_engine_int22
		TEngine.DoYourSubstitutionOn()
		TEngine.ForcePositionResetAll()
		TScreenMessage.ClearAll(0)
		Local h:TPlayer = TPlayer.GetHumanPlayer()
		If h <> Null
			Local side:Int = h.GetShootingDirection()
			Select side
				Case -1
					TScreenMessage.Create(0, 0, Lower(GetText("Substitution")), g_engine_int17 Shl 1, g_Object15, g_Object29, 1.0, "FFFFFF")
				Case 1
					TScreenMessage.Create(0, 0, Lower(GetText("Substitution")), g_engine_int17 Shl 1, g_Object15, g_Object30, 1.0, "FFFFFF")
			End Select
		EndIf
	EndIf
EndIf
Return 0
