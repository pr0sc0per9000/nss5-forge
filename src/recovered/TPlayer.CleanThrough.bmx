' TPlayer.CleanThrough
' VA 0x004F5510   226 bytes
' byte-identical vs NSS5.exe (226/226, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_players:TList
For Local p:TPlayer = EachIn g_players
	If p.selectionno <> 0 And p.teamid <> Self.teamid Then
		If p.distancetogoal_own < Self.distancetogoal_opp - TPitch.YardsToPixels(2.0) Then Return 0
	End If
Next
Return 1
