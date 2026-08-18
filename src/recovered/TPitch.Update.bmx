' TPitch.Update
' VA 0x004E6611   20 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (20/20, original length from Ghidra's inventory)
' Assumption: the class-table pointer at 0x00c5ddfc resolves to TCameraMan+0x3c = TCameraMan.UpdateAll.
	Function Update()
		TCameraMan.UpdateAll()
	End Function
