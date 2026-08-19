' TInputBox.Update  VA 0x005158D7   orig_len=699   vtable slot 0x34   sig ()i
' VA 0x005158d7   699 bytes   vtable slot 0x34   sig ()i
' An earlier draft wrote the semantics but declined to emit code at all,
' blocked on FUN_0058D81A (see below); the file was 100% comments, scoring ~21% by pure
' prologue/epilogue coincidence (our_len was 14 bytes -- an empty "Return 0" stub).
'
' REWRITTEN this pass from a full raw-disassembly trace (harness.disasm_original over the
' whole 0x005158D7..0x00515B91 range), not just the Ghidra decompile, which mis-renders
' several joins here as separate returns. Two concrete corrections vs the prior draft's
' (never-compiled) candidate text, both confirmed by literal jump-target reuse in the
' original bytes:
'
'  1. TAB (c=9): NOT two independent "test, early-return" ifs. The fRet-taken path ends in
'     a 2-byte short `jmp` into the SAME 7-byte "mov eax,0/jmp epilogue" stub that the
'     TabToGadget() path also falls into -- one shared Return 0, i.e. `If fRet ... Else
'     g_activeScreen.TabToGadget() ... EndIf` / `Return 0`, not `If fRet Then fRet();
'     Return 0; EndIf` followed by an unconditional TabToGadget() call.
'  2. The trailing mouse/joystick confirm block. The prior draft nested it inside `If Not
'     MouseHit(1)`, which would SUPPRESS the confirm action on a mouse click -- wrong: the
'     original reuses EAX as one running truthy value across MouseHit(1), the
'     g_engine_int164 gate and all three JoyHit()s (`jne 0x515b4c` straight from the
'     MouseHit test, landing on the very cmp that also gates the JoyHit chain), exactly
'     the short-circuit-Or-of-an-And idiom already established byte-identical in
'     src/recovered_pending/TEngine.CheckInput.bmx (`KeyHit(x[0]) Or (g_engine_int164<>0
'     And JoyHit(x[1],joynum))`), generalised here to three JoyHit()s Or'd inside the And.
'     A mouse click now correctly reaches the confirm action regardless of the joystick
'     gate. Also: the confirm block ends in its own dedicated Return 0 (a second, separate
'     7-byte stub distinct from the one the outer guard's false path shares with this
'     block's false path) -- added, the prior draft's text had none.
'  3. Outer guard is three separate statements, not one `And`-chained If: `If hidden Then
'     Return 0` / `If Not alive Then Return 0` (bare truthy tests -- each produces its own
'     "dead" mov eax,0/jmp pair, exactly the form src/recovered/TButton.Update.bmx uses
'     byte-identical, 131/131, for this identical hidden/alive pair) / `If gettinginput
'     ... EndIf` wrapping the rest of the method, with the method's single trailing
'     `Return 0` shared between this If's false path and the confirm block's false path
'     (both literally jump to the same address in the original).
' Character-loop section (GetChar/ESC/Enter/backspace/append, ElseIf-not-Select per the
' original's plain sequential cmp/je chain) is unchanged from the prior draft and is now
' confirmed correct statement-by-statement against the raw disassembly.
'
' Fields (offsets confirmed against the decompile, matching TGadget/TInputBox precedent):
'   TGadget: txt+0x10, alive+0x38, hidden+0x3c, w+0x2c (Float)
'   TInputBox: limitchars+0x5c, gettinginput+0x60, fRet+0x64 (()i callback, tested bare
'     against the null-function stub, same idiom as g_selgadget.fHit in
'     src/recovered/TScreen.CheckInput.bmx)
' Globals (scripts/explain_global.py; names match the established sibling that already
' declares each address for this exact use):
'   g_activeScreen:TScreen @0x00C61700 (src/recovered/TScreen.TabToGadget.bmx, same
'     TabToGadget() call site)
'   g_sndclick:TSound @0x00C6171C, g_chanclick:TChannel @0x00C6F088
'     (src/recovered/TScreen.CheckInput.bmx, same PlaySound(sound,channel) call shape)
'   g_options_int01:Int @0x00C5D1A8, g_options_arr06/07/08:Int[] @0x00C5D1D4/DC/E4,
'     g_engine_int164:Int @0x00C6EFEC (all established in src/recovered/TScreen.GetInput.bmx
'     and src/recovered_pending/TEngine.CheckInput.bmx for this identical joystick idiom)
' KeyDown(162)=KEY_LCONTROL, KeyDown(86)=KEY_V -- same idiom/shape as
'   src/recovered/TScreen_MainMenu.NewGame.bmx's `KeyDown(162) And KeyDown(69)`, confirmed
'   here too via the EAX-reuse trick (KeyDown(86) is only reached, and its own test reused,
'   when KeyDown(162) was true; when false EAX is already 0 so the shared `cmp eax,0`
'   short-circuits the second KeyDown call away).
'
' REMAINING GAP -- FUN_0058D81A (Ctrl+V paste): the guard `If KeyDown(162) And
' KeyDown(86)` is real and reproduced (confirmed 3-argument cdecl call to FUN_0058D81A
' folded into the following SetText's stack cleanup: `add esp,0x14` = 12 bytes for
' FUN_0058D81A's own ("",-1,-1) args + 8 bytes for SetText(Self,result), so
' `SetText(FUN_0058D81A("", -1, -1))`). FUN_0058D81A itself (83 bytes, 1 caller -- this
' site) is UNRECOVERED and unexported: it calls OpenClipboard/IsClipboardFormatAvailable/
' GetClipboardData/GlobalLock/GlobalUnlock/CloseClipboard, none of which route through any
' named BRL/MaxGUI wrapper in this corpus. No
' name exists anywhere in the corpus to call, and codegen-patterns.md #13.3 forbids
' stubbing a module Function locally just to give this caller something to call (that
' would mask FUN_0058D81A's own separate, still-open work item, U015). Left as a genuine
' no-op inside the (real, byte-matching) guard rather than inventing an uncompilable or
' fake callee; this is the one deliberate behavioural gap in this body.

