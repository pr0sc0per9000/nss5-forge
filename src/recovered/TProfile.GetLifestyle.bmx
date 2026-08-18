' TProfile.GetLifestyle
' VA 0x0056B5DA   116 bytes   vtable slot 0xF4   sig ()i
' byte-identical vs NSS5.exe (116/116, original length from Ghidra's inventory)
' no assumptions: fields 0xf0/0xf4/0xf8 are items/vehicles/property ([]i) from the object
' model; the float constants at 0x00c8ec7c..90 were read out of NSS5.exe as
' 0.0 / 1.0 / 1.0 / 1.0 / 30.0 / 100.0. The loop is `To 9` (jle), not `Until 10` (jl).
	Method GetLifestyle:Int()
		Local n:Float = 0.0
		For Local i:Int = 0 To 9
			If items[i] > 0 Then n = n + 1.0
			If vehicles[i] > 0 Then n = n + 1.0
			If property[i] > 0 Then n = n + 1.0
		Next
		Return Int((n / 30.0) * 100.0)
	End Method
