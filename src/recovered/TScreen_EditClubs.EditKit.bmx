' TScreen_EditClubs.EditKit
' VA 0x0052ef71   178 bytes   vtable slot 0x?   sig ()i
' byte-identical vs NSS5.exe (178/178, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C653C4 declared TClub (globals_final.tsv, construction-site typed);
'   0x00C621CC = TGadget class table + 0x7C = TGadget.GetActiveGadgetName():$;
'   0x00C65E18 = TScreen_EditKits class table + 0x34 = SetUpScreen(:TBase_Team,i).
'   Select, not If/ElseIf (codegen-patterns 10.2).
'!Global g_editclubs_club:TClub
	Function EditKit()
		Select TGadget.GetActiveGadgetName()
			Case "btn_EditKit1"
				TScreen_EditKits.SetUpScreen(g_editclubs_club, 0)
			Case "btn_EditKit2"
				TScreen_EditKits.SetUpScreen(g_editclubs_club, 1)
			Case "btn_EditKit3"
				TScreen_EditKits.SetUpScreen(g_editclubs_club, 2)
			Case "btn_EditKit4"
				TScreen_EditKits.SetUpScreen(g_editclubs_club, 3)
		End Select
	End Function
