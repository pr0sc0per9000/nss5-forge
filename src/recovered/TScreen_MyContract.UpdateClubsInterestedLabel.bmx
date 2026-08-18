' TScreen_MyContract.UpdateClubsInterestedLabel
' VA 0x00554E1E   517 bytes  mode=reloc  byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x3C
' ASSUMPTIONS
'   0x00C67D9C g_label_clubsinterested:TLabel -- globals_final (construction); slot 0x64 =
'                                                TGadget.SetText($,$,i,i)
'   0x00C6F028 g_profile:TProfile -- globals_final (construction); .retired at +0x3C,
'              .transferlisted +0x134, .interestedclubs ([]i) +0x1A4, .myclub +0x1D0,
'              .desiredleagueid +0x140; slot 0x148 = TooSoonSinceLastContract()i
'   TClub.nationid +0x64, .leagueid +0x68, .labelshortname +0x20; TNation.id +0xC (TBase_Team),
'   .tla +0x18; TCompetition.tla +0x10.
'   The retired case is an EARLY RETURN, not the Else arm: the original emits
'   `cmp [eax+0x3c],0 / je` straight into the SetText, then `mov eax,0 / jmp epilogue`.
'   Written as If/Else it is 513 bytes instead of 517.
'   `s :+ ...` (not `s = s + ...`): each arm emits concat(label," (") ... then concat(s,_) last.
	Function UpdateClubsInterestedLabel:Int()
		'!Global g_label_clubsinterested:TLabel
		'!Global g_profile:TProfile
		LogLine("UpdateClubsInterestedLabel")
		If g_profile.retired <> 0
			g_label_clubsinterested.SetText(GetText("None"), "", -1, -1)
			Return 0
		End If
		If g_profile.transferlisted = 3 Then TScreen_MyContract.UpdateClubsInterestedLabelForLoan()
		Local s:String = ""
		For Local i:Int = 0 To 4
			If g_profile.interestedclubs[i] > 0
				If s <> "" Then s :+ ", "
				Local c:TClub = TClub.SelectById(g_profile.interestedclubs[i])
				Local n:TNation = TNation.SelectById(c.nationid)
				Local comp:TCompetition = TCompetition.SelectById(c.leagueid)
				If n.id = g_profile.myclub.nationid
					s :+ c.labelshortname + " (" + comp.tla + ")"
				Else
					s :+ c.labelshortname + " (" + n.tla + ")"
				End If
			End If
		Next
		If s = ""
			s = GetText("None")
			If g_profile.TooSoonSinceLastContract()
				s = GetText("transfer_NoClubsTooSoon")
			Else
				If g_profile.desiredleagueid > 0 Then s = GetText("transfer_NoClubsDesiredTransfer")
			End If
		End If
		g_label_clubsinterested.SetText(s, "", -1, -1)
	End Function
