' TCompetition.Test_UpdateNoofTeamsInLeagues
' VA 0x0050FC75   138 bytes
' byte-identical vs NSS5.exe (138/138, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_competitions:TList
LogLine("Test_UpdateNoofTeamsInLeagues")
For Local c:TCompetition = EachIn g_competitions
	If c.teampool Then
		c.tempNoofTeams = c.teampool[0].list.Count()
	End If
Next
