' TProfile.DeleteCorruptKoreanData
' VA 0x0056D367   348 bytes
' byte-identical vs NSS5.exe (348/348, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_complist:TList
For Local c:TCompetition = EachIn g_complist
	If c.locale = 0 And c.level = 0 And c.based = 102
		If c.id >= 4320 And c.id <= 4355
			g_complist.Remove(c)
		Else
			For Local p:TPromotionPlace = EachIn c.lpromotionplaces
				If p.promotiontoid >= 4320 And p.promotiontoid <= 4355
					c.lpromotionplaces.Remove(p)
				EndIf
			Next
		EndIf
	EndIf
Next
