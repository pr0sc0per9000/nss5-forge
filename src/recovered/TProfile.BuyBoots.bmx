' TProfile.BuyBoots
' VA 0x0056C367   113 bytes   vtable slot 0x12c   sig (i)i
' byte-identical vs NSS5.exe (113/113, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' 'To 9' is load-bearing (cmp 9 / jle); 'Until 10' gives cmp 0xa / jl and misses 8 bytes.
' PTR_FUN_00c5c4d8 = TKit + 0x58 = TKit.GetBootColour.

	Method BuyBoots:Int(a0:Int)
		For Local i:Int=0 To 9
			boots[i]=0
		Next
		boots[a0-1]=5
		playercols.boots=TKit.GetBootColour(a0)
	End Method
