' THorse.RenderAllRunners
' VA 0x0058add2   102 bytes   vtable slot 0x58   sig (f,f,f)i
' byte-identical vs NSS5.exe (102/102, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c6e298 declared TList (name ours; declared type is
' load-bearing). Loop variable type THorse proved by the downcast class table 0x00c6e788.
	Function RenderAllRunners(a0:Float, a1:Float, a2:Float)
		' 0x00C6E298 is the RACE RUNNERS list, not the master horse list. THorse.SelectRunners
		' declares both in one body -- g_horses for 0x00C6E294 (the list it enumerates and
		' sorts) and g_runners for 0x00C6E298 (the list it Clears and AddLasts into) -- so the
		' two are provably different slots, and the module body creates them separately. Spelled
		' g_runners here, this body's slot shared the emitted variable of the master list.
		'!Global g_runners:TList
		For Local h:THorse = EachIn g_runners
			h.Render(a0, a1, a2)
		Next
	End Function
