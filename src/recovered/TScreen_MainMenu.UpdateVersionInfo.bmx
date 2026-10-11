' TScreen_MainMenu.UpdateVersionInfo
' VA 0x0051d97f   50 bytes   vtable slot 0x68   sig ()i
' byte-identical vs NSS5.exe (50/50, original length from Ghidra's inventory)
' globals 0x00c639fc / 0x00c6e900 are Strings, not Ints
' NAMES CHANGED 2026-10-11 (byte-neutral): 0x0051D983 `8b1d00e9c600 mov ebx,[0xc6e900]`
' reads the version string and 0x0051D99F `891dfc39c600 mov [0xc639fc],ebx` stores it.
' The source was g_screen_mainmenu_int25, aliased onto 0x00C639FC, and the destination
' g_screen_mainmenu_int03 was a second variable for 0x00C639FC, so this copy never
' replaced the "0" TScreen_Language.ButtonLanguage stores in g_mainmenu_str and New Career
' then raised CMESSAGE_MUSTBEONLINE. Now g_version (0x00C6E900, "1.15" at 0x00C6E8EC,
' declared in src/module_body/tail.bmx) and g_mainmenu_str (0x00C639FC, data "0" at
' 0x00C639EC, which MainMenu.SetUpScreen replaces with the version through this copy).

	Function UpdateVersionInfo:Int()
		'!Global g_mainmenu_str:String = "0"
		'!Global g_version:String
		g_mainmenu_str = g_version
	End Function
