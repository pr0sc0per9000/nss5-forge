' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' THorse.GetStringForm
' VA 0x0058A9A5   180 bytes   vtable slot 0x40   sig ()$
' byte-identical vs NSS5.exe (180/180, original length from Ghidra's inventory)
' Separator literal is "-". Five Int->String conversions and eight concatenations match the original exactly.
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Method GetStringForm:String()
		Return form[0] + "-" + form[1] + "-" + form[2] + "-" + form[3] + "-" + form[4]
	End Method
