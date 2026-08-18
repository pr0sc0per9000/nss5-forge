' TScreen_Options.SetUpScreen  (KIND=Function -- static)
' VA 0x0051FAB3   340 bytes   sig ()i
' byte-identical vs NSS5.exe (340/340, original length from Ghidra's inventory, mode=reloc)
' GLOBAL NAMES ARE OURS; declared types load-bearing:
'   0x00C61700 TScreen (the active screen), 0x00C63CEC String (table says Int),
'   0x00C63D0C TInputBox, 0x00C6F028 TProfile, 0x00C68BC8 String (table says Int),
'   0x00C63CFC Int (table says TScreen -- bare mov, no refcount traffic; see 10.7).
' Ghidra shows only ONE "" argument in the Replace call; the disassembly has two pushes,
' one for String.Replace's third argument and one for TGadget.SetText's second.
'!Global g_activescreen:TScreen
'!Global g_options_prevscreen:String
'!Global g_options_int01:Int
'!Global g_options_int02:Int
' g_options_int04's original data-section value is 2 (read from NSS5.exe at
' 0x00C5D234 -- codegen-patterns 21.1/21.3).
'!Global g_options_int04:Int = 2
'!Global g_options_int09:Int
'!Global g_options_int10:Int
'!Global g_options_int11:Int
'!Global g_profile:TProfile
'!Global g_options_inputbox:TInputBox
'!Global g_savename:String
TScreenMessage.ClearAll(1)
If g_activescreen.name <> "controls" Then g_options_prevscreen = g_activescreen.name
TScreen.SetActive("options", "tick")
TScreen_Options.RefreshButtons()
g_options_int09 = g_options_int01
g_options_int10 = g_options_int02
g_options_int11 = g_options_int04
If g_options_prevscreen = "mainmenu" Or g_profile.clubid = 0
	g_options_inputbox.SetText("", "", -1, -1)
	g_options_inputbox.SetAlph(0.5)
	g_options_inputbox.alive = 0
Else
	g_options_inputbox.SetText(g_savename.Replace(".sav", ""), "", -1, -1)
	g_options_inputbox.SetAlph(1.0)
	g_options_inputbox.alive = 1
EndIf
