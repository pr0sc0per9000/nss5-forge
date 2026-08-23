' TScreen_Interview.ButtonAddText
' VA 0x0057B640   678 bytes   KIND=Function (static, no implicit Self), SIG=()i, slot 0x38
' byte-identical vs NSS5.exe (678/678, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=73). Verified under NSS5_NO_LEARN=1.
'
' This is the interview mini-game's answer handler: the player clicked a numbered button
' ("btn_N"); check whether N equals the current word's slot index into the answer array.
'
' ASSUMPTIONS
'  * g_Object108:TGadget is the shared "currently active gadget" Global (0x00C61CF8, the
'    same address used throughout the corpus -- see TButton.Draw, TScreen.TextEntered).
'    +0x44 = alph (Float), +0x10 = txt$ -- both TGadget fields; SetAlph is TGadget+0x70
'    (abstract on TGadget itself, resolved virtually through the real subtype), SetColour is
'    TGadget+0x6c.
'  * g_screen_interview_arr (0x00C6CE08) is catalogued Object[] in globals_final.tsv but the
'    element here feeds straight into Abs() then String() with no downcast -- direct evidence
'    (rule 11.2/16.7) it is Int[], not Object[].
'  * g_screen_interview_int02/04/07 (0x00C6CDEC/F4/00) are plain Ints: int04 gates the whole
'    function, int07 is the 1-based question/button index (incremented on a correct answer,
'    negated on a wrong one), int02 is the final question index (Success() fires when
'    int07 reaches it).
'  * g_screen_interview_int06 (0x00C6CDFC) is the accumulated answer-text String (full
'    retain/release traffic in the decompilation).
'  * g_Object727/770 (0x00C6B850/0x00C6C550) are the wrong/right-answer TSound Globals (same
'    addresses as TScreen_Interview.Fail's g_interview_failsound and the Success sound);
'    g_Object859 (0x00C6F090) is the shared TChannel. g_Object796 (0x00C6CDE0) is the
'    TLabel that displays the built-up sentence (same address as CreateScreen's g_iv_label).
'  * TGadget.GetActiveGadgetName() is the recovered Function in
'    src/recovered/TGadget.GetActiveGadgetName.bmx (class-table slot 0x7c); FUN_004a7f60 is
'    Abs(Int) (disassembled directly: `sar edx,31 / xor eax,edx / sub eax,edx`).
'  * Both guards are bcc's early-return idiom (cmp/jne-skip, mov eax,0/jmp end), not nested
'    If-blocks -- confirmed by byte length (nesting cost +4 and +6 bytes respectively).
'  * `TGadget.GetActiveGadgetName().Replace("btn_","").Compare(String(Abs(...)))` must stay
'    ONE expression with no intermediate Locals: the original pushes the String(Abs(...))
'    result straight onto the stack (`50 push eax`) and leaves it live across the
'    GetActiveGadgetName/Replace calls rather than spilling it to a named Local -- an
'    explicit `Local numstr:String = ...` cost 2 extra bytes (mov ebx,eax + push ebx).
'!Global g_screen_interview_int04:Int
'!Global g_screen_interview_int07:Int
' g_screen_interview_int02's original data-section value is 3 (read from NSS5.exe
' at 0x00C6CDEC -- codegen-patterns 21.1/21.3).
'!Global g_screen_interview_int02:Int = 3
'!Global g_screen_interview_int06:String
'!Global g_screen_interview_arr:Int[]
'!Global g_Object108:TGadget
'!Global g_Object727:TSound
'!Global g_Object770:TSound
'!Global g_Object796:TLabel
'!Global g_Object859:TChannel
' CASE DIRECTION CORRECTED 2026-08-22: 2 call sites -> .ToLower().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
If g_screen_interview_int04 = 0 Then Return 0
If g_screen_interview_int07 > 5 Or g_Object108.alph < 1.0 Then Return 0
g_Object108.SetAlph(0.5)
If TGadget.GetActiveGadgetName().Replace("btn_","").Compare(String(Abs(g_screen_interview_arr[g_screen_interview_int07-1]))) = 0
	g_Object108.SetColour("00FF00","FFFFFF")
	PlaySound(g_Object770,g_Object859)
	If g_screen_interview_int07 = 1
		g_screen_interview_int06 = g_screen_interview_int06 + g_Object108.txt
	Else If g_screen_interview_int07 = g_screen_interview_int02
		g_screen_interview_int06 = g_screen_interview_int06 + (", " + g_Object108.txt.ToLower() + ".")
		DisableAllButtons()
		Success()
	Else
		g_screen_interview_int06 = g_screen_interview_int06 + (", " + g_Object108.txt.ToLower())
	End If
	g_Object796.SetText(g_screen_interview_int06,"",-1,-1)
	g_screen_interview_int07 = g_screen_interview_int07 + 1
Else
	g_Object108.SetColour("FF0000","FFFFFF")
	PlaySound(g_Object727,g_Object859)
	g_screen_interview_int06 = g_screen_interview_int06 + "..."
	g_Object796.SetText(g_screen_interview_int06,"",-1,-1)
	DisableAllButtons()
	g_screen_interview_int07 = -g_screen_interview_int07
	Fail()
End If
