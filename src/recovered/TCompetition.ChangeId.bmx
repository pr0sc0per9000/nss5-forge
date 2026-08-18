' TCompetition.ChangeId
' VA 0x0050d310   392 bytes
' byte-identical vs NSS5.exe (392/392, original length from Ghidra's inventory, mode=reloc, 19 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Method (i)i, vtable slot 0xb4.
' ASSUMPTIONS: two string literals masked. Globals 0x00C6099C:TList (competitions),
' 0x00C59A44:TList (clubs).
' NOTE the EXPLICIT `TCompetition.SelectById` prefix -- see the report; the bare form costs
' 2 extra bytes inside a Method.
'!Global g_competitions:TList
'!Global g_clubs:TList
If TCompetition.SelectById(a0) <> Null
	TScreen.DoMessage(GetText("CMESSAGE_NEWCOMPIDEXISTS").Replace("$id", String(a0)), 0, 0)
	Return 0
End If
For Local c:TCompetition = EachIn g_competitions
	For Local pp:TPromotionPlace = EachIn c.lpromotionplaces
		If pp.parentid = Self.id Then pp.parentid = a0
		If pp.promotiontoid = Self.id Then pp.promotiontoid = a0
	Next
Next
For Local cl:TClub = EachIn g_clubs
	If cl.leagueid = Self.id Then cl.leagueid = a0
	If cl.continentalcompid = Self.id Then cl.continentalcompid = a0
Next
Self.id = a0
Return 1
