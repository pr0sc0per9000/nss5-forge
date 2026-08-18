' TScreen.DoMessageGetText
' VA 0x00512A74   685 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ($,i)$, class-table slot 0x9C
' (685/685, original length from Ghidra's inventory; verified under NSS5_NO_LEARN=1,
'  reloc_masked=69)
' The text-entry sibling of TScreen.DoMessage (0x005126DA, already banked): same pump,
' same screen teardown, but an TInputBox instead of the ok/yes-no buttons, and the loop
' ends when the module String Global holding the entered text becomes non-empty.
'
' ASSUMPTIONS -- Global NAMES are ours, the declared TYPES are load-bearing. All but
' g_inputtext are re-used verbatim from TScreen.DoMessage.
'   0x00C61700 g_curscreen:TScreen     0x00C616FC g_screens:TList
'   0x00C6EFDC g_screenwidth:Int       0x00C6EFE0 g_screenheight:Int
'   0x00C6EFD4 g_ticks:Int             0x00C6EFD8 g_starttime:Int
'   0x00C6F254 g_img_back:TImage       0x00C6F274 g_img_play:TImage
'   0x00C61734 g_inputtext:String  -- NEW.  globals_final.tsv calls this
'     `g_screen_int02:Int`; it is a String.  It carries the full retain/release idiom
'     around `g_inputtext = ""` (inc [""+4], dec the old, conditional bbGCFree) and the
'     loop test reads its +8 which is the BBString `length` field (pattern 11.2:
'     refcount traffic decides the type, not the access width).
'   TextEntered / InputDone / InputCancel are siblings of TScreen (class-table +0xA0,
'     +0xA4, +0xA8) so they are written unprefixed and passed as the ()i callbacks.
'   TGadget.txtlines is at +0x18 and is a TList, so slot 0x70 on it is TList.Count.
' SHAPE NOTES
'   * `Local n:Int = b.txtlines.Count() * 15` is REQUIRED and is where the whole length
'     error lived.  Inlined into the CreateInputBox y argument the body is 691 bytes:
'     localise_diff attributed it to a -14/+14 pair (the Count+imul block moves from
'     before the push sequence to inside it) plus three +2 `mov ebx,esi` inserts.  Those
'     three inserts were a knock-on: with `n` inlined, `s` lost ebx to a copy at every
'     AddGadget receiver.  Hoisting `n` restored the original's exact register map as
'     well as its length -- a clean instance of the liveness lever of section 18.4, not
'     of declaration order (18.3 rules that one out).
'   * `g_screenheight / 2` is the signed halving `cdq / and edx,1 / add / sar 1`.
'   * the pump is Repeat/Until on the String length, i.e. `.length <> 0`, NOT a
'     comparison against "" (which would be a _bbStringCompare call).
'   * Cls() is 0x005AD32D; it sits between Plot and DrawRect in max2d and is the only
'     no-argument max2d entry there.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_curscreen:TScreen
'!Global g_screens:TList
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_ticks:Int
'!Global g_starttime:Int
'!Global g_img_back:TImage
'!Global g_img_play:TImage
'!Global g_inputtext:String
Local prev:TScreen = g_curscreen
Local s:TScreen = TScreen.CreateScreen("msgscreen", Null, Null, Null)
Local b:TButton = TButton.CreateButton("msgscreen_message", a0, 10, 10, g_screenwidth - 20, g_screenheight - 80, 0, 3, "FFFFFF", "FFFFFF", Null, Null, 0.75, 1, "")
s.AddGadget(b)
Local n:Int = b.txtlines.Count() * 15
s.AddGadget(TInputBox.CreateInputBox("msgscreen_input", 200, g_screenheight / 2 + n, 400, 30, 1, 2, "FFFFFF", "000000", 0, 1.0, TextEntered, a1, ""))
s.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
s.AddGadget(TButton.CreateButton("msgscreen_cancel", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_back, InputCancel, 1.0, 1, ""))
s.AddGadget(TButton.CreateButton("msgscreen_ok", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, InputDone, 1.0, 1, ""))
TScreen.SetActive("msgscreen", "msgscreen_input")
g_inputtext = ""
Repeat
	Cls()
	g_ticks = MilliSecs() - g_starttime
	s.Update()
	s.Draw()
	TScreenMessage.DrawAll()
	DrawMouse()
	Flip(-1)
Until g_inputtext.length <> 0
FlushAllInput()
g_curscreen = prev
s.Clear()
g_screens.Remove(s)
Return g_inputtext
