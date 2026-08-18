' TScreen_EditCompetition.CreateScreen
' VA 0x00530249   5883 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
' (5883/5883, original length from Ghidra inventory, reloc_masked=588)
'
' ASSUMPTIONS -- module Globals (NAMES ARE OURS; the declared TYPE is load-bearing
' because it selects the vtable slot for every call made through it):
'   0x00C6E950 g_pathPrefix:String              install-path prefix (same slot TCard.CreateCard uses)
'   0x00C6EFE0 g_screenheight:Int               bare dword read, no refcount traffic
'   0x00C65718 g_screen_editcompetition:TScreen construction site = TScreen.CreateScreen
'   0x00C65724 g_editcomp_tbldetails:TTable     construction site = TTable.CreateTable.
'                globals_final.tsv says TButton with a flagged TButton/TTable CONFLICT;
'                TTable is right -- the store comes straight out of [0xC62BAC] = TTable.CreateTable
'                and slots 0x90/0x94 are used as TTable.AddColumn / TTable.AddItem.
'   0x00C65728 g_editcomp_btnidl:TButton          0x00C6572C g_editcomp_inpid:TInputBox
'   0x00C65730 g_editcomp_btnidr:TButton          0x00C65734 g_editcomp_inpname:TInputBox
'   0x00C65738 g_editcomp_inptla:TInputBox        0x00C6573C g_editcomp_cmblevel:TCombo
'   0x00C65740 g_editcomp_cmblocale:TCombo        0x00C65744 g_editcomp_cmbbased:TCombo
'   0x00C65748 g_editcomp_cmbcomptype:TCombo      0x00C6574C g_editcomp_cmbstartyear:TCombo
'   0x00C65750 g_editcomp_cmbrecurring:TCombo     0x00C65754 g_editcomp_inpstartweek:TInputBox
'   0x00C65758 g_editcomp_inpduration:TInputBox   0x00C6575C g_editcomp_cmbmatchday1:TCombo
'   0x00C65760 g_editcomp_cmbmatchday2:TCombo     0x00C65764 g_editcomp_inpgroups:TInputBox
'   0x00C65768 g_editcomp_inprounds:TInputBox     0x00C6576C g_editcomp_cmblegs:TCombo
'   0x00C65770 g_editcomp_cmbregion:TCombo        0x00C65774 g_editcomp_cmbstatus:TCombo
'   0x00C65778 g_editcomp_btnnoofteams:TButton    0x00C6577C g_editcomp_tblpromplaces:TTable
'   0x00C65780 g_editcomp_tblpromfromcomps:TTable 0x00C65784 g_editcomp_inpnewpromplace:TInputBox
'   0x00C65788 g_editcomp_inpnewpromcomp:TInputBox 0x00C6578C g_editcomp_btnnewpromplace:TButton
'   0x00C65790 g_editcomp_btndelpromplace:TButton
'
' Class-table slots resolved via globals_classtable_slots.tsv / vtable_map.tsv:
'   0x00C61C64 TScreen+0x38      CreateScreen   0x00C623CC TButton+0x88   CreateButton
'   0x00C62BAC TTable+0x88       CreateTable    0x00C625E0 TInputBox+0x88 CreateInputBox
'   0x00C630E0 TCombo+0x88       CreateCombo    slot 0x40 on TScreen = AddGadget
'   TTable 0x90/0x94 = AddColumn/AddItem;  TCombo 0x90 = AddItem
'   0x00C61648/4C/54/58 = TCompetition.GetStringLocale/Level/CompType/Region
'   0x00C66164 = TDate.GetStringWeekday(i,i)$;  0x00C65EDC = TScreen_Calendar.SetUpScreen
'   0x00C658DC/E0/E4/E8/EC/F0 = this Type's own ButtonQuit / ButtonAddPlace /
'     ButtonDeletePlace / ButtonPrevComp / ButtonNextComp / UpdateComp -> bare names.
'
' 0x004C5549 = GetText (one argument -- Ghidra merges the following pushes into it).
' 0x005AE256 = brl.max2d LoadImage;  0x005B95D0 as a ()i argument is source-level Null;
' 0x005C7D40 is the empty-string constant -> "".  Every literal below was read out of
' NSS5.exe with harness.read_string -- the oracle masks a literal ADDRESS, so the TEXT
' is not certified by the MATCH.
'
' The five Locals are forced by the original: al/h/w occupy [ebp-0xC]/[ebp-8]/[ebp-4]
' and x/y live in edi/ebx.  `y :+ h + 1` emits mov eax,[ebp-8] / add eax,1 / add ebx,eax;
' the folded constant would be two bytes shorter and does not match.
' "ID", "Level", "Based" ... on the combos and the details table are RAW literals,
' not GetText keys -- only the captions marked GetText() go through the locale table.
'!Global g_pathPrefix:String
'!Global g_screenheight:Int
'!Global g_screen_editcompetition:TScreen
'!Global g_editcomp_tbldetails:TTable
'!Global g_editcomp_btnidl:TButton
'!Global g_editcomp_inpid:TInputBox
'!Global g_editcomp_btnidr:TButton
'!Global g_editcomp_inpname:TInputBox
'!Global g_editcomp_inptla:TInputBox
'!Global g_editcomp_cmblevel:TCombo
'!Global g_editcomp_cmblocale:TCombo
'!Global g_editcomp_cmbbased:TCombo
'!Global g_editcomp_cmbcomptype:TCombo
'!Global g_editcomp_cmbstartyear:TCombo
'!Global g_editcomp_cmbrecurring:TCombo
'!Global g_editcomp_inpstartweek:TInputBox
'!Global g_editcomp_inpduration:TInputBox
'!Global g_editcomp_cmbmatchday1:TCombo
'!Global g_editcomp_cmbmatchday2:TCombo
'!Global g_editcomp_inpgroups:TInputBox
'!Global g_editcomp_inprounds:TInputBox
'!Global g_editcomp_cmblegs:TCombo
'!Global g_editcomp_cmbregion:TCombo
'!Global g_editcomp_cmbstatus:TCombo
'!Global g_editcomp_btnnoofteams:TButton
'!Global g_editcomp_tblpromplaces:TTable
'!Global g_editcomp_tblpromfromcomps:TTable
'!Global g_editcomp_inpnewpromplace:TInputBox
'!Global g_editcomp_inpnewpromcomp:TInputBox
'!Global g_editcomp_btnnewpromplace:TButton
'!Global g_editcomp_btndelpromplace:TButton
	Function CreateScreen()
		g_screen_editcompetition = TScreen.CreateScreen("editcompetition", LoadImage(g_pathPrefix + "GameMedia/Images/Backgrounds/Grass.png", -1), Null, Null)
		g_screen_editcompetition.AddGadget(TButton.CreateButton("pan_title", GetText("Edit Competition"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_screen_editcompetition.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
		g_screen_editcompetition.AddGadget(TButton.CreateButton("editcompetition_calendar", GetText("Calendar"), 10, g_screenheight - 30, 100, 20, 1, 2, "FF99FF", "FFFFFF", Null, TScreen_Calendar.SetUpScreen, 1.0, 1, ""))
		g_editcomp_tbldetails = TTable.CreateTable("tbl_details", 10, 50, 20, 24, 0, 2, "0000FF", 1.0, 1, Null)
		g_editcomp_tbldetails.AddColumn(80, "ID", "000000", "AAAAAA", 2)
		g_editcomp_tbldetails.AddItem(["Name"], "", "")
		g_editcomp_tbldetails.AddItem(["Abbrev."], "", "")
		g_editcomp_tbldetails.AddItem(["Level"], "", "")
		g_editcomp_tbldetails.AddItem(["Locale"], "", "")
		g_editcomp_tbldetails.AddItem(["Based"], "", "")
		g_editcomp_tbldetails.AddItem(["Comp Type"], "", "")
		g_editcomp_tbldetails.AddItem(["Start Year"], "", "")
		g_editcomp_tbldetails.AddItem(["Recurring"], "", "")
		g_editcomp_tbldetails.AddItem(["Start Week"], "", "")
		g_editcomp_tbldetails.AddItem(["Duration"], "", "")
		g_editcomp_tbldetails.AddItem(["Matchday 1"], "", "")
		g_editcomp_tbldetails.AddItem(["Matchday 2"], "", "")
		g_editcomp_tbldetails.AddItem(["Groups"], "", "")
		g_editcomp_tbldetails.AddItem(["Rounds"], "", "")
		g_editcomp_tbldetails.AddItem(["Legs"], "", "")
		g_editcomp_tbldetails.AddItem(["Regional"], "", "")
		g_editcomp_tbldetails.AddItem(["Status"], "", "")
		g_editcomp_tbldetails.AddItem(["Teams"], "", "")
		g_screen_editcompetition.AddGadget(g_editcomp_tbldetails)
		Local al:Int = 2
		Local h:Int = g_editcomp_tbldetails.ih
		Local w:Int = 300
		Local x:Int = 95
		Local y:Int = 50
		g_editcomp_btnidl = TButton.CreateButton("btn_idl", "<", x, y, 98, h, 1, al, "99FF99", "FFFFFF", Null, ButtonPrevComp, 1.0, 4, "")
		g_editcomp_inpid = TInputBox.CreateInputBox("inp_ID", x + 100, y, 100, h, 1, al, "FFFFFF", "000000", 10, 1.0, UpdateComp, 0, "")
		g_editcomp_btnidr = TButton.CreateButton("btn_idr", ">", x + 202, y, 98, h, 1, al, "99FF99", "FFFFFF", Null, ButtonNextComp, 1.0, 5, "")
		y :+ h + 1
		g_editcomp_inpname = TInputBox.CreateInputBox("inp_Name", x, y, w, h, 1, al, "FFFFFF", "000000", 32, 1.0, UpdateComp, 0, "")
		y :+ h + 1
		g_editcomp_inptla = TInputBox.CreateInputBox("inp_TLA", x, y, w, h, 1, al, "FFFFFF", "000000", 10, 1.0, UpdateComp, 0, "")
		y :+ h + 1
		g_editcomp_cmblevel = TCombo.CreateCombo("cmb_Level", "Level", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_cmblocale = TCombo.CreateCombo("cmb_Locale", "Locale", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_cmbbased = TCombo.CreateCombo("cmb_Based", "Based", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_cmbcomptype = TCombo.CreateCombo("cmb_CompType", "Comp Type", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_cmbstartyear = TCombo.CreateCombo("cmb_StartYear", "Start Year", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_cmbrecurring = TCombo.CreateCombo("cmb_Recurring", "Recurring", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_inpstartweek = TInputBox.CreateInputBox("inp_StartWeek", x, y, w, h, 1, al, "FFFFFF", "000000", 2, 1.0, UpdateComp, 0, "")
		y :+ h + 1
		g_editcomp_inpduration = TInputBox.CreateInputBox("inp_Duration", x, y, w, h, 1, al, "FFFFFF", "000000", 2, 1.0, UpdateComp, 0, "")
		y :+ h + 1
		g_editcomp_cmbmatchday1 = TCombo.CreateCombo("cmb_Matchday1", "Primary Matchday", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_cmbmatchday2 = TCombo.CreateCombo("cmb_Matchday2", "Secondary Matchday", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_inpgroups = TInputBox.CreateInputBox("inp_Groups", x, y, w, h, 1, al, "FFFFFF", "000000", 2, 1.0, UpdateComp, 0, "")
		y :+ h + 1
		g_editcomp_inprounds = TInputBox.CreateInputBox("inp_Rounds", x, y, w, h, 1, al, "FFFFFF", "000000", 2, 1.0, UpdateComp, 0, "")
		y :+ h + 1
		g_editcomp_cmblegs = TCombo.CreateCombo("cmb_Legs", "Legs", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_cmbregion = TCombo.CreateCombo("cmb_Region", "Region", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_cmbstatus = TCombo.CreateCombo("cmb_Status", "Status", x, y, w, h, 1, al, "FFFF99", "000000", 1.0, UpdateComp, 1)
		y :+ h + 1
		g_editcomp_btnnoofteams = TButton.CreateButton("btn_NoofTeams", "0", x, y, w, h, 0, al, "AAAAAA", "FFFFFF", Null, Null, 1.0, 1, "")
		g_screen_editcompetition.AddGadget(g_editcomp_btnidl)
		g_screen_editcompetition.AddGadget(g_editcomp_inpid)
		g_screen_editcompetition.AddGadget(g_editcomp_btnidr)
		g_screen_editcompetition.AddGadget(g_editcomp_inpname)
		g_screen_editcompetition.AddGadget(g_editcomp_inptla)
		g_screen_editcompetition.AddGadget(g_editcomp_cmblevel)
		g_screen_editcompetition.AddGadget(g_editcomp_cmblocale)
		g_screen_editcompetition.AddGadget(g_editcomp_cmbbased)
		g_screen_editcompetition.AddGadget(g_editcomp_cmbcomptype)
		g_screen_editcompetition.AddGadget(g_editcomp_cmbstartyear)
		g_screen_editcompetition.AddGadget(g_editcomp_cmbrecurring)
		g_screen_editcompetition.AddGadget(g_editcomp_inpstartweek)
		g_screen_editcompetition.AddGadget(g_editcomp_inpduration)
		g_screen_editcompetition.AddGadget(g_editcomp_cmbmatchday1)
		g_screen_editcompetition.AddGadget(g_editcomp_cmbmatchday2)
		g_screen_editcompetition.AddGadget(g_editcomp_inpgroups)
		g_screen_editcompetition.AddGadget(g_editcomp_inprounds)
		g_screen_editcompetition.AddGadget(g_editcomp_cmblegs)
		g_screen_editcompetition.AddGadget(g_editcomp_cmbregion)
		g_screen_editcompetition.AddGadget(g_editcomp_cmbstatus)
		g_screen_editcompetition.AddGadget(g_editcomp_btnnoofteams)
		For Local i:Int = 0 To 1
			g_editcomp_cmblevel.AddItem(TCompetition.GetStringLevel(i), "99FF99", "FFFFFF", 0)
		Next
		For Local i:Int = 0 To 2
			g_editcomp_cmblocale.AddItem(TCompetition.GetStringLocale(i), "99FF99", "FFFFFF", 0)
		Next
		For Local i:Int = 0 To 5
			g_editcomp_cmbcomptype.AddItem(TCompetition.GetStringCompType(i), "99FF99", "FFFFFF", 0)
		Next
		g_editcomp_cmbstartyear.AddItem(GetText("Year") + " 0", "99FF99", "FFFFFF", 0)
		For Local i:Int = 1 To 4
			g_editcomp_cmbstartyear.AddItem(GetText("Year") + " " + i, "99FF99", "FFFFFF", 0)
		Next
		g_editcomp_cmbrecurring.AddItem(GetText("Every Year"), "99FF99", "FFFFFF", 0)
		g_editcomp_cmbrecurring.AddItem("2 " + GetText("Years"), "99FF99", "FFFFFF", 0)
		g_editcomp_cmbrecurring.AddItem("3 " + GetText("Years"), "99FF99", "FFFFFF", 0)
		g_editcomp_cmbrecurring.AddItem("4 " + GetText("Years"), "99FF99", "FFFFFF", 0)
		g_editcomp_cmbmatchday1.AddItem(GetText("Any"), "99FF99", "FFFFFF", 0)
		For Local i:Int = 0 To 6
			g_editcomp_cmbmatchday1.AddItem(TDate.GetStringWeekday(i, 0), "99FF99", "FFFFFF", 0)
		Next
		g_editcomp_cmbmatchday2.AddItem(GetText("Any"), "99FF99", "FFFFFF", 0)
		For Local i:Int = 0 To 6
			g_editcomp_cmbmatchday2.AddItem(TDate.GetStringWeekday(i, 0), "99FF99", "FFFFFF", 0)
		Next
		For Local i:Int = 0 To 2
			g_editcomp_cmblegs.AddItem(i, "99FF99", "FFFFFF", 0)
		Next
		g_editcomp_cmbregion.AddItem(GetText("None"), "99FF99", "FFFFFF", 0)
		For Local i:Int = 1 To 4
			g_editcomp_cmbregion.AddItem(TCompetition.GetStringRegion(i), "99FF99", "FFFFFF", 0)
		Next
		For Local i:Int = 0 To 6
			g_editcomp_cmbstatus.AddItem(i, "99FF99", "FFFFFF", 0)
		Next
		x = 410
		y = 50
		g_screen_editcompetition.AddGadget(TButton.CreateButton("lbl_NewPromPlace", GetText("New Promotion Place"), x, y, 377, h, 0, al, "AAAAAA", "FFFFFF", Null, Null, 1.0, 0, ""))
		y :+ h + 1
		g_editcomp_inpnewpromplace = TInputBox.CreateInputBox("inp_NewPromPlace", x, y, 160, h, 1, al, "FFFFFF", "000000", 32, 1.0, Null, 0, "")
		g_editcomp_inpnewpromcomp = TInputBox.CreateInputBox("inp_NewPromComp", x + 162, y, 215, h, 1, al, "FFFFFF", "000000", 32, 1.0, Null, 0, "")
		y :+ h + 1
		g_editcomp_btnnewpromplace = TButton.CreateButton("btn_NewPromPlace", GetText("Add"), x, y, 377, h, 1, al, "00FF00", "FFFFFF", Null, ButtonAddPlace, 1.0, 0, "")
		y :+ h + 1
		g_editcomp_btndelpromplace = TButton.CreateButton("btn_DelPromPlace", GetText("Delete"), x, y, 377, h, 1, al, "FF0000", "FFFFFF", Null, ButtonDeletePlace, 1.0, 0, "")
		y :+ h + 10
		g_editcomp_tblpromplaces = TTable.CreateTable("tbl_promotionplaces", x, y, 10, 0, 1, 2, "0000FF", 1.0, 1, Null)
		g_editcomp_tblpromplaces.AddColumn(160, GetText("Promotion Places"), "000000", "AAAAAA", 1)
		g_editcomp_tblpromplaces.AddColumn(215, GetText("Promote To"), "000000", "AAAAAA", 0)
		y = 400
		g_editcomp_tblpromfromcomps = TTable.CreateTable("tbl_promotionfromplaces", x, y, 8, 0, 1, 2, "0000FF", 1.0, 1, Null)
		g_editcomp_tblpromfromcomps.AddColumn(215, GetText("Promotion From Comps"), "000000", "AAAAAA", 0)
		g_editcomp_tblpromfromcomps.AddColumn(160, GetText("Place"), "000000", "AAAAAA", 1)
		g_screen_editcompetition.AddGadget(g_editcomp_tblpromplaces)
		g_screen_editcompetition.AddGadget(g_editcomp_inpnewpromplace)
		g_screen_editcompetition.AddGadget(g_editcomp_inpnewpromcomp)
		g_screen_editcompetition.AddGadget(g_editcomp_btnnewpromplace)
		g_screen_editcompetition.AddGadget(g_editcomp_btndelpromplace)
		g_screen_editcompetition.AddGadget(g_editcomp_tblpromfromcomps)
	End Function
