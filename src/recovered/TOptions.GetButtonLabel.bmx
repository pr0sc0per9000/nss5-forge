' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TOptions.GetButtonLabel
' VA 0x004E2AC9   168 bytes   vtable slot 0x34   sig (i)$
' byte-identical vs NSS5.exe (168/168, original length from Ghidra's inventory, mode=reloc)
' module Globals assumed (names ours, types load-bearing):
'   0x00C5D1A8 : Int          (the Select subject)
'   0x00C5A324 : String[]     (indexed [edx + a0*4 + 0x18]; 0x18 = array data offset)
' 0x004C5549 is the recovered module Function GetText; 0x004A7AC0 = _bbStringFromInt and
' 0x004A7C20 = _bbStringConcat, so the default arm is a two-concat String expression whose
' rightmost operand (a0+1) is evaluated FIRST -- bcc evaluates call operands right-to-left.
' SHAPE: two NESTED SELECTs, not If/ElseIf. Both give themselves away by loading the
' subject into a register before the first comparison (`mov edx,[0xC5D1A8] / cmp edx,0`
' rather than `cmp dword[0xC5D1A8],0`) and by emitting every test up front, ahead of the
' default body, with each case body placed after it. The If/ElseIf chain builds to 165
' bytes with interleaved bodies; the nested Selects reproduce 168 exactly.

	Function GetButtonLabel:String(a0:Int)
		'!Global g_opt_mode:Int
		'!Global g_opt_labels:String[]
		Select g_opt_mode
			Case 0
				Return g_opt_labels[a0]
			Default
				Select a0
					Case -1
						Return GetText("joy_Left")
					Case -2
						Return GetText("joy_Right")
					Case -3
						Return GetText("joy_Up")
					Case -4
						Return GetText("joy_Down")
					Default
						Return GetText("joy_Button") + " " + (a0 + 1)
				End Select
		End Select
	End Function
