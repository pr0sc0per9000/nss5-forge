' TPlayerColours.Delete
' VA 0x004dd145   34 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' Empty body. The 34 bytes are bcc's compiler-generated field teardown for the
' single heap field (boots:$ @0x10): decref then bbGCFree when it reaches zero.
	Method Delete()

	End Method
