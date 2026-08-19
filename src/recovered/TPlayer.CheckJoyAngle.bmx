' TPlayer.CheckJoyAngle  -- KIND=Method, sig ()i, slot 0x184
' VA 0x004FB5CD   1739 bytes
' byte-identical vs NSS5.exe (1739/1739, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=49). Re-verified under NSS5_NO_LEARN=1 twice, the second time with a
' separate toolchain copy -- not a self-fulfilling masking result.
'
' ASSUMPTIONS
'   g_activeball:TBall   0x00C5DEA4  (same Global as TPlayer.UpdateJoy's g_activeball;
'       codegen-patterns 11.2 -- full retain/release traffic, confirmed TBall. The
'       auto-annotator's guess "g_player_tplayer02" is the SAME address; renamed here to
'       match the already-established sibling file.)
'   g_player_int01:Int   0x00C5B1FC  (match-state code; matches many other TPlayer files,
'       e.g. TPlayer.UpdateJoy, TEngine.UpdateSounds)
'   TPlayer.x = +0x4C, TPlayer.y = +0x50, TPlayer.joy:TJoy = +0x158; TJoy.direction = +0x14
'   (confirmed against object_model.json and against TPlayer.DoHeadingAI.bmx's header note).
'   TBall.setpiecetaker:TPlayer = +0x80.
'   All float constants read directly out of NSS5.exe's .rdata via struct.unpack over
'   va2off (never guessed): 80/280/180/280/80/180/135/270/270/215/90/90/305/90/305/215/215/
'   45/270/45/135/135 (case 6), same five values again for case 7 and again for case 9
'   (three byte-identical duplicated bodies -- see below).
'
' CODEGEN NOTES
'   Guard: `g_activeball <> Null And g_activeball.setpiecetaker <> Self Then Return 0` is
'   the same short-circuit idiom as TPlayer.UpdateJoy's guard -- the second operand's
'   dereference is skipped entirely when the Global is Null (confirmed against the
'   disassembly: no `mov eax,[eax+0x80]` executes unless the first `setne` was true).
'
'   Top-level dispatch on g_player_int01 is a genuine Select (guide 10.2): all six
'   `cmp/je` compares (3,2,5,6,7,9) run back to back before any Case body, and the
'   no-match path is a single `jmp` past every body -- there is no Default.
'
'   THREE distinct codegen rules were needed to reach byte-exactness, each confirmed by
'   reading the original bytes directly (harness.disasm_original), not guessed:
'
'   1. BRANCH SWAP (guide 21, extended past its worked example). Every solo-relational
'      `If cond Then A Else B` in this function -- with A and B genuinely different code --
'      compiles, when written the "natural" way matching Ghidra's C literally, to a
'      NEGATED test with A (the written Then) as the fall-through and B (the written Else)
'      as the jump target. The ORIGINAL's bytes are consistently the OPPOSITE physical
'      shape: an UNNEGATED test, with the Else-content physically first (fall-through) and
'      the Then-content second (reached via `jne`). To reproduce that shape the source must
'      be written negated-and-swapped: `If Not-cond Then B Else A`. Confirmed and applied at
'      every top-level 2-arm test in the function (Case 3's x-test, Case 2's x-test, Case
'      5's x-test AND its nested y-test, Case 6/7/9's y-tests). Also applies one level
'      deeper: Case 3's inner `dir<=180 / dir>180` choice, and Case 5's `y<=0` sub-cascade
'      choosing between the "215/90" pair and the "dir<135/dir<270" pair -- EVEN THOUGH the
'      latter is the outer test of a multi-rung cascade whose OWN last rung has no trailing
'      Else (guide 21's stated exception is genuinely narrower than "any cascade": only the
'      truly LAST rung, whose Else is empty, is unnegated; an earlier rung whose Else is the
'      rest of the cascade still gets swapped).
'
'   2. EXPLICIT EARLY `Return 0` after every direct `Self.joy.direction = <value>` in Cases
'      5, 6, 7 and 9 (never after a `ClampFloat` call, and never in Cases 2/3, which fall
'      through to the Select's own trailing `Return 0` normally). Byte-observable: the
'      original reaches the function epilogue two different ways -- a shared `mov eax,0 /
'      jmp <epilogue>` stub at the very end of the Select (used by Case 2/3's assignments
'      and by every ClampFloat branch), and a DUPLICATED inline `mov eax,0 / jmp <epilogue>`
'      immediately after each of these specific assignments (used only by Cases 5/6/7/9).
'      Omitting the explicit Return produced a body 138 bytes SHORT despite every branch's
'      VALUE logic already being correct -- the missing bytes were exactly these repeated
'      5-byte inline returns.
'
'   3. OPERAND ORDER in a `constant OP field` comparison. Ghidra prints
'      `_DAT_00cXXXXX < Self.joy.direction` uniformly, but the original's `fld` sequence
'      loads the FIELD first and the constant second for roughly half of these (Case 3's
'      `dir>80.0` term, Case 5's `dir>215.0`/`dir>90.0`, and one term of each Or-compound in
'      Cases 6/7/9: `dir>305.0`, `dir>270.0`, `dir>135.0`), matching the source literally
'      reading `Self.joy.direction > <const>` (field-first), not Ghidra's printed
'      `<const> < Self.joy.direction`. Six matching insert/delete gap pairs (each exactly
'      6 bytes -- the field-address `mov`+`fld` reordering relative to the constant `fld`)
'      pinpointed every remaining site once the branch-swap and Return-0 fixes made the
'      body length-exact.
'
'   Case 7 and Case 9 are BYTE-IDENTICAL bodies under two different Case labels, confirmed
'   by their content sitting at two different VAs in the original (0x004FB9F8 and
'   0x004FBB47) rather than a shared target from one `Case 7,9` -- reproduced duplicated
'   per law 4 (do not DRY).
'!Global g_ball:TBall
'!Global g_player_int01:Int
	Method CheckJoyAngle:Int()
		If g_ball <> Null And g_ball.setpiecetaker <> Self Then Return 0
		Select g_player_int01
		Case 3
			If Self.x > 0.0
				ClampFloat(Varptr Self.joy.direction, 100.0, 260.0)
			Else
				If Self.joy.direction > 80.0 And Self.joy.direction < 280.0
					If Self.joy.direction > 180.0
						Self.joy.direction = 280.0
					Else
						Self.joy.direction = 80.0
					EndIf
				EndIf
			EndIf
		Case 2
			If Self.x > 0.0
				Self.joy.direction = 180.0
			Else
				Self.joy.direction = 0.0
			EndIf
		Case 5
			If Self.x > 0.0
				If Self.y > 0.0
					ClampFloat(Varptr Self.joy.direction, 180.0, 270.0)
				Else
					ClampFloat(Varptr Self.joy.direction, 90.0, 180.0)
				EndIf
			Else
				If Self.y > 0.0
					If Self.joy.direction < 135.0
						Self.joy.direction = 0.0
						Return 0
					ElseIf Self.joy.direction < 270.0
						Self.joy.direction = 270.0
						Return 0
					EndIf
				Else
					If Self.joy.direction > 215.0
						Self.joy.direction = 0.0
						Return 0
					ElseIf Self.joy.direction > 90.0
						Self.joy.direction = 90.0
						Return 0
					EndIf
				EndIf
			EndIf
		Case 6
			If Self.y > 0.0
				If Self.joy.direction > 305.0 Or Self.joy.direction < 90.0
					Self.joy.direction = 305.0
					Return 0
				ElseIf Self.joy.direction < 215.0
					Self.joy.direction = 215.0
					Return 0
				EndIf
			Else
				If Self.joy.direction < 45.0 Or Self.joy.direction > 270.0
					Self.joy.direction = 45.0
					Return 0
				ElseIf Self.joy.direction > 135.0
					Self.joy.direction = 135.0
					Return 0
				EndIf
			EndIf
		Case 7
			If Self.y < 0.0
				If Self.joy.direction > 305.0 Or Self.joy.direction < 90.0
					Self.joy.direction = 305.0
					Return 0
				ElseIf Self.joy.direction < 215.0
					Self.joy.direction = 215.0
					Return 0
				EndIf
			Else
				If Self.joy.direction < 45.0 Or Self.joy.direction > 270.0
					Self.joy.direction = 45.0
					Return 0
				ElseIf Self.joy.direction > 135.0
					Self.joy.direction = 135.0
					Return 0
				EndIf
			EndIf
		Case 9
			If Self.y < 0.0
				If Self.joy.direction > 305.0 Or Self.joy.direction < 90.0
					Self.joy.direction = 305.0
					Return 0
				ElseIf Self.joy.direction < 215.0
					Self.joy.direction = 215.0
					Return 0
				EndIf
			Else
				If Self.joy.direction < 45.0 Or Self.joy.direction > 270.0
					Self.joy.direction = 45.0
					Return 0
				ElseIf Self.joy.direction > 135.0
					Self.joy.direction = 135.0
					Return 0
				EndIf
			EndIf
		End Select
		Return 0
	End Method
