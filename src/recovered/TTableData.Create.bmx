' TTableData.Create
' VA 0x00526b29   76 bytes   vtable slot 0x30   sig (i,i,$,i):TTableData
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory)

	Function Create:TTableData(a0:Int, a1:Int, a2:String, a3:Int)
		Local t:TTableData = New TTableData
		t.id = a0
		t.teamid = a1
		t.teamname = a2
		t.teamstrength = a3
		Return t
	End Function
