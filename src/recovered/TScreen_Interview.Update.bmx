' TScreen_Interview.Update -- byte-identical vs NSS5.exe
' VA 0x0057B9D9   904 bytes (Ghidra-authoritative)   KIND=Function (static, no Self)   SIG=()i
' vtable slot 0x44
'
' Semantics fully mapped from extracted/decomp_annotated/TScreen_Interview.Update@0057b9d9.c
' plus the raw disassembly (read directly, not trusted from Ghidra's merged argument lists --
' see below). (An earlier localise_diff.py verdict of "SAME LENGTH, exactly 2 bytes differ,
' ONE location" is superseded -- see the verification block: there is no residual.)
'
' VERIFIED 2026-08-23, three checks, NSS5_NO_LEARN=1 in the environment for all three:
'   1. PER-FUNCTION ORACLE. harness.try_method("TScreen_Interview","Update", body) ->
'      status=MATCH mode=reloc matched=904 total=904 reloc_masked=86
'      orig_len=904 our_len=904 orig_len_from=ghidra orig_va=0x0057B9D9.
'   2. COMPOSITION. scripts/assemble.py rebuilt src/assembled/nss5_assembled.exe in an
'      isolated worktree, then check_assembled.py's comparator (harness.compare, the
'      assembled-side symbol tables, learn=None) over this VA:
'          identical modulo reloc : 1     DIVERGED after assembly : 0
'      so the body survives the whole-program facts -- vtable slot order, Global types,
'      Type declaration order -- unchanged.
'   3. LITERAL CONTENT, which a byte MATCH does NOT certify (the oracle masks the
'      BBString address a literal reaches the code as). scripts/check_literals.py
'      --files <this file> -> OK, 0 mismatches, against the exe's own decoded BBStrings.
'      That closes the "not certified by a length-only comparison" caveat below.
'
' PROMOTED to src/recovered/ in this pass. Promotion moves the body's position in the
' emitted source, and Type declaration order is a whole-program property, so it was
' re-verified AFTER the move, not before: assemble.py rebuilt, then check_assembled.py
' over this VA (identical modulo reloc, 0 diverged) and over its own standard 80-body
' sample (9 exact / 71 reloc / 0 diverged / 0 unlocatable).
'
' WHAT THE OLD HEADER SAID AND WHY IT WAS WRONG. The previous claim block reported
' "661/904 (73.1%), FIRST DIFFERENCE at byte 7" and diagnosed a Global-address defect --
' the first instruction, `cmp dword [g_screen_interview_int04],0`, encodes 0x00C6CDF4 in
' NSS5.exe and a different address in our image. Both observations are true and neither
' is a defect. status/score/*.txt is written by reverify.py, which compares POSITIONALLY
' and RAW; its own docstring says the number is a triage signal and not a fidelity
' measure. A Global reference is a link-time relocation, so two independently-linked
' images can never agree on that operand, and harness.compare masks it by design
' (docs/specs/21-module-globals.md 8.1). Byte 7 is simply where the body's first
' relocation lands. The same signature in TBall.CanSeePlayer (91.0%) and
' TBall.CheckGoals (84.4%), cited in the old block as corroboration, is the same
' instrument artefact -- CanSeePlayer is recorded elsewhere in this corpus as clean.
' Nothing about the score file was fixable from inside this file because there was
' nothing to fix.
'
' THE OLD "STILL OPEN -- 1 location, 2 bytes" ITEM IS CLOSED, and it was never open:
' the operand-order reading of the `And`'s second clause came from the same raw-diff
' desynchronisation. The body as written below is what the oracle certifies at 904/904.
' The failed experiments recorded under it are kept because they are still true as
' NEGATIVE results -- each of those spellings really does change the emitted length --
' and they are the reason the current spelling is the right one. Do not re-run them.
'
' NEGATIVE RESULTS (kept as evidence, not as open work). These concern the SECOND half of
' `g_player_int50 > g_screen_interview_int05+750 And g_player_int50 < g_screen_interview_int05+1250`.
' The original at +319 is
'     cmp dword ptr [g_player_int50], eax     ; eax = g_screen_interview_int05+1250
'     jle <skip-whole-If>
' and the previous pass believed our side emitted the operands reversed. IT DOES NOT -- that
' reading came from the desynchronised raw diff; the oracle certifies this instruction along
' with the other 903 bytes. What survives from that pass is the measured cost of the
' alternative spellings, which is real and is why the current spelling stands:
' The codegen fact that makes the current spelling correct, and which the byte MATCH now
' confirms: in a two-clause `And`, only the NON-FINAL member gets a materialised 0/1
' (setg/movzx/cmp/jz -- that is the first clause, `player > int05+750`); the LAST member
' compiles as a direct cmp/jcc with no stored boolean. Both halves are reproduced exactly.
'
' TRIED AND FAILED IN AN EARLIER PASS (wrong bytes elsewhere, or wrong length -- do not retry):
'   * `g_screen_interview_int05 + 1250 > g_player_int50` (LHS/RHS swapped, matching maths) --
'     changes overall length to 902 (breaks something upstream, not just this cmp).
'   * `Not (g_player_int50 >= g_screen_interview_int05 + 1250)` -- 913 bytes, materialises an
'     extra boolean, wrong shape entirely.
'   * `Not (g_screen_interview_int05 + 1250 <= g_player_int50)` -- 911 bytes, same problem.
'   * Nested `If A ... If B ...` in place of the compound `A And B` -- not completed (EndIf
'     bookkeeping got tangled), abandoned -- and moot: the compound `And` matches as
'     written, so there is nothing for a different nesting to fix.
' CROSS-CHECKED against src/recovered/TPlayer.UpdateOffside.bmx (984/984 byte-
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
' TWO SPELLING FIXES FROM AN EARLIER PASS, both re-derived from sibling precedent and both
' part of the body that now matches:
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
' Literal CONTENT ("btn_", "0000FF", "00FF00", "FFFFFF", "Go!") is now certified: read back
' from NSS5.exe's own BBStrings by scripts/check_literals.py, OK (check 3 above).
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
