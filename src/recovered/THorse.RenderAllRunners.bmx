' THorse.RenderAllRunners
' VA 0x0058add2   102 bytes   vtable slot 0x58   sig (f,f,f)i
' byte-identical vs NSS5.exe (102/102, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c6e298 declared TList (name ours; declared type is
' load-bearing). Loop variable type THorse proved by the downcast class table 0x00c6e788.
	Function RenderAllRunners(a0:Float, a1:Float, a2:Float)
		'!Global g_horses:TList
		For Local h:THorse = EachIn g_horses
			h.Render(a0, a1, a2)
		Next
	End Function
