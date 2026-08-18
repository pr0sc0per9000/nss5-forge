' GLOBAL RENAMED (2026-08-15): g_mediapath -> g_iconpath in THIS file only.
' 0x00C6F170 is the GameMedia/Images/Icons/ root. The corpus uses the identifier
' g_mediapath for TWO different slots -- 0x00C6F170 here and in 8 other files, and
' 0x00C6E950 (the install root) in 9 OTHERS. One name, two slots, an exact 9/9 split,
' so no single value assigned to g_mediapath could ever be right at every call site:
' whichever way it went, half the asset paths resolved wrong and ~100 images failed to
' load. Per-body verification cannot catch this -- a Global reaches the compiled code
' only as an absolute address and the byte oracle masks those, so both spellings
' verify byte-perfectly. Renaming is byte-neutral; scripts/reverify.py confirms it.
' See scripts/unify_globals.py for the rest of this defect class.
' TScreen_Leagues.CreateScreen
' VA 0x005444CF   2921 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' (2921/2921, original length from Ghidra's inventory; verified with NSS5_NO_LEARN=1 so no
'  call operand was masked by a name this run itself taught.  reloc_masked=308.)
'
' The prologue is `push ebp / mov ebp,esp / push ebx` with NO `sub esp,N` (16.3): the
' original declares ZERO Locals.  Every gadget is a single inline statement and every
' receiver is re-read from its Global.  The only control flow is the one-time image guard.
'
' FAMILY (12.2).  This is the near-twin of TScreen_Continents.CreateScreen (0x00546597,
' 3130 bytes, already verified): same panel/combo/button/table skeleton, same fixtures block,
' same ten league-table columns.  Leagues drops Continents' five group buttons and adds the
' three-icon load guard, which is where most of the 209-byte difference comes from.
' The differences that are NOT cosmetic and were read off the disassembly, not assumed:
'   * btn_level's text is `GetText("Club")` here; Continents passes `Null`.
'   * both panels' alpha is 1.0 (0x3F800000); Continents' panFixtures/panTable use 0.8.
'   * pan_table's text is `GetText("League")` here; Continents passes `""`.
'   * the "Week" column's first colour is "333333", not Continents' "000000".
'
' ASSUMPTIONS -- module Globals (names are ours; the ADDRESS is the load-bearing part).
' Types are globals_final.tsv type_source=construction (the factory's declared return type
' at the store site) and each is corroborated by the slot used through it (0x40 =
' TScreen.AddGadget, 0x74 = TGadget.AddChild inherited by TPanel, 0x90 = TTable.AddColumn).
'   0x00C66F00 -> g_leagues_screen:TScreen           (from TScreen.CreateScreen)
'   0x00C66F04 -> g_iconWorld:TImage                 } assigned from LoadImageChecked, and
'   0x00C66F08 -> g_iconCountry:TImage               } g_iconClub is passed as
'   0x00C66F0C -> g_iconClub:TImage                  } CreateButton's :TImage argument 11,
'                                                      so TImage is forced by the signature
'   0x00C66F10 -> g_leagues_panTitle:TPanel
'   0x00C66F18 -> g_leagues_panTable:TPanel
'   0x00C66F1C -> g_leagues_panFixtures:TPanel
'   0x00C66F20 -> g_leagues_tblTable:TTable
'   0x00C66F24 -> g_leagues_tblFixturesLeague:TTable
'   0x00C66F28 -> g_leagues_tblFixturesClub:TTable
'   0x00C66F2C -> g_leagues_btnLevel:TButton
'   0x00C66F30/34/38/3C -> g_combo_continent/nation/league/club:TCombo
'       These four are the SAME Globals, at the same addresses and with the same names and
'       types, that src/recovered/TScreen_Leagues.SetUpScreen.bmx already declares -- an
'       independent corroboration of the TCombo typing from another verified body.
'   0x00C66F48/4C/50/54/58 ->
'       g_leagues_btnFixturesFirst/Left/Round/Right/Last:TButton
'   0x00C667B0 -> g_panMenu:TPanel   (shared menu panel; added with AddGadget, never built
'                 here.  Same Global TScreen_Continents.CreateScreen adds.)
'   0x00C6F170 -> g_iconpath:String  (globals_final.tsv calls this Int and is WRONG -- it is
'                 pushed straight into _bbStringConcat, exactly as in TScreen_Home /
'                 TScreen_Abilities / TScreen_WorldMap.CreateScreen; rule 11.2)
'   0x00C6EFDC -> g_screenwidth:Int   (pushed as CreatePanel's `w`; a bare dword push with no
'                 refcount traffic, so Int -- rule 10.7)
'
' Class-table slots resolved via class_tables.tsv + vtable_map.tsv:
'   0x00C61C64 = TScreen+0x38   CreateScreen($,:TImage,()i,()i):TScreen
'   0x00C63294 = TPanel+0x88    CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'   0x00C623CC = TButton+0x88   CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'   0x00C630E0 = TCombo+0x88    CreateCombo($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo
'   0x00C62BAC = TTable+0x88    CreateTable($,i,i,i,i,i,i,$,f,i,()i):TTable
'   slot 0x40 on the TScreen Global = TScreen.AddGadget(:TGadget)i
'   slot 0x74 on the TPanel Globals = TGadget.AddChild(:TGadget)i  (INHERITED -- TPanel has
'     no 0x74 of its own; the Extends chain in class_tables.tsv is TPanel -> TGadget)
'   slot 0x90 on the TTable Globals = TTable.AddColumn(i,$,$,$,i)i
'   Own-Type callbacks (same Type -> bare name, no `TScreen_Leagues.` prefix):
'     +0x3C ComboContinent  +0x40 ComboNation  +0x44 ComboLeague  +0x48 ComboClub
'     +0x54 ButtonFixturesFirst  +0x58 ButtonFixturesLeft  +0x5C ButtonRound
'     +0x60 ButtonFixturesRight  +0x64 ButtonFixturesLast  +0x68 ButtonLevel
'
' Helpers: 0x004C5549 = GetText and 0x004BC372 = LoadImageChecked, both recovered module
' Functions.  Ghidra MERGES GetText's single argument with the pushes that follow -- read the
' `add esp,4` after the call, not Ghidra's argument list.  LoadImageChecked's second argument
' is the flags word -1, which Ghidra likewise folds into the preceding _bbStringConcat.
' 0x004A7C20 = _bbStringConcat (the `+`), 0x004A8590 = _bbGCFree (the inlined BBRELEASE of
' each Global's old value, never written in source).  0x005B95D0 = the empty function =
' source-level Null for an ()i argument.  0x005C9C80 = bbNullObject = Null for an object one.
'
' THE IMAGE GUARD is the `If Not x` form of section 10.3 -- the disassembly at 0x0054450E is
' `mov eax,[0xC66F04] / cmp eax,0x5C9C80 / setne al / movzx eax,al / cmp eax,0 / jne`, the
' 21-byte spelling.  `If g_iconWorld = Null` would be the 12-byte `cmp dword [g],... / je`.
' Ghidra prints both as `== Null`.
'
' EMPTY-STRING FORMS -- Null vs "".  NSS5 pushes TWO different zero-length BBStrings:
'   0x005C7D40  refs=0x40000000  the runtime's shared bbEmptyString (in `.data`)
'   0x00C5D284  refs=0x7FFFFFFF  a bcc-pooled string LITERAL (in `data`)
' The oracle masks both (each is an in-image address), so a MATCH cannot tell them apart.
' Separated by the independent check from TScreen_Continents.CreateScreen: classify all
' sixteen zero-length pushes in each image by the refs marker of the object they point at.
'   orig  E L E E E E E E E L E E E E L L
'   ours  E L E E E E E E E L E E E E L L      == ORIGINAL, exactly
' So CreateButton's 15th argument is `Null` at all six sites, while the four genuine `""`
' texts (pan_title, btn_round and the two blank AddColumn headers) are pooled literals.
' Both spellings give 2921/2921; only this one reproduces the `data`-section references that
' the assembler depends on.
'
' Literals were read out of NSS5.exe with harness.read_string -- the oracle masks a literal's
' ADDRESS, so their CONTENT is not certified by the MATCH, only by that read.  All 52 were
' read; the non-obvious ones are the locale keys "tla_Position", "tla_Played", "tla_Won",
' "tla_Drawn", "tla_Lost", "sla_GoalsFor", "sla_GoalsAgainst", "tla_GoalDifference",
' "tla_Points" (note "sla_" on the two Goals columns, not "tla_"), and the lower-case
' one-word gadget ids "panfixtures", "btn_roundll", "btn_roundrr".  Every float is
' 0x3F800000 = 1.0; there is no 0.8 in this function.
'!Global g_leagues_screen:TScreen
'!Global g_iconWorld:TImage
'!Global g_iconCountry:TImage
'!Global g_iconClub:TImage
'!Global g_leagues_panTitle:TPanel
'!Global g_leagues_panTable:TPanel
'!Global g_leagues_panFixtures:TPanel
'!Global g_leagues_tblTable:TTable
'!Global g_leagues_tblFixturesLeague:TTable
'!Global g_leagues_tblFixturesClub:TTable
'!Global g_leagues_btnLevel:TButton
'!Global g_combo_continent:TCombo
'!Global g_combo_nation:TCombo
'!Global g_combo_league:TCombo
'!Global g_combo_club:TCombo
'!Global g_leagues_btnFixturesFirst:TButton
'!Global g_leagues_btnFixturesLeft:TButton
'!Global g_leagues_btnRound:TButton
'!Global g_leagues_btnFixturesRight:TButton
'!Global g_leagues_btnFixturesLast:TButton
'!Global g_panMenu:TPanel
'!Global g_iconpath:String
'!Global g_screenwidth:Int
	g_leagues_screen = TScreen.CreateScreen("leagues", Null, Null, Null)
	If Not g_iconWorld
		g_iconWorld = LoadImageChecked(g_iconpath + "World.png", -1)
		g_iconCountry = LoadImageChecked(g_iconpath + "Country.png", -1)
		g_iconClub = LoadImageChecked(g_iconpath + "Club.png", -1)
	EndIf
	g_leagues_panTitle = TPanel.CreatePanel("pan_title", "", 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1)
	g_leagues_screen.AddGadget(g_leagues_panTitle)
	g_leagues_screen.AddGadget(g_panMenu)
	g_leagues_btnLevel = TButton.CreateButton("btn_level", GetText("Club"), 10, 10, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_iconClub, ButtonLevel, 1.0, 1, Null)
	g_combo_continent = TCombo.CreateCombo("cmb_Continent", GetText("Continent"), 140, 10, 120, 40, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboContinent, 4)
	g_combo_nation = TCombo.CreateCombo("cmb_Nation", GetText("Nation"), 260, 10, 120, 40, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboNation, 0)
	g_combo_league = TCombo.CreateCombo("cmb_League", GetText("League"), 380, 10, 220, 40, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboLeague, 0)
	g_combo_club = TCombo.CreateCombo("cmb_Club", GetText("Club"), 600, 10, 190, 40, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboClub, 5)
	g_leagues_screen.AddGadget(g_leagues_btnLevel)
	g_leagues_screen.AddGadget(g_combo_continent)
	g_leagues_screen.AddGadget(g_combo_nation)
	g_leagues_screen.AddGadget(g_combo_league)
	g_leagues_screen.AddGadget(g_combo_club)
	g_leagues_panFixtures = TPanel.CreatePanel("panfixtures", GetText("Fixtures"), 410, 70, 380, 30, "FFFFFF", "FFFFFF", 3, 1.0, 1, 430, 1)
	g_leagues_screen.AddGadget(g_leagues_panFixtures)
	g_leagues_btnFixturesFirst = TButton.CreateButton("btn_roundll", "<<", 415, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixturesFirst, 1.0, 4, Null)
	g_leagues_btnFixturesLeft = TButton.CreateButton("btn_roundl", "<", 445, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixturesLeft, 1.0, 0, Null)
	g_leagues_btnRound = TButton.CreateButton("btn_round", "", 475, 75, 250, 20, 1, 2, "888888", "FFFFFF", Null, ButtonRound, 1.0, 0, Null)
	g_leagues_btnFixturesRight = TButton.CreateButton("btn_roundr", ">", 725, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixturesRight, 1.0, 0, Null)
	g_leagues_btnFixturesLast = TButton.CreateButton("btn_roundrr", ">>", 755, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixturesLast, 1.0, 5, Null)
	g_leagues_panFixtures.AddChild(g_leagues_btnFixturesFirst)
	g_leagues_panFixtures.AddChild(g_leagues_btnFixturesLeft)
	g_leagues_panFixtures.AddChild(g_leagues_btnRound)
	g_leagues_panFixtures.AddChild(g_leagues_btnFixturesRight)
	g_leagues_panFixtures.AddChild(g_leagues_btnFixturesLast)
	g_leagues_tblFixturesClub = TTable.CreateTable("tbl_fixturesclub", 410, 100, 20, 0, 1, 2, "00FF00", 1.0, 1, Null)
	g_leagues_tblFixturesClub.AddColumn(38, GetText("Week"), "333333", "EEEEEE", 1)
	g_leagues_tblFixturesClub.AddColumn(90, GetText("Competition"), "000000", "DDDDDD", 1)
	g_leagues_tblFixturesClub.AddColumn(150, GetText("Opponent"), "000000", "FFFFFF", 1)
	g_leagues_tblFixturesClub.AddColumn(78, GetText("Result"), "000000", "DDDDDD", 1)
	g_leagues_tblFixturesClub.AddColumn(20, "", "000000", "EEEEEE", 1)
	g_leagues_tblFixturesLeague = TTable.CreateTable("tbl_fixturesleague", 410, 100, 20, 0, 1, 2, "00FF00", 1.0, 1, Null)
	g_leagues_tblFixturesLeague.AddColumn(150, GetText("Home Team"), "000000", "FFFFFF", 1)
	g_leagues_tblFixturesLeague.AddColumn(78, "", "000000", "EEEEEE", 1)
	g_leagues_tblFixturesLeague.AddColumn(150, GetText("Away Team"), "000000", "FFFFFF", 1)
	g_leagues_panFixtures.AddChild(g_leagues_tblFixturesClub)
	g_leagues_panFixtures.AddChild(g_leagues_tblFixturesLeague)
	g_leagues_panTable = TPanel.CreatePanel("pan_table", GetText("League"), 10, 70, 390, 30, "FFFFFF", "FFFFFF", 3, 1.0, 1, 430, 1)
	g_leagues_screen.AddGadget(g_leagues_panTable)
	g_leagues_tblTable = TTable.CreateTable("tbl_table", 10, 100, 20, 0, 1, 2, "00FF00", 1.0, 1, Null)
	g_leagues_tblTable.AddColumn(30, GetText("tla_Position"), "000000", "EEEEEE", 1)
	g_leagues_tblTable.AddColumn(111, GetText("Name"), "000000", "FFFFFF", 0)
	g_leagues_tblTable.AddColumn(30, GetText("tla_Played"), "000000", "EEEEEE", 1)
	g_leagues_tblTable.AddColumn(30, GetText("tla_Won"), "000000", "DDDDDD", 1)
	g_leagues_tblTable.AddColumn(30, GetText("tla_Drawn"), "000000", "EEEEEE", 1)
	g_leagues_tblTable.AddColumn(30, GetText("tla_Lost"), "000000", "DDDDDD", 1)
	g_leagues_tblTable.AddColumn(30, GetText("sla_GoalsFor"), "000000", "EEEEEE", 1)
	g_leagues_tblTable.AddColumn(30, GetText("sla_GoalsAgainst"), "000000", "DDDDDD", 1)
	g_leagues_tblTable.AddColumn(30, GetText("tla_GoalDifference"), "000000", "EEEEEE", 1)
	g_leagues_tblTable.AddColumn(30, GetText("tla_Points"), "000000", "DDDDDD", 1)
	g_leagues_panTable.AddChild(g_leagues_tblTable)
