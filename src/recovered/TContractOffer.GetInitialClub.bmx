' TContractOffer.GetInitialClub
' VA 0x00572500   323 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_clubs:TList
TClub.SortListBy(11, 1)
For Local c:TClub = EachIn g_clubs
	Local comp:TCompetition = TCompetition.SelectById(c.leagueid)
	If Not comp Then Continue
	If comp.based <> a0 Then Continue
	If comp.duration < 10 Then Continue
	If Rand(6) > 1 Then Continue
	Return c
Next
For Local c:TClub = EachIn g_clubs
	Local comp:TCompetition = TCompetition.SelectById(c.leagueid)
	If Not comp Or comp.duration < 10 Then Continue
	Return c
Next
Return Null
