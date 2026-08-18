' TScreen_MainMenu.ButtonLoadGame
' VA 0x0051d138   75 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (75/75, original length from Ghidra's inventory)
' Assumes two module Globals of declared type TGadget (original names unrecoverable):
'   g_gad1 (0x00c639e0), g_gad2 (0x00c639d8). Slots 0x54/0x58 are TGadget.Hide/Show and
'   +0x3c is TGadget.hidden, so any TGadget subclass would emit the same bytes.
' 0x00c63cb8 = TScreen_MainMenu+0x4c (UpdateLoadTable).
	Function ButtonLoadGame:Int()
		'!Global g_gad1:TGadget
		'!Global g_gad2:TGadget
		g_gad1.Hide()
		If g_gad2.hidden
			TScreen_MainMenu.UpdateLoadTable()
			g_gad2.Show()
		Else
			g_gad2.Hide()
		EndIf
	End Function
