' TFixture.GetAwayTeamId
' VA 0x004C505B   82 bytes   vtable slot 0x74   sig ()i
' byte-identical vs NSS5.exe (82/82, original length from Ghidra's inventory)
' Class-table pointer 0x00c6160c = TCompetition.SelectById.
	Method GetAwayTeamId()
		Local c:TCompetition = TCompetition.SelectById(compid)
		If c <> Null
			Local tp:TTeamPool = c.teampool[groupno-1]
			If tp <> Null
				Local td:TTableData = tp.GetItemById(awayteam)
				If td <> Null Then Return td.teamid
			EndIf
		EndIf
		Return 0
	End Method
