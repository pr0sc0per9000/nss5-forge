' TScreen_EditKits.RefreshKits
' VA 0x005353D7   2234 bytes   class-table slot 0x3c   KIND=Function (static)   sig ()i
' ORACLE: mode=reloc  matched=2234/2234  reloc_masked=167  STATUS=MATCH  (NSS5_NO_LEARN=1,
' naming=full -- every E8 call resolved by name on both sides).
' Body-only format: statements only, no parameters.
'
' ASSUMPTIONS / RESOLUTIONS
'   Globals (names are OURS; the DECLARED TYPES are load-bearing, corroborated by every
'   slot/field used through them):
'     0x00C65C70 g_editkits_team:TBase_Team     (also used by SetUpScreen, already on file)
'     0x00C65C74 g_editkits_skin1:Int            0x00C65C78 g_editkits_skin2:Int
'     0x00C65C6C g_editkits_screen:TScreen
'     0x00C65C88 g_screen_editkits_arr01:TKit[]     -- kit objects, one per Home/Away/Third/Keeper
'     0x00C65C98 g_screen_editkits_arr02:TButton[]  -- icon-preview buttons, same order
'     0x00C65CA4 g_screen_editkits_arr03:TCombo[]   -- "style" combo, same order
'     0x00C65CB0 g_screen_editkits_arr04:TCombo[]   -- shirt1-colour combo
'     0x00C65CBC g_screen_editkits_arr05:TCombo[]   -- shirt2-colour combo
'     0x00C65CCC g_screen_editkits_arr06:TCombo[]   -- shorts-colour combo
'     0x00C65CD8 g_screen_editkits_arr07:TCombo[]   -- socks-colour combo
'   None of these arrays needs an explicit downcast on element read: no _bbObjectDowncast
'   call precedes any [eax+ebx*4+0x18] access, so the array element type is already the
'   concrete Type (TKit[]/TButton[]/TCombo[]), not Object[].
'   TBase_Team.kitcolsHome/Away/Third/Keeper (TKitStrings) live at +0x44/0x48/0x4C/0x50
'   (same offsets already established in TScreen_EditClubs.RefreshKits). TKitStrings'
'   fields style/shirt1/shirt2/shorts/socks are +8/+0xC/+0x10/+0x14/+0x18
'   (extracted/object_model.json). TCombo.btn_head:TButton is +0x5C (object_model.json).
'   Calls: [0x00C5C4B8] = TKit+0x38 = CreateKit(:TKitStrings,$):TKit, TKit slot 0x3C =
'     GetPaintedPlayer($,i,i,$):TPixmap, TButton slot 0x90 = SetIcon(:TImage)i,
'     TCombo slot 0xAC = SelectItem(i)i, TGadget slot 0x64 = SetText($,$,i,i)i (inherited
'     by TInputBox/TButton), TGadget slot 0x6C = SetColour($,$)i (inherited by TButton).
'     0x004A6A30 = _bbStringCompare, 0x004A7AC0 = _bbStringFromInt (via `String(i)`),
'     0x004A7C20 = _bbStringConcat, 0x004A8F60 = _bbObjectDowncast (the `TInputBox(...)`
'     cast on the GetGadgetByName result), 0x004C5549 = GetText (module Function, ONE arg),
'     0x005AE256 = _brl_max2d_LoadImage, 0x004A8590 = _bbGCFree (inlined release of the old
'     arr01[n] kit on reassignment).
'   String literals read out of NSS5.exe:
'     0x00C81690 "GameMedia/Images/Interface/Player.png" (fixed filename, all 4 CreateKit
'       calls -- unlike TScreen_EditClubs/EditNations this screen does NOT call
'       kitcolsX.GetFileName() or concatenate a media-path prefix)
'     0x00C752AC "444444" (GetPaintedPlayer arg 1 and arg 4, all 4 calls)
'     0x00C5D284 "" (SetText's second/subtext arg, throughout)
'     0x00C5D680 "FFFFFF" (SetColour's second arg, throughout)
'     0x00C84B74/BB4/C0C/C64 "inp_Shirt1"/"inp_Shirt2"/"inp_Shorts"/"inp_Socks"
'       (TInputBox gadget-name prefixes; the per-row index i is appended with no separator)
'     0x00C84B3C "Shirt", 0x00C73B5C " 1", 0x00C82BFC " 2" (arr04/arr05 head-button text is
'       GetText("Shirt") + " 1" / + " 2" -- concat order confirmed by which push sits
'       immediately before the _bbStringConcat call, i.e. the LAST-pushed operand is the
'       LEFTMOST/first parameter)
'     0x00C84BD4 "Shorts", 0x00C84C2C "Socks" (arr06/arr07 head-button text is GetText(key)
'       directly, no prefix concat -- confirmed by there being no 0x004A7C20 call between
'       the GetText call and the SetText call for these two, unlike shirt1/shirt2)
'     Style-name literals and their SelectItem() index (0x00C75670.. through 0x00C75698):
'       PLAIN=1 STRIPES=2 SLEEVES=3 SLEEVE_L=4 SLEEVE_R=4 HOOPS=5 SINGLEHOOP=6 SPLIT=7
'       DIAGONALSPLIT_LR=8 DIAGONALSPLIT_RL=8 SEGMENTS=9 STRIPE_LR=10 STRIPE_RL=10
'       STRIPE_L=11 STRIPE_R=11 STRIPE_C=12 STRIPE_V=13 CHEQUERED=14 TRIM=15 default=16
'       (direction/side variants sharing one combo index is reproduced faithfully, not
'       "fixed" -- see law 3 in the project's five laws)
'
' CODEGEN NOTES
'   * Legacy bcc DOES compile `Select` on a String expression (each Case lowers to a
'     _bbStringCompare + `je` INTO an out-of-line case body, all bodies collected after the
'     last test, each ending `jmp <after-select>`). Writing the same logic as an If/ElseIf
'     chain compiles to a materially different, SHORTER shape (inline body + `jne`-skip),
'     which is how this was caught: If/ElseIf gave a length mismatch, `Select` on the same
'     19-way String dispatch matched byte-for-byte. NG's language guide bars Select-on-
'     String; legacy bcc accepts it -- add to the legacy-vs-NG gotcha list if writing this
'     pattern again.
'   * `Local ks:TKitStrings` is declared ONCE, before the `For` loop, not inside it. The
'     original's `mov edi,Null` (edi is ks's register) executes exactly once, immediately
'     before the loop's first entry; a `ks` declared textually inside the loop body
'     re-executes that reset every iteration (confirmed by trying it: produced a 5-byte
'     replace/insert pair, `mov edi,Null` relocated to the per-iteration entry point).
'   * `Select ks.style` (no intermediate `Local sty:String = ks.style`) reads the field
'     directly into the register the Select dispatch already wants (`mov esi,[edi+8]`,
'     one instruction). Introducing an explicit Local for the same value forced an extra
'     `mov eax,[edi+8] / mov esi,eax` hop -- the whole and only length delta (+2) on the
'     next-to-last iteration of this reconstruction.
'!Global g_editkits_team:TBase_Team
'!Global g_editkits_skin1:Int
'!Global g_editkits_skin2:Int
'!Global g_editkits_screen:TScreen
'!Global g_screen_editkits_arr01:TKit[]
'!Global g_screen_editkits_arr02:TButton[]
'!Global g_screen_editkits_arr03:TCombo[]
'!Global g_screen_editkits_arr04:TCombo[]
'!Global g_screen_editkits_arr05:TCombo[]
'!Global g_screen_editkits_arr06:TCombo[]
'!Global g_screen_editkits_arr07:TCombo[]
g_screen_editkits_arr01[0] = TKit.CreateKit(g_editkits_team.kitcolsHome, "GameMedia/Images/Interface/Player.png")
g_screen_editkits_arr01[1] = TKit.CreateKit(g_editkits_team.kitcolsAway, "GameMedia/Images/Interface/Player.png")
g_screen_editkits_arr01[2] = TKit.CreateKit(g_editkits_team.kitcolsThird, "GameMedia/Images/Interface/Player.png")
g_screen_editkits_arr01[3] = TKit.CreateKit(g_editkits_team.kitcolsKeeper, "GameMedia/Images/Interface/Player.png")
Local pix1:TPixmap = g_screen_editkits_arr01[0].GetPaintedPlayer("444444", g_editkits_skin1, -1, "444444")
Local pix2:TPixmap = g_screen_editkits_arr01[1].GetPaintedPlayer("444444", g_editkits_skin1, -1, "444444")
Local pix3:TPixmap = g_screen_editkits_arr01[2].GetPaintedPlayer("444444", g_editkits_skin2, -1, "444444")
Local pix4:TPixmap = g_screen_editkits_arr01[3].GetPaintedPlayer("444444", g_editkits_skin2, -1, "444444")
g_screen_editkits_arr02[0].SetIcon(LoadImage(pix1, -1))
g_screen_editkits_arr02[1].SetIcon(LoadImage(pix2, -1))
g_screen_editkits_arr02[2].SetIcon(LoadImage(pix3, -1))
g_screen_editkits_arr02[3].SetIcon(LoadImage(pix4, -1))
Local ks:TKitStrings
For Local i:Int = 0 To 3
	Select i
		Case 0
			ks = g_editkits_team.kitcolsHome
		Case 1
			ks = g_editkits_team.kitcolsAway
		Case 2
			ks = g_editkits_team.kitcolsThird
		Case 3
			ks = g_editkits_team.kitcolsKeeper
	End Select
	Select ks.style
		Case "PLAIN"
			g_screen_editkits_arr03[i].SelectItem(1)
		Case "STRIPES"
			g_screen_editkits_arr03[i].SelectItem(2)
		Case "SLEEVES"
			g_screen_editkits_arr03[i].SelectItem(3)
		Case "SLEEVE_L"
			g_screen_editkits_arr03[i].SelectItem(4)
		Case "SLEEVE_R"
			g_screen_editkits_arr03[i].SelectItem(4)
		Case "HOOPS"
			g_screen_editkits_arr03[i].SelectItem(5)
		Case "SINGLEHOOP"
			g_screen_editkits_arr03[i].SelectItem(6)
		Case "SPLIT"
			g_screen_editkits_arr03[i].SelectItem(7)
		Case "DIAGONALSPLIT_LR"
			g_screen_editkits_arr03[i].SelectItem(8)
		Case "DIAGONALSPLIT_RL"
			g_screen_editkits_arr03[i].SelectItem(8)
		Case "SEGMENTS"
			g_screen_editkits_arr03[i].SelectItem(9)
		Case "STRIPE_LR"
			g_screen_editkits_arr03[i].SelectItem(10)
		Case "STRIPE_RL"
			g_screen_editkits_arr03[i].SelectItem(10)
		Case "STRIPE_L"
			g_screen_editkits_arr03[i].SelectItem(11)
		Case "STRIPE_R"
			g_screen_editkits_arr03[i].SelectItem(11)
		Case "STRIPE_C"
			g_screen_editkits_arr03[i].SelectItem(12)
		Case "STRIPE_V"
			g_screen_editkits_arr03[i].SelectItem(13)
		Case "CHEQUERED"
			g_screen_editkits_arr03[i].SelectItem(14)
		Case "TRIM"
			g_screen_editkits_arr03[i].SelectItem(15)
		Default
			g_screen_editkits_arr03[i].SelectItem(16)
	End Select
	TInputBox(g_editkits_screen.GetGadgetByName("inp_Shirt1" + String(i))).SetText(ks.shirt1, "", -1, -1)
	TInputBox(g_editkits_screen.GetGadgetByName("inp_Shirt2" + String(i))).SetText(ks.shirt2, "", -1, -1)
	TInputBox(g_editkits_screen.GetGadgetByName("inp_Shorts" + String(i))).SetText(ks.shorts, "", -1, -1)
	TInputBox(g_editkits_screen.GetGadgetByName("inp_Socks" + String(i))).SetText(ks.socks, "", -1, -1)
	g_screen_editkits_arr04[i].btn_head.SetColour(ks.shirt1, "FFFFFF")
	g_screen_editkits_arr04[i].btn_head.SetText(GetText("Shirt") + " 1", "", -1, -1)
	g_screen_editkits_arr05[i].btn_head.SetColour(ks.shirt2, "FFFFFF")
	g_screen_editkits_arr05[i].btn_head.SetText(GetText("Shirt") + " 2", "", -1, -1)
	g_screen_editkits_arr06[i].btn_head.SetColour(ks.shorts, "FFFFFF")
	g_screen_editkits_arr06[i].btn_head.SetText(GetText("Shorts"), "", -1, -1)
	g_screen_editkits_arr07[i].btn_head.SetColour(ks.socks, "FFFFFF")
	g_screen_editkits_arr07[i].btn_head.SetText(GetText("Socks"), "", -1, -1)
Next
