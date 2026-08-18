' TCompetition.GetCupNextRound
' VA 0x0050d9c2   146 bytes
' byte-identical vs NSS5.exe (146/146, original length from Ghidra's inventory, mode=reloc, 3 masked)
' Body-only format: statements only; parameters are a0, a1, ...
' Method ():TCompetition, vtable slot 0xe4.
' ASSUMPTIONS: Global at 0x00C6099C is not used here; the loop walks Self.lpromotionplaces.
' The literal 103 is TPromotionPlace.place; SelectById reached via Self's class table (KIND=Method
' calling a sibling Function with NO Type prefix -- that is what emits FF 50 4C).
For Local pp:TPromotionPlace = EachIn Self.lpromotionplaces
	If pp.place = 103
		Local c:TCompetition = SelectById(pp.promotiontoid)
		If c.comptype = 1 Or c.groups > 1
			Return c
		EndIf
	EndIf
Next
Return Self
