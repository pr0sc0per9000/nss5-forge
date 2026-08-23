' TFormation.GetPlayerXY -- VA 0x004D8B85, 2898 bytes, vtable slot 0x58 -- byte-identical vs NSS5.exe
' VA 0x004d8b85   2898 bytes   vtable slot 0x58   sig (i,f,f,f,f,i,i,*f,*f,f,f)f
'
' harness.try_method('TFormation','GetPlayerXY', <this body>) under NSS5_NO_LEARN=1 returns
' MATCH, our_len 2898 == orig_len 2898 (length_source=ghidra), matched 2898/2898. Reproduced
' twice in separate processes on worker 223, and RE-CONFIRMED independently on worker 253
' (2026-08-22): two fresh try_method calls in separate processes, both MATCH, matched
' 2898/2898; scripts/localise_diff.py on worker 253 reports "CLEAN -- byte-identical modulo
' the oracle's masks", 0 gaps. Promoted from src/recovered_unverified to src/recovered on
' the strength of that fresh worker-253 measurement; the header text above previously said
' "VERIFIED MATCH" but never carried the literal "byte-identical vs NSS5.exe" phrase
' scripts/progress.py greps for, so this body was undercounted as unmatched even though the
' oracle had already closed it. NOTE FOR THE CORPUS: this is exactly the trap RULES.md
' warns about in reverse -- not a false positive slipping into the matched count, but a true
' positive stuck outside it because the header prose did not match the checker's regex.
'
' === HOW IT CLOSED: FIVE SOURCE CHANGES, MEASURED ONE STEP AT A TIME ===
' It closed from source, not from an allocator change. Every previous pass diagnosed the
' residual as a register-allocator tie-break and stopped there; that diagnosis was wrong.
' The evidence that broke it open was the ORIGINAL's own stack-slot census -- enumerate every
' distinct `[ebp-N]` in NSS5.exe's disassembly of this function, count the references per
' slot, and compare that table against `scripts/workflow/walloc_report.py`'s
' usage/degree/block_count keyed by source variable name. The two tables line up variable by
' variable, and where they fail to line up is the defect.
'
' Sequence, each step measured with localise_diff.py before the next was applied:
'   baseline        gaps 31  subs 49  delta   0   (first divergence at ORIGINAL +3, prologue)
'   +change 1       gaps 25  subs 39  delta +10   (first divergence moves to +89)
'   +change 2       gaps 23  subs 39  delta +10
'   +change 3       gaps  9  subs  5  delta -18
'   +change 4       gaps  5  subs  5  delta -14
'   +change 5       gaps  0  subs  0  delta   0   MATCH
'
' CHANGE 1 -- the missing frame slot, found in the a5<>1 widepush term.
'   The original's frame is `sub esp,0x34` (13 slots), ours was `sub esp,0x30` (12). Earlier
'   passes knew this and could not place the missing slot. The slot census places it exactly:
'   the original has FIVE unnamed 4-reference expression temporaries, we had four, and the
'   extra one lives at original offsets +1902..+1969 -- the a5<>1 mirror's bVar8 body.
'   Original there (0x004D92ED..):
'       fild(yOff) -> fstp [-4]                 ' T1
'       fld hSpacing -> fstp [-0x10]            ' T2   <-- hSpacing stored ALONE
'       fld widepush; fmul 0.5 -> fstp [-0x14]  ' T3
'       Abs(dxRatio); T3 = T3*Abs; T2 = T2*T3; T1 = T1+T2
'   Three values live across the Abs() call, so three memory temps. The a5=1 mirror
'   (+968..+1031) computes `hSpacing * (widepush*0.5)` with a single `fmulp` and has only TWO
'   values live across the call. The two mirrors are parenthesised DIFFERENTLY in the original
'   source. Ours used the a5=1 grouping in both. Fixed by moving one closing paren:
'       yOff = Int(Float(yOff) + hSpacing * (g_form_widepush * 0.5 * Abs(dxRatio)))
'   walloc_report confirmed the prediction registered before the build: unnamed spilled temps
'   4 -> 5, frame 0x30 -> 0x34, and every named Local's slot deepened by 4 to sit exactly
'   where the original puts it. NOTE FOR THE CORPUS: this is a liveness fix, but NOT the one
'   section 18.4 describes -- not one named Local's usage/degree/block_count moved (all eleven
'   were byte-identical before and after). The lever was the number of ANONYMOUS
'   sub-expression temporaries live across a call, which is set by operator grouping. A
'   block_count hunt over named Locals would never have found it.
'
' CHANGE 2 -- a5<>1 widepush operand order. Original at +1782 emits the Float(yOff)
'   conversion FIRST, then hSpacing*widepush, then faddp:
'       yOff = Int(Float(yOff) + hSpacing * g_form_widepush)
'   not the `hSpacing * g_form_widepush + Float(yOff)` spelling an earlier pass installed
'   (which emits the multiply first). Same operand order as the a5=1 mirror's `-` form.
'   Worth +9/-9 of shape at zero net length, which is why it survived so long.
'
' CHANGE 3 -- THE BIG ONE: the tail is four Locals, and `a1` is never reassigned there.
'   The original NEVER stores to [ebp+0x10] (a1's own parameter slot) after offset +212.
'   From +2315 it builds four bare values on the x87 stack, in this order, BEFORE the
'   `cmp edi,0` that selects xshift vs xshiftnoball:
'       R1 = a3/2.0 - Float(xOff)      R2 = a4/2.0 + Float(yOff)
'       R3 = a1     - Float(xOff)      R4 = a2     + Float(yOff)
'   R1 and R2 being computed BEFORE the branch, and R2 being consumed only AFTER it, is the
'   tell: they are named values whose live range crosses the If. R3 and R4 are each
'   duplicated on-stack (`fld st(1)` / `fld st(2)`), so each is read twice. That is exactly
'   four Locals declared in that order, and it is what this body now says:
'       Local xMid:Float = a3 / 2.0 - Float(xOff)
'       Local yMid:Float = a4 / 2.0 + Float(yOff)
'       Local xPos:Float = a1 - Float(xOff)
'       Local yPos:Float = a2 + Float(yOff)
'       If a6 <> 0 ... xPos = xPos - (xPos - xMid) / g_form_xshift ...
'       Local leg:Float = yPos - (yPos - yMid) / g_form_yshift
'   The previous header's "fix #4" -- reassigning `a1` in place -- was the opposite of the
'   truth, and it forced a store/reload of a1 at every step, which is what scrambled the
'   whole tail. This one change took gaps 23 -> 9 and subs 39 -> 5. It also dissolved, with
'   no further work, the two things three passes had chased directly: the col/wSpacing spill
'   ORDER swap (wSpacing now lands at [ebp-0x24] and col at [ebp-0x20], as in the original)
'   and the site-3 `fxch st(2)` 3-deep compare idiom, which appears by itself once xPos and
'   leg both stay FPU-resident.
'
' CHANGE 4 -- Case 1 depth adjust grouping, both mirrors:
'       a2 = a2 +/- hSpacing * (g_form_depth * 0.5)
'   Original at 0x004D8D52 is `fld hSpacing; fld depth; fmul 0.5; fmulp st(1)` (4 ops, one
'   extra push); our `g_form_depth * 0.5 * hSpacing` folded to 3 ops. Worth 2 bytes per
'   mirror. An earlier pass measured this same change as a large regression and reverted it;
'   it was correct then too, and only looked wrong because the tail (change 3) was still
'   swamping the aggregate score. A locally-correct fix can score worse while a larger defect
'   is live -- do not revert on the aggregate alone.
'
' CHANGE 5 -- all FIVE `bound < var` clamps become `var > bound`:
'       If a1 > a3 - wSpacing * 3.0 ...              (orig +237)
'       If a2 > a4 - hSpacing * 1.0 ...              (orig +327)
'       If xPos > a3 - wSpacing * wScale * 0.5 ...   (orig +2496)
'       If leg  > a4 - hSpacing * hScale * 0.5 ...   (orig +2606)
'       ElseIf leg > a4 / 12.0 + a4 / 2.0            (orig +2802)
'   Mechanism (already correctly derived by an earlier pass from
'   _src/codegen/cgfixfp_x86.cpp): FPStack::fcomp starts with fxch(rd) where rd is the
'   LHS AS WRITTEN, and fxch emits nothing when rd is already on top. Evaluation order puts
'   the bare var on top, so writing the var on the LEFT makes the fxch free and picks the
'   complementary setcc. The first two clamps lose a 2-byte `fxch st(1)` each; the last three
'   GAIN 6 bytes each, swapping our 2-byte popping `fucomp st(n)` for the original's
'   `fxch st(n) / fucom st(n) / fxch st(n) / fstp st(0)` preserve-and-discard idiom, which is
'   what the tail needs now that two values stay live on the stack. Net -4 +18 = +14, which
'   with change 4's +4 closes the -18 exactly. Earlier passes measured the two halves of this
'   in isolation and read each as a regression; they are one change and only net out together.
'
' === MEASURED ALLOCATOR NUMBERS (scripts/workflow/walloc_report.py --worker walloc223, on
' === the FINAL matching body). Recorded so no later pass has to re-derive them.
'   name      usage degree block_count  outcome        original slot (confirmed by disasm)
'   dxRatio      7     85      95       [ebp-0x2c]     [ebp-0x2c]
'   col         13     71     159       [ebp-0x20]     [ebp-0x20]
'   row          6     62     156       [ebp-0x30]     [ebp-0x30]
'   wSpacing    26    154     149       [ebp-0x24]     [ebp-0x24]
'   hSpacing    27    161     152       [ebp-0x1c]     [ebp-0x1c]
'   yOff        21     50     132       esi            esi
'   xOff        17     52     128       ebx            ebx
'   wScale      19    107     123       [ebp-0x28]     [ebp-0x28]
'   hScale      27    122     111       [ebp-0x18]     [ebp-0x18]
'   bVar8        4      9       1       eax            eax
'   xMid         3     20       1       fp4            (x87 stack, no slot)
'   yMid         2     21       3       fp3            (x87 stack, no slot)
'   xPos        12     47      22       fp2            (x87 stack, no slot)
'   yPos         3     13       3       fp1            (x87 stack, no slot)
'   leg         10     30      17       fp2            (x87 stack, no slot)
' Plus 5 unnamed expression temps at [ebp-4] [ebp-8] [ebp-0xc] [ebp-0x10] [ebp-0x14] and a
' 4-byte compiler-internal fild scratch at [ebp-0x34]: 13 slots, `sub esp,0x34`, as original.
' For reference, the pre-fix build differed from this table in exactly two ways: only FOUR
' unnamed temps (frame 0x30, everything below [ebp-0x14] four bytes shallower) and wSpacing
' spilled before col rather than after. No named Local's usage/degree/block_count differed.
'
' === STANDING IDENTIFICATIONS (all re-confirmed, unchanged) ===
' Globals, with addresses: g_form_width 0xC5BB3C, g_form_widthnoball 0xC5BB40,
' g_form_height 0xC5BB38, g_form_depth 0xC5BB44, g_form_widepush 0xC5BB48,
' g_form_xshift 0xC5BB4C, g_form_xshiftnoball 0xC5BB50, g_form_yshift 0xC5BB54,
' g_form_ymargin 0xC5BB58, g_form_wscale_default 0xC74BC8, g_form_hscale_default 0xC74BCC,
' g_form_posnoise 0xC74D10, g_player_int01 0xC5B1FC. Abs = 0x004A7FE0.
' Still correct and carried forward from earlier passes: the `a2 = -a2` split-fusion,
' Select-not-If for both big dispatches, `If row <= 2` (not `< 3`) in both mirrors,
' `If a6 <> 0` as the primary test everywhere, the two separately-worded wSpacing divisions,
' the single-expression short-circuit form of bVar8 in both mirrors, and no materialised
' `wBoost`/`adj` temporaries.

