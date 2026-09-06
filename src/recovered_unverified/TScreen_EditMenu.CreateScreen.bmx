' TScreen_EditMenu.CreateScreen
' VA 0x00527B84   1446 bytes   sig ()i   class-table slot 0x30   KIND=Function (static)
' byte-identical vs NSS5.exe
' REBUILT this pass from a direct disassembly of NSS5.exe (scripts/disasm.py 0x00527B84),
' not from extracted/decomp*/'s Ghidra pseudo-C. That C is actively misleading here: Ghidra
' constant-propagates every Local whose value it can trace back to a literal, so w=200,
' h=40, y=190/240/290/340/390 and col="FFFFFF" all print as bare hex/string literals with
' ZERO visible assignment in the decompiled source -- exactly the same failure mode already
' caught and documented in TScreen_TestMenu.CreateScreen's header ("w=200 forced... bcc
' does no constant hoisting") and reconfirmed here against that byte-verified sibling: its
' raw extracted/decomp/ file prints row 2's y as literal 0x122 even though the ACTUAL bytes
' are `y :+ h + 10`. The previous draft of this file trusted the literal-looking decompile
' and was wrong about nearly every row (score 2.4%, first diff at byte 3 -- the prologue's
' `sub esp,0x30` itself, because the missing Locals meant nothing needed a frame slot).
' This draft instead reads the instruction stream directly; every claim below is a specific
' push/mov at a specific VA, not an inference from the misleading C.
'
' GLOBALS -- addresses are fact; names are the established corpus choices (python
' scripts/explain_global.py <addr>):
'   0x00C64D18 g_screen:TScreen         construction site (0 prior names resolved; ours).
'   0x00C64D1C g_btn_test:TButton       construction site, "editmenu_save" button. STRONG
'     alias-unified name (extracted/global_alias_unified.tsv), same slot as
'     TScreen_EditMenu.ButtonQuit's g_editmenu_btn and ButtonTestData's g_btn_test -- this
'     assignment revives dead-Global sites in BOTH of those already-recovered bodies.
'   0x00C64D20 g_btn_savemobile:TButton construction site, "editmenu_savemobile" button.
'     0 prior names resolved anywhere in the corpus; ours, chosen to sit next to g_btn_test.
'   0x00C6EFDC g_screen_int21:Int  READ ONLY (screen width). This raw name is what the
'     SYM layer independently resolved for this function and is also
'     extracted/global_alias_map.tsv's merge TARGET name "g_screenwidth" (36 files) at
'     assembly, so no rewrite is needed either way and no separate initialiser is declared.
'
' CALL TARGETS (unchanged from before):
'   TScreen+0x38 = CreateScreen($,:TImage,()i,()i):TScreen
'   TButton+0x88 = CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'   TPanel+0x88  = CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'   TScreen slot 0x40 = AddGadget(:TGadget)i
'   TScreen_EditMenu+0x38/3c/40/44/48/50 = ButtonContinents/ButtonNations/ButtonTestData/
'     ButtonSave/ButtonSaveMobile/ButtonQuit -- same Type, bare names.
'   TScreen_Clubs/_Competitions/_Promotions/_ContinentalComps+0x34 = SetUpScreen()i --
'     cross-Type, qualified names.
'   GetText = module Function 0x004C5549 (already recovered in src/recovered_module/).
'
' THE REAL LOCAL LIST (read off the disassembly; declaration order = the order each one
' first gets a register/slot, which is also source order):
'   Local w:Int = 200                          <- EDI for the whole function, never spilled
'   Local h:Int = 40                           <- ESI for the whole function, never spilled
'   Local xleft:Int  = g_screen_int21/2 - 120 - w/2   <- [ebp-0x2C]; NOT a flat `half-220` --
'     the bytes compute screenwidth/2, subtract 120 into ecx, THEN separately compute w/2
'     into eax and subtract THAT from ecx (two mov/cdq/and/add/sar div-idioms, two chained
'     `sub`s), so `w` really is part of this expression, not folded to a constant.
'   Local xright:Int = g_screen_int21/2 + 120 - w/2  <- [ebp-0x30]; a FRESH, independent
'     re-read and re-divide of g_screen_int21 (bcc does no CSE -- same note as
'     TScreen_MainMenu/TScreen_EditContinents), not a reuse of any "half" value -- and no
'     "half" Local exists at all in this version.
'   Local y:Int = 190                          <- EBX; reassigned `y :+ h + 10` between
'     row-pairs (190/240/290/340/390), NEVER a fresh literal per row despite how the
'     decompile prints it (see header intro).
'   Local col:String = "FFFFFF"                <- [ebp-4]; reused as colA for the SIX
'     "FFFFFF"-on-"FFFFFF" middle rows (continents/nations/clubs/competitions/promotions/
'     continentalcomps). testdata/save/savemobile pass colA as a LITERAL instead
'     ("FF8800"/"FF0000"/"FF0000") -- confirmed byte-for-byte, `col` is simply not read for
'     those three calls.
' pan_title/quit/footer touch NONE of these six Locals -- they run before any of them are
' declared and use flat literals throughout, same as the previous draft already had right.
'
' backpanel's box is DERIVED from xleft/y/w/h, not hardcoded: x=xleft-10, y=y-10 (=180,
' while y still holds its initial 190), w=w*2+60 (=460), h=(h+10)*4+10 (=210) -- numerically
' identical to the flat constants the previous draft used, but the BYTES are the derived
' expressions (extra div/shl/add chains), and that is most of this function's
' `sub esp,0x30` (12 dword slots, all accounted for): col, xleft, xright, one incref-temp
' for the new Save button before it is stored to its Global, and one PER-ROW screen-pointer
' spill each for backpanel/continents/nations/clubs/competitions/promotions/
' continentalcomps/testdata -- 8 more slots, because g_screen is reloaded fresh every row
' and, once w/h/y/col occupy ebx/esi/edi/[ebp-4], there is no spare callee-saved register
' left to hold that reload, so each row's copy gets its own stack slot instead of reusing
' one. pan_title/quit/footer, running BEFORE those six Locals exist, keep their screen
' pointer in ebx itself -- no stack slot needed yet, which is also why the frame only
' starts accumulating slots from the backpanel row onward.
'
' STATEMENT-ORDER QUIRK (byte-confirmed, not tidied): for the Save row, `y :+ h + 10` sits
' BETWEEN `g_btn_test = TButton.CreateButton(...)` and `g_screen_editmenu.AddGadget(g_btn_test)` --
' not after both. Same class of quirk already documented in TScreen_MainMenu.CreateScreen's
' header ("`y :+ 30` happens BETWEEN creating a load panel and AddGadget-ing it").
'
' Return 0 matches the original's explicit `return 0` (sig ()i).
'
' 0x00C64D18, the data-editor screen and its construction site. The g_screen spelling was
' shared with five other screens' slots -- create account, game menu, test menu, options
' and the paused match -- so all six were one emitted variable, and because this body is
' the one CreateAllScreens calls, that variable held the data editor for the whole of a
' normal session and every other screen's read landed here.
'!Global g_screen_editmenu:TScreen
'!Global g_btn_test:TButton
'!Global g_btn_savemobile:TButton
'!Global g_screen_int21:Int
g_screen_editmenu = TScreen.CreateScreen("editmenu", Null, Null, Null)
g_screen_editmenu.AddGadget(TButton.CreateButton("pan_title", GetText("Data Editor"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
g_screen_editmenu.AddGadget(TButton.CreateButton("quit", GetText("Quit"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
g_screen_editmenu.AddGadget(TButton.CreateButton("editmenu_footer", "New Star Games 2010", 0, 560, 800, 20, 0, 2, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
Local w:Int = 200
Local h:Int = 40
Local xleft:Int = g_screen_int21 / 2 - 120 - w / 2
Local xright:Int = g_screen_int21 / 2 + 120 - w / 2
Local y:Int = 190
Local col:String = "FFFFFF"
g_screen_editmenu.AddGadget(TPanel.CreatePanel("backpanel", "", xleft - 10, y - 10, w * 2 + 60, (h + 10) * 4 + 10, "FFFFFF", "FFFFFF", 3, 0.8, 1, 0, 0))
g_screen_editmenu.AddGadget(TButton.CreateButton("editmenu_continents", GetText("Continents"), xleft, y, w, h, 1, 3, col, "FFFFFF", Null, ButtonContinents, 1.0, 1, ""))
g_screen_editmenu.AddGadget(TButton.CreateButton("editmenu_nations", GetText("Nations"), xright, y, w, h, 1, 3, col, "FFFFFF", Null, ButtonNations, 1.0, 1, ""))
y :+ h + 10
g_screen_editmenu.AddGadget(TButton.CreateButton("editmenu_clubs", GetText("Clubs"), xleft, y, w, h, 1, 3, col, "FFFFFF", Null, TScreen_Clubs.SetUpScreen, 1.0, 1, ""))
g_screen_editmenu.AddGadget(TButton.CreateButton("editmenu_competitions", GetText("Competitions"), xright, y, w, h, 1, 3, col, "FFFFFF", Null, TScreen_Competitions.SetUpScreen, 1.0, 1, ""))
y :+ h + 10
g_screen_editmenu.AddGadget(TButton.CreateButton("editmenu_promotions", GetText("Promotions"), xleft, y, w, h, 1, 3, col, "FFFFFF", Null, TScreen_Promotions.SetUpScreen, 1.0, 1, ""))
g_screen_editmenu.AddGadget(TButton.CreateButton("editmenu_continentalcomps", GetText("Continental Comps"), xright, y, w, h, 1, 3, col, "FFFFFF", Null, TScreen_ContinentalComps.SetUpScreen, 1.0, 1, ""))
y :+ h + 10
g_screen_editmenu.AddGadget(TButton.CreateButton("editmenu_testdata", GetText("Test Data"), xleft, y, w, h, 1, 3, "FF8800", "FFFFFF", Null, ButtonTestData, 1.0, 1, ""))
g_btn_test = TButton.CreateButton("editmenu_save", GetText("Save"), xright, y, w, h, 1, 3, "FF0000", "FFFFFF", Null, ButtonSave, 1.0, 1, "")
y :+ h + 10
g_screen_editmenu.AddGadget(g_btn_test)
g_btn_savemobile = TButton.CreateButton("editmenu_savemobile", "Save For Mobile", xright, y, w, h, 1, 3, "FF0000", "FFFFFF", Null, ButtonSaveMobile, 1.0, 1, "")
g_screen_editmenu.AddGadget(g_btn_savemobile)
Return 0
