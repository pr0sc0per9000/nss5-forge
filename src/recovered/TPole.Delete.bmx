' TPole.Delete
' VA 0x0058389B   51 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory, mode=reloc)
' no assumptions: the body is EMPTY. The inlined BBRELEASE of the single heap field at
' +0x24, the class-pointer store to the TTrainingObject class table (0x00C6D678) and the
' tail call to TTrainingObject.Delete are all bcc's automatic destructor chaining, not
' source. (`Super.Delete()` is not writable -- Delete is reserved and bcc rejects it.)
	Method Delete()
	End Method
