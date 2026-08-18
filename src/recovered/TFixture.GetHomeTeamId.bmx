' TFixture.GetHomeTeamId
' VA 0x004C5009   82 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (82/82, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C6160C = TCompetition + 0x4C (SelectById(i):TCompetition).
' c.teampool is TCompetition +0x6C ([]:TTeamPool); TTeamPool + 0x48 = GetItemById(i):TTableData;
' TTableData.teamid is +0x0C.
	Method GetHomeTeamId:Int()
		Local c:TCompetition = TCompetition.SelectById(Self.compid)
		If c <> Null Then
			Local tp:TTeamPool = c.teampool[Self.groupno - 1]
			If tp <> Null Then
				Local td:TTableData = tp.GetItemById(Self.hometeam)
				If td <> Null Then Return td.teamid
			End If
		End If
		Return 0
	End Method
