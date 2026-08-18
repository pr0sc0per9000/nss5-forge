' TScreen_ContinentalComps.ButtonGoToClubs
' VA 0x00534339   148 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (148/148, original length from Ghidra's inventory, mode=reloc)
' Assumes three module Globals (original names unrecoverable):
'   g_ccomps_table:TTable      (0x00C65A48) -- slot 0xD8 = TTable.GetSelectedText(i)$
'   g_clubs_combolocale:TCombo (0x00C65234) -- slot 0xAC = TCombo.SelectItem(i)
'   g_clubs_combobased:TCombo  (0x00C65238) -- slot 0xB0 = TCombo.SelectItemById(i)
' 0x00C6160C = TCompetition class table + 0x4C = TCompetition.SelectById(i):TCompetition
' 0x00C6539C / 0x00C653A0 / 0x00C653A4 = TScreen_Clubs class table
'     + 0x?? = SetUpScreen / ComboLocale / ComboBased
' 0x004A7130 = _bbStringToInt, i.e. Int(<String>).
' The `Local b:Int = c.based` is load-bearing: reading c.based inline at the call site
' comes out 147 bytes.
	Function ButtonGoToClubs:Int()
		'!Global g_ccomps_table:TTable
		'!Global g_clubs_combolocale:TCombo
		'!Global g_clubs_combobased:TCombo
		Local c:TCompetition = TCompetition.SelectById(Int(g_ccomps_table.GetSelectedText(0)))
		If c <> Null And c.locale = 0
			Local b:Int = c.based
			TScreen_Clubs.SetUpScreen()
			g_clubs_combolocale.SelectItem(1)
			TScreen_Clubs.ComboLocale()
			g_clubs_combobased.SelectItemById(b)
			TScreen_Clubs.ComboBased()
		EndIf
	End Function
