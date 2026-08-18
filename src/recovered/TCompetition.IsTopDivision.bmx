' TCompetition.IsTopDivision
' VA 0x0050e417   211 bytes   vtable slot 0x104   sig ()i
' byte-identical vs NSS5.exe (211/211, original length from Ghidra's inventory)
' Slot 0x00c6160c = TCompetition+0x4c = SelectById
	Method IsTopDivision:Int()
		For Local p:TPromotionPlace = EachIn Self.lpromotionplaces
			If p.place = 1
				Local c:TCompetition = TCompetition.SelectById(p.promotiontoid)
				If c <> Null And c.based = Self.based And c.locale = 0 And (c.comptype = 0 Or c.comptype = 4)
					Return 0
				EndIf
			EndIf
		Next
		Return 1
	End Method
