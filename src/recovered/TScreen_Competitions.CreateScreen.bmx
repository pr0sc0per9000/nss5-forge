' TScreen_Competitions.CreateScreen
' VA 0x0052f053   2656 bytes   class-table slot 0x30   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (2656/2656, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=2656/2656  STATUS=MATCH.  NSS5_NO_LEARN=1.
'
' No sub esp -- ebx is the ONLY saved register (no spilled Locals at all); every gadget is
' built and immediately assigned to a module Global or pushed straight into AddGadget, so
' there is nothing here that needed a Local. Shape matches the CreateScreen/SetUpScreen
' gadget-construction family (TScreen_EditCompetition.CreateScreen is the closest twin and
' supplied the CreateButton/CreateTable/CreateCombo argument orders used below).
'
' ASSUMPTIONS -- module Globals (NAMES ARE OURS; the declared TYPE is load-bearing because
' it selects the vtable slot for every call made through it):
'   0x00C6E950 g_pathPrefix:String            install-path prefix (same slot TCard.CreateCard /
'     TScreen_EditCompetition.CreateScreen use)
'   0x00C65574 g_screen_competitions:TScreen   construction site = TScreen.CreateScreen
'   0x00C65588 g_comptable:TTable              construction site = TTable.CreateTable; the
'     SAME Global the banked SetUpScreen/ButtonEdit/ButtonDelete/ButtonDuplicate already use
'   0x00C65578 g_comp_combo1:TCombo   0x00C6557C g_comp_combo2:TCombo
'   0x00C65580 g_comp_combo3:TCombo   0x00C65584 g_comp_combo4:TCombo
'     (all four already used by the banked SetUpScreen/ComboLevel/ComboLocale)
'
' Class-table slots resolved via class_tables.tsv (base 0x00C656BC) / vtable_map.tsv:
'   0x00C61C64 TScreen+0x38    CreateScreen($,:TImage,()i,()i):TScreen
'   0x00C623CC TButton+0x88    CreateButton (15-arg sig, see vtable_map)
'   0x00C62BAC TTable+0x88     CreateTable  (11-arg sig)
'   0x00C630E0 TCombo+0x88     CreateCombo  (13-arg sig)
'   TScreen+0x40 = AddGadget(:TGadget)i;  TTable+0x90 = AddColumn(i,$,$,$,i)i;
'   TCombo+0x90 = AddItem($,$,$,i)i;  TCombo+0xac = SelectItem(i)i
'   This Type's OWN class-table slots (0x00C656EC base+0x30 .. +0x58), read as
'   `push dword ptr [classtable+slot]` when passed as a callback VALUE, not called:
'     +0x34 SetUpScreen  +0x38 ButtonQuit  +0x3c ButtonEdit  +0x40 ButtonDelete
'     +0x44 ButtonDuplicate  +0x48 ButtonNew  +0x4c ButtonInflateIds  +0x50 ButtonCompressIds
'   0x00C65EDC = TScreen_Calendar.SetUpScreen (same slot TScreen_EditCompetition.CreateScreen
'     uses for its own Calendar button).
'
' 0x004C5549 = GetText (one argument -- Ghidra/decompiled pushes around it belong to the
' OUTER CreateButton/CreateTable/CreateCombo/AddColumn/AddItem call, per codegen-patterns 3a).
' Every string literal below was read out of NSS5.exe with harness.read_string -- the oracle
' masks a literal ADDRESS, so the TEXT is not certified by the MATCH.
' "ID"/"Name" and the "tla_*" column keys all go through GetText; "000000"/"AAAAAA"/etc are
' raw colour literals, not GetText keys -- same convention as TScreen_EditCompetition.
'!Global g_pathPrefix:String
'!Global g_screen_competitions:TScreen
'!Global g_comptable:TTable
'!Global g_comp_combo1:TCombo
'!Global g_comp_combo2:TCombo
'!Global g_comp_combo3:TCombo
'!Global g_comp_combo4:TCombo
	Function CreateScreen()
		g_screen_competitions = TScreen.CreateScreen("competitions", LoadImage(g_pathPrefix + "GameMedia/Images/Backgrounds/Grass.png", -1), Null, Null)
		g_screen_competitions.AddGadget(TButton.CreateButton("pan_title", GetText("Competitions"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_screen_competitions.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
		g_comptable = TTable.CreateTable("tbl_comps", 10, 80, 23, 0, 1, 2, "0000FF", 1.0, 1, Null)
		g_comptable.AddColumn(40, GetText("ID"), "000000", "AAAAAA", 1)
		g_comptable.AddColumn(220, GetText("Name"), "000000", "FFFFFF", 0)
		g_comptable.AddColumn(0, GetText("tla_Abbreviation"), "000000", "AAAAAA", 1)
		g_comptable.AddColumn(30, GetText("tla_Based"), "000000", "CCCCCC", 1)
		g_comptable.AddColumn(30, GetText("tla_Level"), "000000", "AAAAAA", 1)
		g_comptable.AddColumn(30, GetText("tla_Locale"), "000000", "CCCCCC", 1)
		g_comptable.AddColumn(30, GetText("tla_Type"), "000000", "AAAAAA", 1)
		g_comptable.AddColumn(60, GetText("tla_YearWeek"), "000000", "CCCCCC", 1)
		g_comptable.AddColumn(30, GetText("tla_Recurring"), "000000", "CCCCCC", 1)
		g_comptable.AddColumn(30, GetText("tla_Duration"), "000000", "AAAAAA", 1)
		g_comptable.AddColumn(30, GetText("tla_Matchday1"), "000000", "AAAAAA", 1)
		g_comptable.AddColumn(30, GetText("tla_Matchday2"), "000000", "CCCCCC", 1)
		g_comptable.AddColumn(30, GetText("tla_Groups"), "000000", "AAAAAA", 1)
		g_comptable.AddColumn(30, GetText("tla_Rounds"), "000000", "CCCCCC", 1)
		g_comptable.AddColumn(60, GetText("tla_Legs"), "000000", "AAAAAA", 1)
		g_comptable.AddColumn(40, GetText("tla_Region"), "000000", "CCCCCC", 1)
		g_comptable.AddColumn(30, GetText("tla_Status"), "000000", "AAAAAA", 1)
		g_screen_competitions.AddGadget(g_comptable)
		g_comp_combo1 = TCombo.CreateCombo("cmb_lvl", GetText("Any Level"), 10, 50, 120, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboLevel, 1)
		g_comp_combo1.AddItem(GetText("Club"), "FFFFFF", "FFFFFF", 0)
		g_comp_combo1.AddItem(GetText("International"), "FFFFFF", "FFFFFF", 0)
		g_screen_competitions.AddGadget(g_comp_combo1)
		g_comp_combo2 = TCombo.CreateCombo("cmb_loc", GetText("Any Locale"), 140, 50, 120, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboLocale, 1)
		g_screen_competitions.AddGadget(g_comp_combo2)
		g_comp_combo3 = TCombo.CreateCombo("cmb_Based", GetText("Based"), 270, 50, 120, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, SetUpScreen, 1)
		g_screen_competitions.AddGadget(g_comp_combo3)
		g_comp_combo4 = TCombo.CreateCombo("cmb_type", GetText("Any Comp Type"), 400, 50, 140, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, SetUpScreen, 1)
		g_comp_combo4.AddItem(GetText("comptype_League"), "FFFFFF", "FFFFFF", 0)
		g_comp_combo4.AddItem(GetText("comptype_KO"), "FFFFFF", "FFFFFF", 0)
		g_comp_combo4.AddItem(GetText("comptype_BestPlaced"), "FFFFFF", "FFFFFF", 0)
		g_comp_combo4.AddItem(GetText("comptype_Pool"), "FFFFFF", "FFFFFF", 0)
		g_comp_combo4.AddItem(GetText("comptype_LeagueCont"), "FFFFFF", "FFFFFF", 0)
		g_comp_combo4.AddItem(GetText("comptype_RegionalSort"), "FFFFFF", "FFFFFF", 0)
		g_comp_combo4.SelectItem(0)
		g_screen_competitions.AddGadget(g_comp_combo4)
		g_screen_competitions.AddGadget(TButton.CreateButton("competitions_calendar", GetText("Calendar"), 690, 50, 100, 20, 1, 2, "FF99FF", "FFFFFF", Null, TScreen_Calendar.SetUpScreen, 1.0, 1, ""))
		g_screen_competitions.AddGadget(TButton.CreateButton("competitions_edit", GetText("Edit"), 120, 570, 100, 20, 1, 2, "00FFFF", "FFFFFF", Null, ButtonEdit, 1.0, 1, ""))
		g_screen_competitions.AddGadget(TButton.CreateButton("competitions_delete", GetText("Delete"), 230, 570, 100, 20, 1, 2, "FF0000", "FFFFFF", Null, ButtonDelete, 1.0, 1, ""))
		g_screen_competitions.AddGadget(TButton.CreateButton("competitions_duplicate", GetText("Duplicate"), 340, 570, 100, 20, 1, 2, "FF9900", "FFFFFF", Null, ButtonDuplicate, 1.0, 1, ""))
		g_screen_competitions.AddGadget(TButton.CreateButton("competitions_new", GetText("New"), 450, 570, 100, 20, 1, 2, "00FF00", "FFFFFF", Null, ButtonNew, 1.0, 1, ""))
		g_screen_competitions.AddGadget(TButton.CreateButton("competitions_inflate", GetText("Inflate IDs"), 560, 570, 110, 20, 1, 2, "FFFF99", "FFFFFF", Null, ButtonInflateIds, 1.0, 1, ""))
		g_screen_competitions.AddGadget(TButton.CreateButton("competitions_compress", GetText("Compress IDs"), 680, 570, 110, 20, 1, 2, "99FFFF", "FFFFFF", Null, ButtonCompressIds, 1.0, 1, ""))
	End Function
