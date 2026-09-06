' TScreen_Casino.SetUpScreen
' VA 0x0057424C   108 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C61C88 = TScreen + 0x5C = SetActive($,$); 0x00C61CE0 = TScreen + 0xB4 = Tutorial().
' 0x00C66914 = TScreen_GameMenu + 0x38 = UpdateTitlePanel(). 0x004BCB98 = module PlayTrack.
' The dispatch through 0x00C66724 lands on TScreen + 0x60 = SetActiveGadget($) -- a Type
' Function, so bcc routes the call through the receiver's class table.
' TProfile + 0x1C8 is helppages:Int[]; +0x4C is element 13 (data starts at +0x18).
' Literals read out of the exe: "casino", "", "btn_casino".
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_screen_gamemenu:TScreen     (0x00C66724)
'     The GAME MENU screen, whose construction site is TScreen_GameMenu.CreateScreen
'     (TScreen_GameMenu.CreateScreen.bmx:20). Entering the casino sets the active gadget
'     on the game menu behind it. Spelled g_screen it shared one emitted variable with
'     five other screens' slots and this call landed on the data-editor screen.
'   Global g_profile:TProfile   (0x00C6F028)
	Function SetUpScreen:Int()
		'!Global g_screen_gamemenu:TScreen
		'!Global g_profile:TProfile
		TScreen.SetActive("casino", "")
		PlayTrack(6)
		g_screen_gamemenu.SetActiveGadget("btn_casino")
		TScreen_GameMenu.UpdateTitlePanel()
		If g_profile.helppages[13] = 0 Then
			TScreen.Tutorial()
			g_profile.helppages[13] = 1
		End If
	End Function
