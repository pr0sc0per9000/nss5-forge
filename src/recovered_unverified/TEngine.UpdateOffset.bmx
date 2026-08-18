' UNVERIFIED -- TEngine.UpdateOffset
' VA 0x004CFB35   2004 bytes (Ghidra-authoritative)   slot 0x58   sig (f)i   KIND=Function (no Self)
' NOTE: this is a static Function on TEngine (declared with the Function keyword inside the
' Type body) -- per codegen-patterns.md 11.5 it is verified with harness.try_method, NOT
' try_function. This file is WRAPPED format; feed it through localise_diff._body_of() /
' reverify.body_of() before handing it to try_method/localise_body, or you get the
' "our_len 14" empty-stub trap (STATUS.md, codegen-patterns.md intro) because the pasted
' `Function ... End Function` wrapper nests inside the probe's own auto-generated wrapper.
'
' CURRENT STATE: our_len 1996 vs orig 2004, delta -8 (best confirmed state). 18
' length-changing gaps (scripts/localise_diff.py), delta fully accounted for (COMPLETE).
' NOT a MATCH; do not promote to src/recovered/.
'
' FIX #5 (four-statement split), FIX #6 (declaration-order swap) and FIXES #7-#10
' (addend ordering) are independently correct and complementary: they touch different,
' non-overlapping instruction ranges, and together they produce the -8 result above.
'
' FIX #7: `(basef - g_engine_float01) * ratezoom + g_engine_float01` (BOTH the
' g_options_int06=2 and Else branches) -- this is the SAME lever as FIX #3 (zoom-first for the
' dx/dy multiplies), one level up: the original loads the Global FIRST (`fld [zoom]`), evaluates
' the subtract+multiply via a FRESH memory re-read of that same Global (not the stacked copy), and
' combines with the EARLIER-pushed copy via a compact register-form `faddp st(1)` (2 bytes) instead
' of `fadd dword ptr [addr]` (6 bytes). Only happens when the Global is the LEFT (textually first)
' operand of the outer `+`:
'     g_engine_float01 = g_engine_float01 + (basef - g_engine_float01) * g_campan_ratezoom2
'     g_engine_float01 = g_engine_float01 + (basef - g_engine_float01) * g_campan_ratezoomdefault
' (was value-first: `(basef - g_engine_float01) * g_campan_ratezoom2 + g_engine_float01`). This is
' the fix for the "fxch-based" gap the OPEN GAPS section flagged as "STILL UNEXAMINED" and
' explicitly warned a hoisted alias Local made WORSE -- this is NOT a hoisted alias, it is a pure
' operand-order swap of the existing Globals/Locals, no new Local. Confirmed +4 bytes in isolation
' against the -15 baseline (delta -15 -> -11); replays cleanly on top of FIX #5/#6 too.
'
' FIX #8: the SAME lever applied to the two offset-smoothing lines right after the
' camera-mode dispatch:
'     g_engine_float02 = g_engine_float02 + (campointx - g_engine_float02) * a0
'     g_engine_float03 = g_engine_float03 + (campointy - g_engine_float03) * a0
' (was value-first). Confirmed +4 bytes in isolation (delta -11 -> -7); replays cleanly.
'
' FIX #9: FIX #5's four-statement split for the human-follow campointx/campointy
' zoom multiply used Global-first for the final multiply (`campointx = g_engine_float01 *
' campointx`). That is BYTE-LENGTH-NEUTRAL (a Global operand costs 6 bytes as either the `fld` or
' the `fmul`'s memory operand, a Local costs 3 bytes either way, so 3+6+3=12 total regardless of
' which one is the `fld`) but NOT byte-IDENTICAL: the original's actual opcode is `fld [local]`
' (`D9 45 xx`, 3B) ; `fmul [Global]` (`D8 0D xxxxxxxx`, 6B) ; `fstp [local]` (`D9 5D xx`, 3B) --
' i.e. the LOCAL is loaded first and the Global is the fmul's memory operand, not the reverse.
' Confirmed by diffing a KEPT probe's disasm against the original at the exact VA: swapping to
' target-first --
'     campointx = campointx * g_engine_float01
'     campointy = campointy * g_engine_float01
' -- reproduces the original's exact opcode bytes at this site (mode/rm byte `45`, not `05`),
' closing a same-length SUB that Global-first left open. No change to `our_len` in isolation (both
' orders are 12 bytes here), but this is what let FIX #7/#8's gap-closing combine cleanly instead
' of leaving a residual +1 branch-shift artefact at this site.
'
' FIX #10: re-tested `Local shootdir:Int = ball.setpiecetaker.GetShootingDirection()` vs
' inlining the call directly into the multiply, ON TOP of FIX #5/#6/#7/#8/#9 --
' the RULED OUT list says this is "zero byte effect, confirmed AGAIN independently" and that
' is correct for TOTAL LENGTH (both forms give the same `our_len`), but it is not localisation-
' neutral: inlining --
'     angle = Int(AngleTo(ball.setpiecetaker.x, ball.setpiecetaker.y, 0.0, ..
'                          Float(g_player_int19 * ball.setpiecetaker.GetShootingDirection())))
' -- raises the tool's `matched` count from 791 to 807 at the SAME -8 delta (fewer/cleaner gaps
' downstream), consistent with the original finding on the -15 baseline (gap
' count 25->23, SUB count 60->55 there). Applied; harmless, measurably cleaner.
'
' RULED OUT THIS PASS (do not re-try -- tested against the -15 baseline):
'   * `campointx = bx + (human.x - bx) * g_campan_ratex` (addend-first, mirroring FIX #7/#8) for
'     the human-follow X/Y TARGET computation itself (as opposed to the zoom-multiply that
'     consumes it, FIX #9) -- tested alone (X only, Y only) and together: every variant made the
'     body LONGER (2007, 2009), never shorter. The addend-first lever from FIX #7/#8 does NOT
'     apply to this `(A - v)*k + v` instance; something about it differs from the zoom-recompute
'     case that was not identified. Left as `(human.x - bx) * g_campan_ratex + bx` (value-first --
'     does not match the original's register-reuse of bx/by for its OWN internal add, see OPEN
'     GAPS, but not worse than trying harder without understanding why the mechanism differs).
'   * Combining `Local basef:Float = Float(g_engine_int163-100) / distf` (folding the division
'     into the declaration, last-declared-float-stays-on-stack per codegen-patterns.md 10.5) --
'     made it WORSE (1974, delta -30 from a -15 baseline). Reverted.
'   * `distf :+ d2` / `basef :/ distf` (compound-assign forms) in place of `x = x + y` / `x = x/y`
'     -- byte-identical to the `=` form. Not the lever for the GAP 3 (`-9 @1198`) residual below.
'
' STILL OPEN (delta -8; read codegen-patterns.md section 22 "spill mechanism" IN FULL before
' touching the frame-size lead, and see the NEW LEAD note above -- both are about the
' same untouched `sub esp,0x50` vs `0x4c` frame-size deficit, NOT changed by any fix this pass):
'   * `sub esp,0x4c` (orig) vs `sub esp,0x50` (ours) -- one extra spilled dword throughout. Root
'     cause still unidentified; the three prioritised hypotheses (the `p:TPlayer` EachIn
'     iterator, `winner:TTeam`, the `dx`/`dy` Double slot-reuse) are UNTRIED by this pass too.
'   * `-9 @1198` (0x004CFFE3): `distf = distf + d2` / `basef = basef / distf` -- original reloads
'     `basef` from memory (`fld [ebp-0x38]`) immediately before the divide; in ours that reload is
'     entirely absent from this position (folded elsewhere by a different allocation). Same net
'     operation count, different placement. Both ruled-out attempts above targeted this
'     gap and failed; still a genuine block_count/liveness question, not a textual one.
'   * `+12/-12 @1623/1626`: the pitch-edge `Local dx:Float`/`dy:Float` (g_player_int16/17 pair,
'     NOT the double dx/dy from FIX #2) region right after the ClampFloat call -- unexamined.
'     Possibly collapses once the frame-size root cause above is fixed.
'   * `-3/-2 @1330/1345` and a residual `+1` nearby: the human-follow X-target's OWN internal add
'     (`(human.x-bx)*ratex + bx`) still uses `fadd [ebp-4]` (3B) where the original uses
'     `faddp st(1)` (2B) -- i.e. the SAME shape FIX #7/#8 fixed for the zoom-recompute Globals does
'     NOT reproduce for this Local (`bx`); see the first RULED OUT entry above. Root cause open.
'   * `-6 @642, +6 @660`: the `g_player_int19*shootdir` site. codegen-patterns.md 16.2's push-
'     order/GP-register-survives-a-call shape is the live hypothesis (original loads
'     `g_player_int19` into a register BEFORE the `GetShootingDirection()` call and multiplies
'     after); everything tried on it (inlining alone, a hoisted `ptarget` Local)
'     has failed to reproduce the register-survives-a-call shape. FIX #10 above is orthogonal
'     (localisation cleanliness only) and does not close this gap.
'   * `-3 @760, +3 @772, -3 @816, +3 @828`: sit inside the dx/dy Cos/Sin region FIX #2 otherwise
'     verified byte-for-byte at +721..+760 -- worth re-diffing that region specifically.
'   * ~20 ebx<->esi same-length SUBs in the distance/dx/dy Cos/Sin block (VA +497..+841): register
'     IDENTITY (not slot depth) differs throughout -- do not chase these individually; they are
'     almost certainly downstream of the frame-size root cause, same as the NEW LEAD argues
'     for the `[ebp-N]` displacement SUBs.
'
' THIS PASS: re-verified the -8/1996 state still builds and scores exactly as claimed
' above (matched=814/2004 via harness.try_method, sub esp,0x50 vs 0x4c, first_diff=5) before
' touching anything. Retired two of the three "untried" frame-size hypotheses, both tested
' in isolation via scripts/localise_diff.py against a scratch copy (never applied to this file
' until proven, per the METHOD NOTE below -- neither was):
'   * `dx`/`dy` Double slot-reuse (one shared `Local dxy:Double` reassigned for both the ball.x
'     and ball.y accumulations instead of two separate Doubles) -- moves the frame from
'     `sub esp,0x50` to `sub esp,0x48`, i.e. drops a WHOLE qword (8 bytes), not the single extra
'     dword needed. Confirms the two Doubles are each genuinely live/spilled (matches the actual
'     qword fld/fstp pairs in the disasm, not just Ghidra's SSA-promoted `fVar` view of that
'     region) and are not the culprit. Reverted; not applied.
'   * The `basea`/`baseb` pitch-clamp Locals (last section, `Local basea:Float =
'     Float(g_player_int16)` immediately consumed once by `limita`) -- inlining `basea` directly
'     into the `limita` expression is BYTE-IDENTICAL (our_len unchanged at 1996, frame unchanged
'     at 0x50): a single-use Float Local costs nothing extra either way here, consistent with
'     10.5/23.2. Confirms this pair is not the culprit either. Left named (matches the decomp's
'     `iVar9`/`iVar10` split more legibly; behaviourally and byte-wise neutral either way).
' Did not get to the third hypothesis (`p:TPlayer`/`winner:TTeam` EachIn iterator) with a safe,
' behaviour-preserving rewrite to test -- `winner` is read twice (the Null guard, then `.squad`)
' and the decompiled call site (PTR_FUN_00c5bb28, single call) rules out re-calling
' TEngine.GetWinningClub() a second time to drop the Local, and this compiler is not known to CSE
' repeated calls (16.8-adjacent), so a like-for-like isolation test was not available. Left open
' for the next pass.
' No edit applied: every isolation test either overshot the target (-8 dword vs the needed -4) or
' was a no-op, and one earlier exploratory edit in this same pass (swapping the dx/dy zoom-multiply
' operand order to mirror FIX #9, `Float(dx) * g_engine_float01`) reproduced a DIFFERENT delta
' (-12, still length-mismatched) and, checked against the real oracle metric via
' harness.try_method (not just localise_diff's aligned gap view), *dropped* matched from 814 to
' 597 -- a sharp reminder that harness.try_method's raw MISMATCH `matched` count (the actual
' status/score number) is a positional count with NO relocation masking while lengths disagree
' (11.3), so it does not reward a locally-correct reordering unless the OVERALL length becomes
' exact; a change that looks like a clean win under localise_diff's tolerant alignment can still
' tank the real score if it does not also close the length gap. That edit was reverted, not
' applied. Net: this file is UNCHANGED (still -8/1996, matched 814/2004);
' it remains closer to the original than anything produced this pass.
'
' METHOD NOTE (arrived at independently more than once, worth repeating): total-length arithmetic
' (before/after `our_len`) is a fast filter but CANNOT tell you whether a change fixed the right
' thing or coincidentally cancelled with an unrelated bug elsewhere (see FIX #9's zero-`our_len`-
' effect that was nonetheless a real byte-identity bug, and FIX #10's zero-`our_len`-effect that
' was nonetheless a real localisation improvement). Confirm a hypothesis by pulling a KEPT probe
' exe (`harness.try_method(..., keep=True)`), then `bytematch.find_method(exe, 'TEngine',
' 'UpdateOffset')` for the VA/length, then `bytematch.disasm_original(va, n, path=exe)`, and diff
' the CLEAN disassembly window against `bytematch.disasm_original(0x004CFB35, 2004)` for the same
' ORIGINAL-relative offsets -- not just localise_diff's before/after gap windows, which show the
' OLD code until you rebuild.
'
' Camera target/offset/zoom update, called once per match tick from TEngine.Update(0.1).
' Computes a target look-at point (campointx/y) from one of several sources selected by
' g_player_int01 (camera mode: 0..11), smooths TEngine's scroll offset toward it by a0 (dt),
' and clamps the offset to the pitch edges.
'
' FIELDS: TBall.x/y=0x18/0x1c, TBall.controlledby=0x70, TBall.setpiecetaker=0x80 (all verified
' via object_model.json). TPlayer.x/y=0x4c/0x50, TPlayer.selectionno=0xbc,
' TPlayer.directiontogoal_opp=0xe0 (verified). TTeam.newstarselno=0x3c (verified, matches the
' TTeam.New field-initialiser = -1 precedent already in the corpus).
'
' GLOBALS (all from extracted/globals_final.tsv unless noted):
'   g_engine_float01 0x00c5b1d4 zoom  g_engine_float02/03 0x00c5b1d8/dc offsetX/Y
'   g_engine_float04/05/06 0x00c5b1e0/e4/e8 prev-offsetX/Y/zoom (save-only, unread elsewhere in body)
'   g_engine_float10/11 0x00c73d3c/40 default target X/Y   g_engine_float12/13 0x00c73d44/48
'   g_campan_ratezoom2/ratezoomdefault 0x00c73d4c/50 and g_campan_ratex/ratey 0x00c73d54/58 --
'     OURS, not in globals_final.tsv (that table stops at g_engine_float13/0x00c73d48; these four
'     are the next 4 floats in the same contiguous block, unsurveyed). Type Float confirmed by
'     the disasm (all x87 dword loads).
'   g_player_int01 0x00c5b1fc mode (verified elsewhere as TPlayer's row, reused here as camera mode)
'   g_player_int16/17/19 0x00c5d634/38/58 (int19 is 0x00c5d658)
'   g_player_tplayer01 0x00c5b248 (verified TPlayer usage row)
'   g_hometeam/g_awayteam 0x00c5b218/1c (majority name in corpus; globals_typed.tsv confirms TTeam)
'   g_options_int06 0x00c5d24c   g_engine_int14/15/16 0x00c5b1ec/f0/f4
'   g_engine_int162/163 0x00c6efe4/e8 (pitch width/height)   g_training_int03 0x00c6cf90
'
' CALLS: TBall.GetActiveBall (slot 0x44), TEngine.GetWinningClub (0xf8), TEngine.SetPiece (0x74),
'   TPlayer.GetHumanPlayer (0x164), TTraining.GetFocus(:TPlayer,*f,*f)i (0xa8), TPitch.YardsToPixels
'   (0x6c), TPlayer.GetShootingDirection (0x160) -- all class-table-slot calls, masked by the
'   oracle. AngleTo/Dist2D/ClampFloat are the already-verified module Functions
'   (src/recovered_module/). _bbFloatToInt/_bbCos/_bbSin resolve via helper_map for the
'   Int()/Cos()/Sin() casts (_bbSin confirmed at 0x004A1F00).
'
' Run (feed through localise_diff._body_of() first -- this file is WRAPPED, see top-of-file note):
'   import localise_diff as L
'   r = L.localise_body('TEngine','UpdateOffset', L._body_of(THIS_FILE_PATH), max_gaps=30)
'   print(L.report(r))
' to reproduce the current -8 state and get fresh disassembly windows for each open gap above.
' (Passing the raw WRAPPED file text straight to localise_diff's CLI reads as our_len=14 --
' the empty-stub trap; do not let that read as a fresh regression.)
	Function UpdateOffset:Int(a0:Float)
		'!Global g_engine_float01:Float
		'!Global g_engine_float02:Float
		'!Global g_engine_float03:Float
		'!Global g_engine_float04:Float
		'!Global g_engine_float05:Float
		'!Global g_engine_float06:Float
		'!Global g_engine_float10:Float
		'!Global g_engine_float11:Float
		'!Global g_engine_float12:Float
		'!Global g_engine_float13:Float
		'!Global g_campan_ratezoom2:Float
		'!Global g_campan_ratezoomdefault:Float
		'!Global g_campan_ratex:Float
		'!Global g_campan_ratey:Float
		'!Global g_player_int01:Int
		'!Global g_player_int16:Int
		'!Global g_player_int17:Int
		'!Global g_player_int19:Int
		'!Global g_player_tplayer01:TPlayer
		'!Global g_hometeam:TTeam
		'!Global g_awayteam:TTeam
		'!Global g_options_int06:Int
		'!Global g_engine_int14:Int
		'!Global g_engine_int15:Int
		'!Global g_engine_int16:Int
		'!Global g_engine_int162:Int
		'!Global g_engine_int163:Int
		'!Global g_training_int03:Int
		g_engine_float04 = g_engine_float02
		g_engine_float05 = g_engine_float03
		g_engine_float06 = g_engine_float01
		Local campointx:Float = g_engine_float10
		Local campointy:Float = g_engine_float11
		Local ball:TBall = TBall.GetActiveBall()
		If ball <> Null Then
			campointx = ball.x * g_engine_float01
			campointy = ball.y * g_engine_float01
			If g_player_int01 = 2 Then
				If ball.setpiecetaker <> Null Then
					campointx = ball.setpiecetaker.x * g_engine_float01
					campointy = ball.setpiecetaker.y * g_engine_float01
				EndIf
			ElseIf g_player_int01 = 8 Then
				If g_player_tplayer01 <> Null Then
					campointx = g_player_tplayer01.x * g_engine_float01
					campointy = g_player_tplayer01.y * g_engine_float01
				EndIf
			ElseIf g_player_int01 = 0 Then
				campointx = Float(-g_player_int16) * g_engine_float01
				campointy = g_engine_float12
			ElseIf g_player_int01 = 11 Then
				Local winner:TTeam = TEngine.GetWinningClub()
				If winner <> Null Then
					For Local p:TPlayer = EachIn winner.squad
						If p.selectionno = 5 Then
							campointx = p.x * g_engine_float01
							campointy = p.y * g_engine_float01
						EndIf
					Next
				Else
					campointx = Float(-g_player_int16) * g_engine_float01
					campointy = g_engine_float13
				EndIf
			Else
				If TEngine.SetPiece() And (ball.setpiecetaker <> Null) And (ball.controlledby = ball.setpiecetaker) Then
					Local angle:Int = ball.setpiecetaker.directiontogoal_opp
					Local distance:Int = 0
					Select g_player_int01
						Case 4
							distance = Int(TPitch.YardsToPixels(10.0))
						Case 6
							distance = Int(TPitch.YardsToPixels(10.0))
						Case 5
							distance = Int(TPitch.YardsToPixels(20.0))
							angle = Int(AngleTo(ball.setpiecetaker.x, ball.setpiecetaker.y, 0.0, Float(g_player_int19 * ball.setpiecetaker.GetShootingDirection())))
					End Select
					Local dx:Double = ball.x
					dx = dx + Cos(angle) * distance
					campointx = g_engine_float01 * Float(dx)
					Local dy:Double = ball.y
					dy = dy + Sin(angle) * distance
					campointy = g_engine_float01 * Float(dy)
				EndIf
			EndIf
			If (g_hometeam.newstarselno > -1 Or g_awayteam.newstarselno > -1) And g_options_int06 > 0 Then
				Local human:TPlayer = TPlayer.GetHumanPlayer()
				If human <> Null And human.selectionno < 11 Then
					If Not(TEngine.SetPiece() And (human = ball.setpiecetaker)) Then
						If g_player_int01 <> 0 And g_player_int01 <> 7 And g_player_int01 <> 9 And g_player_int01 <> 10 Then
							If g_options_int06 = 1 Then
								campointx = human.x * g_engine_float01
								campointy = human.y * g_engine_float01
							Else
								Local bx:Float = ball.x
								Local by:Float = ball.y
								If g_training_int03 <> 0 Then TTraining.GetFocus(human, Varptr bx, Varptr by)
								Local basef:Float = Float(g_engine_int163 - 100)
								Local distf:Float = TPitch.YardsToPixels(15.0)
								Local d2:Float = Dist2D(bx, by, human.x, human.y)
								distf = distf + d2
								basef = basef / distf
								If g_options_int06 = 2 Then
									g_engine_float01 = g_engine_float01 + (basef - g_engine_float01) * g_campan_ratezoom2
									ClampFloat(Varptr g_engine_float01, 0.75, 1.75)
								Else
									g_engine_float01 = g_engine_float01 + (basef - g_engine_float01) * g_campan_ratezoomdefault
									ClampFloat(Varptr g_engine_float01, 0.5, 1.25)
								EndIf
								campointx = (human.x - bx) * g_campan_ratex + bx
								campointy = (human.y - by) * g_campan_ratey + by
								campointx = campointx * g_engine_float01
								campointy = campointy * g_engine_float01
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If g_training_int03 <> 0 Then
				Local human2:TPlayer = TPlayer.GetHumanPlayer()
				If human2 <> Null Then
					Local fx:Float = human2.x
					Local fy:Float = human2.y
					TTraining.GetFocus(human2, Varptr fx, Varptr fy)
					campointx = fx * g_engine_float01
					campointy = fy * g_engine_float01
				EndIf
			EndIf
		EndIf
		campointx = campointx - (g_engine_int162 / 2)
		campointy = campointy - (g_engine_int163 / 2)
		g_engine_float02 = g_engine_float02 + (campointx - g_engine_float02) * a0
		g_engine_float03 = g_engine_float03 + (campointy - g_engine_float03) * a0
		Local basea:Float = Float(g_player_int16)
		Local limita:Float = (basea + TPitch.YardsToPixels(Float(g_engine_int14))) * g_engine_float01
		Local baseb:Float = Float(g_player_int17)
		Local limitb:Float = (baseb + TPitch.YardsToPixels(Float(g_engine_int15))) * g_engine_float01
		Local limitc:Float = (baseb + TPitch.YardsToPixels(Float(g_engine_int16))) * g_engine_float01
		If -limita < limita - g_engine_int162 Then
			ClampFloat(Varptr g_engine_float02, -limita, limita - g_engine_int162)
		Else
			g_engine_float02 = Float(-(g_engine_int162 / 2))
		EndIf
		If -limitb < limitb - g_engine_int163 Then
			ClampFloat(Varptr g_engine_float03, -limitb, limitc - g_engine_int163)
		Else
			g_engine_float03 = Float(-(g_engine_int163 / 2))
		EndIf
	End Function
