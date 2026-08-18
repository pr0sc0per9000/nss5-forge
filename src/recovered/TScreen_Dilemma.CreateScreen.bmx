' TScreen_Dilemma.CreateScreen
' VA 0x00556929   1256 bytes   class-table slot 0x30   sig ()i
' byte-identical vs NSS5.exe (1256/1256, original length from Ghidra's inventory, mode=reloc)
'
' Builds the "boss dilemma" screen: title bar + help button, a bottom nav panel holding two
' relationship buttons and two progress bars, then ten preloaded dilemma-option images.
' fDraw is TScreen_Dilemma.Draw itself (a2 of TScreen.CreateScreen, not Null).
'
' GLOBAL NAMES ARE OURS. 0x00C68048 g_screen_dilemma:TScreen, 0x00C6F2EC g_icon_help:TImage
' (same address/type as TScreen_MatchPaused.CreateScreen), 0x00C68054/58
' g_dilemma_btn1/2:TButton, 0x00C6804C/50 g_dilemma_prg1/2:TProgressBar, and ten TImage
' globals at 0x00C6806C..0x00C68090 for the relationship-option pictures.
'
' SHAPE NOTES -- identical idiom to TScreen_MatchPaused.CreateScreen: pan_title, btn_help
' and pan_nav are AddGadget'd straight off the freshly-stored g_screen_dilemma Global with
' no Local holding the widget; the two relationship buttons and the two progress bars are
' each stored to their own Global FIRST and AddGadget'd on separate following statements
' (matching the original's per-widget retain/release/store then a second AddGadget call
' that re-reads the Global). The ten LoadImageChecked results are plain Global stores with
' no further processing (codegen-patterns 12.2 asset-loader family).
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_screen_dilemma:TScreen
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_icon_help:TImage
'!Global g_dilemma_btn1:TButton
'!Global g_dilemma_btn2:TButton
'!Global g_dilemma_prg1:TProgressBar
'!Global g_dilemma_prg2:TProgressBar
'!Global g_dilemma_img_boss:TImage
'!Global g_dilemma_img_training:TImage
'!Global g_dilemma_img_fans:TImage
'!Global g_dilemma_img_bowling:TImage
'!Global g_dilemma_img_golf:TImage
'!Global g_dilemma_img_cinema:TImage
'!Global g_dilemma_img_pub:TImage
'!Global g_dilemma_img_restaurant:TImage
'!Global g_dilemma_img_shopping:TImage
'!Global g_dilemma_img_sponsors:TImage
g_screen_dilemma = TScreen.CreateScreen("dilemma", Null, TScreen_Dilemma.Draw, Null)
g_screen_dilemma.AddGadget(TPanel.CreatePanel("pan_title", GetText("Dilemma!"), 0, 0, g_screenwidth, 60, "FFFFFF", "FFFFFF", 4, 1.0, 0, 0, 1))
g_screen_dilemma.AddGadget(TButton.CreateButton("btn_help", "", g_screenwidth - 50, 10, 40, 40, 1, 2, "FFFFFF", "FFFFFF", g_icon_help, TScreen.ButtonHelp, 1.0, 1, ""))
g_screen_dilemma.AddGadget(TPanel.CreatePanel("pan_nav", "", 0, g_screenheight - 110, g_screenwidth, 110, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1))
g_dilemma_btn1 = TButton.CreateButton("btn_relationship1", "", 10, g_screenheight - 50, 380, 40, 1, 4, "FFFFFF", "FFFFFF", Null, TScreen_Dilemma.ButtonRelationship, 1.0, 1, "")
g_dilemma_btn2 = TButton.CreateButton("btn_relationship2", "", 410, g_screenheight - 50, 380, 40, 1, 4, "FFFFFF", "FFFFFF", Null, TScreen_Dilemma.ButtonRelationship, 1.0, 1, "")
g_screen_dilemma.AddGadget(g_dilemma_btn1)
g_screen_dilemma.AddGadget(g_dilemma_btn2)
g_dilemma_prg1 = TProgressBar.CreateProgressBar("prg_Relationship1", "", 10, g_screenheight - 100, 380, 40, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
g_dilemma_prg2 = TProgressBar.CreateProgressBar("prg_Relationship2", "", 410, g_screenheight - 100, 380, 40, 2, "FFFFFF", "00FF00", "FFFFFF", 0.8, 1, Null)
g_screen_dilemma.AddGadget(g_dilemma_prg1)
g_screen_dilemma.AddGadget(g_dilemma_prg2)
g_dilemma_img_boss = LoadImageChecked("GameMedia\Images\Relationships\boss.png", -1)
g_dilemma_img_training = LoadImageChecked("GameMedia\Images\Relationships\training_ground.png", -1)
g_dilemma_img_fans = LoadImageChecked("GameMedia\Images\Relationships\fans.png", -1)
g_dilemma_img_bowling = LoadImageChecked("GameMedia\Images\Relationships\bowling.png", -1)
g_dilemma_img_golf = LoadImageChecked("GameMedia\Images\Relationships\golf_course.png", -1)
g_dilemma_img_cinema = LoadImageChecked("GameMedia\Images\Relationships\cinema.png", -1)
g_dilemma_img_pub = LoadImageChecked("GameMedia\Images\Relationships\pub.png", -1)
g_dilemma_img_restaurant = LoadImageChecked("GameMedia\Images\Relationships\restaurant.png", -1)
g_dilemma_img_shopping = LoadImageChecked("GameMedia\Images\Relationships\shopping.png", -1)
g_dilemma_img_sponsors = LoadImageChecked("GameMedia\Images\Relationships\sponsors.png", -1)
Return 0
