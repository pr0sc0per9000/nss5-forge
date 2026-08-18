' TPlayerColours.SetHair
' VA 0x004DD18E   39 bytes   vtable slot 0x34   sig (i)i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory), harness mode=reloc
' Assumptions: field `hair` at +0x0C (object_model.json).
'   ClampInt is the recovered module Function at 0x00505F6D.
	Method SetHair:Int(a0:Int)
		hair = a0
		ClampInt(Varptr hair, 1, 7)
	End Method
