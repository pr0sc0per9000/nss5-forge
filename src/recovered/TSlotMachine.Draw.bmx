' TSlotMachine.Draw
' VA 0x005783E4   133 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (133/133, original length from Ghidra's inventory)
' assumptions: Globals 0x00C6C558/55C/560 declared TSlotStrip (slot 0x3c = Draw),
' 0x00C6C54C TImage, 0x00C6EFE4/E8 Int; string literal "FFFFFF" read from .data;
' 0x00506456 is the recovered module Function SetDrawStateHex.
	Function Draw:Int()
		'!Global g_slotstrip1:TSlotStrip
		'!Global g_slotstrip2:TSlotStrip
		'!Global g_slotstrip3:TSlotStrip
		'!Global g_slotmachineimage:TImage
		'!Global g_screenwidth:Int
		'!Global g_screenheight:Int
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
		g_slotstrip1.Draw()
		g_slotstrip2.Draw()
		g_slotstrip3.Draw()
		SetViewport(0, 0, g_screenwidth, g_screenheight)
		DrawImage(g_slotmachineimage, 202.0, 172.0, 0)
	End Function
