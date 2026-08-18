' TScreen_Competitions.ComboLevel
' VA 0x0052FF28   270 bytes   vtable slot 0x54   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (270/270, original length from Ghidra's inventory, mode=reloc)
' assumptions: Globals 0x00C65578 / 0x00C6557C both TCombo (construction-site typed).
' 0x00C65714 = TScreen_Competitions+0x58 = ComboLocale (own Type -> plain call).
' The five string constants were read out of NSS5.exe as BlitzMax string objects.
' Select, not If/ElseIf: both Case compares sit back to back before either body (10.2).
	Function ComboLevel:Int()
		'!Global g_comp_combo1:TCombo
		'!Global g_comp_combo2:TCombo
		g_comp_combo2.ClearItems()
		Select g_comp_combo1.GetSelectedItem()
			Case 1
				g_comp_combo2.AddItem(GetText("Nation"), "BBBBBB", "FFFFFF", 0)
				g_comp_combo2.AddItem(GetText("Continent"), "BBBBBB", "FFFFFF", 0)
			Case 2
				g_comp_combo2.AddItem(GetText("Continent"), "BBBBBB", "FFFFFF", 0)
				g_comp_combo2.AddItem(GetText("World"), "BBBBBB", "FFFFFF", 0)
		End Select
		g_comp_combo2.SelectItem(1)
		ComboLocale()
	End Function
