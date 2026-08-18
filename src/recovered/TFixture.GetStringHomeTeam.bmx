' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TFixture.GetStringHomeTeam
' VA 0x004c30b7   138 bytes   vtable slot 0x3c   sig ()$
' byte-identical vs NSS5.exe (138/138, original length from Ghidra's inventory)
' FUN_004A7F60 = Abs(Int) (branchless sar/xor/sub); FUN_004A7AC0 = _bbStringFromInt; FUN_004A7C20 = _bbStringConcat
' PTR_FUN_00c6160c = TCompetition slot 0x4C = SelectById(i):TCompetition
' TTeamPool slot 0x48 = GetItemById(i):TTableData; TTableData.teamname at +0x10
' TCompetition.teampool is []:TTeamPool -- the +0x18 in the decompilation is the BBArray data offset
	Method GetStringHomeTeam:String()
		Local s:String = GetText("Team")+" "+String(Abs(hometeam))
		Local c:TCompetition = TCompetition.SelectById(compid)
		If c <> Null
			Local tp:TTeamPool = c.teampool[groupno-1]
			If tp <> Null
				Local td:TTableData = tp.GetItemById(hometeam)
				If td <> Null Then s = td.teamname
			EndIf
		EndIf
		Return s
	End Method
