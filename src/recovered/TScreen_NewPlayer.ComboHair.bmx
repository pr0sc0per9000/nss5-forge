' TScreen_NewPlayer.ComboHair
' VA 0x0052487D   125 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C64240 is a TCombo Global (construction-typed). TCombo.selecteditem is +0x68;
' slots 0xAC=SelectItem(i), 0xC8=GetSelectedColour()$, 0x6C=SetColour($,$), 0xC0=GetSelectedItemId().
' 0x00C6F028 is the TProfile Global; +0x24 = playercols:TPlayerColours, slot 0x34 = SetHair(i).
' 0x00C64424 = TScreen_NewPlayer + 0x54 (RefreshKit).
' The GetSelectedColour result MUST go through a Local -- inlining it makes bcc load the
' SetColour receiver first and the byte order diverges.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_combo_hair:TCombo
'   Global g_profile:TProfile
	Function ComboHair:Int()
		'!Global g_combo_hair:TCombo
		'!Global g_profile:TProfile
		If g_combo_hair.selecteditem < 1 Then g_combo_hair.SelectItem(1)
		Local col:String = g_combo_hair.GetSelectedColour()
		g_combo_hair.SetColour(col, "FFFFFF")
		Local pc:TPlayerColours = g_profile.playercols
		pc.SetHair(g_combo_hair.GetSelectedItemId())
		TScreen_NewPlayer.RefreshKit()
	End Function
