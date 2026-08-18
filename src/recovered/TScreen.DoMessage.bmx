' TScreen.DoMessage
' VA 0x005126DA   803 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ($,i,i)i, class-table slot 0x94
' (803/803, original length from Ghidra's inventory; verified under NSS5_NO_LEARN=1)
' 222 call sites across the game reach this one; it is the modal-dialog pump.
'
' ASSUMPTIONS -- Global NAMES are ours, the declared TYPES are load-bearing.
'   0x00C61700 g_curscreen:TScreen    (already g_currentscreen/g_curscreen in
'                                      TScreen.CreateScreen / TScreen.SetActive)
'   0x00C616FC g_screens:TList        (same as TScreen.SetActive)
'   0x00C6EFDC g_screenwidth:Int      0x00C6EFE0 g_screenheight:Int  (bare dword reads)
'   0x00C61724 g_screen_float01:Float 0x00C61728 g_screen_float02:Float -- the GrabImage
'                                      origin; float01 is the X (pushed second).
'   0x00C61730 g_msgresult:Int        -- set to -1, polled by the loop, returned
'   0x00C6EFD4 g_ticks:Int            0x00C6EFD8 g_starttime:Int  (the MilliSecs pair that
'                                      TEngine.PauseEngine and others already use)
'   0x00C6F274 g_img_play:TImage  (accept icon)   0x00C6F254 g_img_back:TImage (reject icon)
'     -- both names already established by other recovered bodies; 0x00C6F274 is
'        hand-verified TImage in globals_corrections.tsv.
'   0x004A4860 timeGetTime = BlitzMax MilliSecs().
'   MessageDone is a sibling Function of TScreen (class table +0x98) so it is written
'     unprefixed and passed as the button's ()i callback.
' SHAPE NOTES
'   * the ok/yes-no dispatch is a Select with Case 0 / Case 1 and NO Default.  Written as
'     If/ElseIf the body is 799 bytes: localise_diff attributed the whole -4 to three gaps
'     (-12 for the fused `cmp [ebp+0xc],0 / jne` vs the Select's load-then-two-compares,
'     +10 for the second test moved inline, -2 for the missing trailing `jmp`), i.e. exactly
'     the tell in codegen-patterns 10.2.
'   * `bg` is a real Local initialised to Null (`mov ebx,bbNullObject` before the If), not an
'     expression -- it has to survive into TScreen.CreateScreen on the a2 = 0 path.
'   * `prev` captures g_curscreen at the TOP with a bare mov (no retain); the retain appears
'     only at the restoring store, which is the normal object-assignment idiom.
'   * the pump is Repeat/Until with `> -1` (cmp -1 / jle), not `>= 0`.
'   * CreateImage's frames=1 / flags=-1 and Flip's -1 are BlitzMax defaults that bcc emits
'     as explicit pushes, so the shorter spelling is byte-identical.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_curscreen:TScreen
'!Global g_screens:TList
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_msgresult:Int
'!Global g_ticks:Int
'!Global g_starttime:Int
'!Global g_img_back:TImage
'!Global g_img_play:TImage
Local prev:TScreen = g_curscreen
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
Local bg:TImage = Null
If a2 <> 0
	g_curscreen.Draw()
	bg = CreateImage(g_screenwidth, g_screenheight)
	GrabImage(bg, Int(g_screen_float01), Int(g_screen_float02))
EndIf
Local s:TScreen = TScreen.CreateScreen("msgscreen", bg, Null, Null)
s.AddGadget(TButton.CreateButton("msgscreen_message", a0, 0, 0, g_screenwidth, g_screenheight - 60, 0, 3, "FFFFFF", "FFFFFF", Null, Null, 0.75, 0, ""))
s.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
Select a1
	Case 0
		s.AddGadget(TButton.CreateButton("msgscreen_ok", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, MessageDone, 1.0, 1, ""))
		TScreen.SetActive("msgscreen", "msgscreen_ok")
	Case 1
		s.AddGadget(TButton.CreateButton("msgscreen_no", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_back, MessageDone, 1.0, 1, ""))
		s.AddGadget(TButton.CreateButton("msgscreen_yes", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, MessageDone, 1.0, 1, ""))
		TScreen.SetActive("msgscreen", "msgscreen_yes")
End Select
g_msgresult = -1
Repeat
	g_ticks = MilliSecs() - g_starttime
	s.Update()
	s.Draw()
	TScreenMessage.DrawAll()
	DrawMouse()
	Flip(-1)
Until g_msgresult > -1
FlushAllInput()
g_curscreen = prev
s.Clear()
g_screens.Remove(s)
Return g_msgresult
