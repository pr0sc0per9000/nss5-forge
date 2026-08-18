' TScreen_Interview.EnableAllButtons
' VA 0x0057b8e6   131 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (131/131, original length from Ghidra's inventory, mode=reloc)
' assumes module Global (name ours, type load-bearing): Global g_iv_screen:TScreen (0x00C6CDD8)
' slots: TScreen+0x90 = GetGadgetByName($):TGadget, TButton+0x70 = SetAlph(f),
'        TGadget+0x6C = SetColour($,$); piVar3[0xE] is TGadget.alive at +0x38.
' string literals: "btn_" (0x00C7E308), "FFFFFF" (0x00C5D680)
'!Global g_iv_screen:TScreen

	Function EnableAllButtons:Int()
		For Local i:Int = 1 To 15
			Local b:TButton = TButton(g_iv_screen.GetGadgetByName("btn_" + i))
			b.SetAlph(1.0)
			b.alive = 1
			b.SetColour("FFFFFF","FFFFFF")
		Next
	End Function
