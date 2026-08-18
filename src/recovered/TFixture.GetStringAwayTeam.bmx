' TFixture.GetStringAwayTeam
' VA 0x004c3141   138 bytes   vtable slot 0x40   sig ()$
' byte-identical vs NSS5.exe (138/138, original length from Ghidra's inventory, mode=reloc)
' Assumptions: FUN_004A7F60 = Abs(Int); FUN_004A7AC0 = _bbStringFromInt; FUN_004A7C20 = _bbStringConcat.
'   0x00C6160C = TCompetition class table + 0x4C = SelectById(i):TCompetition.
'   TTeamPool slot 0x48 = GetItemById(i):TTableData; TTableData.teamname at +0x10.
'   TCompetition.teampool is []:TTeamPool -- the +0x18 in the decompilation is the BBArray
'   data offset. Literals read out of .data: "Team" at 0x00C70D78 and " " at 0x00C6EF28
'   VERIFIED: harness.read_string confirms "Team" @0x00C70D78 and " " @0x00C6EF28
'   exactly, so despite the stale wording above these were never wrong -- no change needed.
	Method GetStringAwayTeam:String()
		Local s:String = GetText("Team")+" "+String(Abs(awayteam))
		Local c:TCompetition = TCompetition.SelectById(compid)
		If c <> Null
			Local tp:TTeamPool = c.teampool[groupno-1]
			If tp <> Null
				Local td:TTableData = tp.GetItemById(awayteam)
				If td <> Null Then s = td.teamname
			EndIf
		EndIf
		Return s
	End Method
