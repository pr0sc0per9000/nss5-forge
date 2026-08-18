' TScreen_TestTournaments.CheckGroups
' VA 0x00539020   188 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (188/188, original length from Ghidra's inventory)
' assumes: TButton and TCompetition Globals; 'If Not g' (21-byte form) not 'g = Null' - 188 vs 179; TCompetition field +0x40 = groups
	Function CheckGroups:Int()
		'!Global g_btn_group:TButton
		'!Global g_comp:TCompetition
		'!Global g_groupno:Int
		g_btn_group.SetText(GetText("Group"), "", -1, -1)
		If Not g_comp
			g_groupno = 1
		Else
			ClampInt(Varptr g_groupno, 1, g_comp.groups)
			g_btn_group.SetText(GetText("Group") + " " + g_groupno, "", -1, -1)
		EndIf
	End Function
