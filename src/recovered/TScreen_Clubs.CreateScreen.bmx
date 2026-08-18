' TScreen_Clubs.CreateScreen
' VA 0x0052B62C   2176 bytes   mode=reloc   byte-identical vs NSS5.exe (2176/2176)
' Verified with NSS5_NO_LEARN=1 (learned_helpers=None), reloc_masked=235.
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' ASSUMPTIONS -- module Globals (names ours; the ADDRESS is the load-bearing part).
' All seven per-Type Globals are the SAME addresses TScreen_Clubs.SetUpScreen already
' uses and already names (src/recovered/TScreen_Clubs.SetUpScreen.bmx) -- this function
' constructs every gadget SetUpScreen later reads/updates, so the identifiers are reused
' verbatim, not reinvented:
'   0x00C65230 g_clubs_screen:TScreen       (NEW here -- not referenced by SetUpScreen)
'   0x00C65234 g_clubs_combolocale:TCombo   ) already banked by SetUpScreen /
'   0x00C65238 g_clubs_combobased:TCombo    ) ComboLocale / ComboBased; corroborated
'   0x00C6523C g_clubs_combocomp:TCombo     ) here by identical slot 0x90 AddItem /
'   0x00C65240 g_clubs_table:TTable         ) 0x90 AddColumn / 0x40 AddGadget traffic.
'   0x00C65244 g_clubs_title:TButton
'   0x00C65248 g_clubs_btnnames:TButton
'   0x00C6E950 g_mediapath:String           (already banked; concatenated with the
'                                             background path before LoadImage)
'
' Class-table slots resolved via class_tables.tsv (TScreen_Clubs classtable_va =
' 0x00C65368) + vtable_map.tsv -- the eight own-Type Function/Method values passed as
' ()i callback arguments are read INDIRECTLY (`push dword ptr [classtable+slot]`), never
' pushed as a bare constant, which is how their identity was confirmed without guessing:
'   0x00C6539C = +0x34 SetUpScreen   (onSelect of the "competition" combo)
'   0x00C653A0 = +0x38 ComboLocale   (onSelect of the "locale" combo)
'   0x00C653A4 = +0x3C ComboBased    (onSelect of the "based" combo)
'   0x00C653A8 = +0x40 ButtonQuit    (onClick of "quit")
'   0x00C653AC = +0x44 ButtonEdit    (onClick of "clubs_edit")
'   0x00C653B0 = +0x48 ButtonDelete  (onClick of "clubs_delete")
'   0x00C653B4 = +0x4C ButtonNew     (onClick of "clubs_new")
'   0x00C653B8 = +0x50 ButtonSwitchNames (onClick of "clubs_switchnames")
' Other resolved slots/calls: 0x00C61C64 = TScreen+0x38 CreateScreen($,:TImage,()i,()i),
' 0x00C623CC = TButton+0x88 CreateButton (15-arg, verified via 0x3C=60-byte add esp),
' 0x00C62BAC = TTable+0x88 CreateTable (11-arg), 0x00C630E0 = TCombo+0x88 CreateCombo
' (13-arg), TScreen slot 0x40 = AddGadget(:TGadget)i, TTable slot 0x90 = AddColumn
' (i,$,$,$,i), TCombo slot 0x90 = AddItem($,$,$,i)i (a DIFFERENT Type sharing the same
' slot number -- confirmed per-call by which Global was reloaded into ebx first).
' 0x004C5549 = GetText (single-arg module Function; Ghidra merges its argument with the
' surrounding pushes -- confirmed by the `add esp,4` after each call). 0x004A7C20 =
' _bbStringConcat (used for GetText("tla_Rival") + "1"/"2"/"3", table columns 7-9).
' 0x005AE256 = brl.max2d LoadImage (2nd arg -1 = default flags, pushed early and
' reunited with the concat result at the call site -- same eager-constant pattern as the
' Null onClick/onSelect constants below). 0x005B95D0 = the empty-function sentinel, i.e.
' source-level Null for a ()i argument (pushed as a literal constant, unlike the eight
' real callbacks above which are class-table reads). 0x005C9C80 = bbNullObject, Null for
' an object argument. 0x005C7D40 = the compiler-substituted default for an omitted
' trailing String parameter (every CreateButton's final "" argument).
'
' MEASURED SHAPE
'   * No `sub esp,N` -- every value here is either an immediate, a Global reload, or a
'     one-shot call result; nothing needed a spill slot. Only `ebx` (pushed/popped once)
'     is saved, and it is reused throughout purely as a receiver-cache register, never a
'     declared Local.
'   * The table gets 17 AddColumn calls (columns 0..16), matching exactly the 17-case
'     SetColumnWidth loop in the already-banked TScreen_Clubs.SetUpScreen -- confirmation
'     that this is the same table being populated in two stages by two functions.
'   * Three column headers are built with a real _bbStringConcat: GetText("tla_Rival")
'     is concatenated with a bare "1"/"2"/"3" (no space, unlike TScreen_EditClubs's
'     GetText("Rival") + " 1" row labels -- the two screens format the same idea
'     differently and both are reproduced as written).
'   * Two gadgets (g_clubs_title, g_clubs_btnnames) are stored to a Global with full
'     refcount teardown of the old value instead of an immediate AddGadget, exactly like
'     g_clubs_screen and the three combos -- AddGadget for those two happens in a
'     separate statement right after, reading the Global back.
'   * Every CreateButton's trailing align/"" pair and the button colours were read raw
'     with harness.read_string, since the oracle masks a literal's ADDRESS, not its
'     content -- a MATCH does not by itself certify the strings below.
'
' Literals (address -> content, harness.read_string):
'   0x00C82848 'GameMedia/Images/Backgrounds/Grass.png'   0x00C83224 'clubs'
'   0x00C824E4 'Clubs'    0x00C828C8 'Menu'    0x00C7E48C 'pan_title'  0x00C7E818 'quit'
'   0x00C7E894 'EEEEEE'   0x00C5D680 'FFFFFF'  0x00C725EC 'FF0000'  0x00C6FC58 '000000'
'   0x00C8323C 'tbl_clubs'  0x00C72868 '0000FF'
'   table columns, in order: 0x00C82900 'ID', 0x00C82910 'Name', 0x00C82BC4 'Short Name',
'     0x00C8325C 'tla_Abbreviation', 0x00C83288 'Nick Name', 0x00C832A8 'tla_Strength',
'     0x00C832CC 'tla_Rival' (+"1"/"2"/"3" at 0x00C740A4/0x00C832EC/0x00C832FC),
'     0x00C8330C 'tla_Nation', 0x00C81360 'League', 0x00C8332C 'tla_ContinentalComp',
'     0x00C83360 'B Team Of', 0x00C83380 'Stadium', 0x00C8339C 'tla_Capacity',
'     0x00C833C0 'tla_Longitude', 0x00C833E8 'tla_Latitude'.
'     Column colours: color1 is 0x00C6FC58 '000000' throughout; color2 is 0x00C7E268
'     'AAAAAA' for columns 0 and 3 (ID, Abbreviation) and 0x00C5D680 'FFFFFF' elsewhere.
'   combos: 0x00C8340C 'Locale'/0x00C83424 'cmb_loc', 0x00C7CFF8 'Nation',
'     0x00C7D010 'Continent', 0x00C83440 'Based'/0x00C83458 'cmb_based',
'     0x00C83478 'Competition'/0x00C8349C 'cmb_competition'; combo colours
'     0x00C725B8 'FFFF00' / 0x00C5D680 'FFFFFF'.
'   buttons: 0x00C75434 '00FFFF'/0x00C834C8 'Edit'/0x00C834DC 'clubs_edit',
'     0x00C7E930 'Delete'/0x00C834FC 'clubs_delete',
'     0x00C6E904 '00FF00'/0x00C83520 'New'/0x00C83534 'clubs_new',
'     0x00C7E268 'AAAAAA'/0x00C83554 'btn_MemberCount' (this is g_clubs_title),
'     0x00C83580 '99FFFF'/0x00C83598 'Show Names'/0x00C835B8 'clubs_switchnames'
'     (this is g_clubs_btnnames).
'!Global g_clubs_screen:TScreen
'!Global g_clubs_combolocale:TCombo
'!Global g_clubs_combobased:TCombo
'!Global g_clubs_combocomp:TCombo
'!Global g_clubs_table:TTable
'!Global g_clubs_title:TButton
'!Global g_clubs_btnnames:TButton
'!Global g_mediapath:String
	g_clubs_screen = TScreen.CreateScreen("clubs", LoadImage(g_mediapath + "GameMedia/Images/Backgrounds/Grass.png"), Null, Null)
	g_clubs_screen.AddGadget(TButton.CreateButton("pan_title", GetText("Clubs"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
	g_clubs_screen.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
	g_clubs_table = TTable.CreateTable("tbl_clubs", 10, 80, 23, 0, 1, 2, "0000FF", 1.0, 1, Null)
	g_clubs_table.AddColumn(30, GetText("ID"), "000000", "AAAAAA", 1)
	g_clubs_table.AddColumn(120, GetText("Name"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(0, GetText("Short Name"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(0, GetText("tla_Abbreviation"), "000000", "AAAAAA", 0)
	g_clubs_table.AddColumn(0, GetText("Nick Name"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(25, GetText("tla_Strength"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(60, GetText("tla_Rival") + "1", "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(60, GetText("tla_Rival") + "2", "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(60, GetText("tla_Rival") + "3", "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(30, GetText("tla_Nation"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(80, GetText("League"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(80, GetText("tla_ContinentalComp"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(60, GetText("B Team Of"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(60, GetText("Stadium"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(60, GetText("tla_Capacity"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(30, GetText("tla_Longitude"), "000000", "FFFFFF", 0)
	g_clubs_table.AddColumn(30, GetText("tla_Latitude"), "000000", "FFFFFF", 0)
	g_clubs_screen.AddGadget(g_clubs_table)
	g_clubs_combolocale = TCombo.CreateCombo("cmb_loc", GetText("Locale"), 10, 50, 120, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboLocale, 1)
	g_clubs_combolocale.AddItem(GetText("Nation"), "FFFFFF", "FFFFFF", 0)
	g_clubs_combolocale.AddItem(GetText("Continent"), "FFFFFF", "FFFFFF", 0)
	g_clubs_screen.AddGadget(g_clubs_combolocale)
	g_clubs_combobased = TCombo.CreateCombo("cmb_based", GetText("Based"), 140, 50, 120, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboBased, 1)
	g_clubs_screen.AddGadget(g_clubs_combobased)
	g_clubs_combocomp = TCombo.CreateCombo("cmb_competition", GetText("Competition"), 270, 50, 200, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, SetUpScreen, 1)
	g_clubs_screen.AddGadget(g_clubs_combocomp)
	g_clubs_screen.AddGadget(TButton.CreateButton("clubs_edit", GetText("Edit"), 470, 570, 100, 20, 1, 2, "00FFFF", "FFFFFF", Null, ButtonEdit, 1.0, 1, ""))
	g_clubs_screen.AddGadget(TButton.CreateButton("clubs_delete", GetText("Delete"), 580, 570, 100, 20, 1, 2, "FF0000", "FFFFFF", Null, ButtonDelete, 1.0, 1, ""))
	g_clubs_screen.AddGadget(TButton.CreateButton("clubs_new", GetText("New"), 690, 570, 100, 20, 1, 2, "00FF00", "FFFFFF", Null, ButtonNew, 1.0, 1, ""))
	g_clubs_title = TButton.CreateButton("btn_MemberCount", GetText("Clubs"), 480, 50, 200, 20, 0, 2, "AAAAAA", "FFFFFF", Null, Null, 1.0, 1, "")
	g_clubs_screen.AddGadget(g_clubs_title)
	g_clubs_btnnames = TButton.CreateButton("clubs_switchnames", GetText("Show Names"), 690, 50, 100, 20, 1, 2, "99FFFF", "FFFFFF", Null, ButtonSwitchNames, 1.0, 1, "")
	g_clubs_screen.AddGadget(g_clubs_btnnames)
	Return 0
