' GLOBAL RENAMED (2026-08-15): g_Object132 -> g_mainmenu_panLoadGame. Same slot,
' 0x00C639D8, named as the CreatePanel construction site in
' TScreen_MainMenu.CreateScreen.bmx's header. CreateScreen builds the Load Game panel
' into g_mainmenu_panLoadGame; this file read the same slot under the decoder's
' auto-name g_Object132, so it saw Null and `g_Object132.hidden` killed the boot on
' the main menu. Byte-neutral -- verified with scripts/reverify.py.
' TScreen_MainMenu.SetUpScreen
' VA 0x0051CD6A   75 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (75/75, original length from Ghidra's inventory)
' assumes module global:  Global g_mainmenu_panLoadGame:TPanel            (0x00C639D8, construction site)
' assumes module global:  Global g_screen_mainmenu_int31:Int   (0x00C6EFD0)
' NOTE: the original emits `cmp dword [0x00C6EFD0],0 / jne +0` -- an If whose body is
' EMPTY (the jump target is the following instruction). Reproduced as an empty If block;
' the original source most likely had commented-out code there.

	Function SetUpScreen:Int()
		'!Global g_mainmenu_panLoadGame:TPanel
		'!Global g_screen_mainmenu_int31:Int
		TScreen.SetActive("mainmenu","mainmenu_loadgame")
		PlayTrack(1)
		TScreen_MainMenu.UpdateVersionInfo()
		If g_screen_mainmenu_int31 = 0 Then
		EndIf
		If g_mainmenu_panLoadGame.hidden = 0 Then TScreen_MainMenu.UpdateLoadTable()
	End Function
