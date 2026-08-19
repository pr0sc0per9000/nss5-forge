' TScreen_BlackJack.ButtonPlay
' VA 0x005768c8   161 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (161/161, original length from Ghidra's inventory)
' assumes module global:  Global g_contractoffer_tplayer:TProfile   (0x00c6f028, slot 0x104 = TProfile.Bet)
' assumes module global:  Global g_screen_blackjack_int01:Int       (0x00c6b85c)
' assumes module global:  Global g_Object729:TPanel                 (0x00c6b858)
' assumes module global:  Global g_Object752:TScreen                (0x00c6c018)
' assumes module globals: g_Object753/754/755/756:TButton           (0x00c6c01c..0x00c6c028)

	Function ButtonPlay:Int()
		'!Global g_profile:TProfile
		' g_screen_blackjack_int01's original data-section value is 50 (read from
		' NSS5.exe at 0x00C6B85C -- codegen-patterns 21.1/21.3). Two other files alias this
		' SAME address under different names (g_bj_bet in TBlackJack.ShowResult.bmx, g_bet in
		' TScreen_BlackJack.Win.bmx) and each needs its own initialiser too -- merge_globals
		' dedups by name, not address.
		'!Global g_screen_blackjack_int01:Int = 50
		'!Global g_Object729:TPanel
		'!Global g_Object752:TScreen
		'!Global g_Object753:TButton
		'!Global g_Object754:TButton
		'!Global g_Object755:TButton
		'!Global g_Object756:TButton
		If g_profile.Bet(g_screen_blackjack_int01) = 0 Then Return 0
		TScreen_Casino.HideTitleButtons()
		g_Object753.Hide()
		g_Object756.Hide()
		g_Object729.Hide()
		g_Object754.Show()
		g_Object755.Show()
		g_Object752.SetActiveGadget("btn_hit")
		TScreen_GameMenu.UpdateTitlePanel()
		TScreen_BlackJack.UpdateScoreLabels()
		TBlackJack.Play()
	End Function
