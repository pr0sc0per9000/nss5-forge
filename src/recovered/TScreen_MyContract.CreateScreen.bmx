' TScreen_MyContract.CreateScreen
' VA 0x005542E9   2536 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, NO implicit Self), SIG ()i, class-table slot 0x30
' 2536/2536, original length from Ghidra's inventory, reloc_masked=233.
' Re-verified with NSS5_NO_LEARN=1 (still MATCH, so no helper name was learned in-run).
'
' ASSUMPTIONS
'   Module Globals -- the ADDRESSES are fact, the NAMES are ours (module Globals carry no
'   debug record).  The declared TYPE is load-bearing: it picks the dispatch slot.
'     0x00C67D7C g_mc_screen:TScreen                (construction site = TScreen.CreateScreen)
'     0x00C67D84 g_mc_pan_transferstatus:TPanel      "Transfer Status" panel
'     0x00C67D88 g_mc_lbl_translisted1:TLabel        "Transfer Listed" caption
'     0x00C67D8C g_mc_lbl_translisted2:TLabel        "Transfer Listed" value (blank)
'     0x00C67D90 g_mc_btn_requesttransfer:TButton
'     0x00C67D94 g_mc_btn_requestloan:TButton
'     0x00C67D98 g_mc_lbl_desired:TLabel             "Desired Transfer" caption
'     0x00C67D9C g_mc_lbl_clubsinterested2:TLabel    "Clubs Interested" value (blank)
'     0x00C67DA0 g_mc_cmb_continent:TCombo           0x00C67DA4 g_mc_cmb_nation:TCombo
'     0x00C67DA8 g_mc_cmb_division:TCombo            0x00C67DAC g_mc_cmb_club:TCombo
'     0x00C67DB0 g_mc_lbl_offers:TLabel              "transfer_CurrentOffers" caption
'   SHARED with other screens -- same addresses, names kept consistent with the files that
'   established them:
'     0x00C66768 g_pan_title:TPanel   0x00C66780 g_lbl_year:TLabel   0x00C66784 g_lbl_week:TLabel
'       (TScreen_GameMenu.CreateScreen -- the title bar and its year/week labels, re-added
'        onto this screen; construction-site typed there)
'     0x00C6672C g_img_home:TImage   (also from TScreen_GameMenu.CreateScreen -- the Home
'       icon, reused here for btn_play's image, matching its "tt_Home" tooltip)
'     0x00C67B24 g_co_pan538:TPanel   0x00C67B4C g_co_btn548:TButton
'       (TScreen_ContractOffer.CreateScreen -- the "Current Contract" panel and its
'        "Renew Contract" button, both re-added/reused on this screen; also used, under
'        different local names, by TScreen_MyContract.SetUpScreen)
'     0x00C6EFDC g_screenwidth:Int   0x00C6EFE0 g_screenheight:Int   (bare dword reads)
'     0x00C67DC0 g_screen_mycontract_arr:TButton[]   (established by
'       TScreen_MyContract.UpdateOfferButtons -- the five "btn_OfferN" buttons; only TGadget
'       slots are used on its elements here, consistent with that file's note that TLabel[]
'       would emit the same bytes, but TButton[] is what the sibling file settled on)
'
'   Class-table slots, resolved via class_tables.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38       CreateScreen($,:TImage,()i,()i):TScreen
'     0x00C63294 = TPanel+0x88        CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C623CC = TButton+0x88       CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     0x00C634C0 = TLabel+0x88        CreateLabel($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     0x00C630E0 = TCombo+0x88        CreateCombo($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo
'     0x00C638BC = THelpBox+0x30      Create(:TGadget,i,i,i,i,$,i,i):THelpBox
'     TScreen slot 0x40 = AddGadget(:TGadget)i ; TGadget slot 0x74 = AddChild(:TGadget)i
'       (TPanel has no 0x74 of its own -- inherited from TGadget)
'     TList slot 0x44 = AddLast ; TScreen field +0x1C = lHelp:TList
'     0x00C68010/24/28/2C/30/34/38/6C = TScreen_MyContract+0x38/4C/50/54/58/5C/60/6C =
'       ButtonPlay / ButtonRequestTransfer / ButtonRequestLoan / ComboContinent /
'       ComboNation / ComboDivision / ComboClub / ButtonOffer -- all on THIS Type's own
'       table, so every callback is written bare, with no `TScreen_MyContract.` prefix
'       (matches TScreen_GameMenu.CreateScreen's precedent for its own sibling callbacks).
'   BRL / module Functions: 0x004C5549 GetText (ONE argument -- Ghidra merges the following
'   gadget-factory pushes into its arg list), 0x004A7AC0 _bbStringFromInt / 0x004A7C20
'   _bbStringConcat (the "btn_Offer" + i concatenation), 0x004A8590 the GC free of the
'   inlined BBRELEASE (never written in source).
'   0x005B95D0 in an ()i argument slot is source-level Null; 0x005C9C80 is bbNullObject.
'
' LITERALS were read out of the exe with harness.read_string (verified for every string used
' here) -- a MATCH masks a literal's ADDRESS, so its contents are not otherwise certified.
' 0x005C7D40 and 0x00C5D284 are both the empty string.
'
' SHAPE NOTES (read off the disassembly, not the decompilation -- Ghidra folds several of
' these expressions into misleading literals)
'   * `x` and `w` are declared ONCE, before "lbl_Offers" (190 and 150), and REUSED by
'     reassignment (never redeclared) for the "Transfer Status" section and the offer-button
'     loop. `y` and `h` are declared for the first time only after the loop.
'   * The five "btn_OfferN" buttons are `For Local i:Int = 0 To 4` (`cmp esi,4 / jle`, per
'     codegen-patterns 3f); the button name is `"btn_Offer" + i` (String coercion, not an
'     explicit `String(i)` call -- same bytes either way, this is the source form).
'   * Every row advance in the offer loop is `x :+ w + 10` (reads `w` from its slot), not a
'     folded `x :+ 90`, even though `w` is constant 80 throughout the loop -- codegen-patterns
'     10.6/16.8: a Local read emits a different instruction than an equal literal.
'   * The "Transfer Status" panel's own `h` argument is the LITERAL 40, not the `h` Local --
'     `h` is declared in the very next statement and used everywhere after, but not by the
'     panel that triggered its declaration (matches the identical quirk in
'     TScreen_ContractOffer.CreateScreen's "Current Contract" panel).
'   * `w / 2` and `h + 10` etc. are recomputed at every use with no CSE (bcc does none): the
'     "lbl_Status2" value label recomputes `w / 2` twice in one call (once for its own width,
'     once folded into `x + w / 2`), and "btn_RequestLoan" recomputes `w / 2` twice the same
'     way for its x-position and its width.
'   * The "Clubs Interested" row is the one place `y` advances by `h` alone (no `+ 10`), and
'     "lbl_clubsinterested2" is the one place a height is `h + 30` rather than a fresh literal.
'   * `h` is reassigned from 40 to 30 for the four combos, mid-function, by a plain `h = 30`
'     (not a new `Local`) -- the frame stays `sub esp,8` throughout, i.e. only `w` and `h`
'     ever spill; `x`, `y` and the loop's `i` stay in registers throughout their live ranges
'     (which register is byte-neutral, per codegen-patterns 18.1/18.2).
'   * `btn_play`, the four "btn_OfferN" buttons and "lbl_clubsinterested1" are never stored to
'     a Global -- they are built inline as the direct argument of `AddGadget`/`AddChild`
'     (except the offer buttons, which go through the shared array).
'!Global g_mc_screen:TScreen
'!Global g_pan_title:TPanel
'!Global g_co_pan538:TPanel
'!Global g_lbl_year:TLabel
'!Global g_lbl_week:TLabel
'!Global g_img_home:TImage
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_mc_lbl_offers:TLabel
'!Global g_screen_mycontract_arr:TButton[]
'!Global g_mc_pan_transferstatus:TPanel
'!Global g_mc_lbl_translisted1:TLabel
'!Global g_mc_lbl_translisted2:TLabel
'!Global g_mc_btn_requesttransfer:TButton
'!Global g_mc_btn_requestloan:TButton
'!Global g_mc_lbl_desired:TLabel
'!Global g_mc_cmb_continent:TCombo
'!Global g_mc_cmb_nation:TCombo
'!Global g_mc_cmb_division:TCombo
'!Global g_mc_cmb_club:TCombo
'!Global g_mc_lbl_clubsinterested2:TLabel
'!Global g_co_btn548:TButton
	Function CreateScreen()
		g_mc_screen = TScreen.CreateScreen("mycontract", Null, Null, Null)
		g_mc_screen.AddGadget(g_pan_title)
		g_mc_screen.AddGadget(g_co_pan538)
		g_mc_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_mc_screen.AddGadget(g_lbl_year)
		g_mc_screen.AddGadget(g_lbl_week)
		g_mc_screen.AddGadget(TButton.CreateButton("btn_play", "", 120, g_screenheight - 50, 60, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_home, ButtonPlay, 1.0, 1, GetText("tt_Home")))
		Local x:Int = 190
		Local w:Int = 150
		g_mc_lbl_offers = TLabel.CreateLabel("lbl_Offers", GetText("transfer_CurrentOffers"), x, g_screenheight - 50, w, 40, 2, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_mc_screen.AddGadget(g_mc_lbl_offers)
		x :+ w + 10
		w = 80
		For Local i:Int = 0 To 4
			g_screen_mycontract_arr[i] = TButton.CreateButton("btn_Offer" + i, "", x, g_screenheight - 50, w, 40, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonOffer, 1.0, 1, "")
			g_mc_screen.AddGadget(g_screen_mycontract_arr[i])
			x :+ w + 10
		Next
		x = g_screenwidth / 2 + 5
		Local y:Int = 70
		w = g_screenwidth / 2 - 15
		Local h:Int = 40
		g_mc_pan_transferstatus = TPanel.CreatePanel("pan_TransferStatus", GetText("Transfer Status"), x, y, w, 40, "FFFFFF", "FFFFFF", 3, 0.8, 1, 420, 0)
		y :+ 50
		x :+ 10
		w :- 20
		g_mc_screen.AddGadget(g_mc_pan_transferstatus)
		g_mc_lbl_translisted1 = TLabel.CreateLabel("lbl_Status2", GetText("Transfer Listed"), x, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_mc_lbl_translisted2 = TLabel.CreateLabel("lbl_Status2", "", x + w / 2, y, w / 2, h, 3, "888888", "FFFFFF", 1.0, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_mc_pan_transferstatus.AddChild(g_mc_lbl_translisted1)
		g_mc_pan_transferstatus.AddChild(g_mc_lbl_translisted2)
		g_mc_btn_requesttransfer = TButton.CreateButton("btn_RequestTransfer", GetText("transfer_Request"), x, y, w / 2 - 5, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonRequestTransfer, 1.0, 1, "")
		g_mc_screen.AddGadget(g_mc_btn_requesttransfer)
		g_mc_btn_requestloan = TButton.CreateButton("btn_RequestLoan", GetText("transfer_RequestLoan"), x + w / 2 + 5, y, w / 2 - 5, h, 1, 2, "FFFFFF", "FFFFFF", Null, ButtonRequestLoan, 1.0, 1, "")
		y :+ h + 10
		g_mc_screen.AddGadget(g_mc_btn_requestloan)
		g_mc_lbl_desired = TLabel.CreateLabel("lbl_desired", GetText("Desired Transfer"), x, y, w, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		y :+ h + 10
		g_mc_pan_transferstatus.AddChild(g_mc_lbl_desired)
		h = 30
		g_mc_cmb_continent = TCombo.CreateCombo("cmb_Continent", GetText("Any Continent"), x, y, w, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboContinent, 1)
		y :+ h + 10
		g_mc_cmb_nation = TCombo.CreateCombo("cmb_Nation", GetText("Any Nation"), x, y, w, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboNation, 1)
		y :+ h + 10
		g_mc_cmb_division = TCombo.CreateCombo("cmb_Division", GetText("Any Division"), x, y, w, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboDivision, 1)
		y :+ h + 10
		g_mc_cmb_club = TCombo.CreateCombo("cmb_Club", GetText("Any Club"), x, y, w, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboClub, 1)
		y :+ h + 10
		g_mc_pan_transferstatus.AddChild(g_mc_cmb_continent)
		g_mc_pan_transferstatus.AddChild(g_mc_cmb_nation)
		g_mc_pan_transferstatus.AddChild(g_mc_cmb_division)
		g_mc_pan_transferstatus.AddChild(g_mc_cmb_club)
		g_mc_pan_transferstatus.AddChild(TLabel.CreateLabel("lbl_clubsinterested1", GetText("Clubs Interested"), x, y, w, h, 2, "FFFFFF", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h
		g_mc_lbl_clubsinterested2 = TLabel.CreateLabel("lbl_clubsinterested2", "", x, y, w, h + 30, 2, "888888", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_mc_pan_transferstatus.AddChild(g_mc_lbl_clubsinterested2)
		g_mc_screen.lHelp.AddLast(THelpBox.Create(g_co_btn548, 0, 0, 0, 0, GetText("CHELP_RENEWCONTRACT"), 2, 2))
		g_mc_screen.lHelp.AddLast(THelpBox.Create(g_mc_btn_requesttransfer, 0, 0, 0, 0, GetText("CHELP_TRANSFERBUTTON"), 1, 2))
		g_mc_screen.lHelp.AddLast(THelpBox.Create(g_mc_btn_requestloan, 0, 0, 0, 0, GetText("CHELP_LOANBUTTON"), 1, 2))
		g_mc_screen.lHelp.AddLast(THelpBox.Create(g_mc_cmb_continent, 0, 0, 0, 0, GetText("CHELP_TRANSFERCOMBOS"), 1, 2))
	End Function
