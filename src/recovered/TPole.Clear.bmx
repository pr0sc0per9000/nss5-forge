' TPole.Clear
' VA 0x00583C5A   32 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (32/32, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c6d568 declared TList (39 refs, TTraining subsystem).
' The declared type selects the vtable slot: slot 0x74 on TList is Remove.

	Method Clear:Int()
		'!Global g_poles:TList
		g_poles.Remove(Self)
	End Method
