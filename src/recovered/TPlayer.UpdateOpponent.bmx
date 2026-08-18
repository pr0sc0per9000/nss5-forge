' TPlayer.UpdateOpponent
' VA 0x004EF9CC   346 bytes
' byte-identical vs NSS5.exe (346/346, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_playerlist:TList
Self.opponentid = 0
Self.directiontoopponent = 0
Self.distancetoopponent = 0
For Local p:TPlayer = EachIn g_playerlist
	If p.matchstats.reds Or p.selectionno > 10 Then Continue
	If p.teamid <> Self.teamid
		Local dir:Int = Int(AngleTo(Self.x, Self.y, p.x, p.y))
		Local dist:Int = Int(Dist2D(Self.x, Self.y, p.x, p.y))
		If dist < Self.distancetoopponent Or Self.opponentid = 0
			Self.directiontoopponent = dir
			Self.distancetoopponent = dist
			Self.opponentid = p.id
		EndIf
	EndIf
Next
