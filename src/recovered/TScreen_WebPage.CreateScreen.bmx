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
' TScreen_WebPage.CreateScreen
' VA 0x00560B17   1359 bytes   class-table slot 0x30   sig ()i
' byte-identical vs NSS5.exe (1359/1359, original length from Ghidra's inventory, mode=reloc)
'
' Builds a generic "web page" screen: a shared title panel, a bottom nav with a Play
' button plus Twitter/Facebook share buttons, a big headline label, a small league-name
' label, and a small league table. The three background/social images are loaded once and
' cached in Globals, guarded by a plain "If Not bg" truthiness test (NOT an explicit
' `=Null` comparison -- codegen-patterns 10.3; the direct-compare form is 11 bytes shorter
' and does not match).
'
' GLOBAL NAMES ARE OURS. 0x00C6F170 g_iconpath:String (established by TEngine.SetUp and
' several TScreen_*.CreateScreen bodies -- globals_final.tsv mistypes it Int), 0x00C66768
' g_pan_title:TPanel (shared reusable panel, same address as TScreen_GameMenu/
' TScreen_Abilities's "pan_stable"/"pan_title"), 0x00C6F274 g_img_play:TImage (shared icon,
' same address/type as TScreen.DoMessage's g_img_play), 0x00C688D8 g_screen_webpage:TScreen,
' 0x00C688DC/E0/E4 g_webpage_img_bg/fb/tw:TImage, 0x00C688E8/EC g_webpage_lbl_headline/
' league:TLabel, 0x00C688F0 g_webpage_tbl_league:TTable, 0x00C688F4 g_webpage_pan_nav:TPanel,
' 0x00C688F8/FC g_webpage_btn_tw/fb:TButton.
'
' SHAPE NOTES
'   * TScreen.AddGadget (own slot 0x40) is used for pan_title/pan_Nav/labels/table, added
'     straight onto g_screen_webpage; TGadget.AddChild (inherited slot 0x74) is used for
'     the three nav buttons, added onto g_webpage_pan_nav directly -- these are genuinely
'     different calls, not a stylistic choice.
'   * btn_play has no Global of its own -- it is AddChild'd inline, straight off
'     CreateButton's return value, unlike btn_Twitter/btn_Facebook which are each stored to
'     a Global first (matching the original's per-widget retain/release/store then a
'     separate AddChild call).
'   * `GetText("tla_Position")` etc. are each the FIRST argument of the following
'     `AddColumn` call, not a call with a 4-argument literal signature of their own
'     (codegen-patterns's "Ghidra merges pushes with the following call" note).
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_iconpath:String
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
'!Global g_screen_webpage:TScreen
'!Global g_webpage_img_bg:TImage
'!Global g_webpage_img_fb:TImage
'!Global g_webpage_img_tw:TImage
'!Global g_pan_title:TPanel
'!Global g_webpage_pan_nav:TPanel
'!Global g_webpage_btn_tw:TButton
'!Global g_webpage_btn_fb:TButton
'!Global g_webpage_lbl_headline:TLabel
'!Global g_webpage_lbl_league:TLabel
'!Global g_webpage_tbl_league:TTable
'!Global g_img_play:TImage
If Not g_webpage_img_bg
	g_webpage_img_bg = LoadImageChecked("GameMedia/Images/Backgrounds/WebPage.png", -1)
	g_webpage_img_fb = LoadImageChecked(g_iconpath + "Facebook.png", -1)
	g_webpage_img_tw = LoadImageChecked(g_iconpath + "Twitter.png", -1)
EndIf
g_screen_webpage = TScreen.CreateScreen("webpage", g_webpage_img_bg, Null, Null)
g_screen_webpage.AddGadget(g_pan_title)
g_webpage_pan_nav = TPanel.CreatePanel("pan_Nav", "", 0, g_screenheight - 60, g_screenwidth, 60, "FFFFFF", "FFFFFF", 3, 1.0, 0, 0, 1)
g_screen_webpage.AddGadget(g_webpage_pan_nav)
g_webpage_pan_nav.AddChild(TButton.CreateButton("btn_play", "", g_screenwidth - 130, g_screenheight - 50, 120, 40, 1, 2, "FFFFFF", "FFFFFF", g_img_play, TScreen_WebPage.ButtonPlay, 1.0, 1, ""))
g_webpage_btn_tw = TButton.CreateButton("btn_Twitter", GetText("social_Tweet"), g_screenwidth - 260, g_screenheight - 50, 120, 40, 1, 3, "FFFFFF", "FFFFFF", g_webpage_img_tw, TScreen_WebPage.ButtonTwitter, 1.0, 1, "")
g_webpage_btn_fb = TButton.CreateButton("btn_Facebook", GetText("social_Share"), g_screenwidth - 390, g_screenheight - 50, 120, 40, 1, 3, "FFFFFF", "FFFFFF", g_webpage_img_fb, TScreen_WebPage.ButtonFacebook, 1.0, 1, "")
g_webpage_pan_nav.AddChild(g_webpage_btn_tw)
g_webpage_pan_nav.AddChild(g_webpage_btn_fb)
g_webpage_lbl_headline = TLabel.CreateLabel("lbl_Headline", "", 10, 240, 540, 280, 4, "888888", "000000", 0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0)
g_screen_webpage.AddGadget(g_webpage_lbl_headline)
g_webpage_lbl_league = TLabel.CreateLabel("lbl_League", "", 560, 230, 240, 40, 3, "888888", "FFFFFF", 0, 1, 0, 0, 1, Null, 1, 0, 0, 0, "", 0)
g_screen_webpage.AddGadget(g_webpage_lbl_league)
g_webpage_tbl_league = TTable.CreateTable("tbl_League", 561, 270, 12, 0, 1, 2, "00FF00", 1.0, 1, Null)
g_webpage_tbl_league.AddColumn(30, GetText("tla_Position"), "000000", "EEEEEE", 1)
g_webpage_tbl_league.AddColumn(114, GetText("Name"), "000000", "FFFFFF", 0)
g_webpage_tbl_league.AddColumn(30, GetText("tla_Played"), "000000", "EEEEEE", 1)
g_webpage_tbl_league.AddColumn(30, GetText("tla_GoalDifference"), "000000", "EEEEEE", 1)
g_webpage_tbl_league.AddColumn(30, GetText("tla_Points"), "000000", "DDDDDD", 1)
g_screen_webpage.AddGadget(g_webpage_tbl_league)
Return 0
