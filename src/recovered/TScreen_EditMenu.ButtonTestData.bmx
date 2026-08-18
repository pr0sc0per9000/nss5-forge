' TScreen_EditMenu.ButtonTestData
' VA 0x0052817d   156 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (156/156, original length from Ghidra's inventory)
' assumes: TScreen Global + TButton Global; early-return guard (156 vs 151 as If/Else); DoMessage resolved on TScreen slot 0x94
	Function ButtonTestData:Int()
		'!Global g_screen:TScreen
		'!Global g_btn_test:TButton
		If g_screen.GetGadgetByName("editmenu_save").hidden
			TScreen_TestMenu.SetUpScreen()
			Return 0
		EndIf
		If TScreen.DoMessage(GetText("CMESSAGE_TESTDATASAVE"), 1, 0)
			SaveMasterFiles(0)
		EndIf
		If TScreen.DoMessage(GetText("CMESSAGE_TESTDATACONTINUE"), 1, 0)
			TCompetition.SetUpCompetitionsAll()
			TScreen_TestMenu.SetUpScreen()
			g_btn_test.Hide()
		EndIf
	End Function
