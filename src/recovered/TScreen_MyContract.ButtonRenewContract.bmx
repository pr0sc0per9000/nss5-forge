' TScreen_MyContract.ButtonRenewContract
' VA 0x00556154   317 bytes
' byte-identical vs NSS5.exe (317/317, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_profile:TProfile
If g_profile.retired <> 0
	TScreen.DoMessage(GetText("CMESSAGE_RETIRED"), 0, 0)
	Return 0
End If
If g_profile.relationboss < 50
	TScreen.DoMessage(GetText("CMESSAGE_NORENEWBOSSUNHAPPY"), 0, 0)
	Return 0
End If
If g_profile.date.sdate < g_profile.lasttransferdate + 168
	TScreen.DoMessage(GetText("CMESSAGE_NORENEWTOOSOON"), 0, 0)
	Return 0
End If
If g_profile.transferlisted = 3
	TScreen.DoMessage(GetText("CMESSAGE_NORENEWLOANLISTED"), 0, 0)
	Return 0
End If
If g_profile.transferlisted = 4
	TScreen.DoMessage(GetText("CMESSAGE_NORENEWONLOAN"), 0, 0)
	Return 0
End If
Local o:TContractOffer = TContractOffer.GetOffer(g_profile.myclub)
TScreen_ContractOffer.SetUpScreen(o, SetUpScreen, SetUpScreen)
