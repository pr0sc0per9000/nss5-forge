' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen.MessageDone
' VA 0x005129FD   119 bytes   vtable slot 0x98   sig ()i
' byte-identical vs NSS5.exe (119/119, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C61730:Int; 0x00C621CC = TGadget class table + 0x7c =
' TGadget.GetActiveGadgetName():$. FUN_004A6A30 = _bbStringCompare.
' This is a SELECT, not an If/ElseIf chain: all three comparisons are emitted up front
' with `je <case body>` and the bodies live after them, each ending in `jmp end`. The
' ElseIf form is 115 bytes. String contents do not affect the emitted code.
	Function MessageDone:Int()
		'!Global g_screen_int01:Int
		Select TGadget.GetActiveGadgetName()
			Case "msgscreen_ok"
				g_screen_int01 = 1
			Case "msgscreen_yes"
				g_screen_int01 = 1
			Case "msgscreen_no"
				g_screen_int01 = 0
		End Select
	End Function
