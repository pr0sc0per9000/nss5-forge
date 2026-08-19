' TScreen_Interview.Update -- NOT VERIFIED (LENGTH-EXACT 904/904; 661/904 = 73.1% per current
' byte-identical vs NSS5.exe
' status/score, first diff is a Global-address operand at byte 7, see the re-check note below)
' VA 0x0057B9D9   904 bytes (Ghidra-authoritative)   KIND=Function (static, no Self)   SIG=()i
' vtable slot 0x44
'
' Semantics fully mapped from extracted/decomp_annotated/TScreen_Interview.Update@0057b9d9.c
' plus the raw disassembly (read directly, not trusted from Ghidra's merged argument lists --
' see below). An earlier localise_diff.py verdict: SAME LENGTH, exactly
' 2 bytes differ, ONE location.
'
' RE-CHECK (this pass): current status/score/TScreen_Interview.Update.txt
' now reports 661/904 (73.1%), length delta +0, FIRST DIFFERENCE at byte 7 -- i.e. inside the
' very FIRST instruction of the body, `cmp dword [g_screen_interview_int04],0` (the opcode
' bytes `83 3D` and the trailing `00` compare-immediate all match; only the 4-byte address
' operand differs: original encodes 0x00C6CDF4, ours encodes something else). This is NOT the
' byte-319 operand-order issue described below -- it is strictly earlier and it is an address-
' encoding mismatch, not a shape mismatch (same opcode, same length).
'   Checked whether this is fixable from inside this file: extracted/global_address_map.tsv
'   currently has address="-" tier=AMBIGUOUS ("no alignment forced it") for EVERY Global this
'   function touches except g_iv_screen (STRONG, 0x00C6CDD8) and g_player_int50 (STRONG,
'   0x00C6EFD4) -- g_screen_interview_int04/05/07/02/15/arr, g_iv_beep and g_Object796/859 are
'   all still AMBIGUOUS project-wide (only 1-2 bodies reference each, not enough for the
'   solver to force an address). Cross-checked against unrelated work items' own score files
'   (TBall.CanSeePlayer 91.0% "close", TBall.CheckGoals 84.4% "close", TEngine.GoalScored 5.8%)
'   and ALL of them show the identical signature: the first differing bytes are the 4-byte
'   address operand of an otherwise byte-correct instruction. That rules out a body-local
'   cause -- it is a project-wide global-address-resolution state that a single-file edit
'   cannot move. Names used below are already the exact globals_final.tsv spellings (verified
'   again this pass), so there is nothing to rename either. Leaving this as documented so the
'   next pass does not re-diagnose it from scratch.
'
' STILL OPEN -- 1 location, 2 bytes: the SECOND half of the outer
' `g_player_int50 > g_screen_interview_int05+750 And g_player_int50 < g_screen_interview_int05+1250`
' guard. Original disassembly at ORIGINAL +319:
'     cmp dword ptr [g_player_int50], eax     ; eax = g_screen_interview_int05+1250
'     jle <skip-whole-If>
' Ours emits the operands the other way around:
'     cmp eax, dword ptr [g_screen_interview_int05+1250-computed]   ; eax = g_player_int50
'     jge <skip-whole-If>
' Both are logically "skip when player is NOT < threshold" -- same truth table, different
' physical operand assignment (rule 10.1: comparison operand order is byte-observable). The
' first clause of the And (`player > int05+750`) DOES match byte-for-byte already (confirmed
' via localise_diff, no gap/sub reported for it) using the boolean-materialise pattern
' (setg/movzx/cmp/jz); the SECOND clause of a two-clause And compiles as a DIRECT branch
' (cmp/jcc) with no materialised boolean, per bcc's short-circuit codegen: only the non-final
' member(s) of an And-chain get a stored 0/1 value, the last one branches straight through.
' That structural fact IS reproduced exactly (length match down to the very byte) -- the only
' residual is which side of THIS one cmp is register vs memory.
'
' TRIED THIS PASS, ALL FAILED (either wrong bytes elsewhere or wrong length -- do not retry):
'   * `g_screen_interview_int05 + 1250 > g_player_int50` (LHS/RHS swapped, matching maths) --
'     changes overall length to 902 (breaks something upstream, not just this cmp).
'   * `Not (g_player_int50 >= g_screen_interview_int05 + 1250)` -- 913 bytes, materialises an
'     extra boolean, wrong shape entirely.
'   * `Not (g_screen_interview_int05 + 1250 <= g_player_int50)` -- 911 bytes, same problem.
'   * Nested `If A ... If B ...` in place of the compound `A And B` -- not completed (EndIf
'     bookkeeping got tangled this pass), worth a clean retry: nesting might route clause B
'     through a fresh top-of-block codegen context that picks the operand assignment the
'     compound-And path does not.
' NOT YET TRIED: introducing `Local thr:Int = g_screen_interview_int05 + 1250` ahead of the
'   guard and comparing `g_player_int50 < thr` -- forces the threshold into a Local explicitly
'   rather than an inline sub-expression, which may change which value ends up register-
'   resident by the time this cmp is emitted.
' CROSS-CHECKED THIS PASS against src/recovered/TPlayer.UpdateOffside.bmx (984/984 byte-
'   perfect), which has the exact same shape of guard: `g_player_int50 > Self.offsidetime +
'   2500 And g_player_int50 < Self.offsidetime + 3000`, i.e. `variable > threshold+A And
'   variable < threshold+B`, spelled with NO reversal from the decompiled source order on
'   either clause. Our second clause (`g_screen_interview_int05 + 1250 < g_player_int50`) is
'   already spelled with no reversal, matching that sibling. Our first clause IS reversed
'   (`g_player_int50 > g_screen_interview_int05 + 750` vs decomp's `int05+750 < player`), but
'   an earlier localise_diff run already confirmed that clause matches byte-for-byte as spelled,
'   so it is left alone rather than "corrected" to match the sibling's literal wording --
'   trust the tool-verified result over the surface-syntax analogy.
'
' TWO CONCRETE FIXES APPLIED THIS PASS (both re-derived from sibling precedent, not from the
' byte-7 address issue above, which is out of this file's reach):
'   1. `g_screen_interview_int07 = g_screen_interview_int07 + 1` -> `g_screen_interview_int07
'      :+ 1`. Every other plain "+1 self-increment on a Global Int" in the corpus uses `:+`
'      (e.g. `g_engine_int32 :+ 1` / `g_engine_int18 :+ 1` in TBall.Parry.bmx /
'      TEngine.DoHalfEnds.bmx, both byte-identical bodies) and CreateScreen.bmx's own header
'      documents `:+` vs full reassignment as load-bearing (`add [addr],imm` vs a longer
'      load/add/store). The full-reassignment spelling here was an unjustified outlier.
'   2. `TScreen_Interview.EnableAllButtons()` -> `EnableAllButtons()`. Same-Type Function
'      calls are unqualified throughout the corpus: ButtonAddText.bmx (this same Type) calls
'      `DisableAllButtons()` / `Success()` / `Fail()` bare, and TBlackJack.Update.bmx calls its
'      sibling Function `DealersTurn()` bare. The Type-qualified spelling was an unnecessary
'      deviation from that convention (a static Function call likely lowers to the same call
'      target either way, but there is no reason to keep the non-idiomatic spelling).
'
' Field/Global mapping (all confirmed via extracted/globals_final.tsv + sibling files in this
' same Type -- names reused verbatim from src/recovered/TScreen_Interview.ButtonAddText.bmx
' and .CreateScreen.bmx so the merged module Global set stays single-named per address):
'   0x00C6CDD8 g_iv_screen:TScreen        (CreateScreen.bmx/EnableAllButtons.bmx name;
'                                          DisableAllButtons.bmx uses "g_screen_interview" for
'                                          the SAME address -- a pre-existing corpus naming
'                                          split, not introduced here)
'   0x00C6CDD4 g_iv_beep:TSound           (CreateScreen.bmx name)
'   0x00C6CDE0 g_Object796:TLabel         (ButtonAddText.bmx name, the built-up-sentence label)
'   0x00C6F090 g_Object859:TChannel       (ButtonAddText.bmx name, shared PlaySound channel)
'   0x00C6CDEC g_screen_interview_int02:Int  (ButtonAddText.bmx name, final question index)
'   0x00C6CDF4 g_screen_interview_int04:Int  (ButtonAddText.bmx name, "interview finished" gate)
'   0x00C6CDF8 g_screen_interview_int05:Int  (NEW this pass, "last-transition timestamp",
'                                             2 writes matches globals_final.tsv)
'   0x00C6CE00 g_screen_interview_int07:Int  (ButtonAddText.bmx name, 1-based Q/button index,
'                                             negated on a wrong answer -- matches ButtonAddText)
'   0x00C91B10 g_screen_interview_int15:Int  (NEW this pass, "beep already played" latch)
'   0x00C6CE08 g_screen_interview_arr:Int[]  (ButtonAddText.bmx name+type -- CONFIRMED Int[]
'     again here: the shift-loop copies elements with a bare mov, no refcount traffic, and
'     feeds Abs() directly, contradicting globals_final.tsv's Object[] classification per rule
'     16.7/11.2, same pattern as ButtonAddText and the arr01..32 precedent)
'   0x00C6EFD4 g_player_int50:Int (globals_final.tsv "verified", already used corpus-wide)
'
' Calls: FUN_004A7F60 = Abs(Int) (confirmed in ButtonAddText.bmx's own header, disassembled
' directly: sar edx,31/xor eax,edx/sub eax,edx). Ghidra's printed argument lists for
' FUN_004a7f60 and GetText in the decompiled C are WRONG -- they merge the callee's real
' args with the pushes belonging to the NEXT call in program order (documented at the top of
' the annotated decomp file itself: "GHIDRA'S PRINTED ARGUMENT LIST IS NOT EVIDENCE"). The
' `add esp,N` CALL header lines are what is trustworthy: FUN_004a7f60 takes exactly 1 arg (32
' sites agree), GetText exactly 1 arg (1831 sites agree) -- both consistent with Abs(Int):Int
' and GetText(key$):String, and the extra printed args belong to the following
' _bbObjectDowncast / TGadget.SetText calls respectively.
' TScreen.GetGadgetByName($):TGadget = slot 0x90 (confirmed in vtable_map.tsv).
' TGadget.SetColour($,$)i = slot 0x6c, TGadget.SetText($,$,i,i)i = slot 0x64 (both confirmed
' in vtable_map.tsv, inherited by TButton/TLabel respectively -- same slots ButtonAddText.bmx
' already established for g_Object108:TGadget/g_Object796:TLabel).
' TScreenMessage.Count()i = Function, slot 0x34 (vtable_map.tsv).
' TScreen_Interview.EnableAllButtons()i = Function, slot 0x3c, this Type's own (already
' recovered separately in src/recovered/TScreen_Interview.EnableAllButtons.bmx).
'
' `-g_screen_interview_int07 - 1` (not `-1 - g_screen_interview_int07`, which is mathematically
' identical but costs +1 byte twice: original computes it as `eax=int07; neg eax; sub eax,1`,
' i.e. `-(int07) - 1`; the `-1-x` spelling instead loads the -1 immediate then subtracts a
' memory operand, one byte longer both times it appears). Confirmed this pass by direct A/B.
'
' The outer `750`/`1250` window bounds are `0x2ee`/`0x4e2` read straight from the immediates.
' The `And TScreenMessage.Count() = 0` clause is genuinely short-circuit: original computes
' `g_screen_interview_int07 < 0` into a materialised boolean FIRST (setl/movzx), and only CALLS
' Count() when that boolean is true, re-using the same eax slot for the final `= 0` test -- a
' single compound `If A And B` reproduces this exactly (do NOT split into a separate `Local
' done:Int` + two `If` statements; that costs 5 extra bytes, tried and reverted this pass).
'
' Literal CONTENT ("btn_", "0000FF", "00FF00", "FFFFFF", "Go!") is not certified by a length-
' only comparison; not yet re-read from the exe this pass (see codegen-patterns.md 13.2)
' pending a full MATCH -- do that before promoting.
'
' Body-only format: statements only (KIND=Function, no Self, no parameters).
'!Global g_screen_interview_int04:Int
'!Global g_screen_interview_int05:Int
'!Global g_screen_interview_int07:Int
'!Global g_screen_interview_int02:Int
'!Global g_screen_interview_int15:Int
'!Global g_screen_interview_arr:Int[]
'!Global g_iv_screen:TScreen
'!Global g_iv_beep:TSound
'!Global g_Object796:TLabel
'!Global g_Object859:TChannel
'!Global g_player_int50:Int
If g_screen_interview_int04 = 0
	If g_player_int50 > g_screen_interview_int05 + 750 And g_player_int50 < g_screen_interview_int05 + 1250
		If g_screen_interview_int15 = 0
			PlaySound(g_iv_beep, g_Object859)
			g_screen_interview_int15 = 1
			Local btn:TButton = TButton(g_iv_screen.GetGadgetByName("btn_" + String(Abs(g_screen_interview_arr[g_screen_interview_int07 - 1]))))
			If g_screen_interview_arr[g_screen_interview_int07 - 1] < 0
				btn.SetColour("0000FF", "FFFFFF")
			Else
				btn.SetColour("00FF00", "FFFFFF")
			EndIf
			If g_screen_interview_int07 = 1
				g_Object796.SetText("", "", -1, -1)
			EndIf
		EndIf
	Else If g_player_int50 > g_screen_interview_int05 + 1250
		g_screen_interview_int15 = 0
		Local btn:TButton = TButton(g_iv_screen.GetGadgetByName("btn_" + String(Abs(g_screen_interview_arr[g_screen_interview_int07 - 1]))))
		btn.SetColour("FFFFFF", "FFFFFF")
		g_screen_interview_int05 = g_player_int50
		If g_screen_interview_arr[g_screen_interview_int07 - 1] < 0
			For Local i:Int = g_screen_interview_int07 - 1 To g_screen_interview_arr.Length - 2
				g_screen_interview_arr[i] = g_screen_interview_arr[i + 1]
			Next
		Else
			g_screen_interview_int07 :+ 1
		EndIf
		If g_screen_interview_int07 > g_screen_interview_int02
			g_Object796.SetText(GetText("Go!"), "", -1, -1)
			g_screen_interview_int07 = 1
			g_screen_interview_int04 = 1
			EnableAllButtons()
		EndIf
	EndIf
Else
	If g_screen_interview_int07 < 0 And TScreenMessage.Count() = 0
		If g_player_int50 Mod 1000 < 500
			Local btn:TButton = TButton(g_iv_screen.GetGadgetByName("btn_" + String(Abs(g_screen_interview_arr[-g_screen_interview_int07 - 1]))))
			btn.SetColour("FFFFFF", "FFFFFF")
		Else
			Local btn:TButton = TButton(g_iv_screen.GetGadgetByName("btn_" + String(Abs(g_screen_interview_arr[-g_screen_interview_int07 - 1]))))
			btn.SetColour("00FF00", "FFFFFF")
		EndIf
	EndIf
EndIf
Return 0
