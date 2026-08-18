' TCompetition.GetCupPreviousRound
' VA 0x0050d950   114 bytes   vtable slot 0xe0   sig ():TCompetition
' byte-identical vs NSS5.exe (114/114, original length from Ghidra's inventory)
' no globals assumed.  SelectById is called unqualified, which is what emits the
' dispatch through Self's own class table (call [[Self]+0x4c]) rather than the
' absolute TCompetition+0x4c slot a qualified TCompetition.SelectById() would use.
' 103 and 1 are literal constants in the original (0x67 / 1).

	Method GetCupPreviousRound:TCompetition()
		For Local p:TPromotionPlace = EachIn Self.lplacesthatpromotetome
			If p.place = 103
				Local c:TCompetition = SelectById(p.parentid)
				If c.comptype = 1 Then Return c
			EndIf
		Next
		Return Self
	End Method
