' TContractOffer.DoTransferRumour
' VA 0x005736DC   223 bytes
' byte-identical vs NSS5.exe (223/223, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile
Local club:TClub = Null
For Local i:Int = 0 To 4
	If g_profile.interestedclubs[i] > 0
		club = TClub.SelectById(g_profile.interestedclubs[i])
		If Rand(3) = 1 Then Exit
	End If
Next
If club <> Null
	g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_TRANSFERINTEREST" + Rand(10)), g_profile.myclub, club, 0, 0)
End If
