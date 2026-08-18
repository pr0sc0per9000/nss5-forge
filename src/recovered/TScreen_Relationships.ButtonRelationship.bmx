' TScreen_Relationships.ButtonRelationship
' VA 0x00540958   768 bytes  mode=reloc  byte-identical vs NSS5.exe (768/768)
' KIND=Function, SIG ()i, slot 0x38
' ASSUMPTIONS
'   0x00C6F028 g_profile:TProfile; slot 0x120 = TProfile.GotSponsor()i, and the Int fields
'     used are relationboss..relationsponsors (0x104..0x118), lastspendtimefriends (0x128),
'     lastspendtimegirlfriend (0x12C), energy (0x15C, Float), date:TMyDate (0x10, .sdate +8).
'   The six back-to-back _bbStringCompare calls whose targets all lie past the last compare
'     are a Select on TGadget.GetActiveGadgetName(), not an If/ElseIf chain.
'   The energy guard is `If Not (energy >= 20.0)`: bcc emits `setae` for the >= and then
'     INVERTS the branch for the Not (fucompp/setae/movzx/cmp/jne).  `energy < 20.0`
'     would emit setb with a je and is a different byte sequence.
'   `cmp [x],100 / jl skip` is `>= 100`, not Ghidra's printed `< 100`.
'   A `Return 0` at the end of a then-block suppresses the usual jmp-over-else, which is
'     why the boss/team/fans/friends cases are If-then-Return followed by the SetUpScreen
'     call at statement level rather than If/Else.
	Function ButtonRelationship:Int()
		'!Global g_profile:TProfile
		If Not (g_profile.energy >= 20.0)
			TScreen.DoMessage(GetText("CMESSAGE_NOMEETINGINGTIRED"), 0, 0)
			Return 0
		End If
		Select TGadget.GetActiveGadgetName()
			Case "btn_Boss"
				If g_profile.relationboss >= 100
					TScreen.DoMessage(GetText("CMESSAGE_RELATIONSHIPFULL"), 0, 0)
					Return 0
				End If
				TScreen_Pairs.SetUpScreen(1)
			Case "btn_Team"
				If g_profile.relationteam >= 100
					TScreen.DoMessage(GetText("CMESSAGE_RELATIONSHIPFULL"), 0, 0)
					Return 0
				End If
				TScreen_Pairs.SetUpScreen(2)
			Case "btn_Fans"
				If g_profile.relationfans >= 100
					TScreen.DoMessage(GetText("CMESSAGE_RELATIONSHIPFULL"), 0, 0)
					Return 0
				End If
				TScreen_Pairs.SetUpScreen(3)
			Case "btn_Friends"
				g_profile.lastspendtimefriends = g_profile.date.sdate
				If g_profile.relationfriends >= 100
					TScreen.DoMessage(GetText("CMESSAGE_RELATIONSHIPFULL"), 0, 0)
					Return 0
				End If
				TScreen_Pairs.SetUpScreen(4)
			Case "btn_Girlfriend"
				g_profile.lastspendtimegirlfriend = g_profile.date.sdate
				If g_profile.relationgirlfriend = 0
					TScreen.DoMessage(GetText("CMESSAGE_NOGIRLFRIEND"), 0, 0)
				Else
					If g_profile.relationgirlfriend >= 100
						TScreen.DoMessage(GetText("CMESSAGE_RELATIONSHIPFULL"), 0, 0)
						Return 0
					End If
					TScreen_Pairs.SetUpScreen(5)
				End If
			Case "btn_Sponsors"
				If g_profile.GotSponsor() = 0
					TScreen.DoMessage(GetText("CMESSAGE_NOSPONSORS"), 0, 0)
				Else
					If g_profile.relationsponsors >= 100
						TScreen.DoMessage(GetText("CMESSAGE_RELATIONSHIPFULL"), 0, 0)
						Return 0
					End If
					TScreen_Pairs.SetUpScreen(6)
				End If
		End Select
	End Function
