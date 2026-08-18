' TScreen_Continents.RefreshComboColours
' VA 0x005492C1   186 bytes   vtable slot 0x80   sig ()i
' byte-identical vs NSS5.exe (186/186, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C671E0/E4/E8 are three TCombo Globals (construction-typed, medium confidence).
' TGadget + 0x6C = SetColour($,$); TCombo.selecteditem is +0x68.
' String literals read out of .data: 0x00C73A70 = "888888", 0x00C5D680 = "FFFFFF".
' The `col` Local is load-bearing: the original keeps "FFFFFF" in ebx across the three
' conditional calls (mov ebx,imm32 + three `push ebx`). Inlining the literal in the first
' argument makes the body 5 bytes long.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_combo1:TCombo
'   Global g_combo2:TCombo
'   Global g_combo3:TCombo
	Function RefreshComboColours:Int()
		'!Global g_combo1:TCombo
		'!Global g_combo2:TCombo
		'!Global g_combo3:TCombo
		g_combo1.SetColour("888888", "FFFFFF")
		g_combo2.SetColour("888888", "FFFFFF")
		g_combo3.SetColour("888888", "FFFFFF")
		Local col:String = "FFFFFF"
		If g_combo1.selecteditem > 0 Then g_combo1.SetColour(col, "FFFFFF")
		If g_combo2.selecteditem > 0 Then g_combo2.SetColour(col, "FFFFFF")
		If g_combo3.selecteditem > 0 Then g_combo3.SetColour(col, "FFFFFF")
	End Function
