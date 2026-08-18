' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' THorse.GetStringHealth
' VA 0x0058A971   52 bytes   vtable slot 0x3c   sig ()$
' byte-identical vs NSS5.exe (52/52, original length from Ghidra's inventory)
' Uses _bbFloatToInt (0x005B9690), _bbStringFromInt (0x004A7AC0) and the string-concat helper (0x004A7C20).
' harness mode=reloc.

	Method GetStringHealth:String()
		Return Int(health) + "%"
	End Method
