' TPlayer.CheckHoldingKick
' VA 0x004F6BD1, 90 bytes
' byte-identical vs NSS5.exe

	Method CheckHoldingKick:Int()
		If joy.kickbuttondown Then joy.kickenabled = 0
		ResetKick()
		joy.Update(0, GetMouseDirection(), 0)
	End Method
