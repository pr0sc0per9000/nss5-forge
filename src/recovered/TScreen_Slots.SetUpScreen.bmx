' TScreen_Slots.SetUpScreen
' VA 0x005780bb   101 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (101/101, original length from Ghidra's inventory)
' assumption: module Globals at 0x00c6b858 / 0x00c6c49c / 0x00c6c4a0 declared as TGadget
'             (the calls are slot 0x58 = TGadget.Show()i)
' string literal "slots" read directly out of NSS5.exe's data section
	Function SetUpScreen:Int()
		'!Global g_gadA:TGadget
		'!Global g_gadB:TGadget
		'!Global g_gadC:TGadget
		TScreen.SetActive("slots","")
		TScreen_Casino.ShowTitleButtons()
		TScreen_GameMenu.UpdateTitlePanel()
		g_gadA.Show()
		g_gadA.Show()
		g_gadB.Show()
		g_gadC.Show()
	End Function
