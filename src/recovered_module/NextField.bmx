' NextField  -- module-level Function (no Type)
' VA 0x00505c64   134 bytes   sig ($ Var,$)$
' byte-identical vs NSS5.exe (134/134, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. 5 game functions call it. The String twin of NextFieldInt (0x00505bcb):
' returns the text up to the first occurrence of the separator and advances the source
' string past it. Same shape as NextFieldInt with the Int() conversions removed.
'
' The parameter is a Var, not a Ptr -- String has no Ptr spelling -- so the harness needs
' an explicit decl (a0:String Var, a1:String). The empty-string assignment is the shared
' "" constant at 0x00C5D284.
'
' Verified from scratch (decl="a0:String Var, a1:String") -> MATCH 134/134,
' reloc_masked=6. An "IndexError: string index out of range" here comes from an older
' harness.try_function call path, not from a body defect.
	Function NextField:String(a0:String Var, a1:String)
		Local r:String
		Local i:Int = a0.Find(a1)
		If i < 0 Then
			r = a0
			a0 = ""
		Else
			r = a0[..i]
			a0 = a0[i+1..]
		End If
		Return r
	End Function
