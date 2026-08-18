' TScreen_ContinentalComps.ComboComp
' VA 0x0053406c   91 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (91/91, original length from Ghidra's inventory)
' ASSUMPTIONS: module Globals 0x00c65a20 and 0x00c65a2c declared :TCombo (0x00c65a2c is the
' one whose slot 0xc0 = GetSelectedItemId is called), 0x00c65a24 declared :TCompetition.
' PTR_FUN_00c6160c = TCompetition + 0x4c = SelectById; PTR_FUN_00c65c3c = TScreen_ContinentalComps + 0x34 = SetUpScreen.
	Function ComboComp()
		'!Global g_ccComboA:TCombo
		'!Global g_ccCombo:TCombo
		'!Global g_ccComp:TCompetition
		If g_ccComboA <> Null
			g_ccComp = TCompetition.SelectById(g_ccCombo.GetSelectedItemId())
			TScreen_ContinentalComps.SetUpScreen()
		EndIf
	End Function
