' TScreen_ContinentalComps.ComboSelectClub
' VA 0x0053455C   134 bytes   vtable slot 0x5C   sig ()i
' byte-identical vs NSS5.exe (134/134, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Globals 0x00C65A40:TCombo, 0x00C65A24:TCompetition (both construction-typed).
' 0x00C59E0C = TClub class table + 0x60 = TClub.SelectById(i):TClub; 0x00C65C4C =
' TScreen_ContinentalComps + 0x44 = RefreshQualifiers (sibling Function, unqualified).
' FUN_00505B91 = LogLine, FUN_004A7AC0 = _bbStringFromInt, FUN_004A7C20 = _bbStringConcat.
' bcc does no CSE, so the combo id MUST be a Local -- it is consumed twice.
	Function ComboSelectClub:Int()
		'!Global g_cc_combo:TCombo
		'!Global g_cc_comp:TCompetition
		Local id:Int = g_cc_combo.GetSelectedItemId()
		LogLine("ComboClub:" + id)
		Local c:TClub = TClub.SelectById(id)
		If g_cc_comp <> Null And c <> Null
			c.continentalcompid = g_cc_comp.id
		EndIf
		RefreshQualifiers()
	End Function
