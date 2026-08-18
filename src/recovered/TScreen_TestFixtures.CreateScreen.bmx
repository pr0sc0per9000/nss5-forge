' TScreen_TestFixtures.CreateScreen
' VA 0x00539294   1119 bytes   vtable slot 0x30   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (1119/1119, original length from Ghidra's inventory)
'
' Globals (names ours; addresses and types from construction-site evidence in
' extracted/globals_final.tsv, cross-checked against sibling files already in this
' Type -- src/recovered/TScreen_TestFixtures.SetUpScreen.bmx and .ComboContinent.bmx):
'   0x00C66604 g_testfix_screen:TScreen   -- the screen itself (new name; not used
'     elsewhere in this Type's recovered files yet)
'   0x00C66608 g_testfix_table:TTable     -- globals_final.tsv guesses TButton (a
'     construction-site CONFLICT it flags itself); SetUpScreen.bmx already overrode
'     this to TTable from the 0x9C ClearItems / 0x94 AddItem call shapes (rule 11.2/
'     16.7), and this file's own CreateTable() construction site confirms it directly.
'   0x00C6660C g_testfix_label:TButton    -- SetUpScreen.bmx's name; the "fixtures_date"
'     button used purely as a label (SetText'd with the current in-game date there).
'   0x00C66610 g_tf_combocontinent:TCombo -- SAME ADDRESS SetUpScreen.bmx calls
'     "g_testfix_combo" (a pre-existing corpus naming split, not introduced here --
'     same pattern as g_iv_screen/g_screen_interview in TScreen_Interview.Update.bmx).
'     Named to match the majority: ComboContinent.bmx and CheckShowFixtures.bmx both
'     use g_tf_combocontinent for this address.
'   0x00C66614 g_tf_combonation:TCombo    -- matches ComboContinent.bmx/CheckShowFixtures.bmx.
'   0x00C6EFDC g_screen_int21:Int, 0x00C6EFE0 g_screen_int22:Int -- screen w/h, the
'     same pair used corpus-wide (e.g. TScreen_BootShop.CreateScreen.bmx).
'
' Calls: TScreen.CreateScreen($,:TImage,()i,()i):TScreen slot 0x38, TButton.CreateButton
' ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton slot 0x88, TPanel.CreatePanel(...)
' slot 0x88, TTable.CreateTable(...):TTable slot 0x88, TTable.AddColumn(i,$,$,$,i)i
' slot 0x90, TCombo.CreateCombo(...):TCombo slot 0x88, TScreen.AddGadget(:TGadget)i
' slot 0x40 -- all confirmed in extracted/vtable_map.tsv. GetText($):String takes
' exactly 1 argument at every one of these call sites (Ghidra's printed argument lists
' merge GetText's real arg with the pushes of the following Create* call -- see the
' "GHIDRA'S PRINTED ARGUMENT LIST IS NOT EVIDENCE" note in
' extracted/decomp_annotated/TScreen_TestFixtures.CreateScreen@00539294.c).
' Callback function references (ButtonQuit, ButtonPlay x2, ComboContinent,
' TScreen_TestFixtures.SetUpScreen) are this Type's own Functions -- bare/qualified
' names per the existing corpus convention, no vtable indirection needed.
'
' Literal numeric args (x/y/w/h/align/fontsize/style/tag) are the raw hex immediates
' from the disassembly, decimal-converted (e.g. 0x2b2=690, 0x118=280).
	Function CreateScreen:Int()
		'!Global g_testfix_screen:TScreen
		'!Global g_testfix_table:TTable
		'!Global g_testfix_label:TButton
		'!Global g_tf_combocontinent:TCombo
		'!Global g_tf_combonation:TCombo
		'!Global g_screen_int21:Int
		'!Global g_screen_int22:Int
		g_testfix_screen = TScreen.CreateScreen("fixtures", Null, Null, Null)
		g_testfix_screen.AddGadget(TButton.CreateButton("pan_title", GetText("Fixtures"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_testfix_screen.AddGadget(TButton.CreateButton("quit", GetText("Back"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, TScreen_TestFixtures.ButtonQuit, 1.0, 1, ""))
		g_testfix_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screen_int22 - 60, g_screen_int21, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_testfix_label = TButton.CreateButton("fixtures_date", "", 590, g_screen_int22 - 50, 100, 40, 0, 2, "AAAAAA", "FFFFFF", Null, TScreen_TestFixtures.ButtonPlay, 1.0, 4, "")
		g_testfix_screen.AddGadget(g_testfix_label)
		g_testfix_screen.AddGadget(TButton.CreateButton("fixtures_play", GetText("Play"), 690, g_screen_int22 - 50, 100, 40, 1, 2, "00FF00", "FFFFFF", Null, TScreen_TestFixtures.ButtonPlay, 1.0, 5, ""))
		g_testfix_table = TTable.CreateTable("tbl_fixtures", 10, 80, 22, 0, 1, 2, "0000FF", 1.0, 1, Null)
		g_testfix_table.AddColumn(280, GetText("Competition"), "000000", "AAAAAA", 1)
		g_testfix_table.AddColumn(140, GetText("Home Team"), "000000", "AAAAAA", 2)
		g_testfix_table.AddColumn(90, GetText("Result"), "000000", "AAAAAA", 1)
		g_testfix_table.AddColumn(140, GetText("Away Team"), "000000", "AAAAAA", 0)
		g_testfix_table.AddColumn(90, GetText("Info"), "000000", "AAAAAA", 1)
		g_testfix_screen.AddGadget(g_testfix_table)
		g_tf_combocontinent = TCombo.CreateCombo("cmb_Continent", GetText("Continent"), 10, 50, 120, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, TScreen_TestFixtures.ComboContinent, 1)
		g_tf_combonation = TCombo.CreateCombo("cmb_Nation", GetText("Nation"), 140, 50, 120, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, TScreen_TestFixtures.SetUpScreen, 1)
		g_testfix_screen.AddGadget(g_tf_combocontinent)
		g_testfix_screen.AddGadget(g_tf_combonation)
		Return 0
	End Function
