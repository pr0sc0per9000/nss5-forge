' TScreen_ContinentalComps.ButtonRemoveClub
' VA 0x005345e2   72 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (72/72, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C65A4C declared TTable (globals_final.tsv, construction-site typed);
'   0x00C59E0C = TClub class table + 0x60 = TClub.SelectById(i):TClub;
'   0x00C65C4C = TScreen_ContinentalComps class table + 0x44 = sibling Function RefreshQualifiers();
'   TClub field at 0x6C is `continentalcompid:Int`; FUN_004A7130 = _bbStringToInt.
'!Global g_cc_tableclubs:TTable
	Function ButtonRemoveClub()
		Local c:TClub = TClub.SelectById(Int(g_cc_tableclubs.GetSelectedText(0)))
		If c <> Null
			c.continentalcompid = 0
			RefreshQualifiers()
		EndIf
	End Function
