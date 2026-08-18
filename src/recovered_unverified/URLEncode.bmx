' NOT VERIFIED -- URLEncode, module-level Function (no Type)
' VA 0x005084a8   343 bytes   sig ($,i,i)$   (decl: s:String, a1:Int, a2:Int)
' called_by_count=1 in the inventory -- only TScreen_WebPage.GetSocialMessage (0x0056142a)
' calls it, with args (str, 0, 0).
'
' STATUS: length-exact (343/343), MISMATCH at byte 19, matched=241/343.
' Confirmed NOT a logic error -- the whole statement/branch/call structure is right (that is
' WHY the length already matches exactly: 5 separate calls to bbStringSlice(s,i,i+1), one
' bbStringFind, two Asc+HexPad percent-encode sites, matching the original's block layout
' 1-for-1). The remaining defect is PURE REGISTER IDENTITY: the original keeps the
' accumulator `result` in ebx and the loop counter `i` in esi; our build swaps them (result
' in esi, i in ebx), which is a different opcode byte at every push/pop/ModRM/mov-imm32 site
' that touches either register -- same total length, ~100 bytes differ.
'
' RULED OUT:
'   - Not a missing/extra branch, not a wrong call target, not a wrong literal (length
'     already agrees exactly; codegen-patterns.md 21 confirms literal ADDRESSES are masked
'     but VALUES were read directly from the exe for every string constant used below).
'   - Explicit `Local result:String = ""` vs bare `Local result:String` -- IDENTICAL bytes
'     (the empty-string init is elided either way), so that lever does nothing.
'   - Declaring `result` textually BEFORE `reserved` (instead of after) -- made it WORSE
'     (matched dropped 241->238, first_diff moved earlier 19->12). Reverted.
'   - Reordering the If/ElseIf/Else branches is NOT viable at all: the original's actual
'     block order (reserved-check first, then space-check, then encodeAll-check, then
'     plain-copy) is fixed by the disassembly itself; reordering the source would silently
'     misrepresent the real control flow even if it happened to match bytes.
'
' NEXT LEVER TO TRY (untried): codegen-patterns.md section 22's `usage`/`degree`/
' `block_count` triad governs which of two co-resident register winners gets which specific
' colour, and section 18.2 explicitly declines to predict PHYSICAL register identity (only
' register-vs-stack is called byte-observable there) -- but the oracle here requires exact
' bytes, so the physical identity matters and was not solved by tie-break/declaration-order
' experiments alone. `tools/blitzmax-legacy-src/_src/codegen/cgallocregs.cpp`'s `simplify()`/
' `selectRegs()` (LIFO select-stack, colours assigned in REVERSE selection order) is the
' actual mechanism; hand-simulating it requires the full interference graph (all the call-
' result temporaries too, not just `result`/`i`), which was not attempted here for time.
' A structural CFG reshape of the guard around the loop body (per section 22's
' `TTable.Draw` precedent: If/Else vs If-then-Continue) is the most likely next experiment,
' since it changes block_count for `i` (live in every block) without necessarily changing
' `result`'s.
'
' Supporting functions already recovered and VERIFIED (bank these regardless of this file):
'   HexPad(n:Int,digits:Int):String = Right-N-hex-digits, src/recovered_module/HexPad.bmx,
'   44/44 MATCH.
'
' Candidate source (compiles, length-exact, NOT byte-identical -- do not promote to
' src/recovered_module/ until the register-identity defect above is fixed):
'
'	Function URLEncode:String(s:String, a1:Int, a2:Int)
'		Local reserved:String = "!*'();:@&=+$,/?%#[]~r~n"
'		Local result:String
'		For Local i:Int = 0 To s.Length - 1
'			If reserved.Find(s[i..i+1], 0) > -1
'				result :+ "%" + HexPad(Asc(s[i..i+1]), 2)
'			ElseIf s[i..i+1] = " "
'				If a2 <> 0
'					result :+ "+"
'				Else
'					result :+ "%20"
'				EndIf
'			ElseIf a1 <> 0
'				result :+ "%" + HexPad(Asc(s[i..i+1]), 2)
'			Else
'				result :+ s[i..i+1]
'			EndIf
'		Next
'		Return result
'	End Function
