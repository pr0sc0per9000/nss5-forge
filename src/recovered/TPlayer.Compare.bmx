' TPlayer.Compare
' VA 0x0050379f   619 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (619/619, original length from Ghidra's inventory, mode=reloc)
' Assumption: module global at 0xc5de14 declared as Int under the name
' g_team_int03 (from globals_named.tsv); it is the player-sort mode.
' The trailing Super.Compare(a0) resolves to the runtime object-compare helper
' at 0x004a8e70; matched in 'reloc' mode (rel32 call operands masked).
'
' Verified from scratch with the '!Global pragma below -> MATCH
' 619/619, reloc_masked=24. A BUILD_FAIL without them is a harness limitation
' (it cannot bind a Global from prose alone), not a body defect.
	Method Compare:Int(a0:Object)
		'!Global g_team_int03:Int
		Select g_team_int03
			Case 1
				If id < TPlayer(a0).id Then Return -1
				If id > TPlayer(a0).id Then Return 1
			Case 9
				If selectionno < TPlayer(a0).selectionno Then Return -1
				If selectionno > TPlayer(a0).selectionno Then Return 1
			Case 10
				If distancetoball < TPlayer(a0).distancetoball Then Return -1
				If distancetoball > TPlayer(a0).distancetoball Then Return 1
			Case 12
				If distancetometaball < TPlayer(a0).distancetometaball Then Return -1
				If distancetometaball > TPlayer(a0).distancetometaball Then Return 1
			Case 13
				Local d1:Float = distancetoball
				Local d2:Float = TPlayer(a0).distancetoball
				If goalside = 0 Then d1 = d1 * 2.0
				If TPlayer(a0).goalside = 0 Then d2 = d2 * 2.0
				If d1 < d2 Then Return -1
				If d1 > d2 Then Return 1
		End Select
		Return Super.Compare(a0)
	End Method
