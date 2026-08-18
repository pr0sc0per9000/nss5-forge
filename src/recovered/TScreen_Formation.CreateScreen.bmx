' TScreen_Formation.CreateScreen  -- KIND=Function (static, no implicit Self)
' VA 0x0054AFDD   2633 bytes   mode=reloc   byte-identical vs NSS5.exe
' (2633/2633, original length from Ghidra's inventory, reloc_masked=271; verified MATCH
'  under NSS5_NO_LEARN=1, so no call operand was masked by a name this body taught the table)
' KIND=Function, SIG ()i, class-table slot 0x30
'
' ASSUMPTIONS
'   Module Globals -- addresses are fact, NAMES are ours (module Globals have no debug
'   record).  Types are from the construction site IN THIS BODY unless noted:
'     0x00C677A0 g_formscreen:TScreen   0x00C677A4 g_formbtn:TButton   -- SAME addresses,
'        SAME names, as src/recovered/TScreen_Formation.SetUpScreen.bmx (that file's
'        header already resolved slot 0x90 = GetGadgetByName($) on g_formscreen and
'        slot 0x90 = SetIcon(:TImage) on g_formbtn; both are used again here).
'     0x00C677A8 g_formlist:TList   -- globals_typed.tsv: TList, structural-unique(6 sites).
'        Assigned from the alias-set callee 0x005B40BF (CreateList|CreateMap|
'        TGNetHost.Create); picked CreateList on the structural typing. Only ever written
'        here, never read in this body -- consumed elsewhere in the Type.
'     0x00C677AC g_imgArrow, 0x00C677B4 g_imgStar, 0x00C677B8 g_imgStar52 (the asset-guard
'        variable), 0x00C677BC g_imgStar52Grey, 0x00C677C0 g_imgPitch : TImage -- all
'        globals_final.tsv "Object, no call-site typing"; typed TImage here directly from
'        being LoadImageChecked's return value / MidHandleImage's and SetImageHandle's
'        argument. g_imgStar reappears as btn_position's icon; g_imgArrow/g_imgStar52/
'        g_imgStar52Grey/g_imgPitch are write-only in this body (read in Draw()).
'     0x00C677CC g_lblName, 0x00C677D0 g_lblValue : TLabel -- CreateLabel construction
'        sites; write-only here (never AddGadget-ed in this body -- floating labels
'        positioned dynamically elsewhere, e.g. RefreshButtons/ChangePosition).
'     0x00C6EFDC g_screenwidth:Int   0x00C6EFE0 g_screenheight:Int  (bare dword reads, no
'        refcount traffic; same pair as every other CreateScreen).
'     0x00C6F170 g_iconPath:String   0x00C6E950 g_path:String  -- SAME addresses and names
'        as src/recovered/TScreen_Stable.CreateScreen.bmx ("the button-icon path prefix" /
'        "the shared asset-path prefix"); globals_final.tsv mistypes 0x00C6F170 Int, it is
'        the left operand of _bbStringConcat here exactly as in Stable.
'     0x00C6F2EC g_img_helpicon:TImage -- SAME address/name as TScreen_GameMenu.CreateScreen
'        ("image of the help button"); passed into CreateButton's :TImage slot.
'     0x00C6F274 g_imgteam1:TImage -- SAME address as SetUpScreen's first SetIcon() argument
'        (that header: "0x00C6F274/0x00C6F194 -> TImage globals passed to SetIcon" for
'        Case 0 / Case 1). Used here as btn_play's and btn_ask's initial icon.
'     0x00C6F254 g_img_back:TImage -- the widely-shared "back/reject/cancel" icon (same
'        address named g_img_back in TScreen_GameMenu/Controls/Options.CreateScreen).
'        Used as btn_cancel's icon.
'     0x00C6F1B8 g_img_opponent:TImage -- "Object, no call-site typing"; typed TImage from
'        the CreateButton :TImage argument. This address is reused by several OTHER screens
'        for unrelated per-screen icons (g_img_iv / g_img_negcross elsewhere) -- it is a
'        shared scratch Global, not evidence the two screens show the same picture.
'
'   Class-table slots resolved through class_tables.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen  +0x38 CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C61CDC = TScreen  +0xB0 ButtonHelp ()i
'     0x00C623CC = TButton  +0x88 CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$)
'     0x00C63294 = TPanel   +0x88 CreatePanel  ($,$,i,i,i,i,$,$,i,f,i,i,i)
'     0x00C634C0 = TLabel   +0x88 CreateLabel  ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f)
'     0x00C638BC = THelpBox +0x30 Create (:TGadget,i,i,i,i,$,i,i)
'     slot 0x40 on a TScreen = TScreen.AddGadget (:TGadget)i
'     slot 0x90 on a TScreen = TScreen.GetGadgetByName ($):TGadget
'     slot 0x44 on a TList   = TList.AddLast (:Object)i   (via TScreen.lHelp, field +0x1C,
'        same field SetUpScreen's sibling TScreen_Home.CreateScreen calls .lHelp.AddLast on)
'     own class table (TScreen_Formation) -- passed as ()i callback arguments, so written
'     as BARE names, no `TScreen_Formation.` prefix (guide 3d): Draw (+0x40), ButtonFormation
'     (+0x38), ChangePosition (+0x48), CancelRequest (+0x4C), AskBoss (+0x50), ButtonPlay
'     (+0x58), ButtonViewOpponent (+0x5C) -- all already-recovered siblings.
'
'   Module Functions (already recovered, in src/recovered_module/): GetText 0x004C5549,
'   LoadImageChecked 0x004BC372.
'   BRL: 0x005AE38D MidHandleImage, 0x005AE336 SetImageHandle, 0x005B40BF CreateList
'   (alias set with CreateMap/TGNetHost.Create -- structural typing above picks CreateList).
'
'   String literals were all read out of the exe with harness.read_string -- the oracle
'   masks a literal's ADDRESS, so CONTENTS are not covered by the MATCH; verified separately.
'
' SHAPE NOTES (each cost a byte-observable decision, found by disassembling past what
' Ghidra's decompiler shows -- several of its printed argument lists MERGE two adjacent
' calls, and it FOLDS a two-instruction subtraction into one printed constant)
'   * The asset guard is `If Not g_imgStar52` -- the 21-byte setne/movzx/cmp/jne form of
'     guide 10.3 -- and it happens to guard on the SECOND asset the block assigns, not the
'     first; guard choice is a free source decision, not tied to assignment order.
'   * g_imgArrow's LoadImageChecked call has NO g_path prefix (a bare literal path); every
'     other asset in the guard block is `g_path + "..."` or `g_iconPath + "..."`.
'   * The formation-row x is `g_screenwidth - w - 10`, two separate `sub` instructions --
'     Ghidra's decompiler prints this as a single folded `+ -0xB4` constant, which would
'     byte-mismatch if written as a single literal subtraction.
'   * Local declaration order for the 11-row formation loop is y, w, h, x (matches the
'     `mov esi,.. / mov edi,.. / mov ebx,.. / mov eax,[width]; sub; sub; mov [ebp-4],eax`
'     sequence). y and h are each touched ~21 times (read + the `y :+ h + 10` step), w ~12
'     (11 CreateButton calls + once in x's init), x only 11 -- so per section 18.2 y/w/h keep
'     registers and x, the lowest and latest-declared, spills to `[ebp-4]`.
'   * `y :+ h + 10` runs between every pair of the 11 rows and NOT after the last row.
'   * The eight gadgets before the formation loop (btn_help, nav, btn_team, btn_play,
'     btn_position, btn_ask, btn_cancel, btn_opponent) hold their `g_formscreen` receiver
'     in a plain register across the nested CreateButton/GetText call with no spill --
'     ebx is still free there. Inside the formation loop ebx/esi/edi are claimed by h/y/w,
'     so the SAME `g_formscreen.AddGadget(TButton.CreateButton(...))` shape now spills the
'     receiver to a fresh stack slot per row ([ebp-0x30] down to [ebp-8], one new slot each
'     time, never reused) -- this is automatic register pressure, not a distinct source form.
'   * btn_position's and btn_opponent's captions are `GetText(...)`, evaluated as part of
'     CreateButton's right-to-left argument list; Ghidra's pseudocode shows the GetText call
'     with extra trailing arguments that actually belong to CreateButton -- resolved by
'     reading the `add esp,N` after each call instead of trusting the printed arg list.
'   * The closing statement's receiver `g_formscreen.lHelp` is evaluated ONCE into a
'     register held live across the nested GetGadgetByName/GetText/THelpBox.Create calls;
'     `g_formscreen` for GetGadgetByName's OWN receiver is a SEPARATE reload (bcc does no
'     CSE) even though both ultimately read the same Global two statements apart.
'!Global g_imgStar:TImage
'!Global g_imgStar52:TImage
'!Global g_imgStar52Grey:TImage
'!Global g_imgPitch:TImage
'!Global g_imgArrow:TImage
'!Global g_formlist:TList
'!Global g_formscreen:TScreen
'!Global g_formbtn:TButton
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_iconPath:String
'!Global g_path:String
'!Global g_img_helpicon:TImage
'!Global g_imgteam1:TImage
'!Global g_img_back:TImage
'!Global g_img_opponent:TImage
'!Global g_lblName:TLabel
'!Global g_lblValue:TLabel
	Function CreateScreen()
		If Not g_imgStar52
			g_imgStar = LoadImageChecked(g_iconPath + "Star.png", -1)
			g_imgStar52 = LoadImageChecked(g_path + "GameMedia/Images/Interface/Star52.png", -1)
			MidHandleImage(g_imgStar52)
			g_imgStar52Grey = LoadImageChecked(g_path + "GameMedia/Images/Interface/Star52Grey.png", -1)
			MidHandleImage(g_imgStar52Grey)
			g_imgPitch = LoadImageChecked(g_path + "GameMedia/Images/Interface/TacticsPitch.png", -1)
			g_imgArrow = LoadImageChecked("GameMedia/Images/Interface/Arrow.png", -1)
			SetImageHandle(g_imgArrow, 0, 9.0)
			g_formlist = CreateList()
		EndIf
		g_formscreen = TScreen.CreateScreen("formation", Null, Draw, Null)
		g_formscreen.AddGadget(TPanel.CreatePanel("pan_title", GetText("Formation"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1))
		g_formscreen.AddGadget(TButton.CreateButton("btn_help", "", g_screenwidth - 50, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_helpicon, TScreen.ButtonHelp, 1.0, 1, ""))
		g_formscreen.AddGadget(TPanel.CreatePanel("nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1))
		g_formscreen.AddGadget(TButton.CreateButton("btn_team", "", 10, 79, 600, 40, 0, 3, "FFFFFF", "FFFFFF", Null, Null, 1.0, 2, ""))
		g_formbtn = TButton.CreateButton("btn_play", "", 670, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_imgteam1, ButtonPlay, 1.0, 1, "")
		g_formscreen.AddGadget(g_formbtn)
		g_formscreen.AddGadget(TButton.CreateButton("btn_position", GetText("Change Position"), 10, g_screenheight - 50, 200, 40, 1, 3, "FFFFFF", "FFFFFF", g_imgStar, ChangePosition, 1.0, 1, ""))
		g_formscreen.AddGadget(TButton.CreateButton("btn_ask", "", 220, g_screenheight - 50, 60, 40, 1, 3, "FFFFFF", "FFFFFF", g_imgteam1, AskBoss, 1.0, 1, ""))
		g_formscreen.AddGadget(TButton.CreateButton("btn_cancel", "", 290, g_screenheight - 50, 60, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_back, CancelRequest, 1.0, 1, ""))
		g_formscreen.AddGadget(TButton.CreateButton("btn_opponent", GetText("View Opponent"), g_screenwidth - 340, g_screenheight - 50, 200, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_opponent, ButtonViewOpponent, 1.0, 1, ""))
		Local y:Int = 80
		Local w:Int = 170
		Local h:Int = 31
		Local x:Int = g_screenwidth - w - 10
		g_formscreen.AddGadget(TButton.CreateButton("3-4-3", "3-4-3", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("3-5-2 A", "3-5-2 A", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("3-5-2 B", "3-5-2 B", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("4-2-2-2", "4-2-2-2", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("4-2-4", "4-2-4", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("4-3-3", "4-3-3", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("4-4-1-1", "4-4-1-1", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("4-4-2 A", "4-4-2 A", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("4-4-2 B", "4-4-2 B", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("4-5-1", "4-5-1", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		y :+ h + 10
		g_formscreen.AddGadget(TButton.CreateButton("5-3-2", "5-3-2", x, y, w, h, 1, 3, "FFFFFF", "FFFFFF", Null, ButtonFormation, 1.0, 1, ""))
		g_lblName = TLabel.CreateLabel("lbl_Name", "", 0, 0, 80, 14, 1, "FFFFFF", "FFFFFF", 0.5, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0)
		g_lblValue = TLabel.CreateLabel("lbl_Value", "", 0, 0, 80, 14, 1, "FFFFFF", "FFFFFF", 0.5, 3, 0, 0, 1, Null, 1, 0, 0, 0, "", 0)
		g_formscreen.lHelp.AddLast(THelpBox.Create(g_formscreen.GetGadgetByName("3-4-3"), 0, 0, 0, 0, GetText("CHELP_FORMATIONBUTTONS"), 1, 2))
	End Function
