' TScreen_Options.ButtonMatchLength
' VA 0x00520e27   213 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (213/213, original length from Ghidra's inventory)
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
		'!Global g_screen:TScreen
		Select TGadget.GetActiveGadgetName()
			Case "options_matchlength3"
				g_matchlength = 3
			Case "options_matchlength5"
				g_matchlength = 5
			Case "options_matchlength7"
				Local b:TButton = TButton(g_screen.GetGadgetByName("options_matchlength7"))
				If b.alph < 1.0
					TScreen.DoMessage(GetText("CMESSAGE_NO7MINS"), 0, 0)
				Else
					g_matchlength = 7
				End If
		End Select
		RefreshButtons()
	End Function
