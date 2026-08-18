' TCompetition.GetNoofTeamsInRound
' VA 0x0050CC87   650 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method (implicit Self at [ebp+8]), SIG ()i, class-table slot 0xA4
'
' ASSUMPTIONS
'   No module Globals are touched -- everything is Self's own fields or a class-table
'   static, so this file is self-contained by construction.
'   Fields: TCompetition +0x08 id, +0x0C name, +0x24 comptype, +0x40 groups, +0x44 rounds,
'   +0x68 lplacesthatpromotetome:TList.  TPromotionPlace +0x08 parentid, +0x0C place.
'   Class-table statics: 0x00C6160C TCompetition+0x4C SelectById, 0x00C59E20 TClub+0x74
'   CountTeamsInDivision, 0x00C59E24 TClub+0x78 CountTeamsInContinentalComps,
'   0x00C59E28 TClub+0x7C CountTeamsNotInContinentalComps.
'   0x005B40BF is the alias set CreateList|CreateMap|TGNetHost.Create; here it is a bare
'   `CreateList()` STATEMENT whose result is discarded (dead code in the original).
'
' MEASURED SHAPE
'   * `place` is a Select: every Case compare is emitted back to back before any body.
'   * The rounds halving loop is preceded by an explicit clamp Local -- `Local r = rounds
'     / If r < 1 Then r = 1 / For i = 1 To r`.  Writing `For i = 1 To rounds` directly is
'     exactly 10 bytes short (the `cmp ebx,1 / jge / mov ebx,1` clamp).
'   * `/ 2` on a signed Int emits cdq / and edx,1 / add / sar -- that is division, not a
'     shift written in source.
LogLine("GetNoofTeamsInRound: " + id + " " + name)
Local total:Int = 0
CreateList()
For Local pp:TPromotionPlace = EachIn lplacesthatpromotetome
	Local c:TCompetition = TCompetition.SelectById(pp.parentid)
	Select pp.place
		Case 100
			total :+ TClub.CountTeamsInDivision(pp.parentid)
			If c.comptype = 4
				For Local pp2:TPromotionPlace = EachIn c.lplacesthatpromotetome
					total :+ 1
				Next
			End If
		Case 101
			total :+ TClub.CountTeamsNotInContinentalComps(pp.parentid)
		Case 102
			total :+ 1
		Case 103
			total :+ TCompetition.SelectById(pp.parentid).GetNoofTeamsInRound() / 2
		Case 104
			total :+ TCompetition.SelectById(pp.parentid).GetNoofTeamsInRound() / 2
		Case 105
			total :+ 1
		Case 106
			total :+ 1
		Case 107
			total :+ TClub.CountTeamsInContinentalComps(pp.parentid)
		Case 108
			total :+ 1
		Default
			Local g:Int = c.groups
			If g < 1 Then g = 1
			total :+ g
	End Select
Next
If comptype = 1 And rounds > 1
	Local r:Int = rounds
	If r < 1 Then r = 1
	For Local i:Int = 1 To r
		total = total / 2
	Next
End If
LogLine(name + " TeamCount: " + total)
Return total
