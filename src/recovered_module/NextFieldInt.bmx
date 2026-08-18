' NextFieldInt  -- module-level Function (no Type)
' VA 0x00505bcb   153 bytes   sig ($,$)i
' byte-identical vs NSS5.exe (153/153, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. 9 game functions call it. Reads the text up to the first occurrence of the
' separator, returns it as an Int, and advances the source string past the separator --
' the field-at-a-time reader behind the game's text data files.
'
' The parameter is a Var, not a Ptr: a scalar Var compiles identically to a Ptr, but
' String Var has no Ptr spelling, so the harness needs an explicit declaration.
'
' NOTE: this was first reconstructed as returning a trimmed String, which came out two
' bytes long. The runtime-helper table identified the callee at 0x004A7130 as
' _bbStringToInt (4 independent witnesses), not _bbStringTrim -- so the field is parsed as
' an integer and the function returns Int. With that corrected it is exact.
	Function NextFieldInt:Int(a0:String Var, a1:String)
		Local r:Int
		Local i:Int = a0.Find(a1)
		If i < 0 Then
			r = Int(a0)
			a0 = ""
		Else
			r = Int(a0[..i])
			a0 = a0[i+1..]
		End If
		Return r
	End Function
