' TGadget.SetUp
' VA 0x0051378d   155 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (155/155, original length from Ghidra's inventory)
' Globals: g_listup:TImage (0x00c61d00), g_listdown:TImage (0x00c61d04)
' Guard is the `If Not x` emission (setne/movzx), not `If x = Null`.
	Function SetUp:Int()
		'!Global g_listup:TImage
		'!Global g_listdown:TImage
		If Not g_listup
			g_listup = LoadImageChecked("GameMedia/Images/Interface/ListUp.png",-1)
			g_listdown = LoadImageChecked("GameMedia/Images/Interface/ListDown.png",-1)
			MidHandleImage(g_listup)
			MidHandleImage(g_listdown)
		EndIf
	End Function
