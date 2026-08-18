' TKit.GetBootColour
' VA 0x004dc023   139 bytes   vtable slot 0x58   sig (i)$
' byte-identical vs NSS5.exe (139/139, original length from Ghidra's inventory)
' no Default and no trailing Return: the "" result is bcc's implicit return.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function GetBootColour:String(a0:Int)
		Select a0
			Case 1
				Return "666666"
			Case 2
				Return "FFFF00"
			Case 3
				Return "4BD998"
			Case 4
				Return "9900DE"
			Case 5
				Return "FF9933"
			Case 6
				Return "0000FF"
			Case 7
				Return "00FFFF"
			Case 8
				Return "00FF00"
			Case 9
				Return "FF0000"
			Case 10
				Return "FFFFFF"
		End Select
	End Function
