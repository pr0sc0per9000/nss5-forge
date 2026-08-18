' TScreen_EditNations.CreateScreen
' VA 0x005291B2   5898 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' (5898/5898, original length from Ghidra's inventory, reloc_masked=618; re-verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run itself taught.)
'
' ASSUMPTIONS -- module Globals (names ours; addresses are the load-bearing part)
'   0x00C65030 -> g_editnat_screen:TScreen              (assigned from TScreen.CreateScreen)
'   0x00C65038 -> g_table:TTable                        (assigned from TTable.CreateTable)
'   0x00C6503C -> g_cmbNation:TCombo                    (assigned from TCombo.CreateCombo)
'   0x00C65040 -> g_editnat_btnPrev:TButton
'   0x00C65044 -> g_editnat_btnId:TButton
'   0x00C65048 -> g_editnat_btnNext:TButton
'   0x00C6504C -> g_editnat_ibName:TInputBox
'   0x00C65050 -> g_editnat_ibShortName:TInputBox
'   0x00C65054 -> g_editnat_ibTla:TInputBox
'   0x00C65058 -> g_editnat_ibNationality:TInputBox
'   0x00C6505C -> g_editnat_ibStrength:TInputBox
'   0x00C65060 -> g_editnat_cmbContinent:TCombo
'   0x00C65064 -> g_editnat_cmbRival1:TCombo
'   0x00C65068 -> g_editnat_cmbRival2:TCombo
'   0x00C6506C -> g_editnat_cmbRival3:TCombo
'   0x00C65070 -> g_editnat_cmbClimate:TCombo
'   0x00C65074 -> g_editnat_cmbSkin1:TCombo
'   0x00C65078 -> g_editnat_cmbSkin2:TCombo
'   0x00C6507C -> g_editnat_ibStadiumName:TInputBox
'   0x00C65080 -> g_editnat_ibStadiumCapacity:TInputBox
'   0x00C65084 -> g_editnat_ibStadiumLong:TInputBox
'   0x00C65088 -> g_editnat_ibStadiumLat:TInputBox
'   0x00C6508C -> g_editnat_btnMembers:TButton
'   0x00C65090 -> g_editnat_tblMembers:TTable
'   0x00C65094 -> g_editnat_btnGo:TButton
'   0x00C6509C -> g_editnat_btnKit1:TButton   0x00C650A0 -> g_editnat_btnKit2:TButton
'   0x00C650A4 -> g_editnat_btnKit3:TButton   0x00C650A8 -> g_editnat_btnKit4:TButton
'   0x00C6E950 -> g_mediapath:String  (globals_final.tsv row is "String", hand-verified;
'                 concatenated with the .png path before LoadImage)
'   0x00C6EFE0 -> g_screenheight:Int  (bare dword read, no refcount traffic -> Int)
' Names 0x38/0x3C/0x4C..0x78 reuse the identifiers already banked by the other recovered
' TScreen_EditNations bodies (g_table, g_cmbNation, g_editnat_ib*/cmb*).
'
' Class-table slots resolved via class_tables.tsv + vtable_map.tsv:
'   0x00C61C64 = TScreen+0x38   CreateScreen($,:TImage,()i,()i):TScreen
'   0x00C623CC = TButton+0x88   CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'   0x00C62BAC = TTable+0x88    CreateTable($,i,i,i,i,i,i,$,f,i,()i):TTable
'   0x00C630E0 = TCombo+0x88    CreateCombo($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo
'   0x00C625E0 = TInputBox+0x88 CreateInputBox($,i,i,i,i,i,i,$,$,i,f,()i,i,$):TInputBox
'   slot 0x40 on the TScreen Global = TScreen.AddGadget(:TGadget)i
'   TTable slot 0x90 = AddColumn(i,$,$,$,i)  slot 0x94 = AddItem([]$,$,$)
'   TCombo slot 0x90 = AddItem($,$,$,i)
'   Own-Type callbacks (same Type -> bare name): 0x00C65210=+0x38 ButtonQuit,
'   0x00C65214=+0x3C ButtonPrevNat, 0x00C65218=+0x40 ButtonNextNat,
'   0x00C6521C=+0x44 UpdateNat, 0x00C65220=+0x48 ComboNation,
'   0x00C65224=+0x4C GoMember, 0x00C6522C=+0x54 EditKit
'
' Helpers: FUN_004C5549 = GetText (module Function, already recovered).  Ghidra MERGES
' GetText's single argument with the pushes that follow it -- read the `add esp,4`.
' 0x004A7C20 = _bbStringConcat, 0x004A63D0 = _bbArrayNew1D (the one-element String array
' of each AddItem row), 0x005AE256 = brl.max2d LoadImage, 0x005B9690 = _bbFloatToInt
' (emitted for Int(...)), 0x005B95D0 = the empty function, i.e. source-level Null for an
' ()i argument.
'
' Field offsets used: TGadget.x @ +0x20 (Float), TTable.ih @ +0x68 (Int).
'
' Literals were read out of NSS5.exe with harness.read_string -- the oracle masks a
' literal's ADDRESS, so their CONTENT is not certified by the MATCH.  Float constants read
' as raw dwords: 0x00C82D30 = 0x00C83060 = 165.0, 0x00C83064 = 10.0.
'   0x00C824E4 'Clubs'   0x00C8249C 'Nations'   0x00C828C8 'Menu'
'   0x00C82848 'GameMedia/Images/Backgrounds/Grass.png'   0x00C82BA8 'nations'
' Note "cmb_Level" (0x00C82DA0) is deliberately reused as the gadget NAME for the
' continent, climate and both skin combos -- that is what the original pushes.
'
' The five Locals are forced by the original: bcc does no constant hoisting, and the
' emitted `push dword [ebp-8]` / `push dword [ebp-0xc]` for the 2 and the 300 prove they
' were variables.  Declaration order is fixed by the store order at 0x005297C6:
' style(ebp-8), h(edi), w(ebp-0xc), x(ebp-4), y(ebx).  `y :+ h + 1` (mov eax,edi /
' add eax,1 / add ebx,eax) follows every gadget from btn_idr onward except the last
' input box.  x and y are then REASSIGNED for the right-hand column, not redeclared.
'!Global g_editnat_screen:TScreen
'!Global g_table:TTable
'!Global g_cmbNation:TCombo
'!Global g_editnat_btnPrev:TButton
'!Global g_editnat_btnId:TButton
'!Global g_editnat_btnNext:TButton
'!Global g_editnat_ibName:TInputBox
'!Global g_editnat_ibShortName:TInputBox
'!Global g_editnat_ibTla:TInputBox
'!Global g_editnat_ibNationality:TInputBox
'!Global g_editnat_ibStrength:TInputBox
'!Global g_editnat_cmbContinent:TCombo
'!Global g_editnat_cmbRival1:TCombo
'!Global g_editnat_cmbRival2:TCombo
'!Global g_editnat_cmbRival3:TCombo
'!Global g_editnat_cmbClimate:TCombo
'!Global g_editnat_cmbSkin1:TCombo
'!Global g_editnat_cmbSkin2:TCombo
'!Global g_editnat_ibStadiumName:TInputBox
'!Global g_editnat_ibStadiumCapacity:TInputBox
'!Global g_editnat_ibStadiumLong:TInputBox
'!Global g_editnat_ibStadiumLat:TInputBox
'!Global g_editnat_btnMembers:TButton
'!Global g_editnat_tblMembers:TTable
'!Global g_editnat_btnGo:TButton
'!Global g_editnat_btnKit1:TButton
'!Global g_editnat_btnKit2:TButton
'!Global g_editnat_btnKit3:TButton
'!Global g_editnat_btnKit4:TButton
'!Global g_mediapath:String
'!Global g_screenheight:Int
	Function CreateScreen()
		g_editnat_screen = TScreen.CreateScreen("nations", LoadImage(g_mediapath + "GameMedia/Images/Backgrounds/Grass.png"), Null, Null)
		g_editnat_screen.AddGadget(TButton.CreateButton("pan_title", GetText("Nations"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_editnat_screen.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
		g_table = TTable.CreateTable("tbl_details", 10, 50, 20, 24, 0, 2, "0000FF", 1.0, 1, Null)
		g_table.AddColumn(160, "ID", "000000", "AAAAAA", 2)
		g_table.AddItem([GetText("Nation")], "", "")
		g_table.AddItem([GetText("Name")], "", "")
		g_table.AddItem([GetText("Short Name")], "", "")
		g_table.AddItem([GetText("Abbreviation")], "", "")
		g_table.AddItem([GetText("Nationality")], "", "")
		g_table.AddItem([GetText("Strength")], "", "")
		g_table.AddItem([GetText("Continent")], "", "")
		g_table.AddItem([GetText("Rival") + " 1"], "", "")
		g_table.AddItem([GetText("Rival") + " 2"], "", "")
		g_table.AddItem([GetText("Rival") + " 3"], "", "")
		g_table.AddItem([GetText("Climate")], "", "")
		g_table.AddItem([GetText("Primary Skin")], "", "")
		g_table.AddItem([GetText("Secondary Skin")], "", "")
		g_table.AddItem([GetText("Stadium Name")], "", "")
		g_table.AddItem([GetText("Stadium Capacity")], "", "")
		g_table.AddItem([GetText("Stadium Longitude")], "", "")
		g_table.AddItem([GetText("Stadium Latitude")], "", "")
		g_editnat_screen.AddGadget(g_table)
		Local style:Int = 2
		Local h:Int = g_table.ih
		Local w:Int = 300
		Local x:Int = Int(g_table.x + 165.0)
		Local y:Int = 50
		g_editnat_btnPrev = TButton.CreateButton("btn_idl", "<", x, y, 98, h, 1, style, "99FF99", "FFFFFF", Null, ButtonPrevNat, 1.0, 4, "")
		g_editnat_btnId = TButton.CreateButton("btn_id", "", x + 100, y, 100, h, 0, style, "AAAAAA", "FFFFFF", Null, Null, 1.0, 0, "")
		g_editnat_btnNext = TButton.CreateButton("btn_idr", ">", x + 202, y, 98, h, 1, style, "99FF99", "FFFFFF", Null, ButtonNextNat, 1.0, 5, "")
		y :+ h + 1
		g_cmbNation = TCombo.CreateCombo("cmb_Nation", "", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, ComboNation, 1)
		y :+ h + 1
		g_editnat_screen.AddGadget(g_cmbNation)
		g_editnat_screen.AddGadget(g_editnat_btnPrev)
		g_editnat_screen.AddGadget(g_editnat_btnId)
		g_editnat_screen.AddGadget(g_editnat_btnNext)
		g_editnat_ibName = TInputBox.CreateInputBox("inp_Name", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		y :+ h + 1
		g_editnat_ibShortName = TInputBox.CreateInputBox("inp_ShortName", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		y :+ h + 1
		g_editnat_ibTla = TInputBox.CreateInputBox("inp_TLA", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		y :+ h + 1
		g_editnat_ibNationality = TInputBox.CreateInputBox("inp_Nationality", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		y :+ h + 1
		g_editnat_ibStrength = TInputBox.CreateInputBox("inp_Strength", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		y :+ h + 1
		g_editnat_cmbContinent = TCombo.CreateCombo("cmb_Level", "Continent", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateNat, 1)
		y :+ h + 1
		g_editnat_cmbRival1 = TCombo.CreateCombo("cmb_Rival1", "Rival 1", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateNat, 1)
		y :+ h + 1
		g_editnat_cmbRival2 = TCombo.CreateCombo("cmb_Rival2", "Rival 2", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateNat, 1)
		y :+ h + 1
		g_editnat_cmbRival3 = TCombo.CreateCombo("cmb_Rival3", "Rival 3", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateNat, 1)
		y :+ h + 1
		g_editnat_cmbClimate = TCombo.CreateCombo("cmb_Level", "Climate", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateNat, 1)
		y :+ h + 1
		g_editnat_cmbClimate.AddItem(GetText("climate_Variable"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbClimate.AddItem(GetText("climate_Cold"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbClimate.AddItem(GetText("climate_Warm"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbClimate.AddItem(GetText("climate_Hot"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin1 = TCombo.CreateCombo("cmb_Level", "Primary Skin", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateNat, 1)
		y :+ h + 1
		g_editnat_cmbSkin1.AddItem(GetText("skin_White"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin1.AddItem(GetText("skin_Light"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin1.AddItem(GetText("skin_Dark"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin1.AddItem(GetText("skin_Black"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin1.AddItem(GetText("skin_Asian"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin2 = TCombo.CreateCombo("cmb_Level", "Secondary Skin", x, y, w, h, 1, style, "FFFF99", "000000", 1.0, UpdateNat, 1)
		y :+ h + 1
		g_editnat_cmbSkin2.AddItem(GetText("skin_White"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin2.AddItem(GetText("skin_Light"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin2.AddItem(GetText("skin_Dark"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin2.AddItem(GetText("skin_Black"), "BBBBBB", "FFFFFF", 0)
		g_editnat_cmbSkin2.AddItem(GetText("skin_Asian"), "BBBBBB", "FFFFFF", 0)
		g_editnat_ibStadiumName = TInputBox.CreateInputBox("inp_StadiumName", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		y :+ h + 1
		g_editnat_ibStadiumCapacity = TInputBox.CreateInputBox("inp_StadiumCapacity", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		y :+ h + 1
		g_editnat_ibStadiumLong = TInputBox.CreateInputBox("inp_StadiumLong", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		y :+ h + 1
		g_editnat_ibStadiumLat = TInputBox.CreateInputBox("inp_StadiumLat", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateNat, 0, "")
		g_editnat_screen.AddGadget(g_editnat_ibName)
		g_editnat_screen.AddGadget(g_editnat_ibShortName)
		g_editnat_screen.AddGadget(g_editnat_ibTla)
		g_editnat_screen.AddGadget(g_editnat_ibNationality)
		g_editnat_screen.AddGadget(g_editnat_ibStrength)
		g_editnat_screen.AddGadget(g_editnat_cmbRival1)
		g_editnat_screen.AddGadget(g_editnat_cmbRival2)
		g_editnat_screen.AddGadget(g_editnat_cmbRival3)
		g_editnat_screen.AddGadget(g_editnat_cmbContinent)
		g_editnat_screen.AddGadget(g_editnat_cmbClimate)
		g_editnat_screen.AddGadget(g_editnat_cmbSkin1)
		g_editnat_screen.AddGadget(g_editnat_cmbSkin2)
		g_editnat_screen.AddGadget(g_editnat_ibStadiumName)
		g_editnat_screen.AddGadget(g_editnat_ibStadiumCapacity)
		g_editnat_screen.AddGadget(g_editnat_ibStadiumLong)
		g_editnat_screen.AddGadget(g_editnat_ibStadiumLat)
		x = Int(g_table.x + 165.0 + w + 10.0)
		y = 155
		g_editnat_btnMembers = TButton.CreateButton("btn_members", GetText("Clubs"), x, y, w, h, 0, style, "AAAAAA", "FFFFFF", Null, Null, 1.0, 0, "")
		y :+ h + 1
		g_editnat_screen.AddGadget(g_editnat_btnMembers)
		g_editnat_tblMembers = TTable.CreateTable("tbl_members", x, y, 18, 0, 1, 2, "0000FF", 1.0, 1, Null)
		g_editnat_tblMembers.AddColumn(58, GetText("ID"), "000000", "AAAAAA", 1)
		g_editnat_tblMembers.AddColumn(180, GetText("Name"), "000000", "AAAAAA", 0)
		g_editnat_tblMembers.AddColumn(58, GetText("Strength"), "000000", "AAAAAA", 1)
		g_editnat_screen.AddGadget(g_editnat_tblMembers)
		g_editnat_btnGo = TButton.CreateButton("btn_gomember", GetText("Go"), x, g_screenheight - 35, w, h, 1, style, "00FF00", "FFFFFF", Null, GoMember, 1.0, 1, "")
		g_editnat_screen.AddGadget(g_editnat_btnGo)
		g_editnat_screen.AddGadget(TButton.CreateButton("btn_EditKit1", GetText("kit_Home"), 490, 50, 64, 20, 1, 2, "FFFFFF", "FFFFFF", Null, EditKit, 1.0, 1, ""))
		g_editnat_btnKit1 = TButton.CreateButton("btn_Kit1", "", 490, 70, 64, 84, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
		g_editnat_screen.AddGadget(TButton.CreateButton("btn_EditKit2", GetText("kit_Away"), 570, 50, 64, 20, 1, 2, "FFFFFF", "FFFFFF", Null, EditKit, 1.0, 1, ""))
		g_editnat_btnKit2 = TButton.CreateButton("btn_Kit2", "", 570, 70, 64, 84, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
		g_editnat_screen.AddGadget(TButton.CreateButton("btn_EditKit3", GetText("kit_Third"), 650, 50, 64, 20, 1, 2, "FFFFFF", "FFFFFF", Null, EditKit, 1.0, 1, ""))
		g_editnat_btnKit3 = TButton.CreateButton("btn_Kit3", "", 650, 70, 64, 84, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
		g_editnat_screen.AddGadget(TButton.CreateButton("btn_EditKit4", GetText("kit_Keeper"), 730, 50, 64, 20, 1, 2, "FFFFFF", "FFFFFF", Null, EditKit, 1.0, 1, ""))
		g_editnat_btnKit4 = TButton.CreateButton("btn_Kit4", "", 730, 70, 64, 84, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
		g_editnat_screen.AddGadget(g_editnat_btnKit1)
		g_editnat_screen.AddGadget(g_editnat_btnKit2)
		g_editnat_screen.AddGadget(g_editnat_btnKit3)
		g_editnat_screen.AddGadget(g_editnat_btnKit4)
	End Function
