' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TKit.GetHexSkinColour
' VA 0x004DBF3F   96 bytes   vtable slot 0x4c   sig (i)$
' byte-identical vs NSS5.exe (96/96, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' The five case strings are distinct because the original's five string-constant
'   addresses are distinct.
' the fallback is a genuine recursive call to TKit.GetHexSkinColour.

	Function GetHexSkinColour:String(a0:Int)
		Select a0
			Case 1
				Return "FFC28E"
			Case 2
				Return "C47840"
			Case 3
				Return "B75E23"
			Case 4
				Return "7C3400"
			Case 5
				Return "C6A754"
		End Select
		Return TKit.GetHexSkinColour(Rand(1, 5))
	End Function
