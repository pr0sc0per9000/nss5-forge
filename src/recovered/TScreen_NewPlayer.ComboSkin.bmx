' TScreen_NewPlayer.ComboSkin
' VA 0x00524800   125 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory)
' ASSUMPTIONS: module Global 0x00c6423c declared TCombo (construction-site typed),
' 0x00c6f028 declared TProfile. TCombo slots 0xac/0xbc/0xc8/0x6c =
' SelectItem/GetSelectedItem/GetSelectedColour/SetColour; TPlayerColours slot 0x30 =
' SetSkin; the tail call is TScreen_NewPlayer+0x54 = RefreshKit, a sibling Function so it
' carries no Type prefix. The "FFFFFF" literal is a masked address; its VALUE is unproven.
'
' NOTE (new codegen rule): the String Local is load-bearing. Written inline as
' SetColour(g_combo.GetSelectedColour(), "FFFFFF") the body is still exactly 125 bytes but
' diverges at byte 34 -- bcc hoists the receiver into ebx before the nested call. Binding
' the call result to a Local makes bcc evaluate it first and load the receiver into edx
' afterwards, which is the original. The Local costs no bytes and emits no refcount
' traffic; it only reorders evaluation. harness mode=reloc, 8 addresses masked.
	Function ComboSkin:Int()
		'!Global g_comboskin:TCombo
		'!Global g_profile:TProfile
		If g_comboskin.selecteditem < 1 Then g_comboskin.SelectItem(1)
		Local col$ = g_comboskin.GetSelectedColour()
		g_comboskin.SetColour(col, "FFFFFF")
		g_profile.playercols.SetSkin(g_comboskin.GetSelectedItem())
		RefreshKit()
	End Function
