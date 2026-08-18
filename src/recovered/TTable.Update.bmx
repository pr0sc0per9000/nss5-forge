' TTable.Update
' VA 0x005168b6   43 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe

	Method Update:Int()
		If hidden Then Return 0
		If Not alive Then Return 0
	End Method
