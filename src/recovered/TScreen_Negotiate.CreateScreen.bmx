' GLOBAL RENAMED (2026-08-15): g_mediapath -> g_iconpath in THIS file only.
' 0x00C6F170 is the GameMedia/Images/Icons/ root. The corpus uses the identifier
' g_mediapath for TWO different slots -- 0x00C6F170 here and in 8 other files, and
' 0x00C6E950 (the install root) in 9 OTHERS. One name, two slots, an exact 9/9 split,
' so no single value assigned to g_mediapath could ever be right at every call site:
' whichever way it went, half the asset paths resolved wrong and ~100 images failed to
' load. Per-body verification cannot catch this -- a Global reaches the compiled code
' only as an absolute address and the byte oracle masks those, so both spellings
' verify byte-perfectly. Renaming is byte-neutral; scripts/reverify.py confirms it.
' See scripts/unify_globals.py for the rest of this defect class.
' TScreen_Negotiate.CreateScreen
' VA 0x00579DA6   1745 bytes   KIND=Function (static, no Self)   SIG ()i   class-table slot 0x30
' byte-identical vs NSS5.exe (1745/1745, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=168)
'
' Gadget-construction body for the "Higher or Lower" contract-negotiation minigame (a
' casino-style guessing game embedded in TScreen_Negotiate; SetUpScreen.bmx re-seeds it each
' time a negotiation starts). Reconstructed directly from the disassembly, not the Ghidra
' decompilation, which merges each call's own arguments with the pushes of the FOLLOWING
' call (codegen-patterns.md preamble / section on CALL annotations) -- every CreatePanel /
' CreateButton / CreateLabel / GetText argument list below was recovered by walking the
' push/call/add-esp sequence by hand and cross-checked against each call's known arg count
' from extracted/decomp_annotated's CALL comment block.
'
' STATEMENT-ORDER FINDING (the only thing localise_diff.py needed to fix after the first
' draft, all 9 gaps summing to -4 bytes, COMPLETE): every `y :+ N` increment in the original
' is interleaved BETWEEN the CreatePanel/CreateButton/CreateLabel call that assigns a Global
' and the FOLLOWING AddGadget/AddChild call that uses it -- never after both. E.g.
' `g_neg_panhl = TPanel.CreatePanel(...) / y :+ 50 / g_neg_screen.AddGadget(g_neg_panhl)`,
' not increment-then-nothing or increment-after-AddGadget. Five of the nine gaps were this
' exact shape recurring at each of the five y-advances in the function; a naive "increment
' after finishing this UI element" reading (increment placed after the AddChild/AddGadget)
' cost 4 bytes at every site because bcc emits statements in literal source order (guide
' section 3e) and the original literally interleaves the increment mid-statement-group.
' A tenth (well, the last, un-gapped) difference was a same-length wrong-slot SUB: the
' `y :+ (button size) + 10` after the 5-button loop reads original [ebp-0xc], i.e. the `h`
' Local, not `w` -- both equal 94 here so the VALUE is identical, only the SLOT read differs;
' `w` gives byte-identical VALUES but a different, wrong, register/stack fingerprint.
' The x-position formula inside the 5-button loop (`i*w + 145 + i*10`) is its own Local,
' recomputed at the TOP of every iteration (its own six-instruction block precedes every
' push for that iteration's CreateButton call) -- inlining it into the CreateButton call's
' argument list evaluates it at argument-push time instead and lands 18 bytes too late/early
' per iteration (bcc has no CSE and evaluates arguments in push order, guide section 6).
'
' ASSUMPTIONS
'  The `If Not g_icon` guard is the object->Int cast form (`cmp eax,Null / setne al / movzx
'  eax,al / cmp eax,0 / jne skip`), matching src/recovered/TBall.New.bmx's documented shape
'  for `If Not <scalar object>` -- NOT the direct `cmp/jne` shape that `If x <> Null Then`
'  (no cast) uses, confirmed against src/recovered/TButton.CreateButton.bmx's icon guard.
'
'  Module Globals -- NAMES ARE OURS except where a sibling TScreen_Negotiate file already
'  established one (kept for corpus consistency; the SAME physical button/panel is reused
'  and relabelled across the minigame's phases, so a different file may call it something
'  else -- both names are noted below). Declared TYPES are load-bearing (they select the
'  vtable slot for every call made through them):
'    0x00C6CBF0 TScreen   g_neg_screen      (construction site, this function)
'    0x00C6CC20 TImage    g_icon            (question-mark/"Help.png" icon; ALSO the cache
'                          flag for the one-time image-load block; = SetUpScreen.bmx's g_icon)
'    0x00C6CC24 TImage    g_neg_imgup       ("ArrowU.png", btn_higher's icon)
'    0x00C6CC28 TImage    g_neg_imgdown     ("ArrowD_Red.png", btn_lower's icon)
'    0x00C6F170 String    g_iconpath       (asset-path prefix; globals_final.tsv types this
'                          Int and is wrong -- established String across dozens of recovered
'                          CreateScreen bodies, e.g. TScreen_Achievements.CreateScreen.bmx)
'    0x00C6E950 String    g_datapath        (install/data-path prefix, "g_datapath" is the
'                          majority name across the corpus, e.g. TEngine.SetUp.bmx)
'    0x00C6CC1C TImage[]  g_icons           (11 number-card icons, index 1..11; = SetUpScreen
'                          .bmx's g_icons, which indexes it by the same random g_nums values)
'    0x00C66768 TPanel    g_pan_stable      (shared stable-info panel; same address/type as
'                          TScreen_Casino.CreateScreen.bmx's g_pan_stable)
'    0x00C6CBF4 TPanel    g_neg_panhl       ("pan_HigherLower" -- title bar + the 5 number
'                          buttons + Lower/Higher buttons)
'    0x00C6CBF8 TPanel    g_neg_panhl2      ("pan_HigherLower2" -- percent label,
'                          instructions label, Accept button)
'    0x00C6CC38 TButton[] g_btns            (5 number-choice buttons, index 1..5; =
'                          SetUpScreen.bmx's g_btns)
'    0x00C6CBFC TButton   g_neg_btnlower    ("btn_lower"/"Lower"; = SetUpScreen.bmx's
'                          g_btnAccept -- same physical button relabelled "Accept" once the
'                          guessing phase ends)
'    0x00C6CC00 TButton   g_neg_btnhigher   ("btn_higher"/"Higher"; = SetUpScreen.bmx's
'                          g_btnReject, relabelled similarly)
'    0x00C6CC08 TLabel    g_neg_lblpercent  ("lbl_Percent", starts "0%")
'    0x00C6CC04 TLabel    g_neg_lblinstrucs ("lbl_Instrucs", starts "")
'    0x00C6CC0C TButton   g_neg_btnaccept   ("btn_Accept"; = SetUpScreen.bmx's g_btnMore)
'    0x00C6CC10 TButton   g_neg_btnok       ("btn_ok"/tooltip "tt_Proceed"; = SetUpScreen
'                          .bmx's g_btnWait, and TScreen_Negotiate.Fail.bmx's g_neg_okbutton)
'    0x00C6F274 TImage    g_img_play        (btn_Accept's icon; the corpus-wide "accept/play"
'                          checkmark icon, e.g. TScreen.DoMessage.bmx, TScreen_Casino uses a
'                          different address for its own play icon)
'    0x00C6F1B8 TImage    g_img_negcross    (btn_ok's icon at creation; = TScreen_Negotiate
'                          .Fail.bmx's g_img_negcross, SetIcon'd there too on failure)
'    0x00C6EFDC Int       g_screenwidth     0x00C6EFE0 Int g_screenheight
'
'  Class-table slots resolved (extracted/decomp_annotated's SYM block):
'    [0x00C61C64] TScreen+0x38          = CreateScreen($,:TImage,()i,()i):TScreen
'    [0x00C623CC] TButton+0x88          = CreateButton($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'    [0x00C63294] TPanel+0x88           = CreatePanel($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'    [0x00C634C0] TLabel+0x88           = CreateLabel($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'    [0x00C6CDB0] TScreen_Negotiate+0x38 = ButtonLower()i   (passed as a bare function-pointer
'    [0x00C6CDB4] TScreen_Negotiate+0x3C = ButtonHigher()i   value, read straight out of the
'    [0x00C6CDB8] TScreen_Negotiate+0x40 = Update()i         class-table slot memory, not called)
'    [0x00C6CDC8] TScreen_Negotiate+0x50 = ButtonOk()i
'    [0x00C6CDCC] TScreen_Negotiate+0x54 = ButtonAccept()i
'    TScreen+0x40 = AddGadget(:TGadget)  (inherited by nothing here -- called directly on
'                    g_neg_screen); TGadget+0x74 = AddChild(:TGadget) (inherited by TPanel)
'  TScreen.CreateScreen's Null callback argument (arg3, unused here) compiles to the
'  null-function trampoline 0x005B95D0, NOT the object-null 0x005C9C80 used for the TImage
'  bg argument (arg2) -- both forms confirmed by direct bytes, matching
'  TScreen_Casino.CreateScreen.bmx's documented finding for the same construction pattern.
'  0x004A7AC0 _bbStringFromInt = `String(i)`; 0x004A7C20 _bbStringConcat = `+`;
'  0x004BC372 = LoadImageChecked; 0x004C5549 = GetText (module Function, single-argument
'  form only, used here).
'
'  All 22 non-empty string literals were read directly out of NSS5.exe with
'  harness.read_string() and checked against the address the ORIGINAL pushes at each site
'  (a MATCH masks literal ADDRESSES, never certifies TEXT -- codegen-patterns.md 13.2):
'  "negotiate", "highlow_Instrucs", "pan_HigherLower", "Lower", "btn_lower", "Higher",
'  "btn_higher", "pan_HigherLower2", "0%", "lbl_Percent", "888888", "lbl_Instrucs",
'  "btn_Accept", "tt_Proceed", "btn_ok", "navpanel", "Help.png", "ArrowU.png",
'  "ArrowD_Red.png", "GameMedia/Images/Casino/HigherLower/Player", ".png", "btn_", "FFFFFF".
'  The two remaining literal operands (0x005C7D40, 0x00C5D284) are zero-length BBStrings,
'  i.e. plain `""`.
	Function CreateScreen:Int()
		'!Global g_neg_screen:TScreen
		'!Global g_icon:TImage
		'!Global g_neg_imgup:TImage
		'!Global g_neg_imgdown:TImage
		'!Global g_iconpath:String
		'!Global g_datapath:String
		'!Global g_icons:TImage[]
		'!Global g_pan_stable:TPanel
		'!Global g_neg_panhl:TPanel
		'!Global g_neg_panhl2:TPanel
		'!Global g_btns:TButton[]
		'!Global g_neg_btnlower:TButton
		'!Global g_neg_btnhigher:TButton
		'!Global g_neg_lblpercent:TLabel
		'!Global g_neg_lblinstrucs:TLabel
		'!Global g_neg_btnaccept:TButton
		'!Global g_neg_btnok:TButton
		'!Global g_img_play:TImage
		'!Global g_img_negcross:TImage
		'!Global g_screenwidth:Int
		'!Global g_screenheight:Int

		g_neg_screen = TScreen.CreateScreen("negotiate", Null, Null, TScreen_Negotiate.Update)

		If Not g_icon
			g_icon = LoadImageChecked(g_iconpath + "Help.png", -1)
			g_neg_imgup = LoadImageChecked(g_iconpath + "ArrowU.png", -1)
			g_neg_imgdown = LoadImageChecked(g_iconpath + "ArrowD_Red.png", -1)
			For Local i:Int = 1 To 11
				g_icons[i] = LoadImageChecked(g_datapath + "GameMedia/Images/Casino/HigherLower/Player" + String(i) + ".png", -1)
			Next
		EndIf

		g_neg_screen.AddGadget(g_pan_stable)

		Local y:Int = 70
		Local w:Int = 94
		Local h:Int = 94
		Local n:Int = 1

		g_neg_panhl = TPanel.CreatePanel("pan_HigherLower", GetText("highlow_Instrucs"), 135, y, 530, 40, "FFFFFF", "FFFFFF", 3, 0.8, 1, 190, 0)
		y :+ 50
		g_neg_screen.AddGadget(g_neg_panhl)

		For Local i:Int = 0 To 4
			Local x:Int = i * w + 145 + i * 10
			g_btns[n] = TButton.CreateButton("btn_" + String(n), "", x, y, w, h, 0, 2, "FFFFFF", "FFFFFF", g_icon, Null, 1.0, 1, "")
			g_neg_screen.AddGadget(g_btns[n])
			n :+ 1
		Next

		y :+ h + 10
		g_neg_btnlower = TButton.CreateButton("btn_lower", GetText("Lower"), 145, y, 250, 66, 1, 4, "FFFFFF", "FFFFFF", g_neg_imgdown, TScreen_Negotiate.ButtonLower, 1.0, 1, "")
		g_neg_btnhigher = TButton.CreateButton("btn_higher", GetText("Higher"), 405, y, 250, 66, 1, 4, "FFFFFF", "FFFFFF", g_neg_imgup, TScreen_Negotiate.ButtonHigher, 1.0, 1, "")
		y :+ 85
		g_neg_panhl.AddChild(g_neg_btnlower)
		g_neg_panhl.AddChild(g_neg_btnhigher)

		g_neg_panhl2 = TPanel.CreatePanel("pan_HigherLower2", "", 135, y, 530, 220, "FFFFFF", "FFFFFF", 3, 0.8, 1, 0, 0)
		y :+ 10
		g_neg_screen.AddGadget(g_neg_panhl2)

		g_neg_lblpercent = TLabel.CreateLabel("lbl_Percent", "0%", 145, y, 120, 120, 4, "888888", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0.0)
		g_neg_panhl2.AddChild(g_neg_lblpercent)

		g_neg_lblinstrucs = TLabel.CreateLabel("lbl_Instrucs", "", 275, y, 380, 120, 3, "FFFFFF", "FFFFFF", 1.0, 1, 0, 1, 1, Null, 1, 0, 0, 0, "", 0.0)
		y :+ 130
		g_neg_panhl2.AddChild(g_neg_lblinstrucs)

		g_neg_btnaccept = TButton.CreateButton("btn_Accept", "", 145, y, 510, 70, 1, 3, "FFFFFF", "FFFFFF", g_img_play, TScreen_Negotiate.ButtonAccept, 1.0, 1, "")
		g_neg_panhl2.AddChild(g_neg_btnaccept)

		g_neg_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))

		g_neg_btnok = TButton.CreateButton("btn_ok", "", 670, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_negcross, TScreen_Negotiate.ButtonOk, 1.0, 1, GetText("tt_Proceed"))
		g_neg_screen.AddGadget(g_neg_btnok)
	End Function
