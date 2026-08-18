' TScreen_Continents.CreateScreen
' VA 0x00546597   3130 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' (3130/3130, original length from Ghidra's inventory; verified with NSS5_NO_LEARN=1 so no
'  call operand was masked by a name this run itself taught.)
'
' The prologue is `push ebp / mov ebp,esp / push ebx` with NO `sub esp,N` (16.3): the
' original declares ZERO Locals, so every gadget is a single inline statement and every
' receiver is re-read from its Global.  The whole body is 59 statements of straight-line
' gadget construction; there is no control flow at all.
'
' ASSUMPTIONS -- module Globals (names ours; the ADDRESS is the load-bearing part).
' Types are globals_final.tsv type_source=construction (read off the factory's declared
' return type at the store site) and each is corroborated by the slot used through it
' (0x40 = TScreen.AddGadget, 0x74 = TGadget.AddChild inherited by TPanel, 0x90 =
' TTable.AddColumn).
'   0x00C671C4 -> g_continents_screen:TScreen              (from TScreen.CreateScreen)
'   0x00C671C8 -> g_continents_panTable:TPanel
'   0x00C671CC -> g_continents_tblTable:TTable
'   0x00C671D0 -> g_continents_panFixtures:TPanel
'   0x00C671D4 -> g_continents_tblFixturesLeague:TTable
'   0x00C671D8 -> g_continents_tblFixturesClub:TTable
'   0x00C671DC -> g_continents_btnLevel:TButton
'   0x00C671E0 -> g_continents_cmbContinent:TCombo
'   0x00C671E4 -> g_continents_cmbCompetition:TCombo
'   0x00C671E8 -> g_continents_cmbTeam:TCombo
'   0x00C671F0/F4/F8/FC, 0x00C67200 -> g_continents_btnGroupsFirst/Left/Group/Right/Last:TButton
'   0x00C6720C/10/14/18/1C -> g_continents_btnFixturesFirst/Left/Round/Right/Last:TButton
'   0x00C667B0 -> g_panMenu:TPanel   (shared; added to this screen with AddGadget)
'   0x00C66F08 -> g_iconLevel:TImage (globals_final says Object; it is pushed as
'                 CreateButton's :TImage parameter, so TImage is forced by the signature)
'   0x00C6EFDC -> g_screenwidth:Int  (pushed as CreatePanel's `w`; a bare dword push with
'                 no refcount traffic, so Int -- rule 11.2)
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
'   Own-Type callbacks (same Type -> bare name, no Type. prefix):
'     +0x40 ComboContinent  +0x44 ComboCompetition  +0x48 ComboTeam
'     +0x50 ButtonFixturesFirst +0x54 ButtonFixturesLeft +0x58 ButtonRound
'     +0x5C ButtonFixturesRight +0x60 ButtonFixturesLast
'     +0x68 ButtonGroupsFirst +0x6C ButtonGroupsLeft +0x70 ButtonGroup
'     +0x74 ButtonGroupsRight +0x78 ButtonGroupsLast +0x7C ButtonLevel
'
' Helpers: 0x004C5549 = GetText (recovered module Function; Ghidra MERGES its single
' argument with the pushes that follow -- read the `add esp,4`).  0x004A8590 = _bbGCFree
' (the inlined BBRELEASE of each Global's old value, never written in source).
' 0x005B95D0 = the empty function = source-level Null for an ()i argument.
' 0x005C9C80 = bbNullObject = Null for an object argument.
'
' EMPTY-STRING FORMS -- Null vs "".  NSS5 pushes TWO different zero-length BBStrings here:
'   0x005C7D40  refs=0x40000000  the runtime's shared bbEmptyString (in `.data`)
'   0x00C5D284  refs=0x7FFFFFFF  a bcc-pooled string LITERAL (in `data`)
' The oracle masks both (each is an in-image address), so a MATCH cannot tell them apart.
' They were separated by an independent check: classify all 18 empty-string pushes in each
' image by the refs marker of the object they point at, and compare the sequences.
'   `""` everywhere        -> ours L L L L L L L L L L L L L L L L L L   (orig differs)
'   this body              -> ours L E E E E E L E E L L L E E E L E E == ORIGINAL, exactly
' So `Null` in a `$` parameter lowers to bbEmptyString and `""` lowers to a pooled literal.
' CreateButton's 15th argument is `Null` at all eleven sites, and btn_level's text is `Null`
' too; the four genuine `""` texts (pan_title, pan_table, btn_round, btn_group) and the two
' blank AddColumn headers are literals.  Both spellings give 3130/3130, but only this one
' reproduces the `data`-section references, which spec 24.3 depends on.
'
' Literals were read out of NSS5.exe with harness.read_string -- the oracle masks a
' literal's ADDRESS, so their CONTENT is not certified by the MATCH, only by that read.
' All 50 were read; the non-obvious ones are the locale keys "tla_Position", "tla_Played",
' "tla_Won", "tla_Drawn", "tla_Lost", "sla_GoalsFor", "sla_GoalsAgainst",
' "tla_GoalDifference", "tla_Points" (note "sla_" on the two Goals columns, not "tla_").
' The two panel alphas are 0x3F4CCCCD = 0.8; every other float is 0x3F800000 = 1.0.
'!Global g_continents_screen:TScreen
'!Global g_continents_panTable:TPanel
'!Global g_continents_tblTable:TTable
'!Global g_continents_panFixtures:TPanel
'!Global g_continents_tblFixturesLeague:TTable
'!Global g_continents_tblFixturesClub:TTable
'!Global g_continents_btnLevel:TButton
'!Global g_continents_cmbContinent:TCombo
'!Global g_continents_cmbCompetition:TCombo
'!Global g_continents_cmbTeam:TCombo
'!Global g_continents_btnGroupsFirst:TButton
'!Global g_continents_btnGroupsLeft:TButton
'!Global g_continents_btnGroup:TButton
'!Global g_continents_btnGroupsRight:TButton
'!Global g_continents_btnGroupsLast:TButton
'!Global g_continents_btnFixturesFirst:TButton
'!Global g_continents_btnFixturesLeft:TButton
'!Global g_continents_btnRound:TButton
'!Global g_continents_btnFixturesRight:TButton
'!Global g_continents_btnFixturesLast:TButton
'!Global g_panMenu:TPanel
'!Global g_iconLevel:TImage
'!Global g_screenwidth:Int
	g_continents_screen = TScreen.CreateScreen("continents", Null, Null, Null)
	g_continents_screen.AddGadget(TPanel.CreatePanel("pan_title", "", 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1))
	g_continents_screen.AddGadget(g_panMenu)
	g_continents_btnLevel = TButton.CreateButton("btn_level", Null, 10, 10, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_iconLevel, ButtonLevel, 1.0, 1, Null)
	g_continents_cmbContinent = TCombo.CreateCombo("cmb_Continent", GetText("Continent"), 140, 10, 140, 40, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboContinent, 4)
	g_continents_cmbCompetition = TCombo.CreateCombo("cmb_Competition", GetText("Competition"), 280, 10, 300, 40, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboCompetition, 0)
	g_continents_cmbTeam = TCombo.CreateCombo("cmb_Team", GetText("Team"), 580, 10, 210, 40, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboTeam, 5)
	g_continents_screen.AddGadget(g_continents_btnLevel)
	g_continents_screen.AddGadget(g_continents_cmbContinent)
	g_continents_screen.AddGadget(g_continents_cmbCompetition)
	g_continents_screen.AddGadget(g_continents_cmbTeam)
	g_continents_panFixtures = TPanel.CreatePanel("panfixtures", GetText("Fixtures"), 410, 70, 380, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 1)
	g_continents_screen.AddGadget(g_continents_panFixtures)
	g_continents_btnFixturesFirst = TButton.CreateButton("btn_roundll", "<<", 415, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixturesFirst, 1.0, 4, Null)
	g_continents_btnFixturesLeft = TButton.CreateButton("btn_roundl", "<", 445, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixturesLeft, 1.0, 0, Null)
	g_continents_btnRound = TButton.CreateButton("btn_round", "", 475, 75, 250, 20, 1, 2, "888888", "FFFFFF", Null, ButtonRound, 1.0, 0, Null)
	g_continents_btnFixturesRight = TButton.CreateButton("btn_roundr", ">", 725, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixturesRight, 1.0, 0, Null)
	g_continents_btnFixturesLast = TButton.CreateButton("btn_roundrr", ">>", 755, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonFixturesLast, 1.0, 5, Null)
	g_continents_panFixtures.AddChild(g_continents_btnFixturesFirst)
	g_continents_panFixtures.AddChild(g_continents_btnFixturesLeft)
	g_continents_panFixtures.AddChild(g_continents_btnRound)
	g_continents_panFixtures.AddChild(g_continents_btnFixturesRight)
	g_continents_panFixtures.AddChild(g_continents_btnFixturesLast)
	g_continents_tblFixturesClub = TTable.CreateTable("tbl_fixturesclub", 410, 100, 20, 0, 1, 2, "00FF00", 1.0, 1, Null)
	g_continents_tblFixturesClub.AddColumn(38, GetText("Week"), "000000", "EEEEEE", 1)
	g_continents_tblFixturesClub.AddColumn(90, GetText("Competition"), "000000", "DDDDDD", 1)
	g_continents_tblFixturesClub.AddColumn(150, GetText("Opponent"), "000000", "FFFFFF", 1)
	g_continents_tblFixturesClub.AddColumn(78, GetText("Result"), "000000", "DDDDDD", 1)
	g_continents_tblFixturesClub.AddColumn(20, "", "000000", "EEEEEE", 1)
	g_continents_tblFixturesLeague = TTable.CreateTable("tbl_fixturesleague", 410, 100, 20, 0, 1, 2, "00FF00", 1.0, 1, Null)
	g_continents_tblFixturesLeague.AddColumn(150, GetText("Home Team"), "000000", "FFFFFF", 1)
	g_continents_tblFixturesLeague.AddColumn(78, "", "000000", "EEEEEE", 1)
	g_continents_tblFixturesLeague.AddColumn(150, GetText("Away Team"), "000000", "FFFFFF", 1)
	g_continents_panFixtures.AddChild(g_continents_tblFixturesClub)
	g_continents_panFixtures.AddChild(g_continents_tblFixturesLeague)
	g_continents_panTable = TPanel.CreatePanel("pan_table", "", 10, 70, 390, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 430, 1)
	g_continents_btnGroupsFirst = TButton.CreateButton("btn_groupll", "<<", 15, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonGroupsFirst, 1.0, 4, Null)
	g_continents_btnGroupsLeft = TButton.CreateButton("btn_groupl", "<", 45, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonGroupsLeft, 1.0, 0, Null)
	g_continents_btnGroup = TButton.CreateButton("btn_group", "", 75, 75, 260, 20, 1, 2, "888888", "FFFFFF", Null, ButtonGroup, 1.0, 0, Null)
	g_continents_btnGroupsRight = TButton.CreateButton("btn_groupr", ">", 335, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonGroupsRight, 1.0, 0, Null)
	g_continents_btnGroupsLast = TButton.CreateButton("btn_grouprr", ">>", 365, 75, 30, 20, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonGroupsLast, 1.0, 5, Null)
	g_continents_tblTable = TTable.CreateTable("tbl_table", 10, 100, 20, 0, 1, 2, "00FF00", 1.0, 1, Null)
	g_continents_tblTable.AddColumn(30, GetText("tla_Position"), "000000", "EEEEEE", 1)
	g_continents_tblTable.AddColumn(111, GetText("Name"), "000000", "FFFFFF", 0)
	g_continents_tblTable.AddColumn(30, GetText("tla_Played"), "000000", "EEEEEE", 1)
	g_continents_tblTable.AddColumn(30, GetText("tla_Won"), "000000", "DDDDDD", 1)
	g_continents_tblTable.AddColumn(30, GetText("tla_Drawn"), "000000", "EEEEEE", 1)
	g_continents_tblTable.AddColumn(30, GetText("tla_Lost"), "000000", "DDDDDD", 1)
	g_continents_tblTable.AddColumn(30, GetText("sla_GoalsFor"), "000000", "EEEEEE", 1)
	g_continents_tblTable.AddColumn(30, GetText("sla_GoalsAgainst"), "000000", "DDDDDD", 1)
	g_continents_tblTable.AddColumn(30, GetText("tla_GoalDifference"), "000000", "EEEEEE", 1)
	g_continents_tblTable.AddColumn(30, GetText("tla_Points"), "000000", "DDDDDD", 1)
	g_continents_screen.AddGadget(g_continents_panTable)
	g_continents_panTable.AddChild(g_continents_btnGroupsFirst)
	g_continents_panTable.AddChild(g_continents_btnGroupsLeft)
	g_continents_panTable.AddChild(g_continents_btnGroup)
	g_continents_panTable.AddChild(g_continents_btnGroupsRight)
	g_continents_panTable.AddChild(g_continents_btnGroupsLast)
	g_continents_panTable.AddChild(g_continents_tblTable)
