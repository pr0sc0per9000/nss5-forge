' TScreen.DoHelp
' VA 0x005132B5   648 bytes   class-table slot 0xb8   sig (i)i
' byte-identical vs NSS5.exe (648/648, original length from Ghidra's inventory, mode=reloc)
'
' Draws the previous screen (dimmed + snapshotted into a background image), then shows a
' modal "helpscreen" for every THelpBox on the CURRENT screen's lHelp list -- one screen
' per help box, sequentially. a0 <> 0 means "show the End Tutorial button too".
'
' GLOBAL NAMES ARE OURS. 0x00C61700 g_curscreen:TScreen (also TScreen.CreateScreen /
' TScreen.DoMessage's g_currentscreen/g_curscreen), 0x00C616FC g_screens:TList (same
' address as TScreen.DoMessage's g_screens), 0x00C5D258 g_options_int09:Int (also
' TScreen_Options.SetUpScreen), 0x00C61724/0x00C61728 g_screen_float01/02:Float (the
' GrabImage origin, same as TScreen.DoMessage), 0x00C6EFDC/0x00C6EFE0 g_screenwidth/
' g_screenheight:Int (same addresses as TScreen.UpdateOffset/DoMessage), 0x00C61730
' g_screen_int01:Int (the modal-loop exit flag; 2 means "stop showing further help boxes
' entirely", any other nonzero means "next box"), 0x00C6EFD4/0x00C6EFD8 g_ticks/
' g_starttime:Int (the MilliSecs pair TEngine.PauseEngine and TScreen.DoMessage use).
'
' SHAPE NOTES
'   * savedcolor (g_options_int09's old value) is read and g_options_int09 zeroed BEFORE
'     `prev` captures g_curscreen -- that statement order is load-bearing (first_diff 29
'     without it: two `mov [ebp-N],eax` stack slots swap).
'   * `prev.lHelp` (offset 0x1c) is walked as a plain For..EachIn; the loop's own
'     null-skip needs nothing extra (codegen-patterns 10.6).
'   * the "next box vs stop entirely" choice is `If g_screen_int01 = 2 Then Exit` as the
'     last statement of the loop body, sharing its exit target with the natural
'     end-of-list fall-through (both land on `g_options_int09 = savedcolor; Return 0`).
'   * TScreen.Update is declared a Function (class-table slot 0x78, no Self) but is
'     called here as `s.Update()` through the instance, exactly like TScreen.DoMessage.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_curscreen:TScreen
'!Global g_screens:TList
' g_options_int09's original data-section value is 1 (read from NSS5.exe at
' 0x00C5D258 -- codegen-patterns 21.1/21.3).
'!Global g_options_int09:Int = 1
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_screen_int01:Int
'!Global g_ticks:Int
'!Global g_starttime:Int
LogLine("DoHelp")
Local savedcolor:Int = g_options_int09
g_options_int09 = 0
Local prev:TScreen = g_curscreen
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
g_curscreen.Draw()
SetColor(0,0,0)
SetAlpha(0.25)
DrawRect(g_screen_float01, g_screen_float02, Float(g_screenwidth), Float(g_screenheight))
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
Local bg:TImage = CreateImage(g_screenwidth, g_screenheight)
GrabImage(bg, Int(g_screen_float01), Int(g_screen_float02))
For Local hb:THelpBox = EachIn prev.lHelp
	Local s:TScreen = TScreen.CreateScreen("helpscreen", bg, Null, Null)
	s.AddGadget(hb.lbl_Help1)
	s.AddGadget(hb.lbl_Help2)
	s.AddGadget(hb.btn_Ok)
	If a0 <> 0
		s.AddGadget(hb.btn_EndTutorial)
	EndIf
	g_screen_int01 = 0
	TScreen.SetActive("helpscreen", "btn_Help")
	Repeat
		g_ticks = MilliSecs() - g_starttime
		s.Update()
		s.Draw()
		TScreenMessage.DrawAll()
		DrawMouse()
		Flip(-1)
	Until g_screen_int01 <> 0
	FlushAllInput()
	g_curscreen = prev
	s.Clear()
	g_screens.Remove(s)
	If g_screen_int01 = 2 Then Exit
Next
g_options_int09 = savedcolor
Return 0
