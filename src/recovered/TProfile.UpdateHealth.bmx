' TProfile.UpdateHealth
' VA 0x0056B98B   461 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_player_int15:Int
'!Global g_bar_nrg:TProgressBar
'!Global g_bar_booze:TProgressBar
'!Global g_bar_injury:TProgressBar
LogLine("UpdateHealth")
Self.NRG = 0
If Self.drugs <> 99
	Self.drugs = 0
EndIf
Self.gambling = Self.gambling - 5
Self.injury = Self.injury - 1
Self.takenpainkillers = 0
If Self.matchskipped
	Self.UpdateEnergy(40.0)
Else
	Select g_player_int15
		Case 1
			Self.UpdateEnergy(80.0)
		Case 2
			Self.UpdateEnergy(65.0)
		Case 3
			Self.UpdateEnergy(50.0)
	End Select
EndIf
Self.boughtmusic = 0
Self.boughtgame = 0
Self.boughtfilm = 0
ClampInt(Varptr Self.NRG, 0, 100)
ClampInt(Varptr Self.booze, 0, 100)
ClampInt(Varptr Self.gambling, 0, 100)
ClampInt(Varptr Self.injury, 0, 10)
ClampInt(Varptr Self.drugs, 0, 100)
g_bar_nrg.SetPercent(Self.NRG, 1)
g_bar_booze.SetPercent(Self.booze, 1)
g_bar_injury.SetPercent(Self.injury * 10, 1)
THorse.DoHealthUpdate()
Self.CheckSponsorExpiry()
TScreen_GameMenu.UpdateTitlePanel()
