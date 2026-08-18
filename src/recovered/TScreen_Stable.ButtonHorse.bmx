' TScreen_Stable.ButtonHorse
' VA 0x005887FE   130 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (130/130, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Globals 0x00C6DF70:Int, 0x00C6DF68:Int, 0x00C6DF6C:Int, 0x00C6F028:TProfile.
' 0x00C61CC0 = TScreen.DoMessage, 0x00C621CC = TGadget.GetActiveGadgetName,
' 0x00C6E264 = TScreen_Stable class table + 0x5C = RefreshRunners(i)i (sibling Function).
' FUN_004A75B0 = _bbStringReplace, FUN_004A7130 = _bbStringToInt (so the parse is Int()),
' PTR_PTR_00C5D284 is the empty-string constant.
' Both guards are EARLY RETURNS (`cmp / je body / mov eax,0 / jmp end`); the If/Else form
' is 118 bytes.
	Function ButtonHorse:Int()
		'!Global g_screen_stable_int05:Int
		'!Global g_profile:TProfile
		' g_screen_stable_int03's original data-section value is 50 (read from
		' NSS5.exe at 0x00C6DF68 -- codegen-patterns 21.1/21.3).
		'!Global g_screen_stable_int03:Int = 50
		'!Global g_screen_stable_int04:Int
		If g_screen_stable_int05 <> 1 Then Return 0
		If g_profile.bank < g_screen_stable_int03
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
			Return 0
		EndIf
		g_screen_stable_int04 = Int(TGadget.GetActiveGadgetName().Replace("btn_Horse", ""))
		RefreshRunners(0)
	End Function
