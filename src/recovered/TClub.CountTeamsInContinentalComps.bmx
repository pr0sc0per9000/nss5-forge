' TClub.CountTeamsInContinentalComps
' VA 0x004c184b   134 bytes   vtable slot 0x78   sig (i)i
' byte-identical vs NSS5.exe (134/134, original length from Ghidra's inventory)
' assumptions: module Global at 0x00C59A44 declared :TList (the club list -- the
' 0x8c/0x30/0x34 slot triple is TList.ObjectEnumerator / TListEnum.HasNext / NextObject).
' The downcast class table 0x00C59DAC is TClub + 0, so the loop variable is :TClub.
' Fields from object_model.json: TClub.leagueid +0x68, .continentalcompid +0x6c.
	Function CountTeamsInContinentalComps:Int(a0:Int)
		'!Global g_clublist:TList
		Local n:Int = 0
		For Local c:TClub = EachIn g_clublist
			If c.leagueid = a0 And c.continentalcompid > 0
				n = n + 1
			EndIf
		Next
		Return n
	End Function
