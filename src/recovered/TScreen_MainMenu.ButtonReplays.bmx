' TScreen_MainMenu.ButtonReplays
' VA 0x0051D68E   75 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (75/75, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses (data pointers, string/array constants, class tables)
'   differ by construction between probe and NSS5.exe; the emitted code is identical.
' module Globals assumed (names ours, types load-bearing):
'   Global g_g1:TGadget (0x00C639D8), Global g_g2:TGadget (0x00C639E0)
'   any TGadget subclass would give the same slots (Hide 0x54 / Show 0x58) and field (hidden 0x3c)

	Function ButtonReplays:Int()
		'!Global g_g1:TGadget
		'!Global g_g2:TGadget
		g_g1.Hide()
		If g_g2.hidden
			TScreen_MainMenu.UpdateReplayTable()
			g_g2.Show()
		Else
			g_g2.Hide()
		End If
	End Function
