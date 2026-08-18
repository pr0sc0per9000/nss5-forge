' THorse.GetLeadingHorse
' VA 0x0058B050   140 bytes   vtable slot 0x60   sig ():THorse
' byte-identical vs NSS5.exe (140/140, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c6e298 declared TList (the horse list).
' Operand order is load-bearing: 'best.x < h.x' emits the two flds in the other order.

	Function GetLeadingHorse:THorse()
		'!Global g_horses:TList
		Local best:THorse = Null
		For Local h:THorse = EachIn g_horses
			If best = Null Or h.x > best.x Then best = h
		Next
		Return best
	End Function
