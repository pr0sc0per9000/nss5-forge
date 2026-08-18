' TClub.GetActualLeagueId
' VA 0x004C15BE   316 bytes   mode=reloc   byte-identical vs NSS5.exe (316/316)
' KIND=Method, SIG ()i, slot 0x68
' ASSUMPTIONS
'   0x00C6099C -> g_competitions:TList  (slot 0x8C = ObjectEnumerator; the same address is
'     already declared TList by TCompetition.ChangeId / TClub.CheckStadiumSizeAll)
'   TCompetition.teampool is []:TTeamPool -- the middle loop walks a BBArray (data +0x18,
'     size +0x10), not a TList.
'   Field offsets from object_model.json: TCompetition comptype +0x24, locale +0x18,
'     id +0x08, teampool +0x6C; TTeamPool.list +0x08; TTableData.teamid +0x0C;
'     TClub(TBase_Team).id +0x0C; TClub.leagueid +0x68.
'   The two comptype tests are an Or inside one If, gated by And locale = 0 -- Ghidra's
'     bVar8/bVar9 cascade is exactly that short-circuit.
'!Global g_competitions:TList
Local lid:Int = Self.leagueid
For Local c:TCompetition = EachIn g_competitions
	If (c.comptype = 0 Or c.comptype = 4) And c.locale = 0
		For Local tp:TTeamPool = EachIn c.teampool
			For Local td:TTableData = EachIn tp.list
				If td.teamid = Self.id Then lid = c.id
			Next
		Next
	EndIf
Next
Return lid