If hidden Then Return 0
If Not alive Then Return 0
If gettinginput
	Local c:Int
	Repeat
		c = GetChar()
		If c = 27
			gettinginput = 0
			FlushAllInput()
			If fRet Then fRet()
			Return 0
		EndIf
		If c = 13
			gettinginput = 0
			FlushAllInput()
			If fRet Then fRet()
			Return 0
		EndIf
		If c = 9
			gettinginput = 0
			FlushAllInput()
			If fRet
				fRet()
			Else
				g_activeScreen.TabToGadget()
			EndIf
			Return 0
		EndIf
		If c = 8
			If txt.Length > 0
				txt = txt[..txt.Length - 1]
			EndIf
		ElseIf c <> 0
			If limitchars < 1
				If Float(TextWidth(txt)) < w - 40.0
					txt = txt + Chr(c)
				EndIf
			Else
				If limitchars <= txt.Length Then Return 0
				txt = txt + Chr(c)
			EndIf
		EndIf
	Until c = 0
	If KeyDown(162) And KeyDown(86)
		' FUN_0058D81A (clipboard-paste helper) is unrecovered -- see header. No-op here.
	EndIf
	Local joynum:Int = g_options_int01 = 2
	If MouseHit(1) Or (g_engine_int164 <> 0 And (JoyHit(g_options_arr06[1], joynum) Or JoyHit(g_options_arr07[1], joynum) Or JoyHit(g_options_arr08[1], joynum)))
		gettinginput = 0
		FlushAllInput()
		PlaySound(g_sndclick, g_chanclick)
		If fRet Then fRet()
		Return 0
	EndIf
EndIf
Return 0
