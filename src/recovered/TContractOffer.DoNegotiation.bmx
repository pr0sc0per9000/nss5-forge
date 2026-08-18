' TContractOffer.DoNegotiation
' VA 0x00571C1B   239 bytes
' byte-identical vs NSS5.exe (239/239, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile
If Self.negotiationsuccess Then
	TScreen.DoMessage(GetText("CMESSAGE_NONEGOTIATING").Replace("$clubname", Self.club.labelname), 0, 0)
	Return 1
End If
If Self.newbossrel < 40 Then
	If Self.club.id = g_profile.myclub.id Then
		TScreen.DoMessage(GetText("CMESSAGE_NONEGOTIATING").Replace("$clubname", Self.club.labelname), 0, 0)
		Return 1
	Else
		TScreen.DoMessage(GetText("CMESSAGE_NEGOTIATIONSCANCELLED").Replace("$clubname", Self.club.labelname), 0, 0)
		Self.newbossrel = 0
		Return 0
	End If
Else
	TScreen_Negotiate.SetUpScreen(Self)
	Return 1
End If
