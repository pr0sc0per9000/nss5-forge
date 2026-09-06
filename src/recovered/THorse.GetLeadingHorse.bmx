' THorse.GetLeadingHorse
' VA 0x0058B050   140 bytes   vtable slot 0x60   sig ():THorse
' byte-identical vs NSS5.exe (140/140, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c6e298 declared TList (the horse list).
' Operand order is load-bearing: 'best.x < h.x' emits the two flds in the other order.

	Function GetLeadingHorse:THorse()
		' 0x00C6E298 is the RACE RUNNERS list, not the master horse list. THorse.SelectRunners
		' declares both in one body -- g_horses for 0x00C6E294 (the list it enumerates and
		' sorts) and g_runners for 0x00C6E298 (the list it Clears and AddLasts into) -- so the
		' two are provably different slots, and the module body creates them separately. Spelled
		' g_runners here, this body's slot shared the emitted variable of the master list.
		'!Global g_runners:TList
		Local best:THorse = Null
		For Local h:THorse = EachIn g_runners
			If best = Null Or h.x > best.x Then best = h
		Next
		Return best
	End Function
