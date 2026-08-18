' TScreen_MyContract.ButtonOffer
' VA 0x00556669   656 bytes  mode=reloc  byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x6C
' ASSUMPTIONS
'   0x00C6F028 g_profile:TProfile -- globals_final (construction); .transferlisted +0x134,
'              .date :TMyDate +0x10, .interestedclubs ([]i) +0x1A4; slot 0x140 = GoOnLoan(i)i
'   TMyDate.sdate +0x8; TMyDate slot 0x54 = GetYear, slot 0x30 = Create(i,i,i):TMyDate
'   TClub.id +0xC, .labelname +0x1C (TBase_Team)
'   TGadget slot 0x7C = GetActiveGadgetName()$, TScreen slot 0x94 = DoMessage($,i,i)i
' SHAPE NOTES (each measured, each worth several bytes)
'   * The btn_Offer0..4 chain is a SELECT, not If/ElseIf: the five _bbStringCompare tests are
'     back to back (19 bytes apart) with all five bodies emitted after the last one and a
'     trailing `jmp` for the no-match path (codegen-patterns 10.2).
'   * `If yr2 > yr` -- the original emits `cmp edi,esi / jle`; `If yr < yr2` is the same
'     meaning and different bytes.
'   * The DoMessage result is an If-block that FALLS THROUGH into a single `Return 0`;
'     spelled `If ... = 0 Then Return 0` it is 10 bytes long.
'   * `Local o:TContractOffer = TContractOffer.GetOffer(c)` -- the original calls GetOffer
'     BEFORE pushing the two SetUpScreen function pointers, i.e. a temporary existed
'     (codegen-patterns 16.2).  Nested it pushes the pointers first and diverges at 581.
	Function ButtonOffer:Int()
		'!Global g_profile:TProfile
		If g_profile.transferlisted = 3
			Local idx:Int = Int(TGadget.GetActiveGadgetName().Replace("btn_Offer", ""))
			Local n:Int = 0
			For Local c:TClub = EachIn TContractOffer.GetClubsInterestedInLoan()
				If idx = n
					Local yr:Int = g_profile.date.GetYear()
					Local yr2:Int = TMyDate.Create(g_profile.date.sdate + 182, 1, 1).GetYear()
					Local s:String = GetText("CMESSAGE_LOANOFFER").Replace("$clubname", c.labelname)
					If yr2 > yr
						s = GetText("CMESSAGE_LOANOFFERTOSEASONEND").Replace("$clubname", c.labelname)
					End If
					If TScreen.DoMessage(s, 1, 0) <> 0
						g_profile.GoOnLoan(c.id)
						TScreen_MyContract.SetUpScreen()
					End If
					Return 0
				End If
				n = n + 1
			Next
		Else
			Local id:Int = 0
			Select TGadget.GetActiveGadgetName()
				Case "btn_Offer0"
					id = g_profile.interestedclubs[0]
				Case "btn_Offer1"
					id = g_profile.interestedclubs[1]
				Case "btn_Offer2"
					id = g_profile.interestedclubs[2]
				Case "btn_Offer3"
					id = g_profile.interestedclubs[3]
				Case "btn_Offer4"
					id = g_profile.interestedclubs[4]
			End Select
			Local c:TClub = TClub.SelectById(id)
			If c <> Null
				If TContractOffer.CheckClubCanAffordPlayer(c) <> 0
					Local o:TContractOffer = TContractOffer.GetOffer(c)
					TScreen_ContractOffer.SetUpScreen(o, TScreen_MyContract.SetUpScreen, TScreen_MyContract.SetUpScreen)
				Else
					TScreen.DoMessage(GetText("CMESSAGE_TRANSFERCLUBCANNOTAFFORDYOU"), 0, 0)
				End If
			End If
		End If
	End Function
