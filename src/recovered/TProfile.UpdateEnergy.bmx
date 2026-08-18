' TProfile.UpdateEnergy
' VA 0x0056B720   96 bytes   vtable slot 0x100   sig (f)i
' byte-identical vs NSS5.exe (96/96, original length from Ghidra's inventory, mode=reloc)
' Assumptions: FUN_00505B91 = LogLine (recovered module Function; its literal is the
' caller's own name), FUN_00505F90 = ClampFloat, FUN_004A79D0 = _bbStringFromFloat,
' FUN_004A7C20 = _bbStringConcat. 0x00C66914 = TScreen_GameMenu class table + 0x38 =
' UpdateTitlePanel(). ClampFloat's recovered signature takes a Float Ptr; the original
' most likely declared a Float Var, which compiles identically.
	Method UpdateEnergy:Int(a0:Float)
		LogLine("UpdateEnergy:" + a0)
		energy = energy + a0
		ClampFloat(Varptr energy, 0, 100)
		TScreen_GameMenu.UpdateTitlePanel()
	End Method
