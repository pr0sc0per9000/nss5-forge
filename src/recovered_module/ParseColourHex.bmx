' ParseColourHex  -- module-level Function (no Type)
' VA 0x005064ed   184 bytes   sig ($,*i,*i,*i)i
' byte-identical vs NSS5.exe (184/184, original length from Ghidra's inventory, mode=reloc)
'
' NAME IS OURS. The Var-output twin of SetColourHex (0x00505cea): identical parse, but the
' three components are written through Var parameters instead of being handed to SetColor.
' Same length, same guards, same "$" constant at 0x00C7529C.
'
' The three out-parameters are Vars, not Ptrs; a scalar Var compiles identically to a Ptr,
' but the harness needs the explicit decl to spell it.
	Function ParseColourHex:Int(a0:String, a1:Int Var, a2:Int Var, a3:Int Var)
		If a0.length < 6 Then Return 0
		If a0.length > 6 Then a0 = a0[3..]
		a1 = Int("$"+a0[0..2])
		a2 = Int("$"+a0[2..4])
		a3 = Int("$"+a0[4..6])
	End Function
