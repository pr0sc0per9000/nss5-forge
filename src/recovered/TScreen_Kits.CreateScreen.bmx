' TScreen_Kits.CreateScreen
' VA 0x005493AB   1266 bytes   mode=reloc   byte-identical vs NSS5.exe
' (1266/1266, original length from Ghidra's inventory, reloc_masked=130)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x30
'
' ASSUMPTIONS
'   Module Globals (addresses are fact, NAMES are ours -- module Globals have no debug record):
'     0x00C674B8 -> g_screen_kits:TScreen        (construction site = TScreen.CreateScreen)
'     0x00C67500 -> g_lbl_team1:TLabel   0x00C67504 -> g_lbl_team2:TLabel
'     0x00C67508 -> g_lbl_controller1:TLabel   0x00C6750C -> g_lbl_controller2:TLabel
'     0x00C674FC -> g_btn_back:TButton
'     0x00C6EFDC -> g_screen_width:Int   0x00C6EFE0 -> g_screen_height:Int
'         (SAME addresses as TScreen_Pairs.CreateScreen's g_screen_width/g_screen_height)
'     0x00C6F194 -> g_iconBack:TImage    (same address named g_iconBack in
'         TScreen_Roulette.CreateScreen; globals_final.tsv types it plain Object, low
'         confidence -- construction site is elsewhere. Used here as CreateButton's image arg.)
'     0x00C6F230 -> g_img_866:TImage     (same address named g_img_866 in
'         TScreen_ContractOffer.CreateScreen)
'     0x00C6F274 -> g_img_play:TImage    (hand-verified TImage; name established across many
'         recovered CreateScreen bodies, e.g. TScreen_Options.CreateScreen)
'   Class-table slots resolved through globals_final.tsv / vtable_map.tsv:
'     0x00C61C64 = TScreen+0x38     CreateScreen ($,:TImage,()i,()i):TScreen
'     0x00C63294 = TPanel+0x88      CreatePanel ($,$,i,i,i,i,$,$,i,f,i,i,i):TPanel
'     0x00C634C0 = TLabel+0x88      CreateLabel ($,$,i,i,i,i,i,$,$,f,i,i,i,i,:TImage,i,i,i,i,$,f):TLabel
'     0x00C623CC = TButton+0x88     CreateButton ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
'     slot 0x40 on a TScreen = TScreen.AddGadget (:TGadget)i
'     Draw / ButtonQuit / ButtonChangeKits / ButtonPlay are sibling statics of this Type
'     (TScreen_Kits+0x38/0x44/0x48/0x4c), passed as function-pointer arguments; referenced
'     bare per house style for same-Type callbacks.
'   0x005B95D0 (NullFunctionError) is what `Null` compiles to for a `()i` parameter
'   (CreateScreen's 4th arg, and the image/callback pair on the "kits_kit1"/"kits_kit2"
'   buttons, which have no icon or click handler).
'   Ghidra's pseudo-C merges a callee's argument list with the pushes of the FOLLOWING
'   call (the project-wide caveat in every annotated decomp header); every `GetText(text,
'   <13 more literals...)` immediately followed by a 2-argument CreatePanel/CreateLabel/
'   CreateButton call is really `GetText(text)` feeding straight into that Create call's own
'   text argument, with the remaining literals being that Create call's real x/y/w/h/...
'   arguments. Confirmed against each signature's declared arity (13/21/15) from
'   `extracted/decomp_annotated/TScreen_Kits.CreateScreen@005493ab.c`'s CALL table, which
'   records true argument byte-counts from the post-call `add esp,N`.
'   All string literals read out of NSS5.exe with harness.read_string.
'!Global g_screen_kits:TScreen
'!Global g_lbl_team1:TLabel
'!Global g_lbl_team2:TLabel
'!Global g_lbl_controller1:TLabel
'!Global g_lbl_controller2:TLabel
'!Global g_btn_back:TButton
'!Global g_screen_width:Int
'!Global g_screen_height:Int
'!Global g_iconBack:TImage
'!Global g_img_866:TImage
'!Global g_img_play:TImage
g_screen_kits = TScreen.CreateScreen("kits", Null, Draw, Null)
g_screen_kits.AddGadget(TPanel.CreatePanel("pan_title", GetText("Choose Kits"), 0, 0, g_screen_width, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1))
g_lbl_team1 = TLabel.CreateLabel("team1", "", 80, 80, 300, 40, 3, "888888", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_lbl_team2 = TLabel.CreateLabel("team2", "", 420, 80, 300, 40, 3, "888888", "FFFFFF", 1.0, 2, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_screen_kits.AddGadget(g_lbl_team1)
g_screen_kits.AddGadget(g_lbl_team2)
g_lbl_controller1 = TLabel.CreateLabel("controller1", GetText("Player 1"), 80, 120, 300, 30, 2, "FFFFFF", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_lbl_controller2 = TLabel.CreateLabel("controller2", GetText("Player 2"), 420, 120, 300, 30, 2, "FFFFFF", "FFFFFF", 1.0, 3, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
g_screen_kits.AddGadget(g_lbl_controller1)
g_screen_kits.AddGadget(g_lbl_controller2)
g_screen_kits.AddGadget(TButton.CreateButton("kits_kit1", "", 220, 320, 0, 0, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, ""))
g_screen_kits.AddGadget(TButton.CreateButton("kits_kit2", "", 580, 320, 0, 0, 0, 2, "FFFFFF", "FFFFFF", Null, Null, 1.0, 1, ""))
g_screen_kits.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screen_height - 60, g_screen_width, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
g_btn_back = TButton.CreateButton("btn_Back", "", 10, g_screen_height - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_iconBack, ButtonQuit, 1.0, 1, GetText("tt_Back"))
g_screen_kits.AddGadget(g_btn_back)
g_screen_kits.AddGadget(TButton.CreateButton("btn_change", GetText("Change Kits"), 300, g_screen_height - 50, 200, 40, 1, 3, "FFFFFF", "FFFFFF", g_img_866, ButtonChangeKits, 1.0, 1, ""))
g_screen_kits.AddGadget(TButton.CreateButton("btn_play", "", g_screen_width - 130, g_screen_height - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, ButtonPlay, 1.0, 1, GetText("tt_GoToMatch")))
