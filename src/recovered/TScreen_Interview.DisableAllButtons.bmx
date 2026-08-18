' TScreen_Interview.DisableAllButtons
' VA 0x0057B969   112 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (112/112, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C6CDD8 is the screen Global (construction-typed TScreen); slot 0x90 = GetGadgetByName($):TGadget.
' The downcast class table pushed at the bbObjectDowncast site is TButton (0x00C62344).
' TGadget + 0x70 = SetAlph(f); TGadget.alive is +0x38.
' String literal at 0x00C7E308 is "btn_".
' Loop bound: `To 15` (jle), not `Until 16` (jl).
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_screen_interview:TScreen
	Function DisableAllButtons:Int()
		'!Global g_screen_interview:TScreen
		For Local i:Int = 1 To 15
			Local b:TButton = TButton(g_screen_interview.GetGadgetByName("btn_" + i))
			b.SetAlph(1.0)
			b.alive = 0
		Next
	End Function
