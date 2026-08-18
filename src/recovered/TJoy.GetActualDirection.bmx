' TJoy.GetActualDirection
' VA 0x004da63f   38 bytes   vtable slot 0x38   sig ()f
' byte-identical vs NSS5.exe (38/38, original length from Ghidra's inventory)
' 0x004a1f90 is bbATan2

	Method GetActualDirection:Float()
		Return ATan2(axis_y, axis_x)
	End Method
