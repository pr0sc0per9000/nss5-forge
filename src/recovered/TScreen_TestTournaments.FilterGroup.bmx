' TScreen_TestTournaments.FilterGroup
' VA 0x00538ef4   119 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (119/119, original length from Ghidra's inventory)
' assumes module global at 0x00C66428 typed Int (group filter index)
' 0x00C621CC = TGadget + 0x7c = GetActiveGadgetName()$; 0x00C665D8 = TScreen_TestTournaments
' + 0x34 = SetUpScreen()i. String constants at 0x00C853E0/3F4/408.
	Function FilterGroup:Int()
		'!Global g_testgroup:Int
		Select TGadget.GetActiveGadgetName()
			Case "grpL"
				g_testgroup = g_testgroup - 1
			Case "grp"
				g_testgroup = 1
			Case "grpR"
				g_testgroup = g_testgroup + 1
		End Select
		SetUpScreen()
	End Function
