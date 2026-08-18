' TCompetition.ReorderCompetitions
' VA 0x0050E4EA   732 bytes   vtable slot 0x108   sig ()i
' byte-identical vs NSS5.exe (732/732, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C616DC = TCompetition + 0x11C = SortListBy(i,i). EachIn downcast class tables are
' TCompetition (0x00C615C0), TClub (0x00C59DAC) and TPromotionPlace.
' 0x004A7F60 is the Int Abs helper bcc emits for Abs(x) -- 32 call sites in game code.
' Ids are negated to a temporary numbering so a renumber cannot collide with an id it has
' not visited yet, then Abs() restores them; every reference has to be rewritten in step.
' TCompetition + 0x64 = lpromotionplaces:TList, TPromotionPlace + 0x8/+0x10 = parentid /
' promotiontoid, TClub + 0x68/+0x6C = leagueid / continentalcompid.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_comps:TList   (0x00C6099C)
'   Global g_clubs:TList   (0x00C59A44)
	Function ReorderCompetitions:Int()
		'!Global g_comps:TList
		'!Global g_clubs:TList
		TCompetition.SortListBy(23, 1)
		Local n:Int = -1
		For Local c:TCompetition = EachIn g_comps
			For Local cl:TClub = EachIn g_clubs
				If cl.leagueid = c.id Then cl.leagueid = n
				If cl.continentalcompid = c.id Then cl.continentalcompid = n
			Next
			For Local c2:TCompetition = EachIn g_comps
				For Local pp:TPromotionPlace = EachIn c2.lpromotionplaces
					If pp.parentid = c.id Then pp.parentid = n
					If pp.promotiontoid = c.id Then pp.promotiontoid = n
				Next
			Next
			c.id = n
			n = n - 1
		Next
		For Local c:TCompetition = EachIn g_comps
			c.id = Abs(c.id)
			For Local pp:TPromotionPlace = EachIn c.lpromotionplaces
				pp.parentid = Abs(pp.parentid)
				pp.promotiontoid = Abs(pp.promotiontoid)
			Next
		Next
		For Local cl:TClub = EachIn g_clubs
			cl.leagueid = Abs(cl.leagueid)
			cl.continentalcompid = Abs(cl.continentalcompid)
		Next
	End Function
