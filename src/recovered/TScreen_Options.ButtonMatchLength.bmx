' TScreen_Options.ButtonMatchLength
' VA 0x00520e27   213 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (213/213, original length from Ghidra's inventory)
' NAME CORRECTED: the TScreen Global here was spelled g_screen, an identifier seven other
' bodies use for six DIFFERENT TScreen slots (create-account 0x00C64434, data editor
' 0x00C64D18, game menu 0x00C66724, test menu 0x00C6635C, paused match 0x00C6764C and this
' one). MEASURED: this body's single reference is 0x00520E86 `a1e83cc600 mov eax,
' [0xc63ce8]`, immediately before `push 0xc62344` (the "options_matchlength7" literal) and
' the GetGadgetByName call through slot 0x90 -- so it is the OPTIONS screen and nothing
' else; the body touches no other TScreen slot. 0x00C63CE8 is built and named by
' TScreen_Options.CreateScreen (`g_screen_options = TScreen.CreateScreen("options",...)`,
' store at 0x0051DA8F `891de83cc600 mov [0xc63ce8],ebx`), which is 21 further references to
' the same address in that one body. Only TScreen_EditMenu.CreateScreen among the g_screen
' users is reached from CreateAllScreens, so for a normal session the shared variable held
' the DATA EDITOR screen and this GetGadgetByName looked for options_matchlength7 on it.
' ASSUMPTIONS: module Global 0x00c5d230 declared Int (match length in minutes),
' 0x00c63ce8 declared TScreen (construction-site typed). TGadget slot 0x7c =
' GetActiveGadgetName; TScreen slot 0x90 = GetGadgetByName($):TGadget; TScreen slot 0x94 =
' DoMessage($,i,i); TScreen_Options+0x38 = RefreshButtons (sibling Function, no prefix).
' The four String literals are masked addresses; their VALUES are not proven.
'
' NOTES -- two shape corrections the oracle forced:
'  * This is a Select on a String subject, not If/ElseIf. The three _bbStringCompare tests
'    sit back to back and are followed by one "jmp end" (EB 7C) before any body. The
'    If/ElseIf form is 212 bytes.
'  * The inner test must be written "b.alph < 1.0 Then DoMessage Else 7", not
'    ">= 1.0 Then 7 Else DoMessage". bcc negates the source condition and jumps to the
'    Else, so "< 1.0" is what emits 0F 93 C0 setae + jne to the "= 7" block with the
'    DoMessage falling through. The >= spelling emits 0F 92 C0 setb and diverges at byte 144
'    at the same total length.
' harness mode=reloc, 18 addresses masked.
	Function ButtonMatchLength:Int()
		'!Global g_matchlength:Int
		'!Global g_screen_options:TScreen
		Select TGadget.GetActiveGadgetName()
			Case "options_matchlength3"
				g_matchlength = 3
			Case "options_matchlength5"
				g_matchlength = 5
			Case "options_matchlength7"
				Local b:TButton = TButton(g_screen_options.GetGadgetByName("options_matchlength7"))
				If b.alph < 1.0
					TScreen.DoMessage(GetText("CMESSAGE_NO7MINS"), 0, 0)
				Else
					g_matchlength = 7
				End If
		End Select
		RefreshButtons()
	End Function
