' Fn_005084a8 -- NOT VERIFIED (near miss, 361/343 bytes; delta +18)
' VA 0x005084A8   orig 343 bytes (Ghidra inventory).  KIND=Function, module-level (no Self).
' Unattributed "code" function (not in vtable_map.tsv) -- one of the ~992 unattributed
' functions, so this name is OURS per section 8 of the skill, not a recovered original name.
' Verified via harness.try_function, NOT harness.try_method.
'
' SEMANTICS (fully understood, high confidence): a URL percent-encoder.
'   Fn_005084a8(s:String, encodeAll:Int, plusForSpace:Int):String
'   For each character ch of s:
'     - if ch is one of the RFC "reserved" set  !*'();:@&=+$,/?%#[]<CR><LF>
'         (literal at VA 0x00C7C540, confirmed via harness.read_string)
'       append "%" + the 2-digit uppercase hex of Asc(ch)   -- i.e. "%" + Right(Hex(Asc(ch)),2)
'     - else if ch = " "
'         if plusForSpace <> 0: append "+"      (literal 0x00C79738)
'         else:                 append "%20"    (literal 0x00C6EF14)
'     - else if encodeAll <> 0: percent-encode ch same as the reserved branch
'     - else: append ch unchanged
'   Called once, from TScreen_WebPage.GetSocialMessage (0x0056142A) as
'   Fn_005084a8(message, 0, 0) -- i.e. standard "%XX + %20 for space" URL-encoding, used to
'   build a tweet-intent / share-link URL for the in-game web/social share screen.
'
' Call-target identification (all from extracted/helper_map.py full_table() and cross-checked
' against tools/blitzmax-legacy-src/mod/brl.mod/blitz.mod/blitz_string.c):
'   0x004a7c90 _bbStringSlice(s,start,end)         -> Mid(s, start+1, end-start), i.e. Mid(s,i+1,1)
'   0x004a6b60 _bbStringFind(haystack,needle,from)  -> haystack.Find(needle, from)
'   0x004a6a30 _bbStringCompare(a,b)                -> a = b   (ch = " ")
'   0x004a7ee0 -- NOT in helper_map.tsv. Read directly: `if(len) return buf[0]&0xffff else -1`
'                 == blitz_string.c bbStringAsc EXACTLY (blitz.mod source, line ~333). -> Asc(ch)
'   0x0059c927 _brl_retro_Hex(n)                    -> Hex(n)   (8-digit, zero padded, uppercase)
'   0x0050871e -- NOT in helper_map.tsv. Body is `FUN_0059c927(n); FUN_004a7c90(r, r.Length-2, r.Length)`
'                 i.e. Right(Hex(n), 2) EXACTLY (2 trailing hex digits). Confirmed by disasm.
'   0x004a7c20 _bbStringConcat                      -> String + String (":+")
' Literal strings confirmed via harness.read_string: 0x00C7C540 reserved-char set (see above,
' ends \r\n), 0x00C6EF28 " ", 0x00C79738 "+", 0x00C6EF14 "%20", 0x00C7C578 "%".
'
' STATUS: try_function -> MISMATCH, our_len=361 orig_len=343, first_diff at our-body offset 5
' (right after the prologue). All CONTROL FLOW is structurally confirmed correct: the original
' calls bbStringSlice/Mid(s,i+1,1) SEPARATELY at five distinct call sites (0x5084DD, 0x508500,
' 0x508546, 0x508596, 0x5085D4 in the original) rather than sharing one hoisted temp -- an
' earlier attempt that hoisted `Local ch:String = Mid(...)` once per iteration compiled to a
' SINGLE call site and is provably the wrong shape (297/302 bytes, but wrong AST). The version
' below reproduces all five call sites and gets every branch's helper calls right; the residual
' delta is REGISTER ALLOCATION, not logic.
'
' THE GAP: original spills the reserved-char-set literal (0x00C7C540) to a dedicated stack slot
' ([ebp-8], alongside `n` = s.Length-1 at [ebp-4]; `sub esp,8` = 2 slots), and gives registers to
' s (edi), the loop counter i (esi) and the result accumulator (ebx). Our build instead promotes
' the literal into a register (esi) and only spills `n` (`sub esp,4` = 1 slot) -- i.e. our
' allocator ranks the once-referenced literal ABOVE the loop counter i, which is referenced
' ~8 times (init/compare/increment plus five `i+1` uses). That inversion contradicts
' codegen-patterns.md section 18's own rank rule as I understand it, so either (a) a literal
' string operand used as a `.Find()` RECEIVER is scored differently from a named Local by this
' compiler's allocator (not covered by section 18's probes, which used Int Locals only -- worth
' a probe with a String literal receiver), or (b) the reserved-char set needs to be a genuine
' `Local badChars:String = "..."` declared FIRST (tried: gives 366/343, edi/ebx assignment
' correct but badChars STILL wins a register over `i`, so the extra Local declaration alone
' does not fix it either).
' NEXT PASS: this needs a String-literal-in-a-loop register-allocation probe (analogous to
' section 18.2's Int-Local probe) before spending more time guessing at source shape here; the
' control flow and every helper/literal identification above should not need re-deriving.
'
' Blocks TScreen_WebPage.GetSocialMessage (0x0056142A, 173 bytes, sig (i)$) which calls this
' function as its last statement and returns its result directly (tail call in EAX) -- that
' body cannot MATCH until this one does, since the E8 call-target mask only applies to helpers
' named identically on both sides, which requires this function to compile byte-identically
' first.

Function Fn_005084a8:String(s:String, encodeAll:Int, plusForSpace:Int)
	Local result:String = ""
	Local n:Int = s.Length - 1
	For Local i:Int = 0 To n
		If ("!*'();:@&=+$,/?%#[]~r~n").Find(Mid(s, i + 1, 1)) > -1 Then
			result :+ "%" + Right(Hex(Asc(Mid(s, i + 1, 1))), 2)
		Else If Mid(s, i + 1, 1) = " " Then
			If plusForSpace <> 0 Then
				result :+ "+"
			Else
				result :+ "%20"
			EndIf
		Else If encodeAll <> 0 Then
			result :+ "%" + Right(Hex(Asc(Mid(s, i + 1, 1))), 2)
		Else
			result :+ Mid(s, i + 1, 1)
		EndIf
	Next
	Return result
End Function
