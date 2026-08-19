' TCompetition.SetUpCompetition
' byte-identical vs NSS5.exe
' VA 0x0050A94D   403 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
LogLine("SetUpCompetition: " + Self.name)
Self.CreateTeamPool()
Select Self.comptype
	Case 0
		Select Self.level
			Case 1
				If Self.lplacesthatpromotetome.IsEmpty() Then Self.PopulateTeamPool()
				Self.CreateFixtureListLeague()
			Case 0
				Select Self.locale
					Case 0
						Self.PopulateTeamPool()
						Self.CreateFixtureListLeague()
					Case 1
						Self.PopulateTeamPool()
						Self.CreateFixtureListLeague()
				End Select
		End Select
	Case 4
		Select Self.level
			Case 1
			Case 0
				Select Self.locale
					Case 0
						Self.CreateFixtureListLeague()
					Case 1
				End Select
		End Select
	Case 2
	Case 3
	Case 5
	Case 1
		Select Self.level
			Case 1
				If Self.lplacesthatpromotetome.IsEmpty() Then Self.PopulateTeamPool()
				Self.CreateFixtureListKO()
			Case 0
				Select Self.locale
					Case 0
						Self.PopulateTeamPool()
						Self.CreateFixtureListKO()
					Case 1
						Self.PopulateTeamPool()
						Self.CreateFixtureListKO()
				End Select
		End Select
End Select
If Self.startyear > 0
	Self.startyear :+ Self.recurring
End If
