' TScreen_TestMenu.CreateScreen  -- KIND=Function (static, no implicit Self)
' VA 0x005379B9   489 bytes   sig ()i   slot 0x30
' byte-identical vs NSS5.exe (489/489, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=48)
'
' ASSUMPTIONS
'   Globals (names ours):
'     0x00C6635C -> g_screen_testmenu:TScreen  (construction site = TScreen.CreateScreen;
'                   full retain/release traffic)
'     0x00C6EFDC -> g_screenwidth:Int          (bare dword read, no refcount)
'   Class-table slots resolved through globals_final.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38  = CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C623CC = TButton+0x88  = CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     slot 0x40 on the TScreen Global = TScreen.AddGadget (:TGadget)i
'     0x00C66408 = TScreen_TestMenu+0x38 = ButtonQuit ()i        (same Type -> bare name)
'     0x00C66710 = TScreen_TestFixtures+0x34 = SetUpScreen ()i
'     0x00C665D8 = TScreen_TestTournaments+0x34 = SetUpScreen ()i
'   FUN_004C5549 = GetText.  NOTE Ghidra MERGES GetText's single argument with the
'   following CreateButton pushes -- the disassembly shows `push <key>; call 0x4c5549;
'   add esp,4` i.e. exactly ONE argument.
'   FUN_005B95D0 (the empty function) as a ()i argument is source-level `Null`.
'   String literals read from the exe with harness.read_string; 0x005C7D40 is the empty
'   string constant -> "".
'
' The five Locals (w,h,x,y,col) are forced by the original: bcc does no constant hoisting,
' so `push 0xc8` would have been emitted inline had 200 been a literal.  The second row's
' y is `y :+ h + 10` (mov eax,esi / add eax,0xa / add ebx,eax), NOT the folded constant
' 290 -- that difference alone is 2 bytes and it also pushes `col` from a register onto
' the stack, costing 6 more.
'!Global g_screen_testmenu:TScreen
'!Global g_screenwidth:Int
	Function CreateScreen()
		g_screen_testmenu = TScreen.CreateScreen("testmenu", Null, Null, Null)
		g_screen_testmenu.AddGadget(TButton.CreateButton("pan_title", GetText("AppTitle"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_screen_testmenu.AddGadget(TButton.CreateButton("quit", GetText("Back"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
		Local w:Int = 200
		Local h:Int = 40
		Local x:Int = g_screenwidth / 2 - 100
		Local y:Int = 240
		Local col:String = "FFFFFF"
		g_screen_testmenu.AddGadget(TButton.CreateButton("testmenu_fixtures", GetText("Fixtures"), x, y, w, h, 1, 3, col, "FFFFFF", Null, TScreen_TestFixtures.SetUpScreen, 1.0, 1, ""))
		y :+ h + 10
		g_screen_testmenu.AddGadget(TButton.CreateButton("testmenu_tournaments", GetText("Tournaments"), x, y, w, h, 1, 3, col, "FFFFFF", Null, TScreen_TestTournaments.SetUpScreen, 1.0, 1, ""))
	End Function
