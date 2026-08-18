' TScreen_NewPlayer.CreateScreen
' VA 0x0052397C   2981 bytes   mode=reloc   byte-identical vs NSS5.exe
' (2981/2981, original length from Ghidra's inventory, reloc_masked=288; verified with
'  NSS5_NO_LEARN=1 on the first and only build, so no call operand was masked by a name
'  this body taught the table)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' NEGATIVE CONTROLS (all three under NSS5_NO_LEARN=1, all MISMATCH at the expected offset)
'   ComboPosition        -> ComboSide            MISMATCH 2110/2981, first_diff 917
'   TKit.GetHexHairCol(6)-> TKit.GetHexSkinColour(6)  MISMATCH 2110/2981, first_diff 2360
'   ButtonQuit           -> ButtonPlay           MISMATCH 2110/2981, first_diff 2799
'   so the class-table slot operands are genuinely resolved on both sides, not masked blind.
'
' ASSUMPTIONS
'   Module Globals -- addresses are fact, NAMES are ours (module Globals have no debug
'   record).  Types below are from the construction site IN THIS BODY unless noted:
'     0x00C64214 g_np_screen:TScreen        (assigned from TScreen.CreateScreen; called
'                                            through slot 0x40 = TScreen.AddGadget 22x)
'     0x00C6421C g_np_inpname:TInputBox     (assigned from TInputBox.CreateInputBox.
'                 globals_final.tsv says TPanel and flags "CONFLICT: TPanel=1;TInputBox=1"
'                 -- this store is the TInputBox site.  Not byte-load-bearing here: the
'                 Global is only ever passed as an argument, never dispatched through.)
'     0x00C64220 g_np_cmbnation:TCombo      0x00C64228 g_np_cmbclubnation:TCombo
'     0x00C64234 g_np_cmbposition:TCombo    0x00C64238 g_np_cmbside:TCombo
'     0x00C6423C g_np_cmbskin:TCombo        0x00C64240 g_np_cmbhair:TCombo
'                 (all six assigned from TCombo.CreateCombo, then dispatched through
'                  slot 0x90 = TCombo.AddItem($,$,$,i))
'     0x00C64224 g_np_btnflag:TButton       0x00C64244 g_np_btnkit:TButton
'     0x00C6EFDC g_screenwidth:Int   0x00C6EFE0 g_screenheight:Int  (bare dword reads with
'                 no refcount traffic -> Int; same pair as every other CreateScreen)
'     0x00C6F194 g_img_quit:TImage    0x00C6F274 g_img_proceed:TImage
'                 (0x00C6F274 is hand-verified TImage in globals_corrections.tsv.
'                  0x00C6F194 is "Object, no call-site typing" in globals_final.tsv; it is
'                  pushed into CreateButton's declared `:TImage` parameter here, which is
'                  direct evidence -- bcc would reject any other object type uncast.)
'
'   CORRECTION to src/recovered/TScreen_NewPlayer.SetUpScreen.bmx's header (that body's
'   BYTES are unaffected -- Global names have no codegen effect -- but its comment maps two
'   addresses to the wrong gadgets):
'     0x00C64234 is cmb_Position, NOT "g_np_comboskin"   (SetUpScreen's SelectItemById(5)
'                                                         picks pos_Forward, id 5)
'     0x00C64238 is cmb_Side,     NOT "g_np_combohair"   (SelectItemById(2) = side_Centre)
'     0x00C6423C is cmb_Skin  ("g_np_comboskincol" there) 0x00C64240 is cmb_Hair.
'   The create sites in this function are the authority; the ids line up exactly.
'
'   Class-table slots (each pointer verified to be classtable_va + slot exactly):
'     0x00C61C64 = TScreen  +0x38  CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C63294 = TPanel   +0x88  CreatePanel ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C625E0 = TInputBox+0x88  CreateInputBox ($,i,i,i,i,i,i,$,$,i,f,()i,i,$):TInputBox
'     0x00C630E0 = TCombo   +0x88  CreateCombo ($,$,i,i,i,i,i,i,$,$,f,()i,i):TCombo
'     0x00C623CC = TButton  +0x88  CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$)
'     0x00C5C4C8 = TKit     +0x48  GetHexHairCol (i)$
'     0x00C5C4CC = TKit     +0x4C  GetHexSkinColour (i)$
'     slot 0x40 on a TScreen = TScreen.AddGadget (:TGadget)i
'     slot 0x90 on a TCombo  = TCombo.AddItem ($,$,$,i)
'     own class table (TScreen_NewPlayer, base 0x00C643D0) -- passed as ()i arguments, so
'     written as BARE names with no Type. prefix:
'       +0x38 0x00C64408 ComboNation      +0x3C 0x00C6440C ComboClubNation
'       +0x44 0x00C64414 ComboPosition    +0x48 0x00C64418 ComboSide
'       +0x4C 0x00C6441C ComboSkin        +0x50 0x00C64420 ComboHair
'       +0x58 0x00C64428 ButtonPlay       +0x60 0x00C64430 ButtonQuit
'   E8 targets: 0x004C5549 GetText (src/recovered_module/GetText.bmx), 0x004A8590 the GC
'     free of the inlined BBRELEASE (never written in source).
'
' SHAPE NOTES (byte-observable, read off the disassembly)
'   * `sub esp,8` = TWO stack slots.  There are exactly four Int Locals and bcc places them
'     x -> [ebp-4], y -> ebx, w -> edi, h -> [ebp-8], in that declaration order.
'   * y is stepped by `add ebx,0x28` (`y :+ 40`) in six places and RE-ASSIGNED outright
'     (`mov ebx,imm`) at 170 / 260 / 430 -- the original does not accumulate across
'     sections, it sets y absolutely.  Both forms occur and they are not interchangeable.
'   * w, x, y are re-assigned for the right-hand column in the order w, x, y (h is not).
'   * `w / 2` is the signed-divide idiom cdq/and edx,1/add/sar and appears SIX times,
'     including twice inside one CreateCombo call (`x + w / 2` and `w / 2`) -- bcc does no
'     CSE, so the source must compute it twice too.
'   * The two empty-string constants 0x00C5D284 and 0x005C7D40 are both zero-length
'     BBStrings; bcc picks one or the other by argument slot and the source is "" for both.
'   * The AddItem colour argument evaluates TKit.GetHex*(n) between the pushes of args 4
'     and 3, which is just bcc's right-to-left argument evaluation, not a Local.
'   * The seven hair entries are added in id order 1,2,6,4,7,3,5 -- reproduce the original's
'     ordering, do not tidy it (16.8).
'   * String literals were read out of NSS5.exe with harness.read_string; the oracle masks a
'     literal's ADDRESS, so their CONTENTS are not certified by the MATCH.
'!Global g_np_screen:TScreen
'!Global g_np_inpname:TInputBox
'!Global g_np_cmbnation:TCombo
'!Global g_np_btnflag:TButton
'!Global g_np_cmbclubnation:TCombo
'!Global g_np_cmbposition:TCombo
'!Global g_np_cmbside:TCombo
'!Global g_np_cmbskin:TCombo
'!Global g_np_cmbhair:TCombo
'!Global g_np_btnkit:TButton
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_img_quit:TImage
'!Global g_img_proceed:TImage
g_np_screen = TScreen.CreateScreen("newplayer", Null, Null, Null)
g_np_screen.AddGadget(TPanel.CreatePanel("pan_title", GetText("New Player"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1))
Local x:Int = 140
Local y:Int = 80
Local w:Int = 220
Local h:Int = 30
g_np_screen.AddGadget(TPanel.CreatePanel("pan_name", GetText("Player Name"), x - 10, y, w + 20, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 50, 0))
y :+ 40
g_np_inpname = TInputBox.CreateInputBox("inp_Name", x, y, w, h, 1, 2, "FFFFFF", "000000", 29, 1.0, Null, 0, "")
y = 170
g_np_screen.AddGadget(TPanel.CreatePanel("pan_nation", GetText("Nationality"), x - 10, y, w + 20, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 50, 0))
y :+ 40
g_np_cmbnation = TCombo.CreateCombo("cmb_Nation", GetText("Nation"), x, y, w - 50, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboNation, 1)
g_np_btnflag = TButton.CreateButton("flag", "", x + w - 20, y + 16, 42, 30, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
y = 260
g_np_screen.AddGadget(TPanel.CreatePanel("pan_club", GetText("League"), x - 10, y, w + 20, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 130, 0))
y :+ 40
g_np_cmbclubnation = TCombo.CreateCombo("cmb_ClubNation", GetText("Nation"), x, y, w, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboClubNation, 1)
y = 430
g_np_screen.AddGadget(TPanel.CreatePanel("pan_position", GetText("Position"), x - 10, y, w + 20, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 50, 0))
y :+ 40
g_np_cmbposition = TCombo.CreateCombo("cmb_Position", GetText("Position"), x + 95, y, 125, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboPosition, 1)
g_np_cmbposition.AddItem(GetText("pos_Defender"), "BBBBBB", "FFFFFF", 1)
g_np_cmbposition.AddItem(GetText("pos_Midfielder"), "BBBBBB", "FFFFFF", 3)
g_np_cmbposition.AddItem(GetText("pos_Forward"), "BBBBBB", "FFFFFF", 5)
g_np_cmbside = TCombo.CreateCombo("cmb_Side", GetText("Side"), x, y, 85, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboSide, 1)
g_np_cmbside.AddItem(GetText("side_Left"), "BBBBBB", "FFFFFF", 1)
g_np_cmbside.AddItem(GetText("side_Centre"), "BBBBBB", "FFFFFF", 2)
g_np_cmbside.AddItem(GetText("side_Right"), "BBBBBB", "FFFFFF", 3)
g_np_screen.AddGadget(g_np_inpname)
g_np_screen.AddGadget(g_np_cmbnation)
g_np_screen.AddGadget(g_np_btnflag)
g_np_screen.AddGadget(g_np_cmbclubnation)
g_np_screen.AddGadget(g_np_cmbposition)
g_np_screen.AddGadget(g_np_cmbside)
w = 200
x = 450
y = 80
g_np_screen.AddGadget(TPanel.CreatePanel("pan_colours", GetText("Appearance"), x - 20, y, w + 40, 30, "FFFFFF", "FFFFFF", 3, 0.8, 1, 400, 0))
y :+ 40
g_np_screen.AddGadget(TButton.CreateButton("btn_skin", GetText("Skin"), x, y, w / 2, h, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 4, ""))
g_np_cmbskin = TCombo.CreateCombo("cmb_Skin", GetText("Skin"), x + w / 2, y, w / 2, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboSkin, 5)
y :+ 40
g_np_cmbskin.AddItem("", TKit.GetHexSkinColour(1), "FFFFFF", 0)
g_np_cmbskin.AddItem("", TKit.GetHexSkinColour(2), "FFFFFF", 0)
g_np_cmbskin.AddItem("", TKit.GetHexSkinColour(3), "FFFFFF", 0)
g_np_cmbskin.AddItem("", TKit.GetHexSkinColour(4), "FFFFFF", 0)
g_np_cmbskin.AddItem("", TKit.GetHexSkinColour(5), "FFFFFF", 0)
g_np_screen.AddGadget(g_np_cmbskin)
g_np_screen.AddGadget(TButton.CreateButton("btn_hair", GetText("Hair"), x, y, w / 2, h, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 4, ""))
g_np_cmbhair = TCombo.CreateCombo("cmb_Hair", GetText("Hair"), x + w / 2, y, w / 2, h, 1, 2, "FFFFFF", "FFFFFF", 1.0, ComboHair, 5)
y :+ 40
g_np_cmbhair.AddItem("", TKit.GetHexHairCol(1), "FFFFFF", 1)
g_np_cmbhair.AddItem("", TKit.GetHexHairCol(2), "FFFFFF", 2)
g_np_cmbhair.AddItem("", TKit.GetHexHairCol(6), "FFFFFF", 6)
g_np_cmbhair.AddItem("", TKit.GetHexHairCol(4), "FFFFFF", 4)
g_np_cmbhair.AddItem("", TKit.GetHexHairCol(7), "FFFFFF", 7)
g_np_cmbhair.AddItem("", TKit.GetHexHairCol(3), "FFFFFF", 3)
g_np_cmbhair.AddItem("", TKit.GetHexHairCol(5), "FFFFFF", 5)
g_np_screen.AddGadget(g_np_cmbhair)
g_np_btnkit = TButton.CreateButton("btn_Kit", "", x, y + 10, w, 280, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, "")
g_np_screen.AddGadget(g_np_btnkit)
g_np_screen.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
g_np_screen.AddGadget(TButton.CreateButton("btn_quit", "", 10, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_quit, ButtonQuit, 1.0, 1, GetText("tt_Quit")))
g_np_screen.AddGadget(TButton.CreateButton("btn_play", "", 670, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_proceed, ButtonPlay, 1.0, 1, GetText("tt_Proceed")))
