' TScreen_ContinentalComps.CreateScreen
' VA 0x0053357a   1736 bytes   class-table slot 0x30   sig ()i   KIND=Function (static)
' Gadget-construction family (see TScreen_Competitions.CreateScreen, the closest already-
' banked twin, which supplied the CreateButton/CreateTable/CreateCombo argument orders and
' the "assign-to-Global-then-AddGadget" vs "inline-into-AddGadget" convention below).
'
' ASSUMPTIONS -- module Globals (declared TYPE is load-bearing: it selects the vtable slot
' for every call made through it):
'   0x00C6E950 g_promotionplace_int05:String   install-path prefix (globals_final.tsv,
'     hand-verified high confidence; same Global TAchievement.LoadData already uses)
'   0x00C65A1C g_screen_continentalcomps:TScreen     construction site = TScreen.CreateScreen
'   0x00C65A28 g_cc_combocontinent:TCombo    (matches TScreen_ContinentalComps.ComboContinent
'     and .SetUpScreen, already banked, same address)
'   0x00C65A2C g_cc_combocomp:TCombo         (matches .ComboContinent's own naming for this
'     address; .ComboComp.bmx separately calls it g_ccCombo -- pre-existing inconsistency,
'     not introduced here)
'   0x00C65A30 g_cc_btn_editcomp:TButton     (not read elsewhere -- construct-and-forget)
'   0x00C65A34 g_cc_btn_editplace:TButton    (not read elsewhere)
'   0x00C65A38 g_cc_btn_editclub:TButton     (not read elsewhere)
'   0x00C65A3C g_cc_btn_gotoclubs:TButton    (not read elsewhere)
'   0x00C65A40 g_cc_combo:TCombo             (matches .ComboSelectClub and .RefreshClubCombo,
'     already banked, same address)
'   0x00C65A44 g_cc_btn_removeclub:TButton   (not read elsewhere)
'   0x00C65A48 g_cc_tableplaces:TTable       (matches .SetUpScreen's naming for this address;
'     .RefreshClubCombo/.ButtonEditPlaceComp/.ButtonGoToClubs use three OTHER names for the
'     same address -- pre-existing inconsistency across already-banked files, not introduced
'     here)
'   0x00C65A4C g_cc_table:TTable             (matches .ButtonEditClub and .RefreshQualifiers,
'     the majority naming for this address)
'
' Class-table slots (class_tables.tsv / vtable_map.tsv):
'   TScreen+0x38 CreateScreen($,:TImage,()i,()i):TScreen ; TScreen+0x40 AddGadget(:TGadget)i
'   TButton+0x88 CreateButton (15-arg sig, see vtable_map)
'   TCombo+0x88  CreateCombo  (13-arg sig) ; TCombo+0x90 AddItem (unused here)
'   TTable+0x88  CreateTable  (11-arg sig) ; TTable+0x90 AddColumn(i,$,$,$,i)i
' This Type's OWN class-table slots, read as `push dword ptr [classtable+slot]` when passed
' as a callback VALUE (never called from inside this function):
'   +0x38 ButtonQuit +0x3c ComboContinent +0x40 ComboComp +0x48 ButtonEditComp
'   +0x4c ButtonEditPlaceComp +0x50 ButtonEditClub +0x54 ButtonGoToClubs
'   +0x58 RefreshClubCombo +0x5c ComboSelectClub +0x60 ButtonRemoveClub
'
' Every GetText(...) call in the decompilation takes exactly ONE argument (1831 corroborating
' sites, codegen-patterns.md 3a) -- the extra operands Ghidra shows inside the GetText(...)
' parens actually belong to the ENCLOSING CreateButton/CreateTable/CreateCombo/AddColumn call.
' The "X" text on the remove-club button is NOT run through GetText (no GetText call site
' precedes that CreateButton in the annotated CALLS list) -- it is the bare literal "X".
' Every string literal below was read directly out of NSS5.exe with harness.read_string() and
' matches the decompiled text exactly; the oracle masks a literal's ADDRESS, never its content.
'
' The right-hand column's gadgets share a running X cursor: a single Int Local starts at
' 10, and after each of the three widest widgets (combocontinent, combocomp, gotoclubs)
' is assigned to its Global it is advanced by that widget's width plus a 10px gutter
' (140, 260, 130) before the AddGadget call for that same widget -- confirmed by
' localise_diff against the three `add esi, N` sites, which appear in exactly that
' position (post-store, pre-AddGadget), never anywhere else. The remove-club button's
' X is that same cursor plus a one-off +210, computed inline and not written back.
'
' ORACLE: mode=reloc  matched=1736/1736  STATUS=MATCH.
'!Global g_promotionplace_int05:String
'!Global g_screen_continentalcomps:TScreen
'!Global g_cc_combocontinent:TCombo
'!Global g_cc_combocomp:TCombo
'!Global g_cc_btn_editcomp:TButton
'!Global g_cc_btn_editplace:TButton
'!Global g_cc_btn_editclub:TButton
'!Global g_cc_btn_gotoclubs:TButton
'!Global g_cc_combo:TCombo
'!Global g_cc_btn_removeclub:TButton
'!Global g_cc_tableplaces:TTable
'!Global g_cc_table:TTable
	Function CreateScreen()
		g_screen_continentalcomps = TScreen.CreateScreen("continentalcomps", LoadImage(g_promotionplace_int05 + "GameMedia/Images/Backgrounds/Grass.png", -1), Null, Null)
		g_screen_continentalcomps.AddGadget(TButton.CreateButton("pan_title", GetText("Continental Competitions"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_screen_continentalcomps.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
		Local x:Int = 10
		g_cc_combocontinent = TCombo.CreateCombo("cmb_Continent", GetText("Continent"), x, 50, 130, 30, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboContinent, 1)
		x :+ 140
		g_screen_continentalcomps.AddGadget(g_cc_combocontinent)
		g_cc_combocomp = TCombo.CreateCombo("cmb_Comp", GetText("Competition"), x, 50, 250, 30, 1, 2, "FFFF00", "FFFFFF", 1.0, ComboComp, 1)
		x :+ 260
		g_screen_continentalcomps.AddGadget(g_cc_combocomp)
		g_cc_btn_editcomp = TButton.CreateButton("btn_EditComp", GetText("Edit Comp"), x, 50, 124, 30, 1, 2, "9999FF", "FFFFFF", Null, ButtonEditComp, 1.0, 1, "")
		g_screen_continentalcomps.AddGadget(g_cc_btn_editcomp)
		g_cc_tableplaces = TTable.CreateTable("tbl_promotionfromplaces", 10, 90, 24, 0, 1, 2, "0000FF", 1.0, 1, RefreshClubCombo)
		g_cc_tableplaces.AddColumn(30, GetText("ID"), "000000", "EEEEEE", 1)
		g_cc_tableplaces.AddColumn(198, GetText("Promotion From Comps"), "000000", "AAAAAA", 0)
		g_cc_tableplaces.AddColumn(158, GetText("Place"), "000000", "EEEEEE", 1)
		g_screen_continentalcomps.AddGadget(g_cc_tableplaces)
		g_cc_btn_editplace = TButton.CreateButton("btn_EditPPComp", GetText("Edit Place"), x, 90, 120, 30, 1, 2, "9999FF", "FFFFFF", Null, ButtonEditPlaceComp, 1.0, 1, "")
		g_screen_continentalcomps.AddGadget(g_cc_btn_editplace)
		g_cc_btn_editclub = TButton.CreateButton("btn_EditClub", GetText("Edit Club"), x, 130, 120, 30, 1, 2, "9999FF", "FFFFFF", Null, ButtonEditClub, 1.0, 1, "")
		g_screen_continentalcomps.AddGadget(g_cc_btn_editclub)
		g_cc_btn_gotoclubs = TButton.CreateButton("btn_GoToClubs", GetText("Go To Clubs"), x, 170, 120, 30, 1, 2, "99FF99", "FFFFFF", Null, ButtonGoToClubs, 1.0, 1, "")
		x :+ 130
		g_screen_continentalcomps.AddGadget(g_cc_btn_gotoclubs)
		g_cc_combo = TCombo.CreateCombo("cmb_SelectClub", GetText("Select Club"), x, 50, 200, 30, 1, 2, "99FF99", "FFFFFF", 1.0, ComboSelectClub, 1)
		g_screen_continentalcomps.AddGadget(g_cc_combo)
		g_cc_btn_removeclub = TButton.CreateButton("btn_RemoveClub", "X", x + 210, 50, 30, 30, 1, 2, "FF9999", "FFFFFF", Null, ButtonRemoveClub, 1.0, 1, "")
		g_screen_continentalcomps.AddGadget(g_cc_btn_removeclub)
		g_cc_table = TTable.CreateTable("tbl_qualifiers", x, 90, 22, 0, 1, 2, "0000FF", 1.0, 1, Null)
		g_cc_table.AddColumn(40, GetText("ID"), "000000", "AAAAAA", 1)
		g_cc_table.AddColumn(100, GetText("Teams"), "000000", "EEEEEE", 0)
		g_cc_table.AddColumn(100, GetText("Nation"), "000000", "AAAAAA", 0)
		g_screen_continentalcomps.AddGadget(g_cc_table)
	End Function
