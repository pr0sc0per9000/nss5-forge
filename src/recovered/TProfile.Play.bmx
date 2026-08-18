' TProfile.Play
' VA 0x00566397   386 bytes
' byte-identical vs NSS5.exe (386/386, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile
LogLine("Play:" + a0)
Local ended:Int = 0
Local done:Int
Repeat
	Self.date.AddDays(1)
	LogLine("Date:" + Self.date.sdate)
	If Self.myclub <> Null
		If Self.date.GetDay() = 1
			Self.UpdateFinances()
		End If
		If g_profile.GetFame() > Self.myclub.strength + 10
			Self.UpdateRelationship(7, -1)
		End If
		TContractOffer.CheckTransferWindow()
	End If
	done = TCompetition.PlayFixtures()
	If Self.date.sdate < a0 Then done = 0
	If Self.date.sdate = a0 Then done = 1
	If Self.date.GetWeek() = 1 And Self.date.GetDay() = 1 Then ended = 1
Until done Or ended
If ended And Self.myclub = Null
	TCompetition.SetUpCompetitionsAll()
End If
