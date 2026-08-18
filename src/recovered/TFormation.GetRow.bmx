' TFormation.GetRow
' VA 0x004d8aba   57 bytes   vtable slot 0x4c   sig (i)i
' byte-identical vs NSS5.exe

	Method GetRow:Int(a0:Int)
		Local r:Int = 4
		If a0 < 28 Then r = 3
		If a0 < 21 Then r = 2
		If a0 < 14 Then r = 1
		If a0 < 7 Then r = 0
		Return r
	End Method
