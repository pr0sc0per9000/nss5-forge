' TPlayer.ImageHoldingBall
' VA 0x004fc9bf   99 bytes   vtable slot 0x1ac   sig (i)i
' byte-identical vs NSS5.exe (99/99, original length from Ghidra's inventory)
' three separate Ifs, NOT an Or chain (an Or chain emits sete/movzx and comes out 13 bytes long). Global at 0x00c5df28 assumed Int[]; globals_named.tsv guesses Object[], which would be wrong
	Method ImageHoldingBall:Int(a0:Int)
		'!Global g_holdframes:Int[]
		For Local f:Int = EachIn g_holdframes
			If a0 = f Then Return 1
			If a0 = f + 64 Then Return 1
			If a0 = f + 128 Then Return 1
		Next
	End Method
