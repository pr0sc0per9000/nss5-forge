' TCompetition.SortPromotionPlaces
' VA 0x0050e9c6   73 bytes   vtable slot 0x114   sig ()i
' byte-identical vs NSS5.exe (73/73, original length from Ghidra's inventory)
' assumes module global at 0x00C64600 typed Int (TPromotionPlace sort key)
	Method SortPromotionPlaces:Int()
		'!Global g_ppsortby:Int
		g_ppsortby = 18
		lpromotionplaces.Sort()
		lplacesthatpromotetome.Sort()
	End Method
