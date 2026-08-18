' TJoy.CreateJoy
' VA 0x004d9ce4   22 bytes   vtable slot 0x30   sig ():TJoy
' byte-identical vs NSS5.exe (22/22, original length from Ghidra's inventory)
' No assumptions: bbObjectNew(TJoy class table 0x00C5C1A0).
	Function CreateJoy:TJoy()
		Return New TJoy
	End Function
