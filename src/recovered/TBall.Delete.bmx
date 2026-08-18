' TBall.Delete
' VA 0x004C7692   164 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (164/164, original length from Ghidra's inventory)
' Body is empty: the original is entirely the compiler-generated reverse-order release of the String/object fields (replayframes,setpiecebuddy,setpiecetaker,assistedby,lasttouchedby,lastkickedby,controlledby,colour).
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Method Delete()
		' compiler-generated field release
	End Method
