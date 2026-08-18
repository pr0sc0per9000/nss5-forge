' TScreen_EditContinents.CreateScreen
' VA 0x0052836A   2455 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' (2455/2455, original length from Ghidra's inventory, reloc_masked=252; verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run itself taught.)
'
' Gadget-construction twin of TScreen_EditNations.CreateScreen (same shape: title panel,
' quit button, a left "details" table used purely as a row-label legend, an id-scroller
' triplet, a stack of TInputBox value fields, then a right-hand "members" table + Go
' button). Reused that file's naming convention and float constants directly.
'
' ASSUMPTIONS -- module Globals (names ours; addresses are the load-bearing part)
'   0x00C64EC0 -> g_ec_screen:TScreen          (assigned from TScreen.CreateScreen)
'   0x00C64EC4 -> g_ec_continent:TContinent     (declared here for self-containment;
'                 touched only by the already-banked SetUpScreen, not by this body)
'   0x00C64EC8 -> g_ec_details:TTable           (the left "tbl_details" legend table --
'                 NOT named g_table: that name is already claimed by at least THREE other
'                 distinct addresses in the corpus -- 0x00C65038 (TScreen_EditNations),
'                 0x00C679B8 (TScreen_Stats.UpdateHistoryTable, stated explicitly in its
'                 own header) and TScreen_ContinentalComps.ButtonEditPlaceComp. That is a
'                 pre-existing name collision (section 14.1 risk), out of scope to fix
'                 here; this file avoids adding a fourth address under the same name.)
'   0x00C64ECC -> g_ec_btn_prev:TButton         ("btn_idl", the '<' scroller)
'   0x00C64ED0 -> g_ec_btn_id:TButton           ("btn_id", the read-only id box; name
'                 reused from the already-banked SetUpScreen.bmx, which SetTexts it)
'   0x00C64ED4 -> g_ec_btn_next:TButton         ("btn_idr", the '>' scroller)
'   0x00C64ED8 -> g_ec_ib_name:TInputBox        0x00C64EDC -> g_ec_ib_tla:TInputBox
'   0x00C64EE0 -> g_ec_ib_continentality:TInputBox
'   0x00C64EE4 -> g_ec_ib_fedname:TInputBox     0x00C64EE8 -> g_ec_ib_fedshort:TInputBox
'   0x00C64EEC -> g_ec_ib_strength:TInputBox
'   (all six names above reused verbatim from the already-banked SetUpScreen.bmx, which
'    SetTexts every one of them from the loaded TContinent)
'   0x00C64EF0 -> g_ec_btn_nations:TButton      ("btn_members"; SetUpScreen.bmx SetTexts
'                 this same address with the "Nations (n)" count string)
'   0x00C64EF4 -> g_ec_table:TTable             ("tbl_members"; matches SetUpScreen.bmx's
'                 g_ec_table.ClearItems()/.AddItem() on the same address)
'   0x00C64EF8 -> g_ec_btn_go:TButton           ("btn_gomember")
'   0x00C6E950 -> g_mediapath:String  (bare String concat, no arithmetic; content is the
'                 game's install/media path prefix. NAME per TScreen_EditNations.Create-
'                 Screen, which performs the identical `+ "GameMedia/Images/..."` concat
'                 on this same address. UNCERTAIN: other already-banked files call this
'                 same VA g_datapath / g_pathPrefix -- a corpus-wide naming inconsistency
'                 for one real Global that predates this file; the VA is what matters and
'                 is not in doubt, module Global names have no effect on codegen.)
'   0x00C6EFE0 -> g_screenheight:Int  (bare dword read, no refcount traffic -> Int; name
'                 matches TScreen.DoMessage / TScreen_EditNations and others)
'
' Class-table slots resolved via class_tables.tsv + vtable_map.tsv (cross-checked against
' extracted/decomp_annotated/TScreen_EditContinents.CreateScreen@0052836a.c, whose header
' block independently derives every CALL's real argument count from `add esp,N` rather
' than trusting Ghidra's -- Ghidra's own printed parameter counts for FUN_004c5549 in the
' raw, non-annotated decompile are wrong by construction, exactly as documented for
' GetText in codegen-patterns.md section 7):
'   0x00C61C64 = TScreen+0x38    CreateScreen($,:TImage,()i,()i):TScreen
'   0x00C623CC = TButton+0x88    CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'   0x00C62BAC = TTable+0x88     CreateTable($,i,i,i,i,i,i,$,f,i,()i):TTable
'   0x00C625E0 = TInputBox+0x88  CreateInputBox($,i,i,i,i,i,i,$,$,i,f,()i,i,$):TInputBox
'   slot 0x40 on the TScreen Global = TScreen.AddGadget(:TGadget)i
'   TTable slot 0x90 = AddColumn(i,$,$,$,i)   slot 0x94 = AddItem([]$,$,$)
'   Own-Type callbacks (same Type -> bare name): 0x00C6501C=+0x38 ButtonQuit,
'   0x00C65020=+0x3C ButtonPrevCont, 0x00C65024=+0x40 ButtonNextCont,
'   0x00C65028=+0x44 UpdateCont, 0x00C6502C=+0x48 GoMember.
'
' Helpers: FUN_004C5549 = GetText (module Function, already recovered). 0x004A7C20 =
' _bbStringConcat, 0x004A63D0 = _bbArrayNew1D (the one-element String array of each
' AddItem row), 0x005AE256 = brl.max2d LoadImage, 0x005B9690 = _bbFloatToInt (emitted for
' Int(...)), 0x005B95D0 = the empty function, i.e. source-level Null for an ()i argument.
'
' Field offsets used: TGadget.x @ +0x20 (Float), TTable.ih @ +0x68 (Int).
'
' Literals were read out of NSS5.exe with harness.read_string -- the oracle masks a
' literal's ADDRESS, so their CONTENT is not certified by the MATCH. The six left-column
' row labels (0xC82910/24/48/70/9C/D4) read "Name", "Abbreviation", "Continentality",
' "Federation Name", "Federation Short Name", "Strength" -- note "Abbreviation" for the
' TLA field, not "TLA" (the gadget's own NAME is "inp_TLA" at 0xC82A64, but its row-label
' text is the word "Abbreviation"). Float constants read as raw dwords: 0x00C829F0 =
' 0x00C82B24 = 165.0, 0x00C82B28 = 10.0 (identical values to TScreen_EditNations).
'   0x00C82848 'GameMedia/Images/Backgrounds/Grass.png'   0x00C828A0 'editcontinents'
'   0x00C82448 'Continents'   0x00C828C8 'Menu'   0x00C8249C 'Nations'
'   0x00C82B74 'Go'   0x00C6E904 '00FF00'
'
' Three Locals are forced by the original (bcc does no CSE; `push dword [ebp-8]` /
' `[ebp-0xc]` / `[ebp-4]` for the 2, 300 and the FloatToInt result prove they were
' variables); `h` and `y` stay live in edi/ebx across the whole function and never spill,
' exactly as in TScreen_EditNations.CreateScreen. Declaration order style/h/w/x/y follows
' that file's established order (section 18.2's tie-break). `y :+ h + 1` appears after
' every gadget in the left column except the very last input box, and once more after
' creating g_ec_btn_nations in the right column -- that second increment (original +2048,
' `89 F8 / 83 C0 01 / 01 C3`) is easy to miss because AddGadget(g_ec_btn_nations) follows
' it immediately; missing it cost exactly 7 bytes (localise_diff.py: one gap, COMPLETE) on
' the first draft. `y` is then reassigned (not redeclared) to a fresh 50 before the right
' column, and the final Go button's y is `g_screenheight - 35` computed inline, never
' routed back through `y`.
'!Global g_ec_screen:TScreen
'!Global g_ec_continent:TContinent
'!Global g_ec_details:TTable
'!Global g_ec_btn_prev:TButton
'!Global g_ec_btn_id:TButton
'!Global g_ec_btn_next:TButton
'!Global g_ec_ib_name:TInputBox
'!Global g_ec_ib_tla:TInputBox
'!Global g_ec_ib_continentality:TInputBox
'!Global g_ec_ib_fedname:TInputBox
'!Global g_ec_ib_fedshort:TInputBox
'!Global g_ec_ib_strength:TInputBox
'!Global g_ec_btn_nations:TButton
'!Global g_ec_table:TTable
'!Global g_ec_btn_go:TButton
'!Global g_mediapath:String
'!Global g_screenheight:Int
	Function CreateScreen()
		g_ec_screen = TScreen.CreateScreen("editcontinents", LoadImage(g_mediapath + "GameMedia/Images/Backgrounds/Grass.png"), Null, Null)
		g_ec_screen.AddGadget(TButton.CreateButton("pan_title", GetText("Continents"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
		g_ec_screen.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
		g_ec_details = TTable.CreateTable("tbl_details", 10, 50, 20, 24, 0, 2, "0000FF", 1.0, 1, Null)
		g_ec_details.AddColumn(160, "ID", "000000", "AAAAAA", 2)
		g_ec_details.AddItem([GetText("Name")], "", "")
		g_ec_details.AddItem([GetText("Abbreviation")], "", "")
		g_ec_details.AddItem([GetText("Continentality")], "", "")
		g_ec_details.AddItem([GetText("Federation Name")], "", "")
		g_ec_details.AddItem([GetText("Federation Short Name")], "", "")
		g_ec_details.AddItem([GetText("Strength")], "", "")
		g_ec_screen.AddGadget(g_ec_details)
		Local style:Int = 2
		Local h:Int = g_ec_details.ih
		Local w:Int = 300
		Local x:Int = Int(g_ec_details.x + 165.0)
		Local y:Int = 50
		g_ec_btn_prev = TButton.CreateButton("btn_idl", "<", x, y, 98, h, 1, style, "99FF99", "FFFFFF", Null, ButtonPrevCont, 1.0, 4, "")
		g_ec_btn_id = TButton.CreateButton("btn_id", "", x + 100, y, 100, h, 0, style, "AAAAAA", "FFFFFF", Null, Null, 1.0, 0, "")
		g_ec_btn_next = TButton.CreateButton("btn_idr", ">", x + 202, y, 98, h, 1, style, "99FF99", "FFFFFF", Null, ButtonNextCont, 1.0, 5, "")
		y :+ h + 1
		g_ec_screen.AddGadget(g_ec_btn_prev)
		g_ec_screen.AddGadget(g_ec_btn_id)
		g_ec_screen.AddGadget(g_ec_btn_next)
		g_ec_ib_name = TInputBox.CreateInputBox("inp_Name", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateCont, 0, "")
		y :+ h + 1
		g_ec_ib_tla = TInputBox.CreateInputBox("inp_TLA", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateCont, 0, "")
		y :+ h + 1
		g_ec_ib_continentality = TInputBox.CreateInputBox("inp_Continentality", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateCont, 0, "")
		y :+ h + 1
		g_ec_ib_fedname = TInputBox.CreateInputBox("inp_FedName", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateCont, 0, "")
		y :+ h + 1
		g_ec_ib_fedshort = TInputBox.CreateInputBox("inp_FedShortName", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateCont, 0, "")
		y :+ h + 1
		g_ec_ib_strength = TInputBox.CreateInputBox("inp_Strength", x, y, w, h, 1, style, "FFFFFF", "000000", 32, 1.0, UpdateCont, 0, "")
		g_ec_screen.AddGadget(g_ec_ib_name)
		g_ec_screen.AddGadget(g_ec_ib_tla)
		g_ec_screen.AddGadget(g_ec_ib_continentality)
		g_ec_screen.AddGadget(g_ec_ib_fedname)
		g_ec_screen.AddGadget(g_ec_ib_fedshort)
		g_ec_screen.AddGadget(g_ec_ib_strength)
		x = Int(g_ec_details.x + 165.0 + w + 10.0)
		y = 50
		g_ec_btn_nations = TButton.CreateButton("btn_members", GetText("Nations"), x, y, w, h, 0, style, "AAAAAA", "FFFFFF", Null, Null, 1.0, 0, "")
		y :+ h + 1
		g_ec_screen.AddGadget(g_ec_btn_nations)
		g_ec_table = TTable.CreateTable("tbl_members", x, y, 23, 0, 1, 2, "0000FF", 1.0, 1, Null)
		g_ec_table.AddColumn(58, GetText("ID"), "000000", "AAAAAA", 1)
		g_ec_table.AddColumn(180, GetText("Name"), "000000", "AAAAAA", 0)
		g_ec_table.AddColumn(58, GetText("Strength"), "000000", "AAAAAA", 1)
		g_ec_screen.AddGadget(g_ec_table)
		g_ec_btn_go = TButton.CreateButton("btn_gomember", GetText("Go"), x, g_screenheight - 35, w, h, 1, style, "00FF00", "FFFFFF", Null, GoMember, 1.0, 1, "")
		g_ec_screen.AddGadget(g_ec_btn_go)
	End Function
