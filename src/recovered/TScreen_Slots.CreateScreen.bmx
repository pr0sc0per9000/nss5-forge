' TScreen_Slots.CreateScreen
' VA 0x00577E66   597 bytes   mode=reloc   byte-identical vs NSS5.exe (597/597)
' KIND=Function (static), SIG ()i, class-table slot 0x30
' ASSUMPTIONS -- module Globals (names ours; the ADDRESS and the TYPE are load-bearing)
'   0x00C6C490 -> g_slots_imgBg:TImage      (LoadImageChecked return type)
'   0x00C6C494 -> g_slots_imgButton:TImage
'   0x00C6C498 -> g_slots_screen:TScreen    (slot 0x40 = TScreen.AddGadget)
'   0x00C6C49C -> g_slots_btnQuit:TButton
'   0x00C6C4A0 -> g_slots_btnPlay:TButton
'   0x00C66768 -> g_pan_stable:TPanel      (shared panel, AddGadget'd first; same name/type
'                 as TScreen_Abilities/Home/Relationships.CreateScreen use for this address)
'   0x00C6B858 -> g_panCash:TPanel          (shared casino cash panel, AddGadget'd last)
'   0x00C6F194 -> g_iconBack:TImage         (forced by CreateButton's :TImage parameter)
'   0x00C6E950 -> g_datapath:String
'   0x00C6EFDC -> g_screenwidth:Int   0x00C6EFE0 -> g_screenheight:Int  (bare dword pushes,
'                 no refcount traffic -> Int, rule 11.2)
' Class-table slots: 0x00C61C64 = TScreen+0x38 CreateScreen($,:TImage,()i,()i):TScreen;
'   0x00C63294 = TPanel+0x88 CreatePanel; 0x00C623CC = TButton+0x88 CreateButton;
'   0x00C6BA24 = TScreen_Casino+0x38 SetUpScreen; 0x00C6C548 = TScreen_Slots+0x38 ButtonPlay
'   (own Type -> bare name, no prefix); 0x00C6C644/48 = TSlotMachine Update/Draw.
' The image guard is `If Not g_slots_imgBg` (setne/movzx/cmp 0), not `= Null`, and it
' encloses BOTH loads.
' 0x004BC372 = LoadImageChecked (recovered module Function); its second argument is -1.
' Literals read out of .data. 0x3F800000 = 1.0; 0x216/0x1D4 = 534/468.
'!Global g_slots_imgBg:TImage
'!Global g_slots_imgButton:TImage
'!Global g_slots_screen:TScreen
'!Global g_slots_btnQuit:TButton
'!Global g_slots_btnPlay:TButton
'!Global g_pan_stable:TPanel
'!Global g_panCash:TPanel
'!Global g_iconBack:TImage
'!Global g_datapath:String
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
If Not g_slots_imgBg
	g_slots_imgBg = LoadImageChecked(g_datapath + "GameMedia/Images/Casino/Slots/bg.png", -1)
	g_slots_imgButton = LoadImageChecked(g_datapath + "GameMedia/Images/Casino/Slots/Button.png", -1)
EndIf
g_slots_screen = TScreen.CreateScreen("slots", g_slots_imgBg, TSlotMachine.Draw, TSlotMachine.Update)
g_slots_screen.AddGadget(g_pan_stable)
g_slots_screen.AddGadget(TPanel.CreatePanel("navpanel", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 0))
g_slots_btnQuit = TButton.CreateButton("btn_quit", "", 10, g_screenheight - 50, 100, 40, 1, 2, "FFFFFF", "FFFFFF", g_iconBack, TScreen_Casino.SetUpScreen, 1.0, 1, GetText("tt_Back"))
g_slots_btnPlay = TButton.CreateButton("btn_play", "", 534, 468, 100, 60, 1, 2, "FFFFFF", "FFFFFF", g_slots_imgButton, ButtonPlay, 1.0, 10, GetText("tt_Play"))
g_slots_screen.AddGadget(g_slots_btnQuit)
g_slots_screen.AddGadget(g_slots_btnPlay)
g_slots_screen.AddGadget(g_panCash)
