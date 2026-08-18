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
		'!Global g_contractoffer_tplayer:TProfile
		'!Global g_stats_comboclub:TCombo
		LogLine("TScreen_SeasonReview.ButtonPlay")
		LogLine("My Age:" + g_contractoffer_tplayer.GetAge())
		LogLine("Year:" + g_contractoffer_tplayer.date.GetYear())
		If g_contractoffer_tplayer.transferlisted = 4 Then g_contractoffer_tplayer.CancelLoan()
		If g_contractoffer_tplayer.date.GetYear() > 20
			Local ok:Int = 1
			For Local n:Int = EachIn g_contractoffer_tplayer.achievements
				If n = 0 Then ok = 0
			Next
			If ok
				TScreen.DoMessage(GetText("CMESSAGE_RETIREMENTLEGEND").Replace("$playername", g_contractoffer_tplayer.GetOriginalName()), 0, 0)
			Else
				TScreen.DoMessage(GetText("CMESSAGE_RETIREMENT"), 0, 0)
			End If
			g_contractoffer_tplayer.retired = 1
			g_contractoffer_tplayer.SaveGame("")
			g_contractoffer_tplayer.transferlisted = 0
			TScreen_Stats.SetUpScreen()
			g_stats_comboclub.SelectItemById(0)
			TScreen_Stats.ComboClub()
			Return 0
		End If
		TCompetition.SetUpCompetitionsAll()
		TScreen_GameMenu.UpdateNavPanel()
		g_contractoffer_tplayer.CreateNewClubStats(g_contractoffer_tplayer.myclub.id)
		g_contractoffer_tplayer.CreateNewInternationalStats()
		g_contractoffer_tplayer.UpdateEnergy(100.0)
		g_contractoffer_tplayer.injury = 0
		g_contractoffer_tplayer.currentyellowsclub = 0
		g_contractoffer_tplayer.currentyellowscontinent = 0
		If g_contractoffer_tplayer.date.GetYear() Mod 2 = 1
			g_contractoffer_tplayer.currentyellowsinternational = 0
		End If
		If g_contractoffer_tplayer.date.GetYear() = 2
			TScreen.DoMessage(GetText("CMESSAGE_HISTORYBUTTON"), 0, 0)
		End If
		If g_contractoffer_tplayer.GetAge() >= 30
			If g_contractoffer_tplayer.GetAge() = 30
				TScreen.DoMessage(GetText("CMESSAGE_GETTINGOLD"), 0, 0)
			End If
			Local cap:Int = g_contractoffer_tplayer.GetPaceCap()
			If g_contractoffer_tplayer.pace > cap
				g_contractoffer_tplayer.SetAbility(1, cap)
			End If
			If g_contractoffer_tplayer.dribbling > cap
				g_contractoffer_tplayer.SetAbility(2, cap)
			End If
		End If
		If g_contractoffer_tplayer.date.GetYear() = 20
			TScreen.DoMessage(GetText("CMESSAGE_LASTSEASON"), 0, 0)
		End If
		TScreen_Leagues.SetUpScreen(0)
	End Function
