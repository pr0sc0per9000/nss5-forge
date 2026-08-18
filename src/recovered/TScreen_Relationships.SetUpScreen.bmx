' TScreen_Relationships.SetUpScreen
' VA 0x00540590   968 bytes   vtable slot 0x34   sig (i)i   KIND=Function
' byte-identical vs NSS5.exe (968/968, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=80), verified with NSS5_NO_LEARN=1.
'
' Global names are ours; the TYPES are load-bearing:
'   0x00C6F028 g_profile:TProfile          0x00C66BA8..0x00C66BC0 TProgressBar (7)
'   0x00C66BC4..0x00C66BE4 TButton (9)
' `alph` is written as a plain field store (TGadget +0x44), not via SetAlph.
' helppages[14] comes from [profile+0x1C8]+0x50 -- BBArray data starts at +0x18, so
' (0x50-0x18)/4 = 14.  PlayTrack and ColourGreen are recovered module Functions.
'!Global g_profile:TProfile
'!Global g_rel_pb_boss:TProgressBar
'!Global g_rel_pb_team:TProgressBar
'!Global g_rel_pb_fans:TProgressBar
'!Global g_rel_pb_friends:TProgressBar
'!Global g_rel_pb_girlfriend:TProgressBar
'!Global g_rel_pb_sponsors:TProgressBar
'!Global g_rel_pb_happy:TProgressBar
'!Global g_rel_btn01:TButton
'!Global g_rel_btn02:TButton
'!Global g_rel_btn03:TButton
'!Global g_rel_btn04:TButton
'!Global g_rel_btn05:TButton
'!Global g_rel_btn06:TButton
'!Global g_rel_btn07:TButton
'!Global g_rel_btn08:TButton
'!Global g_rel_btn09:TButton
TScreen.SetActive("relationships", "")
PlayTrack(2)
g_rel_pb_boss.SetPercent(g_profile.relationboss, a0)
g_rel_pb_boss.SetColour("", ColourGreen(g_profile.relationboss))
g_rel_pb_team.SetPercent(g_profile.relationteam, a0)
g_rel_pb_team.SetColour("", ColourGreen(g_profile.relationteam))
g_rel_pb_fans.SetPercent(g_profile.relationfans, a0)
g_rel_pb_fans.SetColour("", ColourGreen(g_profile.relationfans))
g_rel_pb_friends.SetPercent(g_profile.relationfriends, a0)
g_rel_pb_friends.SetColour("", ColourGreen(g_profile.relationfriends))
g_rel_pb_girlfriend.SetPercent(g_profile.relationgirlfriend, a0)
g_rel_pb_girlfriend.SetColour("", ColourGreen(g_profile.relationgirlfriend))
g_rel_pb_sponsors.SetPercent(g_profile.relationsponsors, a0)
g_rel_pb_sponsors.SetColour("", ColourGreen(g_profile.relationsponsors))
g_rel_pb_happy.SetPercent(g_profile.GetHappiness(), a0)
g_rel_pb_happy.SetColour("", ColourGreen(g_profile.GetHappiness()))
g_rel_btn01.alph = 0.5
g_rel_btn02.alph = 0.5
g_rel_btn03.alph = 0.5
g_rel_btn04.alph = 0.5
g_rel_btn05.alph = 0.5
g_rel_btn06.alph = 0.5
g_rel_btn07.alph = 0.5
g_rel_btn08.alph = 0.5
g_rel_btn09.alph = 0.5
If g_profile.energy >= 20.0
	g_rel_btn01.alph = 1.0
	g_rel_btn02.alph = 1.0
	g_rel_btn03.alph = 1.0
	g_rel_btn04.alph = 1.0
	g_rel_btn05.alph = 1.0
	g_rel_btn06.alph = 1.0
	If g_profile.relationgirlfriend > 0
		g_rel_btn07.alph = 1.0
		g_rel_btn08.alph = 1.0
	End If
	If g_profile.GotSponsor()
		g_rel_btn09.alph = 1.0
	End If
End If
If g_profile.helppages[14] = 0
	TScreen.Tutorial()
	g_profile.helppages[14] = 1
End If
