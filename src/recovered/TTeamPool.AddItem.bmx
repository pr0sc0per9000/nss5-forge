' TTeamPool.AddItem
' VA 0x005265C2   71 bytes   vtable slot 0x38   sig (i,$,i)i
' byte-identical vs NSS5.exe (71/71, original length from Ghidra's inventory)
' harness mode=reloc; TTableData.Create resolved to TTableData+0x30 on both sides.

	Method AddItem:Int(a0:Int, a1:String, a2:Int)
		list.AddLast(TTableData.Create(list.Count()+1, a0, a1, a2))
	End Method
