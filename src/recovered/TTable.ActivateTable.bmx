' TTable.ActivateTable
' VA 0x00517A9A   78 bytes   vtable slot 0xcc   sig ()i
' byte-identical vs NSS5.exe (78/78, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c61cf8 declared TGadget (104 refs, TScreen subsystem);
' it is only downcast here, so any Object-rooted type gives the same bytes.

	Function ActivateTable:Int()
		'!Global g_activegadget:TGadget
		Local t:TTable = TTable(g_activegadget)
		If t And t.items.Count() Then t.activated=1
	End Function
