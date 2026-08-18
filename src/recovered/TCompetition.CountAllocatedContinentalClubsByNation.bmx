' TCompetition.CountAllocatedContinentalClubsByNation
' VA 0x0050E236   137 bytes   vtable slot 0xFC   sig (i)i
' byte-identical vs NSS5.exe (137/137, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C59A44 is the club TList; EachIn downcast class table is TClub (0x00C59DAC).
' TClub.nationid = +0x64, TClub.continentalcompid = +0x6C, TCompetition.id = +0x08.
' No explicit null test: EachIn supplies it.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_clubs:TList
	Method CountAllocatedContinentalClubsByNation:Int(a0:Int)
		'!Global g_clubs:TList
		Local n:Int = 0
		For Local c:TClub = EachIn g_clubs
			If c.nationid = a0 And c.continentalcompid = Self.id Then n = n + 1
		Next
		Return n
	End Method
