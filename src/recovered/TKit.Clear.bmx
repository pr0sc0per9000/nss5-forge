' TKit.Clear
' VA 0x004dae07   49 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (49/49, original length from Ghidra's inventory)
' assigning Null to an object field also bumps the null-object refcount -- that is bcc, not source

	Method Clear:Int()
		pixmap = Null
	End Method
