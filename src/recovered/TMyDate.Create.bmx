' TMyDate.Create
' VA 0x00537358   54 bytes   vtable slot 0x30   sig (i,i,i):TMyDate
' byte-identical vs NSS5.exe (54/54, original length from Ghidra's inventory)

	Function Create:TMyDate(a0:Int, a1:Int, a2:Int)
		Local d:TMyDate = New TMyDate
		d.SetDate(a0, a1, a2)
		Return d
	End Function
