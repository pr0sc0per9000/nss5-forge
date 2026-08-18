' TScreen_Roulette.ButtonPlay
' VA 0x00574ed6   71 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (71/71, original length from Ghidra's inventory)
' assumes module global:  Global g_profile:TProfile  (0x00c6f028)  -- slot 0x104 is TProfile.Bet(i)i
' the early-return form is load-bearing: the plain `If ... EndIf` form is 64 bytes,
' seven short, because the original emits a second `mov eax,0 / jmp epilogue`

	Function ButtonPlay:Int()
		'!Global g_profile:TProfile
		If Not g_profile.Bet(TScreen_Roulette.GetBetTotal()) Then Return 0
		TScreen_Casino.HideTitleButtons()
		TScreen_GameMenu.UpdateTitlePanel()
		TRoulette.Spin()
	End Function
