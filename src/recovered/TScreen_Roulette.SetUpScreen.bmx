' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Roulette.SetUpScreen
' VA 0x00574E6F   103 bytes   vtable slot 0x34   sig (i)i
' byte-identical vs NSS5.exe (103/103, original length from Ghidra's inventory)
' ASSUMPTION: module Globals 0x00C6BA50, 0x00C6BA58, 0x00C6BA54 declared :TGadget (slot 0x58 = TGadget.Show).
' The first SetActive argument is a string literal whose address is masked by mode=reloc.
' ClearBets() is TScreen_Roulette's own Function (slot 0x44), called unqualified. harness mode=reloc.

	Function SetUpScreen:Int(a0:Int)
		'!Global g_rl1:TGadget
		'!Global g_rl2:TGadget
		'!Global g_rl3:TGadget
		TScreen.SetActive("roulette", "")
		TScreen_Casino.ShowTitleButtons()
		g_rl1.Show()
		g_rl2.Show()
		g_rl3.Show()
		TScreen_GameMenu.UpdateTitlePanel()
		If a0 Then ClearBets()
	End Function
