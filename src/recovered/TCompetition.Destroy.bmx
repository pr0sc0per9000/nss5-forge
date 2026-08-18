' TCompetition.Destroy
' VA 0x005091D9   266 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (266/266, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C6099C declared :TList (the global competition list).
' harness mode=reloc.

	Method Destroy:Int()
		'!Global g_competitions:TList
		lfixturelist.Clear()
		lpromotionplaces.Clear()
		lplacesthatpromotetome.Clear()
		g_competitions.Remove(Self)
		For Local c:TCompetition = EachIn g_competitions
			For Local p:TPromotionPlace = EachIn c.lpromotionplaces
				If p.promotiontoid = id Then c.lpromotionplaces.Remove(p)
			Next
		Next
	End Method
