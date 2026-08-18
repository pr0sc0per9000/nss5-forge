' TScreen_EditClubs.CreateScreen
' VA 0x0052CF39   4556 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' (4556/4556, original length from Ghidra's inventory, reloc_masked=473; re-verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run itself taught.)
'
' ASSUMPTIONS -- module Globals (names ours; the ADDRESS is the load-bearing part).
' All types are globals_final.tsv type_source=construction, i.e. read off the factory's
' declared return type at the store site, and each is corroborated by the slots used
' through it (0x40 = TScreen.AddGadget, 0x90/0x94 = TTable.AddColumn/AddItem).
'   0x00C653BC -> g_editclubs_screen:TScreen            (from TScreen.CreateScreen)
'   0x00C653C8 -> g_editclubs_table:TTable              (from TTable.CreateTable)
'   0x00C653CC -> g_editclubs_btnPrev:TButton
'   0x00C653D0 -> g_editclubs_btnId:TButton
'   0x00C653D4 -> g_editclubs_btnNext:TButton
'   0x00C653D8 -> g_editclubs_ibName:TInputBox
'   0x00C653DC -> g_editclubs_ibShortName:TInputBox
'   0x00C653E0 -> g_editclubs_ibTla:TInputBox
'   0x00C653E4 -> g_editclubs_ibNickName:TInputBox
'   0x00C653E8 -> g_editclubs_ibStrength:TInputBox
'   0x00C653EC -> g_editclubs_cmbNation:TCombo
'   0x00C653F0 -> g_editclubs_cmbRival1:TCombo
'   0x00C653F4 -> g_editclubs_cmbRival2:TCombo
'   0x00C653F8 -> g_editclubs_cmbRival3:TCombo
'   0x00C653FC -> g_editclubs_cmbLeague:TCombo
'   0x00C65400 -> g_editclubs_cmbContinentalComp:TCombo
'   0x00C65404 -> g_editclubs_cmbBTeamOf:TCombo
'   0x00C65408 -> g_editclubs_ibStadiumName:TInputBox
'   0x00C6540C -> g_editclubs_ibStadiumCapacity:TInputBox
'   0x00C65410 -> g_editclubs_ibStadiumLong:TInputBox
'   0x00C65414 -> g_editclubs_ibStadiumLat:TInputBox
'   0x00C6541C/20/24/28 -> g_editclubs_btn1..4:TButton  (identifiers already banked by
'                          TScreen_EditClubs.RefreshKits -- the kit preview buttons)
'   0x00C6E950 -> g_mediapath:String  (globals_final row "String", hand-verified; it is
'                 concatenated with the .png path before LoadImage)
'
' Class-table slots resolved via class_tables.tsv + vtable_map.tsv:
'   0x00C61C64 = TScreen+0x38   CreateScreen($,:TImage,()i,()i):TScreen
'   0x00C623CC = TButton+0x88   CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'   0x00C62BAC = TTable+0x88    CreateTable($,i,i,i,i,i,i,$,f,i,()i):TTable
'   0x00C630E0 = TCombo+0x88    CreateCombo($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo
'   0x00C625E0 = TInputBox+0x88 CreateInputBox($,i,i,i,i,i,i,$,$,i,f,()i,i,$):TInputBox
'   slot 0x40 on the TScreen Global = TScreen.AddGadget(:TGadget)i
'   TTable slot 0x90 = AddColumn(i,$,$,$,i)   slot 0x94 = AddItem([]$,$,$)
'   Own-Type callbacks (same Type -> bare name, no Type. prefix):
'     0x00C6555C = +0x38 ButtonQuit    0x00C65560 = +0x3C ButtonPrevClub
'     0x00C65564 = +0x40 ButtonNextClub 0x00C65568 = +0x44 UpdateClub
'     0x00C65570 = +0x4C EditKit
'
' Helpers: 0x004C5549 = GetText (recovered module Function; Ghidra MERGES its single
' argument with the pushes that follow -- read the `add esp,4`).  0x004A7C20 =
' _bbStringConcat, 0x004A63D0 = _bbArrayNew1D (the one-element String array each AddItem
' row is built from), 0x005AE256 = brl.max2d LoadImage, 0x005B9690 = _bbFloatToInt
' (emitted for Int(...)), 0x005B95D0 = the empty function, i.e. source-level Null for an
' ()i argument, 0x005C9C80 = bbNullObject = Null for an object argument.
'
' Field offsets used: TGadget.x @ +0x20 (Float), TTable.ih @ +0x68 (Int).
'
' The five Locals are forced by the original, not a stylistic choice: at 0x0052D50C..
' 0x0052D541 bcc stores 2 -> [ebp-8], table.ih -> edi, 300 -> [ebp-0xC],
' Int(table.x+165.0) -> [ebp-4], 50 -> ebx, and every later gadget pushes those slots
' (`push dword [ebp-8]` for the style, `push dword [ebp-0xC]` for the width).  Declaration
' order is fixed by that store order: style, h, w, x, y.  `y :+ h + 1`
' (mov eax,edi / add eax,1 / add ebx,eax) follows every gadget from btn_idr onward except
' the last input box (inp_StadiumLat), whose increment would be dead.
'
' Literals were read out of NSS5.exe with harness.read_string -- the oracle masks a
' literal's ADDRESS, so their CONTENT is not certified by the MATCH, only by that read.
' The float added to table.x is 0x00C83704 = 165.0 (raw dword 0x43250000).
'   0x00C83698 'editclubs'   0x00C836B8 'Edit Club'   0x00C828C8 'Menu'
'   0x00C82848 'GameMedia/Images/Backgrounds/Grass.png'
' Note the 16 table rows use GetText(...) but the single column header "ID" (0x00C82900)
' is pushed RAW -- no GetText call -- which is also what TScreen_EditNations does.
' The three Rival rows are GetText("Rival") + " 1"/" 2"/" 3" (a real _bbStringConcat),
' while the combos take the already-joined literals "Rival 1"/"Rival 2"/"Rival 3".
'!Global g_editclubs_screen:TScreen
'!Global g_editclubs_table:TTable
'!Global g_editclubs_btnPrev:TButton
'!Global g_editclubs_btnId:TButton
'!Global g_editclubs_btnNext:TButton
'!Global g_editclubs_ibName:TInputBox
'!Global g_editclubs_ibShortName:TInputBox
'!Global g_editclubs_ibTla:TInputBox
'!Global g_editclubs_ibNickName:TInputBox
'!Global g_editclubs_ibStrength:TInputBox
'!Global g_editclubs_cmbNation:TCombo
'!Global g_editclubs_cmbRival1:TCombo
'!Global g_editclubs_cmbRival2:TCombo
'!Global g_editclubs_cmbRival3:TCombo
'!Global g_editclubs_cmbLeague:TCombo
'!Global g_editclubs_cmbContinentalComp:TCombo
'!Global g_editclubs_cmbBTeamOf:TCombo
'!Global g_editclubs_ibStadiumName:TInputBox
'!Global g_editclubs_ibStadiumCapacity:TInputBox
'!Global g_editclubs_ibStadiumLong:TInputBox
'!Global g_editclubs_ibStadiumLat:TInputBox
'!Global g_editclubs_btn1:TButton
'!Global g_editclubs_btn2:TButton
'!Global g_editclubs_btn3:TButton
'!Global g_editclubs_btn4:TButton
'!Global g_mediapath:String
	g_editclubs_screen = TScreen.CreateScreen("editclubs", LoadImage(g_mediapath + "GameMedia/Images/Backgrounds/Grass.png"), Null, Null)
	g_editclubs_screen.AddGadget(TButton.CreateButton("pan_title", GetText("Edit Club"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
	g_editclubs_screen.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
	g_editclubs_table = TTable.CreateTable("tbl_details", 10, 50, 20, 24, 0, 2, "0000FF", 1.0, 1, Null)
	g_editclubs_table.AddColumn(160, "ID", "000000", "AAAAAA", 2)
	g_editclubs_table.AddItem([GetText("Name")], "", "")
	g_editclubs_table.AddItem([GetText("Short Name")], "", "")
	g_editclubs_table.AddItem([GetText("Abbreviation")], "", "")
	g_editclubs_table.AddItem([GetText("Nick Name")], "", "")
	g_editclubs_table.AddItem([GetText("Strength")], "", "")
	g_editclubs_table.AddItem([GetText("Nation")], "", "")
	g_editclubs_table.AddItem([GetText("Rival") + " 1"], "", "")
	g_editclubs_table.AddItem([GetText("Rival") + " 2"], "", "")
	g_editclubs_table.AddItem([GetText("Rival") + " 3"], "", "")
	g_editclubs_table.AddItem([GetText("League")], "", "")
	g_editclubs_table.AddItem([GetText("Continental Comp")], "", "")
	g_editclubs_table.AddItem([GetText("B Team Of")], "", "")
	g_editclubs_table.AddItem([GetText("Stadium Name")], "", "")
	g_editclubs_table.AddItem([GetText("Stadium Capacity")], "", "")
	g_editclubs_table.AddItem([GetText("Stadium Longitude")], "", "")
	g_editclubs_table.AddItem([GetText("Stadium Latitude")], "", "")
	g_editclubs_screen.AddGadget(g_editclubs_table)
	Local style:Int = 2
	Local h:Int = g_editclubs_table.ih
	Local w:Int = 300
	Local x:Int = Int(g_editclubs_table.x + 165.0)
	Local y:Int = 50
	g_editclubs_btnPrev = TButton.CreateButton("btn_idl", "<", x, y, 98, h, 1, style, "99FF99", "FFFFFF", Null, ButtonPrevClub, 1.0, 4, "")
	g_editclubs_btnId = TButton.CreateButton("btn_id", "", x + 100, y, 100, h, 0, style, "AAAAAA", "FFFFFF", Null, Null, 1.0, 0, "")
	g_editclubs_btnNext = TButton.CreateButton("btn_idr", ">", x + 202, y, 98, h, 1, style, "99FF99", "FFFFFF", Null, ButtonNextClub, 1.0, 5, "")
	y :+ h + 1
	g_editclubs_screen.AddGadget(g_editclubs_btnPrev)
	g_editclubs_screen.AddGadget(g_editclubs_btnId)
	g_editclubs_screen.AddGadget(g_editclubs_btnNext)
	g_editclubs_ibName = TInputBox.CreateInputBox("inp_Name", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	y :+ h + 1
	g_editclubs_ibShortName = TInputBox.CreateInputBox("inp_ShortName", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	y :+ h + 1
	g_editclubs_ibTla = TInputBox.CreateInputBox("inp_TLA", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	y :+ h + 1
	g_editclubs_ibNickName = TInputBox.CreateInputBox("inp_NickName", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	y :+ h + 1
	g_editclubs_ibStrength = TInputBox.CreateInputBox("inp_Strength", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	y :+ h + 1
	g_editclubs_cmbNation = TCombo.CreateCombo("cmb_Nation", "Nation", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateClub, 1)
	y :+ h + 1
	g_editclubs_cmbRival1 = TCombo.CreateCombo("cmb_Rival1", "Rival 1", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateClub, 1)
	y :+ h + 1
	g_editclubs_cmbRival2 = TCombo.CreateCombo("cmb_Rival2", "Rival 2", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateClub, 1)
	y :+ h + 1
	g_editclubs_cmbRival3 = TCombo.CreateCombo("cmb_Rival3", "Rival 3", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateClub, 1)
	y :+ h + 1
	g_editclubs_cmbLeague = TCombo.CreateCombo("cmb_League", "League", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateClub, 1)
	y :+ h + 1
	g_editclubs_cmbContinentalComp = TCombo.CreateCombo("cmb_ContinentalComp", "Continental Comp", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateClub, 1)
	y :+ h + 1
	g_editclubs_cmbBTeamOf = TCombo.CreateCombo("cmb_BTeamOf", "B Team Of", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateClub, 1)
	y :+ h + 1
	g_editclubs_ibStadiumName = TInputBox.CreateInputBox("inp_StadiumName", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	y :+ h + 1
	g_editclubs_ibStadiumCapacity = TInputBox.CreateInputBox("inp_StadiumCapacity", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	y :+ h + 1
	g_editclubs_ibStadiumLong = TInputBox.CreateInputBox("inp_StadiumLong", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	y :+ h + 1
	g_editclubs_ibStadiumLat = TInputBox.CreateInputBox("inp_StadiumLat", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateClub, 0, "")
	g_editclubs_screen.AddGadget(g_editclubs_ibName)
	g_editclubs_screen.AddGadget(g_editclubs_ibShortName)
	g_editclubs_screen.AddGadget(g_editclubs_ibTla)
	g_editclubs_screen.AddGadget(g_editclubs_ibNickName)
	g_editclubs_screen.AddGadget(g_editclubs_ibStrength)
	g_editclubs_screen.AddGadget(g_editclubs_cmbNation)
	g_editclubs_screen.AddGadget(g_editclubs_cmbRival1)
	g_editclubs_screen.AddGadget(g_editclubs_cmbRival2)
	g_editclubs_screen.AddGadget(g_editclubs_cmbRival3)
	g_editclubs_screen.AddGadget(g_editclubs_cmbLeague)
	g_editclubs_screen.AddGadget(g_editclubs_cmbContinentalComp)
	g_editclubs_screen.AddGadget(g_editclubs_cmbBTeamOf)
	g_editclubs_screen.AddGadget(g_editclubs_ibStadiumName)
	g_editclubs_screen.AddGadget(g_editclubs_ibStadiumCapacity)
	g_editclubs_screen.AddGadget(g_editclubs_ibStadiumLong)
	g_editclubs_screen.AddGadget(g_editclubs_ibStadiumLat)
	g_editclubs_screen.AddGadget(TButton.CreateButton("btn_EditKit1", GetText("kit_Home"), 490, 50, 64, 20, 1, 2, "FFFFFF", "FFFFFF", Null, EditKit, 1.0, 1, ""))
	g_editclubs_btn1 = TButton.CreateButton("btn_Kit1", "", 490, 70, 64, 84, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
	g_editclubs_screen.AddGadget(TButton.CreateButton("btn_EditKit2", GetText("kit_Away"), 570, 50, 64, 20, 1, 2, "FFFFFF", "FFFFFF", Null, EditKit, 1.0, 1, ""))
	g_editclubs_btn2 = TButton.CreateButton("btn_Kit2", "", 570, 70, 64, 84, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
	g_editclubs_screen.AddGadget(TButton.CreateButton("btn_EditKit3", GetText("kit_Third"), 650, 50, 64, 20, 1, 2, "FFFFFF", "FFFFFF", Null, EditKit, 1.0, 1, ""))
	g_editclubs_btn3 = TButton.CreateButton("btn_Kit3", "", 650, 70, 64, 84, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
	g_editclubs_screen.AddGadget(TButton.CreateButton("btn_EditKit4", GetText("kit_Keeper"), 730, 50, 64, 20, 1, 2, "FFFFFF", "FFFFFF", Null, EditKit, 1.0, 1, ""))
	g_editclubs_btn4 = TButton.CreateButton("btn_Kit4", "", 730, 70, 64, 84, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
	g_editclubs_screen.AddGadget(g_editclubs_btn1)
	g_editclubs_screen.AddGadget(g_editclubs_btn2)
	g_editclubs_screen.AddGadget(g_editclubs_btn3)
	g_editclubs_screen.AddGadget(g_editclubs_btn4)
