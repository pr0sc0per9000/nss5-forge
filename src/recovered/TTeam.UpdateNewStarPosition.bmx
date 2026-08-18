' TTeam.UpdateNewStarPosition
' VA 0x004dde6a   246 bytes   vtable slot 0x58   sig (i)i
' byte-identical vs NSS5.exe (246/246, original length from Ghidra's inventory)
' No Globals. TPlayer.selectionno is +0xBC, TPlayer.newstar is +0x08, TTeam.squad +0x1C.
' The range test is an early-return guard (`Or` of the two out-of-range cases).
	Method UpdateNewStarPosition:Int(a0:Int)
		If Self.newstarselno > 10 Or Self.newstarselno < 0 Then Return 0
		For Local p:TPlayer = EachIn Self.squad
			If p.selectionno = a0 Then p.selectionno = Self.newstarselno
		Next
		Self.newstarselno = a0
		For Local p:TPlayer = EachIn Self.squad
			If p.newstar Then p.selectionno = Self.newstarselno
		Next
		Return 0
	End Method
