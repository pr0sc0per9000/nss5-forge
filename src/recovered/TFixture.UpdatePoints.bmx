' TFixture.UpdatePoints
' VA 0x004C4C0B   286 bytes
' byte-identical vs NSS5.exe (286/286, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
If Not a0 Or Not a1 Then
	Local tp:TTeamPool = TCompetition.SelectById(Self.compid).teampool[Self.groupno - 1]
	a0 = tp.GetItemById(Self.hometeam)
	a1 = tp.GetItemById(Self.awayteam)
End If
a0.played = a0.played + 1
a0.goalsf = a0.goalsf + Self.score1
a0.goalsa = a0.goalsa + Self.score2
If Self.score1 > Self.score2 Then
	a0.won = a0.won + 1
	a0.points = a0.points + 3
ElseIf Self.penscore1 > Self.penscore2 Then
	a0.won = a0.won + 1
	a0.points = a0.points + 3
ElseIf Self.score1 = Self.score2 Then
	a0.drawn = a0.drawn + 1
	a0.points = a0.points + 1
Else
	a0.lost = a0.lost + 1
End If
a1.played = a1.played + 1
a1.goalsf = a1.goalsf + Self.score2
a1.goalsa = a1.goalsa + Self.score1
If Self.score1 < Self.score2 Then
	a1.won = a1.won + 1
	a1.points = a1.points + 3
ElseIf Self.penscore1 < Self.penscore2 Then
	a1.won = a1.won + 1
	a1.points = a1.points + 3
ElseIf Self.score1 = Self.score2 Then
	a1.drawn = a1.drawn + 1
	a1.points = a1.points + 1
Else
	a1.lost = a1.lost + 1
End If
