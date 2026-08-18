' TFixture.GetWinningTeamTableId
' VA 0x004C4DD7   394 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (394/394, original length from Ghidra's inventory)
' oracle mode 'exact'.
' Select, not If/ElseIf: matchtype is loaded once into a register.
' Cases 1, 2 and 4 are genuinely identical duplicated bodies in the original.
' Local declaration order matters: s1 lands at [ebp-4] and s2 at [ebp-8], and
' the virtual call is GetFirstLegScore(Varptr s1, Varptr s2).
' The aggregate tests really do put the s1 term first and the doubling on
' score2 / s2 as written -- 'shl eax,1' on each side confirms it.
	Method GetWinningTeamTableId:Int()
		Select matchtype
			Case 1
				If score1 > score2 Then Return hometeam
				If score1 < score2 Then Return awayteam
			Case 2
				If score1 > score2 Then Return hometeam
				If score1 < score2 Then Return awayteam
			Case 3
				If score1 > score2 Then Return hometeam
				If score1 < score2 Then Return awayteam
				If penscore1 > penscore2 Then Return hometeam
				Return awayteam
			Case 4
				If score1 > score2 Then Return hometeam
				If score1 < score2 Then Return awayteam
			Case 5
				If penscore1 > penscore2 Then Return hometeam
				If penscore1 < penscore2 Then Return awayteam
				Local s1:Int = 0
				Local s2:Int = 0
				GetFirstLegScore(Varptr s1, Varptr s2)
				If s1 + score2 > s2 + score1 Then Return awayteam
				If s1 + score2 < s2 + score1 Then Return hometeam
				If s1 + score2 * 2 > s2 * 2 + score1 Then Return awayteam
				If s1 + score2 * 2 < s2 * 2 + score1 Then Return hometeam
				Return hometeam
		End Select
	End Method
