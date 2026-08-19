' TPlayer.CheckHoldingKick
' VA 0x004f6bd1   90 bytes   vtable slot 0xf0   sig ()i
' byte-identical vs NSS5.exe (90/90, original length from Ghidra's inventory)
' VA 0x004F6BD1, 90 bytes
' byte-identical vs NSS5.exe

	Method CheckHoldingKick:Int()
		If joy.kickbuttondown Then joy.kickenabled = 0
		ResetKick()
		joy.Update(0, GetMouseDirection(), 0)
	End Method
