' TScreen_TestTournaments.CheckGroups
' VA 0x00539020   188 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (188/188, original length from Ghidra's inventory)
' assumes: TButton and TCompetition Globals; 'If Not g' (21-byte form) not 'g = Null' - 188 vs 179; TCompetition field +0x40 = groups
' NAME CHANGED 2026-10-11 (byte-neutral): 0x0053904A and 0x0053906B
' `a15464c600 mov eax,[0xc66454]` read this screen's competition, stored by
' TScreen_TestTournaments.SetUpScreen at 0x0053881A as g_tt_comp. g_comp is
' TScreen_Continents' competition, 0x00C67220.
	Function CheckGroups:Int()
		'!Global g_btn_group:TButton
		'!Global g_tt_comp:TCompetition
		'!Global g_groupno:Int
		g_btn_group.SetText(GetText("Group"), "", -1, -1)
		If Not g_tt_comp
			g_groupno = 1
		Else
			ClampInt(Varptr g_groupno, 1, g_tt_comp.groups)
			g_btn_group.SetText(GetText("Group") + " " + g_groupno, "", -1, -1)
		EndIf
	End Function
