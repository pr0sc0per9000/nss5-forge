' TScreen_ContinentalComps.ComboComp
' VA 0x0053406c   91 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (91/91, original length from Ghidra's inventory)
' ASSUMPTIONS: module Globals 0x00c65a20 and 0x00c65a2c declared :TCombo (0x00c65a2c is the
' one whose slot 0xc0 = GetSelectedItemId is called), 0x00c65a24 declared :TCompetition.
' PTR_FUN_00c6160c = TCompetition + 0x4c = SelectById; PTR_FUN_00c65c3c = TScreen_ContinentalComps + 0x34 = SetUpScreen.
' NAME AND TYPE CHANGED 2026-10-11 (byte-neutral: the only use is a Null compare,
' 0x00534070 `813d205ac600809c5c00 cmp [0xc65a20],bbNullObject`). 0x00C65A20 is the
' selected TContinent that ComboContinent stores at 0x00533F55 (`891d205ac600`) as
' g_cc_continent; g_ccComboA:TCombo had no writer, so this Function never ran.
	Function ComboComp()
		'!Global g_cc_continent:TContinent
		'!Global g_ccCombo:TCombo
		'!Global g_ccComp:TCompetition
		If g_cc_continent <> Null
			g_ccComp = TCompetition.SelectById(g_ccCombo.GetSelectedItemId())
			TScreen_ContinentalComps.SetUpScreen()
		EndIf
	End Function
