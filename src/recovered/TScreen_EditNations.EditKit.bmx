' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_EditNations.EditKit
' VA 0x0052b54a   178 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (178/178, original length from Ghidra's inventory)
' PTR_FUN_00c621cc = TGadget class table (0x00C62150) + 0x7C = GetActiveGadgetName()$
' PTR_FUN_00c65e18 = TScreen_EditKits slot 0x34 = SetUpScreen(:TBase_Team,i)
' 0x00C65034 : TNation (declared type only has to be a TBase_Team subclass; it is a plain push)
' Select..Case, NOT If/ElseIf -- the ElseIf chain is 4 bytes short
' Global: Global g_editnation:TNation
	Function EditKit:Int()
		'!Global g_editnation:TNation
		Select TGadget.GetActiveGadgetName()
			Case "btn_EditKit1"
				TScreen_EditKits.SetUpScreen(g_editnation,0)
			Case "btn_EditKit2"
				TScreen_EditKits.SetUpScreen(g_editnation,1)
			Case "btn_EditKit3"
				TScreen_EditKits.SetUpScreen(g_editnation,2)
			Case "btn_EditKit4"
				TScreen_EditKits.SetUpScreen(g_editnation,3)
		End Select
	End Function
