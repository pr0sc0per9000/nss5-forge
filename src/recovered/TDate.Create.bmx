' TDate.Create
' VA 0x00536860   81 bytes   vtable slot 0x30   sig (i,i,i):TDate
' byte-identical vs NSS5.exe (81/81, original length from Ghidra's inventory)
' local name 'd' is invented; slot 0x34 = SetDate, slot 0x3c = SetJulian per vtable_map.tsv
	Function Create:TDate(a0:Int, a1:Int, a2:Int)
		Local d:TDate = New TDate
		If a1 > 0
			d.SetDate(a0, a1, a2)
		Else
			d.SetJulian(a0)
		EndIf
		Return d
	End Function
