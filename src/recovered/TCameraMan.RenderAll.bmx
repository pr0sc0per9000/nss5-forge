' TCameraMan.RenderAll
' VA 0x004eb921   93 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c5dca0 declared TList (name ours; declared type is
' load-bearing). Loop variable type TCameraMan proved by the downcast class table 0x00c5ddc0.
	Function RenderAll()
		'!Global g_cameramen:TList
		For Local c:TCameraMan = EachIn g_cameramen
			c.Render()
		Next
	End Function
