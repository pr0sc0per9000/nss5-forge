' TCompetition.ValidatePromotionPlaces
' VA 0x0050ff5b   255 bytes   vtable slot 0x?   sig ()i
' byte-identical vs NSS5.exe (255/255, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C59E18 = TClub class table + 0x6C = SelectListByLeagueId(i):TList;
'   TList slots 0x38 IsEmpty, 0x70 Count, 0x8C ObjectEnumerator.
'   TPromotionPlace.place at +0xC. FUN_00505B91 = recovered module Function LogLine.
'   Two operand-order facts, each worth 2 bytes: the emptiness test is `l.IsEmpty() = 0`
'   (`cmp eax,0 / jne`), NOT `Not l.IsEmpty()`; and the second half of the And is
'   `pp.place > n` (`cmp eax,edi / setg`), NOT `n < pp.place`.
	Method ValidatePromotionPlaces()
		Local n:Int = 0
		Local l:TList = TClub.SelectListByLeagueId(Self.id)
		If l.IsEmpty() = 0 Then n = l.Count()
		For Local pp:TPromotionPlace = EachIn Self.lpromotionplaces
			If pp.place < 100 And pp.place > n
				LogLine("WARNING! Promotion place exceeds number of teams in competition: " + Self.id + " " + Self.name)
				Return 1
			End If
		Next
		Return 0
	End Method
