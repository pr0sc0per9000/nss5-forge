' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' THorse.GetStringEnergy
' VA 0x0058A93D   52 bytes   vtable slot 0x38   sig ()$
' byte-identical vs NSS5.exe (52/52, original length from Ghidra's inventory)
' FUN_005b9690 = _bbFloatToInt (emitted by Int()), then _bbStringFromInt + _bbStringConcat
	Method GetStringEnergy:String()
		Return Int(energy) + "%"
	End Method
