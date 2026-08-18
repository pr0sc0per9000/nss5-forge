' TScreen_ContractOffer.ButtonReject
' VA 0x00554219   87 bytes   vtable slot 0x4C   sig ()i
' byte-identical vs NSS5.exe (87/87, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C6F028 is the TProfile module Global (globals_final: construction-typed, high confidence);
' field +0x1D0 is TProfile.myclub:TClub.
' 0x00C61CC0 = TScreen + 0x94 (DoMessage($,i,i)i). GetText is the recovered module Function.
' 0x00C67B8C is NOT a class-table slot: its static image value is 0x005B95D0 =
' _brl_blitz_NullFunctionError, so it is a FUNCTION-POINTER Global (an Int() callback).
' That matches TScreen_ContractOffer.SetUpScreen(:TContractOffer,()i,()i) taking two callbacks.
' The string literal at 0x00C8A160 is "CMESSAGE_FIRSTCONTRACTREJECT" (read out of .data).
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_offer_profile:TProfile
'   Global fReject:Int()
	Function ButtonReject:Int()
		'!Global fReject:Int()
		'!Global g_offer_profile:TProfile
		If Not g_offer_profile.myclub Then
			If TScreen.DoMessage(GetText("CMESSAGE_FIRSTCONTRACTREJECT"), 1, 0) Then
				fReject()
			End If
		Else
			fReject()
		End If
	End Function
