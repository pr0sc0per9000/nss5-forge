' TScreen_Promotions.CreateScreen
' VA 0x00532A4C   1181 bytes   KIND=Function (static, no Self)   SIG ()i   class-table slot 0x30
' byte-identical vs NSS5.exe (1181/1181, original length from Ghidra's inventory, mode=reloc)
'
' Builds the promotion/relegation screen: background, title panel, quit button, a nation
' filter combo, two competition combos (with their own results tables) and the
' Promote/Relegate buttons.
'
' This closes out the near-miss in src/recovered_unverified/TScreen_Promotions.CreateScreen.bmx
' (delta +15). The root cause identified there is correct: two Int values are held
' in registers and REUSED across many gadget calls rather than re-pushed as fresh literals --
' `Local xpos:Int = 10` (register ebx) and `Local colw:Int = 160` (register edi). The part
' that file leaves open -- the exact STATEMENT placement of each `xpos :+ ...` update -- is
' settled by walking the full raw disassembly instruction-by-instruction
' (harness.disasm_original, after=400 to see past its 200-instruction default): every
' `xpos :+` update happens immediately after the gadget that produced the new offset is
' ASSIGNED to its Global, and BEFORE that gadget is AddGadget'd or its AddColumn is called,
' not after. Getting this statement order right (not just the arithmetic) is what
' closes the remaining 15 bytes to an exact match.
'   xpos = 10                                  (before cmb_Nation)
'   xpos :+ 140                                (right after cmb_Nation's assignment, before its AddGadget)
'   xpos :+ colw + 10                          (right after tbl_comp1's assignment, before its AddColumn)
'   xpos :+ colw + 10                          (right after btn_Relegate's assignment, before its AddGadget)
' colw=160 is never reassigned; it is reused as-is for cmb_Comp1.w, tbl_comp1.AddColumn width,
' btn_Promote.w, btn_Relegate.w, cmb_Comp2.w and tbl_comp2.AddColumn width (six sites).
'
' Globals ('!Global pragmas, all construction-site typed from the CreateXxx call they receive):
'   g_pathPrefix:String (0x00C6E950, established name from LoadImageChecked.bmx etc.)
'   g_screen_promotions:TScreen  g_promo_combo_nation:TCombo
'   g_promo_combo1:TCombo  g_promo_combo2:TCombo  g_promo_table1:TTable  g_promo_table2:TTable
'   g_promo_btn_promote:TButton  g_promo_btn_relegate:TButton
'
' Literals read from the exe with harness.read_string(), all confirmed exact:
'   "GameMedia/Images/Backgrounds/Grass.png", "promotions", "Promotions", "pan_title",
'   "Menu", "quit", "Nation", "cmb_Nation", "Competition", " 1", " 2", "cmb_Comp1",
'   "cmb_Comp2", "tbl_comp1", "tbl_comp2", "Teams", ">>", "<<", "btn_Promote", "btn_Relegate",
'   "EEEEEE", "FFFFFF", "FF0000", "000000", "FFFF00", "00FF00", "0000FF".
'
' Class-table slots used (confirmed against raw disassembly, not Ghidra's merged arg lists):
'   TScreen+0x38 CreateScreen; TScreen+0x40 AddGadget; TButton+0x88 CreateButton;
'   TCombo+0x?? CreateCombo; TTable+0x?? CreateTable; TTable+0x90 AddColumn.

	Function CreateScreen:Int()
		'!Global g_pathPrefix:String
		'!Global g_screen_promotions:TScreen
		'!Global g_promo_combo_nation:TCombo
		'!Global g_promo_combo1:TCombo
		'!Global g_promo_combo2:TCombo
		'!Global g_promo_table1:TTable
		'!Global g_promo_table2:TTable
		'!Global g_promo_btn_promote:TButton
		'!Global g_promo_btn_relegate:TButton

		g_screen_promotions = TScreen.CreateScreen("promotions", LoadImage(g_pathPrefix + "GameMedia/Images/Backgrounds/Grass.png", -1), Null, Null)
		g_screen_promotions.AddGadget(TButton.CreateButton("pan_title", GetText("Promotions"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_screen_promotions.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))

		Local xpos:Int = 10
		Local colw:Int = 160
		g_promo_combo_nation = TCombo.CreateCombo("cmb_Nation", GetText("Nation"), xpos, 50, 130, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboNation, 1)
		xpos :+ 140
		g_screen_promotions.AddGadget(g_promo_combo_nation)

		g_promo_combo1 = TCombo.CreateCombo("cmb_Comp1", GetText("Competition") + " 1", xpos, 50, colw, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, SetUpScreen, 1)
		g_screen_promotions.AddGadget(g_promo_combo1)

		g_promo_table1 = TTable.CreateTable("tbl_comp1", xpos, 80, 25, 0, 1, 2, "0000FF", 1.0, 1, Null)
		xpos :+ colw + 10
		g_promo_table1.AddColumn(colw, GetText("Teams"), "000000", "FFFFFF", 0)
		g_screen_promotions.AddGadget(g_promo_table1)

		g_promo_btn_promote = TButton.CreateButton("btn_Promote", ">>", xpos, 80, colw, 30, 1, 2, "00FF00", "FFFFFF", Null, ButtonPromote, 1.0, 1, "")
		g_screen_promotions.AddGadget(g_promo_btn_promote)

		g_promo_btn_relegate = TButton.CreateButton("btn_Relegate", "<<", xpos, 120, colw, 30, 1, 2, "FF0000", "FFFFFF", Null, ButtonRelegate, 1.0, 1, "")
		xpos :+ colw + 10
		g_screen_promotions.AddGadget(g_promo_btn_relegate)

		g_promo_combo2 = TCombo.CreateCombo("cmb_Comp2", GetText("Competition") + " 2", xpos, 50, colw, 20, 1, 2, "FFFF00", "FFFFFF", 1.0, SetUpScreen, 1)
		g_screen_promotions.AddGadget(g_promo_combo2)

		g_promo_table2 = TTable.CreateTable("tbl_comp2", xpos, 80, 25, 0, 1, 2, "0000FF", 1.0, 1, Null)
		g_promo_table2.AddColumn(colw, GetText("Teams"), "000000", "FFFFFF", 0)
		g_screen_promotions.AddGadget(g_promo_table2)
	End Function
