' TCompetition.IsCupFinal
' VA 0x0050E0B4   386 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
If Self.comptype <> 1 Then Return 0
LogLine("IsCupFinal:" + Self.tla)
If Not Self.lpromotionplaces Or Self.lpromotionplaces.IsEmpty() Then Return 1
For Local pp:TPromotionPlace = EachIn Self.lpromotionplaces
	Select Self.level
		Case 0
			Select Self.locale
				Case 0
					If TCompetition.SelectById(pp.promotiontoid).locale = 0 Then Return 0
				Case 1
					Local c:TCompetition = TCompetition.SelectById(pp.promotiontoid)
					If c <> Null
						If c.id = 555 Or Lower(c.tla) = "SUPER CUP" Then Return 1
						If c.locale = 1 Then Return 0
					End If
			End Select
		Case 1
			Return 0
	End Select
Next
Return 1
