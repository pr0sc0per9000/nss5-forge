' TScreen_EditKits.CreateScreen
' VA 0x0053465A   3057 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x30
' (3057/3057, original length from Ghidra's inventory, reloc_masked=280; verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run itself taught.
'  Re-run twice, same result.)
'
' ASSUMPTIONS -- module Globals (names ours; the ADDRESS is the load-bearing part)
'   0x00C65C6C -> g_editkits_screen:TScreen     (from TScreen.CreateScreen; the name is
'                 already verified by TScreen_EditKits.SetUpScreen)
'   0x00C65C98 -> g_editkits_btnKit:TButton[]      (kit preview buttons)
'   0x00C65CA4 -> g_editkits_cmbKitType:TCombo[]
'   0x00C65CB0 -> g_editkits_cmbShirt1:TCombo[]
'   0x00C65CBC -> g_editkits_cmbShirt2:TCombo[]
'   0x00C65CCC -> g_editkits_cmbShorts:TCombo[]
'   0x00C65CD8 -> g_editkits_cmbSocks:TCombo[]
'   0x00C65CE8 -> g_editkits_inpShirt1:TInputBox[]
'   0x00C65CF8 -> g_editkits_inpShirt2:TInputBox[]
'   0x00C65D08 -> g_editkits_inpShorts:TInputBox[]
'   0x00C65D18 -> g_editkits_inpSocks:TInputBox[]
'   0x00C6E950 -> g_mediapath:String  (concatenated with the .png path before LoadImage)
' globals_final.tsv types the ten arrays `Object[]` from USAGE; that is wrong in the
' informative direction -- the element type is fixed by the slot each array element is
' called through (0x90 = TCombo.AddItem on arr03..arr07) and by what is stored into it
' (TCombo.CreateCombo / TInputBox.CreateInputBox / TButton.CreateButton).  Element access
' is `mov eax,[g] / mov eax,[eax+edi*4+0x18]`, i.e. BBArray data at +0x18 (patterns 11.1).
'
' Class-table slots resolved via class_tables.tsv + vtable_map.tsv:
'   0x00C61C64 = TScreen+0x38   CreateScreen($,:TImage,()i,()i):TScreen
'   0x00C623CC = TButton+0x88   CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'   0x00C630E0 = TCombo+0x88    CreateCombo($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo
'   0x00C625E0 = TInputBox+0x88 CreateInputBox($,i,i,i,i,i,i,$,$,i,f,()i,i,$):TInputBox
'   slot 0x40 on the TScreen Global = TScreen.AddGadget(:TGadget)i
'   TCombo slot 0x90 = AddItem($,$,$,i)
'   Own-Type callbacks (same Type -> bare name, no Type. prefix):
'     0x00C65E1C = +0x38 ButtonQuit   0x00C65E24 = +0x40 UpdateKitCmb
'     0x00C65E28 = +0x44 UpdateKitInp
'
' Helpers: 0x004C5549 = GetText and 0x00506DE2 = KitColour, both recovered module
' Functions (KitColour is verified 240/240 -- without it the four E8s
' in the inner loop could not be named on the original side and this body could not have
' matched).  0x004A7AC0 = _bbStringFromInt (every `"name" + i`), 0x004A7C20 =
' _bbStringConcat, 0x005AE256 = brl.max2d LoadImage, 0x005B95D0 = the empty function,
' i.e. source-level Null for an ()i argument, 0x005C9C80 = bbNullObject.
'
' LOCALS -- the prologue is `sub esp,0x10`, exactly four dword slots, and all four are
' used: [ebp-4] y, [ebp-8] h, [ebp-0xC] x, [ebp-0x10] w.  `i` (edi) and `j` (ebx) are the
' two For counters and are register-allocated, as is the String `t`: bcc keeps it in eax
' across the whole Select and never spills it, which is why a fifth slot never appears
' (codegen-patterns 16.2 -- a String Local consumed downstream costs zero bytes).  The
' same shape is independently confirmed by KitColour, whose `Local c:Int = idx` lives in
' eax with no `sub esp` at all.
'   `y :+ h * 2`  is  mov eax,[ebp-8] / shl eax,1 / add [ebp-4],eax
'   `y :+ h + 2`  is  mov eax,[ebp-8] / add eax,2 / add [ebp-4],eax
'   `w / 2`       is  cdq / and edx,1 / add eax,edx / sar eax,1 (signed div-by-2), so the
'                 half-widths are `w / 2` while the column offset is the literal `x + 72`
'                 -- both spellings occur and they are not interchangeable.
'   `x :+ 200`    is  add dword [ebp-0xC],0xC8 at the bottom of the outer loop.
' `For ... To 3` / `To 16` (both emit `jle`), not `Until`.
'
' The four kit names are a Select on `i` with NO Case 0: the "Home Kit" fetch happens
' before the compare block and the no-match jump lands past every Case body, which is the
' Select signature from 10.2, not an If/ElseIf chain.
'
' Literals were read out of NSS5.exe with harness.read_string -- the oracle masks a
' literal's ADDRESS, so their CONTENT is certified by that read, not by the MATCH.
'   0x00C849D8 'editkits'      0x00C849F4 'Edit Kits'    0x00C828C8 'Menu'
'   0x00C84A14 'Home Kit'      0x00C84A30 'Away Kit'     0x00C84A4C 'Third Kit'
'   0x00C84A6C 'Keeper Kit'    0x00C84A8C 'editkits_kit' 0x00C84AB0 'Kit Type'
'   0x00C84ACC 'btn_KitType'   0x00C84AF0 'cmb_KitType'  0x00C81600 'btn_Kit'
'   0x00C84B3C 'Shirt'  0x00C73B5C ' 1'  0x00C82BFC ' 2'  0x00C84BD4 'Shorts'
'   0x00C84C2C 'Socks'  0x00C84B54 'cmb_Shirt1'  0x00C84B74 'inp_Shirt1'
'   0x00C84B94 'cmb_Shirt2'  0x00C84BB4 'inp_Shirt2'  0x00C84BEC 'cmb_Shorts'
'   0x00C84C0C 'inp_Shorts'  0x00C84C44 'cmb_Socks'  0x00C84C64 'inp_Socks'
'   0x00C82848 'GameMedia/Images/Backgrounds/Grass.png'
'   kit-type items: 0x00C75670 'PLAIN' 0x00C756AC 'STRIPES' 0x00C75790 'SLEEVES'
'   0x00C757AC 'SLEEVE' 0x00C757FC 'HOOPS' 0x00C75828 'SINGLEHOOP' 0x00C75848 'SPLIT'
'   0x00C84B14 'DIAGONALSPLIT' 0x00C758D4 'SEGMENTS' 0x00C75718 'STRIPE_LR'
'   0x00C756C8 'STRIPE' 0x00C75758 'STRIPE_C' 0x00C75774 'STRIPE_V'
'   0x00C758F0 'CHEQUERED' 0x00C75698 'TRIM'  -- that order is load-bearing.
' Note "Socks" takes GetText("Socks") + " 1" while "Shorts" takes a bare GetText, and the
' shirt rows use " 1"/" 2"; reproduce the asymmetry, do not tidy it (16.8).
'!Global g_editkits_screen:TScreen
'!Global g_editkits_btnKit:TButton[]
'!Global g_editkits_cmbKitType:TCombo[]
'!Global g_editkits_cmbShirt1:TCombo[]
'!Global g_editkits_cmbShirt2:TCombo[]
'!Global g_editkits_cmbShorts:TCombo[]
'!Global g_editkits_cmbSocks:TCombo[]
'!Global g_editkits_inpShirt1:TInputBox[]
'!Global g_editkits_inpShirt2:TInputBox[]
'!Global g_editkits_inpShorts:TInputBox[]
'!Global g_editkits_inpSocks:TInputBox[]
'!Global g_mediapath:String
	g_editkits_screen = TScreen.CreateScreen("editkits", LoadImage(g_mediapath + "GameMedia/Images/Backgrounds/Grass.png"), Null, Null)
	g_editkits_screen.AddGadget(TButton.CreateButton("pan_title", GetText("Edit Kits"), 0, 0, 800, 40, 0, 3, "EEEEEE", "FFFFFF", Null, Null, 1.0, 0, ""))
	g_editkits_screen.AddGadget(TButton.CreateButton("quit", GetText("Menu"), 690, 10, 100, 20, 1, 2, "FF0000", "000000", Null, ButtonQuit, 1.0, 1, ""))
	Local x:Int = 26
	Local w:Int = 144
	Local h:Int = 20
	For Local i:Int = 0 To 3
		Local y:Int = 64
		Local t:String = GetText("Home Kit")
		Select i
		Case 1
			t = GetText("Away Kit")
		Case 2
			t = GetText("Third Kit")
		Case 3
			t = GetText("Keeper Kit")
		End Select
		g_editkits_screen.AddGadget(TButton.CreateButton("editkits_kit" + i, t, x, y, w, h, 0, 2, "AAAAAA", "FFFFFF", Null, Null, 1.0, 1, ""))
		y :+ h * 2
		g_editkits_screen.AddGadget(TButton.CreateButton("btn_KitType" + i, GetText("Kit Type"), x, y, w / 2, h, 0, 2, "AAAAAA", "FFFFFF", Null, Null, 1.0, 1, ""))
		g_editkits_cmbKitType[i] = TCombo.CreateCombo("cmb_KitType" + i, GetText("Kit Type"), x + 72, y, w / 2, h, 1, 2, "FFFF99", "000000", 1.0, UpdateKitCmb, 1)
		y :+ h + 2
		g_editkits_cmbKitType[i].AddItem("PLAIN", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("STRIPES", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("SLEEVES", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("SLEEVE", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("HOOPS", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("SINGLEHOOP", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("SPLIT", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("DIAGONALSPLIT", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("SEGMENTS", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("STRIPE_LR", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("STRIPE", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("STRIPE_C", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("STRIPE_V", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("CHEQUERED", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbKitType[i].AddItem("TRIM", "BBBBBB", "FFFFFF", 0)
		g_editkits_cmbShirt1[i] = TCombo.CreateCombo("cmb_Shirt1" + i, GetText("Shirt") + " 1", x, y, w / 2, h, 1, 2, "FFFF99", "000000", 1.0, UpdateKitCmb, 1)
		g_editkits_inpShirt1[i] = TInputBox.CreateInputBox("inp_Shirt1" + i, x + 72, y, w / 2, h, 1, 2, "FFFFFF", "000000", 6, 1.0, UpdateKitInp, 0, "")
		y :+ h + 2
		g_editkits_cmbShirt2[i] = TCombo.CreateCombo("cmb_Shirt2" + i, GetText("Shirt") + " 2", x, y, w / 2, h, 1, 2, "FFFF99", "000000", 1.0, UpdateKitCmb, 1)
		g_editkits_inpShirt2[i] = TInputBox.CreateInputBox("inp_Shirt2" + i, x + 72, y, w / 2, h, 1, 2, "FFFFFF", "000000", 6, 1.0, UpdateKitInp, 0, "")
		y :+ h + 2
		g_editkits_cmbShorts[i] = TCombo.CreateCombo("cmb_Shorts" + i, GetText("Shorts"), x, y, w / 2, h, 1, 2, "FFFF99", "000000", 1.0, UpdateKitCmb, 1)
		g_editkits_inpShorts[i] = TInputBox.CreateInputBox("inp_Shorts" + i, x + 72, y, w / 2, h, 1, 2, "FFFFFF", "000000", 6, 1.0, UpdateKitInp, 0, "")
		y :+ h + 2
		g_editkits_cmbSocks[i] = TCombo.CreateCombo("cmb_Socks" + i, GetText("Socks") + " 1", x, y, w / 2, h, 1, 2, "FFFF99", "000000", 1.0, UpdateKitCmb, 1)
		g_editkits_inpSocks[i] = TInputBox.CreateInputBox("inp_Socks" + i, x + 72, y, w / 2, h, 1, 2, "FFFFFF", "000000", 6, 1.0, UpdateKitInp, 0, "")
		y :+ h + 2
		For Local j:Int = 0 To 16
			g_editkits_cmbShirt1[i].AddItem("", KitColour(j), "FFFFFF", 0)
			g_editkits_cmbShirt2[i].AddItem("", KitColour(j), "FFFFFF", 0)
			g_editkits_cmbShorts[i].AddItem("", KitColour(j), "FFFFFF", 0)
			g_editkits_cmbSocks[i].AddItem("", KitColour(j), "FFFFFF", 0)
		Next
		g_editkits_btnKit[i] = TButton.CreateButton("btn_Kit" + i, "", x + 10, y + 10, 128, 256, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
		g_editkits_screen.AddGadget(g_editkits_btnKit[i])
		g_editkits_screen.AddGadget(g_editkits_cmbKitType[i])
		g_editkits_screen.AddGadget(g_editkits_cmbShirt1[i])
		g_editkits_screen.AddGadget(g_editkits_cmbShirt2[i])
		g_editkits_screen.AddGadget(g_editkits_cmbShorts[i])
		g_editkits_screen.AddGadget(g_editkits_cmbSocks[i])
		g_editkits_screen.AddGadget(g_editkits_inpShirt1[i])
		g_editkits_screen.AddGadget(g_editkits_inpShirt2[i])
		g_editkits_screen.AddGadget(g_editkits_inpShorts[i])
		g_editkits_screen.AddGadget(g_editkits_inpSocks[i])
		x :+ 200
	Next
