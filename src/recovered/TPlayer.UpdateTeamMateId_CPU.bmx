' TPlayer.UpdateTeamMateId_CPU
' VA 0x004ef8f8   212 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (212/212, original length from Ghidra's inventory)
' assumes: 0x00C5DE10 is the players TList. The third condition is a NESTED If, not a third And operand (212 vs 223); and 'p.passpotential > best' not 'best < p.passpotential' (cmp [edx+0x10c],esi / jle).
	Method UpdateTeamMateId_CPU:Int()
		'!Global g_players:TList
		Local best:Int = 0
		For Local p:TPlayer = EachIn g_players
			If p.matchstats.reds Or p.selectionno > 10 Then Continue
			If p.teamid = Self.teamid And p.selectionno < 11
				If p.passpotential > best
					Self.teammateid = p.id
					best = p.passpotential
				EndIf
			EndIf
		Next
	End Method
