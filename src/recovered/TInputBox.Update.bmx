' TInputBox.Update  -- KIND=Method, vtable slot 0x34
' VA 0x005158d7   699 bytes   sig ()i
' byte-identical vs NSS5.exe (699/699, mode=reloc, reloc_masked=36), verified with
' harness.try_method under NSS5_NO_LEARN=1.
'
' GAME BEHAVIOUR: while an input box has focus, ESC and ENTER both close it and fire its
' callback; TAB closes it and fires the callback, or advances focus to the next gadget
' when there is no callback; BACKSPACE trims one character. Any other character is
' appended, but only if either the box has a character limit and is still under it (at
' the limit the keystroke is dropped and the method returns immediately), or it has no
' limit and the rendered text is still narrower than the box width minus 40 pixels.
' Ctrl+V pastes the clipboard over the whole contents (calls the module Function
' GetClipboardText, src/recovered_module/Fn_0058D81A.GetClipboardText.bmx). A left
' click, or any of the three configured joystick confirm buttons when a joystick is
' enabled, closes the box with the click sound.
'
' STRUCTURE NOTES
' 1. The character dispatch is a SELECT, not If/ElseIf (codegen-patterns 10.2): the
'    original emits the four character tests as one grouped chain
'    (`mov eax,edi / cmp eax,0x1b / je ... / cmp eax,0xd / je ... / cmp eax,9 / je ... /
'    cmp eax,8 / je ...`), with bcc placing the Default body FIRST (immediately after the
'    test chain, ending in a jmp to End Select) and every Case body after it; the last
'    Case body's own jump to End Select degenerates to `EB 00`. The Default body here is
'    exactly `If c <> 0 ... EndIf`, tested against the raw local (not the Select
'    scrutinee copy), which is how it is told apart from a fifth Case.
' 2. `If limitchars > 0` has the limit test in the Then arm, operand order
'    `txt.Length >= limitchars` (txt evaluated first, i.e. the left operand) -- Return 0
'    immediately at the limit rather than silently dropping the character.
' 3. `g_engine_int164` is used as a bare truthy test inside the Or/And chain
'    (`mov eax,[g] / cmp eax,0 / je`, no `<> 0` comparison pair), which also leaves the
'    running truth value in eax for the JoyHit chain that follows.
' 4. `joynum` is written branchily, the same idiom as the byte-identical sibling
'    src/recovered/TScreen.GetInput.bmx: `joynum = 0` then
'    `If g_options_int01 = 2 Then joynum = 1`, not an assigned comparison.
' 5. The Ctrl+V statement is `SetText(GetClipboardText(), "", -1, -1)`: cdecl pushes
'    right-to-left, so in source order the arguments are (Self, <call result>,
'    0xC5D284, -1, -1), and slot 0x64 (extracted/vtable_map.tsv) is
'    TGadget.SetText($,$,i,i), a four-parameter method. 0x00C5D284 is the immortal empty
'    string (class ptr 0x005C7D60, refs 0x7FFFFFFF, length 0). The same
'    SetText(x, "", -1, -1) shape is already byte-identical in
'    src/recovered/TButton.CreateButton.bmx, TCombo.Activate.bmx and six other bodies.
'
' Fields (offsets confirmed against the disassembly):
'   TGadget: txt +0x10, w +0x2c (Float), alive +0x38, hidden +0x3c
'   TInputBox: limitchars +0x5c, gettinginput +0x60, fRet +0x64 (()i callback, compared
'     against the null-function stub 0x005B95D0, same idiom as g_selgadget.fHit in
'     src/recovered/TScreen.CheckInput.bmx)
' Globals (scripts/explain_global.py; names match the sibling that already declares each
' address for this exact use):
'   g_activeScreen:TScreen @0x00C61700 (src/recovered/TScreen.TabToGadget.bmx, same
'     TabToGadget() call site, slot 0x8c)
'   g_sndclick:TSound @0x00C6171C, g_chanclick:TChannel @0x00C6F088
'     (src/recovered/TScreen.CheckInput.bmx, same PlaySound(sound,channel) shape)
'   g_options_int01:Int @0x00C5D1A8, g_options_arr06/07/08:Int[] @0x00C5D1D4/DC/E4,
'     g_engine_int164:Int @0x00C6EFEC (all established in src/recovered/TScreen.GetInput.bmx)
' KeyDown(162)=KEY_LCONTROL, KeyDown(86)=KEY_V. The chain reuses eax: when KeyDown(162)
'   returns 0 the shared "cmp eax,0" short-circuits the second KeyDown away, same shape as
'   src/recovered/TScreen_MainMenu.NewGame.bmx's "KeyDown(162) And KeyDown(69)".
'!Global g_activeScreen:TScreen
'!Global g_sndclick:TSound
'!Global g_chanclick:TChannel
'!Global g_options_int01:Int
'!Global g_options_arr06:Int[]
'!Global g_options_arr07:Int[]
'!Global g_options_arr08:Int[]
'!Global g_engine_int164:Int

If hidden Then Return 0
If Not alive Then Return 0
If gettinginput
	Local c:Int
	Repeat
		c = GetChar()
		Select c
		Case 27
			gettinginput = 0
			FlushAllInput()
			If fRet Then fRet()
			Return 0
		Case 13
			gettinginput = 0
			FlushAllInput()
			If fRet Then fRet()
			Return 0
		Case 9
			gettinginput = 0
			FlushAllInput()
			If fRet
				fRet()
			Else
				g_activeScreen.TabToGadget()
			EndIf
			Return 0
		Case 8
			If txt.Length > 0
				txt = txt[..txt.Length - 1]
			EndIf
		Default
			If c <> 0
				If limitchars > 0
					If txt.Length >= limitchars Then Return 0
					txt = txt + Chr(c)
				Else
					If Float(TextWidth(txt)) < w - 40.0
						txt = txt + Chr(c)
					EndIf
				EndIf
			EndIf
		End Select
	Until c = 0
	If KeyDown(162) And KeyDown(86)
		SetText(GetClipboardText(), "", -1, -1)
	EndIf
	Local joynum:Int = 0
	If g_options_int01 = 2 Then joynum = 1
	If MouseHit(1) Or (g_engine_int164 And (JoyHit(g_options_arr06[1], joynum) Or JoyHit(g_options_arr07[1], joynum) Or JoyHit(g_options_arr08[1], joynum)))
		gettinginput = 0
		FlushAllInput()
		PlaySound(g_sndclick, g_chanclick)
		If fRet Then fRet()
		Return 0
	EndIf
EndIf
Return 0
