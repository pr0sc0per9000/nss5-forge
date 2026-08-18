' TScreen_TestTournaments.CreateScreen
' VA 0x00537C19   2877 bytes   KIND=Function (static, no implicit Self)   sig ()i   slot 0x30
' byte-identical vs NSS5.exe (2877/2877, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=311), verified with NSS5_NO_LEARN=1 -- MATCH on the first attempt, no call
' operand was masked by a name this run itself taught.
'
' FAMILY (12.2): gadget-construction skeleton identical in shape to TScreen_TestMenu's and
' TScreen_Leagues'/TScreen_Continents' CreateScreen bodies -- one CreateXxx call per gadget,
' AddGadget/AddColumn/AddItem calls immediately after. A gadget the rest of the module needs
' later (referenced by SetUpScreen or a Check*/Filter*/Combo* sibling) is stored to its own
' module Global with the full retain-old/release-new pattern and THEN added; a throwaway
' gadget (pan_title, quit, navpanel, btn_play) is passed straight into AddGadget in one
' nested statement with no separate store. Both forms occur in this one function and the
' choice was read off the retain/release traffic in the decompilation, not guessed.
'
' Twin verified against extracted/decomp_annotated -- every GetText call takes exactly ONE
' argument (Ghidra folds the following call's pushes into GetText's printed arg list; read
' the `add esp,4` after the call, not the printed list, guide 3a). FOUR gadgets' text is a
' bare literal with NO GetText wrapper at all (confirmed by the absence of any GetText call
' in the call-site list immediately before their CreateCombo/CreateButton): all four TCombo
' texts ("Level","Locale","Based","Competition") and three buttons' texts ("<",">","<<",
' ">>" -- i.e. grpL/grpR/rndLL/rndL/rndR/rndRR) plus "date"'s and "navpanel"'s "".
'
' ASSUMPTIONS -- module Globals (names are ours except where noted; the ADDRESS and the
' declared TYPE are the load-bearing parts). Types are the Function's own construction site
' (globals_final.tsv type_source=construction) plus the slot used through each one.
'   0x00C6640C -> g_tt_screen:TScreen              (TScreen.CreateScreen)
'   0x00C66410 -> g_tt_tbl_teams:TTable             SAME NAME as already-verified
'   0x00C66414 -> g_tt_tbl_fixtures:TTable          TScreen_TestTournaments.SetUpScreen.bmx
'   0x00C66418 -> g_tt_lbl_date:TButton             SAME NAME, TYPE CORRECTED -- see below
'   0x00C6641C -> g_tt_btn_groupL:TButton  ("grpL", not read elsewhere in the corpus)
'   0x00C66420 -> g_btn_group:TButton               SAME NAME as already-verified
'                                                    TScreen_TestTournaments.CheckGroups.bmx
'                                                    (the "grp" button; SetText(GetText(
'                                                    "Group")+groupno) is called on it there)
'   0x00C66424 -> g_tt_btn_groupR:TButton  ("grpR", not read elsewhere)
'   0x00C6642C -> g_tt_btn_roundFF:TButton ("rndLL", not read elsewhere)
'   0x00C66430 -> g_tt_btn_roundF:TButton  ("rndL", not read elsewhere)
'   0x00C66434 -> g_tt_button:TButton                SAME NAME as already-verified
'                                                    TScreen_TestTournaments.CheckRounds.bmx
'                                                    (the "rnd" button; SetText(GetText(
'                                                    "Round")+' '+g_tt_int02) is called there)
'   0x00C66438 -> g_tt_btn_roundN:TButton  ("rndR", not read elsewhere)
'   0x00C6643C -> g_tt_btn_roundNN:TButton ("rndRR", not read elsewhere)
'   0x00C66444 -> g_combo_level:TCombo               SAME NAME as already-verified
'   0x00C66448 -> g_combo_locale:TCombo              TScreen_TestTournaments.ComboBased.bmx
'   0x00C6644C -> g_combo_based:TCombo               (its own header: "GLOBAL NAMES ARE OURS")
'   0x00C66450 -> g_tt_cmb_comp:TCombo               SAME NAME as already-verified
'                                                    TScreen_TestTournaments.SetUpScreen.bmx
'   0x00C6EFDC -> g_screenwidth:Int   (pushed as CreatePanel's `w`; bare dword, no refcount
'                 traffic, so Int -- guide 10.7. Same Global every other CreateScreen uses.)
'   0x00C6EFE0 -> g_screenheight:Int  (same convention, `y = g_screenheight - 60/50`)
'
' *** CROSS-FILE CONFLICT, FLAGGED NOT FIXED ***
' TScreen_TestTournaments.SetUpScreen.bmx declares 0x00C66418 as g_tt_lbl_date:TLabel. This
' function's own construction site is unambiguous -- `TButton.CreateButton("date","",...)` --
' so the true type is TButton, not TLabel (TButton and TLabel are SIBLINGS, both `Extends
' TGadget`, never convertible to each other; see class_tables.tsv). SetUpScreen's own MATCH
' is unaffected because it only calls SetText, which is TGadget's inherited slot 0x64 and
' resolves identically for either type -- but if both files are assembled together under the
' SAME Global name with two different declared types, scripts/assemble.py's merge will flag
' an unresolved Global-type conflict (`TButton` sorts before `TLabel` alphabetically, so the
' arbitrary tie-break happens to land on the correct one, but it should be resolved for real:
' change SetUpScreen's pragma from TLabel to TButton and re-verify -- its own bytes cannot
' change from this since slot 0x64 is TGadget's, not TButton's or TLabel's own).
'
' Class-table slots resolved via class_tables.tsv + vtable_map.tsv:
'   0x00C61C64 = TScreen+0x38   CreateScreen($,:TImage,()i,()i):TScreen
'   0x00C623CC = TButton+0x88   CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'   0x00C63294 = TPanel+0x88    CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'   0x00C62BAC = TTable+0x88    CreateTable($,i,i,i,i,i,i,$,f,i,()i):TTable
'   0x00C630E0 = TCombo+0x88    CreateCombo($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo
'   slot 0x40 on the TScreen Global  = TScreen.AddGadget(:TGadget)i
'   slot 0x90 on the TTable Globals  = TTable.AddColumn(i,$,$,$,i)i
'   slot 0x90 on the TCombo Globals  = TCombo.AddItem($,$,$,i)i
'   Own-Type callbacks (same Type -> bare name, no `TScreen_TestTournaments.` prefix), all
'   already verified independently:
'     +0x38 ComboLevel  +0x3C ComboLocale  +0x40 ComboBased  +0x44 ComboCompetition
'     +0x48 FilterGroup  +0x4C FilterRound  +0x58 ButtonQuit  +0x5C ButtonPlay
' 0x004C5549 = GetText (recovered module Function). Ghidra MERGES GetText's single argument
' with the pushes of the FOLLOWING call -- read the `add esp,4` after the call, not Ghidra's
' printed argument list (guide 3a). 0x004A8590 = _bbGCFree, the inlined BBRELEASE of each
' Global's old value on store, never written in source (guide 3d). 0x005B95D0 (the empty
' function) as a ()i argument is source-level Null. 0x005C9C80 = bbNullObject = Null for an
' object argument.
'
' All 60 string literals were read out of NSS5.exe with harness.read_string (a MATCH masks a
' literal's ADDRESS and does not certify its content, guide 13.2) -- every one confirmed
' verbatim, including the easy-to-mistype locale keys "tla_Position"/"tla_Played"/"tla_Won"/
' "tla_Drawn"/"tla_Lost"/"sla_GoalsFor"/"sla_GoalsAgainst"/"tla_GoalDifference"/"tla_Points"
' (note "sla_" on the two Goals columns, not "tla_") and the quit button's key, which is
' "Menu", not "Back". Every float is 1.0 (0x3F800000); there is no other alpha value in
' this function.
'!Global g_tt_screen:TScreen
'!Global g_tt_tbl_teams:TTable
'!Global g_tt_tbl_fixtures:TTable
'!Global g_tt_lbl_date:TButton
'!Global g_tt_btn_groupL:TButton
'!Global g_btn_group:TButton
'!Global g_tt_btn_groupR:TButton
'!Global g_tt_btn_roundFF:TButton
'!Global g_tt_btn_roundF:TButton
'!Global g_tt_button:TButton
'!Global g_tt_btn_roundN:TButton
'!Global g_tt_btn_roundNN:TButton
'!Global g_combo_level:TCombo
'!Global g_combo_locale:TCombo
'!Global g_combo_based:TCombo
'!Global g_tt_cmb_comp:TCombo
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
g_tt_screen = TScreen.CreateScreen("tournaments", Null, Null, Null)
g_tt_screen.AddGadget(TButton.CreateButton("pan_title", GetText("Tournaments"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
g_tt_screen.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
g_tt_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
g_tt_lbl_date = TButton.CreateButton("date", "", 590, g_screenheight - 50, 100, 40, 0, 2, "AAAAAA", "FFFFFF", Null, ButtonPlay, 1.0, 4, "")
g_tt_screen.AddGadget(g_tt_lbl_date)
g_tt_screen.AddGadget(TButton.CreateButton("btn_play", GetText("Play"), 690, g_screenheight - 50, 100, 40, 1, 2, "00FF00", "FFFFFF", Null, ButtonPlay, 1.0, 5, ""))
g_tt_tbl_teams = TTable.CreateTable("tbl_table", 10, 100, 21, 0, 1, 2, "0000FF", 1.0, 1, Null)
g_tt_tbl_teams.AddColumn(28, GetText("tla_Position"), "000000", "AAAAAA", 1)
g_tt_tbl_teams.AddColumn(100, GetText("Name"), "000000", "AAAAAA", 0)
g_tt_tbl_teams.AddColumn(28, GetText("tla_Played"), "000000", "AAAAAA", 1)
g_tt_tbl_teams.AddColumn(28, GetText("tla_Won"), "000000", "AAAAAA", 1)
g_tt_tbl_teams.AddColumn(28, GetText("tla_Drawn"), "000000", "AAAAAA", 1)
g_tt_tbl_teams.AddColumn(28, GetText("tla_Lost"), "000000", "AAAAAA", 1)
g_tt_tbl_teams.AddColumn(28, GetText("sla_GoalsFor"), "000000", "AAAAAA", 1)
g_tt_tbl_teams.AddColumn(28, GetText("sla_GoalsAgainst"), "000000", "AAAAAA", 1)
g_tt_tbl_teams.AddColumn(28, GetText("tla_GoalDifference"), "000000", "AAAAAA", 1)
g_tt_tbl_teams.AddColumn(28, GetText("tla_Points"), "000000", "AAAAAA", 1)
g_tt_screen.AddGadget(g_tt_tbl_teams)
g_tt_tbl_fixtures = TTable.CreateTable("tbl_fixtures", 380, 100, 21, 0, 1, 2, "0000FF", 1.0, 1, Null)
g_tt_tbl_fixtures.AddColumn(80, GetText("Date"), "000000", "AAAAAA", 1)
g_tt_tbl_fixtures.AddColumn(100, GetText("Home Team"), "000000", "AAAAAA", 2)
g_tt_tbl_fixtures.AddColumn(60, "", "000000", "AAAAAA", 1)
g_tt_tbl_fixtures.AddColumn(100, GetText("Away Team"), "000000", "AAAAAA", 0)
g_tt_tbl_fixtures.AddColumn(60, GetText("Info"), "000000", "AAAAAA", 1)
g_tt_screen.AddGadget(g_tt_tbl_fixtures)
g_tt_btn_groupL = TButton.CreateButton("grpL", "<", 600, 50, 30, 20, 1, 2, "00FFFF", "FFFFFF", Null, FilterGroup, 1.0, 4, "")
g_btn_group = TButton.CreateButton("grp", GetText("Group"), 630, 50, 100, 20, 0, 2, "EEEEEE", "FFFFFF", Null, FilterGroup, 1.0, 0, "")
g_tt_btn_groupR = TButton.CreateButton("grpR", ">", 730, 50, 30, 20, 1, 2, "00FFFF", "FFFFFF", Null, FilterGroup, 1.0, 5, "")
g_tt_screen.AddGadget(g_tt_btn_groupL)
g_tt_screen.AddGadget(g_btn_group)
g_tt_screen.AddGadget(g_tt_btn_groupR)
g_tt_btn_roundFF = TButton.CreateButton("rndLL", "<<", 570, 70, 30, 20, 1, 2, "00FFFF", "FFFFFF", Null, FilterRound, 1.0, 4, "")
g_tt_btn_roundF = TButton.CreateButton("rndL", "<", 600, 70, 30, 20, 1, 2, "00FFFF", "FFFFFF", Null, FilterRound, 1.0, 0, "")
g_tt_button = TButton.CreateButton("rnd", GetText("Round"), 630, 70, 100, 20, 0, 2, "DDDDDD", "FFFFFF", Null, FilterRound, 1.0, 0, "")
g_tt_btn_roundN = TButton.CreateButton("rndR", ">", 730, 70, 30, 20, 1, 2, "00FFFF", "FFFFFF", Null, FilterRound, 1.0, 0, "")
g_tt_btn_roundNN = TButton.CreateButton("rndRR", ">>", 760, 70, 30, 20, 1, 2, "00FFFF", "FFFFFF", Null, FilterRound, 1.0, 5, "")
g_tt_screen.AddGadget(g_tt_btn_roundFF)
g_tt_screen.AddGadget(g_tt_btn_roundF)
g_tt_screen.AddGadget(g_tt_button)
g_tt_screen.AddGadget(g_tt_btn_roundN)
g_tt_screen.AddGadget(g_tt_btn_roundNN)
g_combo_level = TCombo.CreateCombo("cmb_lvl", "Level", 10, 50, 120, 40, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboLevel, 4)
g_combo_level.AddItem("Club", "FFFFFF", "FFFFFF", 0)
g_combo_level.AddItem("International", "FFFFFF", "FFFFFF", 0)
g_tt_screen.AddGadget(g_combo_level)
g_combo_locale = TCombo.CreateCombo("cmb_loc", "Locale", 130, 50, 120, 40, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboLocale, 0)
g_tt_screen.AddGadget(g_combo_locale)
g_combo_based = TCombo.CreateCombo("cmb_Based", "Based", 250, 50, 120, 40, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboBased, 0)
g_tt_screen.AddGadget(g_combo_based)
g_tt_cmb_comp = TCombo.CreateCombo("cmb_comps", "Competition", 370, 50, 180, 40, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboCompetition, 5)
g_tt_screen.AddGadget(g_tt_cmb_comp)
