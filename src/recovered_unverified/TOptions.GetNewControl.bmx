' TOptions.GetNewControl -- NOT VERIFIED (near miss, 703 of 705 bytes, delta -2, COMPLETE)
' byte-identical vs NSS5.exe
' VA 0x004E2C3A   705 bytes (Ghidra-authoritative)   KIND=Function (static, no Self)   SIG=()i
' vtable slot 0x3c
'
' GAP A (the outer test) is CLOSED. It was not a source-spelling
' question at all -- it was a REGISTER-REUSE question, same family as section 22. Original
' loads `g_options_int01` into eax ONCE via `Local mode:Int = g_options_int01` / `If mode <>
' 0`, i.e. the OUTER test reads the Global through a Local, while the LATER, INNER test
' (`If g_options_int01 = 2 Then usejoybutton = 1`) reads the bare Global directly (a straight
' `cmp dword [addr],N`). Confirmed by the byte shapes: the outer test is `mov eax,[addr] /
' cmp eax,0` (8 bytes, register-mediated) and the inner one is `cmp dword [addr],2` (7 bytes,
' direct memory compare) -- and per full original disassembly the Local's register (eax) is
' NEVER reused afterward (the inner test reloads the Global fresh), so this was purely a
' codegen-shape choice, not a live-value-reuse optimisation. Using a `Local` for the OUTER
' occurrence only closed the -1 byte gap with zero effect elsewhere. 705 -> our 702 -> 703.
'
' STILL OPEN -- 1 gap, -2 bytes (GAP B only, unchanged from before, see below).
'
' localise_diff.py verdict: delta_accounted -3 of -3 == COMPLETE, only 2 gaps remain, both
' pure control-flow byte artifacts -- every field/Global/call in the body is correctly named
' and the whole control-flow SHAPE (branch polarity, loop bounds, float-comparison form) is
' proven right, because fixing each of these closed a much bigger gap first (see history below).
'
' RESOLVED DURING THIS PASS (do not re-derive):
'   * The If/Else is `If g_options_int01 <> 0 Then <JOYSTICK> Else <KEYBOARD> EndIf` -- NOT
'     `If g_options_int01 = 0 Then <KEYBOARD> Else <JOYSTICK>` as Ghidra's annotated C
'     suggests. Raw disasm: `cmp eax,0 / je 0x4e2e44`, and 0x4e2e44 is the KEYBOARD prompt +
'     capture loop, physically relocated to the END of the function (reached only by this
'     jump and by nothing else) while the JOYSTICK body is inline right after the test. That
'     is the standard "Then inline, Else out-of-line" shape for `If cond Then A Else B`, so
'     cond = `g_options_int01 <> 0` and A = JOYSTICK, B = KEYBOARD. Getting this backwards
'     (as the first draft did, following Ghidra literally) cost two ~144-byte gaps.
'   * `usejoybutton` is `Local usejoybutton:Int = 0 / If g_options_int01 = 2 Then
'     usejoybutton = 1` (an If-STATEMENT, matching TOptions.WaitForJoyRelease.bmx's `port`
'     exactly) -- NOT `Local usejoybutton:Int = (g_options_int01 = 2)` (a SETcc expression).
'     Both compute the same value but emit different bytes; the statement form is confirmed
'     by original bytes `mov esi,0 / cmp [g],2 / jne +5 / mov esi,1` (conditional-move-style),
'     not a `sete`/`movzx` pair.
'   * Each JoyX()/JoyY() axis-boundary check assigns its call result to a Float Local first
'     (`Local jx:Float = JoyX(usejoybutton)` then `If jx < -0.4 ... `, then `jx =
'     JoyX(usejoybutton)` again for the second check) rather than comparing the call result
'     inline. Inlined, bcc emits an extra memory round-trip (`fld const / fstp [temp] / ...
'     / fld [temp] / fucompp`, +9 bytes per site); through the Float Local it emits the
'     original's shorter `fld const / <call> / fxch st(1) / fucompp`. This is the Float-local
'     x87-residency rule (codegen-patterns 6/10.5) applied to a comparison operand, not just
'     a return expression.
'   * The final loop condition is `Until MilliSecs() > starttime + 3000` (MilliSecs() as the
'     LEFT operand) -- matches original's `call MilliSecs -> eax; edx = starttime+3000; cmp
'     eax,edx`, i.e. eax(MilliSecs) compared against edx(starttime+3000) in that order.
'
'   GAP B (-2 bytes, ORIGINAL +656): right after the keyboard capture `For...Next` loop's
'     `jle <loopback>`, original emits an extra 2-byte `jmp` to the address immediately
'     following it (a jump-to-next-instruction, EB 00) before falling into the shared
'     `Flip(-1)` tail. Our build's loop falls through directly with no such jump.
'
'   FULL-FUNCTION original disassembly read this pass (0x4E2C3A..0x4E2EF2) shows this is NOT
'   an isolated artifact: the JOYSTICK (Then) branch closes with an explicit LONG jump
'   `E9 88 00 00 00  jmp 0x4e2ecc` (skipping over the whole out-of-line KEYBOARD block to
'   reach the shared tail), and the KEYBOARD (Else) branch -- despite being placed physically
'   LAST, immediately before that same tail -- ALSO closes with an explicit jump to the exact
'   same target, `EB 00  jmp 0x4e2ecc`, which is degenerate only because the target happens to
'   equal the very next address. So bcc emits an unconditional "jmp JOIN" at the end of BOTH
'   If/Else branches unconditionally, never eliding it even when the branch is already
'   physically adjacent to JOIN. Our build's Then branch DOES reproduce this (confirmed by
'   reading our own probe.exe: `E9 86 00 00 00` immediately before the KEYBOARD block, same
'   shape as original's `E9 88...`) but our Else branch's `Next` falls straight into `push -1`
'   with NO trailing jmp at all -- not a shorter jmp, an ABSENT one. This is a genuine
'   asymmetry between the two branches' closing codegen that untouched-content permutation did
'   not explain.
'   TRIED THIS PASS, NO EFFECT: `Next i` (explicit loop-variable name) -- FAILS TO COMPILE
'     under NG/SuperStrict ("Identifier 'i' not found" -- `i` is out of scope by `Next`'s
'     position under BlitzMax NG's block scoping, even though legacy BlitzMax accepts named
'     `Next`). Do not retry this spelling; NG rejects it outright, it is not just byte-neutral.
'   NOT YET TRIED: checking whether the Then branch in a MINIMAL two-statement-body If/Else
'     (no loop at all) still gets a trailing jmp on both sides on a fresh probe, to isolate
'     whether the double-jmp is a property of If/Else generally (source-form-independent,
'     meaning something about OUR Else's specific trailing statement suppresses it) or
'     specific to this body's shape.
'
' RE-VERIFICATION PASS (refine.json item 42): re-ran scripts/localise_diff.py against this
'   exact file. Confirms the header's numbers are current, not stale: verdict "1
'   length-changing gap(s), -2 bytes total", delta_accounted -2 of -2 == COMPLETE, ZERO
'   `subs` (no wrong callee/global/immediate anywhere), naming=full (every E8 in the body
'   masks by name, so nothing is hiding behind an unresolved call). The status/score/*.txt
'   report's "byte agreement 73.1%, first difference at byte 10" is NOT a statement-level
'   problem in this file -- localise_diff's tolerant alignment (which blanks in-image
'   absolute/relative operands before comparing) shows the raw score is measuring
'   whole-binary call-target/global-address cascade noise from OTHER not-yet-fixed bodies
'   elsewhere in the program, not anything wrong here. GAP B is the only real finding.
'   TRIED THIS PASS, NO EFFECT: rewrote the keyboard capture loop as `Local i:Int = 0 /
'     While i <= 255 ... i :+ 1 / Wend` in place of `For Local i:Int = 0 To 255 ... Next`.
'     Produced byte-IDENTICAL probe output to the For/Next version (same single GAP B, same
'     size, same disassembly) -- the loop-exit shape (inc/cmp/jle then a degenerate
'     jmp-to-fallthrough that ours elides and original keeps) is unaffected by For vs While.
'     This is evidence GAP B is a backend peephole difference (dead/degenerate
'     jmp-to-next-instruction elimination) between the original's legacy-BlitzMax bcc and
'     whatever toolchain builds our probes, not a source-spelling question -- consistent
'     with codegen-patterns.md having no documented lever for it. Reverted to For/Next,
'     which also matches the sibling TOptions.WaitForJoyRelease.bmx's established idiom for
'     an identical `0 To 255` KeyDown-scan loop. NO SOURCE CHANGE MADE this pass -- the body
'     was already the closest reachable reconstruction; see RULE 4.
'
' Globals (names ours, types load-bearing):
'   0x00C6EFE4 g_engine_int162:Int   0x00C6EFE8 g_engine_int163:Int  -- screen center*2 (see
'     TScreen.GetInput.bmx, same pair, same file's globals_final.tsv rows)
'   0x00C6EFEC g_engine_int164:Int  -- "joystick enabled" gate (JoyCount() result)
'   0x00C5D1A8 g_options_int01:Int  -- joystick device selector (0/1/2), same address as
'     TOptions.WaitForJoyRelease.bmx's `g_joyport` and TScreen.GetInput.bmx's g_options_int01
'   0x00C61714 g_Object102:TImage  -- control-screen background image, typed by the
'     DrawImageRect construction site (first param is TImage); globals_final.tsv only had
'     "Object, low confidence, init=bbNullObject"
'   0x00C61724 g_screen_float01:Float, 0x00C61728 g_screen_float02:Float  -- DrawImageRect
'     x/y, same pair TScreen.Draw.bmx uses for SetOrigin
'   0x00C6EFDC g_screen_int21:Int, 0x00C6EFE0 g_screen_int22:Int  -- DrawImageRect w/h,
'     cast to Float at the call (read-only ints per globals_final.tsv)
'
' Calls: FUN_005ad32d = Cls() (confirmed in TScreen.DoMessageGetText.bmx), FUN_004a4860 =
' MilliSecs() (confirmed in TEngine.PauseEngine.bmx/TEngine.MatchLoop.bmx), FUN_005b4721 =
' KeyDown (the KeyDown|MouseDown alias set, chosen KeyDown per the 256-iteration range and
' per TOptions.WaitForJoyRelease.bmx's own established choice for this exact VA).
'
' Body-only format: statements only, no parameters (KIND=Function, no Self).
'!Global g_engine_int162:Int
'!Global g_engine_int163:Int
'!Global g_engine_int164:Int
'!Global g_options_int01:Int
'!Global g_Object102:TImage
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_screen_int21:Int
'!Global g_screen_int22:Int
g_engine_int164 = JoyCount()
WaitForJoyRelease()
Local starttime:Int = MilliSecs()
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
Repeat
	Cls()
	SetOrigin(0, 0)
	TScreen.RenderBorder()
	DrawImageRect(g_Object102, g_screen_float01, g_screen_float02, Float(g_screen_int21), Float(g_screen_int22), 0)
	Local mode:Int = g_options_int01
	Select mode
	Case 0
		TEngine.DrawMyText(GetText("CMESSAGE_GETKEY"), g_engine_int162 / 2, g_engine_int163 / 2, 1, 1, 1.0, 1.0, "FFFFFF", 0)
		For Local i:Int = 0 To 255
			If KeyDown(i)
				WaitForJoyRelease()
				Return i
			EndIf
		Next
	Default
		TEngine.DrawMyText(GetText("CMESSAGE_GETJOY"), g_engine_int162 / 2, g_engine_int163 / 2, 1, 1, 1.0, 1.0, "FFFFFF", 0)
		If g_engine_int164 <> 0
			Local usejoybutton:Int = 0
			If g_options_int01 = 2 Then usejoybutton = 1
			For Local i:Int = 0 Until 15
				If JoyDown(i, usejoybutton)
					WaitForJoyRelease()
					Return i
				EndIf
			Next
			Local jx:Float = JoyX(usejoybutton)
			If jx < -0.4
				FlushAllInput()
				Return -1
			EndIf
			jx = JoyX(usejoybutton)
			If jx > 0.4
				FlushAllInput()
				Return -2
			EndIf
			Local jy:Float = JoyY(usejoybutton)
			If jy < -0.4
				FlushAllInput()
				Return -3
			EndIf
			jy = JoyY(usejoybutton)
			If jy > 0.4
				FlushAllInput()
				Return -4
			EndIf
		EndIf
	End Select
	Flip(-1)
Until MilliSecs() > starttime + 3000
