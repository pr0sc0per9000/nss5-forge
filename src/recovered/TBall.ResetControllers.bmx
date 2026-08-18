' TBall.ResetControllers
' VA 0x004CBCE3   198 bytes   vtable slot 0xa0   sig ()i
' byte-identical vs NSS5.exe (198/198, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables) differ by construction between probe and NSS5.exe; emitted code is identical.

	Method ResetControllers:Int()
		kicktime = 0
		controlledby = Null
		lastkickedby = Null
		lasttouchedby = Null
		curlamount = 0
		passtoid = 0
		setpiecetaker = Null
		setpiecebuddy = Null
	End Method
