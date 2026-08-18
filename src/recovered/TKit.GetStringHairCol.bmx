' TKit.GetStringHairCol
' VA 0x004dc297   121 bytes   vtable slot 0x68   sig (i)$
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' the fallback sits after End Select; in the original its code is placed behind all case bodies.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function GetStringHairCol:String(a0:Int)
		Select a0
			Case 1
				Return "CHAIR_BLACK"
			Case 2
				Return "CHAIR_BROWN"
			Case 3
				Return "CHAIR_BLOND"
			Case 4
				Return "CHAIR_RED"
			Case 5
				Return "CHAIR_GREY"
			Case 6
				Return "CHAIR_LBROWN"
			Case 7
				Return "CHAIR_DBLOND"
		End Select
		Return "CHAIR_UNKNOWN:" + a0
	End Function