'!Global g_form_height:Float
'!Global g_form_width:Float
'!Global g_form_widthnoball:Float
'!Global g_form_depth:Float
'!Global g_form_widepush:Float
'!Global g_form_xshift:Float
'!Global g_form_xshiftnoball:Float
'!Global g_form_yshift:Float
'!Global g_form_ymargin:Float
'!Global g_form_wscale_default:Float
'!Global g_form_hscale_default:Float
'!Global g_form_posnoise:Float
'!Global g_player_int01:Int
	Method GetPlayerXY:Float(a0:Int, a1:Float, a2:Float, a3:Float, a4:Float, a5:Int, a6:Int, a7:Float Ptr, a8:Float Ptr, a9:Float, a10:Float)
		a2 = -a2
		Local dxRatio:Float = a1 / (a3 / 2.0)
		a1 = a1 + a3 / 2.0
		a2 = a2 + a4 / 2.0
		Local col:Int = Self.GetColFromSelectionNo(a0)
		Local row:Int = Self.GetRowFromSelectionNo(a0)
		Local wSpacing:Float
		If a6 <> 0
			wSpacing = a3 / (g_form_width * a9)
		Else
			wSpacing = a3 / (g_form_widthnoball * a9)
		EndIf
		Local hSpacing:Float = a4 / (g_form_height * a10)
		Local yOff:Int = 0
		Local xOff:Int = 0
		If a1 < wSpacing * 3.0 Then a1 = wSpacing * 3.0
		If a1 > a3 - wSpacing * 3.0 Then a1 = a3 - wSpacing * 3.0
		If a2 < hSpacing * 1.0 Then a2 = hSpacing * 1.0
		If a2 > a4 - hSpacing * 1.0 Then a2 = a4 - hSpacing * 1.0
		If a5 = 1
			wSpacing = wSpacing + (a4 - a2) / 30.0
		Else
			wSpacing = wSpacing + a2 / 30.0
		EndIf
		Local wScale:Float = g_form_wscale_default
		Local hScale:Float = g_form_hscale_default
		Local bVar8:Int
		If a5 = 1
			Select a6
				Case 0
					a2 = a2 + hSpacing * g_form_depth
				Case 1
					a2 = a2 + hSpacing * (g_form_depth * 0.5)
			End Select
			Select row
				Case 0
					yOff = Int(hSpacing * 1.25)
					If a6 <> 0 Then hScale = 1.8 Else hScale = 1.0
				Case 1
					yOff = Int(hSpacing * 0.5)
					If a6 <> 0 Then hScale = 1.6 Else hScale = 1.2
				Case 2
					yOff = Int(-(hSpacing * 0.25))
					If a6 <> 0 Then hScale = 1.4 Else hScale = 1.4
				Case 3
					yOff = Int(-(hSpacing * 1.0))
					If a6 <> 0 Then hScale = 1.2 Else hScale = 1.6
				Case 4
					yOff = Int(-(hSpacing * 1.75))
					If a6 <> 0 Then hScale = 1.0 Else hScale = 1.8
			End Select
			If row <= 2
				If a6 <> 0
					If col = 0 Or col = 6
						yOff = Int(Float(yOff) - hSpacing * g_form_widepush)
					EndIf
				Else
					bVar8 = (dxRatio > 0.0 And col = 0) Or (dxRatio <= 0.0 And col = 6)
					If bVar8
						yOff = Int(Float(yOff) - hSpacing * (g_form_widepush * 0.5) * Abs(dxRatio))
					EndIf
				EndIf
			EndIf
			Select col
				Case 0
					xOff = Int(-(wSpacing * 4.5))
					wScale = 1.5
				Case 1
					xOff = Int(-(wSpacing * 3.5))
					wScale = 2.0
				Case 2
					xOff = Int(-(wSpacing * 1.5))
					wScale = 3.0
				Case 3
					xOff = 0
					wScale = 3.5
				Case 4
					xOff = Int(wSpacing * 1.5)
					wScale = 3.0
				Case 5
					xOff = Int(wSpacing * 3.5)
					wScale = 2.0
				Case 6
					xOff = Int(wSpacing * 4.5)
					wScale = 1.5
			End Select
		Else
			Select a6
				Case 0
					a2 = a2 - hSpacing * g_form_depth
				Case 1
					a2 = a2 - hSpacing * (g_form_depth * 0.5)
			End Select
			Select row
				Case 0
					yOff = Int(-(hSpacing * 1.25))
					If a6 <> 0 Then hScale = 1.8 Else hScale = 1.0
				Case 1
					yOff = Int(-(hSpacing * 0.5))
					If a6 <> 0 Then hScale = 1.6 Else hScale = 1.2
				Case 2
					yOff = Int(hSpacing * 0.25)
					If a6 <> 0 Then hScale = 1.4 Else hScale = 1.4
				Case 3
					yOff = Int(hSpacing * 1.0)
					If a6 <> 0 Then hScale = 1.2 Else hScale = 1.6
				Case 4
					yOff = Int(hSpacing * 1.75)
					If a6 <> 0 Then hScale = 1.0 Else hScale = 1.8
			End Select
			If row <= 2
				If a6 <> 0
					If col = 0 Or col = 6
						yOff = Int(Float(yOff) + hSpacing * g_form_widepush)
					EndIf
				Else
					bVar8 = (dxRatio < 0.0 And col = 0) Or (dxRatio >= 0.0 And col = 6)
					If bVar8
						yOff = Int(Float(yOff) + hSpacing * (g_form_widepush * 0.5 * Abs(dxRatio)))
					EndIf
				EndIf
			EndIf
			Select col
				Case 0
					xOff = Int(wSpacing * 4.5)
					wScale = 1.5
				Case 1
					xOff = Int(wSpacing * 3.5)
					wScale = 2.0
				Case 2
					xOff = Int(wSpacing * 1.25)
					wScale = 3.0
				Case 3
					xOff = 0
					wScale = 3.5
				Case 4
					xOff = Int(-(wSpacing * 1.25))
					wScale = 3.0
				Case 5
					xOff = Int(-(wSpacing * 3.5))
					wScale = 2.0
				Case 6
					xOff = Int(-(wSpacing * 4.5))
					wScale = 1.5
			End Select
		EndIf
		If g_player_int01 = 1 Then hScale = hScale * g_form_ymargin
		Local xMid:Float = a3 / 2.0 - Float(xOff)
		Local yMid:Float = a4 / 2.0 + Float(yOff)
		Local xPos:Float = a1 - Float(xOff)
		Local yPos:Float = a2 + Float(yOff)
		If a6 <> 0
			xPos = xPos - (xPos - xMid) / g_form_xshift
		Else
			xPos = xPos - (xPos - xMid) / g_form_xshiftnoball
		EndIf
		Local leg:Float = yPos - (yPos - yMid) / g_form_yshift
		If xPos < wSpacing * wScale * 0.5 Then xPos = wSpacing * wScale * 0.5
		If xPos > a3 - wSpacing * wScale * 0.5 Then xPos = a3 - wSpacing * wScale * 0.5
		If leg < hSpacing * hScale * 0.5 Then leg = hSpacing * hScale * 0.5
		If leg > a4 - hSpacing * hScale * 0.5 Then leg = a4 - hSpacing * hScale * 0.5
		If row = 0 And col > 1 And col < 5
			If a5 = 1
				If leg < a4 / 2.0 - a4 / 12.0 Then leg = a4 / 2.0 - a4 / 12.0
			ElseIf leg > a4 / 12.0 + a4 / 2.0
				leg = a4 / 12.0 + a4 / 2.0
			EndIf
		EndIf
		a7[0] = xPos - a3 / 2.0
		a8[0] = leg - a4 / 2.0
		a8[0] = -a8[0]
		Return g_form_posnoise
	End Method
