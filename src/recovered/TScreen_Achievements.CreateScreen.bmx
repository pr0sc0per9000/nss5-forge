' GLOBAL RENAMED (2026-08-15): g_ach_imgpath -> g_iconpath in THIS file only.
' 0x00C6F170 is the GameMedia/Images/Icons/ root. The corpus uses the identifier
' g_mediapath for TWO different slots -- 0x00C6F170 here and in 8 other files, and
' 0x00C6E950 (the install root) in 9 OTHERS. One name, two slots, an exact 9/9 split,
' so no single value assigned to g_mediapath could ever be right at every call site:
' whichever way it went, half the asset paths resolved wrong and ~100 images failed to
' load. Per-body verification cannot catch this -- a Global reaches the compiled code
' only as an absolute address and the byte oracle masks those, so both spellings
' verify byte-perfectly. Renaming is byte-neutral; scripts/reverify.py confirms it.
' See scripts/unify_globals.py for the rest of this defect class.
' TScreen_Achievements.CreateScreen
' VA 0x00559280   742 bytes   mode=reloc   byte-identical vs NSS5.exe (742/742)
' KIND=Function (static), SIG ()i, class-table slot 0x30
' ASSUMPTIONS -- module Globals (names ours; the ADDRESS and the TYPE are load-bearing)
'   0x00C68314 -> g_ach_screen:TScreen        (slot 0x40 = TScreen.AddGadget)
'   0x00C68318 -> g_ach_imgStar:TImage        0x00C6831C -> g_ach_imgStarGrey:TImage
'   0x00C68320 -> g_ach_panAchievements:TPanel
'   0x00C68324 -> g_ach_tblAchievements:TTable   (slot 0x90 = TTable.AddColumn)
'   0x00C68328 -> g_ach_prgAchievements:TProgressBar
'   0x00C6F170 -> g_iconpath:String        (concat operand for the two star icons; a
'                 different Global from g_datapath, already the full icon directory)
'   0x00C66768 -> g_pan_stable:TPanel   0x00C667B0 -> g_pan_money:TPanel  (shared; the
'                 names/types other CreateScreen bodies already use for those addresses)
'   0x00C6EFDC -> g_screenwidth:Int
' Class-table slots: 0x00C61C64 TScreen+0x38 CreateScreen; 0x00C63294 TPanel+0x88
'   CreatePanel; 0x00C62BAC TTable+0x88 CreateTable; 0x00C637A8 TProgressBar+0x88
'   CreateProgressBar. 0x005B95D0 = the empty function = source-level Null for an ()i.
' THREE Locals, forced by the prologue (16.3): `sub esp,4` + three callee-saved registers,
' and the original materialises them explicitly --
'     mov ebx,0xa            -> Local x:Int = 10
'     mov [ebp-4],0x46       -> Local y:Int = 70
'     mov edi,g_screenwidth-20 -> Local w:Int = g_screenwidth - 20
'   The progress bar's y is `y + 420` (mov eax,[ebp-4] / add eax,0x1A4), NOT the literal 490,
'   and the table's x is the same `x`. Without these three the body is 722 bytes.
' Empty strings are all pooled LITERALS (0x00C5D284), so `""`, not `Null` -- 0x005C7D40
'   (bbEmptyString) does not appear anywhere in this function.
' Literals read out of .data. 0x3F800000 = 1.0, 0x3F4CCCCD = 0.8, 0x27C = 636, 0x2A = 42.
'!Global g_ach_screen:TScreen
'!Global g_ach_imgStar:TImage
'!Global g_ach_imgStarGrey:TImage
'!Global g_ach_panAchievements:TPanel
'!Global g_ach_tblAchievements:TTable
'!Global g_ach_prgAchievements:TProgressBar
'!Global g_iconpath:String
'!Global g_pan_stable:TPanel
'!Global g_pan_money:TPanel
'!Global g_screenwidth:Int
g_ach_screen = TScreen.CreateScreen("achievements", Null, Null, Null)
If Not g_ach_imgStar
	g_ach_imgStar = LoadImageChecked(g_iconpath + "Star28.png", -1)
	g_ach_imgStarGrey = LoadImageChecked(g_iconpath + "StarGrey28.png", -1)
	MidHandleImage(g_ach_imgStar)
	MidHandleImage(g_ach_imgStarGrey)
EndIf
g_ach_screen.AddGadget(g_pan_stable)
g_ach_screen.AddGadget(g_pan_money)
Local x:Int = 10
Local y:Int = 70
Local w:Int = g_screenwidth - 20
g_ach_panAchievements = TPanel.CreatePanel("pan_achievements", GetText("My Achievements"), x, y, w, 30, "FFFFFF", "FFFFFF", 3, 1.0, 1, 430, 0)
g_ach_tblAchievements = TTable.CreateTable("tbl_achievements", x, 100, 13, 29, 1, 3, "00FF00", 1.0, 0, Null)
g_ach_tblAchievements.AddColumn(42, "", "000000", "EEEEEE", 1)
g_ach_tblAchievements.AddColumn(636, "", "000000", "FFFFFF", 0)
g_ach_tblAchievements.AddColumn(100, "", "000000", "EEEEEE", 1)
g_ach_prgAchievements = TProgressBar.CreateProgressBar("prg_Achievements", "", x, y + 420, w, 40, 3, "888888", "00FF00", "FFFFFF", 0.8, 3, Null)
g_ach_screen.AddGadget(g_ach_panAchievements)
g_ach_screen.AddGadget(g_ach_tblAchievements)
g_ach_screen.AddGadget(g_ach_prgAchievements)
