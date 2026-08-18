' TScreen_TestMenu.SetUpScreen
' VA 0x00537ba2   51 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory)
' assumptions: module Global 0x00c6635c declared TScreen (globals_final construction site);
'              a Function reached through an object reference dispatches through that
'              object's class table, which is why slot 0x60 (TScreen.SetActiveGadget($))
'              shows as a double deref in the decompilation.
'              String literals read out of NSS5.exe at 0x00c850b8 / 0x00c85194.
	Function SetUpScreen:Int()
		'!Global g_screen:TScreen
		TScreen.SetActive("testmenu","")
		g_screen.SetActiveGadget("testmenu_newgame")
	End Function
