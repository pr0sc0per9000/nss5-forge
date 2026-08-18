' WrapAngle  -- module-level Function (no Type)
' VA 0x00506184   89 bytes   sig (*f)i
' byte-identical vs NSS5.exe (89/89, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. 2 game functions call it. Normalises the Float pointed at by a0 into
' [0,359] in place, by two test-at-the-top While loops.
'
' The three .rdata float constants are read out of NSS5.exe, not guessed: 0x00C7BB98 and
' 0x00C7BB9C both hold 360.0 (bcc does not pool duplicate constants, so each literal gets
' its own slot) and 0x00C7BBA0 holds 359.0 -- so the upper test is > 359.0, not >= 360.0.
' The parameter is a Var; a scalar Var compiles identically to a Ptr.
	Function WrapAngle:Int(a0:Float Var)
		While a0 < 0.0
			a0 = a0 + 360.0
		Wend
		While a0 > 359.0
			a0 = a0 - 360.0
		Wend
	End Function
