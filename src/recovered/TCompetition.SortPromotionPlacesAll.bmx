' TCompetition.SortPromotionPlacesAll
' VA 0x0050E966   96 bytes   vtable slot 0x110   sig ()i
' byte-identical vs NSS5.exe (96/96, original length from Ghidra's inventory)
' ASSUMPTION: Global 0x00c6099c declared :TList; element type TCompetition from class table 0x00c615c0; slot 0x114 = TCompetition.SortPromotionPlaces
	Function SortPromotionPlacesAll:Int()
		'!Global g_competitions:TList
		For Local c:TCompetition = EachIn g_competitions
			c.SortPromotionPlaces()
		Next
	End Function
