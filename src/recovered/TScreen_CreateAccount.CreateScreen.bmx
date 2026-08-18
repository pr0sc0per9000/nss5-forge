' TScreen_CreateAccount.CreateScreen
' VA 0x00524EB7   2013 bytes   mode=reloc   byte-identical vs NSS5.exe
' (2013/2013, original length from Ghidra's inventory, reloc_masked=183; verified with
'  NSS5_NO_LEARN=1, status=MATCH, mode="reloc" -- no call operand was masked by a name
'  this body taught the table)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' ASSUMPTIONS
'   Module Globals -- addresses are fact, NAMES are ours (module Globals carry no debug
'   record). Construction sites establish the types:
'     0x00C64434 g_screen:TScreen           (from TScreen.CreateScreen; dispatched through
'                                            slot 0x40 = TScreen.AddGadget throughout)
'     0x00C64438 g_panDetails:TPanel        (from TPanel.CreatePanel; every label/inputbox
'                                            is added to it via slot 0x74 = TGadget.AddChild,
'                                            and its own x/h fields are read for SetPosition)
'     0x00C6443C g_inpName:TInputBox        (from TInputBox.CreateInputBox; ALREADY NAMED
'                 g_inpName in src/recovered/TScreen_CreateAccount.SetUpScreen.bmx, which
'                 reads g_profile.name into it via TGadget.SetText -- same address, same
'                 name, kept consistent across both files)
'     0x00C64440 g_inpEmail:TInputBox       0x00C64444 g_inpPassword1:TInputBox
'     0x00C64448 g_inpPassword2:TInputBox   0x00C6444C g_inpKey:TInputBox
'     0x00C6EFDC g_screenwidth:Int   0x00C6EFE0 g_screenheight:Int  (bare dword reads with
'                 no refcount traffic -> Int; same pair as every other CreateScreen)
'     0x00C6F194 g_img_quit:TImage   0x00C6F274 g_img_proceed:TImage
'                 (SAME two addresses as src/recovered/TScreen_NewPlayer.CreateScreen.bmx,
'                  which already established their names and TImage typing there -- reused
'                  verbatim for consistency; this body pushes them into CreateButton's
'                  declared `:TImage` parameter, which is direct evidence of the type)
'   The seven label constructs (lbl_instrucs, lbl_name, lbl_email, lbl_password1,
'   lbl_password2, lbl_instrucskey, lbl_key) and the pan_title/pan_nav panels are never
'   stored to a Global: the disassembly shows retain-only with no prior release-old, i.e.
'   no assignment target, matching the "temporary passed straight to AddChild/AddGadget"
'   shape already documented in TScreen_NewPlayer.CreateScreen.bmx. The panel g_panDetails
'   and the five TInputBox gadgets DO show retain + release-old(Global) + store-new, i.e.
'   a genuine `Global = Expr` assignment statement, because their Globals are read again
'   later in the function (or, for g_inpName, in a sibling file).
'
'   Class-table slots (each pointer verified to be classtable_va + slot exactly):
'     0x00C61C64 = TScreen    +0x38  CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C623CC = TButton    +0x88  CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$)
'     0x00C625E0 = TInputBox  +0x88  CreateInputBox ($,i,i,i,i,i,i,$,$,i,f,()i,i,$):TInputBox
'     0x00C63294 = TPanel     +0x88  CreatePanel ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C634C0 = TLabel     +0x88  CreateLabel ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f)
'     0x00C63CA0 = TScreen_MainMenu +0x34  SetUpScreen ()i  (the "Back" button's onClick --
'                 this screen has no ButtonQuit of its own; Back goes straight to Main Menu)
'     0x00C644FC = TScreen_CreateAccount +0x38  ButtonPlay ()i  (own Type, bare name)
'     slot 0x40 on a TScreen  = TScreen.AddGadget (:TGadget)i
'     slot 0x74 on a TGadget  = TGadget.AddChild  (:TGadget)i  (TPanel inherits it -- there
'                 is no AddChild override in TPanel's own vtable rows)
'     slot 0x84 on a TGadget  = TGadget.SetPosition (i,i,i)i
'     TGadget field offsets used: +0x20 x:Float, +0x28 h:Float (object_model.json)
'   E8 targets: 0x004C5549 GetText (src/recovered_module/GetText.bmx), 0x004A8590 the GC
'     free of the inlined BBRELEASE (never written in source), 0x005B9690 _bbFloatToInt
'     (emitted for every Float->Int argument coercion, never written in source),
'     0x005B95D0 the null-function-pointer stub (emitted for a literal `Null` passed to a
'     ()i-typed parameter, never written in source -- see codegen-patterns.md 3a).
'
' SHAPE NOTES (byte-observable, read off the disassembly -- the decompiled C hides all of
' this by constant-propagating the Locals, which is why raw disassembly was required; see
' codegen-patterns.md 16.3)
'   * `sub esp,0x10` = FOUR stack slots. Three Locals spill to them (x, w, lw); the fourth
'     slot is a one-off compiler temporary for the SetPosition height calc (an Int must be
'     stored to memory before `fild` can load it as a float -- not a declared source Local).
'   * y and h keep registers (ebx, edi); x, w, lw spill to the stack. Matches
'     codegen-patterns.md 18.2: the two highest-reference-count Locals win a register (y is
'     read by every construct's y-argument AND by all six advances; h is read by every
'     construct's h-argument AND multiplied/added in five of the six advances).
'   * h is a genuine `Local h:Int = 30`, read RAW in most calls but as `h * 4` for the one
'     multi-line label (lbl_instrucs). pan_details's own height argument is the LITERAL 30
'     (`push 0x1e` as an immediate), not a read of `h` -- numerically identical, textually a
'     different thing, confirmed because the push happens as an immediate operand rather
'     than a register read.
'   * lw ("label width", 180) is a second, never-modified width Local distinct from w (the
'     wide 500/520 content width): every single-line field label uses `lw` for its width and
'     every InputBox derives both its x (`x + lw + 10`) and its w (`w - lw - 10`) from it.
'   * The six "advance the cursor" statements are NOT a uniform `y :+ 40`: they read
'     `y :+ h*4+10` once (after the multi-line instructions label), `y :+ h+10` four times,
'     and `y :+ h+20` once (the extra 10 sits after Password2, before the instructions-key
'     label) -- reproduce each exactly, do not normalise them to a single constant.
'   * CRITICAL ORDERING: for every construct that IS assigned to a Global (pan_details and
'     all five InputBoxes), the disassembly places the NEXT row's cursor-advance BETWEEN the
'     assignment and that same construct's own AddGadget/AddChild call -- i.e.
'     `g_x = Create(...)` / `y :+ ...` / `AddChild(g_x)`, not
'     `g_x = Create(...)` / `AddChild(g_x)` / `y :+ ...`. Getting this backwards produced
'     ten small length-changing gaps (five swapped +7/-7 or +11/-11 pairs, net delta 0) that
'     `localise_diff.py` traced to exactly this reordering -- confirmed on all five sites,
'     zero `subs` once fixed. For the INLINE constructs (every label), there is no separate
'     assignment, so the advance naturally falls after that label's own AddChild call, which
'     is where it already read correctly on the first pass.
'   * String literals were read out of NSS5.exe with harness.read_string for every literal
'     in this body; the oracle masks a literal's ADDRESS, not its content, so this body's
'     text was independently confirmed, not merely left as a MATCH-blessed placeholder.
'!Global g_screen:TScreen
'!Global g_panDetails:TPanel
'!Global g_inpName:TInputBox
'!Global g_inpEmail:TInputBox
'!Global g_inpPassword1:TInputBox
'!Global g_inpPassword2:TInputBox
'!Global g_inpKey:TInputBox
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_img_quit:TImage
'!Global g_img_proceed:TImage
	Function CreateScreen:Int()
		g_screen = TScreen.CreateScreen("createaccount", Null, Null, Null)
		g_screen.AddGadget(TPanel.CreatePanel("pan_title", GetText("Create Account"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1))
		Local x:Int = 140
		Local y:Int = 90
		Local w:Int = 520
		Local h:Int = 30
		Local lw:Int = 180
		g_panDetails = TPanel.CreatePanel("pan_details", GetText("Your Details"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 390, 0)
		x :+ 10
		y :+ 40
		w :- 20
		g_screen.AddGadget(g_panDetails)
		g_panDetails.AddChild(TLabel.CreateLabel("lbl_instrucs", GetText("account_Instrucs"), x, y, w, h * 4, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h * 4 + 10
		g_panDetails.AddChild(TLabel.CreateLabel("lbl_name", GetText("Player Name"), x, y, lw, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_inpName = TInputBox.CreateInputBox("inp_Name", x + lw + 10, y, w - lw - 10, h, 0, 2, "888888", "FFFFFF", 0, 1.0, Null, 0, "")
		y :+ h + 10
		g_panDetails.AddChild(g_inpName)
		g_panDetails.AddChild(TLabel.CreateLabel("lbl_email", GetText("Email"), x, y, lw, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_inpEmail = TInputBox.CreateInputBox("inp_Email", x + lw + 10, y, w - lw - 10, h, 1, 2, "FFFFFF", "000000", 32, 1.0, Null, 0, "")
		y :+ h + 10
		g_panDetails.AddChild(g_inpEmail)
		g_panDetails.AddChild(TLabel.CreateLabel("lbl_password1", GetText("Password"), x, y, lw, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_inpPassword1 = TInputBox.CreateInputBox("inp_Password1", x + lw + 10, y, w - lw - 10, h, 1, 2, "FFFFFF", "000000", 32, 1.0, Null, 1, "")
		y :+ h + 10
		g_panDetails.AddChild(g_inpPassword1)
		g_panDetails.AddChild(TLabel.CreateLabel("lbl_password2", GetText("Re-type Password"), x, y, lw, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_inpPassword2 = TInputBox.CreateInputBox("inp_Password2", x + lw + 10, y, w - lw - 10, h, 1, 2, "FFFFFF", "000000", 32, 1.0, Null, 1, "")
		y :+ h + 20
		g_panDetails.AddChild(g_inpPassword2)
		g_panDetails.AddChild(TLabel.CreateLabel("lbl_instrucskey", GetText("instrucs_Key"), x, y, w, h, 2, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		y :+ h + 10
		g_panDetails.AddChild(TLabel.CreateLabel("lbl_key", GetText("Activation Key"), x, y, lw, h, 3, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0))
		g_inpKey = TInputBox.CreateInputBox("inp_Key", x + lw + 10, y, w - lw - 10, h, 1, 2, "FFFFFF", "000000", 32, 1.0, Null, 0, "")
		g_panDetails.AddChild(g_inpKey)
		g_panDetails.SetPosition(g_panDetails.x, (g_screenheight / 2) - (g_panDetails.h + 390) / 2, 1)
		g_screen.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
		g_screen.AddGadget(TButton.CreateButton("btn_quit", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_quit, TScreen_MainMenu.SetUpScreen, 1.0, 1, GetText("tt_Back")))
		g_screen.AddGadget(TButton.CreateButton("btn_play", "", 670, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_proceed, ButtonPlay, 1.0, 1, GetText("tt_CreateAccount")))
		Return 0
	End Function
