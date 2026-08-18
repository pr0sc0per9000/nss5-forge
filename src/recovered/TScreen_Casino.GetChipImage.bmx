' TScreen_Casino.GetChipImage
' VA 0x0057442f   134 bytes   vtable slot 0x40   sig (i):TImage
' byte-identical vs NSS5.exe (134/134, original length from Ghidra's inventory)
' module global at 0x00c6b840 assumed TImage[]; element loads are arr+0x18+4*i.
' Parameter names are not recoverable from the binary; a0/a1/... as emitted by the harness.
	Function GetChipImage:TImage(a0:Int)
		'!Global g_casino_chipimages:TImage[]
		Select a0
			Case 50
				Return g_casino_chipimages[0]
			Case 100
				Return g_casino_chipimages[1]
			Case 250
				Return g_casino_chipimages[2]
			Case 500
				Return g_casino_chipimages[3]
			Case 1000
				Return g_casino_chipimages[4]
			Case 2500
				Return g_casino_chipimages[5]
			Case 5000
				Return g_casino_chipimages[6]
		End Select
		Return Null
	End Function
