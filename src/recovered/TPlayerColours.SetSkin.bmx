' TPlayerColours.SetSkin
' VA 0x004DD167   39 bytes   vtable slot 0x30   sig (i)i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory), harness mode=reloc
' Assumptions: field `skin` at +0x08 (object_model.json).
'   ClampInt is the recovered module Function at 0x00505F6D (src/recovered_module/ClampInt.bmx).
	Method SetSkin:Int(a0:Int)
		skin = a0
		ClampInt(Varptr skin, 1, 5)
	End Method
