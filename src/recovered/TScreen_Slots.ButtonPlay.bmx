' TScreen_Slots.ButtonPlay
' VA 0x00578120   97 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (97/97, original length from Ghidra's inventory)
' assumptions / Globals declared:
'   0x00c6c564 Int  (g_slotmachine_int01)
'   0x00c6f028 TProfile (globals_final, typed from construction site, high confidence) --
'              load-bearing: it selects slot 0x104 = TProfile.Bet(i)i
'   0x00c6b85c Int  (g_screen_blackjack_int01, the stake)
' 0x00c6b268 = TScreenMessage classtable+0x34 -> TScreenMessage.Count()i
' 0x00c6ba40 = TScreen_Casino+0x54 -> HideTitleButtons()
' 0x00c6c64c = TSlotMachine+0x40 -> Spin()
' 0x00c66914 = TScreen_GameMenu+0x38 -> UpdateTitlePanel()
' The short-circuit Or materialises via sete/movzx and the guard is an early return.
' Renamed g_contractoffer_tplayer -> g_profile. Same slot (0x00C6F028), same
' type (TProfile -- this file's typing was the CORRECT side of the conflict); the old
' name encoded the disproved TPlayer guess and split one Global into two in assembly.
' g_profile is what 6 other files already call 0x00C6F028.
	Function ButtonPlay:Int()
		'!Global g_slotmachine_int01:Int
		'!Global g_profile:TProfile
		'!Global g_screen_blackjack_int01:Int
		If g_slotmachine_int01 = 1 Or TScreenMessage.Count() Then Return 0
		If g_profile.Bet(g_screen_blackjack_int01)
			TScreen_Casino.HideTitleButtons()
			TSlotMachine.Spin()
			TScreen_GameMenu.UpdateTitlePanel()
		EndIf
	End Function
