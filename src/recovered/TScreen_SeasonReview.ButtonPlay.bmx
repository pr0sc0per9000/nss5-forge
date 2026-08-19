' TScreen_SeasonReview.ButtonPlay
' VA 0x00560796   849 bytes   vtable slot 0x40   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (849/849, original length from Ghidra's inventory, mode=reloc)
' assumptions:
'   0x00C6F028 g_contractoffer_tplayer:TProfile;  0x00C679C8 :TCombo (the stats screen's
'   club combo -- slot 0xB0 = TCombo.SelectItemById(i))
'   TProfile +0x10 date:TMyDate (slot 0x54 = GetYear), +0x3C retired, +0xA4 pace,
'     +0xB8 dribbling, +0x134 transferlisted, +0x16C injury, +0x18C currentyellowsclub,
'     +0x190 currentyellowscontinent, +0x194 currentyellowsinternational,
'     +0x1BC achievements ([]i), +0x1D0 myclub:TClub
'   TProfile slots 0x40 SaveGame, 0x4C CreateNewClubStats, 0x50 CreateNewInternationalStats,
'     0xA0 GetAge, 0xAC SetAbility, 0x100 UpdateEnergy, 0x130 GetPaceCap, 0x144 CancelLoan,
'     0x160 GetOriginalName
' The retirement arm ends in an explicit `Return 0` (mov eax,0 / jmp epilogue), so the
' year test is an early-return If-block, not If/Else.
' The achievements scan is `For n:Int = EachIn <array>` -- the pointer walk over
' data(+0x18) .. data+size(+0x10) is the array EachIn form, not an index loop.
	Function ButtonPlay:Int()
		'!Global g_profile:TProfile
		'!Global g_stats_comboclub:TCombo
		LogLine("TScreen_SeasonReview.ButtonPlay")
		LogLine("My Age:" + g_profile.GetAge())
		LogLine("Year:" + g_profile.date.GetYear())
		If g_profile.transferlisted = 4 Then g_profile.CancelLoan()
		If g_profile.date.GetYear() > 20
			Local ok:Int = 1
			For Local n:Int = EachIn g_profile.achievements
				If n = 0 Then ok = 0
			Next
			If ok
				TScreen.DoMessage(GetText("CMESSAGE_RETIREMENTLEGEND").Replace("$playername", g_profile.GetOriginalName()), 0, 0)
			Else
				TScreen.DoMessage(GetText("CMESSAGE_RETIREMENT"), 0, 0)
			End If
			g_profile.retired = 1
			g_profile.SaveGame("")
			g_profile.transferlisted = 0
			TScreen_Stats.SetUpScreen()
			g_stats_comboclub.SelectItemById(0)
			TScreen_Stats.ComboClub()
			Return 0
		End If
		TCompetition.SetUpCompetitionsAll()
		TScreen_GameMenu.UpdateNavPanel()
		g_profile.CreateNewClubStats(g_profile.myclub.id)
		g_profile.CreateNewInternationalStats()
		g_profile.UpdateEnergy(100.0)
		g_profile.injury = 0
		g_profile.currentyellowsclub = 0
		g_profile.currentyellowscontinent = 0
		If g_profile.date.GetYear() Mod 2 = 1
			g_profile.currentyellowsinternational = 0
		End If
		If g_profile.date.GetYear() = 2
			TScreen.DoMessage(GetText("CMESSAGE_HISTORYBUTTON"), 0, 0)
		End If
		If g_profile.GetAge() >= 30
			If g_profile.GetAge() = 30
				TScreen.DoMessage(GetText("CMESSAGE_GETTINGOLD"), 0, 0)
			End If
			Local cap:Int = g_profile.GetPaceCap()
			If g_profile.pace > cap
				g_profile.SetAbility(1, cap)
			End If
			If g_profile.dribbling > cap
				g_profile.SetAbility(2, cap)
			End If
		End If
		If g_profile.date.GetYear() = 20
			TScreen.DoMessage(GetText("CMESSAGE_LASTSEASON"), 0, 0)
		End If
		TScreen_Leagues.SetUpScreen(0)
	End Function
