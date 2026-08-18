' TPlayer.ResetKick
' VA 0x004f2e37   83 bytes   vtable slot 0xac   sig ()i
' byte-identical vs NSS5.exe (83/83, original length from Ghidra's inventory)
' the value -1.0 is a GUESS: bcc loads any non-zero Float constant from a data slot and that address is relocation-masked, so the constant's value is NOT established by this match
	Method ResetKick:Int()
		kickpower = 0
		kickdirection = -1.0
		joy.kickbuttondown = 0
		joy.kickbuttonhits = 0
		icalledforball = 0
		ihadashot = 0
	End Method
