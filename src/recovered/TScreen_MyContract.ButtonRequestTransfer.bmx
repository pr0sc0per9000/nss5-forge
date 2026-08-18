' TScreen_MyContract.ButtonRequestTransfer
' VA 0x0055587A   612 bytes  mode=reloc  byte-identical vs NSS5.exe (612/612, original
' length from Ghidra's inventory, reloc_masked=47)
' KIND=Function (static method on TScreen_MyContract), SIG ()i, slot 0x4C
'
' ASSUMPTIONS (Global names are ours; the declared TYPE is load-bearing)
'  0x00C6F028 g_profile : TProfile      -- globals_final "TProfile (construction)".
'             Fields used: +0x134 transferlisted, +0x10 date:TMyDate, +0x74
'             contractexpires, +0x104 relationboss, +0x50 webheadline:String,
'             +0x1D0 myclub:TClub.  Slots: 0xC0 UpdateRelationship(i,i), 0x80
'             DoNews($,:TBase_Team,:TBase_Team,i,i)$.
'  0x00C67D90 g_mc_btn_reqtransfer : TButton      -- only +0x44 (TGadget.alph:Float) read.
'  0x00C67B34 g_mc_bar_relationboss : TProgressBar -- slot 0x8C SetPercent(f,i),
'             slot 0x6C SetColour($,$). TProgressBar (not TGadget) is required: TGadget
'             0x6C is SetColour too but 0x8C is not SetPercent.
'  Class-table statics: TScreen+0x94 DoMessage($,i,i)i, TContractOffer+0x50
'  TransferWindowOpen()i, TScreen_MyContract+0x44 UpdateTransferStatus()i,
'  TScreen_MyContract+0x68 UpdateOfferButtons()i.
'  Module Functions: 0x004C5549 GetText, 0x00507DC1 ColourGreen.
'  All literals read out of NSS5.exe with harness.read_string.
'
' NOTES ON FORM
'  The alph guard is an EARLY RETURN (`cmp/jne body/mov eax,0/jmp end`, guide 3f), not an
'  If-block wrapping the whole body -- the block form is 649 bytes.
'  BOTH dispatches are `Select`, not If/ElseIf (guide 10.2): the subject is loaded once
'  into eax and cases 0/3/4 compare back to back. Cases 3 and 4 have EMPTY bodies (each is
'  a bare 2-byte `jmp end` at 0x555A6F / 0x555A71) and must stay separate -- merging them
'  into `Case 3, 4` would give one shared target.
'  The inner `Select TContractOffer.TransferWindowOpen()` likewise has an empty `Case 1`.
	Function ButtonRequestTransfer:Int()
		'!Global g_profile:TProfile
		'!Global g_mc_btn_reqtransfer:TButton
		'!Global g_mc_bar_relationboss:TProgressBar
		If g_mc_btn_reqtransfer.alph < 1.0 Then Return 0
		Select g_profile.transferlisted
			Case 0
				If TScreen.DoMessage(GetText("CMESSAGE_REQUESTCONFIRM"), 1, 0)
					g_profile.transferlisted = 1
					g_profile.UpdateRelationship(1, -30)
					g_profile.webheadline = g_profile.DoNews(GetText("CNEWS_TRANSFERREQUEST"), g_profile.myclub, Null, 0, 0)
					Select TContractOffer.TransferWindowOpen()
						Case 1
						Case 0
							Local s:String = GetText("CMESSAGE_TRANSFERWINDOWCLOSEDNEXT")
							If g_profile.date.GetWeek() < 26
								s = s.Replace("$transdate", "26")
							Else
								s = s.Replace("$transdate", "1")
							EndIf
							TScreen.DoMessage(s, 0, 0)
					End Select
				EndIf
			Case 3
			Case 4
			Default
				If g_profile.date.sdate > g_profile.contractexpires
					TScreen.DoMessage(GetText("CMESSAGE_REQUESTNOTCANCELLEDCONTRACT"), 0, 0)
				ElseIf g_profile.relationboss > 60
					TScreen.DoMessage(GetText("CMESSAGE_REQUESTCANCELLED"), 0, 0)
					g_profile.transferlisted = 0
				Else
					TScreen.DoMessage(GetText("CMESSAGE_REQUESTNOTCANCELLED"), 0, 0)
				EndIf
		End Select
		TScreen_MyContract.UpdateTransferStatus()
		TScreen_MyContract.UpdateOfferButtons()
		g_mc_bar_relationboss.SetPercent(g_profile.relationboss, 0)
		g_mc_bar_relationboss.SetColour("", ColourGreen(g_profile.relationboss))
	End Function
