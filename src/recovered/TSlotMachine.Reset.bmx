' TSlotMachine.Reset
' VA 0x0057834e   24 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (24/24, original length from Ghidra's inventory)
' Assumes module global at 0x00C6C564 is Int; name taken from globals_named.tsv
' (g_slotmachine_int01). Declared in the probe as: Global g_slotmachine_int01:Int
	Function Reset:Int()
		'!Global g_slotmachine_int01:Int
		g_slotmachine_int01 = 0
	End Function
