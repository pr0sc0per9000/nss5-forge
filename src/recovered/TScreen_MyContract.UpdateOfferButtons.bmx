' TScreen_MyContract.UpdateOfferButtons
' VA 0x00556291   984 bytes   vtable slot 0x68   sig ()i
' byte-identical vs NSS5.exe (984/984, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_mycontract_arr:TButton[]  (0x00c67dc0; only TGadget slots 0x54/0x58/0x64/0x6c are used, so TLabel[] would emit the same bytes)
' assumes module global:  Global g_Object575:TLabel                (0x00c67db0)
' assumes module global:  Global g_contractoffer_tplayer:TProfile  (0x00c6f028)
' The three empty Case bodies (0/3/4) are real: bcc emits one jmp each (EB 04 / EB 02 / EB 00).

	Function UpdateOfferButtons:Int()
		'!Global g_screen_mycontract_arr:TButton[]
		'!Global g_Object575:TLabel
		'!Global g_profile:TProfile
		LogLine("UpdateOfferButtons")
		For Local i:Int = 0 To 4
			g_screen_mycontract_arr[i].Hide()
		Next
		If g_profile.transferlisted = 4
			Local ds:String = TMyDate.Create(g_profile.loanexpires,1,1).GetString("WW")
			g_Object575.SetText(GetText("transfer_OnLoanUntil").Replace("$date",ds),"",-1,-1)
			Return 0
		EndIf
		If g_profile.transferlisted = 3
			Local n:Int = 0
			For Local c:TClub = EachIn TContractOffer.GetClubsInterestedInLoan()
				g_screen_mycontract_arr[n].SetText(c.tla,"",-1,-1)
				g_screen_mycontract_arr[n].SetColour(c.GetPrimaryColour(),"FFFFFF")
				g_screen_mycontract_arr[n].Show()
				n = n + 1
			Next
			If n = 0
				g_Object575.SetText(GetText("transfer_NoLoanOffers"),"",-1,-1)
			Else
				g_Object575.SetText(GetText("transfer_CurrentOffers"),"",-1,-1)
			EndIf
		Else
			If TContractOffer.TransferWindowOpen()
				Local slot:Int = 0
				Select g_profile.transferlisted
				Case 0
				Case 3
				Case 4
				Default
					For Local i:Int = 0 To 4
						If g_profile.interestedclubs[i] > 0
							Local c:TClub = TClub.SelectById(g_profile.interestedclubs[i])
							If c <> Null
								g_screen_mycontract_arr[slot].SetText(c.tla,"",-1,-1)
								g_screen_mycontract_arr[slot].SetColour(c.GetPrimaryColour(),"FFFFFF")
								g_screen_mycontract_arr[slot].Show()
								slot = slot + 1
							EndIf
						EndIf
					Next
				End Select
				Local found:Int = 0
				For Local j:Int = 0 To 4
					If g_profile.interestedclubs[j] > 0 Then found = 1
				Next
				g_Object575.SetText(GetText("transfer_NoOffers"),"",-1,-1)
				If found
					g_Object575.SetText(GetText("transfer_CurrentOffers"),"",-1,-1)
					If g_profile.transferlisted = 0
						g_Object575.SetText(GetText("transfer_OffersNotListed"),"",-1,-1)
					EndIf
				EndIf
			Else
				Local nw:Int = 26
				If g_profile.date.GetWeek() > 32 Then nw = 1
				g_Object575.SetText(GetText("transfer_OffersWindowOpens").Replace("$num",nw),"",-1,-1)
			EndIf
		EndIf
	End Function
