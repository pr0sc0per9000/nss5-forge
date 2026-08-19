' TScreen_Options.SetUpScreen  (KIND=Function -- static)
' VA 0x0051FAB3   340 bytes   sig ()i
' byte-identical vs NSS5.exe (340/340, original length from Ghidra's inventory, mode=reloc)
' GLOBAL NAMES ARE OURS; declared types load-bearing:
'   0x00C61700 TScreen (the active screen), 0x00C63CEC String (table says Int),
'   0x00C63D0C TInputBox, 0x00C6F028 TProfile, 0x00C68BC8 String (table says Int),
'   0x00C63CFC Int (table says TScreen -- bare mov, no refcount traffic; see 10.7).
' Ghidra shows only ONE "" argument in the Replace call; the disassembly has two pushes,
' one for String.Replace's third argument and one for TGadget.SetText's second.
'
' The three snapshot lines below read DAT_00c5d244 / DAT_00c5d248 / DAT_00c5d274 in the
' decompilation (extracted/decomp/TScreen_Options.SetUpScreen@0051fab3.c) and store to
' DAT_00c63cfc / DAT_00c63d00 / DAT_00c63d04. The screen/window source addresses are the
' SAME cells TOptions.LoadOptions/SaveOptions already call g_opt_screen/g_opt_window, so
' those exact names are used here instead of a freshly invented g_options_int01/int02 --
' "g_options_int01" and "g_options_int02" are already the corpus-established canonical
' names for two UNRELATED addresses (0x00C5D1A8 control-mode and 0x00C5D22C g_opt_radar,
' extracted/global_address_map.tsv, both CERTAIN/unanimous), so reusing them here would
' have collided this function's screen/window reads onto those other Globals. Likewise the
' snapshot destinations reuse TScreen_Options.ButtonTick's own g_opt_b/g_opt_d names
' (0x00C63CFC/0x00C63D00, ButtonTick@005216f7's header) rather than g_options_int09/int10,
' since "g_options_int09" already canonicalises to the UNRELATED g_opt_tooltips
' (0x00C5D258). Without this, ButtonTick's dirty check (g_opt_screen<>g_opt_b Or
' g_opt_window<>g_opt_d) compared the real current values against Globals nothing here
' ever actually reached, so the "at screen open" baseline stayed 0 and the check almost
' always read as changed -- see TScreen_Options.ResetScreen.bmx for the matching apply-path
' fix. Currency's g_options_int04/int11 pairing is left as originally named; it is not part
' of the resolution/window path.
'!Global g_activescreen:TScreen
'!Global g_options_prevscreen:String
'!Global g_opt_screen:Int
'!Global g_opt_window:Int
' g_options_int04's original data-section value is 2 (read from NSS5.exe at
' 0x00C5D234 -- codegen-patterns 21.1/21.3).
'!Global g_options_int04:Int = 2
'!Global g_opt_b:Int
'!Global g_opt_d:Int
'!Global g_options_int11:Int
'!Global g_profile:TProfile
'!Global g_options_inputbox:TInputBox
'!Global g_savename:String
TScreenMessage.ClearAll(1)
If g_activescreen.name <> "controls" Then g_options_prevscreen = g_activescreen.name
TScreen.SetActive("options", "tick")
TScreen_Options.RefreshButtons()
g_opt_b = g_opt_screen
g_opt_d = g_opt_window
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
