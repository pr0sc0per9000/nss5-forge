' TNation.Delete
' VA 0x004bd616   51 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory)
' assumptions: none. Body is empty -- the 51 bytes are entirely compiler-generated
' teardown: inlined BBRELEASE of the single heap field at +0x60, then the Super
' (TBase_Team, classtable 0x00c596ac) Delete chain call at FUN_004bd053.
	Method Delete()
	End Method
