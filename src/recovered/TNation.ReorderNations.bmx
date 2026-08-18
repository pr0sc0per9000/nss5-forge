' TNation.ReorderNations
' VA 0x004BEF0D   788 bytes   vtable slot 0x6C   sig ()i
' byte-identical vs NSS5.exe (788/788, original length from Ghidra's inventory, mode=reloc)
'
' Twin of TCompetition.ReorderCompetitions (0x0050E4EA): ids are renumbered through a
' negative temporary space so a rewrite cannot collide with an id not yet visited, then
' Abs() restores them.
' 0x00C59A40 = TNation + 0x78 = SortListBy(i,i). 0x004A7F60 is the Int Abs helper.
' TBase_Team + 0xC = id, +0x28/+0x2C/+0x30 = rivalid1..3; TClub + 0x64 = nationid;
' TCompetition + 0x18 = locale, + 0x20 = based.
' The `c.locale = 0 And c.based = nat.id` pair is a short-circuit And, matching the
' decompiler's two-step bVar7.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_nations:TList   (0x00C596F0)
'   Global g_clubs:TList     (0x00C59A44)
'   Global g_comps:TList     (0x00C6099C)
	Function ReorderNations:Int()
		'!Global g_nations:TList
		'!Global g_clubs:TList
		'!Global g_comps:TList
		LogLine("ReorderNations")
		TNation.SortListBy(2, 1)
		Local n:Int = -1
		For Local nat:TNation = EachIn g_nations
			For Local n2:TNation = EachIn g_nations
				If n2.rivalid1 = nat.id Then n2.rivalid1 = n
				If n2.rivalid2 = nat.id Then n2.rivalid2 = n
				If n2.rivalid3 = nat.id Then n2.rivalid3 = n
			Next
			For Local cl:TClub = EachIn g_clubs
				If cl.nationid = nat.id Then cl.nationid = n
			Next
			For Local c:TCompetition = EachIn g_comps
				If c.locale = 0 And c.based = nat.id Then c.based = n
			Next
			nat.id = n
			n = n - 1
		Next
		For Local nat:TNation = EachIn g_nations
			nat.id = Abs(nat.id)
			nat.rivalid1 = Abs(nat.rivalid1)
			nat.rivalid2 = Abs(nat.rivalid2)
			nat.rivalid3 = Abs(nat.rivalid3)
		Next
		For Local cl:TClub = EachIn g_clubs
			cl.nationid = Abs(cl.nationid)
		Next
		For Local c:TCompetition = EachIn g_comps
			If c.locale = 0 Then c.based = Abs(c.based)
		Next
	End Function
